//
//  SafeTTesting_Events.swift
//  project493
//
//  Created by Isis Cordova on 4/10/19.
//  Copyright © 2019 SeniorDesign_17. All rights reserved.
//

import Foundation
import UIKit
import AWSDynamoDB

@objcMembers class SafeTTesting_Events: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var _userId: String?
    var _Type: String?
    var _description: String?
    
    
    class func dynamoDBTableName() -> String {
        
        return "safet-mobilehub-905430148-SafeT_Testing1"
    }
    
    class func hashKeyAttribute() -> String {
        
        return "_userId"
    }
    
    override class func jsonKeyPathsByPropertyKey() -> [AnyHashable: Any] {
        return [
            
            "_userId" : "userId",
            "_Type" : "Type",
            "_description" : "description"
        ]
    }
}
