import Vapor
import PostgresBridge

extension BlackDatabase {
    static var kittest: BlackDatabase { .init(name: "kittest") }
}

// Called before your application initializes.
public func configure(_ app: Application) throws {
    // Logger
    app.logger.logLevel = .debug
    
    let orm = PostgresBlackORM()
    orm.register(.kittest, on: app.eventLoopGroup)
    
    let _: EventLoopFuture<Void> = orm.transaction(to: .kittest, on: app.eventLoopGroup.next()) { conn in
        conn.query("SELECT 'hello' as title").map { rows in
            print(rows)
        }
    }
    
    try boot(app)
}

struct BlackORM {
    
}
