import Foundation

/// Ejecuta el combate mediante el motor y devuelve el resultado trazable.
/// Síncrono y puro: la resolución no depende de la interfaz.
nonisolated struct ResolveCombatUseCase: Sendable {
    private let engine: CombatEngine

    init(engine: CombatEngine = CombatEngine()) {
        self.engine = engine
    }

    func execute(participants: BattleParticipants) -> CombatResult {
        engine.resolve(participants)
    }
}
