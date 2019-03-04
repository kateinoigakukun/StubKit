extension String: DefaultStubbable {
    static func defaultStub() -> String {
        return "This is Stub String"
    }
}

extension Character: DefaultStubbable {
    static func defaultStub() -> Character {
        return "🍣"
    }
}
