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
pod 'StubKit'
```

## Usage

### Getting started

You can instantiate any kind of `Codable` with a single line!

```swift
import StubKit

// Codable struct
struct User: Codable {
  let id: Int
  let name: String
  let sex: Sex
}

// User(id: 1234, name: "This is Stub String", sex: .female)
let stubUser = try Stub.make(User.self)
```

### Customize property

You can customize properties even if the property is defined as `let`.
```swift
let maleUser = try Stub.make(User.self) {
  $0.set(\.sex, value: .male)
}
```

### Using `Stubbable`

If you customize default stub, please conform `Stubbable`.
```swift
extension URL: Stubbable {
  static func stub() -> URL {
    return URL(string: "https://example.com")!
  }
}
```
