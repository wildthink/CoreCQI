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
    }
    
    @_functionBuilder
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

extension Schema.Block: BlockConvertable {
    func asSchemaBlocks() -> [Schema.Block] { [self] }
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


public struct EntityInfo {
    func asSchemaBlocks() -> [Schema.Block] {
        []
    }
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
 Property
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

func demoSchema() {
    let schema = Schema(name: "demo") {
        "alpha"
        Schema.Block(value: 23)
    }
    
    Swift.print(schema)
}
