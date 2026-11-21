import SwiftUI

/// Local filters applied to the heroes already loaded in the catalog.
struct HeroFilterBar: View {
    let publisherOptions: [String]
    let genderOptions: [String]
    let selectedPublisher: String?
    let selectedGender: String?
    let hasActiveFilters: Bool
    let onSelectPublisher: (String?) -> Void
    let onSelectGender: (String?) -> Void
    let onClear: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                menu(
                    title: .guideFiltersPublisher,
                    selection: selectedPublisher,
                    options: publisherOptions,
                    identifier: "guide.filter.publisher",
                    onSelect: onSelectPublisher
                )

                menu(
                    title: .guideFiltersGender,
                    selection: selectedGender,
                    options: genderOptions,
                    identifier: "guide.filter.gender",
                    onSelect: onSelectGender
                )

                if hasActiveFilters {
                    Button(action: onClear) {
                        Label(
                            L10n.localizedKey(.guideFiltersClear),
                            systemImage: "xmark.circle.fill"
                        )
                        .font(ComicTypography.caption)
                        .foregroundStyle(ComicPalette.paper)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(ComicPalette.red.opacity(0.30), in: Capsule())
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityIdentifier("guide.filter.clear")
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func menu(
        title: LocalizableStringKey,
        selection: String?,
        options: [String],
        identifier: String,
        onSelect: @escaping (String?) -> Void
    ) -> some View {
        Menu {
            Button {
                onSelect(nil)
            } label: {
                L10n.text(.guideFiltersAll)
            }

            ForEach(options, id: \.self) { option in
                Button {
                    onSelect(option)
                } label: {
                    if option == selection {
                        Label(option, systemImage: "checkmark")
                    } else {
                        Text(option)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                L10n.text(title)
                    .font(ComicTypography.caption)
                    .foregroundStyle(ComicPalette.paper.opacity(0.7))

                if let selection {
                    Text(selection)
                        .font(ComicTypography.caption)
                        .foregroundStyle(ComicPalette.paper)
                        .lineLimit(1)
                } else {
                    L10n.text(.guideFiltersAll)
                        .font(ComicTypography.caption)
                        .foregroundStyle(ComicPalette.paper)
                        .lineLimit(1)
                }

                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(ComicPalette.yellow)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                Capsule()
                    .fill(ComicPalette.ink.opacity(0.75))
            }
            .overlay {
                Capsule()
                    .stroke(
                        selection == nil
                            ? ComicPalette.paper.opacity(0.18)
                            : ComicPalette.yellow,
                        lineWidth: 1.5
                    )
            }
            .frame(minHeight: 44)
        }
        .frame(minHeight: 44)
        .accessibilityIdentifier(identifier)
        .disabled(options.isEmpty)
    }
}
