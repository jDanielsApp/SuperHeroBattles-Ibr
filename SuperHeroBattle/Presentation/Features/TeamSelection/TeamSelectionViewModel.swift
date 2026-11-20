import Foundation

/// Posición de un hueco dentro de un equipo.
nonisolated struct TeamSlotLocation: Hashable, Sendable {
    let side: TeamSide
    let slot: Int
}

/// Estado de la pantalla de selección de equipos.
///
/// Reglas de la fase:
/// - No se repiten héroes dentro de un mismo equipo.
/// - Sí puede aparecer el mismo héroe en ambos equipos.
/// - La selección aleatoria rellena únicamente el hueco solicitado.
///
/// Aleatoriedad: al entrar en la pantalla se sortean `teamSize × 2` IDs
/// del índice completo de personajes y se cargan en segundo plano (caché
/// local primero, red para los ausentes). El botón aleatorio consume ese
/// pool precargado; agotado, sortea un ID nuevo bajo demanda y, si la red
/// o el índice fallan, cae al catálogo local.
@MainActor
@Observable
final class TeamSelectionViewModel {
    let mode: CombatMode

    private(set) var teamA: TeamDraft
    private(set) var teamB: TeamDraft
    private(set) var message: TeamSelectionMessage?
    private(set) var busySlot: TeamSlotLocation?

    private let selectHero: SelectHeroUseCase
    private let generateRandomHero: GenerateRandomHeroUseCase
    private let drawRandomHeroes: DrawRandomHeroesUseCase
    private let buildBattleParticipants: BuildBattleParticipantsUseCase

    private var hasPreparedRandomPool = false

    /// Héroes sorteados del índice completo, pendientes de consumir por el
    /// botón aleatorio. No alimenta la UI directamente.
    @ObservationIgnored private var randomPool: [Hero] = []

    /// IDs ya sorteados: nunca se repiten entre tiradas.
    @ObservationIgnored private var drawnIDs: Set<String> = []

    @ObservationIgnored private var randomTask: Task<Void, Never>?
    @ObservationIgnored private var preloadTask: Task<Void, Never>?
    @ObservationIgnored private var randomGeneration = 0

    init(
        mode: CombatMode,
        selectHero: SelectHeroUseCase,
        generateRandomHero: GenerateRandomHeroUseCase,
        drawRandomHeroes: DrawRandomHeroesUseCase,
        buildBattleParticipants: BuildBattleParticipantsUseCase
    ) {
        self.mode = mode
        self.selectHero = selectHero
        self.generateRandomHero = generateRandomHero
        self.drawRandomHeroes = drawRandomHeroes
        self.buildBattleParticipants = buildBattleParticipants
        teamA = TeamDraft(side: .teamA, mode: mode)
        teamB = TeamDraft(side: .teamB, mode: mode)
    }

    var bothTeamsComplete: Bool {
        teamA.isComplete && teamB.isComplete
    }

    /// Participantes listos para el combate; nil hasta que ambos equipos estén completos.
    var battleParticipants: BattleParticipants? {
        guard bothTeamsComplete else { return nil }
        return try? buildBattleParticipants.execute(teamA: teamA, teamB: teamB)
    }

    func hero(in slot: Int, side: TeamSide) -> Hero? {
        draft(for: side).hero(in: slot)
    }

