import SwiftUI

/// Narration section shared by the live combat and saved battle detail
/// screens: title, source badge, and published text.
///
/// In live combat, `isLoading` shows the generation indicator while the
/// narration is not yet available; the history detail passes the
/// persisted text directly.
struct CombatNarrationSection: View {
    let narration: CombatNarrative?
    var isLoading = false
    var textIdentifier = "combat.narration"
    var loadingIdentifier = "combat.narration.loading"
    var sourceIdentifier = "combat.narration.source"

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            L10n.text(.combatNarrationTitle)
                .font(ComicTypography.headline)
                .foregroundStyle(ComicPalette.yellow)
                .accessibilityAddTraits(.isHeader)

            if let narration {
                sourceBadge(narration.source)

                Text(narration.text)
                    .font(ComicTypography.body)
                    .foregroundStyle(ComicPalette.paper.opacity(0.9))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(textIdentifier)
            } else if isLoading {
                loadingRow
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(ComicPalette.midnight.opacity(0.86))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(ComicPalette.paper.opacity(0.18), lineWidth: 2)
        }
    }

    // MARK: - Loading

    private var loadingRow: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(ComicPalette.yellow)

            L10n.text(.combatNarrationLoading)
                .font(ComicTypography.body)
                .foregroundStyle(ComicPalette.paper.opacity(0.7))
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.text(.combatNarrationLoading))
        .accessibilityIdentifier(loadingIdentifier)
    }

    // MARK: - Source

    @ViewBuilder
    private func sourceBadge(_ source: NarrativeSource) -> some View {
        let key: LocalizableStringKey = source == .foundationModels
            ? .combatNarrationSourceFoundationModels
            : .combatNarrationSourceTemplate
        let accent: Color = source == .foundationModels
            ? ComicPalette.yellow
            : ComicPalette.blue

        L10n.text(key)
            .font(ComicTypography.caption)
            .foregroundStyle(ComicPalette.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(accent, in: Capsule())
            .accessibilityIdentifier(sourceIdentifier)
    }
}

#Preview {
    VStack(spacing: 20) {
        CombatNarrationSection(
            narration: CombatNarrative(
                text: "Simulación ficticia: los equipos se enfrentan con todo.",
                source: .template
            )
        )
        CombatNarrationSection(narration: nil, isLoading: true)
    }
    .padding(20)
    .background(ComicPalette.midnight)
    .preferredColorScheme(.dark)
}
