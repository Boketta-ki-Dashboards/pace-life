import SwiftUI
import PaceLifeCore

/// Pace dashboard. Every widget reads real stored data; the layout (order, visibility,
/// size) is the user's persisted `HomeWidgetPreference` list and is edited in place.
struct HomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(Navigator.self) private var navigator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var editing = false
    @State private var draft: [HomeWidgetPreference] = []
    @State private var addingWidget = false
    @State private var newHabit = false

    private var layout: [HomeWidgetPreference] { editing ? draft : model.state.widgets }

    var body: some View {
        Page(title: model.greeting(), subtitle: nil) {
            Button(action: toggleEditing) {
                Label(editing ? model.text(.done) : model.dash(.customize), systemImage: editing ? "checkmark" : "slider.horizontal.3")
            }
            .buttonStyle(PaceCompactButtonStyle())
            .accessibilityIdentifier(editing ? "saveWidgets" : "customizeWidgets")
        } accessory: {
            if editing {
                Button { addingWidget = true } label: { Label(model.dash(.addWidget), systemImage: "plus") }
                    .buttonStyle(PaceCompactButtonStyle())
                    .accessibilityIdentifier("addWidget")
            } else {
                PaceIconButton(systemImage: "calendar", label: model.calendarText(.calendar)) { navigator.open(.calendar) }
                    .accessibilityIdentifier("openCalendar")
                PaceIconButton(systemImage: "chart.bar.xaxis", label: model.dash(.statistics)) { navigator.open(.statistics) }
                    .accessibilityIdentifier("openStatistics")
            }
        } content: {
            if editing {
                Label(model.dash(.editHint), systemImage: "hand.draw")
                    .font(.subheadline).foregroundStyle(PaceColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if model.activeHabits.isEmpty {
                welcomeCard
            }
            let visible = layout.filter(\.isVisible)
            if visible.isEmpty {
                PaceCard { PaceEmptyState(systemImage: "rectangle.3.group", title: model.text(.noWidgets), message: model.dash(.widgetLibrary)) }
            }
            ForEach(visible) { widget in
                WidgetChrome(editing: editing, widget: widget, isFirst: widget.kind == visible.first?.kind, isLast: widget.kind == visible.last?.kind,
                             remove: { setVisible(widget.kind, false) }, resize: { resize(widget.kind, $0) },
                             moveUp: { move(widget.kind, by: -1) }, moveDown: { move(widget.kind, by: 1) },
                             drop: { source in move(source, before: widget.kind) }) {
                    widgetView(widget)
                }
            }
        }
        .sheet(isPresented: $newHabit) { HabitEditor() }
        .sheet(isPresented: $addingWidget) {
            WidgetLibrary(hidden: draft.filter { !$0.isVisible }.map(\.kind)) { kind in
                setVisible(kind, true, moveToEnd: true)
            }
        }
    }

    // MARK: Editing

    private func toggleEditing() {
        if editing {
            if model.setWidgets(draft) {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { editing = false }
            }
        } else {
            draft = model.state.widgets
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { editing = true }
        }
    }

    private func setVisible(_ kind: HomeWidgetKind, _ visible: Bool, moveToEnd: Bool = false) {
        guard let index = draft.firstIndex(where: { $0.kind == kind }) else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
            var item = draft.remove(at: index)
            item.isVisible = visible
            if moveToEnd, let last = draft.lastIndex(where: \.isVisible) { draft.insert(item, at: last + 1) }
            else if moveToEnd { draft.insert(item, at: 0) }
            else { draft.insert(item, at: index) }
        }
    }

    private func resize(_ kind: HomeWidgetKind, _ size: HomeWidgetSize) {
        guard let index = draft.firstIndex(where: { $0.kind == kind }) else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { draft[index].size = size }
    }

    /// Moves among visible widgets; hidden preferences keep their relative order.
    private func move(_ kind: HomeWidgetKind, by offset: Int) {
        let visible = draft.filter(\.isVisible).map(\.kind)
        guard let position = visible.firstIndex(of: kind), visible.indices.contains(position + offset) else { return }
        let neighbour = visible[position + offset]
        if offset < 0 { move(kind, before: neighbour) } else { move(neighbour, before: kind) }
    }

    private func move(_ source: HomeWidgetKind, before target: HomeWidgetKind) {
        guard source != target, let from = draft.firstIndex(where: { $0.kind == source }) else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
            let item = draft.remove(at: from)
            let to = draft.firstIndex(where: { $0.kind == target }) ?? draft.count
            draft.insert(item, at: to)
        }
    }

    // MARK: Widgets

    @ViewBuilder private func widgetView(_ widget: HomeWidgetPreference) -> some View {
        switch widget.kind {
        case .overview: OverviewTiles()
        case .progress: HeroProgressCard(size: widget.resolvedSize)
        case .streak: StreakCard()
        case .habits: HabitsWidget(size: widget.resolvedSize, add: { newHabit = true })
        case .routines: RoutinesWidget(size: widget.resolvedSize)
        case .week: WeekWidget(size: widget.resolvedSize)
        case .mode: ModeWidget()
        case .paths: PathsWidget(size: widget.resolvedSize)
        case .adaptive: AdaptiveWidget()
        case .calendar: CalendarWidget(size: widget.resolvedSize)
        case .circles: CirclesWidget()
        case .experiments: ExperimentsWidget()
        case .chapters: ChaptersWidget()
        }
    }

    private var welcomeCard: some View {
        PaceCard {
            VStack(alignment: .leading, spacing: PaceSpacing.s) {
                Image(systemName: "leaf").font(.title).foregroundStyle(PaceColor.accent).accessibilityHidden(true)
                Text(model.text(.noHabits)).font(.title3.weight(.semibold))
                Text(model.text(.welcomeDetail)).foregroundStyle(PaceColor.textSecondary)
                Button(model.text(.newHabit)) { newHabit = true }
                    .buttonStyle(PaceButtonStyle()).accessibilityIdentifier("welcome.addHabit")
            }
        }
    }
}

