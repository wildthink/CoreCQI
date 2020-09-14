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

/**
 Any  Struct or Class acting as a query model for CGI Data.
 
 IDEAS:
 - include/exclude options
 - renaming slot <=> column
 - transformers (eg. name/URL to Image)
 - forrmatters
 - think carefully about reverse operations (e.g. Image ?-> name)
 - JSON Column vs JOIN relationships
 */
public protocol CQIType {
    static var CQIKeys: [CQI.PropertyKey] { get }
    static func cqiQuery() throws -> CQI.Query
}

public struct CQI {
    public struct PropertyKey: StringRepresentable {
        public var value: String
        public init(stringLiteral value: String) {
            self.value = value
        }
    }
    public struct Query: StringRepresentable {
        public var value: String
        public init(stringLiteral value: String) {
            self.value = value
        }
    }
}

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
    
// MARK: exec methos
// =====================================
    public func exec(sql: String) throws {
        try db.batch(sql: sql)
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
    
    func first<C: CQIEntity>(_ type: C.Type = C.self,
               from table: String? = nil,
               where format: String? = nil, _ argv: Any...,
               order_by: [Database.Ordering]? = nil
    )
    throws -> C? {
        if let format = format {
            let pred = NSPredicate(format: format, argumentArray: argv)
            return try first(type.config, from: table, where: pred, order_by: order_by) as? C
        } else {
            return try first(type.config, from: table, order_by: order_by) as? C
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
        try db.select(cols, from: table,
                      where: predicate?.sql,
                      order_by: order_by, limit: 1) { row in
            record = try create(cfg, from: row)
        }
        return record
    }

    func select<C: CQIEntity>(_ type: C.Type = C.self,
                from table: String? = nil,
                where format: String? = nil, _ argv: Any...,
                order_by: [Database.Ordering]? = nil,
                limit: Int = 0) throws -> [C] {
        
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
    }
    
    func select(_ cfg: CQIConfig,
                from table: String? = nil,
                where predicate: NSPredicate? = nil,
                order_by: [Database.Ordering]? = nil,
                limit: Int = 0) throws -> [Any] {
        
        let table = table ?? cfg.table
        let cols = cfg.columns()
        
        var recs: [Any] = []
        try db.select(cols, from: table, where: predicate?.sql,
                      order_by: order_by, limit: limit) { row in
            let nob = try create(cfg, from: row)
            recs.append(nob)
        }
        return recs
    }

    func create(_ cfg: CQIConfig, from row: Row) throws -> Any {
        
        var nob = try createInstance(of: cfg.type)
        
        if var bob = nob as? CQIEntity {
            bob.preload()
            nob = bob
        }

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
            if let factory = valueType as? DatabaseSerializable.Type
            {
                value = try factory.deserialize(from: db_value)
            }
//            else if let factory = valueType as? Decodable.Type {
//                switch db_value {
//                    case let DatabaseValue.blob(data):
//                        let decoder = JSONDecoder()
//                        let nob = try decoder.decode(factory, from: data)
//                    case let DatabaseValue.text(str):
//                        guard let data = str.data(using: .utf8)
//                        else { throw DatabaseError("Cannot deserialize \(slot.column)") }
//                        value = try JSONSerialization.jsonObject(with: data, options: [])
//                    default:
//                        value = db_value.anyValue
//                }
//            }
            else {
                value = db_value.anyValue
            }
            try property.set(value: value as Any, on: &nob)
        }
        // FIXME: Is this a much of a performance hit in copying when
        // the object is a `struct`
        // Do we have a choice?
        if var bob = nob as? CQIEntity {
            bob.postload()
            return bob
        }
        return nob
    }

}
