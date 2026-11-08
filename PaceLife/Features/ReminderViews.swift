import SwiftUI
import UIKit
import UniformTypeIdentifiers
import PaceLifeCore

/// Reminder card embedded in habit and routine details.
struct ReminderSection: View {
    @Environment(AppModel.self) private var model
    let target: ReminderTarget
    let defaultWeekdays: Set<Int>
    @State private var editing: ReminderDraft?

    var body: some View {
        let items = model.reminders(for: target)
        PaceCard {
            VStack(alignment: .leading, spacing: PaceSpacing.s) {
                PaceCardHeader(title: model.feature(.reminders), systemImage: "bell") {
                    Button { editing = ReminderDraft(target: target, weekdays: defaultWeekdays) } label: { PaceSquareIcon(systemImage: "plus") }
                        .buttonStyle(.plain).accessibilityLabel(model.feature(.addReminder)).accessibilityIdentifier("reminder.add")
                }
                if items.isEmpty {
                    Text(model.feature(.reminderNote)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
                }
                ForEach(items) { reminder in ReminderRow(reminder: reminder) { editing = ReminderDraft(reminder) } }
                if model.notificationsDenied { DeniedNotice() }
            }
        }
        .sheet(item: $editing) { ReminderEditor(draft: $0) }
    }
}

struct ReminderRow: View {
    @Environment(AppModel.self) private var model
    let reminder: Reminder
    var showsTarget = false
    let edit: () -> Void

