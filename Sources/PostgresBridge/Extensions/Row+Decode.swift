//
//  Row+Decode.swift
//  PostgresBridge
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation

extension EventLoopFuture where Value == [PostgresRow] {
    public func first<R>(decoding type: R.Type) -> EventLoopFuture<R?> where R: Decodable {
        flatMapThrowing { try $0.first(as: type) }
    }
    
    public func all<R>(decoding type: R.Type) -> EventLoopFuture<[R]> where R: Decodable {
        flatMapThrowing { try $0.all(as: type) }
    }
}

extension Array where Element == PostgresRow {
    public func first<R>(as type: R.Type) throws -> R? where R: Decodable {
        try first?.sql().decode(model: type)
    }
    
    public func all<R>(as type: R.Type) throws -> [R] where R: Decodable {
        try map { try $0.sql().decode(model: type) }
    }
}
