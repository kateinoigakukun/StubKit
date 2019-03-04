struct StubDecoder: Decoder {
    let codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey: Any] = [:]
    let context: StubDecoderContext
    /// Parent `SingleValue` types to avoid infinite decoding loop.
    /// e.g.
    /// enum LinkedList<T> {
    ///     case tail
    ///     case next(T, LinkedList<T>)
    /// }
    /// Some types have itself type properties like this `LinkedList`.
    let parentTypes: [Any.Type]

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        return KeyedDecodingContainer(StubKeyedDecodingContainer(codingPath: codingPath, context: context, parentTypes: parentTypes))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return StubUnkeyedDecodingContainer(codingPath: codingPath, context: context, parentTypes: parentTypes)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return StubSingleValueDecodingContainer(codingPath: codingPath, context: context, parentTypes: parentTypes)
    }

    func stub<T: Decodable>(of type: T.Type) throws -> T {
        do {
            return try T(from: self)
        } catch let error as StubDecodingError {
            switch error {
            case .notConformingToStubbable: throw error
            }
        } catch {
            if EnumStub.isEnum(T.self) { return try EnumStub.stub(T.self) }
            throw error
        }
    }
}

private func makeStubFromStubbable<T>(of type: T.Type) -> T? {
    if let stubbable = type as? Stubbable.Type {
        return stubbable.stub() as? T
    }
    if let stubbable = type as? DefaultStubbable.Type {
        return stubbable.defaultStub() as? T
    }
    return nil
}

class StubDecoderContext {
    var maxSequenceLength: Int
    var maxDepth: Int

    init(maxSequenceLength: Int, maxDepth: Int) {
        self.maxSequenceLength = maxSequenceLength
        self.maxDepth = maxDepth
    }
}

public enum StubDecodingError: Error, Equatable {
    case notConformingToStubbable(Any.Type)

    public static func == (lhs: StubDecodingError, rhs: StubDecodingError) -> Bool {
        switch (lhs, rhs) {
        case let (.notConformingToStubbable(ltype), .notConformingToStubbable(rtype)):
            return ltype == rtype
        }
    }
}

struct StubSingleValueDecodingContainer: SingleValueDecodingContainer {
    let codingPath: [CodingKey]
    let context: StubDecoderContext

    /// Parent `SingleValue` types to avoid recursive infinite decoding
    let parentTypes: [Any.Type]

    func decodeNil() -> Bool {
        if context.maxDepth > codingPath.count {
            return false
        }
        return true
    }

    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        if let stub = makeStubFromStubbable(of: type) { return stub }

        // If `parentTypes` contains `T.Type`, `T` may require `T` to decode self.
        if parentTypes.contains(where: { $0 == (T.self as Any.Type) }) {
            throw StubDecodingError.notConformingToStubbable(T.self)
        }

        let decoder = StubDecoder(codingPath: codingPath, context: context, parentTypes: parentTypes + [T.self])
        return try  decoder.stub(of: type)
    }

}

struct StubUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    let codingPath: [CodingKey]
    var count: Int? {
        if codingPath.count >= context.maxDepth {
            return 0
        } else {
            return context.maxSequenceLength
        }
    }
    var isAtEnd: Bool { return currentIndex >= count ?? 0 }
    var currentIndex: Int = 0
    let context: StubDecoderContext
    let parentTypes: [Any.Type]

    init(codingPath: [CodingKey], context: StubDecoderContext, parentTypes: [Any.Type]) {
        self.codingPath = codingPath
        self.context = context
        self.parentTypes = parentTypes
    }

    mutating func decodeNil() throws -> Bool {
        return false
    }

    mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        defer { advance() }
        if let stub = makeStubFromStubbable(of: type) { return stub }

        // If `parentTypes` contains `T.Type`, `T` may require `T` to decode self.
        if parentTypes.contains(where: { $0 == (T.self as Any.Type) }) {
            throw StubDecodingError.notConformingToStubbable(T.self)
        }
        let decoder = StubDecoder(codingPath: codingPath, context: context, parentTypes: parentTypes + [T.self])
        return try decoder.stub(of: type)
    }

    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        defer { advance() }
        return KeyedDecodingContainer(StubKeyedDecodingContainer<NestedKey>(codingPath: codingPath, context: context, parentTypes: parentTypes))
    }

    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        defer { advance() }
        return StubUnkeyedDecodingContainer(codingPath: codingPath, context: context, parentTypes: parentTypes)
    }

    mutating func superDecoder() throws -> Decoder {
        defer { advance() }
        return StubDecoder(codingPath: codingPath, context: context, parentTypes: parentTypes)
    }

    private mutating func advance() {
        currentIndex += 1
    }
}

struct StubKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    let codingPath: [CodingKey]
    let allKeys: [Key] = []
    let context: StubDecoderContext
    let parentTypes: [Any.Type]

    func contains(_ key: Key) -> Bool {
        return true
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        if context.maxDepth > codingPath.count {
            return false
        }
        return true
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
        if let stub = makeStubFromStubbable(of: type) { return stub }
        // If `parentTypes` contains `T.Type`, `T` may require `T` to decode self.
        if parentTypes.contains(where: { $0 == (T.self as Any.Type) }) {
            throw StubDecodingError.notConformingToStubbable(T.self)
        }
        let decoder = StubDecoder(codingPath: codingPath + [key], context: context, parentTypes: parentTypes + [T.self])
        return try decoder.stub(of: type)
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        return KeyedDecodingContainer(StubKeyedDecodingContainer<NestedKey>(codingPath: codingPath + [key], context: context, parentTypes: parentTypes))
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        return StubUnkeyedDecodingContainer(codingPath: codingPath + [key], context: context, parentTypes: parentTypes)
    }

    func superDecoder() throws -> Decoder {
        return StubDecoder(codingPath: codingPath, context: context, parentTypes: parentTypes)
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        return StubDecoder(codingPath: codingPath + [key], context: context, parentTypes: parentTypes)
    }

}
