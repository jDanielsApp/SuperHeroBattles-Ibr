import Foundation

/// Estado de la pantalla de combate. El resultado del motor es inmutable;
/// la narración se genera aparte y nunca altera puntuaciones ni ganador.
///
/// El guardado en el historial es **explícito**: el usuario pulsa Guardar,
/// confirma el alerta y el combate se registra (snapshots de ambos equipos,
/// modalidad, ganador o empate y narración con su origen) antes de volver a
/// Home. Sin suerte, feeling ni cálculos intermedios.
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

    /// El registro exige narración y su origen: Guardar se habilita solo
    /// cuando la narración está publicada y el combate no se guardó ya.
    var canSave: Bool {
        narration != nil && !isSaved && !isSaving
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
            // Cancelación o fallo del servicio: nada que publicar ni guardar.
        }

        guard narrationGeneration == generation else { return }
        isGeneratingNarration = false
    }

    // MARK: - Historial

    /// Guarda el combate en el historial tras la confirmación del usuario y
    /// navega de vuelta a Home. Un fallo de Realm es silencioso: el combate
    /// sigue en pantalla y el usuario puede reintentar.
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
            // Fallo silencioso: sin navegación ni estado guardado.
            return
        }

        isSaved = true
        onSaved?()
    }
}
