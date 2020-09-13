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
    
    // MARK: CQI methods
    // =====================================

    func create(_ info: TypeInfo, from row: Row, columns: [String]) throws -> Any {
        
        var nob = try createInstance(of: info.type)
        
        for (ndx, col) in columns.enumerated() {
            let property = try info.property(named: col)
            var valueType: Any.Type = property.type
            
            if property.isOptional,
               let pinfo = try? typeInfo(of: property.type),
               let elementType = pinfo.elementType {
                valueType = elementType
            }
            // FIXME: Add the ability to use a ValueTransformer here
            // Actually will need to create a Swifty TypeTransformer
            let db_value = try row.value(at: ndx)
            let value: Any?
            if let factory = valueType as? DatabaseSerializable.Type
            {
                value = try factory.deserialize(from: db_value)
            } else {
                value = db_value.anyValue
            }
            try property.set(value: value as Any, on: &nob)
        }
        return nob
    }
    
    // Try and support simple basic DB row to Struct translations
    public func select<T>(_ type: T.Type = T.self, id: EntityID) throws -> T {
        guard let nob = try select(first: type, where: NSPredicate(format: "%K = %@", "id", id.int64)) else {
            throw CQIError.nothingFound() // in table with id = id
        }
        return nob
    }
    
    /**
     This method is a wrapper to the lower level `select(...)` to allow for an  request for
     a single instance  of the explicitly specified type.
     */
    public func select<T>(first type: T.Type, from table: String? = nil,
                          sorted_by: [String] = [],
                          where filter: NSPredicate? = nil) throws -> T? {
        try select(type, from: table, sorted_by: sorted_by, where: filter, limit: 1)
                .first
    }
    
    public func select(_ type: Any.Type, from table: String? = nil,
                          sorted_by: [String] = [],
                          where: NSPredicate? = nil,
                          limit: Int = 0) throws -> [Any] {
        
        // Using CQITypes enables a more robust interface to the underlying SQL/DB
        // FIXME: Let's check and use the provided CQIType metadata
        
        let inf = try typeInfo(of: type)
        let table = table ?? inf.name
        let cols = inf.properties.map { $0.name }
        
        // FIXME: NOT yet using NSPredicate
        var recs: [Any] = []
        try db.select(cols, from: table, limit: limit) { row in
            let nob = try create(inf, from: row, columns: cols)
            recs.append(nob)
        }
        return recs
    }

    public func select<T>(_ type: T.Type = T.self, from table: String? = nil,
                          sorted_by: [String] = [],
                          where: NSPredicate? = nil,
                          limit: Int = 0) throws -> [T] {

        // Using CQITypes enables a more robust interface to the underlying SQL/DB
        // FIXME: Let's check and use the provided CQIType metadata

        let inf = try typeInfo(of: T.self)
        let table = table ?? inf.name
        let cols = inf.properties.map { $0.name }
        
        // FIXME: NOT yet using NSPredicate
        var recs: [T] = []
        try db.select(cols, from: table, limit: limit) { row in
            if let nob = try create(inf, from: row, columns: cols) as? T {
                recs.append(nob)
            }
        }
        return recs
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

// MARK: CQI Config SELECT

public extension CQIAdaptor {
    
    func first<C: CQIEntity>(_ type: C.Type = C.self,
               from table: String? = nil,
               sorted_by: [String] = [],
               where test: NSPredicate? = nil) throws -> C? {
        try first(type.config, from: table, sorted_by: sorted_by, where: test) as? C
    }
    
    func first(_ cfg: CQIConfig,
                from table: String? = nil,
                sorted_by: [String] = [],
                where test: NSPredicate? = nil) throws -> Any? {
        
        let table = table ?? cfg.table
        let cols = cfg.columns()// cfg.slots.map { $0.column }
        
        // FIXME: NOT yet using Sort or NSPredicate
        var record: Any?
        try db.select(cols, from: table, limit: 1) { row in
            record = try create(cfg, from: row)
        }
        return record
    }

    func select<C: CQIEntity>(_ type: C.Type = C.self,
                from table: String? = nil,
                sorted_by sorts: [String] = [],
                where test: NSPredicate? = nil,
                limit: Int = 0) throws -> [C] {
        try (select(type.config, from: table, sorted_by: sorts, where: test, limit: limit)
                as? [C]) ?? []
    }
    
    func select(_ cfg: CQIConfig,
                from table: String? = nil,
                sorted_by: [String] = [],
                where: NSPredicate? = nil,
                limit: Int = 0) throws -> [Any] {
        
        let table = table ?? cfg.table
        let cols = cfg.columns() // slots.filter({ !$0.isMapped }).map { $0.column }
        
        // FIXME: NOT yet using Sort or NSPredicate
        var recs: [Any] = []
        try db.select(cols, from: table, limit: limit) { row in
            let nob = try create(cfg, from: row)
            recs.append(nob)
        }
        return recs
    }

    func create(_ cfg: CQIConfig, from row: Row) throws -> Any {
        
        var nob = try createInstance(of: cfg.type)
        
//        for (ndx, slot) in cfg.slots.enumerated() {
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
            } else if let factory = valueType as? Decodable {
                switch db_value {
//                    case let DatabaseValue.blob(data):
//                        value = factory.init
//                        value = try JSONDecoder().decode(factory, from: data)
                    case let DatabaseValue.text(str):
                        guard let data = str.data(using: .utf8)
                        else { throw DatabaseError("Cannot deserialize \(slot.column)") }
                        value = try JSONSerialization.jsonObject(with: data, options: [])
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
        // the object is a `struct`
        // Do we have a choice?
        if var bob = nob as? CQIEntity {
            bob.didInit()
            return bob
//            nob = e // in case nob is a struct
//            Swift.print(#line, e, nob)
        }
        return nob
    }

}
