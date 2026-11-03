import SwiftUI
import PaceLifeCore

struct RoutinesView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var creating = false
    @State private var showArchive = false
    var body: some View {
        NavigationStack {
            List {
                SaveErrorBanner()
                Toggle(model.text(.archive), isOn: $showArchive)
                let routines = model.state.routines.filter { $0.isArchived == showArchive }
                if routines.isEmpty { Text(model.routineText(.noRoutines)).foregroundStyle(PaceColor.textSecondary) }
                ForEach(routines) { routine in
                    NavigationLink {
                        RoutineDetail(routineID: routine.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(routine.title).font(.headline)
                            Text(model.routineText(.steps) + ": " + model.number(Double(routine.steps.count)))
                                .font(.footnote).foregroundStyle(PaceColor.textSecondary)
                        }
                    }.accessibilityIdentifier("routine.open." + routine.title)
                }
            }
            .scrollContentBackground(.hidden).background(PaceColor.background)
            .navigationTitle(model.routineText(.routines)).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(model.text(.done)) { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button { creating = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel(model.routineText(.newRoutine)).accessibilityIdentifier("addRoutine")
                }
            }
            .sheet(isPresented: $creating) { RoutineEditor() }
        }
    }
}

struct RoutineDetail: View {
    @Environment(AppModel.self) private var model
    let routineID: UUID
    @State private var editing = false
    @State private var confirmArchive = false
    private var routine: Routine? { model.state.routines.first { $0.id == routineID } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SaveErrorBanner()
                if let routine {
                    Text(routine.notes).foregroundStyle(PaceColor.textSecondary)
                    if let session = model.routineSession(routineID) {
                        sessionCard(session)
                    } else if !routine.isArchived {
                        Button(model.routineText(.start)) { model.startRoutine(routineID) }
                            .buttonStyle(PaceButtonStyle())
                            .disabled(!model.dueRoutines.contains(where: { $0.id == routineID }))
                            .accessibilityIdentifier("startRoutine")
                        if !model.dueRoutines.contains(where: { $0.id == routineID }) {
                            Text(model.text(.notScheduled)).font(.footnote)
                        }
                        ForEach(routine.steps) { step in Text(step.title) }
                    }
                    Text(model.routineText(.snapshotNote)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
                    Text(model.routineText(.history)).font(.title3.bold())
                    ForEach(model.state.routineSessions.filter { $0.routineID == routineID }.sorted { $0.day > $1.day }) { session in
                        PaceCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(session.day.rawValue + " · " + session.titleSnapshot).font(.headline)
                                Text(model.number(Double(session.completedStepIDs.count)) + " / " + model.number(Double(session.steps.count)))
                                ForEach(session.steps) { step in
                                    Label(step.title, systemImage: session.completedStepIDs.contains(step.id) ? "checkmark.circle.fill" : "circle")
                                }
                            }
                        }
                    }
                    Button(model.text(.edit)) { editing = true }.buttonStyle(PaceButtonStyle(kind: .secondary))
                    if !routine.isArchived {
                        Button(model.text(.archive)) { confirmArchive = true }.buttonStyle(PaceButtonStyle(kind: .destructive))
                    }
                }
            }.padding(16)
        }
        .background(PaceColor.background)
        .navigationTitle(routine?.title ?? model.routineText(.routines)).navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $editing) { if let routine { RoutineEditor(routine: routine) } }
        .confirmationDialog(model.routineText(.archiveNote), isPresented: $confirmArchive) {
            Button(model.text(.archive), role: .destructive) { model.archiveRoutine(routineID) }
        }
    }
    private func sessionCard(_ session: RoutineSession) -> some View {
        PaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(session.titleSnapshot).font(.title3.bold())
                Text(model.number(Double(session.completedStepIDs.count)) + " / " + model.number(Double(session.steps.count)))
                    .accessibilityIdentifier("routine.progress")
                ProgressView(value: session.progress).tint(PaceColor.accent)
                ForEach(session.steps) { step in
                    Toggle(isOn: Binding(get: { session.completedStepIDs.contains(step.id) }, set: { model.setRoutineStep(session, stepID: step.id, completed: $0) })) {
                        VStack(alignment: .leading) {
                            Text(step.title)
                            if let minutes = step.minutes { Text(model.number(Double(minutes)) + " " + model.text(.minutes)).font(.footnote) }
                        }
                    }.disabled(session.isPaused).accessibilityIdentifier("routine.step." + step.title)
                }
                if !session.isComplete {
                    Button(model.routineText(session.isPaused ? .resume : .pause)) { model.pauseRoutine(session.id, paused: !session.isPaused) }
                        .buttonStyle(PaceButtonStyle(kind: .secondary)).accessibilityIdentifier("pauseRoutine")
                }
            }
        }
    }
}

