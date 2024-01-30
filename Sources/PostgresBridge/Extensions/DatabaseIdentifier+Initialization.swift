//
//  DatabaseIdentifier.swift
//  PostgresBridge
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation
import Bridges

extension DatabaseIdentifier {
    /// Initialize identifier based on `PG_DB` environment variable
    public static var psqlEnvironment: DatabaseIdentifier {
        var maxConnections: Int = 1
        if let maxConString = ProcessInfo.processInfo.environment["PG_MAX_CON"], let maxCon = Int(maxConString) {
            maxConnections = maxCon
        }
        return PostgresDatabaseIdentifier(name: ProcessInfo.processInfo.environment["PG_DB"], host: .psqlEnvironment, maxConnectionsPerEventLoop: maxConnections)
    }
    
    public static func psql(name: String? = ProcessInfo.processInfo.environment["PG_DB"], host: DatabaseHost, maxConnectionsPerEventLoop: Int = 1) -> DatabaseIdentifier {
        PostgresDatabaseIdentifier(name: name, host: host, maxConnectionsPerEventLoop: maxConnectionsPerEventLoop)
    }
}

public class PostgresDatabaseIdentifier: DatabaseIdentifier, PostgresDatabaseIdentifiable {
    public typealias B = PBR
    
    public convenience init?(url: URL, maxConnectionsPerEventLoop: Int = 1) {
        guard let host = DatabaseHost(url: url) else {
            return nil
        }
        self.init(name: url.path.split(separator: "/").last.flatMap(String.init), host: host, maxConnectionsPerEventLoop: maxConnectionsPerEventLoop)
    }
    
    public func all<T>(_ table: T.Type, on bridges: AnyBridgesObject) -> EventLoopFuture<[T]> where T : Table {
        PostgresBridge(bridges.bridges.bridge(to: B.self, on: bridges.eventLoop)).connection(to: self) { conn in
            T.select.execute(on: conn).all(decoding: T.self)
        }
    }
    
    public func first<T>(_ table: T.Type, on bridges: AnyBridgesObject) -> EventLoopFuture<T?> where T : Table {
        PostgresBridge(bridges.bridges.bridge(to: B.self, on: bridges.eventLoop)).connection(to: self) { conn in
            T.select.execute(on: conn).first(decoding: T.self)
        }
    }
    
    public func query(_ query: SwifQLable, on bridges: AnyBridgesObject) -> EventLoopFuture<[BridgesRow]> {
        PostgresBridge(bridges.bridges.bridge(to: B.self, on: bridges.eventLoop)).connection(to: self) { conn in
            query.execute(on: conn).map { $0 as [BridgesRow] }
        }
    }
    
    public func all<T>(_ table: T.Type, on bridges: AnyBridgesObject) async throws -> [T] where T : SwifQL.Table {
        try await PostgresBridge(bridges.bridges.bridge(to: B.self, on: bridges.eventLoop)).connection(to: self) { conn in
            try await T.select.execute(on: conn).all(decoding: T.self)
        }
    }
    
    public func first<T>(_ table: T.Type, on bridges: AnyBridgesObject) async throws -> T? where T : SwifQL.Table {
        try await PostgresBridge(bridges.bridges.bridge(to: B.self, on: bridges.eventLoop)).connection(to: self) { conn in
            try await T.select.execute(on: conn).first(decoding: T.self)
        }
    }
    
    public func query(_ query: SwifQL.SwifQLable, on bridges: AnyBridgesObject) async throws -> [BridgesRow] {
        try await PostgresBridge(bridges.bridges.bridge(to: B.self, on: bridges.eventLoop)).connection(to: self) { conn in
            try await query.execute(on: conn)
        }
    }
}
