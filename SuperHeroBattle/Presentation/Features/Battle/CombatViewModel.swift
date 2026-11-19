import Foundation

/// Estado de la pantalla de combate. Resuelve una única vez al construirse:
/// el resultado es inmutable y la IA nunca lo modifica.
@MainActor
@Observable
final class CombatViewModel {
    let participants: BattleParticipants
    private(set) var result: CombatResult

    init(participants: BattleParticipants, resolveCombat: ResolveCombatUseCase) {
        self.participants = participants
        result = resolveCombat.execute(participants: participants)
    }
}
