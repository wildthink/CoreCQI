import XCTest
@testable import CoreCQI

final class CoreCQITests: XCTestCase {
    
    var dba: CQIAdaptor!
    
    override func setUpWithError() throws {
        dba = try CQIAdaptor(inMemory: true)
        
        // Load some test data
        let sql = """
        CREATE TABLE person (id integer primary key, given, family, age);

        INSERT INTO person (given, family, age)
        VALUES
            ('George', 'Jetson', 25),
            ('Jane', 'Jetson', 22)
        ;
        """
        
        try dba.exec(sql: sql)
    }

    struct Person: DBEntity {
        var id: EntityID
        
        var given: String
        var family: String
        var age: Int
    }
    
    func testQueries() throws {
        let p1: Person? = dba.first()
        let p2 = dba.first(Person.self)
        print (p1 as Any, p2)
    }

    static var allTests = [
        ("testQueries", testQueries),
    ]
}
