#!/usr/bin/env python3
"""Descarga y actualiza el índice público de IDs de SuperHeroAPI.

Este proceso solo extrae IDs numéricos de https://superheroapi.com/ids.html.
No descarga fichas de personajes, imágenes ni usa el token de la API.

El archivo de salida contiene exclusivamente una lista de enteros ordenados
de menor a mayor, sin duplicados.
"""

from __future__ import annotations

import json
import os
import sys
import tempfile
from pathlib import Path
from typing import Iterable

import requests
from bs4 import BeautifulSoup

DEFAULT_SOURCE_URL = "https://superheroapi.com/ids.html"
DEFAULT_OUTPUT_PATH = Path("data/character_ids.json")
DEFAULT_MIN_EXPECTED_IDS = 500
DEFAULT_MAX_SHRINK_RATIO = 0.20
DEFAULT_CONNECT_TIMEOUT = 10.0
DEFAULT_READ_TIMEOUT = 30.0
USER_AGENT = "SuperHeroBattle-character-id-updater/1.0"

# Una tabla de índice debe tener un mínimo de filas numéricas y la mayoría
# de sus filas deben ser IDs. Así se ignoran tablas de navegación o resúmenes.
MIN_ROWS_PER_TABLE = 10
MIN_NUMERIC_ROW_RATIO = 0.5


class UpdateError(RuntimeError):
    """Error controlado que debe terminar el proceso con código distinto de cero."""


def fetch_html(source_url: str, timeout: tuple[float, float]) -> str:
    try:
        response = requests.get(
            source_url,
            timeout=timeout,
            headers={
                "User-Agent": USER_AGENT,
                "Accept": "text/html,application/xhtml+xml",
            },
        )
    except requests.RequestException as error:
        raise UpdateError(f"La petición HTTP ha fallado: {error}") from error

    if response.status_code != 200:
        raise UpdateError(f"La respuesta HTTP no es correcta: {response.status_code}")

    if not response.text.strip():
        raise UpdateError("La respuesta HTTP está vacía")

    return response.text


def extract_ids(html: str) -> list[int]:
    soup = BeautifulSoup(html, "html.parser")
    tables = soup.find_all("table")
    if not tables:
        raise UpdateError("No se ha encontrado ninguna tabla en la página")

    ids: set[int] = set()
    used_tables = 0

    for table in tables:
        rows = table.find_all("tr")
        if len(rows) < MIN_ROWS_PER_TABLE:
            continue

        table_ids: list[int] = []
        for row in rows:
            first_cell = row.find("td")
            if first_cell is None:
                continue
            text = first_cell.get_text(strip=True)
            if text.isdigit():
                table_ids.append(int(text))

        if len(table_ids) < MIN_ROWS_PER_TABLE:
            continue
        if len(table_ids) < len(rows) * MIN_NUMERIC_ROW_RATIO:
            continue

        ids.update(table_ids)
        used_tables += 1

    if not ids:
        raise UpdateError("No se han podido extraer IDs de las tablas")

    print(f"Tablas de IDs utilizadas: {used_tables}")
    return sorted(ids)


def load_previous_ids(path: Path) -> list[int] | None:
    if not path.exists():
        return None

    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise UpdateError(f"El JSON anterior no se puede leer: {error}") from error

    if not isinstance(raw, list) or not all(
        isinstance(value, int) and not isinstance(value, bool) for value in raw
    ):
        raise UpdateError("El JSON anterior no contiene una lista de enteros")

    if not raw:
        raise UpdateError("El JSON anterior está vacío")

    return raw


def validate_ids(
    ids: list[int],
    previous_ids: list[int] | None,
    min_expected_ids: int,
    max_shrink_ratio: float,
) -> None:
    if not ids:
        raise UpdateError("El índice extraído está vacío")

    if previous_ids is None:
        if len(ids) < min_expected_ids:
            raise UpdateError(
                f"El índice extraído tiene {len(ids)} IDs, por debajo del mínimo "
                f"esperado para la primera ejecución ({min_expected_ids})"
            )
        return

    minimum_after_shrink = len(previous_ids) * (1.0 - max_shrink_ratio)
    if len(ids) < minimum_after_shrink:
        raise UpdateError(
            f"El índice extraído tiene {len(ids)} IDs y el anterior {len(previous_ids)}; "
            f"la caída supera el {max_shrink_ratio:.0%} permitido"
        )


def log_changes(previous_ids: Iterable[int], current_ids: Iterable[int]) -> None:
    previous = set(previous_ids)
    current = set(current_ids)
    added = sorted(current - previous)
    removed = sorted(previous - current)

    print(f"IDs nuevos: {len(added)}")
    if added:
        print(f"  {format_id_sample(added)}")

    print(f"IDs desaparecidos: {len(removed)}")
    if removed:
        print(f"  {format_id_sample(removed)}")


def format_id_sample(ids: list[int], limit: int = 20) -> str:
    sample = ", ".join(str(value) for value in ids[:limit])
    if len(ids) > limit:
        sample += f", … (+{len(ids) - limit})"
    return sample


def write_atomically(path: Path, ids: list[int]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(ids, indent=2) + "\n"

    temporary_path: str | None = None
    try:
        with tempfile.NamedTemporaryFile(
            "w",
            encoding="utf-8",
            dir=path.parent,
            prefix=f".{path.name}.",
            suffix=".tmp",
            delete=False,
        ) as temporary_file:
            temporary_file.write(payload)
            temporary_file.flush()
            os.fsync(temporary_file.fileno())
            temporary_path = temporary_file.name

        os.replace(temporary_path, path)
        temporary_path = None
    finally:
        if temporary_path is not None and os.path.exists(temporary_path):
            os.unlink(temporary_path)


def main() -> int:
    source_url = os.environ.get("SOURCE_URL", DEFAULT_SOURCE_URL)
    output_path = Path(os.environ.get("OUTPUT_PATH", str(DEFAULT_OUTPUT_PATH)))
    min_expected_ids = int(os.environ.get("MIN_EXPECTED_IDS", DEFAULT_MIN_EXPECTED_IDS))
    max_shrink_ratio = float(
        os.environ.get("MAX_SHRINK_RATIO", DEFAULT_MAX_SHRINK_RATIO)
    )
    timeout = (
        float(os.environ.get("HTTP_CONNECT_TIMEOUT", DEFAULT_CONNECT_TIMEOUT)),
        float(os.environ.get("HTTP_READ_TIMEOUT", DEFAULT_READ_TIMEOUT)),
    )

    try:
        html = fetch_html(source_url, timeout)
        ids = extract_ids(html)
        previous_ids = load_previous_ids(output_path)
        validate_ids(ids, previous_ids, min_expected_ids, max_shrink_ratio)

        if previous_ids == ids:
            print(f"Sin cambios: {len(ids)} IDs.")
            return 0

        if previous_ids is not None:
            log_changes(previous_ids, ids)

        write_atomically(output_path, ids)
        print(f"Actualizado {output_path}: {len(ids)} IDs.")
        return 0
    except UpdateError as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1
    except Exception as error:  # noqa: BLE001 - el proceso debe fallar de forma controlada
        print(f"Error inesperado: {type(error).__name__}: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
