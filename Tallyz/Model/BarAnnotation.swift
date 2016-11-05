//
//  BarAnnotation.swift
//  Tallyz
//
//  Created by LionKing on 7/25/16.
//  Copyright © 2016 bigcity. All rights reserved.
//

import Foundation
import MapKit

class BarAnnotation: NSObject, MKAnnotation
{
    let title:String?;
    let subtitle:String?;
    let iconUrl:String;
    let coordinate: CLLocationCoordinate2D;
    
    init(title: String?, subtitle:String?, coordinate: CLLocationCoordinate2D, iconUrl:String)
    {
        self.title = title;
        self.subtitle = subtitle;
        self.coordinate = coordinate;
        self.iconUrl = iconUrl;
        
        super.init();
    }
}
