import SwiftUI
import PaceLifeCore

struct CalendarView: View {
    @Environment(AppModel.self) private var model
    @State private var selected = Date()
    @State private var scope: CalendarScope = .month
    @State private var initialized = false

    var body: some View {
        let dates = model.days(containing: selected, scope: scope)
        PaceSubpage(title: model.dash(.calendarTitle)) {
            Button(model.dash(.today)) { selected = model.today }
                .buttonStyle(PaceCompactButtonStyle(prominent: false))
                .accessibilityIdentifier("calendarToday")
        } content: {
            PaceSegmentedControl(selection: $scope, options: [(CalendarScope.week, model.calendarText(.week)), (CalendarScope.month, model.calendarText(.month))])
            PaceCard {
                VStack(alignment: .leading, spacing: PaceSpacing.s) {
                    HStack(spacing: PaceSpacing.xxs) {
                        Button { move(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                            .buttonStyle(.plain).accessibilityLabel(model.calendarText(.previous))
                        Text(selected.formatted(.dateTime.month(.wide).year().locale(model.locale))).font(.headline)
                        Button { move(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                            .buttonStyle(.plain).accessibilityLabel(model.calendarText(.next))
                        Spacer(minLength: 0)
                        HStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 3).fill(PaceColor.goalReachedFill).frame(width: 10, height: 10)
                            Text(model.dash(.goalLegend)).font(.caption2).foregroundStyle(PaceColor.textSecondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    PaceCalendarGrid(dates: dates, scope: scope, selected: selected) { selected = $0 }
                }
            }
            dayCard
            if let overview = model.overview(on: selected) { details(overview) }
        }
        .onAppear { if !initialized { selected = model.today; initialized = true } }
    }

    private var dayCard: some View {
        let summary = model.summary(on: selected)
        let planned = summary.plannedHabitIDs?.count ?? 0
        return PaceCard {
            VStack(alignment: .leading, spacing: PaceSpacing.s) {
                Text(selected.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(model.locale))).font(.headline)
                HStack(alignment: .center, spacing: PaceSpacing.m) {
                    VStack(alignment: .leading, spacing: PaceSpacing.xxs) {
                        HStack(alignment: .firstTextBaseline, spacing: PaceSpacing.xs) {
                            Text(model.number(Double(summary.plannedHabitIDs == nil ? summary.completedHabitIDs.count : summary.plannedCompletedCount)))
                                .font(.system(size: 40, weight: .bold)).monospacedDigit()
                            Text(model.text(.habits)).font(.title3.weight(.semibold))
                        }
                        if summary.plannedHabitIDs != nil {
                            Text(model.text(.target) + ": " + model.number(Double(planned))).font(.subheadline).foregroundStyle(PaceColor.textSecondary)
                        }
                    }
                    Spacer(minLength: PaceSpacing.xs)
                    if let progress = summary.progress {
                        PaceRing(progress: progress, diameter: 84, lineWidth: 10, centerText: model.percent(progress))
                    }
                }
                if let progress = summary.progress { PaceProgressBar(progress: progress) }
                if summary.goalReached {
                    Label(model.dash(.goalReached), systemImage: "checkmark.seal.fill").font(.subheadline.weight(.semibold)).foregroundStyle(PaceColor.accent)
                } else if summary.isForecast {
                    Text(model.dash(.forecastDay)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
                } else if summary.isRestDay {
                    Text(model.dash(.streakRest)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
                } else if summary.plannedHabitIDs == nil {
                    Text(model.dash(.noPlanKnown)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
                } else {
                    Text(model.dash(.remaining, model.number(Double(planned - summary.plannedCompletedCount)))).font(.subheadline)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private func details(_ overview: DayOverview) -> some View {
        if overview.isForecast { Text(model.calendarText(.forecast)).font(.footnote).foregroundStyle(PaceColor.textSecondary) }
        if let habits = overview.plannedHabits, let routines = overview.plannedRoutines {
            PaceCard {
                VStack(alignment: .leading, spacing: PaceSpacing.s) {
                    Text(model.calendarText(.planned)).font(.headline)
                    ForEach(habits) { habit in Label(habit.title, systemImage: "checklist") }
                    ForEach(routines) { routine in Label(routine.title, systemImage: "list.bullet.rectangle") }
                    if habits.isEmpty && routines.isEmpty { Text(model.text(.noDueHabits)).foregroundStyle(PaceColor.textSecondary) }
                }
            }
        } else {
            Text(model.calendarText(.unknownHistory)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
        }
        PaceCard {
            VStack(alignment: .leading, spacing: PaceSpacing.s) {
                Text(model.calendarText(.recorded)).font(.headline)
                if overview.completions.isEmpty && overview.routineSessions.isEmpty {
                    Text(model.calendarText(.noRecords)).foregroundStyle(PaceColor.textSecondary)
                }
                ForEach(overview.completions) { record in
                    HStack(alignment: .top, spacing: PaceSpacing.s) {
                        Image(systemName: record.isComplete ? "checkmark.circle.fill" : "circle.lefthalf.filled").foregroundStyle(PaceColor.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(model.state.habits.first { $0.id == record.habitID }?.title ?? model.text(.habits)).font(.subheadline.weight(.semibold))
                            Text(model.number(record.actualValue) + " / " + model.number(record.targetSnapshot) + (record.goalTypeSnapshot == .duration ? " " + model.text(.minutes) : ""))
                                .font(.footnote).monospacedDigit().foregroundStyle(PaceColor.textSecondary)
                            if let target = overview.adaptivePlan?.entries.first(where: { $0.habitID == record.habitID })?.acceptedTarget {
                                Text(model.adaptiveText(.adjusted) + ": " + model.number(target)).font(.footnote).foregroundStyle(PaceColor.accentStrong)
                            }
                        }
                    }
                }
                ForEach(overview.routineSessions) { session in
                    HStack {
                        Label(session.titleSnapshot, systemImage: "list.bullet.rectangle").font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(model.number(Double(session.completedStepIDs.count)) + " / " + model.number(Double(session.steps.count)))
                            .font(.footnote).monospacedDigit().foregroundStyle(PaceColor.textSecondary)
                    }
                }
            }
        }
    }

    private func move(_ amount: Int) {
        if let next = model.displayCalendar.date(byAdding: scope == .week ? .weekOfYear : .month, value: amount, to: selected) { selected = next }
    }
}

/// Pace statistics: period segments, metric chips, period navigation, total with
/// comparison, bar chart and best values. Only stored results are counted.
struct StatisticsView: View {
    @Environment(AppModel.self) private var model
    @State private var scope: CalendarScope = .week
    @State private var metric: DailyMetric = .completedHabits
    @State private var anchor = Date()
    @State private var selectedBar: Int?
    @State private var initialized = false

    var body: some View {
        let calendar = model.displayCalendar
        let dates = model.days(containing: anchor, scope: scope)
        let values = dates.map { model.metricValue(metric, on: $0) }
        let elapsed = dates.filter { calendar.startOfDay(for: $0) <= calendar.startOfDay(for: model.today) }
        let total = values.reduce(0, +)
        let average = elapsed.isEmpty ? 0 : elapsed.map { model.metricValue(metric, on: $0) }.reduce(0, +) / Double(elapsed.count)
        let previousAnchor = calendar.date(byAdding: scope == .week ? .weekOfYear : .month, value: -1, to: anchor) ?? anchor
        let previous = model.days(containing: previousAnchor, scope: scope)
        let previousAverage = previous.isEmpty ? 0 : previous.map { model.metricValue(metric, on: $0) }.reduce(0, +) / Double(previous.count)
        PaceSubpage(title: model.dash(.statistics)) {
            PaceSegmentedControl(selection: $scope, options: [(CalendarScope.week, model.calendarText(.week)), (CalendarScope.month, model.calendarText(.month))])
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: PaceSpacing.xs) {
                    PaceChip(title: model.text(.habits), systemImage: "checkmark.circle", isSelected: metric == .completedHabits) { metric = .completedHabits }
                    PaceChip(title: model.text(.minutes), systemImage: "timer", isSelected: metric == .minutes) { metric = .minutes }
                    PaceChip(title: model.text(.routines), systemImage: "list.bullet.rectangle", isSelected: metric == .completedRoutines) { metric = .completedRoutines }
                }
            }
            PaceCard(padding: PaceSpacing.xs) {
                HStack {
                    Button { shift(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                        .buttonStyle(.plain).accessibilityLabel(model.calendarText(.previous))
                    Spacer()
                    VStack(spacing: 0) {
                        Text(periodTitle(dates)).font(.subheadline.weight(.semibold))
                        Text(periodRange(dates)).font(.caption).foregroundStyle(PaceColor.textSecondary)
                    }
                    Spacer()
                    Button { shift(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                        .buttonStyle(.plain).accessibilityLabel(model.calendarText(.next))
                        .disabled(dates.last.map { calendar.startOfDay(for: $0) >= calendar.startOfDay(for: model.today) } ?? false)
                }
            }
            PaceCard {
                VStack(alignment: .leading, spacing: PaceSpacing.xs) {
                    HStack(alignment: .firstTextBaseline, spacing: PaceSpacing.xs) {
                        Text(model.number(total)).font(.system(size: 44, weight: .bold)).monospacedDigit()
                            .accessibilityIdentifier("statistics.total")
                        Text(unit).font(.title3.weight(.semibold)).foregroundStyle(PaceColor.accent)
                    }
                    Text(model.dash(.perDay, model.number((average * 10).rounded() / 10))).font(.subheadline).foregroundStyle(PaceColor.textSecondary)
                    if previousAverage > 0 {
                        let change = (average - previousAverage) / previousAverage
                        Label(model.dash(.vsPrevious, (change > 0 ? "+" : "") + model.percent(change)), systemImage: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.footnote).foregroundStyle(change >= 0 ? PaceColor.accent : PaceColor.textSecondary)
                    }
                }
            }
            PaceCard {
                VStack(alignment: .leading, spacing: PaceSpacing.s) {
                    if total == 0 { Text(model.dash(.noValues)).font(.subheadline).foregroundStyle(PaceColor.textSecondary) }
                    PaceBarChart(bars: bars(dates: dates, values: values), height: 150, format: { model.number($0) }, selection: $selectedBar)
                    if let index = selectedBar, dates.indices.contains(index) {
                        Text(dates[index].formatted(.dateTime.weekday(.wide).day().month(.wide).locale(model.locale)) + ": " + model.number(values[index]) + " " + unit)
                            .font(.subheadline.weight(.semibold))
                    } else {
                        Text(model.dash(.tapDay)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
                    }
                }
            }
            bestValues
        }
        .onChange(of: scope) { _, _ in selectedBar = nil }
        .onChange(of: metric) { _, _ in selectedBar = nil }
        .onAppear { if !initialized { anchor = model.today; initialized = true } }
    }

    private var unit: String {
        switch metric { case .completedHabits: model.dash(.habitsDone); case .minutes: model.text(.minutes); case .completedRoutines: model.text(.routines) }
    }

    private func bars(dates: [Date], values: [Double]) -> [PaceBarChart.Bar] {
        let calendar = model.displayCalendar
        return dates.enumerated().map { index, date in
            let future = calendar.startOfDay(for: date) > calendar.startOfDay(for: model.today)
            let label = scope == .week ? model.weekdayShort(calendar.component(.weekday, from: date))
                : (calendar.component(.day, from: date) % 5 == 1 ? model.number(Double(calendar.component(.day, from: date))) : "")
            return PaceBarChart.Bar(id: index, label: label,
                                    accessibilityLabel: date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(model.locale)),
                                    value: values[index], isHighlighted: calendar.isDate(date, inSameDayAs: model.today), isFuture: future)
        }
    }

    private var bestValues: some View {
        let calendar = model.displayCalendar
        let today = DayKey(date: model.today)
        let yearAgo = DayKey(date: calendar.date(byAdding: .day, value: -364, to: model.today) ?? model.today)
        let weekStarts: [DayKey] = (0..<52).compactMap { offset in
            calendar.date(byAdding: .weekOfYear, value: -offset, to: model.today)
                .flatMap { model.days(containing: $0, scope: .week).first }.map { DayKey(date: $0) }
        }
        let bestDay = model.state.bestDay(of: metric, from: yearAgo, through: today)
        let bestWeek = model.state.bestWeek(of: metric, weekStarts: weekStarts)
        let streak = model.lifeStreak
        return PaceCard {
            VStack(alignment: .leading, spacing: PaceSpacing.s) {
                Text(model.dash(.bestValues)).font(.title3.weight(.semibold))
                bestRow(icon: "trophy.fill", title: model.dash(.bestDay), detail: bestDay.map { model.dayLabel($0.start) }, value: bestDay.map { model.number($0.value) + " " + unit })
                bestRow(icon: "trophy.fill", title: model.dash(.bestWeek), detail: bestWeek.map { model.dayLabel($0.start) + " – " + model.dayLabel($0.end) }, value: bestWeek.map { model.number($0.value) + " " + unit })
                bestRow(icon: "flame.fill", title: model.dash(.longestStreak),
                        detail: streak.longestStart.flatMap { start in streak.longestEnd.map { model.dayLabel(start) + " – " + model.dayLabel($0) } },
                        value: model.dash(.streakDays, model.number(Double(streak.longest))), tint: PaceColor.streak)
                Text(model.dash(.streakRule)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
            }
        }
    }

    private func bestRow(icon: String, title: String, detail: String?, value: String?, tint: Color? = nil) -> some View {
        HStack(alignment: .center, spacing: PaceSpacing.s) {
            Image(systemName: icon).foregroundStyle(tint ?? PaceColor.accent).frame(width: 24).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline)
                if let detail { Text(detail).font(.caption).foregroundStyle(PaceColor.textSecondary) }
            }
            Spacer(minLength: PaceSpacing.xs)
            Text(value ?? "–").font(.subheadline.weight(.bold)).monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    private func periodTitle(_ dates: [Date]) -> String {
        let calendar = model.displayCalendar
        if dates.contains(where: { calendar.isDate($0, inSameDayAs: model.today) }) {
            return scope == .week ? model.dash(.thisWeek) : model.dash(.thisMonth)
        }
        return scope == .week ? model.calendarText(.week) : (dates.first?.formatted(.dateTime.month(.wide).year().locale(model.locale)) ?? "")
    }

    private func periodRange(_ dates: [Date]) -> String {
        guard let first = dates.first, let last = dates.last else { return "" }
        return first.formatted(.dateTime.day().month(.abbreviated).locale(model.locale)) + " – " + last.formatted(.dateTime.day().month(.abbreviated).year().locale(model.locale))
    }

    private func shift(_ amount: Int) {
        selectedBar = nil
        if let next = model.displayCalendar.date(byAdding: scope == .week ? .weekOfYear : .month, value: amount, to: anchor) { anchor = next }
    }
}
