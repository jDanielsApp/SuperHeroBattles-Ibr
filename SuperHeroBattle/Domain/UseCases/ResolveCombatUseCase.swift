import Foundation

/// Runs the combat through the engine and returns the traceable result.
/// Synchronous and pure: resolution does not depend on the UI.
nonisolated struct ResolveCombatUseCase: Sendable {
    private let engine: CombatEngine

    init(engine: CombatEngine = CombatEngine()) {
        self.engine = engine
    }

    func execute(participants: BattleParticipants) -> CombatResult {
        engine.resolve(participants)
    }
}
