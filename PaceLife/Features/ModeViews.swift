import SwiftUI
import PaceLifeCore

struct ModesView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var add = false
    @State private var editing: LifeMode?
    @State private var deleting: LifeMode?
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            List {
                SaveErrorBanner()
                Section {
                    Button {
                        model.activateMode(nil)
                        if !model.saveFailed { dismiss() }
                    } label: {
                        HStack {
                            Text(model.text(.noMode))
                            Spacer()
                            if model.state.activeModeID == nil { Image(systemName: "checkmark") }
                        }
                    }
                    ForEach(model.state.modes) { mode in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(mode.title).font(.headline)
                                Spacer()
                                if model.state.activeModeID == mode.id { Image(systemName: "checkmark.circle.fill").foregroundStyle(PaceColor.accent) }
                            }
                            Text(model.number(Double(mode.habitIDs.count)) + " " + model.text(.habits))
                                .font(.footnote).foregroundStyle(PaceColor.textSecondary)
                            Button(model.text(.activate)) {
                                model.activateMode(mode.id)
                                if !model.saveFailed { dismiss() }
                            }.accessibilityIdentifier("mode.activate." + mode.title)
                            HStack {
                                Button(model.text(.edit)) { editing = mode }
                                Spacer()
                                Button(model.text(.deleteMode), role: .destructive) { deleting = mode; confirmDelete = true }
                            }.font(.callout)
                        }.padding(.vertical, 8).buttonStyle(.borderless)
                    }
                } footer: { Text(model.text(.modeNote)) }
            }
            .scrollContentBackground(.hidden).background(PaceColor.background)
            .navigationTitle(model.text(.modes)).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(model.text(.done)) { dismiss() }.accessibilityIdentifier("closeModes") }
                ToolbarItem(placement: .primaryAction) {
                    Button { add = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel(model.text(.newMode)).accessibilityIdentifier("addMode")
                }
            }
            .sheet(isPresented: $add) { ModeEditor() }
            .sheet(item: $editing) { ModeEditor(existing: $0) }
            .confirmationDialog(model.text(.deleteMode), isPresented: $confirmDelete, titleVisibility: .visible) {
                Button(model.text(.deleteMode), role: .destructive) { if let mode = deleting { _ = model.deleteMode(mode) }; deleting = nil }
                Button(model.text(.cancel), role: .cancel) { deleting = nil }
            } message: { Text(model.text(.deleteModeMessage)) }
        }
    }
}

struct ModeEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let existing: LifeMode?
    @State private var title: String
    @State private var habitIDs: Set<UUID>

    init(existing: LifeMode? = nil) {
        self.existing = existing
        _title = State(initialValue: existing?.title ?? "")
        _habitIDs = State(initialValue: existing?.habitIDs ?? [])
    }
    var body: some View {
        NavigationStack {
            Form {
                SaveErrorBanner()
                Section(model.text(.name)) {
                    TextField(model.text(.name), text: $title).textInputAutocapitalization(.sentences).accessibilityIdentifier("modeTitle")
                }
                Section {
                    ForEach(model.activeHabits) { habit in
                        Toggle(habit.title, isOn: Binding(get: { habitIDs.contains(habit.id) }, set: { enabled in
                            if enabled { habitIDs.insert(habit.id) } else { habitIDs.remove(habit.id) }
                        })).accessibilityIdentifier("mode.habit." + habit.title)
                    }
                    if model.activeHabits.isEmpty { Text(model.text(.noHabits)).foregroundStyle(PaceColor.textSecondary) }
                } header: { Text(model.text(.selectedHabits)) } footer: { Text(model.text(.emptyMode)) }
            }
            .scrollContentBackground(.hidden).background(PaceColor.background)
            .navigationTitle(model.text(existing == nil ? .newMode : .editMode)).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(model.text(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(model.text(.save)) {
                        var mode = existing ?? LifeMode(title: title)
                        mode.title = title.trimmingCharacters(in: .whitespacesAndNewlines); mode.habitIDs = habitIDs
                        if model.saveMode(mode) { dismiss() }
                    }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("saveMode")
                }
            }
        }
    }
}
