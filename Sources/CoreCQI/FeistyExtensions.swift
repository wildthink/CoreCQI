//
//  FeistyExtensions.swift
//  ExampleCoders
//
//  Copyright © 2020 Jason Jobe. All rights reserved.
//  Created by Jason Jobe on 9/6/20.
//

import Foundation
//import CSQLite
import FeistyDB
import FeistyExtensions

public extension Row {
    
    func columnNames() throws -> [String] {
        var cols: [String] = []
        for ndx in 0..<count {
            cols.append(try self.name(ofColumn: ndx) )
        }
        return cols
    }
}

public extension Database {
    func select(_ cols: [String], from table: String,
                where test: String? = nil, limit: Int,
                
                _ block: ((_ row: Row) throws -> ())) throws {
        var sql = "SELECT \(cols.joined(separator: ",")) FROM \(table)"
        if let test = test {
            Swift.print(" WHERE \(test)", terminator: "", to: &sql)
        }
        if limit > 0 {
            sql = " LIMIT \(limit)"
        }
        try prepare(sql: sql).results(block)
    }

}

extension URL: DatabaseSerializable {
    
    public func serialized() -> DatabaseValue {
        return .text(self.description)
    }
    
    public static func deserialize(from value: DatabaseValue) throws -> Self {
        guard case let DatabaseValue.text(str) = value
        else { throw DatabaseError("Cannot deserialize \(value) into URL") }
        return URL(string: str)!
    }
}

