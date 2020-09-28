//
//  File.swift
//  
//
//  Created by Jason Jobe on 9/24/20.
//

import Foundation

public typealias PersonName = PersonNameComponents

//public struct PersonName: Codable, Equatable {
//    public var components: PersonNameComponents
//
//    public subscript(keyPath: WritableKeyPath<PersonNameComponents,String>)
//    -> String
//    {
//        get { components[keyPath: keyPath] }
//        //        mutating
//        set { components[keyPath: keyPath] = newValue }
//    }
//    public var phoneticRepresentation: PersonNameComponents? {
//        get { components.phoneticRepresentation }
//        set { components.phoneticRepresentation = newValue }
//    }
//}

public struct DaySpan {
    var years: Int = 0
    var months: Int = 0
    var days: Int = 0
    
    var estDays: Int {
        (years * 365) + Int(Double(months) * 30.42) + days
    }
    
    var estMonths: Double {
        (Double(years) * 12) + Double(months) + (Double(days) / 30.42)
    }
}

public extension String {
    
    subscript (_ index: Int) -> String {
        return String(self[self.index(startIndex, offsetBy: index)])
    }
    
    subscript (_ range: CountableRange<Int>) -> String {
        let lowerBound = index(startIndex, offsetBy: range.lowerBound)
        let upperBound = index(startIndex, offsetBy: range.upperBound)
        return String(self[lowerBound..<upperBound])
    }
    
    subscript (_ range: CountableClosedRange<Int>) -> String {
        let lowerBound = index(startIndex, offsetBy: range.lowerBound)
        let upperBound = index(startIndex, offsetBy: range.upperBound)
        return String(self[lowerBound...upperBound])
    }
    
    subscript (_ range: CountablePartialRangeFrom<Int>) -> String {
        return String(self[index(startIndex, offsetBy: range.lowerBound)...])
    }
    
    subscript (_ range: PartialRangeUpTo<Int>) -> String {
        return String(self[..<index(startIndex, offsetBy: range.upperBound)])
    }
    
    subscript (_ range: PartialRangeThrough<Int>) -> String {
        return String(self[...index(startIndex, offsetBy: range.upperBound)])
    }
    
}

// 'y.m.15'
// fri.1.%2.#10

public extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    subscript (safe index: Index, else value: Element) -> Element {
        return indices.contains(index) ? self[index] : value
    }
}

public extension Collection {

    func has_any(_ items: [Element]) -> Bool where Element: Equatable {
        for item in items {
            if self.contains (item) { return true }
        }
        return false
    }
    
    func has_all(_ items: [Element]) -> Bool where Element: Equatable {
        for item in items {
            if !self.contains (item) { return false }
        }
        return true
    }

}
