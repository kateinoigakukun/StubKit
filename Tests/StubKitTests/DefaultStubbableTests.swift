import XCTest
@testable import StubKit

final class DefaultStubbableTests: XCTestCase {

    func testDefaultStub() {
        _ = Int8.defaultStub()
        _ = Int16.defaultStub()
        _ = Int32.defaultStub()
        _ = Int64.defaultStub()
        _ = Int.defaultStub()
        _ = UInt8.defaultStub()
        _ = UInt16.defaultStub()
        _ = UInt32.defaultStub()
        _ = UInt64.defaultStub()
        _ = UInt.defaultStub()
        _ = Float.defaultStub()
        _ = Double.defaultStub()
        _ = String.defaultStub()
        _ = Character.defaultStub()
        _ = Bool.defaultStub()
        _ = URL.defaultStub()
        #if compiler(>=5)
        _ = Result<Int, Error>.defaultStub()
        #endif
    }
}
