import SwiftUI
import PaceLifeCore

struct ModesView: View {
    @Environment(AppModel.self) private var model
    @State private var add = false
    @State private var editing: LifeMode?
    @State private var deleting: LifeMode?
    @State private var confirmDelete = false

    var body: some View {
        PaceSubpage(title: model.text(.modes), subtitle: model.feature(.scheduleRule)) {
            Button { add = true } label: { PaceSquareIcon(systemImage: "plus") }
                .buttonStyle(.plain).accessibilityLabel(model.text(.newMode)).accessibilityIdentifier("addMode")
        } content: {
            Button { model.activateMode(nil) } label: {
                modeRow(title: model.text(.noMode), detail: model.number(Double(model.activeHabits.count)) + " " + model.text(.habits),
                        active: model.state.activeModeID == nil)
            }
            .buttonStyle(.plain).accessibilityIdentifier("mode.all")
            ForEach(model.state.modes) { mode in
                let active = model.state.activeModeID == mode.id
                PaceCard {
                    VStack(alignment: .leading, spacing: PaceSpacing.s) {
                        HStack(alignment: .center, spacing: PaceSpacing.s) {
                            Image(systemName: "circle.hexagongrid.fill")
                                .font(.title3).foregroundStyle(active ? PaceColor.onSelection : PaceColor.accentStrong)
                                .frame(width: 40, height: 40)
                                .background(active ? PaceColor.selectionFill : PaceColor.accentSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.title).font(.headline)
                                Text(model.modeSummary(mode)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
                                Label(mode.scheduledWeekdays.map { $0.isEmpty ? model.feature(.manualOnly) : model.feature(.scheduledOn, model.weekdaysLabel($0)) } ?? model.feature(.manualOnly),
                                      systemImage: mode.scheduledWeekdays?.isEmpty == false ? "calendar.badge.clock" : "hand.tap")
                                    .font(.caption).foregroundStyle(PaceColor.accentStrong)
                            }
                            Spacer(minLength: PaceSpacing.xs)
                            if active { PaceBadge(text: model.pathText(.active), systemImage: "checkmark") }
                        }
                        HStack(spacing: PaceSpacing.xs) {
                            if !active {
                                Button(model.text(.activate)) { model.activateMode(mode.id) }
                                    .buttonStyle(PaceCompactButtonStyle())
                                    .accessibilityIdentifier("mode.activate." + mode.title)
                            }
                            Button(model.text(.edit)) { editing = mode }.buttonStyle(PaceCompactButtonStyle(prominent: false))
                            Spacer(minLength: 0)
                            Button(role: .destructive) { deleting = mode; confirmDelete = true } label: {
                                Image(systemName: "trash").frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain).foregroundStyle(PaceColor.danger)
                            .accessibilityLabel(model.text(.deleteMode))
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $add) { ModeEditor() }
        .sheet(item: $editing) { ModeEditor(existing: $0) }
        .confirmationDialog(model.text(.deleteMode), isPresented: $confirmDelete, titleVisibility: .visible) {
            Button(model.text(.deleteMode), role: .destructive) { if let mode = deleting { _ = model.deleteMode(mode) }; deleting = nil }
            Button(model.text(.cancel), role: .cancel) { deleting = nil }
        } message: { Text(model.text(.deleteModeMessage)) }
    }

    private func modeRow(title: String, detail: String, active: Bool) -> some View {
        PaceCard {
            HStack(spacing: PaceSpacing.s) {
                Image(systemName: "square.grid.2x2")
                    .font(.title3).foregroundStyle(active ? PaceColor.onSelection : PaceColor.accentStrong)
                    .frame(width: 40, height: 40)
                    .background(active ? PaceColor.selectionFill : PaceColor.accentSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(detail).font(.footnote).foregroundStyle(PaceColor.textSecondary)
                }
                Spacer()
                if active { PaceBadge(text: model.pathText(.active), systemImage: "checkmark") }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(active ? .isSelected : [])
    }
}

struct ModeEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let existing: LifeMode?
    @State private var title: String
    @State private var habitIDs: Set<UUID>
    @State private var schedule: Set<Int>
    @State private var priorities: [UUID]

    init(existing: LifeMode? = nil) {
        self.existing = existing
        _title = State(initialValue: existing?.title ?? "")
        _habitIDs = State(initialValue: existing?.habitIDs ?? [])
        _schedule = State(initialValue: existing?.scheduledWeekdays ?? [])
        _priorities = State(initialValue: existing?.priorityHabitIDs ?? [])
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
                        HStack(spacing: PaceSpacing.s) {
                            Toggle(habit.title, isOn: Binding(get: { habitIDs.contains(habit.id) }, set: { enabled in
                                if enabled { habitIDs.insert(habit.id) } else { habitIDs.remove(habit.id); priorities.removeAll { $0 == habit.id } }
                            }))
                            .tint(PaceColor.accentStrong)
                            .accessibilityIdentifier("mode.habit." + habit.title)
                            if habitIDs.contains(habit.id) {
                                let isPriority = priorities.contains(habit.id)
                                Button {
                                    if isPriority { priorities.removeAll { $0 == habit.id } }
                                    else if priorities.count < LifeMode.maximumPriorities { priorities.append(habit.id) }
                                } label: {
                                    Image(systemName: isPriority ? "star.fill" : "star")
                                        .foregroundStyle(isPriority ? PaceColor.streak : PaceColor.textSecondary)
                                        .frame(width: 44, height: 44)
                                }
                                .buttonStyle(.borderless)
                                .disabled(!isPriority && priorities.count >= LifeMode.maximumPriorities)
                                .accessibilityLabel(model.feature(.priority) + ": " + habit.title)
                                .accessibilityAddTraits(isPriority ? .isSelected : [])
                                .accessibilityIdentifier("mode.priority." + habit.title)
                            }
                        }
                    }
                    if model.activeHabits.isEmpty { Text(model.text(.noHabits)).foregroundStyle(PaceColor.textSecondary) }
                } header: { Text(model.text(.selectedHabits)) } footer: { Text(model.text(.emptyMode) + " " + model.feature(.priorityNote)) }
                Section {
                    PaceWeekdayPicker(selection: $schedule, identifierPrefix: "mode.schedule")
                } header: { Text(model.feature(.autoSchedule)) } footer: { Text(model.feature(.autoScheduleNote)) }
            }
            .paceFormStyle()
            .navigationTitle(model.text(existing == nil ? .newMode : .editMode)).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(model.text(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(model.text(.save)) {
                        var mode = existing ?? LifeMode(title: title)
                        mode.title = title.trimmingCharacters(in: .whitespacesAndNewlines); mode.habitIDs = habitIDs
                        mode.scheduledWeekdays = schedule.isEmpty ? nil : schedule
                        mode.priorityHabitIDs = priorities.filter { habitIDs.contains($0) }
                        if model.saveMode(mode) { model.applyModeSchedule(); dismiss() }
                    }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("saveMode")
                }
            }
        }
    }
}

/// Seven weekday chips in the user's week order (Pace quick-pick style).
struct PaceWeekdayPicker: View {
    @Environment(AppModel.self) private var model
    @Binding var selection: Set<Int>
    var identifierPrefix: String? = nil

    var body: some View {
        HStack(spacing: PaceSpacing.xxs) {
            ForEach(model.weekdays, id: \.self) { day in
                let on = selection.contains(day)
                Button {
                    if on { selection.remove(day) } else { selection.insert(day) }
                } label: {
                    Text(model.weekdayShort(day))
                        .font(.subheadline.weight(on ? .semibold : .regular))
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .foregroundStyle(on ? PaceColor.onSelection : PaceColor.textPrimary)
                        .background(on ? PaceColor.selectionFill : PaceColor.fieldBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(model.weekday(day))
                .accessibilityAddTraits(on ? .isSelected : [])
                .accessibilityIdentifier((identifierPrefix ?? "weekday") + "." + String(day))
            }
        }
    }
}
