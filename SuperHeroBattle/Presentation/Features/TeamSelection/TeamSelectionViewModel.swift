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
    private let buildBattleParticipants: BuildBattleParticipantsUseCase
    private let preloadHeroes: LoadHeroesByIDsUseCase
    private let characterIDs: any CharacterIDProviding

    private var hasPreloadedCatalog = false

    @ObservationIgnored private var randomTask: Task<Void, Never>?
    @ObservationIgnored private var preloadTask: Task<Void, Never>?
    @ObservationIgnored private var randomGeneration = 0

    init(
        mode: CombatMode,
        selectHero: SelectHeroUseCase,
        generateRandomHero: GenerateRandomHeroUseCase,
        buildBattleParticipants: BuildBattleParticipantsUseCase,
        preloadHeroes: LoadHeroesByIDsUseCase,
        characterIDs: any CharacterIDProviding
    ) {
        self.mode = mode
        self.selectHero = selectHero
        self.generateRandomHero = generateRandomHero
        self.buildBattleParticipants = buildBattleParticipants
        self.preloadHeroes = preloadHeroes
        self.characterIDs = characterIDs
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

    /// Precarga la primera página del catálogo para que el botón aleatorio
    /// tenga héroes disponibles sin haber pasado por la Guía. Es un intento
    /// silencioso: si falla, el propio selector o la Guía mostrarán el error.
    func loadCatalogIfNeeded() {
        guard !hasPreloadedCatalog else { return }
        hasPreloadedCatalog = true

        guard let ids = try? characterIDs.characterIDs(), !ids.isEmpty else { return }
        let pageIDs = Array(ids.prefix(CharacterGuideViewModel.pageSize))

        preloadTask = Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await self.preloadHeroes.execute(ids: pageIDs)
            } catch {
                // Precarga silenciosa: el selector o la Guía presentan el error.
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

    /// Rellena únicamente el hueco solicitado con un héroe aleatorio del
    /// catálogo local, excluyendo solo los integrantes de su propio equipo.
    func fillRandom(side: TeamSide, slot: Int) {
        guard busySlot == nil else { return }

        randomGeneration &+= 1
        let generation = randomGeneration
        let excludedIDs = Set(draft(for: side).heroIDs)

        busySlot = TeamSlotLocation(side: side, slot: slot)
        message = nil

        randomTask = Task { [weak self] in
            guard let self else { return }

            do {
                let hero = try await self.generateRandomHero.execute(excluding: excludedIDs)
                try Task.checkCancellation()
                guard self.randomGeneration == generation else { return }

                if let hero {
                    self.assign(hero, to: side, slot: slot)
                } else {
                    self.message = .noHeroesAvailable
                }
            } catch is CancellationError {
                guard self.randomGeneration == generation else { return }
            } catch {
                guard self.randomGeneration == generation else { return }
                self.message = .noHeroesAvailable
            }

            guard self.randomGeneration == generation else { return }
            self.busySlot = nil
            self.randomTask = nil
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
