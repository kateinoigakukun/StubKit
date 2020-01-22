/// A type that provide a stub
public protocol StubProvider {
    /// Provide a stub for type
    ///
    /// - Parameter type:  The type you want to stub
    /// - Returns: Return a stub or return nil if you can't instantiate a value.
    func stub<T>(of type: T.Type) -> T?
}

