//
//  DBEntity.swift
//  
//  Copyright © 2020 Jason Jobe. All rights reserved.
//  Created by Jason Jobe on 9/7/20.
//

import Foundation

public typealias EIDValue = Decodable & Encodable & FixedWidthInteger

public class Counter {
    var name: String
    var count: Int64
    
    public init(_ name: String, start: Int64 = 0) {
        self.name = name
        self.count = start
    }
    func next() -> Int64 {
        count += 1
        return count
    }
}

public typealias EntityID = Int64

public extension EntityID {
    var int64: Int64 { self }
}

/*
public extension EntityID {
    init (_ counter: Counter) {
        _value = counter.next()
    }
}

public struct EntityID
: Comparable, Codable, Hashable,
  ExpressibleByNilLiteral, ExpressibleByIntegerLiteral
{
    let _value: Int64
    public var int64: Int64 { _value }
    
    public init(nilLiteral: ()) {
        _value = 0
    }
    public init(integerLiteral value: Int64) {
        _value = value
    }
    public init<I:BinaryInteger>(_ value: I) {
        _value = Int64(value)
    }
    public static func < (lhs: EntityID, rhs: EntityID) -> Bool {
        lhs._value < rhs._value
    }
}
*/
