import NIO
import PostgresNIO
import AsyncKit
import Bridges
import Logging

public struct PostgresBridge {
    let context: BridgeWithContext<_PostgresBridge>
    
    init (_ context: BridgeWithContext<_PostgresBridge>) {
        self.context = context
    }
    
    public func connection<T>(to db: DatabaseIdentifier,
                                            _ closure: @escaping (PostgresConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        context.bridge.connection(to: db, on: context.eventLoop, closure)
    }
    
    public func transaction<T>(to db: DatabaseIdentifier,
                                            _ closure: @escaping (PostgresConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        context.bridge.transaction(to: db, on: context.eventLoop, closure)
    }
    
    public func register(_ db: DatabaseIdentifier) {
        context.bridge.register(db)
    }
    
    public func migrator(for db: DatabaseIdentifier) -> Migrator {
        BridgeDatabaseMigrations<_PostgresBridge>(context.bridge, db: db)
    }
}

final class _PostgresBridge: Bridgeable {
    typealias Source = PostgresConnectionSource
    typealias Database = PostgresDatabase
    typealias Connection = PostgresConnection
    
    static var dialect: SQLDialect { .psql }
    
    var pools: [String: GroupPool] = [:]
    
    let logger: Logger
    let eventLoopGroup: EventLoopGroup
    
    required init (eventLoopGroup: EventLoopGroup, logger: Logger) {
        self.eventLoopGroup = eventLoopGroup
        self.logger = logger
    }
    
    /// Gives a connection to the database and closes it automatically in both success and error cases
    func connection<T>(to db: DatabaseIdentifier,
                                           on eventLoop: EventLoop,
                                           _ closure: @escaping (PostgresConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.db(db, on: eventLoop).withConnection { conn in
            closure(conn).flatMap { result in
                if conn.isClosed {
                    return conn.eventLoop.future(result)
                } else {
                    return conn.close().transform(to: result)
                }
            }.flatMapError { error in
                if conn.isClosed {
                    return conn.close().flatMapThrowing {
                        throw error
                    }
                } else {
                    return conn.eventLoop.makeFailedFuture(error)
                }
            }
        }
    }
    
    func db(_ db: DatabaseIdentifier, on eventLoop: EventLoop) -> PostgresDatabase {
        _ConnectionPoolPostgresDatabase(pool: pool(db, for: eventLoop), logger: logger)
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
        pool.withConnection(logger: logger) {
            $0.send(request, logger: logger)
        }
    }
    
    func withConnection<T>(_ closure: @escaping (PostgresConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        pool.withConnection(logger: self.logger, closure)
    }
}
