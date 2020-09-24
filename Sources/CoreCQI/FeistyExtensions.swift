//
//  FeistyExtensions.swift
//  ExampleCoders
//
//  Copyright © 2020 Jason Jobe. All rights reserved.
//  Created by Jason Jobe on 9/6/20.
//
import Foundation
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

public extension DatabaseValue {
    static var yes: DatabaseValue { .integer(1) }
    static var no: DatabaseValue { .integer(0) }
}

public extension Database {
    typealias RowHandler = (_ row: Row) throws -> ()
    enum Ordering { case asc(String), desc(String) }
    
    func selectSQL(_ cols: [String], from table: String,
                where test: String? = nil,
                order_by: [Ordering]? = nil, limit: Int) -> String
    {
        var sql = "SELECT \(cols.joined(separator: ",")) FROM \(table)"
        if let test = test {
            Swift.print(" WHERE \(test)", terminator: "", to: &sql)
        }
        if let order = order_by?
            .map({$0.description}).joined(separator: ",") {
            Swift.print(" ORDER BY \(order)", terminator: "", to: &sql)
        }
        if limit > 0 {
            Swift.print(" LIMIT \(limit)", terminator: "", to: &sql)
        }
        return sql
    }

    // select^ (_cols: [s], from: <table/s>, where: <test/s>?
    //          order_by: [Ordering]? limit: i, ƒ: RowHandler)
    
    func select(_ cols: [String], from table: String,
                where test: String? = nil,
                order_by: [Ordering]? = nil, limit: Int,
                _ call: RowHandler) throws {
        let sql = selectSQL(cols, from: table,
                            where: test, order_by: order_by, limit: limit)
        try prepare(sql: sql).results(call)
    }

    //MARK: Update SQL
    // https://www.sqlite.org/rowvalue.html
    
    // WARNING: ?1 parameter MUST be the id so it IS SKIPPED herein
    func sqlRowValues(cols: [String]) -> (String, String) {
        var colv = ""
        var argv = ""
        for ndx in 2 ..< cols.count {
            Swift.print("?\(ndx),", terminator: "", to: &argv)
            Swift.print("\(cols[ndx - 1]),", terminator: "", to: &colv)
        }
        // Add the last one WITHOUT the trailing comma
        Swift.print("?\(cols.count)", terminator: "", to: &argv)
        Swift.print("\(cols[cols.count - 1])", terminator: "", to: &colv)
        return(colv, argv)
     }
    
    // WARNING: ?1 parameter MUST be the id
    func updateSQL(_ table: String, cols: [String]) -> String {
//        var colv = ""
//        var argv = ""
//        for ndx in 2 ..< cols.count {
//            Swift.print("?\(ndx),", terminator: "", to: &argv)
//            Swift.print("\(cols[ndx - 1]),", terminator: "", to: &colv)
//        }
//        // Add the last one WITHOUT the trailing comma
//        Swift.print("?\(cols.count)", terminator: "", to: &argv)
//        Swift.print("\(cols[cols.count - 1])", terminator: "", to: &colv)
        
        let (colv, argv) = sqlRowValues(cols: cols)
        return """
            UPDATE \(table)
            SET (\(colv)) = (\(argv))
            WHERE \(cols[0]) = ?1 AND (\(colv)) != (\(argv))
            """
    }
    
    func update(_ table: String, cols: [String], to values: [ParameterBindable?]) throws {
        let sql = updateSQL(table, cols: cols)
        let statement = try prepare(sql: sql)
        try statement.bind(parameterValues: values)
        try statement.execute()
    }
    
    func insertSQL(_ table: String, cols: [String]) -> String {
        let (colv, argv) = sqlRowValues(cols: cols)
        return "INSERT INTO \(table) (\(colv)) VALUES (\(argv))"
    }
    
    func insert(_ table: String, cols: [String], to values: [ParameterBindable?]) throws {
        let sql = insertSQL(table, cols: cols)
        let statement = try prepare(sql: sql)
        try statement.bind(parameterValues: values)
        try statement.execute()
    }
}

extension Database.Ordering: CustomStringConvertible {
    public var description: String {
        switch self {
            case let .asc(col):
                return "\(col) ASC"
            case let .desc(col):
                return "\(col) DESC"
        }
    }
}

extension URL: DatabaseSerializable {
    
    public func serialized() -> DatabaseValue {
        return .text(self.description)
    }
    
    // URL uses init? so we provide example.com just in case
    public static func deserialize(from value: DatabaseValue) throws -> Self {
        guard case let DatabaseValue.text(str) = value
        else { throw DatabaseError("Cannot deserialize \(value) into URL") }
        return URL(string: str) ?? URL(string: "http://example.com")!
    }
}

// MARK: Database Iterface

extension EntityID: DatabaseSerializable {
    
    public func serialized() -> DatabaseValue {
        return .integer(self)
    }
    
    public static func deserialize(from value: DatabaseValue) throws -> Self {
        guard case let DatabaseValue.integer(i64) = value
        else { throw DatabaseError("Cannot deserialize \(value) into EntityID") }
        return EntityID(i64)
    }
}

public extension DatabaseValue {
    var isNull: Bool {
        switch self {
            case .null: return true
            default: return false
        }
    }
}

public extension Encodable {
    
    func encodeToJSONData() throws -> Data {
        try JSONEncoder().encode(self)
    }
    
    func encodeToJSONText() throws -> String {
        let data = try JSONEncoder().encode(self)
        guard let str = String(data: data, encoding: .utf8)
        else {
            throw DatabaseError("\(Self.self) cannot be coverted to JSON")
        }
        return str
    }
}

public extension Decodable {
    
    static func decodeFromJSON(data: Data) throws -> Self {
        return try JSONDecoder().decode(Self.self, from: data)
    }
    
    static func decodeFromJSON(text: String, encoding: String.Encoding = .utf8) throws -> Self {
        let data = text.data(using: encoding)!
        return try JSONDecoder().decode(Self.self, from: data)
    }
}

extension DatabaseSerializable where Self: Codable {
    
    public func serialized() -> DatabaseValue {
        if let data = try? JSONEncoder().encode(self),
           let str = String(data: data, encoding: .utf8) {
            return .text(str)
        }
        return .null
    }
    
    public static func deserialize(from value: DatabaseValue) throws -> Self {
        switch value {
            case .blob(let data):
                return try Self.decodeFromJSON(data: data)
            case .text(let str):
                return try Self.decodeFromJSON(text: str, encoding: .utf8)
            default:
                throw DatabaseError("\(value) is NOT JSON decodable")
        }
    }
}