    /// Precarga el trabajo de aleatoriedad: sortea `teamSize × 2` IDs del
    /// índice completo (2 en 1v1, 4 en 2v2, 6 en 3v3) y lanza su
    /// obtención en segundo plano. Así el botón aleatorio resuelve al
    /// instante y no depende solo de la base de datos local. Silencioso:
    /// si falla, el propio botón caerá al sorteo bajo demanda o al
    /// catálogo local. Solo se ejecuta una vez por pantalla.
    func prepareRandomPool() {
        guard !hasPreparedRandomPool else { return }
        hasPreparedRandomPool = true

        let count = mode.teamSize * 2

        preloadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let outcome = try await self.drawRandomHeroes.execute(count: count)
                self.randomPool.append(contentsOf: outcome.heroes)
                self.drawnIDs.formUnion(outcome.drawnIDs)
            } catch {
                // Precarga silenciosa: el botón aleatorio tiene respaldos.
            }
            self.preloadTask = nil
        }
    }

    func assign(_ hero: Hero, to side: TeamSide, slot: Int) {
        do {
            let updated = try selectHero.execute(hero: hero, slot: slot, in: draft(for: side))
            setDraft(updated, for: side)
            message = nil
        } catch TeamValidationError.duplicateHero {
            message = .duplicateHero
        } catch {
            message = .invalidSlot
        }
    }

    func clear(side: TeamSide, slot: Int) {
        var updated = draft(for: side)
        do {
            try updated.clear(at: slot)
            setDraft(updated, for: side)
            message = nil
        } catch {
            message = .invalidSlot
        }
    }

    /// Rellena únicamente el hueco solicitado con un héroe aleatorio:
    /// consume el pool precargado desde el índice completo; agotado, sortea
    /// un ID nuevo bajo demanda; sin red ni índice, cae al catálogo local.
    /// El sorteo excluye solo los integrantes del equipo que se rellena.
    func fillRandom(side: TeamSide, slot: Int) {
        guard busySlot == nil else { return }

        let excludedIDs = Set(draft(for: side).heroIDs)

        // El pool precargado resuelve el hueco al instante.
        if let hero = pooledHero(excluding: excludedIDs) {
            assign(hero, to: side, slot: slot)
            return
        }

        randomGeneration &+= 1
        let generation = randomGeneration

        busySlot = TeamSlotLocation(side: side, slot: slot)
        message = nil

        randomTask = Task { [weak self] in
            await self?.resolveRandomSlot(
                side: side,
                slot: slot,
                excludedIDs: excludedIDs,
                generation: generation
            )
        }
    }

    /// Cancela el trabajo en curso al salir de la pantalla sin borrar lo publicado.
    func cancelActiveWork() {
        randomTask?.cancel()
        randomTask = nil
        randomGeneration &+= 1

        preloadTask?.cancel()
        preloadTask = nil

        busySlot = nil
    }

    // MARK: - Resolución del aleatorio

    /// Cadena de resolución bajo demanda: sorteo de un ID nuevo desde el
    /// índice completo y, si no hay red ni índice, catálogo local. La
    /// cancelación nunca publica; una generación antigua tampoco.
    private func resolveRandomSlot(
        side: TeamSide,
        slot: Int,
        excludedIDs: Set<String>,
        generation: Int
    ) async {
        var candidate: Hero?

        do {
            let outcome = try await drawRandomHeroes.execute(
                count: 1,
                excluding: drawnIDs.union(excludedIDs)
            )
            drawnIDs.formUnion(outcome.drawnIDs)
            randomPool.append(contentsOf: outcome.heroes)
            try Task.checkCancellation()

            // El sorteo ya excluye el equipo actual; el filtro es defensivo.
            candidate = outcome.heroes.first { !excludedIDs.contains($0.id) }
        } catch is CancellationError {
            return
        } catch {
            // Red o índice caídos: se prueba el catálogo local.
        }

        if candidate == nil {
            do {
                candidate = try await generateRandomHero.execute(excluding: excludedIDs)
            } catch is CancellationError {
                return
            } catch {
                candidate = nil
            }
        }

        guard randomGeneration == generation else { return }

        if let candidate {
            // El héroe del sorteo sale del pool para no repetirlo.
            if let index = randomPool.firstIndex(where: { $0.id == candidate.id }) {
                randomPool.remove(at: index)
            }
            assign(candidate, to: side, slot: slot)
        } else {
            message = .noHeroesAvailable
        }

        busySlot = nil
        randomTask = nil
    }

    /// Saca del pool el primer héroe que no pertenezca al equipo indicado.
    private func pooledHero(excluding heroIDs: Set<String>) -> Hero? {
        guard let index = randomPool.firstIndex(where: { !heroIDs.contains($0.id) }) else {
            return nil
        }
        return randomPool.remove(at: index)
    }

    // MARK: - Borradores

    private func draft(for side: TeamSide) -> TeamDraft {
        switch side {
        case .teamA: teamA
        case .teamB: teamB
        }
    }

    private func setDraft(_ draft: TeamDraft, for side: TeamSide) {
        switch side {
        case .teamA: teamA = draft
        case .teamB: teamB = draft
        }
    }
}
