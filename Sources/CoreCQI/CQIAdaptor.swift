//
//  CQIAdaptor.swift
//  Common Query Interface
//  Adaptor
//
//  Copyright © 2020 Jason Jobe. All rights reserved.
//  Created by Jason Jobe on 9/5/20.
//

import Foundation
import FeistyDB
import FeistyExtensions
import Runtime

/**
 @DomainObject(id: 2) var nob: NobStruct
 @DomainList(where: "age < 10") var nobs: [NobStruct]
 
   adaptor(select: S.Type, id: x) throws -> S?
  adaptor(select: S.Type,  sort_by: [pkey], where: predicate) throws -> [S]
 
 */
open class CQIAdaptor {
    
    public struct CQIError: Swift.Error {
        public var message: String
        public init (_ msg: String = "") {
            message = msg
        }
        
        static func notImplemented(_ f: String = #function) -> CQIError {
            CQIError("NOT IMPLEMENTED: \(f)")
        }
        static func illegalOperation(_ f: String = #function) -> CQIError {
            CQIError("ILLEGAL OPERATION: \(f)")
        }
        static func nothingFound(_ f: String = #function) -> CQIError {
            CQIError("UNEXPECTLY NO DATA WAS FOUND: \(f)")
        }
    }
    
    public static var shared: CQIAdaptor?
    
    public var db: Database
    public var name: String?
    
    public var transformers: [String:NSValueTransformerName] = [:]
    
    public init(name: String?, rawSQLiteDatabase dbc: SQLiteDatabaseConnection) throws {
        db = Database(rawSQLiteDatabase: dbc)
        self.name = name
        try addExtensions()
    }
    
    public init(database: Database) throws {
        db = database
        try addExtensions()
    }

    public init(inMemory: Bool = true) throws {
        try db = Database(inMemory: inMemory)
        try addExtensions()
    }
    
    public init(url: URL, create: Bool = true) throws {
        try db = Database(url: url, create: create)
        try addExtensions()
    }
    
    public init(file: String, create: Bool = true) throws {
        try db = Database(url: URL(fileURLWithPath: file), create: create)
        try addExtensions()
    }
    
    public var logErrors: Bool = true
    
    func log (_ error: Swift.Error, from caller: String = #function) {
        guard logErrors else { return }
        Report.print(error)
    }
    
// MARK: exec methos
// =====================================
    public func exec(sql: String) throws {
        do {
            try db.batch(sql: sql)
        } catch {
            log(error)
            throw error
        }
    }
    
    public func exec (contentsOfFile file: String) throws {
        let str = try String(contentsOfFile: file)
        try exec(sql: str)
    }
    
    open func addExtensions() throws {
    }
    
}

extension NSPredicate {
    var sql: String {
        description.replacingOccurrences(of: "\"", with: "'")
    }
}

// MARK: CQI Tuples by SELECT
extension NSPredicate {
    
    convenience init?(format: String?, argv: [Any]) {
        guard let format = format else { return nil }
        self.init(format: format, argumentArray: argv)
    }
}

public extension CQIAdaptor {
    typealias DS = DatabaseSerializable
    
    func first(_ type: CQIStruct.Type,
               from table: String? = nil,
               where format: String? = nil, _ argv: Any...,
               order_by: [Database.Ordering]? = nil
    )
    -> CQIStruct? {
        if let format = format {
            let pred = NSPredicate(format: format, argumentArray: argv)
            return try? first(type.config, from: table, where: pred, order_by: order_by)
                as? CQIStruct
        } else {
            return try? first(type.config, from: table, order_by: order_by) as? CQIStruct
        }
    }
    
    func select(_ type: CQIStruct.Type,
                from table: String? = nil,
                where format: String? = nil, _ argv: Any...,
                order_by: [Database.Ordering]? = nil,
                limit: Int = 0) -> [CQIStruct] {
        
        do {
            if let format = format {
                let pred = NSPredicate(format: format, argumentArray: argv)
                return try (select(type.config, from: table,
                                   where: pred, order_by: order_by, limit: limit)
                                as? [CQIStruct]) ?? []
            } else {
                return try (select(type.config, from: table,
                                   order_by: order_by, limit: limit)
                                as? [CQIStruct]) ?? []
            }
        } catch {
            //            log(error)
            return []
        }
    }

