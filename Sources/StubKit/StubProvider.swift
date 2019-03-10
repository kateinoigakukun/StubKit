/// A type that provide a stub
public protocol StubProvider {
    /// Provide a stub for type
    ///
    /// - Parameter type:  The type you want to stub
    /// - Returns: Return a stub or return nil if you can't instantiate a value.
    func stub<T>(of type: T.Type) -> T?
}

extension Array: StubProvider where Element == StubProvider {
    public func stub<T>(of type: T.Type) -> T? {
        return lazy.compactMap { $0.stub(of: type) }.first
    }
}

