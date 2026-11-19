import Foundation

/// Mensajes presentables de la selección de equipos.
nonisolated enum TeamSelectionMessage: Equatable, Sendable {
    case duplicateHero
    case noHeroesAvailable
    case invalidSlot

    var messageKey: LocalizableStringKey {
        switch self {
        case .duplicateHero: .teamSelectionErrorDuplicate
        case .noHeroesAvailable: .teamSelectionErrorNoHeroes
        case .invalidSlot: .teamSelectionErrorInvalidSlot
        }
    }
}
