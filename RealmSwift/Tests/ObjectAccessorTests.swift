////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import XCTest
import RealmSwift
import Foundation

class ObjectAccessorTests: TestCase {
    func setAndTestAllProperties(object: SwiftObject) {
        object.boolCol = true
        XCTAssertEqual(object.boolCol, true)
        object.boolCol = false
        XCTAssertEqual(object.boolCol, false)

        object.intCol = -1
        XCTAssertEqual(object.intCol, -1)
        object.intCol = 0
        XCTAssertEqual(object.intCol, 0)
        object.intCol = 1
        XCTAssertEqual(object.intCol, 1)

        object.floatCol = 20
        XCTAssertEqual(object.floatCol, 20 as Float)
        object.floatCol = 20.2
        XCTAssertEqual(object.floatCol, 20.2 as Float)
        object.floatCol = 16777217
        XCTAssertEqual(Double(object.floatCol), 16777216.0 as Double)

        object.doubleCol = 20
        XCTAssertEqual(object.doubleCol, 20)
        object.doubleCol = 20.2
        XCTAssertEqual(object.doubleCol, 20.2)
        object.doubleCol = 16777217
        XCTAssertEqual(object.doubleCol, 16777217)

        object.stringCol = ""
        XCTAssertEqual(object.stringCol, "")
        let utf8TestString = "值значен™👍☞⎠‱௹♣︎☐▼❒∑⨌⧭иеمرحبا"
        object.stringCol = utf8TestString
        XCTAssertEqual(object.stringCol, utf8TestString)

        let data = "b".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        object.binaryCol = data
        XCTAssertEqual(object.binaryCol, data)

        let date = NSDate(timeIntervalSinceReferenceDate: 2) as NSDate
        object.dateCol = date
        XCTAssertEqual(object.dateCol, date)

        object.objectCol = SwiftBoolObject(value: [true])
        XCTAssertEqual(object.objectCol.boolCol, true)
    }

    func testStandaloneAccessors() {
        let object = SwiftObject()
        setAndTestAllProperties(object)
    }

    func testPersistedAccessors() {
        let object = SwiftObject()
        Realm().beginWrite()
        Realm().create(SwiftObject)
        setAndTestAllProperties(object)
        Realm().commitWrite()
    }

    func testIntSizes() {
        let realm = realmWithTestPath()

        let v8  = Int8(1)  << 6
        let v16 = Int16(1) << 12
        let v32 = Int32(1) << 30
        // 1 << 40 doesn't auto-promote to Int64 on 32-bit platforms
        let v64 = Int64(1) << 40
        realm.write {
            let obj = SwiftAllIntSizesObject()

            let testObject: Void -> Void = {
                func setAndTestValue<O: Object, T: Equatable>(object: O, #value: T, #getter: (O) ->(T), #setter: (O, T) -> ()) {
                    setter(object, value)
                    XCTAssertEqual(getter(object), value)
                }

                obj.objectSchema.properties.map { $0.name }.map { obj[$0] = 0 }

                setAndTestValue(obj, value: v8, getter: { Int8($0["int8"]! as Int) }, setter: { $0["int8"] = Int($1) as NSNumber })
                setAndTestValue(obj, value: v16, getter: { Int16($0["int16"]! as Int) }, setter: { $0["int16"] = Int($1) as NSNumber })
                setAndTestValue(obj, value: v32, getter: { Int32($0["int32"]! as Int) }, setter: { $0["int32"] = Int($1) as NSNumber })
                setAndTestValue(obj, value: v64, getter: { Int64($0["int64"]! as Int) }, setter: { $0["int64"] = Int($1) as NSNumber })

                setAndTestValue(obj, value: v8, getter: { Int8($0.valueForKey("int8")! as Int) }, setter: { $0.setValue(Int($1) as NSNumber, forKey: "int8") })
                setAndTestValue(obj, value: v16, getter: { Int16($0.valueForKey("int16")! as Int) }, setter: { $0.setValue(Int($1) as NSNumber, forKey: "int16") })
                setAndTestValue(obj, value: v32, getter: { Int32($0.valueForKey("int32")! as Int) }, setter: { $0.setValue(Int($1) as NSNumber, forKey: "int32") })
                setAndTestValue(obj, value: v64, getter: { Int64($0.valueForKey("int64")! as Int) }, setter: { $0.setValue(Int($1) as NSNumber, forKey: "int64") })

                setAndTestValue(obj, value: v8, getter: {$0.int8}, setter: {_ = $0.int8 = $1})
                setAndTestValue(obj, value: v16, getter: {$0.int16}, setter: {_ = $0.int16 = $1})
                setAndTestValue(obj, value: v32, getter: {$0.int32}, setter: {_ = $0.int32 = $1})
                setAndTestValue(obj, value: v64, getter: {$0.int64}, setter: {_ = $0.int64 = $1})
            }

            testObject()

            realm.add(obj)

            testObject()
        }

        let obj = realm.objects(SwiftAllIntSizesObject).first!
        XCTAssertEqual(obj.int8, v8)
        XCTAssertEqual(obj.int16, v16)
        XCTAssertEqual(obj.int32, v32)
        XCTAssertEqual(obj.int64, v64)
    }

    func testLongType() {
        let longNumber = 17179869184
        let intNumber = 2147483647
        let negativeLongNumber = -17179869184
        let updatedLongNumber = 8589934592

        let realm = realmWithTestPath()

        realm.beginWrite()
        realm.create(SwiftIntObject.self, value: [longNumber])
        realm.create(SwiftIntObject.self, value: [intNumber])
        realm.create(SwiftIntObject.self, value: [negativeLongNumber])
        realm.commitWrite()

        let objects = realm.objects(SwiftIntObject)
        XCTAssertEqual(objects.count, Int(3), "3 rows expected")
        XCTAssertEqual(objects[0].intCol, longNumber, "2 ^ 34 expected")
        XCTAssertEqual(objects[1].intCol, intNumber, "2 ^ 31 - 1 expected")
        XCTAssertEqual(objects[2].intCol, negativeLongNumber, "-2 ^ 34 expected")

        realm.beginWrite()
        objects[0].intCol = updatedLongNumber
        realm.commitWrite()

        XCTAssertEqual(objects[0].intCol, updatedLongNumber, "After update: 2 ^ 33 expected")
    }
}
