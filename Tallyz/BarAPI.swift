//
//  BarAPI.swift
//  Tallyz
//
//  Created by LionKing on 7/25/16.
//  Copyright © 2016 bigcity. All rights reserved.
//

import Foundation
import QuadratTouch
import MapKit
import RealmSwift

struct API {
    struct notifications {
        static let venuesUpdated = "venues_updated";
    }
}

enum VenueType: Int {
    case Food = 0, Coffee, Nightlife
}

class BarAPI
{
    static let sharedInstance = BarAPI();
    
    var session:Session?;
    
    init()
    {
        // Initialize the Foursquare client
        // Note: It's not recommended to put API secrets into public GitHub code. You can imagine the secrets below don't work, so get your own!
        
        /*let client = Client(clientID: "X4I3CFADAN4MEB2TEVYUZSQ4SHSTXSZL34VNP4CJHSJGLKPV", clientSecret: "EDOLJK3AGCOQDRKVT2GK5E4GECU42UJUCGGWLTUFNEF1ZXHB", redirectURL: "");*/
        
        let client = Client(clientID: "CMED20GNDBGVU4T0HQIEF41M0ZQS0MXIZUJ4ENIFX2SKZF2K", clientSecret: "M4OZVJKAHJPC4EKIQPB01YWFT2X0FGFY023JKV1W2XKYOVGR", redirectURL: "");
        
        
        let configuration = Configuration(client:client);
        Session.setupSharedSessionWithConfiguration(configuration);
        
        self.session = Session.sharedSession();
    }
    func getBarPhoto(venueId:String)->String {
       var photoUrl:String = "";
        if let session = self.session {
            let parameters = ["limit":"1"];
            
            let photoTask = session.venues.photos(venueId, parameters:parameters )
                {
                    (result) -> Void in
                    if let response = result.response {
                        if let photos = response["photos"]!["items"] as? [[String: AnyObject]]
                        {
                            
                        }
                    }
            }
            
            photoTask.start()
        }
       /* //https://api.foursquare.com/v2/venues/43695300f964a5208c291fe3/photos?limit=1&oauth_token=QBA5J4VLXKERV4MJZL5DUJSOD4X10SLSUKHHGZQCS1NLB20R&v=20160725
        let urlString = "https://api.foursquare.com/v2/venues/"+venueId+"/photos?limit=1&clientID=KGNYBGGEOPD5AH5YSEMKAML22BM4JPGGWSEAM2T1OBZ1C04R&clientSecret=Z0QQXMLPX0FDTL2U32KTW3VW35XYRIACT5OUVYQXMUUMYQQV&v=20160725"
        let url = NSURL(string: urlString)// Creating URL
        let request = NSURLRequest(URL: url!) // Creating Http Request
        let response: AutoreleasingUnsafeMutablePointer<NSURLResponse?>=nil
        // Sending Synchronous request using NSURLConnection
        do {
            let responseData = try NSURLConnection.sendSynchronousRequest(request, returningResponse: response) //Converting data to String
            if let jsonResult = try NSJSONSerialization.JSONObjectWithData(responseData, options: []) as? NSDictionary {
                if let responseDic  = jsonResult["response"]
                {
                    let photoDic = responseDic["photos"]
                    if let photos = responseDic["photos"]!["items"] as? [[String: AnyObject]]
                    {
                        return photos[0]["prefix"] as! String+"original"+(photos[0]["suffix"] as! String)
                    }
                }
                //print("Synchronous\(jsonResult)")
            }
        } catch (let e) {
            print(e)
            // You can handle error response here
        } */
        return ""
    }
    func getBarsWithLocation(location:CLLocation, venueType:VenueType = VenueType.Food)
    {
        if let session = self.session
        {  // Provide the user location and the hard-coded Foursquare category ID for "Coffeeshops, food, nightlife"
         
            var parameters = location.parameters();
            //parameters += [Parameter.categoryId: "4bf58dd8d48988d1e0931735,4d4b7105d754a06374d81259,4d4b7105d754a06376d81259"];
            
            switch venueType {
            case .Food:
               parameters += [Parameter.categoryId: "4d4b7105d754a06374d81259"];
            case .Coffee:
               parameters += [Parameter.categoryId: "4bf58dd8d48988d1e0931735"];
            case .Nightlife:
               parameters += [Parameter.categoryId: "4d4b7105d754a06376d81259"];
            }
            
            
            parameters += [Parameter.radius: "35000"];
            parameters += [Parameter.limit: "50"];
            
            // Start a "search", i.e. an async call to Foursquare that should return venue data
            let searchTask = session.venues.search(parameters)
                {
                    (result) -> Void in
                    
                    if let response = result.response
                    {
                        if let venues = response["venues"] as? [[String: AnyObject]]
                        {
                            autoreleasepool
                                {
                                    let realm = try! Realm(); // Note: no error handling
                                    realm.beginWrite();
                                    
                                    for venue:[String: AnyObject] in venues
                                    {
                                        let venueObject:Venue = Venue();
                                        
                                        if let id = venue["id"] as? String
                                        {
                                            venueObject.id = id;
                                        }
                                        
                                        if let name = venue["name"] as? String
                                        {
                                            venueObject.name = name;
                                        }
                                        
                                        if  let location = venue["location"] as? [String: AnyObject]
                                        {
                                            if let longitude = location["lng"] as? Double
                                            {
                                                venueObject.longitude = longitude;
                                            }
                                            
                                            if let latitude = location["lat"] as? Double
                                            {
                                                venueObject.latitude = latitude;
                                            }
                                            if let distance = location["distance"] as? Int
                                            {
                                                venueObject.distance = distance;
                                            }
                                            
                                            if let formattedAddress = location["formattedAddress"] as? [String]
                                            {
                                                venueObject.address = formattedAddress.joinWithSeparator(" ");
                                            }
                                            venueObject.venueType = venueType.rawValue
                                        }
                                        
                                       
                                        
                                        if let categories = venue["categories"] as? [[String: AnyObject]]
                                        {
                                            for category: [String: AnyObject] in categories {
                                                if let icon = category["icon"] as? [String: AnyObject] {
                                                    if let prefix = icon["prefix"] as? String {
                                                        if let suffix = icon["suffix"] as? String {
                                                            venueObject.imageUrl = prefix+"32"+suffix;
                                                        }
                                                    }
                                                }
                                            }
                                           
                                        }
                                        realm.add(venueObject, update: true);
                                    }
                                    
                                    do {
                                        try realm.commitWrite();
                                        print("Committing write...");
                                    }
                                    catch (let e)
                                    {
                                        print("Y U NO REALM ? \(e)");
                                    }
                            }
                            
                            NSNotificationCenter.defaultCenter().postNotificationName(API.notifications.venuesUpdated, object: nil, userInfo: nil);
                        }
                    }
            }
            
            searchTask.start()
        }
    }
}

extension CLLocation
{
    func parameters() -> Parameters
    {
        let ll      = "\(self.coordinate.latitude),\(self.coordinate.longitude)"
        let llAcc   = "\(self.horizontalAccuracy)"
        let alt     = "\(self.altitude)"
        let altAcc  = "\(self.verticalAccuracy)"
        let parameters = [
            Parameter.ll:ll,
            Parameter.llAcc:llAcc,
            Parameter.alt:alt,
            Parameter.altAcc:altAcc
        ]
        return parameters
    }
}
