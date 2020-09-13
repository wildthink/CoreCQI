//
//  CQIConfig.swift
//  CoreCQI
//
//  Created by Jason Jobe on 9/9/20.
//

import Foundation
import Runtime

public protocol CQIEntity {
    static var config: CQIConfig { get }
    var id: EntityID { get }
}

//extension CQIEntity: Indentifiable {}

/**
 The Config is built and modifiied following these steps.
 1.  Create a full list of available slots from the TypeInfo
 2.  Remove any dependent slots from the column list.
 3.  Add any map-from keys to col_list
 */
public struct CQIConfig {
    var ename: String
    var type: Any.Type
    var info: TypeInfo
    var slots: [Slot] = []
    
    public init(_ name: String, type: Any.Type) throws {
        self.ename = name
        self.type = type
        let ti = try typeInfo(of: type)
        self.info = ti
        slots = ti.properties.enumerated().map { (n, c) in Slot(col: c.name, ndx: n) }
    }
    
    public func index(ofColumn col: String) -> Int? {
        slots.first { $0.column == col }?.col_ndx
    }
    
    public func set(_ prop: String, from col: String) -> Self {
        var next = self
        for ndx in 0..<slots.count {
            if next.slots[ndx].property == prop {
                // If there is a previous slot entry for the
                // same column then we will use it's index
                // to avoid duplicate columns in the SQL SELECT
                if let col_ndx = index(ofColumn: col),
                   col_ndx != next.slots[ndx].col_ndx
                {
                    next.slots[ndx].col_ndx = col_ndx
                    next.slots[ndx].isMapped = true
                }
                next.slots[ndx].column = col
                break
            }
        }
        return next
    }
}

struct Slot {
    var column: String
    var property: String
    var col_ndx: Int
    var isMapped: Bool = false // true if col == prop
    
    init (col: String, ndx: Int, prop: String? = nil) {
        column = col
        col_ndx = ndx
        property = prop ?? col
    }
//    var
}

//public extension CQIConfig {
//
//    init <E>(_ en: String, type: E.Type) {
//        self.ename = en
//        self.type = E.self
//        // FIXME: Do error handling
//        info = try! typeInfo(of: type)
//    }
//}

public extension CQIEntity {
//    static func qtype() -> Self.Type { Self.self }
    static func Config(_ name: String? = nil, type: Self.Type = Self.self) -> CQIConfig {
        let ename = name ?? String(describing: type)
        return try! CQIConfig(ename, type: type)
    }
    
//    static var Config: CQIConfig {
//        CQIConfig(String(describing: Self.self), type: Self.self)
//    }
}

// MARK: Helpers

public protocol StringRepresentable: Hashable, Codable, ExpressibleByStringLiteral,
                                     Comparable,
                                     CustomStringConvertible where StringLiteralType == String {
    var value: String { set get }
}

public extension StringRepresentable {
    
    var description: String { value }
    
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.value < rhs.value
    }
}

@propertyWrapper
public struct CQIValue<T> {
    public private(set) var wrappedValue: T
    public var id: Int64 = 0
    public var projectedValue: CQIValue<T> { return self }
    
    public init(wrappedValue: T, id: Int64, in table: String? = nil)  {
        self.wrappedValue = wrappedValue
    }
    
    public init(wrappedValue: T, from table: String? = nil, where test: String? = nil, limit: Int = 0)  {
        self.wrappedValue = wrappedValue
    }
}
