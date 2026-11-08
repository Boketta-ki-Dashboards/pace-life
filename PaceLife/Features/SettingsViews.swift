import SwiftUI
import PaceLifeCore

/// Accessible list editor for the home layout (also reachable from Profile).
struct WidgetEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var widgets: [HomeWidgetPreference] = []
    @State private var initialized = false
    @State private var editMode: EditMode = .active

    var body: some View {
        List {
            SaveErrorBanner()
            Section {
                ForEach($widgets) { $widget in
                    VStack(alignment: .leading, spacing: PaceSpacing.xs) {
                        HStack(spacing: PaceSpacing.s) {
                            Image(systemName: model.widgetIcon(widget.kind)).foregroundStyle(PaceColor.accentStrong).frame(width: 24)
                                .accessibilityHidden(true)
                            Toggle(model.widgetName(widget.kind), isOn: $widget.isVisible)
                                .tint(PaceColor.accentStrong)
                                .accessibilityIdentifier("widget." + widget.kind.rawValue)
                        }
                        if widget.isVisible && !model.supportedSizes(widget.kind).isEmpty {
                            Picker(model.dash(.chooseSize), selection: Binding(get: { widget.resolvedSize }, set: { widget.size = $0 })) {
                                ForEach(model.supportedSizes(widget.kind), id: \.self) { Text(model.widgetSizeName($0)).tag($0) }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                }
                .onMove { source, destination in widgets.move(fromOffsets: source, toOffset: destination) }
            } footer: { Text(model.text(.widgetsHelp)) }
        }
        .environment(\.editMode, $editMode)
        .paceFormStyle()
        .navigationTitle(model.text(.widgets)).navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .onAppear { if !initialized { widgets = model.state.widgets; initialized = true } }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(model.text(.save)) { if model.setWidgets(widgets) { dismiss() } }.accessibilityIdentifier("saveWidgetList")
            }
        }
    }
}

struct ProfileView: View {
    @Environment(AppModel.self) private var model
    @State private var editingName = false

