//
//  Row+Decode.swift
//  PostgresBridge
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation
import Bridges

extension PostgresRow: BridgesRow {
    public func decode<D>(model type: D.Type, prefix: String?) throws -> D where D : Decodable {
        try sql().decode(model: type, prefix: prefix)
    }
}
