//
//  PostgresMigration.swift
//  PostgresBridge
//
//  Created by Mihael Isaev on 28.01.2020.
//

import Bridges
import PostgresNIO

public protocol PostgresMigration: Migration {
    associatedtype Connection = PostgresConnection
}