    // jmj
    func select<A: DS>(_ col: String, from table: String,
                      where format: String? = nil, _ argv: Any...,
                      order_by: [Database.Ordering]? = nil) -> [A] {
        var records: [A] = []
        do {
            try db.select([col], from: table,
                          where: NSPredicate(format: format, argv: argv)?.sql,
                          order_by: order_by, limit: 1) { row in
                let rec = try A.deserialize(from: row[0])
                records.append(rec)
            }
        } catch {
            log(error)
        }
        return records
    }

    func first<A: DS>(_ col: String, from table: String,
                      where format: String? = nil, _ argv: Any...,
                      order_by: [Database.Ordering]? = nil) -> A? {
        var record: A?
        do {
            try db.select([col], from: table,
                          where: NSPredicate(format: format, argv: argv)?.sql,
                          order_by: order_by, limit: 1) { row in
                record = try A.deserialize(from: row[0])
            }
        } catch {
            log(error)
        }
        return record
    }
    
    func first<A:DS, B:DS>(_ cols: [String], from table: String,
                      where format: String? = nil, _ argv: Any...,
                      order_by: [Database.Ordering]? = nil) -> (A?, B?)? {
        var record: (A?, B?)?
        do {
            try db.select(cols, from: table,
                          where: NSPredicate(format: format, argv: argv)?.sql,
                          order_by: order_by, limit: 1) { row in
                record = (
                    try A.deserialize(from: row[0]),
                    try B.deserialize(from: row[1])
                )
            }
        } catch {
            log(error)
        }
        return record
    }

    func first<A:DS, B:DS, C:DS>
        (_ cols: [String], from table: String,
         where format: String? = nil, _ argv: Any...,
         order_by: [Database.Ordering]? = nil) -> (A?, B?, C?)?
    {
        var record: (A?, B?, C?)?
        do {
            try db.select(cols, from: table,
                          where: NSPredicate(format: format, argv: argv)?.sql,
                          order_by: order_by, limit: 1) { row in
                record = (
                    try A.deserialize(from: row[0]),
                    try B.deserialize(from: row[1]),
                    try C.deserialize(from: row[2])
                )
            }
        } catch {
            log(error)
        }
        return record
    }

}

// MARK: CQI Config SELECT

public extension CQIAdaptor {
    
    // Primary entry method
    func first<C: CQIEntity>(_ type: C.Type = C.self,
               from table: String? = nil,
               where format: String? = nil, _ argv: Any...,
               order_by: [Database.Ordering]? = nil
    )
    -> C? {
        if let format = format {
            let pred = NSPredicate(format: format, argumentArray: argv)
            return try? first(type.config, from: table, where: pred, order_by: order_by) as? C
        } else {
            return try? first(type.config, from: table, order_by: order_by) as? C
        }
    }
    
    func first(_ cfg: CQIConfig,
                from table: String? = nil,
                where predicate: NSPredicate? = nil,
                order_by: [Database.Ordering]? = nil
    ) throws -> Any? {
        
        let table = table ?? cfg.table
        let cols = cfg.columns()// cfg.slots.map { $0.column }
        
        var record: Any?
        do {
            try db.select(cols, from: table,
                          where: predicate?.sql,
                          order_by: order_by, limit: 1) { row in
                record = try create(cfg, from: row)
            }
        } catch {
            log(error)
            throw error
        }
        return record
    }

    // Primary entry method for Collections
    func select<C: CQIEntity>(_ type: C.Type = C.self,
                from table: String? = nil,
                where format: String? = nil, _ argv: Any...,
                order_by: [Database.Ordering]? = nil,
                limit: Int = 0) -> [C] {
        
        do {
            if let format = format {
                let pred = NSPredicate(format: format, argumentArray: argv)
                return try (select(type.config, from: table,
                                   where: pred, order_by: order_by, limit: limit)
                        as? [C]) ?? []
            } else {
                return try (select(type.config, from: table,
                                   order_by: order_by, limit: limit)
                        as? [C]) ?? []
            }
        } catch {
            log(error)
            return []
        }
    }
    
    func select(_ cfg: CQIConfig,
                from table: String? = nil,
                where predicate: NSPredicate? = nil,
                order_by: [Database.Ordering]? = nil,
                limit: Int = 0) throws -> [Any] {
        
        let table = table ?? cfg.table
        let cols = cfg.columns()
        
        var recs: [Any] = []
        do {
            try db.select(cols, from: table, where: predicate?.sql,
                          order_by: order_by, limit: limit) { row in
                let nob = try create(cfg, from: row)
                recs.append(nob)
            }
        } catch {
            log(error)
            throw error
        }
        return recs
    }

