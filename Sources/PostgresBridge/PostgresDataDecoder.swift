import Foundation

struct DecoderUnwrapper: Decodable {
    let decoder: Decoder
    init(from decoder: Decoder) {
        self.decoder = decoder
    }
}

protocol PostgresEnumDecodable {
    init?(postgresData: PostgresData) throws
}
extension Array: PostgresEnumDecodable where Element: BridgesEnum, Element.RawValue == String {
    private struct EnumValue: CodingKey {
        var stringValue: String
        var intValue: Int?
        
        init (_ str: String) {
            stringValue = str
        }
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        init?(intValue: Int) { nil }
    }

    init?(postgresData: PostgresData) throws {
        guard var str = postgresData.string?.replacingOccurrences(of: "\"", with: "") else {
            throw DecodingError.valueNotFound(String.self, DecodingError.Context.init(
                codingPath: [],
                debugDescription: "Unable to proceed \(Element.self) enum :("
            ))
        }
        str.removeFirst(22)
        var values: [String] = []
        while true {
            guard let length = str.first?.asciiValue else {
                break
            }
            str.removeFirst(1)
            guard str.count >= Int(length) else {
                break
            }
            let startIndex = str.index(str.startIndex, offsetBy: 0)
            let endIndex = str.index(str.startIndex, offsetBy: Int(length))
            let substring = str[startIndex..<endIndex]
            let value = String(substring)
            guard value.count > 0 else {
                continue
            }
            values.append(value)
            str.removeFirst(Int(length))
        }
        self = try values.map { value in
            guard let v = Element.init(rawValue: value) else {
                throw DecodingError.valueNotFound(String.self, DecodingError.Context.init(
                    codingPath: [EnumValue(value)],
                    debugDescription: "Looks like \(Element.self) doesn't have \(value) case"
                ))
            }
            return v
        }
    }
}

/// Original credits to
/// [Vapor/Postgres-Kit](https://github.com/vapor/postgres-kit/blob/master/Sources/PostgresKit/PostgresDataDecoder.swift)

public final class PostgresDataDecoder {
    public let jsonDecoder: JSONDecoder

    public init(json: JSONDecoder = JSONDecoder()) {
        self.jsonDecoder = json
        self.jsonDecoder.dateDecodingStrategy = .formatted(BridgesDateFormatter())
    }

    private struct PostgresCodingKey: CodingKey {
        init (_ column: String) {
            stringValue = column
        }
        
        var stringValue: String
        
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        var intValue: Int?
        
        init?(intValue: Int) {
            self.intValue = intValue
            self.stringValue = "\(intValue)"
        }
    }
    
    public func decode<T>(_ columns: [String], _ type: T.Type, from data: PostgresData) throws -> T
        where T: Decodable
    {
        if let convertible = T.self as? PostgresEnumDecodable.Type {
            guard let value = try convertible.init(postgresData: data) else {
                throw DecodingError.typeMismatch(T.self, DecodingError.Context.init(
                    codingPath: columns.map { PostgresCodingKey($0) },
                    debugDescription: "Could not convert to \(T.self): \(data)"
                ))
            }
            return value as! T
        }
        if let convertible = T.self as? PostgresDataConvertible.Type {
            guard let value = convertible.init(postgresData: data) else {
                throw DecodingError.typeMismatch(T.self, DecodingError.Context.init(
                    codingPath: columns.map { PostgresCodingKey($0) },
                    debugDescription: "Could not convert to \(T.self): \(data)"
                ))
            }
            return value as! T
        } else {
            return try T.init(from: _Decoder(data: data, json: self.jsonDecoder))
        }
    }

    enum Error: Swift.Error, CustomStringConvertible {
        case unexpectedDataType(PostgresDataType, expected: String)
        case nestingNotSupported

        var description: String {
            switch self {
            case .unexpectedDataType(let type, let expected):
                return "Unexpected data type: \(type). Expected \(expected)."
            case .nestingNotSupported:
                return "Decoding nested containers is not supported."
            }
        }
    }

    final class _Decoder: Decoder {
        var codingPath: [CodingKey] {
            return []
        }

        var userInfo: [CodingUserInfoKey : Any] {
            return [:]
        }

        let data: PostgresData
        let json: JSONDecoder

        init(data: PostgresData, json: JSONDecoder) {
            self.data = data
            self.json = json
        }

        func unkeyedContainer() throws -> UnkeyedDecodingContainer {
            guard let data = self.data.array else {
                throw Error.unexpectedDataType(self.data.type, expected: "array")
            }
            return _UnkeyedDecoder(data: data, json: self.json)
        }

        func container<Key>(
            keyedBy type: Key.Type
        ) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
            let data: Data
            if let jsonb = self.data.jsonb {
                data = jsonb
            } else if let json = self.data.json {
                data = json
            } else {
                throw Error.unexpectedDataType(self.data.type, expected: "json")
            }
            return try self.json
                .decode(DecoderUnwrapper.self, from: data)
                .decoder.container(keyedBy: Key.self)
        }

        func singleValueContainer() throws -> SingleValueDecodingContainer {
            _ValueDecoder(data: self.data, json: self.json)
        }
    }

    struct _UnkeyedDecoder: UnkeyedDecodingContainer {
        var count: Int? {
            self.data.count
        }

        var isAtEnd: Bool {
            self.currentIndex == self.data.count
        }
        var currentIndex: Int = 0

        let data: [PostgresData]
        let json: JSONDecoder
        var codingPath: [CodingKey] {
            []
        }

        mutating func decodeNil() throws -> Bool {
            defer { self.currentIndex += 1 }
            return self.data[self.currentIndex].value == nil
        }

        mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            defer { self.currentIndex += 1 }
            let data = self.data[self.currentIndex]
            let jsonData: Data
            if let jsonb = data.jsonb {
                jsonData = jsonb
            } else if let json = data.json {
                jsonData = json
            } else {
                throw Error.unexpectedDataType(data.type, expected: "json")
            }
            return try self.json.decode(T.self, from: jsonData)
        }

        mutating func nestedContainer<NestedKey>(
            keyedBy type: NestedKey.Type
        ) throws -> KeyedDecodingContainer<NestedKey>
            where NestedKey : CodingKey
        {
            throw Error.nestingNotSupported
        }

        mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            throw Error.nestingNotSupported
        }

        mutating func superDecoder() throws -> Decoder {
            throw Error.nestingNotSupported
        }
    }

    struct _ValueDecoder: SingleValueDecodingContainer {
        let data: PostgresData
        let json: JSONDecoder
        var codingPath: [CodingKey] {
            []
        }

        func decodeNil() -> Bool {
            return self.data.value == nil
        }

        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            if let convertible = T.self as? PostgresDataConvertible.Type {
                guard let value = convertible.init(postgresData: data) else {
                    throw DecodingError.typeMismatch(T.self, DecodingError.Context.init(
                        codingPath: [],
                        debugDescription: "Could not convert to \(T.self): \(data)"
                    ))
                }
                return value as! T
            } else {
                return try T.init(from: _Decoder(data: self.data, json: self.json))
            }
        }
    }
}
