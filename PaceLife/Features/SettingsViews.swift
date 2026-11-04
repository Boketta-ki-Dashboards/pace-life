import SwiftUI
import PaceLifeCore

struct WidgetEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var widgets: [HomeWidgetPreference] = []
    @State private var initialized = false
    @State private var editMode: EditMode = .inactive

    var body: some View {
        NavigationStack {
            List {
                SaveErrorBanner()
                Section {
                    ForEach($widgets) { $widget in
                        Toggle(model.widgetName(widget.kind), isOn: $widget.isVisible)
                            .accessibilityIdentifier("widget." + widget.kind.rawValue)
                    }.onMove { source, destination in widgets.move(fromOffsets: source, toOffset: destination) }
                } footer: { Text(model.text(.widgetsHelp)) }
            }
            .environment(\.editMode, $editMode)
            .scrollContentBackground(.hidden).background(PaceColor.background)
            .navigationTitle(model.text(.widgets)).navigationBarTitleDisplayMode(.inline)
            .onAppear { if !initialized { widgets = model.state.widgets; initialized = true } }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    EditButton().environment(\.editMode, $editMode)
                        .accessibilityIdentifier("reorderWidgets")
                }
                ToolbarItem(placement: .cancellationAction) { Button(model.text(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(model.text(.save)) { if model.setWidgets(widgets) { dismiss() } }.accessibilityIdentifier("saveWidgets")
                }
            }
        }
    }
}

struct ProfileView: View {
    @Environment(AppModel.self) private var model
    @State private var modes = false
    @State private var habits = false
    @State private var widgets = false

    var body: some View {
        Page(title: model.text(.profile), subtitle: model.text(.localOnly)) {
            PaceCard {
                VStack(alignment: .leading, spacing: 16) {
                    Label(model.text(.theme), systemImage: "circle.lefthalf.filled").font(.headline)
                    Picker(model.text(.theme), selection: Binding(get: { model.state.settings.theme }, set: { model.setTheme($0) })) {
                        Text(model.text(.automatic)).tag(AppTheme.system)
                        Text(model.text(.light)).tag(AppTheme.light)
                        Text(model.text(.dark)).tag(AppTheme.dark)
                    }.pickerStyle(.menu).accessibilityIdentifier("theme")
                    Divider()
                    Label(model.text(.language), systemImage: "globe").font(.headline)
                    Picker(model.text(.language), selection: Binding(get: { model.state.settings.language }, set: { model.setLanguage($0) })) {
                        Text("Deutsch").tag(AppLanguage.de)
                        Text("English").tag(AppLanguage.en)
                        Text("Русский").tag(AppLanguage.ru)
                    }.pickerStyle(.menu).accessibilityIdentifier("language")
                }
            }
            PaceCard {
                VStack(spacing: 8) {
                    settingsButton(.modes, icon: "circle.hexagongrid") { modes = true }
                        .accessibilityIdentifier("profile.modes")
                    Divider()
                    settingsButton(.habits, icon: "checklist") { habits = true }
                    Divider()
                    settingsButton(.widgets, icon: "rectangle.3.group") { widgets = true }
                }
            }
            PaceCard { PaceStatus(title: model.text(.privacy), message: model.text(.privacyDetail), systemImage: "lock.shield") }
            PaceCard { PaceStatus(title: "Pace Connect · " + model.text(.unavailable), message: model.text(.connectDetail), systemImage: "link") }
            Text("Pace Life · " + model.text(.version)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
        }
        .sheet(isPresented: $modes) { ModesView() }
        .sheet(isPresented: $habits) { HabitsView() }
        .sheet(isPresented: $widgets) { WidgetEditor() }
    }

    private func settingsButton(_ key: Copy, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack { Label(model.text(key), systemImage: icon); Spacer(); Image(systemName: "chevron.right") }
                .frame(minHeight: 48).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}

struct DevelopmentView: View {
    @Environment(AppModel.self) private var model
    @State private var paths = false
    @State private var chapters = false
    @State private var experiments = false
    @State private var adaptive = false
    var body: some View {
        Page(title: model.text(.development)) {
            Button("Life Paths") { paths = true }.buttonStyle(PaceButtonStyle()).accessibilityIdentifier("managePaths")
            Button("Pace Adaptive") { adaptive = true }.buttonStyle(PaceButtonStyle(kind: .secondary))
            Button("Life Chapters") { chapters = true }.buttonStyle(PaceButtonStyle(kind: .secondary)).accessibilityIdentifier("manageChapters")
            Button("Life Experiments") { experiments = true }.buttonStyle(PaceButtonStyle(kind: .secondary)).accessibilityIdentifier("manageExperiments")
        }.sheet(isPresented: $paths) { PathsView() }
            .sheet(isPresented: $chapters) { ChaptersView() }
            .sheet(isPresented: $experiments) { ExperimentsView() }
            .sheet(isPresented: $adaptive) { AdaptiveView() }
    }
}
