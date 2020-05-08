//
//  Bridges+Application.swift
//  PostgresBridge
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Bridges

extension BridgesApplication {
    public var postgres: PostgresBridge {
        .init(bridges.bridge(to: PBR.self, on: eventLoopGroup.next()))
    }
}

extension BridgesRequest {
    public var postgres: PostgresBridge {
        .init(bridgesApplication.bridges.bridge(to: PBR.self, on: eventLoop))
    }
}

import NIO
import Logging

extension PBR {
    public static func create(eventLoopGroup: EventLoopGroup, logger: Logger) -> AnyBridge {
        PBR(eventLoopGroup: eventLoopGroup, logger: logger)
    }
}
