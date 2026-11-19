import Foundation

/// Fuente de suerte de cada combatiente. Inyectable para pruebas deterministas:
/// la suerte es la única aleatoriedad del motor de combate.
nonisolated protocol LuckProvider: Sendable {
    /// Tirada de suerte en el rango cerrado 7...77.
    func nextLuck() -> Int
}

/// Suerte del sistema. Usa el RNG global de Swift, que es seguro entre hilos.
nonisolated struct SystemLuckProvider: LuckProvider {
    static let luckRange: ClosedRange<Int> = 7...77

    init() {}

    func nextLuck() -> Int {
        Int.random(in: Self.luckRange)
    }
}
