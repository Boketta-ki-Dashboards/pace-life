import SwiftUI
import PaceLifeCore

@main
@MainActor
struct PaceLifeApp: App {
    @State private var model: AppModel

    init() {
        let support = URL.applicationSupportDirectory
        var folder = support.appendingPathComponent("PaceLife", isDirectory: true)
        #if DEBUG
        // UI tests always use their own store; real user data is never reset.
        if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            let session = UUID(uuidString: ProcessInfo.processInfo.environment["PACE_UI_TEST_SESSION"] ?? "") ?? UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
            folder = support.appendingPathComponent("PaceLifeUITests", isDirectory: true).appendingPathComponent(session.uuidString, isDirectory: true)
            if ProcessInfo.processInfo.arguments.contains("--uitesting-reset") {
                try? FileManager.default.removeItem(at: folder)
            }
        }
        #endif
        _model = State(initialValue: AppModel(repository: JSONStateRepository(url: folder.appendingPathComponent("life.json"))))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(\.locale, model.locale)
                .preferredColorScheme(model.colorScheme)
                .tint(PaceColor.accentStrong)
        }
    }
}