/// Edit-mode frame of one widget: remove, size menu, move menu and drag handle.
/// Widget content stays visible but inert while editing.
private struct WidgetChrome<Content: View>: View {
    @Environment(AppModel.self) private var model
    let editing: Bool
    let widget: HomeWidgetPreference
    let isFirst: Bool
    let isLast: Bool
    let remove: () -> Void
    let resize: (HomeWidgetSize) -> Void
    let moveUp: () -> Void
    let moveDown: () -> Void
    let drop: (HomeWidgetKind) -> Void
    @ViewBuilder var content: Content

    var body: some View {
        if editing {
            let name = model.widgetName(widget.kind)
            VStack(alignment: .leading, spacing: PaceSpacing.xs) {
                HStack(spacing: PaceSpacing.xs) {
                    Button(action: remove) {
                        Image(systemName: "xmark").font(.caption.weight(.bold)).foregroundStyle(PaceColor.textPrimary)
                            .frame(width: 28, height: 28).background(PaceColor.fieldBackground, in: Circle())
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(model.dash(.removeWidget) + ": " + name)
                    .accessibilityIdentifier("widget.remove." + widget.kind.rawValue)
                    Text(name).font(.subheadline.weight(.semibold)).lineLimit(1)
                    Spacer(minLength: 0)
                    let sizes = model.supportedSizes(widget.kind)
                    if !sizes.isEmpty {
                        Menu {
                            ForEach(sizes, id: \.self) { size in
                                Button { resize(size) } label: {
                                    if size == widget.resolvedSize { Label(model.widgetSizeName(size), systemImage: "checkmark") }
                                    else { Text(model.widgetSizeName(size)) }
                                }
                            }
                        } label: {
                            Label(model.widgetSizeName(widget.resolvedSize), systemImage: "rectangle.expand.vertical")
                                .font(.footnote).foregroundStyle(PaceColor.textSecondary)
                                .frame(minHeight: 44)
                        }
                        .accessibilityLabel(model.dash(.chooseSize) + ": " + name)
                        .accessibilityValue(model.widgetSizeName(widget.resolvedSize))
                        .accessibilityIdentifier("widget.size." + widget.kind.rawValue)
                    }
                    Menu {
                        Button(action: moveUp) { Label(model.dash(.moveUp), systemImage: "arrow.up") }.disabled(isFirst)
                        Button(action: moveDown) { Label(model.dash(.moveDown), systemImage: "arrow.down") }.disabled(isLast)
                    } label: {
                        Image(systemName: "circle.grid.2x3.fill").font(.body).foregroundStyle(PaceColor.textSecondary)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(model.dash(.moveUp) + " / " + model.dash(.moveDown) + ": " + name)
                    .accessibilityIdentifier("widget.move." + widget.kind.rawValue)
                }
                content
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, PaceSpacing.xs).padding(.bottom, PaceSpacing.xs)
            .background(PaceColor.accentSoft.opacity(0.35), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(PaceColor.accent, lineWidth: 1.5).allowsHitTesting(false) }
            .draggable(widget.kind.rawValue) {
                Label(name, systemImage: model.widgetIcon(widget.kind))
                    .padding(PaceSpacing.s)
                    .background(PaceColor.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .dropDestination(for: String.self) { items, _ in
                guard let raw = items.first, let source = HomeWidgetKind(rawValue: raw) else { return false }
                drop(source)
                return true
            }
            .accessibilityElement(children: .contain)
            .accessibilityAction(named: Text(model.dash(.moveUp))) { if !isFirst { moveUp() } }
            .accessibilityAction(named: Text(model.dash(.moveDown))) { if !isLast { moveDown() } }
        } else {
            content
        }
    }
}

/// Sheet listing widgets that are not on the overview.
private struct WidgetLibrary: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let hidden: [HomeWidgetKind]
    let add: (HomeWidgetKind) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PaceSpacing.s) {
                    Text(model.dash(.widgetLibrary)).font(.subheadline).foregroundStyle(PaceColor.textSecondary)
                    if hidden.isEmpty {
                        PaceCard { PaceEmptyState(systemImage: "checkmark.circle", title: model.dash(.addWidget), message: model.dash(.noHiddenWidgets)) }
                    }
                    ForEach(hidden, id: \.self) { kind in
                        Button { add(kind); dismiss() } label: {
                            PaceSettingsRowLabel(systemImage: model.widgetIcon(kind), title: model.widgetName(kind), showsChevron: false)
                                .overlay(alignment: .trailing) {
                                    Image(systemName: "plus.circle.fill").font(.title2).foregroundStyle(PaceColor.accentStrong)
                                        .padding(.trailing, PaceSpacing.s).accessibilityHidden(true)
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(model.dash(.addWidget) + ": " + model.widgetName(kind))
                        .accessibilityIdentifier("widget.add." + kind.rawValue)
                    }
                }
                .padding(PaceSpacing.m)
            }
            .background(PaceColor.background)
            .navigationTitle(model.dash(.addWidget)).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(model.text(.cancel)) { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Individual widgets

/// Four position-style tiles (Pace Social region tiles → Life Mode, streak, routines, paths).
private struct OverviewTiles: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let streak = model.lifeStreak
        let active = model.state.paths.filter { $0.status == .active }
        let pathProgress = active.isEmpty ? 0 : active.map { model.state.pathProgress($0) }.reduce(0, +) / Double(active.count)
        let columns = [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 150 : 74), spacing: PaceSpacing.xs)]
        LazyVGrid(columns: columns, spacing: PaceSpacing.xs) {
            tile(.modes, icon: "circle.hexagongrid", label: "Life Mode",
                 value: model.activeMode?.title ?? model.text(.noMode), detail: model.dash(.active), id: "overview.mode")
            tile(.statistics, icon: "flame", label: model.text(.streak),
                 value: model.number(Double(streak.current)), detail: model.dash(.streakDays, "").trimmingCharacters(in: .whitespaces), id: "overview.streak")
            tile(.routines, icon: "list.bullet.rectangle", label: model.text(.routines),
                 value: model.number(Double(model.completedRoutineCount)) + "/" + model.number(Double(model.dueRoutines.count)),
                 detail: model.dash(.today), id: "overview.routines")
            tile(.paths, icon: "point.topleft.down.to.point.bottomright.curvepath", label: model.dash(.paths),
                 value: active.isEmpty ? "–" : model.percent(pathProgress),
                 detail: model.number(Double(active.count)) + " " + model.dash(.active), id: "overview.paths")
        }
    }

    private func tile(_ route: AppRoute, icon: String, label: String, value: String, detail: String, id: String) -> some View {
        NavigationLink(value: route) {
            VStack(spacing: 2) {
                Image(systemName: icon).font(.system(size: 22)).foregroundStyle(PaceColor.textPrimary)
                    .frame(height: 28).accessibilityHidden(true)
                Text(label).font(.caption).foregroundStyle(PaceColor.textSecondary).lineLimit(1).minimumScaleFactor(0.7)
                Text(value).font(.headline.weight(.heavy)).foregroundStyle(PaceColor.textPrimary)
                    .lineLimit(1).minimumScaleFactor(0.55)
                Text(detail).font(.caption2).foregroundStyle(PaceColor.textSecondary).lineLimit(2).multilineTextAlignment(.center)
            }
            .padding(.horizontal, 6).padding(.vertical, PaceSpacing.s)
            .frame(maxWidth: .infinity, minHeight: 112)
            .background(PaceColor.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(PaceColor.border, lineWidth: 1)
            }
            .overlay(alignment: .topTrailing) {
                Image(systemName: "chevron.right").font(.caption2.weight(.bold)).foregroundStyle(PaceColor.textSecondary)
                    .padding(PaceSpacing.xs).accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(id)
    }
}

/// Hero card modelled on "Deine Schritte heute": big count, goal bar, ring, two shortcuts.
private struct HeroProgressCard: View {
    @Environment(AppModel.self) private var model
    @Environment(Navigator.self) private var navigator
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .largeTitle) private var heroSize: CGFloat = 56
    let size: HomeWidgetSize

    var body: some View {
        let due = model.dueHabits
        let done = model.completedCount
        let progress = model.progress
        PaceCard {
            VStack(alignment: .leading, spacing: PaceSpacing.s) {
                HStack(alignment: .top, spacing: PaceSpacing.xs) {
                    Text(model.dash(.todayHabits)).font(.headline).fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: PaceSpacing.xs)
                    Button { navigator.open(.adaptive) } label: { Label(model.dash(.adjustDay), systemImage: "scope") }
                        .buttonStyle(PaceLinkButtonStyle())
                        .accessibilityIdentifier("hero.adaptive")
                }
                if due.isEmpty {
                    Text(model.dash(.noPlanToday)).foregroundStyle(PaceColor.textSecondary)
                    Text(model.text(.emptyProgress)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
                } else {
                    let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: PaceSpacing.m)) : AnyLayout(HStackLayout(alignment: .center, spacing: PaceSpacing.m))
                    layout {
                        VStack(alignment: .leading, spacing: PaceSpacing.xs) {
                            Text(model.number(Double(done)))
                                .font(.system(size: min(heroSize, 96), weight: .bold)).monospacedDigit()
                                .lineLimit(1).minimumScaleFactor(0.5)
                                .accessibilityIdentifier("hero.completed")
                            Text(model.dash(.ofHabits, model.number(Double(due.count)))).font(.body)
                            PaceProgressBar(progress: progress)
                            Text(done >= due.count ? model.dash(.goalReached) : model.dash(.remaining, model.number(Double(due.count - done))))
                                .font(.subheadline).foregroundStyle(done >= due.count ? PaceColor.accent : PaceColor.textPrimary)
                        }
                        PaceRing(progress: progress, diameter: size == .compact ? 88 : 112, centerText: model.percent(progress))
                            .accessibilityHidden(true)
                    }
                    if size != .compact { shortcuts }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.progress")
    }

    private var shortcuts: some View {
        PaceTile {
            HStack(spacing: 0) {
                NavigationLink(value: AppRoute.routines) {
                    shortcut(icon: "list.bullet.rectangle",
                             value: model.number(Double(model.completedRoutineCount)) + "/" + model.number(Double(model.dueRoutines.count)),
                             label: model.dash(.routinesToday))
                }
                .buttonStyle(.plain).accessibilityIdentifier("hero.routines")
                Rectangle().fill(PaceColor.border).frame(width: 1, height: 36).padding(.horizontal, PaceSpacing.xs).accessibilityHidden(true)
                NavigationLink(value: AppRoute.statistics) {
                    shortcut(icon: "timer", value: model.number(model.todayMinutes), label: model.dash(.focusMinutes))
                }
                .buttonStyle(.plain).accessibilityIdentifier("hero.minutes")
            }
            .padding(.vertical, 4)
        }
    }

    private func shortcut(icon: String, value: String, label: String) -> some View {
        HStack(spacing: PaceSpacing.xs) {
            Image(systemName: icon).font(.title3).foregroundStyle(PaceColor.textPrimary).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(value).font(.headline.weight(.bold)).monospacedDigit().foregroundStyle(PaceColor.textPrimary)
                Text(label).font(.caption).foregroundStyle(PaceColor.textSecondary).lineLimit(2)
            }
            Spacer(minLength: 2)
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(PaceColor.textSecondary).accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct StreakCard: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        let streak = model.lifeStreak
        let today = model.todaySummary
        let status = today.isRestDay ? model.dash(.streakRest) : streak.todayCompleted ? model.dash(.streakDone) : model.dash(.streakOpen)
        NavigationLink(value: AppRoute.statistics) {
            PaceCard {
                HStack(spacing: PaceSpacing.s) {
                    Image(systemName: "flame.fill")
                        .font(.title3)
                        .foregroundStyle(streak.current > 0 ? PaceColor.streak : PaceColor.textSecondary)
                        .frame(width: 44, height: 44)
                        .background(streak.current > 0 ? PaceColor.streak.opacity(0.14) : PaceColor.fieldBackground, in: Circle())
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(model.dash(.streakDays, model.number(Double(streak.current)))).font(.title3.weight(.heavy))
                            .foregroundStyle(PaceColor.textPrimary).accessibilityIdentifier("streak.current")
                        Text(status).font(.subheadline).foregroundStyle(PaceColor.textSecondary)
                    }
                    Spacer(minLength: PaceSpacing.xs)
                    if streak.longest > 0 {
                        Text(model.dash(.record, model.number(Double(streak.longest)))).font(.caption).foregroundStyle(PaceColor.textSecondary)
                    }
                    PaceChevron()
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("home.streak")
    }
}

private struct HabitsWidget: View {
    @Environment(AppModel.self) private var model
    @Environment(Navigator.self) private var navigator
    let size: HomeWidgetSize
    let add: () -> Void

    var body: some View {
        let due = model.dueHabits
        let shown = size == .compact ? Array(due.prefix(3)) : due
        PaceCard {
            VStack(alignment: .leading, spacing: PaceSpacing.s) {
                PaceCardHeader(title: model.text(.habits)) {
                    Button(action: add) { PaceSquareIcon(systemImage: "plus") }
                        .buttonStyle(.plain).accessibilityLabel(model.text(.newHabit)).accessibilityIdentifier("addHabit")
                    NavigationLink(value: AppRoute.habits) { PaceChevron().frame(width: 44, height: 44).contentShape(Rectangle()) }
                        .buttonStyle(.plain).accessibilityLabel(model.text(.manageHabits)).accessibilityIdentifier("manageHabits")
                }
                if due.isEmpty {
                    Text(model.text(.noDueHabits)).foregroundStyle(PaceColor.textSecondary)
                }
                ForEach(shown) { habit in
                    HabitRow(habit: habit, open: { navigator.open(.habit(habit.id)) })
                }
                if shown.count < due.count {
                    NavigationLink(value: AppRoute.habits) {
                        Text("+ " + model.number(Double(due.count - shown.count)) + " " + model.text(.habits)).font(.subheadline)
                    }
                    .buttonStyle(PaceLinkButtonStyle())
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
        let kind = model.dayGoalType(habit)
        let done = completion?.isComplete == true
        PaceTile {
            HStack(spacing: PaceSpacing.xs) {
                Button {
                    if kind == .binary { _ = model.record(habit, value: done ? 0 : 1) }
                    else { record = true }
                } label: {
                    ZStack {
                        if kind == .binary || done {
                            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 28)).foregroundStyle(done ? PaceColor.accent : PaceColor.textSecondary)
                        } else {
                            PaceRing(progress: completion?.progress ?? 0, diameter: 26, lineWidth: 3)
                            Image(systemName: "plus").font(.caption2.weight(.bold)).foregroundStyle(PaceColor.accentStrong)
                        }
                    }
                    .frame(width: 44, height: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.success, trigger: done) { old, new in !old && new }
                .accessibilityLabel(habit.title + ", " + model.text(kind == .binary ? .completed : .recordProgress))
                .accessibilityValue(done ? "1" : "0")
                .accessibilityIdentifier("habit.complete." + habit.title)
                Button(action: open) {
                    HStack(spacing: PaceSpacing.xs) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(habit.title).font(.headline).foregroundStyle(PaceColor.textPrimary)
                                .strikethrough(done && kind == .binary, color: PaceColor.textSecondary)
                            if let entry = model.adaptiveEntry(habit), let adjusted = entry.acceptedTarget {
                                Text(adjusted == 0 ? model.adaptiveText(.deferred) : model.adaptiveText(.adjusted) + ": " + model.number(completion?.actualValue ?? 0) + " / " + model.number(adjusted))
                                    .font(.footnote).foregroundStyle(PaceColor.accentStrong)
                            }
                            if kind != .binary {
                                Text(model.number(completion?.actualValue ?? 0) + " / " + model.number(model.dayTarget(habit)) + (kind == .duration ? " " + model.text(.minutes) : ""))
                                    .font(.footnote).monospacedDigit().foregroundStyle(PaceColor.textSecondary)
                            }
                        }
                        Spacer(minLength: 0)
                        if model.habitStreak(habit) > 0 {
                            Label(model.number(Double(model.habitStreak(habit))), systemImage: "flame.fill")
                                .font(.caption.weight(.semibold)).foregroundStyle(PaceColor.streak)
                        }
                        Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(PaceColor.textSecondary).accessibilityHidden(true)
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain).accessibilityIdentifier("habit.detail." + habit.title)
            }
        }
        .sheet(isPresented: $record) { RecordEditor(habit: habit) }
    }
}

private struct RoutinesWidget: View {
    @Environment(AppModel.self) private var model
    let size: HomeWidgetSize

    var body: some View {
        let due = model.dueRoutines
        let shown = size == .compact ? Array(due.prefix(2)) : due
        PaceCard {
            VStack(alignment: .leading, spacing: PaceSpacing.s) {
                NavigationLink(value: AppRoute.routines) { PaceCardHeader(title: model.text(.routines), chevron: true).contentShape(Rectangle()) }
                    .buttonStyle(.plain).accessibilityIdentifier("manageRoutines")
                if due.isEmpty { Text(model.dash(.noRoutinesToday)).foregroundStyle(PaceColor.textSecondary) }
                ForEach(shown) { routine in
                    let session = model.routineSession(routine.id)
                    NavigationLink(value: AppRoute.routine(routine.id)) {
                        PaceTile {
                            HStack(spacing: PaceSpacing.s) {
                                PaceRing(progress: session?.progress ?? 0, diameter: 32, lineWidth: 4).accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(routine.title).font(.headline).foregroundStyle(PaceColor.textPrimary)
                                    Text(([model.routineTime(routine)].compactMap { $0 } + [model.number(Double(routine.steps.count)) + " " + model.routineText(.steps)]).joined(separator: " · "))
                                        .font(.footnote).foregroundStyle(PaceColor.textSecondary)
                                    if size == .large {
                                        Text(routine.steps.map(\.title).joined(separator: " · ")).font(.footnote).foregroundStyle(PaceColor.textSecondary).lineLimit(2)
                                    }
                                }
                                Spacer(minLength: 0)
                                Text(session.map { model.number(Double($0.completedStepIDs.count)) + "/" + model.number(Double($0.steps.count)) } ?? model.dash(.startRoutine))
                                    .font(.subheadline.weight(.semibold)).monospacedDigit().foregroundStyle(PaceColor.accentStrong)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home.routine." + routine.title)
                }
            }
        }
    }
}

private struct WeekWidget: View {
    @Environment(AppModel.self) private var model
    let size: HomeWidgetSize

    var body: some View {
        let days = model.days(containing: model.today, scope: .week)
        let summaries = days.map { model.summary(on: $0) }
        let elapsed = summaries.filter { !$0.isForecast }
        let known = elapsed.filter { ($0.plannedHabitIDs?.isEmpty == false) }
        let reached = known.filter(\.goalReached).count
        let completed = days.filter { $0 <= model.today }.map { model.metricValue(.completedHabits, on: $0) }.reduce(0, +)
        let progresses = known.compactMap(\.progress)
        let average = progresses.isEmpty ? 0 : progresses.reduce(0, +) / Double(progresses.count)
        PaceCard {
            VStack(alignment: .leading, spacing: PaceSpacing.s) {
                NavigationLink(value: AppRoute.statistics) { PaceCardHeader(title: model.dash(.yourWeek), chevron: true).contentShape(Rectangle()) }
                    .buttonStyle(.plain).accessibilityIdentifier("home.week")
                PaceBarChart(bars: model.weekBars(containing: model.today), top: 1, goal: 1,
                             height: size == .compact ? 90 : 130, format: { model.percent($0) })
                if size != .compact {
                    HStack(spacing: PaceSpacing.xs) {
                        PaceStatTile(value: model.number(completed), label: model.dash(.weekTotal))
                        PaceStatTile(value: model.percent(average), label: model.dash(.weekAverage))
                    }
                }
                Label(model.dash(.daysReached, model.number(Double(reached)), model.number(Double(known.count))), systemImage: "checkmark.circle")
                    .font(.footnote).foregroundStyle(PaceColor.textSecondary)
            }
        }
    }
}

private struct ModeWidget: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        PaceCard {
            HStack(alignment: .center, spacing: PaceSpacing.s) {
                Image(systemName: "circle.hexagongrid.fill").font(.title2).foregroundStyle(PaceColor.accentStrong)
                    .frame(width: 48, height: 48).background(PaceColor.accentSoft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.text(.activeMode)).font(.subheadline).foregroundStyle(PaceColor.textSecondary)
                    Text(model.activeMode?.title ?? model.text(.noMode)).font(.title3.weight(.bold)).foregroundStyle(PaceColor.brand)
                        .accessibilityIdentifier("mode.active")
                    Text(model.activeMode.map { model.modeSummary($0) } ?? model.dash(.modesDetail))
                        .font(.footnote).foregroundStyle(PaceColor.textSecondary)
                }
                Spacer(minLength: PaceSpacing.xs)
                NavigationLink(value: AppRoute.modes) { Text(model.text(.modes)).font(.subheadline.weight(.semibold)) }
                    .buttonStyle(PaceCompactButtonStyle(prominent: false))
                    .accessibilityIdentifier("manageModes")
            }
        }
    }
}

private struct PathsWidget: View {
    @Environment(AppModel.self) private var model
    let size: HomeWidgetSize
    var body: some View {
        let active = model.state.paths.filter { $0.status == .active }
        let shown = size == .compact ? Array(active.prefix(1)) : size == .regular ? Array(active.prefix(3)) : active
        PaceCard {
            VStack(alignment: .leading, spacing: PaceSpacing.s) {
                NavigationLink(value: AppRoute.paths) { PaceCardHeader(title: model.pathText(.paths), chevron: true).contentShape(Rectangle()) }
                    .buttonStyle(.plain).accessibilityIdentifier("home.paths")
                if active.isEmpty { Text(model.pathText(.noPaths)).foregroundStyle(PaceColor.textSecondary) }
                ForEach(shown) { path in
                    let progress = model.state.pathProgress(path)
                    NavigationLink(value: AppRoute.path(path.id)) {
                        PaceTile {
                            VStack(alignment: .leading, spacing: PaceSpacing.xs) {
                                HStack {
                                    Text(path.title).font(.headline).foregroundStyle(PaceColor.textPrimary)
                                    Spacer()
                                    Text(model.percent(progress)).font(.subheadline.weight(.bold)).monospacedDigit().foregroundStyle(PaceColor.textPrimary)
                                }
                                PaceProgressBar(progress: progress, height: 6)
                                if size != .compact, let next = model.nextMilestone(in: path) {
                                    Text(model.dash(.nextUp) + ": " + next.title).font(.footnote).foregroundStyle(PaceColor.textSecondary).lineLimit(1)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct AdaptiveWidget: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        PaceCard {
            VStack(alignment: .leading, spacing: PaceSpacing.s) {
                PaceCardHeader(title: "Pace Adaptive", chevron: false)
                if let plan = model.adaptivePlan {
                    HStack(alignment: .firstTextBaseline, spacing: PaceSpacing.xxs) {
                        Text(model.number(plan.effectiveMinutes)).font(.title.weight(.bold)).monospacedDigit()
                        Text("/ " + model.number(Double(plan.availableMinutes)) + " " + model.text(.minutes)).font(.subheadline).foregroundStyle(PaceColor.textSecondary)
                    }
                    PaceProgressBar(progress: plan.availableMinutes > 0 ? plan.effectiveMinutes / Double(plan.availableMinutes) : 0,
                                    tint: plan.exceedsBudget ? PaceColor.warning : nil)
                    if plan.exceedsBudget { Text(model.adaptiveText(.overBudget)).font(.footnote).foregroundStyle(PaceColor.warning) }
                } else {
                    Text(model.text(.adaptiveDetail)).font(.subheadline).foregroundStyle(PaceColor.textSecondary)
                }
                NavigationLink(value: AppRoute.adaptive) {
                    Text(model.adaptivePlan == nil ? model.dash(.adjustDay) : "Pace Adaptive")
                }
                .buttonStyle(PaceButtonStyle(kind: .secondary))
                .accessibilityIdentifier("manageAdaptive")
            }
        }
    }
}

private struct CalendarWidget: View {
    @Environment(AppModel.self) private var model
    let size: HomeWidgetSize
    var body: some View {
        let scope: CalendarScope = size == .compact ? .week : .month
        let dates = model.days(containing: model.today, scope: scope)
        let summaries = dates.map { model.summary(on: $0) }.filter { !$0.isForecast && $0.plannedHabitIDs?.isEmpty == false }
        NavigationLink(value: AppRoute.calendar) {
            PaceCard {
                VStack(alignment: .leading, spacing: PaceSpacing.s) {
                    PaceCardHeader(title: model.dash(.calendarTitle), chevron: true)
                    HStack {
                        Text(model.today.formatted(.dateTime.month(.wide).year().locale(model.locale))).font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(model.dash(.monthReached, model.number(Double(summaries.filter(\.goalReached).count)), model.number(Double(summaries.count))))
                            .font(.caption).foregroundStyle(PaceColor.textSecondary)
                    }
                    PaceCalendarGrid(dates: dates, scope: scope)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.calendar")
    }
}

private struct CirclesWidget: View {
    @Environment(AppModel.self) private var model
    @Environment(Navigator.self) private var navigator
    var body: some View {
        PaceCard {
            VStack(alignment: .leading, spacing: PaceSpacing.s) {
                Button { navigator.select(.circles) } label: { PaceCardHeader(title: model.dash(.yourCirclesWidget), chevron: true).contentShape(Rectangle()) }
                    .buttonStyle(.plain)
                if model.state.circles.isEmpty { Text(model.dash(.noCirclesWidget)).foregroundStyle(PaceColor.textSecondary) }
                ForEach(model.state.circles.prefix(3)) { circle in
                    NavigationLink(value: AppRoute.circle(circle.id)) {
                        PaceTile {
                            HStack(spacing: PaceSpacing.s) {
                                PaceAvatar(name: circle.title, seed: circle.id, size: 36)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(circle.title).font(.headline).foregroundStyle(PaceColor.textPrimary)
                                    Text(model.circleMembersLine(circle)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
                                }
                                Spacer(minLength: 0)
                                PaceBadge(text: model.circleText(.demo))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct ExperimentsWidget: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        let active = model.state.experiments.filter { $0.status == .active }
        PaceCard {
            VStack(alignment: .leading, spacing: PaceSpacing.s) {
                NavigationLink(value: AppRoute.experiments) { PaceCardHeader(title: model.dash(.activeExperiments), chevron: true).contentShape(Rectangle()) }
                    .buttonStyle(.plain)
                if active.isEmpty { Text(model.dash(.noExperimentsWidget)).foregroundStyle(PaceColor.textSecondary) }
                ForEach(active.prefix(3)) { experiment in
                    NavigationLink(value: AppRoute.experiment(experiment.id)) {
                        PaceTile {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(experiment.title).font(.headline).foregroundStyle(PaceColor.textPrimary)
                                    Text(model.experimentCheckedInToday(experiment) ? model.dash(.checkedInToday) : model.dash(.openCheckIn))
                                        .font(.footnote).foregroundStyle(model.experimentCheckedInToday(experiment) ? PaceColor.accent : PaceColor.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(PaceColor.textSecondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct ChaptersWidget: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        let latest = model.state.chapterTimeline().first
        PaceCard {
            VStack(alignment: .leading, spacing: PaceSpacing.s) {
                NavigationLink(value: AppRoute.chapters) { PaceCardHeader(title: model.dash(.latestChapter), chevron: true).contentShape(Rectangle()) }
                    .buttonStyle(.plain)
                if let latest {
                    NavigationLink(value: AppRoute.chapter(latest.id)) { ChapterRowCard(chapter: latest) }.buttonStyle(.plain)
                } else {
                    Text(model.dash(.noChaptersWidget)).foregroundStyle(PaceColor.textSecondary)
                }
            }
        }
    }
}
