import SwiftUI
import PaceLifeCore

/// Pace bar chart: Y axis with three ticks, optional goal line, highlighted current
/// bar, dashed placeholders for future days and an honest gap for unknown values.
struct PaceBarChart: View {
    struct Bar: Identifiable {
        let id: Int
        let label: String
        let accessibilityLabel: String
        /// Nil means "unknown"; it is drawn as a gap, never as zero.
        let value: Double?
        var isHighlighted = false
        var isFuture = false
        var reachedGoal = false
    }
    let bars: [Bar]
    var top: Double? = nil
    var goal: Double? = nil
    var height: CGFloat = 140
    let format: (Double) -> String
    var selection: Binding<Int?>? = nil

    private var scaleTop: Double {
        if let top, top > 0 { return top }
        let maximum = max(bars.compactMap(\.value).max() ?? 0, goal ?? 0)
        guard maximum > 0 else { return 1 }
        let magnitude = pow(10, floor(log10(maximum)))
        let step = magnitude / 2
        return max(step, ceil(maximum / step) * step)
    }

    var body: some View {
        let top = scaleTop
        VStack(spacing: PaceSpacing.xxs) {
            HStack(alignment: .top, spacing: PaceSpacing.xs) {
                VStack(alignment: .trailing) {
                    Text(format(top)); Spacer(); Text(format(top / 2)); Spacer(); Text(format(0))
                }
                .font(.caption2).monospacedDigit().foregroundStyle(PaceColor.textSecondary)
                .frame(height: height)
                .accessibilityHidden(true)
                ZStack(alignment: .bottom) {
                    VStack(spacing: 0) {
                        ForEach(0..<3, id: \.self) { index in
                            Rectangle().fill(PaceColor.border).frame(height: 1)
                            if index < 2 { Spacer() }
                        }
                    }
                    .accessibilityHidden(true)
                    if let goal, goal > 0, goal <= top {
                        GeometryReader { proxy in
                            Rectangle().fill(PaceColor.accent).frame(height: 1.5)
                                .offset(y: proxy.size.height * (1 - goal / top))
                        }
                        .accessibilityHidden(true)
                    }
                    HStack(alignment: .bottom, spacing: PaceSpacing.xs) {
                        ForEach(bars) { bar in column(bar, top: top) }
                    }
                }
                .frame(height: height)
            }
            HStack(spacing: PaceSpacing.xs) {
                Text(format(top)).font(.caption2).monospacedDigit().hidden().accessibilityHidden(true)
                HStack(spacing: PaceSpacing.xs) {
                    ForEach(bars) { bar in
                        Text(bar.label)
                            .font(.caption.weight(bar.isHighlighted ? .bold : .regular))
                            .foregroundStyle(bar.isHighlighted ? PaceColor.textPrimary : PaceColor.textSecondary)
                            .frame(maxWidth: .infinity)
                            .lineLimit(1).minimumScaleFactor(0.6)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
    }

    @ViewBuilder private func column(_ bar: Bar, top: Double) -> some View {
        let selected = selection?.wrappedValue == bar.id
        let fraction = min(1, max(0, (bar.value ?? 0) / top))
        let shape = UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 2, bottomTrailingRadius: 2, topTrailingRadius: 6, style: .continuous)
        let content = VStack(spacing: 0) {
            Spacer(minLength: 0)
            if bar.isFuture {
                Capsule().strokeBorder(PaceColor.track, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                    .frame(height: 10)
            } else if bar.value == nil {
                Text(verbatim: "–").font(.caption2).foregroundStyle(PaceColor.textSecondary)
            } else {
                shape.fill(barColor(bar, selected: selected))
                    .frame(height: max(fraction > 0 ? 4 : 2, height * fraction))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(bar.accessibilityLabel)
        .accessibilityValue(bar.isFuture || bar.value == nil ? "–" : format(bar.value ?? 0))
        .accessibilityAddTraits(selected ? .isSelected : [])
        if let selection, !bar.isFuture {
            Button { selection.wrappedValue = selected ? nil : bar.id } label: { content }
                .buttonStyle(.plain)
        } else {
            content
        }
    }

    private func barColor(_ bar: Bar, selected: Bool) -> Color {
        if selected || bar.isHighlighted { return PaceColor.accentStrong }
        if bar.reachedGoal { return PaceColor.goalReachedFill }
        return PaceColor.chartLow
    }
}

/// One calendar day: reached days are filled, known partial days show their
/// progress ring, rest days and unknown days stay neutral, future days are muted.
struct PaceDayCell: View {
    let dayNumber: String
    let summary: DaySummary
    let caption: String
    var isToday = false
    var isSelected = false
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 40

    var body: some View {
        let reached = summary.goalReached
        ZStack {
            if reached {
                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(PaceColor.goalReachedFill)
            } else if summary.isForecast {
                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(PaceColor.fieldBackground)
            } else if let progress = summary.progress {
                PaceRing(progress: progress, diameter: size * 0.82, lineWidth: 2.5)
            }
            VStack(spacing: 0) {
                Text(dayNumber)
                    .font(.subheadline.weight(reached || isToday ? .bold : .semibold)).monospacedDigit()
                    .foregroundStyle(reached ? PaceColor.onGoalReached : summary.isForecast ? PaceColor.textSecondary : PaceColor.textPrimary)
                Text(caption)
                    .font(.system(size: 9, weight: .medium)).monospacedDigit()
                    .foregroundStyle(reached ? PaceColor.onGoalReached : PaceColor.textSecondary)
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: size + 8)
        .overlay {
            if isToday || isSelected {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? PaceColor.accent : PaceColor.accentStrong, lineWidth: isSelected ? 2 : 1.5)
            }
        }
        .overlay(alignment: .topTrailing) {
            if isToday { Circle().fill(PaceColor.accent).frame(width: 5, height: 5).padding(4) }
        }
    }
}

/// Week or month grid of `PaceDayCell`s with localized weekday headers.
struct PaceCalendarGrid: View {
    @Environment(AppModel.self) private var model
    let dates: [Date]
    let scope: CalendarScope
    var selected: Date? = nil
    var onSelect: ((Date) -> Void)? = nil

    var body: some View {
        let calendar = model.displayCalendar
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(model.weekdays, id: \.self) { weekday in
                Text(calendar.veryShortStandaloneWeekdaySymbols[weekday - 1])
                    .font(.caption.weight(.semibold)).foregroundStyle(PaceColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
            }
            if scope == .month, let first = dates.first {
                let offset = (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7
                ForEach(0..<offset, id: \.self) { _ in Color.clear.frame(height: 1).accessibilityHidden(true) }
            }
            ForEach(dates, id: \.self) { date in
                let summary = model.summary(on: date)
                let isToday = calendar.isDate(date, inSameDayAs: model.today)
                let isSelected = selected.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                let cell = PaceDayCell(dayNumber: model.number(Double(calendar.component(.day, from: date))),
                                       summary: summary, caption: caption(summary), isToday: isToday, isSelected: isSelected && !isToday)
                Group {
                    if let onSelect {
                        Button { onSelect(date) } label: { cell }.buttonStyle(.plain)
                    } else {
                        cell
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(model.locale)))
                .accessibilityValue(accessibilityValue(summary))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }

    private func caption(_ summary: DaySummary) -> String {
        if summary.isForecast { return "–" }
        guard let planned = summary.plannedHabitIDs else {
            return summary.completedHabitIDs.isEmpty ? "" : model.number(Double(summary.completedHabitIDs.count))
        }
        if planned.isEmpty { return "–" }
        return model.number(Double(summary.plannedCompletedCount)) + "/" + model.number(Double(planned.count))
    }

    private func accessibilityValue(_ summary: DaySummary) -> String {
        if summary.goalReached { return model.dash(.goalLegend) }
        if summary.isForecast { return model.dash(.forecastDay) }
        if summary.isRestDay { return model.dash(.streakRest) }
        if let progress = summary.progress { return model.percent(progress) }
        return model.dash(.noPlanKnown)
    }
}

/// Builds the bars of the current week from honest day summaries.
extension AppModel {
    func weekBars(containing date: Date) -> [PaceBarChart.Bar] {
        let calendar = displayCalendar
        return days(containing: date, scope: .week).enumerated().map { index, day in
            let result = self.summary(on: day)
            let weekday = calendar.component(.weekday, from: day)
            let isToday = calendar.isDate(day, inSameDayAs: self.today)
            let value: Double? = result.isRestDay ? nil : result.progress
            return PaceBarChart.Bar(id: index, label: self.weekdayShort(weekday),
                                    accessibilityLabel: day.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(self.locale)),
                                    value: value, isHighlighted: isToday, isFuture: result.isForecast, reachedGoal: result.goalReached)
        }
    }
}
