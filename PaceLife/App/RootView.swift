import SwiftUI
import PaceLifeCore

private enum RootTab: String, CaseIterable {
    case today, development, circles, profile
    var copy: Copy { switch self { case .today: .today; case .development: .development; case .circles: .circles; case .profile: .profile } }
    var icon: String { switch self { case .today: "sun.max"; case .development: "chart.xyaxis.line"; case .circles: "person.2"; case .profile: "person.crop.circle" } }
}

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase
    @ScaledMetric(relativeTo: .caption) private var tabFont: CGFloat = 13
    @State private var tab: RootTab = .today

    var body: some View {
        Group {
            if model.loaded {
                NavigationStack {
                    Group {
                        switch tab {
                        case .today: HomeView()
                        case .development: DevelopmentView()
                        case .circles: CirclesView()
                        case .profile: ProfileView()
                        }
                    }
                    .background(PaceColor.background)
                    .safeAreaInset(edge: .bottom, spacing: 0) { dock }
                }
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
                Button { tab = item } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.icon).font(.system(size: 20))
                        Text(model.text(item.copy)).font(.system(size: tabFont, weight: tab == item ? .semibold : .regular))
                            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .padding(.vertical, 8)
                    .foregroundStyle(tab == item ? PaceColor.onSelection : PaceColor.textSecondary)
                    .background(tab == item ? PaceColor.selectionFill : Color.clear, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(model.text(item.copy))
                .accessibilityIdentifier("tab." + item.rawValue)
                .accessibilityAddTraits(tab == item ? .isSelected : [])
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(PaceColor.surface.shadow(color: .black.opacity(0.04), radius: 10, y: -3))
    }
}

struct SaveErrorBanner: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        if model.saveFailed {
            Label(model.text(.saveError), systemImage: "exclamationmark.triangle")
                .font(.callout).foregroundStyle(PaceColor.danger)
                .accessibilityIdentifier("saveError")
        }
    }
}

struct Page<Content: View>: View {
    @Environment(AppModel.self) private var model
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PaceRootHeader(title: title, subtitle: subtitle, placeholderLabel: model.text(.placeholder))
                SaveErrorBanner()
                content
            }
            .padding(.horizontal, 16).padding(.bottom, 24)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(PaceColor.background)
        .toolbar(.hidden, for: .navigationBar)
    }
}
