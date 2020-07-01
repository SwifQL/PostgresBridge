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
        let prepared = prepare(_postgresDialect).splitted
        let binds: [PostgresData]
        do {
            binds = try prepared.values.map { try PostgresDataEncoder().encode($0) }
        } catch {
            return conn.eventLoop.makeFailedFuture(error)
        }
        return conn.query(prepared.query, binds).map { $0.rows }
    }
}
