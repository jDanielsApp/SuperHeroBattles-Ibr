import SwiftUI

/// Detalle de un combate guardado: equipos, resultado y narración persistida.
///
/// El borrado individual aparece aquí: el botón de la toolbar pide
/// confirmación con un alerta que nombra a ambos equipos y, tras borrar,
/// la vista vuelve al listado.
struct CombatRecordDetailView: View {
    @State private var viewModel: CombatRecordDetailViewModel
    @State private var isPresentingDeleteConfirmation = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// iPhone Duo abierto (o iPad): la narración va a la derecha del resto.
    private var isWideLayout: Bool {
        horizontalSizeClass == .regular
    }

    init(viewModel: CombatRecordDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            ComicBackground()

            if #available(iOS 27.1, *), isWideLayout {
                wideLayout
            } else {
                ScrollView {
                    CombatArrangementLayout(
                        leading: { restBlocks },
                        trailing: { narrationSection }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                }
            }
        }
        .navigationTitle(L10n.localizedKey(.historyDetailTitle))
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("history.detail")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingDeleteConfirmation = true
                } label: {
                    Label(L10n.localizedKey(.historyDelete), systemImage: "trash")
                }
                .disabled(!viewModel.canDelete)
                .accessibilityIdentifier("history.detail.delete")
                .accessibilityLabel(L10n.text(.historyDelete))
            }
        }
        .alert(
            L10n.localizedKey(.historyDeleteConfirmTitle),
            isPresented: $isPresentingDeleteConfirmation
        ) {
            Button(L10n.localizedKey(.historyDeleteConfirm), role: .destructive) {
                Task {
                    await viewModel.delete()
                    if viewModel.isDeleted {
                        dismiss()
                    }
                }
            }
            .accessibilityIdentifier("history.delete.confirm")

            Button(L10n.localizedKey(.commonCancel), role: .cancel) {}
            .accessibilityIdentifier("history.delete.cancel")
        } message: {
            Text(deletionMessage)
        }
    }

    // MARK: - Reparto de pantalla

    /// Pantalla interior del Duo: `ArrangementView` decide el eje con la
    /// geometría real —resto y narración lado a lado en horizontal, apilados
    /// en vertical— con scroll independiente por panel. Nunca dentro de un
    /// ScrollView común.
    @available(iOS 27.1, *)
    private var wideLayout: some View {
        ArrangementView {
            ScrollView {
                restBlocks
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
        } secondary: {
            ScrollView {
                narrationSection
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
        }
        .arrangementViewStyle(.split)
    }

    /// Bloques del registro: fecha, veredicto y equipos.
    private var restBlocks: some View {
        VStack(spacing: 18) {
            dateHeader

            CombatOutcomeBanner(
                outcome: viewModel.record.outcome,
                isRevealed: true,
                outcomeIdentifier: "history.detail.outcome"
            )

            teamSection(.teamA, snapshots: viewModel.record.teamA)

            ComicVersusDivider()

            teamSection(.teamB, snapshots: viewModel.record.teamB)
        }
    }

    // MARK: - Borrado

    /// Mensaje del alerta con los equipos del combate.
    private var deletionMessage: String {
        String(
            format: L10n.string(.historyDeleteConfirmMessage, locale: locale),
            names(viewModel.record.teamA),
            names(viewModel.record.teamB)
        )
    }

    private func names(_ snapshots: [HeroSnapshot]) -> String {
        let list = snapshots.map(\.name).joined(separator: ", ")
        return list.isEmpty ? "—" : list
    }

    // MARK: - Contenido

    private var dateHeader: some View {
        Text(viewModel.record.date, format: .dateTime.day().month(.abbreviated).year().hour().minute())
            .font(ComicTypography.body)
            .foregroundStyle(ComicPalette.paper.opacity(0.7))
            .frame(maxWidth: .infinity)
    }

    private func teamSection(_ side: TeamSide, snapshots: [HeroSnapshot]) -> some View {
        let accent = side == .teamA ? TeamPalette.teamA : TeamPalette.teamB

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(accent)
                    .frame(width: 14, height: 14)
                    .accessibilityHidden(true)

                L10n.text(side == .teamA ? .teamSelectionTeamA : .teamSelectionTeamB)
                    .font(ComicTypography.headline)
                    .foregroundStyle(ComicPalette.paper)

                Spacer(minLength: 0)
            }

            VStack(spacing: 8) {
                ForEach(snapshots) { snapshot in
                    HStack(spacing: 12) {
                        HeroImageView(url: snapshot.imageURL, size: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(snapshot.name)
                                .font(ComicTypography.headline)
                                .foregroundStyle(ComicPalette.paper)
                                .lineLimit(1)

                            if let publisher = snapshot.publisher {
                                Text(publisher)
                                    .font(ComicTypography.caption)
                                    .foregroundStyle(accent)
                                    .lineLimit(1)
                            }
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(10)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(ComicPalette.ink.opacity(0.55))
                    }
                }
            }
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

    private var narrationSection: some View {
        CombatNarrationSection(
            narration: CombatNarrative(
                text: viewModel.record.narration,
                source: viewModel.record.narrationSource
            ),
            textIdentifier: "history.detail.narration",
            sourceIdentifier: "history.detail.narration.source"
        )
    }
}

#Preview {
    NavigationStack {
        CombatRecordDetailView(
            viewModel: CombatRecordDetailViewModel(
                record: CombatRecord(
                    date: Date(),
                    mode: .twoVsTwo,
                    teamA: Array(FixedRosterHeroRepository.roster.prefix(2)).map(HeroSnapshot.init(hero:)),
                    teamB: Array(FixedRosterHeroRepository.roster.dropFirst(2).prefix(2)).map(HeroSnapshot.init(hero:)),
                    outcome: .winner(.teamA),
                    narration: "Simulación ficticia: los equipos se enfrentan con todo.",
                    narrationSource: .template
                ),
                deleteHistory: DeleteCombatHistoryUseCase(
                    repository: InMemoryCombatHistoryRepository()
                )
            )
        )
    }
    .preferredColorScheme(.dark)
}
