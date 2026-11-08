import SwiftUI
import PaceLifeCore

struct AdaptiveView: View {
    @Environment(AppModel.self) private var model
    @State private var available = 30
    @State private var energy = 3
    @State private var load = 3
    @State private var protectedIDs: Set<UUID> = []
    @State private var editing: AdaptiveEntry?
    @State private var recording: Habit?
    var body: some View {
        PaceSubpage(title: "Pace Adaptive", subtitle: model.text(.adaptiveDetail)) {
            if let plan = model.adaptivePlan {
                summary(plan)
                if plan.entries.isEmpty {
                    PaceCard { PaceEmptyState(systemImage: "clock", title: "Pace Adaptive", message: model.adaptiveText(.noActivities)) }
                }
                ForEach(plan.entries) { entry in entryCard(entry, plan: plan) }
                Text(model.adaptiveText(.frozen)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
            } else {
                planner
            }
            Text(model.adaptiveText(.rule)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
            let history = model.state.adaptivePlans.filter { $0.day != DayKey(date: model.today) }.sorted { $0.day > $1.day }
            if !history.isEmpty { PaceSectionTitle(model.text(.history)) }
            ForEach(history) { plan in
                PaceCard {
                    VStack(alignment: .leading, spacing: PaceSpacing.s) {
                        HStack {
                            Text(model.dayLabel(plan.day)).font(.headline)
                            Spacer()
                            Text(model.number(plan.effectiveMinutes) + " / " + model.number(Double(plan.availableMinutes)) + " " + model.text(.minutes))
                                .font(.footnote).foregroundStyle(PaceColor.textSecondary)
                        }
                        ForEach(plan.entries) { entry in
                            let actual = model.state.completions.first { $0.habitID == entry.habitID && $0.day == plan.day }?.actualValue ?? 0
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.titleSnapshot).font(.subheadline.weight(.semibold))
                                Text(model.adaptiveHistoryLine(entry, actual: actual))
                                    .font(.footnote).foregroundStyle(PaceColor.textSecondary)
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $editing) { entry in
            if let plan = model.adaptivePlan { AdaptiveTargetEditor(entry: entry, day: plan.day) }
        }
        .sheet(item: $recording) { RecordEditor(habit: $0) }
    }

    private var planner: some View {
        VStack(alignment: .leading, spacing: PaceSpacing.s) {
            PaceCard {
                VStack(alignment: .leading, spacing: PaceSpacing.s) {
                    Text(model.adaptiveText(.available)).font(.headline)
                    HStack(spacing: PaceSpacing.m) {
                        stepButton("minus", label: model.adaptiveText(.available) + " −") { available = max(0, available - 5) }
                        VStack(spacing: 0) {
                            Text(model.number(Double(available))).font(.system(size: 44, weight: .bold)).monospacedDigit()
                                .accessibilityIdentifier("adaptive.available")
                            Text(model.text(.minutes)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        stepButton("plus", label: model.adaptiveText(.available) + " +") { available = min(1440, available + 5) }
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: PaceSpacing.xs), count: 3), spacing: PaceSpacing.xs) {
                        ForEach([15, 30, 45, 60, 90, 120], id: \.self) { minutes in
                            Button { available = minutes } label: {
                                Text(model.number(Double(minutes)))
                                    .font(.subheadline.weight(available == minutes ? .semibold : .regular))
                                    .frame(maxWidth: .infinity, minHeight: 36)
                                    .foregroundStyle(available == minutes ? PaceColor.onSelection : PaceColor.textPrimary)
                                    .background(available == minutes ? PaceColor.selectionFill : PaceColor.fieldBackground,
                                                in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(available == minutes ? .isSelected : [])
                        }
                    }
                }
            }
            PaceCard {
                VStack(alignment: .leading, spacing: PaceSpacing.s) {
                    Text(model.adaptiveText(.energy)).font(.headline)
                    PaceSegmentedControl(selection: $energy, options: (1...5).map { (value: $0, title: model.number(Double($0))) }, identifierPrefix: "adaptive.energy")
                    Text(model.adaptiveText(.load)).font(.headline)
                    PaceSegmentedControl(selection: $load, options: (1...5).map { (value: $0, title: model.number(Double($0))) }, identifierPrefix: "adaptive.load")
                }
            }
            let flexible = model.dueHabits.filter { model.dayGoalType($0) == .duration }
            if !flexible.isEmpty {
                PaceCard {
                    VStack(alignment: .leading, spacing: PaceSpacing.xs) {
                        Text(model.adaptiveText(.protect)).font(.headline)
                        ForEach(flexible) { habit in
                            Toggle(habit.title, isOn: Binding(get: { protectedIDs.contains(habit.id) }, set: {
                                if $0 { protectedIDs.insert(habit.id) } else { protectedIDs.remove(habit.id) }
                            }))
                            .tint(PaceColor.accentStrong).frame(minHeight: 44)
                        }
                    }
                }
            }
            Button(model.adaptiveText(.propose)) { model.proposeAdaptive(available: available, energy: energy, load: load, protectedIDs: protectedIDs) }
                .buttonStyle(PaceButtonStyle())
                .accessibilityIdentifier("proposeAdaptive")
        }
    }

    private func stepButton(_ icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.title3.weight(.semibold)).foregroundStyle(PaceColor.accentStrong)
                .frame(width: 48, height: 48)
                .background(PaceColor.accentSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func summary(_ plan: DailyAdaptivePlan) -> some View {
        let available = Double(plan.availableMinutes)
        return PaceCard {
            VStack(alignment: .leading, spacing: PaceSpacing.s) {
                Text(model.adaptiveText(.current)).font(.headline)
                HStack(alignment: .firstTextBaseline, spacing: PaceSpacing.xs) {
                    Text(model.number(plan.effectiveMinutes)).font(.system(size: 52, weight: .bold)).monospacedDigit()
                    Text(model.text(.minutes)).font(.title3.weight(.semibold))
                }
                Text(model.adaptiveText(.available) + ": " + model.number(available)).font(.subheadline)
                PaceProgressBar(progress: available > 0 ? plan.effectiveMinutes / available : 0,
                                tint: plan.exceedsBudget ? PaceColor.warning : nil)
                HStack(spacing: PaceSpacing.xs) {
                    PaceStatTile(value: model.number(plan.suggestedMinutes), label: model.adaptiveText(.suggested))
                    PaceStatTile(value: model.number(plan.routineMinutes), label: model.adaptiveText(.routineTime))
                }
                if plan.unknownDurationCount > 0 {
                    Text(model.adaptiveText(.unknown) + ": " + model.number(Double(plan.unknownDurationCount))).font(.footnote).foregroundStyle(PaceColor.textSecondary)
                }
                if plan.exceedsBudget { Label(model.adaptiveText(.overBudget), systemImage: "exclamationmark.triangle").font(.footnote).foregroundStyle(PaceColor.warning) }
            }
        }
    }

    private func entryCard(_ entry: AdaptiveEntry, plan: DailyAdaptivePlan) -> some View {
        let actual = model.state.completions.first { $0.habitID == entry.habitID && $0.day == plan.day }?.actualValue ?? 0
        return PaceCard {
            VStack(alignment: .leading, spacing: PaceSpacing.s) {
                HStack {
                    Text(entry.titleSnapshot).font(.headline)
                    if entry.supportsPath { PaceBadge(text: "Life Paths", systemImage: "link") }
                    Spacer()
                }
                HStack(spacing: PaceSpacing.xs) {
                    PaceStatTile(value: model.number(entry.originalTarget), label: model.adaptiveText(.original))
                    PaceStatTile(value: model.number(entry.acceptedTarget ?? entry.suggestedTarget),
                                 label: model.adaptiveText(entry.acceptedTarget == nil ? .suggested : .adjusted))
                    PaceStatTile(value: model.number(actual), label: model.adaptiveText(.actual))
                }
                if let target = entry.acceptedTarget {
                    if target == 0 { Text(model.adaptiveText(.deferred)).font(.footnote).foregroundStyle(PaceColor.textSecondary) }
                    else {
                        Text(model.number(actual) + " / " + model.number(target)).font(.subheadline.weight(.semibold)).monospacedDigit()
                            .accessibilityIdentifier("adaptive.progress." + entry.titleSnapshot)
                        PaceProgressBar(progress: actual / target, height: 6)
                    }
                }
                if entry.isProtected {
                    Label(model.adaptiveText(.protect), systemImage: "lock").font(.footnote).foregroundStyle(PaceColor.textSecondary)
                } else {
                    if entry.decision == .declined { Text(model.adaptiveText(.decline)).font(.footnote).foregroundStyle(PaceColor.textSecondary) }
                    HStack(spacing: PaceSpacing.xs) {
                        if entry.decision == .pending {
                            Button(model.adaptiveText(.accept)) { model.decideAdaptive(plan.day, habitID: entry.habitID, decision: .accepted) }
                                .buttonStyle(PaceCompactButtonStyle())
                                .accessibilityIdentifier("adaptive.accept." + entry.titleSnapshot)
                            Button(model.adaptiveText(.decline)) { model.decideAdaptive(plan.day, habitID: entry.habitID, decision: .declined) }
                                .buttonStyle(PaceCompactButtonStyle(prominent: false))
                        }
                        if entry.decision == .accepted {
                            Button(model.adaptiveText(.undo)) { model.decideAdaptive(plan.day, habitID: entry.habitID, decision: .reverted) }
                                .buttonStyle(PaceCompactButtonStyle(prominent: false))
                        }
                        Button(model.text(.edit)) { editing = entry }.buttonStyle(PaceCompactButtonStyle(prominent: false))
                    }
                }
                if let habit = model.state.habits.first(where: { $0.id == entry.habitID && !$0.isArchived }) {
                    Button { recording = habit } label: { Label(model.text(.recordProgress), systemImage: "plus.circle") }
                        .buttonStyle(PaceLinkButtonStyle())
                        .accessibilityIdentifier("adaptive.record." + entry.titleSnapshot)
                }
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
