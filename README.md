<p align="center">
    <a href="LICENSE">
        <img src="https://img.shields.io/badge/license-MIT-brightgreen.svg" alt="MIT License">
    </a>
    <a href="https://swift.org">
        <img src="https://img.shields.io/badge/swift-5.2-brightgreen.svg" alt="Swift 5.2">
    </a>
    <img src="https://img.shields.io/github/workflow/status/SwifQL/PostgresBridge/test" alt="Github Actions">
    <a href="https://discord.gg/q5wCPYv">
        <img src="https://img.shields.io/discord/612561840765141005" alt="Swift.Stream">
    </a>
</p>

# Bridge to PostgreSQL

Work with Postgres with SwifQL through its pure NIO driver.

## Installation

```swift
.package(url: "https://github.com/SwifQL/PostgresBridge.git", from:"1.0.0-rc"),
.package(url: "https://github.com/SwifQL/VaporBridges.git", from:"1.0.0-rc"),
.target(name: "App", dependencies: [
    .product(name: "Vapor", package: "vapor"),
    .product(name: "PostgresBridge", package: "PostgresBridge"),
    .product(name: "VaporBridges", package: "VaporBridges")
]),
```

For more info please take a look at the `Bridges` repo.

## Advanced use cases:

### Type safe identifiers

If want to use custom identifiers which under the hood stores any kind of core Swift data type like `Int`, `String`, `UUID` etc. they won't be decoded from PostgreSQL table without conforming this identifier to `PostgresDataConvertible`

Below is example of Identifier implementation described in [this blog post](https://www.donnywals.com/creating-type-safe-identifiers-for-your-codable-models/) with added Encodable conformance.

```swift
struct IdentifierType<T, KeyType: Codable>: Codable, PostgresDataConvertible where KeyType: PostgresDataConvertible {
    let wrappedValue: KeyType
    
    // PostgresDataConvertible requirement
    public static var postgresDataType: PostgresDataType {
        KeyType.postgresDataType
    }
    
    // PostgresDataConvertible requirement
    public init?(postgresData: PostgresData) {
        guard let wrappedValue = KeyType.init(postgresData: postgresData) else { return nil }
        self.init(wrappedValue)
    }

    // PostgresDataConvertible requirement
    public var postgresData: PostgresData? {
        wrappedValue.postgresData
    }

    init(_ wrappedValue: KeyType) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.wrappedValue = try container.decode(KeyType.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

struct Author: Codable {
    typealias Identifier = IdentifierType<Author, UUID>
    
    let id: Identifier
    // ...
}

struct Category: Codable {
    typealias Identifier = IdentifierType<Category, UUID>
    
    let id: Identifier
    // ...
}

struct Book: Codable {
    typealias Identifier = IdentifierType<Book, UUID>
    
    let id: Identifier
    // ...
    let categoryID: Category.Identifier
    let authorIds: [Author.Identifier]
}
```
With such implementation both `categoryID` and `authorIds` will be properly decoded to form `Book` object. Without such addition only `categoryID` is properly decoded
