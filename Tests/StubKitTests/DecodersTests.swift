import XCTest
@testable import StubKit

// MARK: KeyedDecodingContainer
class StubKeyedDecodingContainerTests: XCTestCase {

    func testDecodeEmpty() {
        struct Empty: Decodable {}
        XCTAssertNoThrow(try Stub.make(Empty.self))
    }

    func testDecodeStubbableProperty() {
        struct Item: Codable {
            let property: String
        }
        do {
            let item = try Stub.make(Item.self)
            XCTAssertEqual(item.property, String.stub())
        } catch {
            XCTFail(String(describing: error))
        }
    }

    func testDecodeDecodableProperty() {
        struct Item: Decodable {
            struct Property: Decodable {
                let value: String
            }
            let property: Property
        }
        do {
            let item = try Stub.make(Item.self)
            XCTAssertEqual(item.property.value, String.stub())
        } catch {
            XCTFail(String(describing: error))
        }
    }

    func testDecodeRecursiveStructure() {
        // Can't decode `RecursiveStructure` and throw StubDecodingError.notConformingToStubbable
        enum RecursiveStructure: Decodable {
            indirect case hasNext(next: RecursiveStructure)

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                self = try .hasNext(next: container.decode(RecursiveStructure.self))
            }
        }

        struct Item: Decodable {
            let recursiveStructure: RecursiveStructure
        }

        XCTAssertThrowsError(try Stub.make(Item.self)) { error in
            guard let stubDecodingError = error as? StubDecodingError else {
                XCTFail(String(describing: error))
                return
            }
            XCTAssertEqual(stubDecodingError, .notConformingToStubbable(RecursiveStructure.self))
        }
    }

    func testEscapableRecursiveStructure() {
        struct Item: Decodable, Equatable {
            let children: [Item]
        }

        do {
            _ = try Stub.make(Item.self)
        } catch {
            XCTFail(String(describing: error))
        }
    }

    func testDecodeUndecodableEnum() {
        enum UndecodableEnum: String, Codable {
            case case1
        }
        struct Item: Codable {
            let undecodableEnum: UndecodableEnum
        }

        do {
            let item = try Stub.make(Item.self)
            XCTAssertEqual(item.undecodableEnum, .case1)
        } catch {
            XCTFail(String(describing: error))
        }
    }

    func testNestedContainer() {
        struct Item: Codable {
            enum NestedCodingKeys: CodingKey {
                case nestedKey
            }
            let property: String
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .property)
                property = try nestedContainer.decode(String.self, forKey: .nestedKey)
            }
        }
        do {
            let item = try Stub.make(Item.self)
            XCTAssertEqual(item.property, String.stub())
        } catch {
            XCTFail(String(describing: error))
        }
    }

    func testNestedUnkeyedContainer() {
        struct Item: Codable {
            let value: String
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                var nestedUnkeyedContainer = try container.nestedUnkeyedContainer(forKey: .value)
                value = try nestedUnkeyedContainer.decode(String.self)
            }
        }

        do {
            let item = try Stub.make(Item.self)
            XCTAssertEqual(item.value, String.stub())
        } catch {
            XCTFail(String(describing: error))
        }
    }

    func testDecodeOptional() {
        // Test for `StubKeyedDecodingContainer`'s `decodeNil` and `contains`
        struct Item: Decodable {
            let optionalValue: String?
        }

        do {
            let item = try Stub.make(Item.self)
            let stringStub = String.stub()
            XCTAssertEqual(item.optionalValue, stringStub)
        } catch {
            XCTFail(String(describing: self))
        }
    }

    func testSuperDecoder() {
        class Super: Codable {
            let value: Item
        }
        struct Item: Codable {
            let _super: Super
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let superDecoder = try container.superDecoder()
                _super = try Super(from: superDecoder)
            }
        }

        do {
            _ = try Stub.make(Item.self)
        } catch let error as StubDecodingError {
            XCTAssertEqual(error, StubDecodingError.notConformingToStubbable(Item.self))
        } catch {
            XCTFail(String(describing: error))
        }
    }

    func testSuperDecoderWithKey() {
        struct Item: Codable {
            struct Super: Codable {
                let value: String
            }
            let _super: Super
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let superDecoder = try container.superDecoder(forKey: ._super)
                _super = try Super(from: superDecoder)
            }
        }

        do {
            let item = try Stub.make(Item.self)
            XCTAssertEqual(item._super.value, String.stub())
        } catch {
            XCTFail(String(describing: self))
        }
    }

}

// MARK: StubSingleValueDecodingContainer
class StubSingleValueDecodingContainerTests: XCTestCase {

