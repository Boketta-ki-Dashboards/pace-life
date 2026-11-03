import SwiftUI
import PaceLifeCore

struct AdaptiveView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var available = 30
    @State private var energy = 3
    @State private var load = 3
    @State private var protectedIDs: Set<UUID> = []
    @State private var editing: AdaptiveEntry?
    @State private var recording: Habit?
    var body: some View {
        NavigationStack {
            List {
                SaveErrorBanner()
                if let plan = model.adaptivePlan {
                    summary(plan)
                    if plan.entries.isEmpty { Text(model.adaptiveText(.noActivities)) }
                    ForEach(plan.entries) { entry in entrySection(entry, plan: plan) }
                    Text(model.adaptiveText(.frozen)).font(.footnote)
                } else {
                    Section {
                        Stepper(model.adaptiveText(.available) + ": " + model.number(Double(available)), value: $available, in: 0...1440, step: 5)
                        Stepper(model.adaptiveText(.energy) + ": " + model.number(Double(energy)), value: $energy, in: 1...5)
                        Stepper(model.adaptiveText(.load) + ": " + model.number(Double(load)), value: $load, in: 1...5)
                    }
                    Section(model.adaptiveText(.protect)) {
                        ForEach(model.dueHabits.filter { model.dayGoalType($0) == .duration }) { habit in
                            Toggle(habit.title, isOn: Binding(get: { protectedIDs.contains(habit.id) }, set: {
                                if $0 { protectedIDs.insert(habit.id) } else { protectedIDs.remove(habit.id) }
                            }))
                        }
                    }
                    Button(model.adaptiveText(.propose)) { model.proposeAdaptive(available: available, energy: energy, load: load, protectedIDs: protectedIDs) }
                        .accessibilityIdentifier("proposeAdaptive")
                }
                Section { Text(model.adaptiveText(.rule)).font(.footnote).foregroundStyle(PaceColor.textSecondary) }
                Section(model.text(.history)) {
                    ForEach(model.state.adaptivePlans.filter { $0.day != DayKey(date: model.today) }.sorted { $0.day > $1.day }) { plan in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(plan.day.rawValue).font(.headline)
                            ForEach(plan.entries) { entry in
                                let actual = model.state.completions.first { $0.habitID == entry.habitID && $0.day == plan.day }?.actualValue ?? 0
                                Text(entry.titleSnapshot).font(.headline)
                                Text(model.adaptiveText(.actual) + ": " + model.number(actual))
                                Text(model.adaptiveText(.original) + ": " + model.number(entry.originalTarget))
                                if let target = entry.acceptedTarget { Text(model.adaptiveText(.adjusted) + ": " + model.number(target)) }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden).background(PaceColor.background)
            .navigationTitle("Pace Adaptive").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(model.text(.done)) { dismiss() }.accessibilityIdentifier("closeAdaptive") } }
            .sheet(item: $editing) { entry in
                if let plan = model.adaptivePlan { AdaptiveTargetEditor(entry: entry, day: plan.day) }
            }
            .sheet(item: $recording) { RecordEditor(habit: $0) }
        }
    }
    private func summary(_ plan: DailyAdaptivePlan) -> some View {
        Section {
            LabeledContent(model.adaptiveText(.available), value: model.number(Double(plan.availableMinutes)))
            LabeledContent(model.adaptiveText(.suggested), value: model.number(plan.suggestedMinutes))
            LabeledContent(model.adaptiveText(.current), value: model.number(plan.effectiveMinutes))
            LabeledContent(model.adaptiveText(.routineTime), value: model.number(plan.routineMinutes))
            if plan.unknownDurationCount > 0 { LabeledContent(model.adaptiveText(.unknown), value: model.number(Double(plan.unknownDurationCount))) }
            if plan.exceedsBudget { Text(model.adaptiveText(.overBudget)).foregroundStyle(PaceColor.warning) }
        }
    }
    private func entrySection(_ entry: AdaptiveEntry, plan: DailyAdaptivePlan) -> some View {
        Section(entry.titleSnapshot) {
            LabeledContent(model.adaptiveText(.original), value: model.number(entry.originalTarget))
            LabeledContent(model.adaptiveText(.suggested), value: model.number(entry.suggestedTarget))
            let actual = model.state.completions.first { $0.habitID == entry.habitID && $0.day == plan.day }?.actualValue ?? 0
            LabeledContent(model.adaptiveText(.actual), value: model.number(actual))
            if let target = entry.acceptedTarget {
                LabeledContent(model.adaptiveText(.adjusted), value: model.number(target))
                if target == 0 { Text(model.adaptiveText(.deferred)).font(.footnote) }
                else { Text(model.number(actual) + " / " + model.number(target)).accessibilityIdentifier("adaptive.progress." + entry.titleSnapshot) }
            }
            if entry.supportsPath { Label("Life Paths", systemImage: "link") }
            if entry.isProtected { Text(model.adaptiveText(.protect)).font(.footnote) }
            else {
                if entry.decision == .pending {
                    Button(model.adaptiveText(.accept)) { model.decideAdaptive(plan.day, habitID: entry.habitID, decision: .accepted) }
                        .accessibilityIdentifier("adaptive.accept." + entry.titleSnapshot)
                    Button(model.adaptiveText(.decline)) { model.decideAdaptive(plan.day, habitID: entry.habitID, decision: .declined) }
                }
                if entry.decision == .declined { Text(model.adaptiveText(.decline)).font(.footnote) }
                Button(model.text(.edit)) { editing = entry }
                if entry.decision == .accepted {
                    Button(model.adaptiveText(.undo)) { model.decideAdaptive(plan.day, habitID: entry.habitID, decision: .reverted) }
                }
            }
            if let habit = model.state.habits.first(where: { $0.id == entry.habitID && !$0.isArchived }) {
                Button(model.text(.recordProgress)) { recording = habit }.accessibilityIdentifier("adaptive.record." + entry.titleSnapshot)
            }
        }
    }
}

struct AdaptiveTargetEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let entry: AdaptiveEntry
    let day: DayKey
    @State private var value = ""
    private var valid: Bool { model.parseNumber(value).map { (0...entry.originalTarget).contains($0) } ?? false }
    var body: some View {
        NavigationStack {
            Form {
                SaveErrorBanner()
                Text(entry.titleSnapshot).font(.headline)
                LabeledContent(model.adaptiveText(.original), value: model.number(entry.originalTarget))
                TextField(model.adaptiveText(.adjusted), text: $value).keyboardType(.decimalPad)
                if model.parseNumber(value) == 0 { Text(model.adaptiveText(.deferred)) }
                if day != DayKey(date: model.today) { Text(model.text(.dayChanged)) }
            }
            .navigationTitle("Pace Adaptive").navigationBarTitleDisplayMode(.inline)
            .onAppear { value = model.inputNumber(entry.acceptedTarget ?? entry.suggestedTarget) }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(model.text(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(model.adaptiveText(.accept)) {
                        guard let number = model.parseNumber(value) else { return }
                        if model.decideAdaptive(day, habitID: entry.habitID, decision: .accepted, target: number) { dismiss() }
                    }.disabled(!valid || day != DayKey(date: model.today))
                }
            }
        }
    }
}
