import SwiftUI

/// Pure, testable logic for the suspense scoreboard.
///
/// - `revealed`: the real score is shown.
/// - `cyclingMystery`: plausible random numbers rotating (default).
/// - `staticMystery`: a single frozen random number (Reduce Motion).
nonisolated enum SuspenseScore {
    /// Plausible range for a combatant's total (base + luck).
    static let combatantRange: ClosedRange<Double> = 12...140

    /// Rotation cadence for the suspense scoreboard: readable, no strobing.
    static let cyclingInterval: TimeInterval = 0.12

    /// Plausible range for a team's total, scaled by its size and
    /// generous enough to absorb the feeling.
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

    /// Plausible random number within the requested range.
    static func randomMystery(in range: ClosedRange<Double>) -> Double {
        .random(in: range)
    }

    enum Decision: Equatable, Sendable {
        case revealed
        case cyclingMystery
        case staticMystery
    }
}

/// Suspense score: while the narration is not yet published it shows
/// plausible random numbers; once revealed it shows the real value.
///
/// Reduce Motion freezes a single random number. VoiceOver never
/// announces the random number: while in suspense the pending score
/// label is read, and the real score once revealed.
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
        // While in suspense, VoiceOver announces the state, never the random number.
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
