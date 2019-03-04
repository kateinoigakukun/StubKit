/// A type that have a custom stub
public protocol Stubbable {
    static func stub() -> Self
}

/// A type that have a default stub
internal protocol DefaultStubbable {
    static func defaultStub() -> Self
}
