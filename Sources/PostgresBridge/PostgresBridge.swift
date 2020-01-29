import NIO
import PostgresNIO
import AsyncKit
import Bridges
import Logging

public final class PostgresBridge: Bridgeable {
    public typealias Source = PostgresConnectionSource
    public typealias Database = PostgresDatabase
    public typealias Connection = PostgresConnection
    
    public static var dialect: SQLDialect { .psql }
    
    public var pools: [String: GroupPool] = [:]
    
    public let logger: Logger
    public let eventLoopGroup: EventLoopGroup
    
    required public init (eventLoopGroup: EventLoopGroup, logger: Logger) {
        self.eventLoopGroup = eventLoopGroup
        self.logger = logger
    }
    
    public func connection<T>(to db: DatabaseIdentifier,
                                           _ closure: @escaping (PostgresConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.db(db).withConnection(closure)
    }
    
    public func db(_ db: DatabaseIdentifier) -> PostgresDatabase {
        _ConnectionPoolPostgresDatabase(pool: pool(db), logger: logger)
    }
    
    deinit {
        shutdown()
    }
}

// MARK: Database on pool

private struct _ConnectionPoolPostgresDatabase {
    let pool: EventLoopConnectionPool<PostgresConnectionSource>
    let logger: Logger
}

extension _ConnectionPoolPostgresDatabase: PostgresDatabase {
    var eventLoop: EventLoop { self.pool.eventLoop }
    
    func send(_ request: PostgresRequest, logger: Logger) -> EventLoopFuture<Void> {
        self.pool.withConnection(logger: logger) {
            $0.send(request, logger: logger)
        }
    }
    
    func withConnection<T>(_ closure: @escaping (PostgresConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.pool.withConnection(logger: self.logger, closure)
    }
}
