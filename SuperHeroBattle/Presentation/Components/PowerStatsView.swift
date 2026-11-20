import SwiftUI

/// PowerStats bars with an accessible numeric value.
struct PowerStatsView: View {
    let stats: PowerStats

    @Environment(\.locale) private var locale

    var body: some View {
        VStack(spacing: 10) {
            ForEach(PowerStatKind.allCases) { kind in
                statRow(kind)
            }
        }
    }

    private func statRow(_ kind: PowerStatKind) -> some View {
        let value = stats[kind]
        let fraction = Double(value ?? 0) / 100.0

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                L10n.text(kind.localizedKey)
                    .font(ComicTypography.caption)
                    .foregroundStyle(ComicPalette.paper.opacity(0.78))

                Spacer(minLength: 8)

                if let value {
                    Text(String(value))
                        .font(ComicTypography.caption)
                        .foregroundStyle(ComicPalette.yellow)
                } else {
                    L10n.text(.guideDetailUnknown)
                        .font(ComicTypography.caption)
                        .foregroundStyle(ComicPalette.paper.opacity(0.45))
                }
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(ComicPalette.paper.opacity(0.12))

                    Capsule()
                        .fill(value == nil ? ComicPalette.paper.opacity(0.10) : ComicPalette.yellow)
                        .frame(width: proxy.size.width * fraction)
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(for: kind, value: value))
    }

    private func accessibilityLabel(for kind: PowerStatKind, value: Int?) -> String {
        let title = L10n.string(kind.localizedKey, locale: locale)
        let valueText = value.map { String($0) } ?? L10n.string(.guideDetailUnknown, locale: locale)
        return "\(title): \(valueText)"
    }
}

private extension PowerStatKind {
    var localizedKey: LocalizableStringKey {
        switch self {
        case .intelligence: .powerStatIntelligence
        case .strength: .powerStatStrength
        case .speed: .powerStatSpeed
        case .durability: .powerStatDurability
        case .power: .powerStatPower
        case .combat: .powerStatCombat
        }
    }
}
