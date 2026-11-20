import SwiftUI

/// Explicit search bar: button and Return key. It does not fire a request per keystroke.
struct HeroSearchBar: View {
    @Binding var query: String
    let canSubmit: Bool
    let isLoading: Bool
    let onSubmit: () -> Void
    let onClear: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.headline.weight(.bold))
                .foregroundStyle(ComicPalette.paper.opacity(0.7))
                .accessibilityHidden(true)

            TextField(L10n.localizedKey(.searchPlaceholder), text: $query)
                .font(ComicTypography.body)
                .foregroundStyle(ComicPalette.paper)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($isFocused)
                .onSubmit {
                    isFocused = false
                    onSubmit()
                }
                .accessibilityLabel(L10n.text(.accessibilitySearchField))
                .accessibilityIdentifier("search.field")

            if !query.isEmpty {
                Button {
                    onClear()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(ComicPalette.paper.opacity(0.65))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.text(.accessibilitySearchClear))
                .accessibilityIdentifier("search.clear")
            }

            Button {
                isFocused = false
                onSubmit()
            } label: {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.title2)
                    .foregroundStyle(canSubmit ? ComicPalette.yellow : ComicPalette.paper.opacity(0.35))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
            .accessibilityLabel(L10n.text(.accessibilitySearchSubmit))
            .accessibilityIdentifier("search.submit")
        }
        .padding(.leading, 14)
        .padding(.trailing, 4)
        .padding(.vertical, 4)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ComicPalette.ink.opacity(0.78))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ComicPalette.panelBorder, lineWidth: 2)
        }
        .opacity(isLoading ? 0.9 : 1)
    }
}
