//
//  SwifQLable+Execute.swift
//  PostgresBridge
//
//  Created by Mihael Isaev on 27.01.2020.
//

import SwifQL

extension SwifQLable {
    @discardableResult
    public func execute(on conn: PostgresConnection) -> EventLoopFuture<[PostgresRow]> {
        let prepared = prepare(.psql).splitted
        let binds: [PostgresData]
        do {
            binds = try prepared.values.map { try PostgresDataEncoder().encode($0) }
        } catch {
            return conn.eventLoop.makeFailedFuture(error)
        }
        conn.logger.debug("\(prepared.query) \(binds)")
        return conn.query(prepared.query, binds).map { $0.rows }
    }
    
    @discardableResult
    public func execute(on conn: PostgresConnection) async throws -> [PostgresRow] {
        let future: EventLoopFuture<[PostgresRow]> = execute(on: conn)
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
