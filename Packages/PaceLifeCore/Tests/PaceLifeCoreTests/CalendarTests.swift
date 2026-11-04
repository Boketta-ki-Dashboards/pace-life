import Foundation
import XCTest
@testable import PaceLifeCore

final class CalendarTests: XCTestCase {
    private static func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }
    private static var berlin: Calendar {
        var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "Europe/Berlin")!; c.firstWeekday = 2; return c
    }
    func testCalendarRangesUseCivilDaysAcrossDSTAndYearBoundaries() {
        let march = PlanningCalendar.days(containing: Self.date("2026-03-29T12:00:00Z"), scope: .month, calendar: Self.berlin)
        XCTAssertEqual(march.count, 31)
        XCTAssertEqual(Set(march.map { DayKey(date: $0, calendar: Self.berlin) }).count, 31)
        XCTAssertEqual(DayKey(date: march.first!, calendar: Self.berlin).rawValue, "2026-03-01")
        XCTAssertEqual(DayKey(date: march.last!, calendar: Self.berlin).rawValue, "2026-03-31")
        XCTAssertTrue(zip(march, march.dropFirst()).contains { $1.timeIntervalSince($0) == 23 * 3600 })
        let week = PlanningCalendar.days(containing: Self.date("2027-01-01T12:00:00Z"), scope: .week, calendar: Self.berlin)
        XCTAssertEqual(week.count, 7)
        XCTAssertEqual(DayKey(date: week.first!, calendar: Self.berlin).rawValue, "2026-12-28")
        XCTAssertEqual(DayKey(date: week.last!, calendar: Self.berlin).rawValue, "2027-01-03")
    }
    func testPastCalendarShowsFactsInsteadOfInventingMissedPlans() async throws {
        try await MainActor.run {
            let day = Self.date("2026-11-02T12:00:00Z")
            let store = try LifeStore(repository: MemoryStateRepository())
            let habit = Habit(title: "Learn", goalType: .duration, target: 60, createdAt: day)
            try store.saveHabit(habit); try store.record(habitID: habit.id, value: 15, on: day, calendar: Self.berlin)
            let mode = LifeMode(title: "Rest")
            try store.saveMode(mode); try store.activateMode(id: mode.id, at: day.addingTimeInterval(86400))
            let previous = store.overview(on: day, today: day.addingTimeInterval(86400), calendar: Self.berlin)
            XCTAssertNil(previous.plannedHabits)
            XCTAssertNil(previous.plannedRoutines)
            XCTAssertEqual(previous.completions.first?.actualValue, 15)
            XCTAssertEqual(previous.completions.first?.targetSnapshot, 60)
            let future = store.overview(on: day.addingTimeInterval(172800), today: day.addingTimeInterval(86400), calendar: Self.berlin)
            XCTAssertTrue(future.isForecast)
            XCTAssertEqual(future.plannedHabits?.count, 0)
            XCTAssertTrue(future.completions.isEmpty)
        }
    }

    func testStoredDayEditorDatesIgnoreCalendarEraAndPreserveLocalDayAcrossDST() throws {
        let cases = [
            ("2026-03-28", "Europe/Berlin", "2026-03-28T11:00:00Z"),
            ("2026-03-29", "Europe/Berlin", "2026-03-29T10:00:00Z"),
            ("2026-10-25", "Europe/Berlin", "2026-10-25T11:00:00Z"),
            ("2026-11-04", "Pacific/Kiritimati", "2026-11-03T22:00:00Z"),
            ("2026-11-04", "America/Los_Angeles", "2026-11-04T20:00:00Z")
        ]
        for identifier in [Calendar.Identifier.gregorian, .buddhist, .japanese] {
            for (stored, zone, expected) in cases {
                var calendar = Calendar(identifier: identifier)
                calendar.timeZone = try XCTUnwrap(TimeZone(identifier: zone))
                let key = DayKey(rawValue: stored)
                let date = try XCTUnwrap(key.localDate(calendar: calendar))
                XCTAssertEqual(date, Self.date(expected), "Editor must use the stored Gregorian year and local noon")
                XCTAssertEqual(DayKey(date: date, calendar: calendar), key, "Opening and saving must preserve the stored day")
            }
        }
        XCTAssertNil(DayKey(rawValue: "2026-02-30").localDate(calendar: Self.berlin))
        XCTAssertEqual(DayKey(rawValue: "2026-03-29").civilDate, Self.date("2026-03-29T12:00:00Z"))
    }
}
