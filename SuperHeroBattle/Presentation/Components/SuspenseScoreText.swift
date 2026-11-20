import SwiftUI

/// Lógica del marcador en suspense, pura y testeable.
///
/// - `revealed`: se muestra la puntuación real.
/// - `cyclingMystery`: números aleatorios plausibles que rotan (normal).
/// - `staticMystery`: un único número aleatorio congelado (Reduce Motion).
nonisolated enum SuspenseScore {
    /// Rango plausible del total de un combatiente (base + suerte).
    static let combatantRange: ClosedRange<Double> = 12...140

    /// Cadencia de rotación del marcador en suspense: legible, sin estrobo.
    static let cyclingInterval: TimeInterval = 0.12

    /// Rango plausible del total de un equipo, escalado por su tamaño y
    /// holgado para absorber el feeling.
    static func teamRange(forTeamSize size: Int) -> ClosedRange<Double> {
        let count = Double(max(1, size))
        return 12 * count...(140 * count + 99)
    }

    static func decision(isRevealed: Bool, reduceMotion: Bool) -> Decision {
        if isRevealed {
            return .revealed
        }
        return reduceMotion ? .staticMystery : .cyclingMystery
    }

    /// Número aleatorio plausible dentro del rango pedido.
    static func randomMystery(in range: ClosedRange<Double>) -> Double {
        .random(in: range)
    }

    enum Decision: Equatable, Sendable {
        case revealed
        case cyclingMystery
        case staticMystery
    }
}

/// Puntuación en suspense: mientras la narración no está publicada muestra
/// números aleatorios plausibles; al revelarse muestra el valor real.
///
/// Reduce Motion congela un único número aleatorio. VoiceOver nunca
/// anuncia el número aleatorio: en suspense se lee la etiqueta de
/// puntuación pendiente y al revelarse la puntuación real.
struct SuspenseScoreText: View {
    let realValue: Double
    let isRevealed: Bool
    let range: ClosedRange<Double>
    let format: FloatingPointFormatStyle<Double>

    @State private var staticMystery: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.locale) private var locale

    private var decision: SuspenseScore.Decision {
        SuspenseScore.decision(isRevealed: isRevealed, reduceMotion: reduceMotion)
    }

    init(
        realValue: Double,
        isRevealed: Bool,
        range: ClosedRange<Double> = SuspenseScore.combatantRange,
        format: FloatingPointFormatStyle<Double> = .number.precision(.fractionLength(0...1))
    ) {
        self.realValue = realValue
        self.isRevealed = isRevealed
        self.range = range
        self.format = format
        _staticMystery = State(initialValue: SuspenseScore.randomMystery(in: range))
    }

    var body: some View {
        Group {
            switch decision {
            case .revealed:
                Text(realValue, format: format)

            case .cyclingMystery:
                TimelineView(.periodic(from: .now, by: SuspenseScore.cyclingInterval)) { _ in
                    Text(SuspenseScore.randomMystery(in: range), format: format)
                }

            case .staticMystery:
                Text(staticMystery, format: format)
            }
        }
        // En suspense VoiceOver anuncia el estado, nunca el número aleatorio.
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        isRevealed
            ? realValue.formatted(format)
            : L10n.string(.combatScorePending, locale: locale)
    }
}

#Preview {
    VStack(spacing: 16) {
        SuspenseScoreText(realValue: 87.5, isRevealed: false)
            .font(ComicTypography.headline)
        SuspenseScoreText(realValue: 87.5, isRevealed: true)
            .font(ComicTypography.headline)
    }
    .padding(20)
    .background(ComicPalette.midnight)
    .preferredColorScheme(.dark)
}
