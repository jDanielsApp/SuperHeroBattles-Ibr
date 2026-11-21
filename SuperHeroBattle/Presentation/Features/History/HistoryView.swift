import SwiftUI

/// History of saved combats: a list with deletion from the detail and
/// full clearing.
struct HistoryView: View {
    @State private var viewModel: CombatHistoryViewModel
    @State private var isPresentingClearConfirmation = false

    @Environment(\.locale) private var locale

    init(viewModel: CombatHistoryViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            ComicBackground()

            content
        }
        .navigationTitle(L10n.localizedKey(.historyTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !viewModel.records.isEmpty {
                    Button {
                        isPresentingClearConfirmation = true
                    } label: {
                        Label(
                            L10n.localizedKey(.historyClear),
                            systemImage: "trash.circle"
                        )
                    }
                    .accessibilityIdentifier("history.clear")
                }
            }
        }
        .alert(
            L10n.localizedKey(.historyClearConfirmTitle),
            isPresented: $isPresentingClearConfirmation
        ) {
            Button(L10n.localizedKey(.historyClearConfirm), role: .destructive) {
                Task {
                    await viewModel.deleteAll()
                }
            }
            .accessibilityIdentifier("history.clear.confirm")

            Button(L10n.localizedKey(.commonCancel), role: .cancel) {}
            .accessibilityIdentifier("history.clear.cancel")
        } message: {
            L10n.text(.historyClearConfirmMessage)
        }
        .task {
            await viewModel.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.records.isEmpty {
            ComicLoadingView(
                textKey: .historyLoading,
                accessibilityKey: .historyLoading
            )
            .accessibilityIdentifier("history.loading")
        } else if viewModel.loadFailed {
            failureView
        } else if viewModel.isEmpty {
            emptyView
        } else {
            recordList
        }
    }

    private var emptyView: some View {
        ComicStatusView(
            systemImage: "clock.arrow.circlepath",
            titleKey: .historyEmptyTitle,
            messageKey: .historyEmptyMessage,
            accent: ComicPalette.blue
        )
        .accessibilityIdentifier("history.empty")
    }

    private var failureView: some View {
        ComicErrorView(
            titleKey: .historyFailureTitle,
            messageKey: .historyFailureMessage,
            retryIdentifier: "history.retry",
            retry: {
                Task {
                    await viewModel.retry()
                }
            }
        )
    }

    private var recordList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(viewModel.records) { record in
                    recordRow(record)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .comicReadableWidth()
        }
        .accessibilityIdentifier("history.list")
    }

    /// Full row: tapping the combat opens its detail, where individual
    /// deletion lives.
    private func recordRow(_ record: CombatRecord) -> some View {
        NavigationLink(value: AppRoute.combatRecord(record)) {
            recordRowContent(record)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("history.row")
    }

    private func recordRowContent(_ record: CombatRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(record.mode.rawValue)
                    .font(ComicTypography.caption)
                    .foregroundStyle(ComicPalette.ink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(ComicPalette.yellow, in: Capsule())

                outcomeText(record)
                    .font(ComicTypography.caption)
                    .foregroundStyle(ComicPalette.paper.opacity(0.8))

                Spacer(minLength: 0)

                Text(record.date, format: historyDateFormat)
                    .font(ComicTypography.caption)
                    .foregroundStyle(ComicPalette.paper.opacity(0.55))
            }

            HStack(spacing: 6) {
                Text(names(record.teamA))
                    .font(ComicTypography.headline)
                    .foregroundStyle(TeamPalette.teamA)
                    .lineLimit(1)

                L10n.text(.homeVersus)
                    .font(ComicTypography.caption)
                    .foregroundStyle(ComicPalette.paper.opacity(0.5))

                Text(names(record.teamB))
                    .font(ComicTypography.headline)
                    .foregroundStyle(TeamPalette.teamB)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ComicPalette.midnight.opacity(0.86))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ComicPalette.panelBorder, lineWidth: 2)
        }
        .accessibilityElement(children: .combine)
    }

    private func outcomeText(_ record: CombatRecord) -> some View {
        Text(HistoryOutcomeText.text(for: record.outcome, locale: locale))
            .font(ComicTypography.caption)
            .foregroundStyle(ComicPalette.paper.opacity(0.8))
    }

    private func names(_ snapshots: [HeroSnapshot]) -> String {
        let list = snapshots.map(\.name).joined(separator: ", ")
        return list.isEmpty ? "—" : list
    }

    private var historyDateFormat: Date.FormatStyle {
        .dateTime.day().month(.abbreviated).year().hour().minute()
    }
}

#Preview {
    NavigationStack {
        HistoryView(
            viewModel: CombatHistoryViewModel(
                getHistory: GetCombatHistoryUseCase(
                    repository: InMemoryCombatHistoryRepository()
                ),
                deleteHistory: DeleteCombatHistoryUseCase(
                    repository: InMemoryCombatHistoryRepository()
                )
            )
        )
    }
    .preferredColorScheme(.dark)
}
