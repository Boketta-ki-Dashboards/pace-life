import Foundation

public enum IntegrationAvailability: Equatable, Sendable { case unavailable }

/// Deliberately exposes capability state only until a reviewed external contract exists.
public protocol PaceIdentityService: Sendable { var availability: IntegrationAvailability { get } }
public protocol PaceFriendsService: Sendable { var availability: IntegrationAvailability { get } }
public protocol PaceGroupsService: Sendable { var availability: IntegrationAvailability { get } }
public protocol PaceActivityReadService: Sendable { var availability: IntegrationAvailability { get } }

public struct UnavailablePaceServices: PaceIdentityService, PaceFriendsService, PaceGroupsService, PaceActivityReadService {
    public init() {}
    public var availability: IntegrationAvailability { .unavailable }
}
