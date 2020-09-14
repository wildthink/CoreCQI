import XCTest
@testable import CoreCQI

final class CoreCQITests: XCTestCase {
    
    let dba = CQIAdaptor!
    
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

    struct Person {
        var given: String
        var family: String
        var age: Int
    }
    
    func testQueries() {
        let p: Person = dba.first()
        print (p)
    }

    static var allTests = [
        ("testQueries", testQueries),
    ]
}
