import Foundation

/// Estado de la pantalla de combate. El resultado del motor es inmutable;
/// la narración se genera aparte y nunca altera puntuaciones ni ganador.
@MainActor
@Observable
final class CombatViewModel {
    let participants: BattleParticipants
    private(set) var result: CombatResult
    private(set) var narration: CombatNarrative?
    private(set) var isGeneratingNarration = false

    let narrationLanguage: NarrationLanguage

    private let generateNarration: GenerateCombatNarrationUseCase

    @ObservationIgnored private var narrationGeneration = 0

    init(
        participants: BattleParticipants,
        resolveCombat: ResolveCombatUseCase,
        generateNarration: GenerateCombatNarrationUseCase,
        narrationLanguage: NarrationLanguage
    ) {
        self.participants = participants
        self.generateNarration = generateNarration
        self.narrationLanguage = narrationLanguage
        result = resolveCombat.execute(participants: participants)
    }

    /// Genera la narración una vez por resultado. La cancelación no publica:
    /// la guarda de generación evita que una tarea antigua toque el estado.
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
            // Cancelación o fallo del servicio: nada que publicar. La UI
            // mantiene el resultado matemático y oculta el indicador.
        }

        guard narrationGeneration == generation else { return }
        isGeneratingNarration = false
    }
}
