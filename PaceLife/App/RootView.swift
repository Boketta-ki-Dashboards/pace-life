import SwiftUI
import PaceLifeCore

enum RootTab: String, CaseIterable, Hashable {
    case today, development, circles, profile
    var copy: Copy { switch self { case .today: .today; case .development: .development; case .circles: .circles; case .profile: .profile } }
    var icon: String { switch self { case .today: "house"; case .development: "chart.bar"; case .circles: "person.2"; case .profile: "person" } }
    var selectedIcon: String { switch self { case .today: "house.fill"; case .development: "chart.bar.fill"; case .circles: "person.2.fill"; case .profile: "person.fill" } }
}

/// Every pushed subpage. Pushes cover the root pager, so native back swipes never
/// compete with horizontal tab paging; the Pace dock stays visible on all of them.
enum AppRoute: Hashable {
    case habits, habit(UUID), modes, routines, routine(UUID), paths, path(UUID), adaptive, calendar, statistics
    case chapters, chapter(UUID), experiments, experiment(UUID), circle(UUID), challenge(UUID), widgets, connect, reminders, backup
}

@MainActor @Observable
final class Navigator {
    var tab: RootTab = .today
    var path: [AppRoute] = []
    func open(_ route: AppRoute) { path.append(route) }
    /// Dock behaviour: switching tabs (or re-selecting the current one) returns to its root.
    func select(_ tab: RootTab) {
        path.removeAll()
        self.tab = tab
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var navigator = Navigator()

    var body: some View {
        Group {
            if model.loaded {
                NavigationStack(path: Binding(get: { navigator.path }, set: { navigator.path = $0 })) {
                    // Native page gestures provide interactive tracking, cancellation and
                    // velocity-aware settling. Subpages are pushed above this pager.
                    TabView(selection: Binding(get: { navigator.tab }, set: { navigator.tab = $0 })) {
                        HomeView().tag(RootTab.today).accessibilityHidden(navigator.tab != .today)
                        DevelopmentView().tag(RootTab.development).accessibilityHidden(navigator.tab != .development)
                        CirclesView().tag(RootTab.circles).accessibilityHidden(navigator.tab != .circles)
                        ProfileView().tag(RootTab.profile).accessibilityHidden(navigator.tab != .profile)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .background(PaceColor.background)
                    .overlay(alignment: .top) {
                        // Scrolling content never appears behind the status bar.
                        PaceColor.background.ignoresSafeArea(edges: .top).frame(height: 0)
                            .allowsHitTesting(false).accessibilityHidden(true)
                    }
                    .navigationTitle(model.text(navigator.tab.copy))
                    .toolbar(.hidden, for: .navigationBar)
                    .navigationDestination(for: AppRoute.self) { RouteDestination(route: $0) }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) { dock }
                .environment(navigator)
            } else {
                VStack(spacing: 24) {
                    PaceStatus(title: "Pace Life", message: model.text(.loadError), systemImage: "externaldrive.badge.exclamationmark")
                    Button(model.text(.retry)) { model.reload() }.buttonStyle(PaceButtonStyle())
                }.padding(24)
            }
        }
        .foregroundStyle(PaceColor.textPrimary)
        .onChange(of: scenePhase) { _, phase in if phase == .active { model.refreshDay() } }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in model.refreshDay() }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name.NSSystemTimeZoneDidChange)) { _ in model.refreshDay() }
    }

    private var dock: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(RootTab.allCases, id: \.self) { item in
                let selected = navigator.tab == item
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { navigator.select(item) }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: selected ? item.selectedIcon : item.icon)
                            .font(.system(size: 20, weight: selected ? .semibold : .regular))
                            .frame(height: 24)
                        Text(model.text(item.copy)).font(.system(size: 13, weight: selected ? .bold : .medium))
                            .lineLimit(1).minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                    .foregroundStyle(selected ? PaceColor.onSelection : PaceColor.textPrimary)
                    .background(selected ? PaceColor.selectionFill : Color.clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityShowsLargeContentViewer {
                    Label(model.text(item.copy), systemImage: item.icon)
                }
                .accessibilityLabel(model.text(item.copy))
                .accessibilityIdentifier("tab." + item.rawValue)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(.horizontal, 12).padding(.top, 6).padding(.bottom, 4)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("paceDock")
        .background(PaceColor.surface)
        .overlay(alignment: .top) { Rectangle().fill(PaceColor.border).frame(height: 1).accessibilityHidden(true) }
    }
}

/// Maps a route to its page. Routes carry stable IDs; a missing object shows an
/// honest unavailable state instead of crashing (e.g. after deleting a chapter).
struct RouteDestination: View {
    let route: AppRoute
    var body: some View {
        switch route {
        case .habits: HabitsView()
        case .habit(let id): HabitDetailContent(habitID: id)
        case .modes: ModesView()
        case .routines: RoutinesView()
        case .routine(let id): RoutineDetail(routineID: id)
        case .paths: PathsView()
        case .path(let id): PathDetail(pathID: id)
        case .adaptive: AdaptiveView()
        case .calendar: CalendarView()
        case .statistics: StatisticsView()
        case .chapters: ChaptersView()
        case .chapter(let id): ChapterDetail(chapterID: id)
        case .experiments: ExperimentsView()
        case .experiment(let id): ExperimentDetail(experimentID: id)
        case .circle(let id): CircleDetail(circleID: id)
        case .challenge(let id): CircleChallengeDetail(challengeID: id)
        case .widgets: WidgetEditor()
        case .connect: ConnectView()
        case .reminders: RemindersView()
        case .backup: BackupView()
        }
    }
}

struct SaveErrorBanner: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        if model.saveFailed {
            Label(model.text(.saveError), systemImage: "exclamationmark.triangle")
                .font(.callout).foregroundStyle(PaceColor.danger)
                .padding(PaceSpacing.s)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(PaceColor.danger.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .accessibilityIdentifier("saveError")
        }
    }
}

/// Root tab page: Pace header (wordmark + primary action, title + icon actions) and
/// one vertical scroll. Horizontal paging between tabs is handled by the pager.
struct Page<Primary: View, Accessory: View, Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var primary: Primary
    @ViewBuilder var accessory: Accessory
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PaceSpacing.s) {
                PaceRootHeader(title: title, subtitle: subtitle) { primary } accessory: { accessory }
                SaveErrorBanner()
                content
            }
            .padding(.horizontal, PaceSpacing.m).padding(.bottom, PaceSpacing.l)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(PaceColor.background)
    }
}

extension Page where Primary == EmptyView, Accessory == EmptyView {
    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.init(title: title, subtitle: subtitle, primary: { EmptyView() }, accessory: { EmptyView() }, content: content)
    }
}
