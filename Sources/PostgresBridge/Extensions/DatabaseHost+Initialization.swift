//
//  DatabaseHost.swift
//  PostgresBridge
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Bridges
import NIOSSL
import Foundation

extension DatabaseHost {
    public static var psqlEnvironment: DatabaseHost {
        let host = ProcessInfo.processInfo.environment["PG_HOST"] ?? "127.0.0.1"
        let port = Int(ProcessInfo.processInfo.environment["PG_PORT"] ?? "5432")
        let user = ProcessInfo.processInfo.environment["PG_USER"] ?? "postgres"
        let pwd = ProcessInfo.processInfo.environment["PG_PWD"]
        return .init(hostname: host, port: port ?? 5432, username: user, password: pwd, tlsConfiguration: nil)
    }
    
    public init?(url: URL) {
        guard url.scheme?.hasPrefix("postgres") == true else {
            return nil
        }
        guard let username = url.user else {
            return nil
        }
        guard let password = url.password else {
            return nil
        }
        guard let hostname = url.host else {
            return nil
        }
        guard let port = url.port else {
            return nil
        }

        let tlsConfiguration: TLSConfiguration?
        if url.query?.contains("ssl=true") == true || url.query?.contains("sslmode=require") == true {
            tlsConfiguration = TLSConfiguration.forClient()
        } else {
            tlsConfiguration = nil
        }
        
        self.init(hostname: hostname, port: port, username: username, password: password, tlsConfiguration: tlsConfiguration)
    }
    
    public init(
        unixDomainSocketPath: String,
        username: String,
        password: String,
        database: String
    ) {
        let address = {
            try SocketAddress.init(unixDomainSocketPath: unixDomainSocketPath)
        }
        self.init(address: address, username: username, password: password, tlsConfiguration: nil)
    }
}
