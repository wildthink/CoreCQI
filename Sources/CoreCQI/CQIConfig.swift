//
//  CQIConfig.swift
//  CoreCQI
//
//  Created by Jason Jobe on 9/9/20.
//

import Foundation
import Runtime

/**
 The Config is built and modifiied following these steps.
 1.  Create a full list of available slots from the TypeInfo
 2.  Remove any dependent slots from the column list.
 3.  Add any map-from keys to col_list
 */
public class CQIConfig {
    var table: String
    var type: Any.Type
    var info: TypeInfo
    var slots: [Property] = []
    
    public init(_ name: String, type: Any.Type) throws {
        self.table = name
        self.type = type
        let ti = try typeInfo(of: type)
        self.info = ti
        slots = ti.properties.map { Property($0.name) }
    }
    
    public func index(ofColumn col: String) -> Int? {
        slots.first { $0.column == col }?.col_ndx
    }
    
    /**
     The method returns a unique set of database columns and updates the Slot.col_ndx
     to correspond with its ordering
     */
    public func columns() -> [String] {
        var cols: [String] = []

        for ndx in 0..<slots.count where !slots[ndx].isExcluded {
            if let col_ndx = cols.firstIndex(of: slots[ndx].column) {
                slots[ndx].col_ndx = col_ndx
            } else {
                slots[ndx].col_ndx = cols.count
                cols.append(slots[ndx].column)
            }
        }
        return cols
    }
    
    public func exclude(_ props: String...) -> Self {
        
        for ndx in 0..<slots.count {
            if props.contains(slots[ndx].name) {
                slots[ndx].column = ""
                slots[ndx].col_ndx = -1
            }
        }
        return self
    }
    
    public func set(_ prop: String, from col: String) -> Self {

        for ndx in 0..<slots.count {
            if slots[ndx].name == prop {
                slots[ndx].column = col
                break
            }
        }
        return self
    }
}

struct Property {
    var name: String
    var column: String
    var col_ndx: Int
    var isExcluded: Bool { col_ndx < 0 }
//    var isMapped: Bool = false // true if col == prop
    
    init (_ name: String, col: String? = nil, ndx: Int = 0) {
        self.name = name
        column = col ?? name
        col_ndx = ndx
    }
}

public extension CQIEntity {

    static func Config(_ name: String? = nil, type: Self.Type = Self.self) -> CQIConfig {
        let table = name ?? String(describing: type)
        return try! CQIConfig(table, type: type)
    }
    
    static var config: CQIConfig { Config() }

    func preload() {}
    func postload() {}
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
