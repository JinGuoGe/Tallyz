//
//  Venue.swift
//  Tallyz
//
//  Created by LionKing on 7/25/16.
//  Copyright © 2016 bigcity. All rights reserved.
//

import Foundation
import RealmSwift
import MapKit

class Venue: Object
{
    dynamic var id:String = "";
    dynamic var name:String = "";
    
    dynamic var latitude:Double = 0;
    dynamic var longitude:Double = 0;
    
    dynamic var address:String = "";
    dynamic var imageUrl:String = "";
    dynamic var distance:Int = 0;
    dynamic var venueType:Int = 0;
    var coordinate:CLLocation {
        return CLLocation(latitude: Double(latitude), longitude: Double(longitude));
    }
    
    override static func primaryKey() -> String?
    {
        return "id";
    }
}

