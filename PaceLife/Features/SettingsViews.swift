import SwiftUI
import PaceLifeCore

struct WidgetEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var widgets: [HomeWidgetPreference] = []
    @State private var initialized = false

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
            .environment(\.editMode, .constant(.active))
            .scrollContentBackground(.hidden).background(PaceColor.background)
            .navigationTitle(model.text(.widgets)).navigationBarTitleDisplayMode(.inline)
            .onAppear { if !initialized { widgets = model.state.widgets; initialized = true } }
            .toolbar {
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
    var body: some View {
        Page(title: model.text(.development)) {
            Text(model.text(.futureDetail)).foregroundStyle(PaceColor.textSecondary)
            future("Life Paths", message: .pathsDetail, icon: "point.topleft.down.to.point.bottomright.curvepath")
            future("Pace Adaptive", message: .adaptiveDetail, icon: "slider.horizontal.3")
            future("Life Chapters", message: .chaptersDetail, icon: "book.closed")
            future("Life Experiments", message: .experimentsDetail, icon: "flask")
        }
    }
    private func future(_ title: String, message: Copy, icon: String) -> some View {
        PaceCard {
            VStack(alignment: .leading, spacing: 12) {
                PaceStatus(title: title, message: model.text(message), systemImage: icon)
                Text(model.text(.unavailable)).font(.caption.weight(.semibold)).foregroundStyle(PaceColor.textSecondary)
            }
        }
    }
}

struct CirclesView: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        Page(title: model.text(.circles)) {
            PaceCard {
                PaceStatus(title: "Pace Circles · " + model.text(.unavailable), message: model.text(.circlesDetail), systemImage: "person.2")
            }
            PaceTile { Label(model.text(.privacy), systemImage: "lock.shield").font(.callout) }
        }
    }
}