struct RoutineEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Routine
    @State private var editMode: EditMode = .inactive
    private let isNew: Bool
    init(routine: Routine? = nil) {
        isNew = routine == nil
        _draft = State(initialValue: routine ?? Routine(title: "", steps: [RoutineStep(title: "")]))
    }
    private var valid: Bool {
        !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !draft.weekdays.isEmpty && !draft.steps.isEmpty
            && draft.steps.allSatisfy { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    var body: some View {
        NavigationStack {
            Form {
                SaveErrorBanner()
                Section {
                    TextField(model.text(.name), text: $draft.title).accessibilityIdentifier("routineTitle")
                    TextField(model.routineText(.notes), text: $draft.notes, axis: .vertical)
                    Picker(model.routineText(.mode), selection: $draft.modeID) {
                        Text(model.routineText(.noMode)).tag(UUID?.none)
                        ForEach(model.state.modes) { Text($0.title).tag(Optional($0.id)) }
                    }
                }
                stepsSection
                Section(model.text(.frequency)) {
                    ForEach(model.weekdays, id: \.self) { day in
                        Toggle(model.weekday(day), isOn: Binding(get: { draft.weekdays.contains(day) }, set: {
                            if $0 { draft.weekdays.insert(day) } else { draft.weekdays.remove(day) }
                        }))
                    }
                    Toggle(model.routineText(.plannedTime), isOn: Binding(get: { draft.plannedMinute != nil }, set: { draft.plannedMinute = $0 ? 480 : nil }))
                    if draft.plannedMinute != nil {
                        DatePicker(model.routineText(.plannedTime), selection: Binding(get: {
                            Calendar.current.date(bySettingHour: (draft.plannedMinute ?? 480) / 60, minute: (draft.plannedMinute ?? 480) % 60, second: 0, of: model.today) ?? model.today
                        }, set: {
                            let c = Calendar.current.dateComponents([.hour, .minute], from: $0)
                            draft.plannedMinute = (c.hour ?? 0) * 60 + (c.minute ?? 0)
                        }), displayedComponents: .hourAndMinute)
                    }
                }
                if draft.isArchived { Toggle(model.text(.archive), isOn: $draft.isArchived) }
            }
            .environment(\.editMode, $editMode)
            .scrollContentBackground(.hidden).background(PaceColor.background)
            .navigationTitle(model.routineText(isNew ? .newRoutine : .editRoutine)).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(model.text(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(model.text(.save)) { if model.saveRoutine(draft) { dismiss() } }
                        .disabled(!valid).accessibilityIdentifier("saveRoutine")
                }
                ToolbarItem(placement: .bottomBar) { EditButton().environment(\.editMode, $editMode) }
            }
        }
    }
    private var stepsSection: some View {
        Section(model.routineText(.steps)) {
            ForEach($draft.steps) { $step in
                VStack(alignment: .leading) {
                    TextField(model.routineText(.stepTitle), text: $step.title).accessibilityIdentifier("routineStepTitle")
                    Toggle(model.routineText(.stepDuration), isOn: Binding(get: { step.minutes != nil }, set: { step.minutes = $0 ? 5 : nil }))
                    if step.minutes != nil {
                        Stepper(model.number(Double(step.minutes ?? 5)) + " " + model.text(.minutes), value: Binding(get: { step.minutes ?? 5 }, set: { step.minutes = $0 }), in: 1...1440)
                    }
                }
            }.onDelete { draft.steps.remove(atOffsets: $0) }
                .onMove { draft.steps.move(fromOffsets: $0, toOffset: $1) }
            Button(model.routineText(.addStep)) { draft.steps.append(RoutineStep(title: "")) }.accessibilityIdentifier("addRoutineStep")
        }
    }
}
