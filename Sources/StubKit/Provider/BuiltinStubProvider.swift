struct BuiltinStubProvider: StubProvider {
    func stub<T>(of type: T.Type) -> T? {
        if let stub = StubbableProvider().stub(of: T.self) {
            return stub
        }
        if let stub = EnumStubProvider().stub(of: T.self) {
            return stub
        }
        return nil
    }
}

struct CompositStubProviderWith<Primary: StubProvider>: StubProvider {
    let primaryProvider: Primary
    let providers: [StubProvider]
    let isProvidersEmpty: Bool

    init(primaryProvider: Primary, providers: [StubProvider]) {
        self.primaryProvider = primaryProvider
        self.providers = providers
        self.isProvidersEmpty = providers.isEmpty
    }
    func stub<T>(of type: T.Type) throws -> T? {
        // fast path
        if let stub = try primaryProvider.stub(of: T.self) {
            return stub
        }
        if isProvidersEmpty { return nil }

        // slow path
        return try providers.lazy.compactMap { try $0.stub(of: T.self) }.first
    }
}
