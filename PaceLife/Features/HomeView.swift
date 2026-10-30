import SwiftUI
import PaceLifeCore

struct HomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var newHabit = false
    @State private var widgets = false
    @State private var modes = false
    @State private var allHabits = false
    @State private var selectedHabit: Habit?

    var body: some View {
        Page(title: model.text(.today), subtitle: model.today.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(model.locale))) {
            HStack {
                Text(model.text(.welcome)).font(.title3.weight(.semibold))
                Spacer()
                Button { widgets = true } label: { Image(systemName: "slider.horizontal.3").frame(width: 44, height: 44) }
                    .accessibilityLabel(model.text(.widgets)).accessibilityIdentifier("customizeWidgets")
            }
            if model.activeHabits.isEmpty {
                PaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Image(systemName: "leaf").font(.largeTitle).foregroundStyle(PaceColor.accent)
                        Text(model.text(.noHabits)).font(.title3.bold())
                        Text(model.text(.welcomeDetail)).foregroundStyle(PaceColor.textSecondary)
                    }
                }
            }
            if model.state.widgets.allSatisfy({ !$0.isVisible }) {
                PaceStatus(title: model.text(.noWidgets), message: model.text(.widgetsHelp), systemImage: "rectangle.3.group")
            }
            ForEach(model.state.widgets.filter(\.isVisible)) { widget in
                switch widget.kind {
                case .progress: progressCard
                case .mode: modeCard
                case .habits: habitsCard
                }
            }
            Button { newHabit = true } label: { Label(model.text(.newHabit), systemImage: "plus") }
                .buttonStyle(PaceButtonStyle()).accessibilityIdentifier("addHabit")
            Button(model.text(.manageHabits)) { allHabits = true }.buttonStyle(PaceButtonStyle(kind: .secondary))
        }
        .sheet(isPresented: $newHabit) { HabitEditor() }
        .sheet(isPresented: $widgets) { WidgetEditor() }
        .sheet(isPresented: $modes) { ModesView() }
        .sheet(isPresented: $allHabits) { HabitsView() }
        .sheet(item: $selectedHabit) { HabitDetail(habitID: $0.id) }
    }

    private var progressCard: some View {
        PaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(model.text(.progress)).font(.title3.bold())
                if model.dueHabits.isEmpty {
                    Text(model.text(.emptyProgress)).foregroundStyle(PaceColor.textSecondary)
                } else {
                    let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 24)) : AnyLayout(HStackLayout(spacing: 24))
                    layout {
                        PaceProgressRing(progress: model.progress, value: model.progress.formatted(.percent.locale(model.locale).precision(.fractionLength(0))), label: model.text(.completed))
                            .layoutPriority(1)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(model.number(Double(model.completedCount)) + " / " + model.number(Double(model.dueHabits.count)))
                                .font(.title.bold()).monospacedDigit()
                            Text(model.text(.progressDetail)).foregroundStyle(PaceColor.textSecondary)
                        }
                    }
                }
            }
        }.accessibilityElement(children: .contain).accessibilityIdentifier("home.progress")
    }

    private var modeCard: some View {
        PaceCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(model.text(.activeMode), systemImage: "circle.hexagongrid").font(.headline)
                    Spacer()
                    Button { modes = true } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                        .accessibilityLabel(model.text(.modes)).accessibilityIdentifier("manageModes")
                }
                Text(model.activeMode?.title ?? model.text(.noMode)).font(.title3.bold()).foregroundStyle(PaceColor.brand)
                    .accessibilityIdentifier("mode.active")
                Text(model.text(.modeNote)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
            }
        }
    }

    private var habitsCard: some View {
        PaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(model.text(.habits)).font(.title3.bold())
                if model.dueHabits.isEmpty {
                    Text(model.text(.noDueHabits)).foregroundStyle(PaceColor.textSecondary)
                }
                ForEach(model.dueHabits) { habit in
                    HabitRow(habit: habit, open: { selectedHabit = habit })
                    if habit.id != model.dueHabits.last?.id { Divider() }
                }
            }
        }
    }
}

struct HabitRow: View {
    @Environment(AppModel.self) private var model
    let habit: Habit
    let open: () -> Void
    @State private var record = false

    var body: some View {
        let completion = model.completion(habit)
        let kind = completion?.goalTypeSnapshot ?? habit.goalType
        HStack(spacing: 12) {
            Button {
                if kind == .binary { _ = model.record(habit, value: completion?.isComplete == true ? 0 : 1) }
                else { record = true }
            } label: {
                Image(systemName: completion?.isComplete == true ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 28)).foregroundStyle(completion?.isComplete == true ? PaceColor.accent : PaceColor.textSecondary)
                    .frame(width: 44, height: 48)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(habit.title + ", " + model.text(kind == .binary ? .completed : .recordProgress))
            .accessibilityValue(completion?.isComplete == true ? "1" : "0")
            .accessibilityIdentifier("habit.complete." + habit.title)
            Button(action: open) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.title).font(.headline).foregroundStyle(PaceColor.textPrimary)
                    if kind != .binary {
                        Text(model.number(completion?.actualValue ?? 0) + " / " + model.number(completion?.targetSnapshot ?? habit.target) + (kind == .duration ? " " + model.text(.minutes) : ""))
                            .font(.footnote).foregroundStyle(PaceColor.textSecondary)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }.buttonStyle(.plain).accessibilityIdentifier("habit.detail." + habit.title)
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(PaceColor.textSecondary).accessibilityHidden(true)
        }
        .sheet(isPresented: $record) { RecordEditor(habit: habit) }
    }
}
