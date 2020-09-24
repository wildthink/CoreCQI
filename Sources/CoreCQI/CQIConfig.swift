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
    public typealias OwnerType = CQIStruct.Type
    
    var table: String
    var type: OwnerType
    var info: TypeInfo
    var slots: [Property] = []
    
    public init(_ name: String, type: OwnerType) throws {
        self.table = name
        self.type = type
        let ti = try typeInfo(of: type)
        self.info = ti
        slots = ti.properties.map { Property($0.name, info: $0) }
    }
    
    /**
     The method returns a unique set of database columns and updates the Slot.col_ndx
     to correspond with its ordering
     */
    
    public func columns() -> [String] {
        var cols = Set<String>()
        for p in slots {
            cols.formUnion(p.columns)
        }
        return Array(cols)
    }
    
    public func exclude(_ props: String...) -> Self {
        
        for ndx in 0..<slots.count {
            if props.contains(slots[ndx].name) {
                slots[ndx].columns = []
            }
        }
        return self
    }
    
    func property(named: String) -> Property? {
        slots.first(where: {$0.name == named })
    }
    
    public func derive(_ prop: String, from: String...) -> Self {
        property(named: prop)?.columns = from
        return self
    }
}

class Property: CustomStringConvertible {
    var name: String
    var columns: [String] = []
    var info: PropertyInfo

    var isExcluded: Bool { columns.isEmpty }
    var hasColumnValue: Bool { columns.count == 1 }
    
    init (_ name: String, col: String? = nil, info: PropertyInfo) {
        self.name = name
        if let qt = info.type as? CQIStruct.Type {
            columns = qt.config.columns()
        } else {
            columns = [col ?? name]
        }
        self.info = info
    }
    
    var description: String {
        "Slot (\(columns) -> \(name)"
    }
}

public extension CQIStruct {

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