    var body: some View {
        PaceTile {
            HStack(spacing: PaceSpacing.s) {
                Button(action: edit) {
                    VStack(alignment: .leading, spacing: 2) {
                        if showsTarget { Text(model.reminderTitle(reminder.target)).font(.subheadline.weight(.semibold)).foregroundStyle(PaceColor.textPrimary) }
                        Text(model.timeLabel(minute: reminder.minute)).font(.title3.weight(.bold)).monospacedDigit().foregroundStyle(PaceColor.textPrimary)
                        Text(model.weekdaysLabel(reminder.weekdays)).font(.caption).foregroundStyle(PaceColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint(model.feature(.editReminder))
                Toggle(model.feature(.enabled), isOn: Binding(get: { reminder.isEnabled }, set: { enabled in
                    var updated = reminder; updated.isEnabled = enabled
                    Task { _ = await model.saveReminder(updated) }
                }))
                .labelsHidden()
                .tint(PaceColor.accentStrong)
                .accessibilityLabel(model.feature(.reminder) + " " + model.timeLabel(minute: reminder.minute))
            }
            .padding(.vertical, 2)
        }
    }
}

private struct DeniedNotice: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    var body: some View {
        VStack(alignment: .leading, spacing: PaceSpacing.xs) {
            Label(model.feature(.notificationsDenied), systemImage: "bell.slash").font(.footnote).foregroundStyle(PaceColor.warning)
            Button(model.feature(.openSettings)) {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
            .buttonStyle(PaceLinkButtonStyle())
        }
    }
}

struct ReminderDraft: Identifiable {
    let id: UUID
    let target: ReminderTarget
    var minute: Int
    var weekdays: Set<Int>
    var isEnabled: Bool
    let isExisting: Bool
    init(target: ReminderTarget, weekdays: Set<Int>) {
        id = UUID(); self.target = target; minute = 8 * 60; self.weekdays = weekdays.isEmpty ? Set(1...7) : weekdays
        isEnabled = true; isExisting = false
    }
    init(_ reminder: Reminder) {
        id = reminder.id; target = reminder.target; minute = reminder.minute; weekdays = reminder.weekdays
        isEnabled = reminder.isEnabled; isExisting = true
    }
}

struct ReminderEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State var draft: ReminderDraft
    @State private var saving = false

    var body: some View {
        NavigationStack {
            Form {
                SaveErrorBanner()
                Section(model.reminderTitle(draft.target)) {
                    DatePicker(model.feature(.time), selection: Binding(get: { date(for: draft.minute) }, set: { draft.minute = minute(of: $0) }),
                               displayedComponents: .hourAndMinute)
                        .accessibilityIdentifier("reminder.time")
                    Toggle(model.feature(.enabled), isOn: $draft.isEnabled).tint(PaceColor.accentStrong)
                }
                Section {
                    PaceWeekdayPicker(selection: $draft.weekdays, identifierPrefix: "reminder.weekday")
                } header: { Text(model.text(.frequency)) } footer: { Text(model.feature(.reminderLimit)) }
                if model.notificationsDenied { Section { DeniedNotice() } }
                Section { Text(model.feature(.reminderNote)).font(.footnote).foregroundStyle(PaceColor.textSecondary) }
                if draft.isExisting {
                    Section {
                        Button(model.feature(.deleteReminder), role: .destructive) { if model.deleteReminder(draft.id) { dismiss() } }
                            .accessibilityIdentifier("reminder.delete")
                    }
                }
            }
            .paceFormStyle()
            .navigationTitle(model.feature(draft.isExisting ? .editReminder : .addReminder)).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(model.text(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(model.text(.save)) {
                        saving = true
                        let reminder = Reminder(id: draft.id, target: draft.target, minute: draft.minute, weekdays: draft.weekdays, isEnabled: draft.isEnabled)
                        Task {
                            let saved = await model.saveReminder(reminder)
                            saving = false
                            if saved { dismiss() }
                        }
                    }
                    .disabled(draft.weekdays.isEmpty || saving)
                    .accessibilityIdentifier("reminder.save")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func date(for minute: Int) -> Date {
        Calendar.current.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: Date()) ?? Date()
    }
    private func minute(of date: Date) -> Int {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }
}

/// All reminders across habits and routines (Profile → Erinnerungen).
struct RemindersView: View {
    @Environment(AppModel.self) private var model
    @State private var editing: ReminderDraft?

    var body: some View {
        let reminders = model.state.reminders.sorted { $0.minute < $1.minute }
        PaceSubpage(title: model.feature(.reminders), subtitle: model.feature(.remindersDetail)) {
            if reminders.isEmpty {
                PaceCard { PaceEmptyState(systemImage: "bell", title: model.feature(.reminders), message: model.feature(.remindersEmpty)) }
            }
            ForEach(reminders) { reminder in
                ReminderRow(reminder: reminder, showsTarget: true) { editing = ReminderDraft(reminder) }
            }
            if model.notificationsDenied { PaceCard { DeniedNotice() } }
            Text(model.feature(.reminderNote)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
            Text(model.feature(.reminderLimit)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
        }
        .sheet(item: $editing) { ReminderEditor(draft: $0) }
    }
}

/// A validated, current-schema JSON backup.
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    let data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        self.data = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

struct BackupView: View {
    @Environment(AppModel.self) private var model
    @State private var exporting = false
    @State private var document: BackupDocument?
    @State private var importing = false
    @State private var pending: LifeState?
    @State private var confirmRestore = false
    @State private var message: String?

    var body: some View {
        PaceSubpage(title: model.feature(.backup), subtitle: model.text(.privacyDetail)) {
            PaceCard {
                VStack(alignment: .leading, spacing: PaceSpacing.s) {
                    PaceCardHeader(title: model.feature(.exportData), systemImage: "square.and.arrow.up", chevron: false)
                    Text(model.feature(.exportNote)).font(.subheadline).foregroundStyle(PaceColor.textSecondary)
                    Button(model.feature(.exportData)) {
                        if let data = model.exportDocument() { document = BackupDocument(data: data); exporting = true }
                        else { message = model.feature(.exportFailed) }
                    }
                    .buttonStyle(PaceButtonStyle())
                    .accessibilityIdentifier("backup.export")
                }
            }
            PaceCard {
                VStack(alignment: .leading, spacing: PaceSpacing.s) {
                    PaceCardHeader(title: model.feature(.importData), systemImage: "arrow.counterclockwise", chevron: false)
                    Text(model.feature(.importNote)).font(.subheadline).foregroundStyle(PaceColor.textSecondary)
                    Button(model.feature(.importData)) { importing = true }
                        .buttonStyle(PaceButtonStyle(kind: .secondary))
                        .accessibilityIdentifier("backup.import")
                }
            }
            if let message {
                Text(message).font(.subheadline.weight(.semibold)).foregroundStyle(PaceColor.textPrimary)
                    .accessibilityIdentifier("backup.message")
            }
        }
        .fileExporter(isPresented: $exporting, document: document, contentType: .json, defaultFilename: defaultFilename) { result in
            if case .failure = result { message = model.feature(.exportFailed) }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            guard case .success(let url) = result else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            if let data = try? Data(contentsOf: url), let backup = model.decodeBackup(data) {
                pending = backup; confirmRestore = true
            } else {
                message = model.feature(.restoreFailed)
            }
        }
        .confirmationDialog(model.feature(.restoreTitle), isPresented: $confirmRestore, titleVisibility: .visible) {
            Button(model.feature(.restoreConfirm), role: .destructive) {
                if let pending, model.restore(pending) { message = model.feature(.restoreDone) }
                pending = nil
            }
            Button(model.text(.cancel), role: .cancel) { pending = nil }
        } message: {
            Text(model.feature(.restoreMessage, pending.map { model.backupSummary($0) } ?? ""))
        }
    }

    private var defaultFilename: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX"); formatter.dateFormat = "yyyy-MM-dd"
        return "PaceLife-Backup-" + formatter.string(from: model.today)
    }
}
