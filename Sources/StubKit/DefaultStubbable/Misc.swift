import Foundation

extension Bool: DefaultStubbable {
    static func defaultStub() -> Bool {
        return true
    }
}

extension URL: DefaultStubbable {
    static func defaultStub() -> URL {
        return URL(string: "https://example.com")!
    }
}

#if compiler(>=5)
extension Result: DefaultStubbable where Success: DefaultStubbable {
    static func defaultStub() -> Result<Success, Failure> {
        return .success(.defaultStub())
    }
}
#endif
