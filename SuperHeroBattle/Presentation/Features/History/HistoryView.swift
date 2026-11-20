import SwiftUI

/// History of saved combats: a list with deletion from the detail and
/// full clearing.
struct HistoryView: View {
    @State private var viewModel: CombatHistoryViewModel
    @State private var isPresentingClearConfirmation = false

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
            loadingView
        } else if viewModel.loadFailed {
            failureView
        } else if viewModel.isEmpty {
            emptyView
        } else {
            recordList
        }
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)

            ProgressView()
                .controlSize(.large)
                .tint(ComicPalette.yellow)

            L10n.text(.historyLoading)
                .font(ComicTypography.body)
                .foregroundStyle(ComicPalette.paper.opacity(0.78))

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.text(.historyLoading))
        .accessibilityIdentifier("history.loading")
    }

    private var emptyView: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)

            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 52, weight: .black))
                .foregroundStyle(ComicPalette.blue)
                .accessibilityHidden(true)

            L10n.text(.historyEmptyTitle)
                .font(ComicTypography.title)
                .foregroundStyle(ComicPalette.paper)
                .multilineTextAlignment(.center)

            L10n.text(.historyEmptyMessage)
                .font(ComicTypography.body)
                .foregroundStyle(ComicPalette.paper.opacity(0.72))
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("history.empty")
    }

    private var failureView: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 46, weight: .black))
                .foregroundStyle(ComicPalette.red)
                .accessibilityHidden(true)

            L10n.text(.historyFailureTitle)
                .font(ComicTypography.title)
                .foregroundStyle(ComicPalette.paper)
                .multilineTextAlignment(.center)

            L10n.text(.historyFailureMessage)
                .font(ComicTypography.body)
                .foregroundStyle(ComicPalette.paper.opacity(0.72))
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await viewModel.retry()
                }
            } label: {
                L10n.text(.searchErrorRetry)
                    .font(ComicTypography.headline)
                    .foregroundStyle(ComicPalette.ink)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(ComicPalette.yellow, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("history.retry")

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
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

    @ViewBuilder
    private func outcomeText(_ record: CombatRecord) -> some View {
        switch record.outcome {
        case .winner(let side):
            let teamName = L10n.string(
                side == .teamA ? .teamSelectionTeamA : .teamSelectionTeamB
            )
            Text(String(format: L10n.string(.historyWinner), teamName))
        case .draw:
            L10n.text(.combatResultDraw)
        }
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
