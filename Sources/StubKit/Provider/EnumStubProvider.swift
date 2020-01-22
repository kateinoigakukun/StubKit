struct EnumStubProvider: StubProvider {

    /// Check if `type` is a Enum type.
    /// Notes: `Any.Type` means pointer to type metadata.
    ///         The kind field is a pointer-sized integer that describes the kind of type the metadata describes.
    ///         This field is at offset 0 from the metadata pointer.
    ///         And Enum metadata has a kind as 2.
    ///
    /// References:
    ///   - https://github.com/apple/swift/blob/5a969418030f008c2276e9e4d482928d2b1b50e4/docs/Lexicon.rst
    ///   - https://github.com/apple/swift/blob/5a969418030f008c2276e9e4d482928d2b1b50e4/docs/ABI/TypeMetadata.rst#common-metadata-layout
    ///   - https://qiita.com/kateinoigakukun/items/8718d152c3708a7a314b
    /// - Parameter type: The type you want to check.
    /// - Returns: Whether `type` is a Enum type.
    static func isEnum(_ type: Any.Type) -> Bool {
        let typeMetadata = unsafeBitCast(type, to: UnsafePointer<UInt8>.self)

        // Reference: https://github.com/apple/swift/blob/master/include/swift/ABI/MetadataKind.def
        #if compiler(>=5)
        let enumKind = 1
        #else
        let enumKind = 2
        #endif
        return typeMetadata.pointee == enumKind
    }

    enum EnumKind {

        /// Enum which has no payload.
        /// e.g.
        /// enum Kind {
        ///     case cat
        /// }
        /// enum Status: String {
        ///     case onSale = "on_sale"
        ///     case trading
        /// }
        case noPayload

        /// Enum which has payload.
        /// e.g.
        /// enum Event {
        ///     case select(Item)
        /// }
        case payload

        // Enum which has no cases.
        /// e.g.
        /// enum Never {}
        ///
        case noCases
    }

    /// Check Enum kind.
    /// - Parameter type: The type you want to check.
    /// - Returns: `EnumKind`
    static func enumKind(_ type: Any.Type) -> EnumKind {

        struct TypeMetadata {
            let kind: UInt8
            let typeDescriptor: UnsafePointer<TypeDescriptor>
        }

        /// Notes: Enum type metadata records a pointer to type descriptor which contains basic information like number of cases.
        /// References:
        ///   - https://github.com/apple/swift/blob/6e7051eb1e/docs/ABI/TypeMetadata.rst#nominal-type-descriptor
        struct TypeDescriptor {
            let contextFlag: Int32
            let parent: Int32
            let name: Int
            #if compiler(>=5)
            let reflectionFieldDescriptor: Int32
            #endif
            let payloadCases: Int32
            let noPayloadCases: Int32
        }

        let typeMetadata = unsafeBitCast(type, to: UnsafePointer<TypeMetadata>.self).pointee
        let descriptor = typeMetadata.typeDescriptor.pointee
        if descriptor.payloadCases == 0 && descriptor.noPayloadCases == 0 {
            return .noCases
        } else if descriptor.payloadCases == 0 {
            return .noPayload
        } else {
            return .payload
        }
    }

    enum Error: Swift.Error {
        case notEnumType(Any.Type)
        case notSupportingPayloadEnum(Any.Type)
        case notSupportingNoCasesEnum(Any.Type)
    }

    /// Make a stub of `T`
    /// Notes: **Only supporting no-payload Enum**
    ///
    /// - Parameter type: The `Enum` type that does not have associated values.
    /// - Returns: A stub of `T`
    static func stub<T>(of type: T.Type) throws -> T {
        guard EnumStubProvider.isEnum(type) else { throw Error.notEnumType(T.self) }
        switch EnumStubProvider.enumKind(type) {
        case .noPayload:
            return withUnsafePointer(to: 0) {
                UnsafeRawPointer($0).assumingMemoryBound(to: T.self).pointee
            }
        case .payload:
            throw Error.notSupportingPayloadEnum(type)
        case .noCases:
            throw Error.notSupportingNoCasesEnum(type)
        }
    }

    func stub<T>(of type: T.Type) -> T? {
        return try? EnumStubProvider.stub(of: type)
    }
}