    func create(_ cfg: CQIConfig, from row: Row) throws -> Any {
        
//        guard var nob = try createInstance(of: cfg.type) as? CQIStruct
//        else { throw CQIError("Unable to createInstance of \(cfg.type)") }
        
        var nob = try cfg.createInstance()
        
        for slot in cfg.slots where !slot.isExcluded {
            
            let property = slot.info
            var valueType: Any.Type = property.type
            
            if property.isOptional,
               let pinfo = try? typeInfo(of: property.type),
               let elementType = pinfo.elementType {
                valueType = elementType
            }

            // FIXME: Add the ability to use a ValueTransformer here
            // Actually will need to create a Swifty TypeTransformer
            // Using the slot.column (a String) is more convenient
            // programatically but not as performant as ndx could be(?)
            
            let db_value = try row.value(named: slot.columns[0])
            let value: Any?

            switch valueType {

                case _ where db_value.isNull:
                    value = nil
    
                case is String.Type:
                    value = db_value.stringValue
                    
                case is Data.Type:
                    value = db_value.dataValue
                    
                case let f as CQIStruct.Type:
                    value = try create(f.config, from: row)
                    
                case let f as DatabaseSerializable.Type where !db_value.isNull:
                    value = try f.deserialize(from: db_value)

                case let f as Decodable.Type where !property.sealed:

                    switch db_value {
                        case .null:
                            value = nil
                        case let DatabaseValue.blob(data):
                            value = try f.decodeFromJSON(data: data)
                        case let DatabaseValue.text(str):
                            value = try f.decodeFromJSON(text: str)
                        default:
                            // Primative DB types are Decodable
                            // But should we throw?
                            value = db_value.anyValue
                    }
                    
                default:
                    value = db_value.anyValue
            }
            try property.set(value: value as Any, on: &nob)
        }
        nob.postload()
        return nob
    }
}

public extension CQIAdaptor {

    @discardableResult
    func delete<E: CQIEntity>(_ nob: E) throws -> Int {
        try db.delete(from: E.config.table, where: "id = \(nob.id)")
        return db.changes
    }
    
    func delete(all type: CQIEntity.Type)
    throws -> Int
    {
        try db.delete(from: type.config.table, where: "", confirmAll: true)
        return db.changes
    }

    func delete(any type: CQIEntity.Type, where format: String, _ argv: Any...)
    throws -> Int
    {
        let pred = NSPredicate(format: format, argumentArray: argv)
        try db.delete(from: type.config.table, where: pred.sql)
        return db.changes
    }

    func columnsAndValues<E: CQIEntity>(_ nob: E) throws -> ([String], [ParameterBindable?]) {
        let cfg = E.config
        var cols: [String] = []
        var values: [ParameterBindable?] = []
        
        // FIXME: New design allows for nested structs to hold multiple
        // column values
        for slot in cfg.slots where slot.hasColumnValue {
            let property = try cfg.info.property(named: slot.name)
            cols.append(slot.columns[0])
            try values.append(property.get(from: nob) as? ParameterBindable)
        }
        return (cols, values)
     }

    @discardableResult
    func insert<E: CQIEntity>(_ nob: E) throws -> Int64 {
        // guard nob.id == nil else { throw }
        let (cols, values) = try columnsAndValues(nob)
        try db.insert(E.config.table, cols: cols, to: values)
        return db.lastInsertRowid ?? nob.id
    }

    @discardableResult
    func update<E: CQIEntity>(_ nob: E) throws -> Int {
        // guard nob.id != nil else { throw }
        let (cols, values) = try columnsAndValues(nob)
        try db.update(E.config.table, cols: cols, to: values)
        return db.changes
    }

    func upsert<E: CQIEntity>(_ nob: inout E) throws {
        
        let cfg = E.config
        let (cols, values) = try columnsAndValues(nob)
        if nob.id == 0 {
            try db.insert(cfg.table, cols: cols, to: values)
            if let rowid = db.lastInsertRowid {
                nob.id = EntityID(rowid)
            }
        } else {
            try db.update(cfg.table, cols: cols, to: values)
        }
    }
}