    func testDecodeStubbable() {
        struct StubbableValue: Decodable, Stubbable, Equatable {
            let value: String
            static func stub() -> StubbableValue {
                return StubbableValue(value: "sigle_value_stub")
            }
        }

        struct Item: Decodable {
            let property: StubbableValue

            init(from decoder: Decoder) throws {
                property = try decoder.singleValueContainer().decode(StubbableValue.self)
            }
        }

        do {
            let item = try Stub.make(Item.self)
            XCTAssertEqual(item.property, StubbableValue.stub())
        } catch {
            XCTFail(String(describing: error))
        }
    }

    func testDecodeOptional() {

        struct Item: Decodable {
            let optionalProperty: Optional<Int>

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                optionalProperty = try container.decode(Optional<Int>.self)
            }
        }

        do {
            let item = try Stub.make(Item.self)
            XCTAssertEqual(item.optionalProperty, Optional.some(Int.stub()))
        } catch {
            XCTFail(String(describing: error))
        }

        do {
            var stub = Stub(type: Item.self)
            stub.maxDepth = 0
            let item = try stub.make()
            XCTAssertEqual(item.optionalProperty, Optional<Int>.none)
        } catch {
            XCTFail(String(describing: error))
        }
    }

    func testDecodeDecodable() {
        struct Item: Decodable {
            let property: String

            init(from decoder: Decoder) throws {
                property = try decoder.singleValueContainer().decode(String.self)
            }
        }

        do {
            let item = try Stub.make(Item.self)
            XCTAssertEqual(item.property, String.stub())
        } catch {
            XCTFail(String(describing: error))
        }
    }

    func testDecodeUndecodableEnum() {
        enum UndecodableEnum: String, Decodable {
            case case1
        }
        struct Item: Decodable {
            let property: UndecodableEnum
            init(from decoder: Decoder) throws {
                property = try decoder.singleValueContainer().decode(UndecodableEnum.self)
            }
        }

        do {
            let item = try Stub.make(Item.self)
            XCTAssertEqual(item.property, .case1)
        } catch {
            XCTFail(String(describing: error))
        }
    }

    func testDecodeIndirectRecursiveSingleValue() {
        struct Box: Decodable, Equatable {
            let content: Content
        }
        struct Content: Decodable, Equatable {
            let children: [Item]
        }
        enum Item: Decodable, Equatable {
            indirect case some(next: Box)

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                self = try .some(next: container.decode(Box.self))
            }
        }
        do {
            var stub = Stub(type: Box.self)
            stub.maxDepth = 2
            stub.maxSequenceLength = 1
            let box = try stub.make()
            XCTAssertEqual(
                box.content,
                Content(children: [])
            )
        } catch {
            XCTFail(String(describing: error))
        }
    }

    func testDecodeDirectResursiveSingleValue() {
        enum Item: Decodable {
            indirect case some(next: Item)

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                self = try .some(next: container.decode(Item.self))
            }
        }

        XCTAssertThrowsError(try Stub.make(Item.self)) { error in
            guard let stubDecodingError = error as? StubDecodingError else {
                XCTFail(String(describing: error))
                return
            }
            switch stubDecodingError {
            case .notConformingToStubbable(let type):
                XCTAssert(type == Item.self as Any.Type)
                return
            }
        }
    }
}

// MARK: UnkeyedDecodingContainer
class StubUnkeyedDecodingContainerTests: XCTestCase {

    func testDecodeStubbable() {
        struct Element: Decodable, Stubbable, Equatable {
            let value: String
            static func stub() -> Element {
                return Element(value: "stubbable_element_stub")
            }
        }
        let maxSequenceLength = 10
        var stubber = Stub(type: [Element].self)
        stubber.maxSequenceLength = maxSequenceLength
        do {
            let array = try stubber.make()
            XCTAssertEqual(array.count, maxSequenceLength)
            XCTAssertEqual(array.first, Element.stub())
        } catch {
            XCTFail(String(describing: error))
        }
    }

    func testDecodeNotStubbable() {
        enum NotStubbable1: Decodable {
            indirect case some(next: NotStubbable1)

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                self = try .some(next: container.decode(NotStubbable1.self))
            }
        }

        struct Box: Decodable {
            let singleValue: NotStubbable1

            init(from decoder: Decoder) throws {
                var container = try decoder.unkeyedContainer()
                singleValue = try container.decode(NotStubbable1.self)
            }
        }

        struct Item: Decodable {
            let box: Box
        }

