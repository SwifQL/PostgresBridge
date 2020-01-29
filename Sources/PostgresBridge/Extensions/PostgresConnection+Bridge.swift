//
//  PostgresConnection+Bridge.swift
//  PostgresBridge
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Bridges
import NIO

extension PostgresConnection: BridgeConnection {
    public var dialect: SQLDialect { .psql }
    
    public func query(raw: String) -> EventLoopFuture<Void> {
        query(raw).transform(to: ())
    }
    
    public func query<V: Decodable>(raw: String, decoding type: V.Type) -> EventLoopFuture<[V]> {
        query(raw).all(decoding: type)
    }
}
