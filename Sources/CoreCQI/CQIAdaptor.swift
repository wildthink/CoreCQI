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
import CRuntime

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
    public var transformers: [String:NSValueTransformerName] = [:]
    
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
        Swift.print(error)
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
        //        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else {
        //            throw SQLiteError("Error in execution", takingDescriptionFromDatabase: db)
        //        }
    }
    
    public func exec (contentsOfFile file: String) throws {
        let str = try String(contentsOfFile: file)
        try exec(sql: str)
    }
    
    open func addExtensions() throws {
//        try db.addAggregateFunction("min_meter", LevelMeter(mode: .min))
//        try db.addModule("cal", type: CalendarModule.self)
    }
    
}

extension NSPredicate {
    var sql: String {
        description.replacingOccurrences(of: "\"", with: "'")
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
        
        guard var nob = try createInstance(of: cfg.type) as? CQIEntity
        else { throw CQIError() }
        
//        if var bob = nob as? CQIEntity {
//            bob.preload()
//            nob = bob
//        }

        for slot in cfg.slots where !slot.isExcluded {
            let property = try cfg.info.property(named: slot.name)
            var valueType: Any.Type = property.type
            
            if property.isOptional,
               let pinfo = try? typeInfo(of: property.type),
               let elementType = pinfo.elementType {
                valueType = elementType
            }
            // FIXME: Add the ability to use a ValueTransformer here
            // Actually will need to create a Swifty TypeTransformer
            let db_value = try row.value(at: slot.col_ndx)
            let value: Any?
            if case .null = db_value {
                value = nil
            }
            else if let factory = valueType as? DatabaseSerializable.Type
            {
                value = try factory.deserialize(from: db_value)
            }
            else if !property.sealed,
                    let factory = valueType as? Decodable.Type {
                switch db_value {
                    case let DatabaseValue.blob(data):
                        value = try factory.decodeFromJSON(data: data)
                    case let DatabaseValue.text(str):
                        value = try factory.decodeFromJSON(text: str)
                    default:
                        value = db_value.anyValue
                }
            }
            else {
                value = db_value.anyValue
            }
            try property.set(value: value as Any, on: &nob)
        }
        // FIXME: Is this a much of a performance hit in copying when
        // the object is a `struct`?
        // Do we have a choice?
//        if var bob = nob as? CQIEntity {
//            bob.postload()
//            return bob
//        }
        nob.postload()
        return nob
    }
}

public extension CQIAdaptor {

    @discardableResult
    func update<E: CQIEntity>(_ nob: E) throws -> Int64 {
        
        let cfg = E.config
        var cols: [String] = []
        var values: [ParameterBindable?] = []

        for slot in cfg.slots where !slot.isExcluded {
            let property = try cfg.info.property(named: slot.name)
            cols.append(slot.column)
            try values.append(property.get(from: nob) as? ParameterBindable)
//            var valueType: Any.Type = property.type
        }
        let sql = db.updateSQL(cfg.table, cols: cols)
        print (sql)
        try db.update(cfg.table, cols: cols, to: values)
        return db.lastInsertRowid ?? nob.id._value
    }
}
