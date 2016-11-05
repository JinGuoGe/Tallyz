//
//  VenueItem.swift
//  Tallyz
//
//  Created by LionKing on 8/2/16.
//  Copyright © 2016 bigcity. All rights reserved.
//

import Foundation
import Firebase

struct VenueItem {
    
    var key: String!
    var venueID: String!
    var maleCount: Int!
    var femaleCount: Int!
    var ref: Firebase?
   
    
    // Initialize from arbitrary data
    init(venueID: String, maleCount: Int, femaleCount: Int, key: String = "") {
        self.key = key
        self.venueID = venueID
        self.maleCount = maleCount
        self.femaleCount = femaleCount
        self.ref = nil
    }
    
    init(snapshot: FDataSnapshot) {
        key = snapshot.key
        
        venueID = snapshot.value.objectForKey("venueID") as! String
        maleCount = snapshot.value.objectForKey("maleCount") as! Int
        femaleCount = snapshot.value.objectForKey("femaleCount") as! Int
        ref = snapshot.ref
    }
    
    func toAnyObject() -> AnyObject {
        return [
            "venueID": venueID,
            "maleCount": maleCount,
            "femaleCount": femaleCount
        ]
    }
    
}
