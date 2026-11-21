import SwiftUI

/// Explicit saving: the button enables once the narration is published
/// and asks for confirmation before recording the combat.
struct CombatSaveSection: View {
    let canSave: Bool
    let isBusy: Bool
    let onSave: () async -> Void

    @State private var isPresentingConfirmation = false

    var body: some View {
        Button {
            isPresentingConfirmation = true
        } label: {
            ComicCTALabel(
                titleKey: .combatSaveAction,
                systemImage: "tray.and.arrow.down.fill",
                isBusy: isBusy,
                isEmphasized: canSave
            )
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
        .accessibilityIdentifier("combat.save")
        .accessibilityHint(L10n.text(.combatSaveHint))
        .alert(
            L10n.localizedKey(.combatSaveConfirmTitle),
            isPresented: $isPresentingConfirmation
        ) {
            Button(L10n.localizedKey(.combatSaveConfirm)) {
                Task {
                    await onSave()
                }
            }
            .accessibilityIdentifier("combat.save.confirm")

            Button(L10n.localizedKey(.commonCancel), role: .cancel) {}
            .accessibilityIdentifier("combat.save.cancel")
        } message: {
            L10n.text(.combatSaveConfirmMessage)
        }
    }
}
