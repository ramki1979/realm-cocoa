//
//  tutorial.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import "RLMTestCase.h"

#import <realm/objc/Realm.h>
#import <realm/objc/RLMPrivateTableMacrosFast.h>

REALM_TABLE_DEF_3(PeopleTable,
                  Name,  String,
                  Age,   Int,
                  Hired, Bool)

REALM_TABLE_DEF_2(PeopleTable2,
                  Hired, Bool,
                  Age,   Int)

REALM_TABLE_IMPL_3(PeopleTable,
                   Name,  String,
                   Age,   Int,
                   Hired, Bool)

REALM_TABLE_IMPL_2(PeopleTable2,
                   Hired, Bool,
                   Age,   Int)

REALM_TABLE_FAST(PeopleTable)

REALM_TABLE_FAST(PeopleTable2)

@interface MACTestTutorial: RLMTestCase

@end

@implementation MACTestTutorial

- (void)testTutorial
{
    //------------------------------------------------------
    NSLog(@"--- Creating tables ---");
    //------------------------------------------------------

    RLMTransactionManager *manager = [self managerWithTestPath];
    
    [manager writeUsingBlock:^(RLMRealm *realm) {
        // Create new table in realm
        PeopleTable *people = [realm createTableWithName:@"employees" asTableClass:[PeopleTable class]];
        
        // Add some rows
        [people addName:@"John" Age:20 Hired:YES];
        [people addName:@"Mary" Age:21 Hired:NO];
        [people addName:@"Lars" Age:21 Hired:YES];
        [people addName:@"Phil" Age:43 Hired:NO];
        [people addName:@"Anni" Age:54 Hired:YES];
        
        // Insert at specific position
        [people insertEmptyRowAtIndex:2 Name:@"Frank" Age:34 Hired:YES];
        
        // Getting the size of the table
        NSLog(@"PeopleTable Size: %lu - is %@.    [6 - not empty]", [people rowCount],
              people.rowCount == 0 ? @"empty" : @"not empty");
        
        //------------------------------------------------------
        NSLog(@"--- Working with individual rows ---");
        //------------------------------------------------------
        
        // Getting values
        NSString * name = [people rowAtIndex:5].Name;   // => 'Anni'
        // Using a row
        PeopleTableRow *myRow = [people rowAtIndex:5];
        int64_t age = myRow.Age;                           // => 54
        BOOL hired  = myRow.Hired;                         // => true
        NSLog(@"%@ is %lld years old.", name, age);
        if (hired) NSLog(@"is hired.");
        
        // Setting values  (note: setter access will be made obsolete, use dot notation)
        [people rowAtIndex:5].Age = 43;  // Getting younger
        
        // or with dot-syntax:
        myRow.Age += 1;                                    // Happy birthday!
        NSLog(@"%@ age is now %lld.   [44]", myRow.Name, myRow.Age);
        
        // Get last row
        NSString *lastname = [people rowAtLastIndex].Name;       // => "Anni"
        NSLog(@"Last name is %@.   [Anni]", lastname);
        
        // Change a row - not implemented yet
        // [people setAtIndex:4 Name:"Eric" Age:50 Hired:YES];
        
        // Delete row
        [people removeRowAtIndex:2];
    }];
    
    PeopleTable *people = [[self realmPersistedAtTestPath] tableWithName:@"employees" asTableClass:[PeopleTable class]];
    
    NSLog(@"%lu rows after remove.  [5]", [people rowCount]);  // 5
    XCTAssertEqual([people rowCount], (NSUInteger)5,@"rows should be 5");

    // Iterating over rows:
    for (NSUInteger i = 0; i < [people rowCount]; ++i) {
        PeopleTableRow *row = [people rowAtIndex:i];
        NSLog(@"(Rows) %@ is %lld years old.", row.Name, row.Age);
    }

    //------------------------------------------------------
    NSLog(@"--- Simple Searching ---");
    //------------------------------------------------------

    NSUInteger row;
    row = [people.Name find:@"Philip"];    // row = (NSUInteger)-1
    NSLog(@"Philip: %zu  [-1]", row);
    XCTAssertEqual(row, NSNotFound, @"Philip should not be there", nil);

    row = [people.Name find:@"Mary"];
    NSLog(@"Mary: %zu", row);
    XCTAssertEqual(row, (NSUInteger)1,@"Mary should have been there", nil);

    PeopleTableView *view = [[[people where].Age columnIsEqualTo:21] findAll];
    NSUInteger cnt = [view rowCount];             // cnt = 2
    XCTAssertEqual(cnt, (NSUInteger)2,@"Should be two rows in view", nil);

    //------------------------------------------------------
    NSLog(@"--- Queries ---");
    //------------------------------------------------------

    // Create query (current employees between 20 and 30 years old)
    PeopleTableQuery *q = [[[people where].Hired columnIsEqualTo:YES]            // Implicit AND
                                  .Age columnIsBetween:20 :30];

    // Get number of matching entries
    NSLog(@"Query count: %lu",[q countRows]);
    XCTAssertEqual([q countRows] , (NSUInteger)2,@"Expected 2 rows in query", nil);

    // Get the average age - currently only a low-level interface!
    double avg = [q.Age avg] ;
    NSLog(@"Average: %f    [20.5]", avg);
    XCTAssertEqual(avg, 20.5,@"Expected 20.5 average", nil);

    // Execute the query and return a table (view)
    RLMView *res = [q findAll];
    for (NSUInteger i = 0; i < [res rowCount]; ++i) {
        NSLog(@"%zu: %@ is %lld years old", i,
            [people rowAtIndex:i].Name,
            [people rowAtIndex:i].Age);
    }
    
    [manager writeUsingBlock:^(RLMRealm *realm) {
        PeopleTable *table = [realm tableWithName:@"employees" asTableClass:[PeopleTable class]];
        [table addName:@"Anni" Age:54 Hired:YES];
        
        XCTAssertEqual([table rowCount], (NSUInteger)6, @"PeopleTable should have 6 rows");
        
        for (NSUInteger i = 0; i < [table rowCount]; i++) {
            PeopleTableRow *row = [table rowAtIndex:i];
            NSLog(@"%zu: %@", i, row.Name);
        }
    }];
}

@end