import SwiftUI
import PaceLifeCore

struct CalendarView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric(relativeTo: .body) private var cellSize: CGFloat = 44
    @State private var selected = Date()
    @State private var scope: CalendarScope = .week
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian); c.locale = model.locale; c.timeZone = .current; return c
    }
    private var days: [Date] { PlanningCalendar.days(containing: selected, scope: scope, calendar: calendar) }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Picker(model.calendarText(.calendar), selection: $scope) {
                        Text(model.calendarText(.week)).tag(CalendarScope.week)
                        Text(model.calendarText(.month)).tag(CalendarScope.month)
                    }.pickerStyle(.segmented)
                    HStack {
                        Button { move(-1) } label: { Image(systemName: "chevron.left").frame(width: cellSize, height: cellSize) }
                            .accessibilityLabel(model.calendarText(.previous))
                        Spacer()
                        Text(selected.formatted(.dateTime.month(.wide).year().locale(model.locale))).font(.headline)
                        Spacer()
                        Button { move(1) } label: { Image(systemName: "chevron.right").frame(width: cellSize, height: cellSize) }
                            .accessibilityLabel(model.calendarText(.next))
                    }
                    calendarGrid
                    Text(selected.formatted(.dateTime.weekday(.wide).day().month(.wide).year().locale(model.locale))).font(.title3.bold())
                    if let overview = model.overview(on: selected) { details(overview) }
                }.padding(16)
            }
            .background(PaceColor.background)
            .navigationTitle(model.calendarText(.calendar)).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(model.text(.done)) { dismiss() }.accessibilityIdentifier("closeCalendar") }
                ToolbarItem(placement: .primaryAction) { Button(model.text(.today)) { selected = model.today } }
            }
        }
    }
    private var calendarGrid: some View {
        ScrollView(.horizontal) {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize), spacing: 4), count: 7), spacing: 8) {
                ForEach(model.weekdays, id: \.self) { weekday in
                    Text(calendar.veryShortStandaloneWeekdaySymbols[weekday - 1]).font(.caption).frame(width: cellSize)
                }
                if scope == .month, let first = days.first {
                    let offset = (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7
                    ForEach(0..<offset, id: \.self) { _ in Color.clear.frame(width: cellSize, height: cellSize).accessibilityHidden(true) }
                }
                ForEach(days, id: \.self) { date in
                    let day = DayKey(date: date, calendar: calendar)
                    let selectedDay = day == DayKey(date: selected, calendar: calendar)
                    let hasRecords = model.state.completions.contains { $0.day == day } || model.state.routineSessions.contains { $0.day == day }
                    Button { selected = date } label: {
                        VStack(spacing: 2) {
                            Text(model.number(Double(calendar.component(.day, from: date)))).font(.body)
                            Circle().fill(hasRecords ? PaceColor.accentStrong : Color.clear).frame(width: 4, height: 4)
                        }.frame(width: cellSize, height: cellSize)
                            .background(selectedDay ? PaceColor.selectionFill : PaceColor.surface, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(selectedDay ? PaceColor.onSelection : PaceColor.textPrimary)
                    }.buttonStyle(.plain)
                        .accessibilityLabel(date.formatted(.dateTime.weekday(.wide).day().month(.wide).year().locale(model.locale)))
                        .accessibilityAddTraits(selectedDay ? .isSelected : [])
                }
            }.frame(width: cellSize * 7 + 24)
        }
    }
    @ViewBuilder private func details(_ overview: DayOverview) -> some View {
        if overview.isForecast { Text(model.calendarText(.forecast)).font(.footnote).foregroundStyle(PaceColor.textSecondary) }
        if let habits = overview.plannedHabits, let routines = overview.plannedRoutines {
            PaceCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text(model.calendarText(.planned)).font(.headline)
                    ForEach(habits) { habit in Label(habit.title, systemImage: "checklist") }
                    ForEach(routines) { routine in Label(routine.title, systemImage: "list.bullet.rectangle") }
                    if habits.isEmpty && routines.isEmpty { Text(model.text(.noDueHabits)) }
                }
            }
        } else { Text(model.calendarText(.unknownHistory)).font(.footnote).foregroundStyle(PaceColor.textSecondary) }
        PaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(model.calendarText(.recorded)).font(.headline)
                if overview.completions.isEmpty && overview.routineSessions.isEmpty { Text(model.calendarText(.noRecords)) }
                ForEach(overview.completions) { record in
                    VStack(alignment: .leading, spacing: 4) {
                        Label(model.state.habits.first { $0.id == record.habitID }?.title ?? model.text(.habits), systemImage: record.isComplete ? "checkmark.circle.fill" : "circle.lefthalf.filled")
                        Text(model.number(record.actualValue) + " / " + model.number(record.targetSnapshot) + (record.goalTypeSnapshot == .duration ? " " + model.text(.minutes) : ""))
                        if let target = overview.adaptivePlan?.entries.first(where: { $0.habitID == record.habitID })?.acceptedTarget {
                            Text(model.adaptiveText(.adjusted) + ": " + model.number(target)).font(.footnote)
                        }
                    }
                }
                ForEach(overview.routineSessions) { session in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.titleSnapshot).font(.headline)
                        Text(model.number(Double(session.completedStepIDs.count)) + " / " + model.number(Double(session.steps.count)))
                    }
                }
            }
        }
    }
    private func move(_ amount: Int) {
        if let next = calendar.date(byAdding: scope == .week ? .weekOfYear : .month, value: amount, to: selected) { selected = next }
    }
}
