import Foundation

nonisolated enum AppRoute: Hashable {
    case characterGuide
    case duelMode
    case settings
    case teamSelection(CombatMode)
    case combat(BattleParticipants)
}
