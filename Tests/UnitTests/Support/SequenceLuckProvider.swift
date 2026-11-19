import Foundation
@testable import SuperHeroBattle

/// Proveedor de suerte con secuencia fija. Al agotarse repite el último valor.
///
/// Solo para tests: mantiene estado mutable sin bloqueo porque el motor de
/// combate lo consume de forma síncrona desde un único contexto.
final class SequenceLuckProvider: LuckProvider, @unchecked Sendable {
    private let values: [Int]
    private var index = 0

    init(_ values: [Int]) {
        self.values = values
    }

    func nextLuck() -> Int {
        guard !values.isEmpty else { return SystemLuckProvider.luckRange.lowerBound }
        let value = values[min(index, values.count - 1)]
        if index < values.count - 1 {
            index += 1
        }
        return value
    }
}
