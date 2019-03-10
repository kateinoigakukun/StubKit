struct StubbableProvider: StubProvider {
    func stub<T>(of type: T.Type) -> T? {
        if let stubbable = type as? Stubbable.Type {
            return stubbable.stub() as? T
        }
        if let stubbable = type as? DefaultStubbable.Type {
            return stubbable.defaultStub() as? T
        }
        return nil
    }
}
