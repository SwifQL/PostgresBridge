//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 03.04.2023.
//

import Foundation

struct PostgresBridgeError:  LocalizedError, Error, Decodable {
    var reason: String
    var description: String { reason }
    var errorDescription: String? { self.description }
    var failureReason: String? { self.description }
    var recoverySuggestion: String? { self.description }
    var helpAnchor: String? { self.description }
}
