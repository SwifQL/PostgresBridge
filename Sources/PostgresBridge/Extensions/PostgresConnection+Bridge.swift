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
        logger.debug("\(raw)")
        return query(raw).transform(to: ())
    }
    
    public func query(sql: SwifQLable) -> EventLoopFuture<Void> {
        logger.debug("\(sql)")
        return sql.execute(on: self).transform(to: ())
    }
    
    public func query<V: Decodable>(raw: String, decoding type: V.Type) -> EventLoopFuture<[V]> {
        logger.debug("\(raw)")
        return query(raw).map { $0.rows }.all(decoding: type)
    }
    
    public func query<V>(sql: SwifQLable, decoding type: V.Type) -> EventLoopFuture<[V]> where V : Decodable {
        logger.debug("\(sql)")
        return sql.execute(on: self).all(decoding: type)
    }
    
    ///ASYNC
    public func query(raw: String) async throws {
        let future: EventLoopFuture<Void> = query(raw: raw)
        return try await withCheckedThrowingContinuation { cont in
            future.whenSuccess { _ in
                cont.resume()
            }
            future.whenFailure { error in
                cont.resume(throwing: error)
            }
        }
    }
    
    public func query(sql: SwifQL.SwifQLable) async throws {
        let future: EventLoopFuture<Void> = query(sql: sql)
        return try await withCheckedThrowingContinuation { cont in
            future.whenSuccess { _ in
                cont.resume()
            }
            future.whenFailure { error in
                cont.resume(throwing: error)
            }
        }
    }
    
    public func query<V>(raw: String, decoding type: V.Type) async throws -> [V] where V : Decodable {
        let future: EventLoopFuture<[V]> = query(raw).map { $0.rows }.all(decoding: type)
        return try await withCheckedThrowingContinuation { cont in
            future.whenSuccess { val in
                cont.resume(returning: val)
            }
            future.whenFailure { error in
                cont.resume(throwing: error)
            }
        }
    }
    
    public func query<V>(sql: SwifQL.SwifQLable, decoding type: V.Type) async throws -> [V] where V : Decodable {
        let future: EventLoopFuture<[V]> = sql.execute(on: self).all(decoding: type)
        return try await withCheckedThrowingContinuation { cont in
            future.whenSuccess { val in
                cont.resume(returning: val)
            }
            future.whenFailure { error in
                cont.resume(throwing: error)
            }
        }
    }
}
