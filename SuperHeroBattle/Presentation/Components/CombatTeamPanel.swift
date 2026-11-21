import SwiftUI

/// One team's combat panel: total in suspense until the narration is
/// published, combatants with their base/luck/total line, and the
/// affinity bonuses when the team has matches.
///
/// The score format binds to the environment locale so every visible
/// and spoken number shares the app's decimal separator.
struct CombatTeamPanel: View {
    let summary: TeamCombatSummary
    /// Whether the narration is published: the real scores stay hidden
    /// until then.
    let isRevealed: Bool
    /// Team size, to scale the suspense range of the team total.
    let teamSize: Int

    @Environment(\.locale) private var locale

    private var accent: Color {
        summary.side == .teamA ? TeamPalette.teamA : TeamPalette.teamB
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow

            VStack(spacing: 8) {
                ForEach(summary.combatants) { score in
                    combatantRow(score)
                }
            }

            affinitySection
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(ComicPalette.midnight.opacity(0.86))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(accent.opacity(0.45), lineWidth: 2)
        }
    }

    private var headerRow: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(accent)
                .frame(width: 14, height: 14)
                .accessibilityHidden(true)

            L10n.text(summary.side == .teamA ? .teamSelectionTeamA : .teamSelectionTeamB)
                .font(ComicTypography.headline)
                .foregroundStyle(ComicPalette.paper)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 8)

            SuspenseScoreText(
                realValue: summary.totalScore,
                isRevealed: isRevealed,
                range: SuspenseScore.teamRange(forTeamSize: teamSize),
                format: scoreFormat
            )
            .font(ComicTypography.headline)
            .foregroundStyle(ComicPalette.yellow)
            .accessibilityIdentifier("combat.total.\(summary.side.rawValue)")
        }
        .accessibilityElement(children: .combine)
    }

    private func combatantRow(_ score: CombatantScore) -> some View {
        HStack(spacing: 12) {
            HeroImageView(url: score.hero.imageURL, size: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(score.hero.name)
                    .font(ComicTypography.headline)
                    .foregroundStyle(ComicPalette.paper)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    statCaption(.combatResultBase, value: score.baseScore.formatted(scoreFormat))
                    statDivider
                    statCaption(.combatResultLuck, value: String(score.luck))
                    statDivider
                    statTotalCaption(score)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(ComicPalette.ink.opacity(0.55))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(ComicPalette.paper.opacity(0.12), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(combatantAccessibilityLabel(score))
        .accessibilityIdentifier("combat.combatant.\(summary.side.rawValue)-\(score.hero.id)")
    }

    // MARK: - Affinity

    /// The affinity section only appears when the team has bonuses; a team
    /// without matches (and 1v1, with no pairs) doesn't show it.
    @ViewBuilder
    private var affinitySection: some View {
        if !summary.affinityBonuses.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                L10n.text(.combatResultAffinity)
                    .font(ComicTypography.caption)
                    .foregroundStyle(ComicPalette.paper.opacity(0.55))

                ForEach(summary.affinityBonuses) { bonus in
                    affinityRow(bonus)
                }
            }
        }
    }

    private func affinityRow(_ bonus: AffinityBonus) -> some View {
        let firstName = summary.combatants.first { $0.hero.id == bonus.heroAID }?.hero.name ?? bonus.heroAID
        let secondName = summary.combatants.first { $0.hero.id == bonus.heroBID }?.hero.name ?? bonus.heroBID

        return VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("\(firstName) + \(secondName)")
                    .font(ComicTypography.caption)
                    .foregroundStyle(ComicPalette.paper)
                    .lineLimit(1)

                Spacer(minLength: 6)

                Text("+\(bonus.bonus)")
                    .font(ComicTypography.caption)
                    .foregroundStyle(ComicPalette.yellow)
            }

            if !bonus.matchedAffiliations.isEmpty {
                Text(bonus.matchedAffiliations.joined(separator: ", "))
                    .font(ComicTypography.caption)
                    .foregroundStyle(ComicPalette.paper.opacity(0.5))
                    .lineLimit(1)
            }

            if !bonus.matchedRelatives.isEmpty {
                Text(bonus.matchedRelatives.joined(separator: ", "))
                    .font(ComicTypography.caption)
                    .foregroundStyle(ComicPalette.paper.opacity(0.5))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ComicPalette.blue.opacity(0.16))
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Style details

    private var statDivider: some View {
        Text("·")
            .font(ComicTypography.caption)
            .foregroundStyle(ComicPalette.paper.opacity(0.35))
    }

    private func statCaption(_ key: LocalizableStringKey, value: String) -> some View {
        HStack(spacing: 3) {
            L10n.text(key)
                .font(ComicTypography.caption)
                .foregroundStyle(ComicPalette.paper.opacity(0.55))

            Text(value)
                .font(ComicTypography.caption)
                .foregroundStyle(ComicPalette.paper.opacity(0.8))
        }
    }

    /// Combatant total: kept in suspense until the narration is published.
    private func statTotalCaption(_ score: CombatantScore) -> some View {
        HStack(spacing: 3) {
            L10n.text(.combatResultTotal)
                .font(ComicTypography.caption)
                .foregroundStyle(ComicPalette.paper.opacity(0.55))

            SuspenseScoreText(
                realValue: score.totalScore,
                isRevealed: isRevealed,
                format: scoreFormat
            )
            .font(ComicTypography.caption)
            .foregroundStyle(ComicPalette.paper.opacity(0.8))
        }
    }

    /// Score format bound to the app locale: every visible and spoken
    /// number on this screen shares the same decimal separator.
    private var scoreFormat: FloatingPointFormatStyle<Double> {
        .number.precision(.fractionLength(0...1)).locale(locale)
    }

    private func combatantAccessibilityLabel(_ score: CombatantScore) -> String {
        let base = L10n.string(.combatResultBase, locale: locale)
        let luck = L10n.string(.combatResultLuck, locale: locale)
        let total = L10n.string(.combatResultTotal, locale: locale)

        // While in suspense the real total is not announced: the scoreboard is
        // pending narration and the visible number is random.
        let totalDescription = isRevealed
            ? score.totalScore.formatted(scoreFormat)
            : L10n.string(.combatScorePending, locale: locale)

        return "\(score.hero.name): \(base) \(score.baseScore.formatted(scoreFormat)), "
            + "\(luck) \(score.luck), \(total) \(totalDescription)"
    }
}
