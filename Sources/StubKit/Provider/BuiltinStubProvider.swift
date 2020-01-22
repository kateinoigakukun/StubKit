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

struct CompositStubProvider: StubProvider {
    let providers: [StubProvider]
    func stub<T>(of type: T.Type) -> T? {
        providers.lazy.compactMap { $0.stub(of: T.self) }.first
    }
}
