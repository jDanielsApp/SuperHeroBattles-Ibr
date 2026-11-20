import Foundation

/// Position of a slot within a team.
nonisolated struct TeamSlotLocation: Hashable, Sendable {
    let side: TeamSide
    let slot: Int
}

/// State for the team selection screen.
///
/// Rules:
/// - No repeated heroes within one team.
/// - The same hero MAY appear in both teams.
/// - Random selection fills only the requested slot.
///
/// Randomness: entering the screen draws `teamSize × 2` IDs from the
/// full character index and loads them in the background (local cache
/// first, network for missing ones). The random button consumes that
/// preloaded pool; once exhausted, it draws a new ID on demand, and if
/// the network or index fail it falls back to the local catalog.
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

    /// Heroes drawn from the full index, waiting to be consumed by the
    /// random button. Does not feed the UI directly.
    @ObservationIgnored private var randomPool: [Hero] = []

    /// IDs already drawn: never repeated across draws.
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

    /// Participants ready for combat; nil until both teams are complete.
    var battleParticipants: BattleParticipants? {
        guard bothTeamsComplete else { return nil }
        return try? buildBattleParticipants.execute(teamA: teamA, teamB: teamB)
    }

    func hero(in slot: Int, side: TeamSide) -> Hero? {
        draft(for: side).hero(in: slot)
    }

    /// Preloads the random work: draws `teamSize × 2` IDs from the full
    /// index (2 in 1v1, 4 in 2v2, 6 in 3v3) and fetches them in the
    /// background. This lets the random button resolve instantly rather
    /// than depending only on the local database. Silent: on failure the
    /// button itself falls back to on-demand draws or the local catalog.
    /// Runs only once per screen.
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
                // Silent preload: the random button has fallbacks.
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

    /// Fills only the requested slot with a random hero: consumes the
    /// preloaded pool from the full index; once exhausted, draws a new ID
    /// on demand; with no network or index, falls back to the local
    /// catalog. The draw excludes only members of the team being filled.
    func fillRandom(side: TeamSide, slot: Int) {
        guard busySlot == nil else { return }

        let excludedIDs = Set(draft(for: side).heroIDs)

        // The preloaded pool resolves the slot instantly.
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

    /// Cancels in-flight work when leaving the screen without discarding published state.
    func cancelActiveWork() {
        randomTask?.cancel()
        randomTask = nil
        randomGeneration &+= 1

        preloadTask?.cancel()
        preloadTask = nil

        busySlot = nil
    }

    // MARK: - Random resolution

    /// On-demand resolution chain: draw a new ID from the full index and,
    /// with no network or index, fall back to the local catalog.
    /// Cancellation never publishes; neither does a stale generation.
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

            // The draw already excludes the current team; the filter is defensive.
            candidate = outcome.heroes.first { !excludedIDs.contains($0.id) }
        } catch is CancellationError {
            return
        } catch {
            // Network or index down: try the local catalog.
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
            // The drawn hero is removed from the pool so it is not repeated.
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

    /// Removes from the pool the first hero not belonging to the given team.
    private func pooledHero(excluding heroIDs: Set<String>) -> Hero? {
        guard let index = randomPool.firstIndex(where: { !heroIDs.contains($0.id) }) else {
            return nil
        }
        return randomPool.remove(at: index)
    }

    // MARK: - Drafts

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
