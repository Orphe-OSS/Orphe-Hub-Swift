//
//  OSCMappingValues.swift
//  Orphe-Hub-Swift
//
//  Created by kyosuke on 2017/06/28.
//  Copyright © 2017 no new folk studio Inc. All rights reserved.
//

import RealmSwift

class OSCMappingValues: Object {
    
    dynamic var name = ""
    dynamic var min:Float = 0.0
    dynamic var max:Float = 0.0
    
    override static func primaryKey() -> String? {
        return "name"
    }
    
    static func getMin(name:String) -> Float? {
        do{
            let realm = try Realm()
            let oscMappingValues = realm.object(ofType: OSCMappingValues.self, forPrimaryKey: name)
            if let oscMappingValues = oscMappingValues {
                return oscMappingValues.min
            } else {
                return nil
            }
        }
        catch{
            print("could not make realm object")
        }
        return nil
    }
    
    static func setMin(name:String, minValue:Float){
        do{
            let realm = try Realm()
            let oscMappingValues = realm.object(ofType: OSCMappingValues.self, forPrimaryKey: name)
            if let oscMappingValues = oscMappingValues {
                try realm.write {
                    oscMappingValues.min = minValue
                }
            }
            else{
                let oscMappingValues = OSCMappingValues()
                oscMappingValues.name = name
                try realm.write {
                    realm.add(oscMappingValues)
                }
            }
        }
        catch{
            print("could not make realm object")
        }
    }
    
    static func getMax(name:String) -> Float? {
        do{
            let realm = try Realm()
            let oscMappingValues = realm.object(ofType: OSCMappingValues.self, forPrimaryKey: name)
            if let oscMappingValues = oscMappingValues {
                return oscMappingValues.max
            } else {
                return nil
            }
        }
        catch{
            print("could not make realm object")
        }
        return nil
    }
    
    static func setMax(name:String, maxValue:Float){
        do{
            let realm = try Realm()
            let oscMappingValues = realm.object(ofType: OSCMappingValues.self, forPrimaryKey: name)
            if let oscMappingValues = oscMappingValues {
                try realm.write {
                    oscMappingValues.max = maxValue
                }
            }
            else{
                let oscMappingValues = OSCMappingValues()
                oscMappingValues.name = name
                try realm.write {
                    realm.add(oscMappingValues)
                }
            }
        }
        catch{
            print("could not make realm object")
        }
    }
    
    private static func reset() throws {
        let realm = try Realm()
        let records = realm.objects(OSCMappingValues.self)
        try realm.write {
            realm.delete(records)
        }
    }
    
}
