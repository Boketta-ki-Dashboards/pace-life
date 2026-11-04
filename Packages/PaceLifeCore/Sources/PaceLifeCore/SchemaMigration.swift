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
        result.widgets.append(HomeWidgetPreference(kind: .paths, isVisible: false))
        result.widgets.append(HomeWidgetPreference(kind: .adaptive, isVisible: false))
        try result.validate()
        return result
    }
}

struct SchemaTwoEnvelope: Decodable {
    let schemaVersion: Int
    let state: SchemaTwoState
}
struct SchemaTwoState: Decodable {
    let habits: [Habit]
    let modes: [LifeMode]
    let completions: [HabitCompletion]
    let activations: [ModeActivation]
    let activeModeID: UUID?
    let widgets: [HomeWidgetPreference]
    let settings: AppSettings
    let routines: [Routine]
    let routineSessions: [RoutineSession]
    func migrated() throws -> LifeState {
        let kinds: Set<HomeWidgetKind> = [.progress, .mode, .habits, .routines]
        guard widgets.count == kinds.count, Set(widgets.map(\.kind)) == kinds else { throw LifeError.invalidWidgets }
        var result = LifeState(habits: habits, modes: modes, completions: completions,
                               activations: activations, activeModeID: activeModeID,
                               widgets: widgets, settings: settings, routines: routines, routineSessions: routineSessions)
        result.widgets.append(HomeWidgetPreference(kind: .paths, isVisible: false))
        result.widgets.append(HomeWidgetPreference(kind: .adaptive, isVisible: false))
        try result.validate()
        return result
    }
}

struct SchemaThreeEnvelope: Decodable {
    let schemaVersion: Int
    let state: SchemaThreeState
}
struct SchemaThreeState: Decodable {
    let habits: [Habit]
    let modes: [LifeMode]
    let completions: [HabitCompletion]
    let activations: [ModeActivation]
    let activeModeID: UUID?
    let widgets: [HomeWidgetPreference]
    let settings: AppSettings
    let routines: [Routine]
    let routineSessions: [RoutineSession]
    let paths: [LifePath]
    let pathEntries: [PathEntry]
    func migrated() throws -> LifeState {
        let kinds: Set<HomeWidgetKind> = [.progress, .mode, .habits, .routines, .paths]
        guard widgets.count == kinds.count, Set(widgets.map(\.kind)) == kinds else { throw LifeError.invalidWidgets }
        var result = LifeState(habits: habits, modes: modes, completions: completions,
                               activations: activations, activeModeID: activeModeID, widgets: widgets,
                               settings: settings, routines: routines, routineSessions: routineSessions,
                               paths: paths, pathEntries: pathEntries)
        result.widgets.append(HomeWidgetPreference(kind: .adaptive, isVisible: false))
        try result.validate()
        return result
    }
}

struct SchemaFourEnvelope: Decodable {
    let schemaVersion: Int
    let state: SchemaFourState
}
struct SchemaFourState: Decodable {
    let habits: [Habit]
    let modes: [LifeMode]
    let completions: [HabitCompletion]
    let activations: [ModeActivation]
    let activeModeID: UUID?
    let widgets: [HomeWidgetPreference]
    let settings: AppSettings
    let routines: [Routine]
    let routineSessions: [RoutineSession]
    let paths: [LifePath]
    let pathEntries: [PathEntry]
    let adaptivePlans: [DailyAdaptivePlan]
    func migrated() -> LifeState {
        LifeState(habits: habits, modes: modes, completions: completions, activations: activations,
                  activeModeID: activeModeID, widgets: widgets, settings: settings, routines: routines,
                  routineSessions: routineSessions, paths: paths, pathEntries: pathEntries, adaptivePlans: adaptivePlans)
    }
}

struct SchemaFiveEnvelope: Decodable {
    let schemaVersion: Int
    let state: SchemaFiveState
}
struct SchemaFiveState: Decodable {
    let base: SchemaFourState
    let chapters: [LifeChapter]
    enum CodingKeys: String, CodingKey { case chapters }
    init(from decoder: Decoder) throws {
        base = try SchemaFourState(from: decoder)
        chapters = try decoder.container(keyedBy: CodingKeys.self).decode([LifeChapter].self, forKey: .chapters)
    }
    func migrated() -> LifeState {
        var state = base.migrated(); state.chapters = chapters; return state
    }
}
