//
//  Schema.swift
//  ExampleCoders
//
//  Copyright © 2020 Jason Jobe. All rights reserved.
//  Created by Jason Jobe on 9/6/20.
//

import Foundation

func trace(_ line: Int = #line, _ f: String = #function) {
    Swift.print(line, f)
}

extension BlockConvertable {
    func trace(_ line: Int = #line, _ f: String = #function) {
        Swift.print(line, type(of: self), f)
    }
}

public struct Schema {
    var name: String
    var blocks: [Block]
    
    init(name: String,
         @Schema.Builder builder: () -> [Block]) {
        self.name = name
        self.blocks = builder()
    }
}

public extension Schema {
    struct Block {
        var value: Any?
        var tags: [String] = []
    }
    
    @resultBuilder
    struct Builder {
        static func buildBlock() -> [Schema.Block] {
            trace()
            return []
        }
    }
}

protocol BlockConvertable {
    func asSchemaBlocks() -> [Schema.Block]
}

extension BlockConvertable {
    func tag(_ tags: String...) -> Self {
        // Apply the tags
        self
    }
}

extension Schema.Block: BlockConvertable {
    func asSchemaBlocks() -> [Schema.Block] { [self] }
    
    mutating func tag(_ tags: String...) -> Self {
        var new = self.tags
        for t in tags {
            new.append(t)
        }
        self.tags = new
        return self
    }
}

//extension Schema.Group: BlockConvertable {
//    func asSchemaBlocks() -> [Schema.Block] {
//        [Schema.Block(name: name, value: .group(Schema.Blocks))]
//    }
//}

extension Schema.Builder {
    static func buildBlock(_ values: BlockConvertable...) -> [Schema.Block] {
        trace()
        return values.flatMap { $0.asSchemaBlocks() }
    }
}

// Here we extend Array to make it conform to our BlockConvertable
// protocol, in order to be able to return an empty array from our
// 'buildIf' implementation in case a nil value was passed:
extension Array: BlockConvertable where Element == Schema.Block {
    func asSchemaBlocks() -> [Schema.Block] { self }
}


extension String: BlockConvertable {
    func asSchemaBlocks() -> [Schema.Block] {
        trace()
        return [Schema.Block(value: self)]
    }
}

//extension BlockConvertable {
//    func sample(_ str: String) -> [Schema.Block] {
//        trace()
//        return [Schema.Block(value: self)]
//    }
//}

// DEMO
/**
 Options:
 Entity
 - includes (Freebase style type inclusion)
 - The Base Entity is included by other Entities
 Property
 - DB storage format (e.g. TEXT, INTEGER, ...)
 - Formatter/Transformer
    - Date
    - URL <-> String
     - string <-> image
     - string <-> color
 - Relationship - have optional, inverse relationship key
    - to_one
    - to_many
 - tags -> [String] JSON
 - JSON
    - [String/Int/Double]
    - [String: Any]
 */

//public struct EntityInfo {
//    func asSchemaBlocks() -> [Schema.Block] {
//        []
//    }
//}

struct Column: BlockConvertable {
    
    var name: String
    var column: String
    var memo: String?
    var unique: Bool = false
    var primaryKey: Bool = false
    
//    var columnType: Any.Type
//    var valueType: Any.Type
//    var transformer: () -> Void
    func asSchemaBlocks() -> [Schema.Block] { [] }
}

extension Column {
    
    init (_ name: String, as col: String? = nil, primaryKey: Bool = false,
          memo: String? = nil) {
        self.name = name
        self.column = col ?? name
        self.primaryKey = primaryKey
        self.memo = memo
    }

    // init(_ name: String?, ref key: String) // refers to a previously defined Column
    
    func memo(_ text: String) -> Self {
        var me = self
        me.memo = text
        return me
    }
}

struct Table: BlockConvertable {
    typealias Block = Schema.Block
    var name: String
    var blocks: [Block]
    func asSchemaBlocks() -> [Schema.Block] { blocks }
    
    init(_ name: String,
         @Schema.Builder builder: () -> [Block]) {
        self.name = name
        self.blocks = builder()
    }
    
    init(ref: String) {
        self.name = ref
        self.blocks = []
    }
}

struct Group: BlockConvertable {
    typealias Block = Schema.Block
    var name: String
    var blocks: [Block]
    func asSchemaBlocks() -> [Schema.Block] { blocks }
    
    init(_ name: String,
         @Schema.Builder builder: () -> [Block]) {
        self.name = name
        self.blocks = builder()
    }
    
    init(ref: String) {
        self.name = ref
        self.blocks = []
    }
}

@resultBuilder
struct Prop {
    static func buildBlock() -> [Schema.Block] {
        trace()
        return []
    }
}

@resultBuilder
struct Relationship {
    static func buildBlock() -> [Schema.Block] {
        trace()
        return []
    }
}

//protocol Funky {
//    @Relationship var link: [Schema.Block] { get }
//}


func include(table: String) -> [Schema.Block] {
    Table(ref: table).asSchemaBlocks()
}

func demoSchema() {
    typealias T_ = Table
    
    let schema = Schema(name: "habit") {
        Column("dob")
            .memo("Date of Birth")
        Table ("Base") {
            Column("id", primaryKey: true)
        }
        T_("plan") {
            include(table: "Base")
            Column("name")
            Column("")
        }
    }
    
    Swift.print(schema)
}