        XCTAssertThrowsError(try Stub.make(Item.self)) { error in
            guard let stubDecodingError = error as? StubDecodingError else {
                XCTFail(String(describing: error))
                return
            }
            XCTAssertEqual(stubDecodingError, .notConformingToStubbable(NotStubbable1.self))
        }
    }

    func testDecodeUndecodableEnum() {
        enum SingleValue: String, Decodable {
            case case1
        }
        struct Item: Decodable {
            let singleValue: SingleValue
            init(from decoder: Decoder) throws {
                var container = try decoder.unkeyedContainer()
                singleValue = try container.decode(SingleValue.self)
            }
        }

        do {
            let item = try Stub.make(Item.self)
            XCTAssertEqual(item.singleValue, .case1)
        } catch {
            XCTFail(String(describing: error))
        }
    }

    func testNestedContainer() {
        struct UnkeyedItem: Decodable {
            enum NestedCodingKeys: CodingKey {
                case nestedKey
            }
            let values: [String]
            init(values: [String]) { self.values = values }
            init(from decoder: Decoder) throws {
                var container = try decoder.unkeyedContainer()
                var values = [String]()
                while !container.isAtEnd {
                    let value = try container.nestedContainer(keyedBy: NestedCodingKeys.self)
                        .decode(String.self, forKey: .nestedKey)
                    values.append(value)
                }
                self.values = values
            }
        }
        let maxSequenceLength = 10
        var stubber = Stub(type: UnkeyedItem.self)
        stubber.maxSequenceLength = maxSequenceLength
        do {
            let item = try stubber.make()
            XCTAssertEqual(item.values.count, maxSequenceLength)
            XCTAssertEqual(item.values.first, String.stub())
        } catch {
            XCTFail(String(describing: error))
        }
    }

    func testNestedUnkeyedContainer() {
        struct UnkeyedItem: Decodable {
            enum NestedCodingKeys: CodingKey {
                case nestedKey
            }
            let values: [String]
            init(values: [String]) { self.values = values }
            init(from decoder: Decoder) throws {
                var container = try decoder.unkeyedContainer()
                var values = [String]()
                while !container.isAtEnd {
                    var nestedContainer = try container.nestedUnkeyedContainer()
                    let value = try nestedContainer.decode(String.self)
                    values.append(value)
                }
                self.values = values
            }
        }
        let maxSequenceLength = 10
        var stubber = Stub(type: UnkeyedItem.self)
        stubber.maxSequenceLength = maxSequenceLength
        do {
            let item = try stubber.make()
            XCTAssertEqual(item.values.count, maxSequenceLength)
            XCTAssertEqual(item.values.first, String.stub())
        } catch {
            XCTFail(String(describing: error))
        }
    }

    func testDecodeOptionalProperty() {
        struct UnkeyedItem: Decodable {
            let optionalProperties: [Int?]

            init(from decoder: Decoder) throws {
                var container = try decoder.unkeyedContainer()
                var optionalProperties = [Int?]()
                while !container.isAtEnd {
                    let optionalProperty = try container.decodeIfPresent(Int.self)
                    optionalProperties.append(optionalProperty)
                }
                self.optionalProperties = optionalProperties
            }
        }
        let maxSequenceLength = 10
        var stubber = Stub(type: UnkeyedItem.self)
        stubber.maxSequenceLength = maxSequenceLength
        do {
            let item = try stubber.make()
            XCTAssertEqual(item.optionalProperties.count, maxSequenceLength)
            XCTAssertEqual(item.optionalProperties.first, Int.stub())
        } catch {
            XCTFail(String(describing: error))
        }
    }

    func testSuperDecoder() {
        struct UnkeyedItem: Codable {
            struct Super: Codable {
                let value: String
            }
            let _super: Super
            let values: [String]

            init(from decoder: Decoder) throws {
                var container = try decoder.unkeyedContainer()
                self._super = try Super(from: container.superDecoder())
                var values = [String]()
                while !container.isAtEnd {
                    let value = try container.decode(String.self)
                    values.append(value)
                }
                self.values = values
            }
        }
        let maxSequenceLength = 10
        var stubber = Stub(type: UnkeyedItem.self)
        stubber.maxSequenceLength = maxSequenceLength
        do {
            let item = try stubber.make()
            XCTAssertEqual(item.values.count, maxSequenceLength - 1)
            XCTAssertEqual(item._super.value, String.stub())
        } catch {
            XCTFail(String(describing: error))
        }
    }
}


extension String: Stubbable {
    public static func stub() -> String {
        return "This is Stub String"
    }
}

extension Int: Stubbable {
    public static func stub() -> Int {
        return 33550336
    }
}

extension UInt64: Stubbable {
    public static func stub() -> UInt64 {
        return 33550336
    }
}

extension Int64: Stubbable {
    public static func stub() -> Int64 {
        return 33550336
    }
}

extension Float: Stubbable {
    public static func stub() -> Float {
        return 1.6180339887
    }
}

extension Double: Stubbable {
    public static func stub() -> Double {
        return 1.6180339887
    }
}

extension URL: Stubbable {
    public static func stub() -> URL {
        return URL(string: "https://example.com")!
    }
}

extension Bool: Stubbable {
    public static func stub() -> Bool {
        return false
    }
}
