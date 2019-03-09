/// `Stub` is smart stubbing system for `Decodable` entity.
///
/// e.g.
/// struct Item: Codable {
///     public var id: Id
///     public var name: String
///     public var description: String?
///     ...
/// }
///
/// let stub: Item = try Stub.make(Item.self)
///
public struct Stub<T: Decodable> {

    let decoder: StubDecoder
    let context: StubDecoderContext

    /// Maximum length of `Unkeyed` object like `Array`.
    /// Default is 60.
    public var maxSequenceLength: Int {
        get { return context.maxSequenceLength }
        set { context.maxSequenceLength = newValue }
    }

    /// Maximum depth for decoding nested types like optionals and structs.
    /// This value avoid infinite decoding loop.
    /// Default is 2.
    public var maxDepth: Int {
        get { return context.maxDepth }
        set { context.maxDepth = newValue }
    }

    init(type: T.Type, context: StubDecoderContext) {
        self.decoder = StubDecoder(codingPath: [], context: context, parentTypes: [])
        self.context = context
    }

    /// Initialize a new `Stub` instance.
    ///
    /// - Parameter type: The type of the entity you want to stub.
    public init(type: T.Type = T.self) {
        self.init(type: type, context: .init(maxSequenceLength: 60, maxDepth: 2))
    }

    /// Make a stub of `T`.
    /// e.g.
    /// let item = Stub(type: Item.self).make {
    ///     $0.set(\.id, value: 1)
    /// }
    ///
    /// - Parameter mutation: Mutation for stub entity.
    /// - Returns: A stub of `T`.
    /// - Throws: `StubDecodingError.notConformingToStubbable` if leaf of `T` does not conform to `Stubbable`.
    /// - Throws: `InjectionError.unsupportedProperty` if you try to inject unsupported property type like `didSet`.
    public func make(_ mutation: (Injector) -> Void = { _ in }) throws -> T {
        let instance = try decoder.stub(of: T.self)
        let injector = Injector()
        mutation(injector)
        return try injector.inject(to: instance)
    }

    /// Convenience method of `Stub(type: T.self).make()`
    ///
    /// - Parameter type: The type of the entity you want to stub.
    /// - Parameter mutation: Mutation for stub entity.
    /// - Returns: A stub of `T`.
    /// - Throws: `StubDecodingError.notConformingToStubbable` if leaf of `T` does not conform to `Stubbable`.
    public static func make(_ type: T.Type = T.self, _ mutation: (Injector) -> Void = { _ in }) throws -> T {
        return try Stub(type: type).make(mutation)
    }
}
