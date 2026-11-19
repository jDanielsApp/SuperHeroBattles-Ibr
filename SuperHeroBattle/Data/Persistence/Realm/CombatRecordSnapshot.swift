import Foundation

/// Representación persistible y estable de `CombatRecord`.
///
/// Se guarda como JSON dentro de Realm para no acoplar el esquema a los
/// cambios de las entidades de dominio. `CombatOutcome` lleva valor asociado,
/// así que se descompone en `outcomeKind` y `winnerSide`.
nonisolated struct CombatRecordSnapshot: Codable, Sendable {
    let id: UUID
    let date: Date
    let mode: String
    let teamA: [HeroSnapshot]
    let teamB: [HeroSnapshot]
    let outcomeKind: String
    let winnerSide: String?
    let narration: String
    let narrationSource: String

    init(record: CombatRecord) {
        id = record.id
        date = record.date
        mode = record.mode.rawValue
        teamA = record.teamA
        teamB = record.teamB

        switch record.outcome {
        case .winner(let side):
            outcomeKind = "winner"
            winnerSide = side.rawValue
        case .draw:
            outcomeKind = "draw"
            winnerSide = nil
        }

        narration = record.narration
        narrationSource = record.narrationSource.rawValue
    }

    func makeRecord() -> CombatRecord {
        let outcome: CombatOutcome
        switch outcomeKind {
        case "winner":
            let side = winnerSide.flatMap(TeamSide.init(rawValue:)) ?? .teamA
            outcome = .winner(side)
        default:
            outcome = .draw
        }

        return CombatRecord(
            id: id,
            date: date,
            mode: CombatMode(rawValue: mode) ?? .oneVsOne,
            teamA: teamA,
            teamB: teamB,
            outcome: outcome,
            narration: narration,
            narrationSource: NarrativeSource(rawValue: narrationSource) ?? .template
        )
    }
}
