//
//  File.swift
//  
//
//  Created by Jason Jobe on 5/29/21.
//

import Foundation
import Runtime

public typealias SQL = String

public extension SQL {
    /**
     entity      cid  name            type       notnull  dflt_value  pk
     ----------  ---  --------------  ---------  -------  ----------  --
     _atms       0    id              INTEGER    0        ¤           1
     _atms       1    _id             TEXT       0        ¤           0
     */
    static var master_schema: SQL {
        """
        select m.name as entity, p.* from sqlite_master as m join pragma_table_info(m.name) as p order by m.name, p.cid;
        """
    }
    
    static func table_schema(_ name: String) -> SQL {
        """
        select p.* from pragma_table_info(\(name)) as p order by p.cid;
        """
    }
}


public class SQLTable {
    var name: String
    var includes: [EntityInfo] // NSMutableOrderedSet // <EntityInfo>
    var columns: [SQLColumn] // NSMutableOrderedSet // <SQLColumn>
    
    public init(name: String, include: [EntityInfo], columns: [SQLColumn]) {
        self.name = name
        self.includes = include
        self.columns = columns
    }
}

public struct SQLColumn: Hashable {
    
    public static func == (lhs: SQLColumn, rhs: SQLColumn) -> Bool {
        lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    public enum StorageType: Int { case integer, float, text, blob, any }
    
    var name: String
    var cid: Int
    var storageType: StorageType = .any
    var valueType: ValueType = Any.Type.self
    
    var sql_def: String {
        "\(name) \(storageType)"
    }
}

public typealias ValueType = Any.Type

public struct EntityInfo {
    var name: String
    var includes: [EntityInfo]
}

public extension SQLTable {
    func addColumns(for cols: [SQLColumn]) -> String {
        var sql = ""
        for c in cols where !columns.contains(c) {
            Swift.print ("ALTER TABLE \(name) ADD \(c.sql_def);", to: &sql)
        }
        return sql
    }
}
