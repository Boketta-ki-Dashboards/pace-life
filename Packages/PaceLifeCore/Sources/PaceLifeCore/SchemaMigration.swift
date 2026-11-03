import Foundation

/// Frozen schema-one shape. Never add defaults here to accommodate a broken old document.
/// New schema fields remain mandatory in the current Codable LifeState.
struct SchemaOneEnvelope: Decodable {
    let schemaVersion: Int
    let state: SchemaOneState
}
struct SchemaOneState: Decodable {
    let habits: [Habit]
    let modes: [LifeMode]
    let completions: [HabitCompletion]
    let activations: [ModeActivation]
    let activeModeID: UUID?
    let widgets: [HomeWidgetPreference]
    let settings: AppSettings

    func migrated() throws -> LifeState {
        let legacyKinds: Set<HomeWidgetKind> = [.progress, .mode, .habits]
        guard widgets.count == legacyKinds.count, Set(widgets.map(\.kind)) == legacyKinds else { throw LifeError.invalidWidgets }
        var result = LifeState(habits: habits, modes: modes, completions: completions,
                               activations: activations, activeModeID: activeModeID,
                               widgets: widgets, settings: settings)
        result.widgets.append(HomeWidgetPreference(kind: .routines, isVisible: false))
        try result.validate()
        return result
    }
}
