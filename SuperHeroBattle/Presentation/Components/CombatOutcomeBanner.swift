import SwiftUI

/// Outcome banner shared by the live combat and saved battle detail
/// screens: winner with a Lottie slot, or a draw.
///
/// With `isRevealed == false` it shows the suspense variant instead of the
/// verdict, so the winner stays hidden until the narration is published.
/// The spring entrance of the reveal is disabled under Reduce Motion.
struct CombatOutcomeBanner: View {
    let outcome: CombatOutcome
    var isRevealed = true
    var suspenseKey: LocalizableStringKey = .combatOutcomePending
    var outcomeIdentifier = "combat.outcome"
    var pendingIdentifier = "combat.outcome.pending"

    @State private var isWinnerAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if isRevealed {
                revealedContent
                    // Subtle verdict entrance; no motion under Reduce Motion.
                    .scaleEffect(isWinnerAppeared ? 1 : 0.85)
                    .opacity(isWinnerAppeared ? 1 : 0)
            } else {
                suspenseContent
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            ComicPalette.midnight.opacity(0.86),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(strokeColor, lineWidth: 2)
        }
        .onAppear {
            if isRevealed {
                revealVerdict()
            }
        }
        .onChange(of: isRevealed) {
            if isRevealed {
                revealVerdict()
            }
        }
    }

    // MARK: - Verdict

    @ViewBuilder
    private var revealedContent: some View {
        switch outcome {
        case .winner(let side):
            VStack(spacing: 10) {
                // Lottie slot presenting the winner.
                ComicLottieView(
                    animationName: "combat_winner",
                    fallbackIcon: "trophy.fill",
                    loopMode: .playOnce
                )
                .frame(width: 60, height: 60)

                L10n.text(.combatResultWinner)
                    .font(ComicTypography.caption)
                    .foregroundStyle(ComicPalette.paper.opacity(0.75))

                L10n.text(side == .teamA ? .teamSelectionTeamA : .teamSelectionTeamB)
                    .font(ComicTypography.title)
                    .foregroundStyle(side == .teamA ? TeamPalette.teamA : TeamPalette.teamB)
                    .accessibilityIdentifier(outcomeIdentifier)
            }
        case .draw:
            VStack(spacing: 10) {
                Image(systemName: "equal.circle.fill")
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(ComicPalette.paper)
                    .accessibilityHidden(true)

                L10n.text(.combatResultDraw)
                    .font(ComicTypography.title)
                    .foregroundStyle(ComicPalette.paper)
                    .accessibilityIdentifier(outcomeIdentifier)
            }
        }
    }

    private var strokeColor: Color {
        switch (outcome, isRevealed) {
        case (.winner, true): ComicPalette.yellow
        case (.draw, true): ComicPalette.paper.opacity(0.35)
        case (_, false): ComicPalette.paper.opacity(0.35)
        }
    }

    // MARK: - Suspense

    /// Decorative mystery while the narration writes the outcome.
    private var suspenseContent: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(ComicPalette.yellow)
                    .frame(width: 58, height: 58)

                Text("?")
                    .font(ComicTypography.title)
                    .foregroundStyle(ComicPalette.ink)
            }
            .accessibilityHidden(true)

            L10n.text(suspenseKey)
                .font(ComicTypography.body)
                .foregroundStyle(ComicPalette.paper.opacity(0.8))
                .multilineTextAlignment(.center)
                .accessibilityIdentifier(pendingIdentifier)
        }
    }

    private func revealVerdict() {
        if reduceMotion {
            isWinnerAppeared = true
        } else {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                isWinnerAppeared = true
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CombatOutcomeBanner(outcome: .winner(.teamA), isRevealed: false)
        CombatOutcomeBanner(outcome: .winner(.teamA))
        CombatOutcomeBanner(outcome: .draw)
    }
    .padding(20)
    .background(ComicPalette.midnight)
    .preferredColorScheme(.dark)
}
