struct BuiltinStubProvider: StubProvider {
    func stub<T>(of type: T.Type) -> T? {
        return [StubbableProvider(), EnumStubProvider()].stub(of: type)
    }
}
