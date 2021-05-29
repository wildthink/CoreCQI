//
//  File.swift
//  
//
//  Created by Jason Jobe on 5/29/21.
//

import Foundation

public class SQLTable {
    var name: String
    var includes: NSMutableOrderSet<EntityInfo>
    var columns: NSMutableOrderSet<SQLColumn>
}

public struct SQLColumn: Hasable {

    public enum StorageType { case integer, float, text, blob, any }
    var name: String
    var storageType: StorageType
    var valueType: ValueType
    
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
            print ("ALTER TABLE \(name) ADD \(col.sql_def);", into: &sql)
        }
        return sql
    }
}
