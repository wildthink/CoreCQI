struct CoreCQI {
    var text = "Core Common Query Interface"
}

public protocol CQIEntity {
    static var config: CQIConfig { get }
    var id: EntityID { get set }
    mutating func preload()
    mutating func postload()
}

public typealias DBEntity = CQIEntity & Identifiable

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
/*
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
*/

