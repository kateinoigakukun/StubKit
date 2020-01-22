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
    func stub<T>(of type: T.Type) -> T? {
        // fast path
        if let stub = primaryProvider.stub(of: T.self) {
            return stub
        }
        if isProvidersEmpty { return nil }

        // slow path
        return providers.lazy.compactMap { $0.stub(of: T.self) }.first
    }
}
