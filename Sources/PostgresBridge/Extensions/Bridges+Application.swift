//
//  Bridges+Application.swift
//  PostgresBridge
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Bridges

extension BridgesApplication {
    public var postgres: PostgresBridge {
        bridges.bridge(to: PostgresBridge.self)
    }
}

import NIO
import Logging

extension PostgresBridge {
    public static func create(eventLoopGroup: EventLoopGroup, logger: Logger) -> AnyBridge {
        PostgresBridge(eventLoopGroup: eventLoopGroup, logger: logger)
    }
}
