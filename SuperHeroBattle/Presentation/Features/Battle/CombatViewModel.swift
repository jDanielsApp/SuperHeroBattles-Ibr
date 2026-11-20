import Foundation

/// State for the combat screen. The engine result is immutable;
/// the narration is generated separately and never alters scores or the winner.
///
/// Saving to history is **explicit**: the user taps Save,
/// confirms the alert and the combat is recorded (snapshots of both teams,
/// mode, winner or tie, and the narration with its source) before returning
/// Home. No luck, affinity or intermediate calculations.
@MainActor
@Observable
final class CombatViewModel {
    let participants: BattleParticipants
    private(set) var result: CombatResult
    private(set) var narration: CombatNarrative?
    private(set) var isGeneratingNarration = false
    private(set) var isSaving = false
    private(set) var isSaved = false

    let narrationLanguage: NarrationLanguage

    private let generateNarration: GenerateCombatNarrationUseCase
    private let saveCombatHistory: SaveCombatHistoryUseCase
    private let timeProvider: any TimeProvider
    private let onSaved: (@MainActor () -> Void)?

    @ObservationIgnored private var narrationGeneration = 0

    init(
        participants: BattleParticipants,
        resolveCombat: ResolveCombatUseCase,
        generateNarration: GenerateCombatNarrationUseCase,
        narrationLanguage: NarrationLanguage,
        saveCombatHistory: SaveCombatHistoryUseCase,
        timeProvider: any TimeProvider = SystemTimeProvider(),
        onSaved: (@MainActor () -> Void)? = nil
    ) {
        self.participants = participants
        self.generateNarration = generateNarration
        self.narrationLanguage = narrationLanguage
        self.saveCombatHistory = saveCombatHistory
        self.timeProvider = timeProvider
        self.onSaved = onSaved
        result = resolveCombat.execute(participants: participants)
    }

    /// Recording requires the narration and its origin: Save is enabled only
    /// when the narration is published and the combat hasn't already been saved.
    var canSave: Bool {
        narration != nil && !isSaved && !isSaving
    }

    /// Is the narration published? It governs revealing the winner and the
    /// real scores: until then the screen keeps the suspense and the
    /// mathematical result remains immutable.
    var isNarrationPublished: Bool {
        narration != nil
    }

    /// Generates the narration once per result. Cancellation publishes nothing:
    /// the generation guard keeps a stale task from touching the state.
    func loadNarration() async {
        guard narration == nil else { return }

        narrationGeneration &+= 1
        let generation = narrationGeneration
        isGeneratingNarration = true

        do {
            let narrative = try await generateNarration.execute(
                result: result,
                participants: participants,
                language: narrationLanguage
            )
            guard narrationGeneration == generation else { return }
            narration = narrative
        } catch {
            // Cancellation or service failure: nothing to publish or save.
        }

        guard narrationGeneration == generation else { return }
        isGeneratingNarration = false
    }

    // MARK: - History

    /// Saves the combat to history after the user confirms and
    /// navigates back Home. A Realm failure is silent: the combat
    /// stays on screen and the user can retry.
    func save() async {
        guard let narration, !isSaved, !isSaving else { return }

        isSaving = true
        defer { isSaving = false }

        let record = CombatRecord(
            date: timeProvider.now,
            mode: result.mode,
            teamA: result.teamA.combatants.map(\.hero),
            teamB: result.teamB.combatants.map(\.hero),
            outcome: result.outcome,
            narration: narration.text,
            narrationSource: narration.source
        )

        do {
            try await saveCombatHistory.execute(record)
        } catch {
            // Silent failure: no navigation and no saved state.
            return
        }

        isSaved = true
        onSaved?()
    }
}
