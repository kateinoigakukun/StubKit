# StubKit

[![Build Status](https://travis-ci.com/kateinoigakukun/StubKit.svg?token=WvLpRvqJbpyazdGFXQCC&branch=master)](https://travis-ci.com/kateinoigakukun/StubKit) [![codecov](https://codecov.io/gh/kateinoigakukun/StubKit/branch/master/graph/badge.svg?token=WqSnBYoNJq)](https://codecov.io/gh/kateinoigakukun/StubKit)

A smart stubbing system.

## Installation

### Using [Carthage](https://github.com/Carthage/Carthage)

```
github "kateinoigakukun/StubKit"
```

### Using [CocoaPods](https://cocoapods.org/)

```
pod "SwiftStubKit", :git => "https://github.com/kateinoigakukun/StubKit.git"
```

## Usage

### Getting started

You can instantiate any kind of `Decodable` with a single line.

```swift
import StubKit

// Codable struct
struct User: Codable {
  let id: Int
  let name: String
  let sex: Sex
}

let stubUser = try Stub.make(User.self)
// User(id: 1234, name: "This is Stub String", sex: .female)
```

### Customize property

You can customize properties even if the property is defined as `let`.
```swift
let maleUser = try Stub.make(User.self) {
  $0.set(\.sex, value: .male)
}
// User(id: 1234, name: "This is Stub String", sex: .male)
```

### Using `Stubbable`

If you want to customize the default stub value, please conform `Stubbable`.
```swift
extension String: Stubbable {
  static func stub() -> String {
    return "This is custommized Stub String"
  }
}

let stubUser = try Stub.make(User.self)
// User(id: 1234, name: "This is customized Stub String", sex: .female)
```

### Advanced Usage

```swift

struct RandomIntStubProvider: StubProvider {
    func stub<T>(of type: T.Type) -> T? {
        if type is Int.Type {
            return Int.random(in: 0..<100) as? T
        }
        return nil
    }
}

let userStub = Stub(type: User.self, provider: [RandomIntStubProvider()])
try userStub.make() // User(id: 97)
try userStub.make() // User(id: 54)
try userStub.make() // User(id: 12)
```

### Need to conform non-final class as Stubbable?

You can make it `Stubbable` by defining the `UnsafeStubbable`.

```swift
public protocol UnsafeStubbable: Stubbable {
    associatedtype Target = Self
    static func unsafeStub() -> Target
}

extension UnsafeStubbable {
    public static func stub() -> Self {
        return unsafeStub() as! Self
    }
}

extension UIImage: UnsafeStubbable {
    public static func unsafeStub() -> UIImage {
        return #imageLiteral(resourceName: "dummy")
    }
}
```


## How does it work

StubKit mainly uses two techniques.
- Traverse using `Decoder` protocol.
- Inject value with non-mutable `KeyPath`.
- Existential type using `Self`.

### Traverse struct using `Decoder` protocol
![](./resources/tree.png)

Swift has `Decodable` protocol and if a type conforms to `Decodable`, Swift compiler generates some code to decode internally. So we can decode a JSON to Swift struct without any configuration. StubKit uses this system to construct instance through `Decoder`. `Decoder` is a protocol which provide a value by key or index like `JSONDecoder`. If we pass the `Decoder` which just provide a stub value recursively, we can instantiate any kind of `Decodable` instance.


### Inject value with non-mutable `KeyPath`

I know it's only natural but, Swift can't mutate `let` defined property. But Swift has `MemoryLayout<T>.offset` which provide the offset to the property from its own address. So actually in memory we can mutate `let` property.


### Existential type using `Self`

A protocol that has `associatedtype` or uses `Self` type can't be existential type. But using `Self` for return type of method is only available in Swift4.2. (I think using `Self` for type of getter should be also available.) This technique makes `Stubbale` type-safely.