    var body: some View {
        Page(title: model.text(.profile), subtitle: nil) {
            EmptyView()
        } accessory: {
            EmptyView()
        } content: {
            profileCard
            activityCard
            PaceCard {
                VStack(alignment: .leading, spacing: PaceSpacing.s) {
                    Text(model.dash(.appearanceLanguage)).font(.title3.weight(.semibold))
                    PaceSegmentedControl(selection: Binding(get: { model.state.settings.theme }, set: { model.setTheme($0) }),
                                         options: [(AppTheme.system, model.text(.automatic)), (AppTheme.light, model.text(.light)), (AppTheme.dark, model.text(.dark))])
                    PaceTile {
                        HStack {
                            Label(model.text(.language), systemImage: "globe").font(.subheadline)
                            Spacer()
                            Picker(model.text(.language), selection: Binding(get: { model.state.settings.language }, set: { model.setLanguage($0) })) {
                                Text(verbatim: "Deutsch").tag(AppLanguage.de)
                                Text(verbatim: "English").tag(AppLanguage.en)
                                Text(verbatim: "Русский").tag(AppLanguage.ru)
                            }
                            .pickerStyle(.menu).tint(PaceColor.accentStrong)
                            .accessibilityIdentifier("language")
                        }
                        .frame(minHeight: 44)
                    }
                }
            }
            PaceSectionTitle(model.dash(.settings))
            settingsLinks
            PaceCard {
                VStack(alignment: .leading, spacing: PaceSpacing.xs) {
                    Text(model.text(.about)).font(.headline)
                    Text(model.dash(.wordmarkNote)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
                    Text(verbatim: "Pace Life 0.1.0 · " + model.text(.version)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
                }
            }
        }
        .sheet(isPresented: $editingName) { DisplayNameEditor() }
    }

    @ViewBuilder private var settingsLinks: some View {
            NavigationLink(value: AppRoute.modes) {
                PaceSettingsRowLabel(systemImage: "circle.hexagongrid", title: model.text(.modes), subtitle: model.dash(.modesDetail),
                                     value: model.activeMode?.title)
            }
            .buttonStyle(.plain).accessibilityIdentifier("profile.modes")
            NavigationLink(value: AppRoute.habits) {
                PaceSettingsRowLabel(systemImage: "checklist", title: model.text(.habits), subtitle: model.dash(.habitsDetail),
                                     value: model.number(Double(model.activeHabits.count)))
            }
            .buttonStyle(.plain).accessibilityIdentifier("profile.habits")
            NavigationLink(value: AppRoute.widgets) {
                PaceSettingsRowLabel(systemImage: "rectangle.3.group", title: model.dash(.homeLayout), subtitle: model.dash(.homeLayoutDetail))
            }
            .buttonStyle(.plain).accessibilityIdentifier("profile.widgets")
            NavigationLink(value: AppRoute.reminders) {
                PaceSettingsRowLabel(systemImage: "bell", title: model.feature(.reminders), subtitle: model.feature(.remindersDetail),
                                     value: model.number(Double(model.state.reminders.filter(\.isEnabled).count)))
            }
            .buttonStyle(.plain).accessibilityIdentifier("profile.reminders")
            NavigationLink(value: AppRoute.backup) {
                PaceSettingsRowLabel(systemImage: "externaldrive", title: model.feature(.backup), subtitle: model.feature(.backupDetail))
            }
            .buttonStyle(.plain).accessibilityIdentifier("profile.backup")
            NavigationLink(value: AppRoute.connect) {
                PaceSettingsRowLabel(systemImage: "link", title: "Pace Connect", subtitle: model.dash(.connectStatus), value: model.text(.unavailable))
            }
            .buttonStyle(.plain).accessibilityIdentifier("profile.connect")
    }

    private var profileCard: some View {
        PaceCard {
            HStack(spacing: PaceSpacing.s) {
                Image(systemName: "person.fill").font(.title2).foregroundStyle(PaceColor.accentStrong)
                    .frame(width: 56, height: 56).background(PaceColor.accentSoft, in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.state.settings.displayName ?? model.dash(.yourName)).font(.title3.weight(.semibold))
                    Text(model.text(.localOnly)).font(.subheadline).foregroundStyle(PaceColor.textSecondary)
                }
                Spacer(minLength: PaceSpacing.xs)
                Button { editingName = true } label: { PaceSquareIcon(systemImage: "pencil") }
                    .buttonStyle(.plain).accessibilityLabel(model.dash(.yourName)).accessibilityIdentifier("editDisplayName")
            }
        }
    }

    private var activityCard: some View {
        let streak = model.lifeStreak
        return PaceCard {
            VStack(alignment: .leading, spacing: PaceSpacing.s) {
                Text(model.dash(.yourActivity)).font(.title3.weight(.semibold))
                NavigationLink(value: AppRoute.statistics) {
                    activityRow(icon: "flame", title: model.text(.streak) + ": " + model.dash(.streakDays, model.number(Double(streak.current))),
                                detail: model.dash(.record, model.number(Double(streak.longest))))
                }.buttonStyle(.plain)
                NavigationLink(value: AppRoute.statistics) {
                    activityRow(icon: "chart.bar", title: model.dash(.statistics),
                                detail: model.calendarText(.week) + " · " + model.calendarText(.month))
                }.buttonStyle(.plain).accessibilityIdentifier("profile.statistics")
                Text(model.text(.privacyDetail)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
            }
        }
    }

    private func activityRow(icon: String, title: String, detail: String) -> some View {
        PaceTile {
            HStack(spacing: PaceSpacing.s) {
                Image(systemName: icon).foregroundStyle(PaceColor.textSecondary).frame(width: 24).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(PaceColor.textPrimary)
                    Text(detail).font(.caption).foregroundStyle(PaceColor.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(PaceColor.textSecondary).accessibilityHidden(true)
            }
            .frame(minHeight: 44)
        }
        .accessibilityElement(children: .combine)
    }
}

struct DisplayNameEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var initialized = false
    var body: some View {
        NavigationStack {
            Form {
                SaveErrorBanner()
                Section {
                    TextField(model.dash(.yourName), text: $name)
                        .textInputAutocapitalization(.words)
                        .accessibilityIdentifier("displayName")
                } footer: { Text(model.dash(.nameHint)) }
            }
            .paceFormStyle()
            .navigationTitle(model.dash(.yourName)).navigationBarTitleDisplayMode(.inline)
            .onAppear { if !initialized { name = model.state.settings.displayName ?? ""; initialized = true } }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(model.text(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(model.text(.save)) { model.setDisplayName(name); if !model.saveFailed { dismiss() } }
                        .accessibilityIdentifier("saveDisplayName")
                }
            }
        }
        .presentationDetents([.medium])
    }
}

/// Growth tab: shortcuts to every long-term module plus a live summary.
struct DevelopmentView: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        let active = model.state.paths.filter { $0.status == .active }
        let progress = active.isEmpty ? 0 : active.map { model.state.pathProgress($0) }.reduce(0, +) / Double(active.count)
        Page(title: model.text(.development), subtitle: nil) {
            EmptyView()
        } accessory: {
            NavigationLink(value: AppRoute.statistics) {
                Image(systemName: "chart.bar.xaxis").font(.system(size: 20)).foregroundStyle(PaceColor.textPrimary).frame(width: 44, height: 44)
            }
            .buttonStyle(.plain).accessibilityLabel(model.dash(.statistics)).accessibilityIdentifier("development.statistics")
        } content: {
            HStack(spacing: PaceSpacing.xs) {
                PaceStatTile(value: active.isEmpty ? "–" : model.percent(progress), label: model.pathText(.paths), systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                PaceStatTile(value: model.dash(.streakDays, model.number(Double(model.lifeStreak.current))), label: model.text(.streak), systemImage: "flame")
            }
            moduleRow(.paths, icon: "point.topleft.down.to.point.bottomright.curvepath", title: model.pathText(.paths), detail: model.dash(.growthPaths),
                      value: model.number(Double(active.count)), id: "managePaths")
            moduleRow(.statistics, icon: "chart.bar", title: model.dash(.statistics), detail: model.dash(.growthStats), value: nil, id: "openStatisticsDevelopment")
            moduleRow(.chapters, icon: "book.closed", title: "Life Chapters", detail: model.dash(.growthChapters),
                      value: model.number(Double(model.state.chapters.filter { !$0.isArchived }.count)), id: "manageChapters")
            moduleRow(.experiments, icon: "flask", title: "Life Experiments", detail: model.dash(.growthExperiments),
                      value: model.number(Double(model.state.experiments.filter { $0.status == .active }.count)), id: "manageExperiments")
            moduleRow(.adaptive, icon: "slider.horizontal.3", title: "Pace Adaptive", detail: model.dash(.growthAdaptive), value: nil, id: "developmentAdaptive")
            if !active.isEmpty {
                PaceSectionTitle(model.pathText(.active))
                ForEach(active.prefix(3)) { path in
                    NavigationLink(value: AppRoute.path(path.id)) { PathRowCard(path: path) }
                        .buttonStyle(.plain)
                }
            }
        }
    }

    private func moduleRow(_ route: AppRoute, icon: String, title: String, detail: String, value: String?, id: String) -> some View {
        NavigationLink(value: route) {
            PaceSettingsRowLabel(systemImage: icon, title: title, subtitle: detail, value: value)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }
}

/// Honest integration status: nothing is connected, planned capabilities are named.
struct ConnectView: View {
    @Environment(AppModel.self) private var model
    private let services = UnavailablePaceServices()

    var body: some View {
        PaceSubpage(title: "Pace Connect", subtitle: model.dash(.connectStatus)) {
            PaceCard {
                VStack(alignment: .leading, spacing: PaceSpacing.s) {
                    HStack(spacing: PaceSpacing.s) {
                        Image(systemName: "link.badge.plus").font(.title2).foregroundStyle(PaceColor.textSecondary)
                            .frame(width: 48, height: 48).background(PaceColor.fieldBackground, in: Circle())
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(model.dash(.connectStatus)).font(.headline)
                            Text(model.text(.localOnly)).font(.subheadline).foregroundStyle(PaceColor.textSecondary)
                        }
                    }
                    Text(model.dash(.connectNoAccount)).font(.subheadline)
                }
            }
            PaceSectionTitle(model.dash(.connectPlanned))
            capability(model.dash(.connectIdentity), icon: "person.crop.circle.badge.checkmark", available: services.identityAvailability)
            capability(model.dash(.connectFriends), icon: "person.2", available: services.friendsAvailability)
            capability(model.dash(.connectGroups), icon: "person.3", available: services.groupsAvailability)
            capability(model.dash(.connectProgress), icon: "arrow.left.arrow.right", available: services.activityAvailability)
            Text(model.dash(.connectRule)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
        }
    }

    private func capability(_ title: String, icon: String, available: Bool) -> some View {
        PaceSettingsRowLabel(systemImage: icon, title: title, subtitle: available ? model.dash(.connectAvailable) : model.text(.unavailable), showsChevron: false)
            .opacity(available ? 1 : 0.7)
            .accessibilityElement(children: .combine)
    }
}

private extension UnavailablePaceServices {
    /// Reads the capability protocols; every value is `.unavailable` until a reviewed contract exists.
    var identityAvailability: Bool { (self as any PaceIdentityService).availability != .unavailable }
    var friendsAvailability: Bool { (self as any PaceFriendsService).availability != .unavailable }
    var groupsAvailability: Bool { (self as any PaceGroupsService).availability != .unavailable }
    var activityAvailability: Bool { (self as any PaceActivityReadService).availability != .unavailable }
}
