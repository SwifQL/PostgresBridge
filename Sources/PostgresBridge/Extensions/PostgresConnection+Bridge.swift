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
    
    public func query(sql: SwifQLable) -> EventLoopFuture<Void> {
        sql.execute(on: self).transform(to: ())
    }
    
    public func query<V: Decodable>(raw: String, decoding type: V.Type) -> EventLoopFuture<[V]> {
        query(raw).map { $0.rows }.all(decoding: type)
    }
    
    public func query<V>(sql: SwifQLable, decoding type: V.Type) -> EventLoopFuture<[V]> where V : Decodable {
        sql.execute(on: self).all(decoding: type)
    }
}
