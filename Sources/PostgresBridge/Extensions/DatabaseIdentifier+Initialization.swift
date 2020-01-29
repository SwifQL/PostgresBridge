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
        .init(name: ProcessInfo.processInfo.environment["PG_DB"], host: .psqlEnvironment, maxConnectionsPerEventLoop: 1)
    }

    public init?(url: URL, maxConnectionsPerEventLoop: Int = 1) {
        guard let host = DatabaseHost(url: url) else {
            return nil
        }
        self.init(name: url.path.split(separator: "/").last.flatMap(String.init), host: host, maxConnectionsPerEventLoop: maxConnectionsPerEventLoop)
    }
}
