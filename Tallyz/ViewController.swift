//
//  ViewController.swift
//  CheckInBar
//
//  Created by LionKing on 7/18/16.
//  Copyright © 2016 bigcity. All rights reserved.
//

import UIKit
import MapKit
import RealmSwift
import Firebase

class ViewController: ThemeCustomViewController, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate
{
    
    /// Outlet for the map view (top)
    @IBOutlet var mapView:MKMapView?;
    
    /// Outlet for the table view (bottom)
    @IBOutlet var tableView:UITableView?;
    
    /// Location manager to get the user's location
    var locationManager:CLLocationManager?;
    
  
    @IBOutlet weak var categoryView: UIView!
    /// Convenient property to remember the last location
    var lastLocation:CLLocation?;
    var m_myLocation:CLLocation?;
    var lastSearchedLocation:CLLocation?
    var lastVenueLocation:CLLocation?
    /// Stores venues from Realm, as a non-lazy list
    var venues:[Venue]?;

    /// Span in meters for map view and data filtering
    let distanceSpan:Double = 35000*0.5
    let mapViewSpan:Double = 1000
    var checkInStatus:Bool = false
    var checkInVenueID:String = ""
    var lastCategory = VenueType.Food;
    var bInitializedMap:Bool = false
    
    let ref = Firebase(url: "https://tallyz-e2313.firebaseio.com/venue-items")
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        lastSearchedLocation = nil
         NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("onVenuesUpdated:"), name: API.notifications.venuesUpdated, object: nil);
         self.title = "Food & Drinks"
         tableView!.registerNib(UINib(nibName: "BarsTableViewCell", bundle: nil), forCellReuseIdentifier: "BarCell")
        mapView?.zoomEnabled = true
        mapView?.showsUserLocation = true
        
        let defaults = NSUserDefaults.standardUserDefaults()
        let sex = defaults.stringForKey("sex")
        if (sex == "male") {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.gender = 0;
        }
        else if (sex == "female") {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.gender = 1;
        }
        else {
             self.performSegueWithIdentifier("MainViewToSettingView", sender: self)
        }
        
       
    }
    
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated);
        categoryView.backgroundColor =  self.UIColorFromRGB(0x46abf5);
       
        
        self.navigationController?.navigationBarHidden = false
        if let tableView = self.tableView
        {
            tableView.delegate = self;
            tableView.dataSource = self;
        }
        
        if let mapView = self.mapView
        {
            mapView.delegate = self;
        }
    }
    
    override func viewDidAppear(animated: Bool)
    {
        if locationManager == nil
        {
            locationManager = CLLocationManager();
            
            locationManager!.delegate = self;
            locationManager!.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
            locationManager!.requestAlwaysAuthorization();
            //locationManager!.distanceFilter = 50; // Don't send location updates with a distance smaller than 50 meters between them
            locationManager!.distanceFilter = kCLLocationAccuracyBest;
            locationManager!.startUpdatingLocation();
        }
    }
    
    func refreshVenues(location: CLLocation?, getDataFromFoursquare:Bool = false)
    {
        // If location isn't nil, set it as the last location
        if location != nil
        {
            lastLocation = location;
        }
        
        // If the last location isn't nil, i.e. if a lastLocation was set OR parameter location wasn't nil
        if let location = lastLocation
        {
            // Make a call to Foursquare to get data
            if getDataFromFoursquare == true
            {
                BarAPI.sharedInstance.getBarsWithLocation(location, venueType: lastCategory);
            }
            
            // Convenience method to calculate the top-left and bottom-right GPS coordinates based on region (defined with distanceSpan)
            let (start, stop) = calculateCoordinatesWithRegion(location);
            
            // Set up a predicate that ensures the fetched venues are within the region
            let predicate = NSPredicate(format: "latitude < %f AND latitude > %f AND longitude > %f AND longitude < %f AND venueType == %d", start.latitude, stop.latitude, start.longitude, stop.longitude, lastCategory.rawValue );
            
            // Initialize Realm (while supressing error handling)
            let realm = try! Realm();
            
            // Get the venues from Realm. Note that the "sort" isn't part of Realm, it's Swift, and it defeats Realm's lazy loading nature!
            venues = realm.objects(Venue).filter(predicate).sort {
                location.distanceFromLocation($0.coordinate) < location.distanceFromLocation($1.coordinate);
            };
            
            // Throw the found venues on the map kit as annotations
            for venue in venues!
            {
                let annotation = BarAnnotation(title: venue.name, subtitle: venue.address, coordinate: CLLocationCoordinate2D(latitude: Double(venue.latitude), longitude: Double(venue.longitude)), iconUrl: venue.imageUrl);
                
                mapView?.addAnnotation(annotation);
            }
            
            // RELOAD ALL THE DATAS !!!
            tableView?.reloadData();
        }
    }

    
    func calculateCoordinatesWithRegion(location:CLLocation) -> (CLLocationCoordinate2D, CLLocationCoordinate2D)
    {
        let region = MKCoordinateRegionMakeWithDistance(location.coordinate, distanceSpan, distanceSpan);
        
        var start:CLLocationCoordinate2D = CLLocationCoordinate2D();
        var stop:CLLocationCoordinate2D = CLLocationCoordinate2D();
        
        start.latitude  = region.center.latitude  + (region.span.latitudeDelta  / 2.0);
        start.longitude = region.center.longitude - (region.span.longitudeDelta / 2.0);
        stop.latitude   = region.center.latitude  - (region.span.latitudeDelta  / 2.0);
        stop.longitude  = region.center.longitude + (region.span.longitudeDelta / 2.0);
        
        return (start, stop);
    }
    
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation)
    {
        if let mapView = self.mapView
        {
            // setRegion sets both the center coordinate, and the "zoom level"
            if (self.bInitializedMap == false) {
                self.bInitializedMap = true
                let region = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, mapViewSpan, mapViewSpan);
                mapView.setRegion(region, animated: true);
            }
            
            m_myLocation = newLocation
            // When a new location update comes in, reload from Realm and from Foursquare
            if checkInStatus == false {
               mornitorComeInToVenue(m_myLocation!, delta: 6.0)
            }
            else {
                mornitorComeOutFromVenue(m_myLocation!, delta: 8.0)
            }
            
            if (lastSearchedLocation == nil) {
                refreshVenues(newLocation, getDataFromFoursquare: true);
                lastSearchedLocation = newLocation
            }
            else {
                let distance:Double = newLocation.distanceFromLocation(lastSearchedLocation!)
               
                if (distance < 20) {
                     refreshVenues(newLocation);
                }
                else {
                    refreshVenues(newLocation, getDataFromFoursquare: true);
                    lastSearchedLocation = newLocation
                }
            }
            
           
        }
    }
    
    func mornitorComeOutFromVenue(checkLocation: CLLocation,delta:Double) {
        let distance:Double = checkLocation.distanceFromLocation(lastVenueLocation!)
        if (distance>delta){
            registerComeOut(self.checkInVenueID)
        }
        
    }

    func mornitorComeInToVenue(checkLocation: CLLocation,delta:Double) {
        let nearestVenuID:String = self.getNearestVenueFromLocation(checkLocation, delta: delta)
        if (nearestVenuID  != "") {
            registerComeIn(nearestVenuID)
        }
        
    }
    
    func registerComeIn(venueID:String) {
        
        ref.childByAppendingPath(venueID).observeSingleEventOfType(.Value, withBlock: { snap in
            if snap.value is NSNull {
                // The value is null
                // Create the venue item from the struct
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                var venueItem:VenueItem?
                if (appDelegate.gender == 0)
                {
                    venueItem = VenueItem(venueID: venueID, maleCount: 1, femaleCount: 0)
                }
                else {
                    venueItem = VenueItem(venueID: venueID, maleCount: 0, femaleCount: 1)
                }
                // Create a child id from the item's name as a lowercase string
                let venueItemRef = self.ref.childByAppendingPath(venueID)
                
                // Save the grocery items in its AnyObject form
                venueItemRef.setValue(venueItem!.toAnyObject())
            }
            else {
                var venueItem = VenueItem(snapshot: snap)
                let venueItemRef = self.ref.childByAppendingPath(venueID)
                
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                
                if (appDelegate.gender == 0) {
                    venueItem.maleCount = venueItem.maleCount + 1
                }
                else {
                   venueItem.femaleCount = venueItem.femaleCount + 1
                }
                
                venueItemRef.updateChildValues(venueItem.toAnyObject() as! [NSObject : AnyObject])
            }
            self.checkInStatus = true
            self.checkInVenueID = venueID
        })
    }
    func registerComeOut(venueID:String) {
        
        ref.childByAppendingPath(venueID).observeSingleEventOfType(.Value, withBlock: { snap in
            if snap.value is NSNull {
                
            }
            else {
                var venueItem = VenueItem(snapshot: snap)
                let venueItemRef = self.ref.childByAppendingPath(venueID)
                
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                
                if (appDelegate.gender == 0) {
                     venueItem.maleCount = venueItem.maleCount - 1
                }
                else {
                     venueItem.femaleCount = venueItem.femaleCount - 1
                }
               
                venueItemRef.updateChildValues(venueItem.toAnyObject() as! [NSObject : AnyObject])
            }
            self.checkInStatus = false
            self.checkInVenueID = ""
        })
    }

    func getNearestVenueFromLocation(checkLocation: CLLocation,delta:Double) -> String {
        var venueID:String=""
        var vDelta:Double = delta
        if (venues == nil) {
            return venueID
            
        }
        for venue in venues!
        {
            let venueLocation = CLLocation(latitude: venue.latitude, longitude: venue.longitude)
            let distance:Double = checkLocation.distanceFromLocation(venueLocation)
            // If distance between my position and venue position is in delta range, then assume i'm in that venue.
            if (distance < vDelta) {
               venueID = venue.id
               vDelta = distance
               lastVenueLocation = venueLocation
            }
        }
        return venueID
    }
    func onVenuesUpdated(notification:NSNotification)
    {
        // When new data from Foursquare comes in, reload from local Realm
        refreshVenues(nil);
    }

    @IBAction func onCoffeeSelected(sender: AnyObject) {
        mapView?.removeAnnotations((mapView?.annotations)!)
        lastCategory = VenueType.Coffee;
        refreshVenues(nil, getDataFromFoursquare: true)
    }
    @IBAction func onFoodSelected(sender: AnyObject) {
        mapView?.removeAnnotations((mapView?.annotations)!)
        lastCategory = VenueType.Food;
        refreshVenues(nil, getDataFromFoursquare: true)
    }
    @IBAction func onNightlifeSelected(sender: AnyObject) {
        mapView?.removeAnnotations((mapView?.annotations)!)
        lastCategory = VenueType.Nightlife;
        refreshVenues(nil, getDataFromFoursquare: true)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // When venues is nil, this will return 0 (nil-coalescing operator ??)
         return venues?.count ?? 0;
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1;
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60;
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
       /* var cell = tableView.dequeueReusableCellWithIdentifier("BarCell") as! BarsTableViewCell!
        if cell == nil {
            cell = BarsTableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "BarCell")
        }*/

        let cell = tableView.dequeueReusableCellWithIdentifier("BarCell", forIndexPath: indexPath) as! BarsTableViewCell
        if let venue = venues?[indexPath.row]
        {
            cell.name?.text = venue.name;
            cell.address?.text = venue.address;
           
            if (venue.distance >= 1000) {
                cell.distance?.text =  (String(0.621371*Float(venue.distance)/1000) as NSString).substringWithRange(NSRange(location: 0, length: 3))+" mi";
            }
            else {
                cell.distance?.text =  String(venue.distance)+" m";
            }
            
            // Create Url from string
            let url = NSURL(string: venue.imageUrl)!
            
            
            // Download task:
            // - sharedSession = global NSURLCache, NSHTTPCookieStorage and NSURLCredentialStorage objects.
            let task = NSURLSession.sharedSession().dataTaskWithURL(url) { (responseData, responseUrl, error) -> Void in
                // if responseData is not null...
                if let data = responseData{
                    
                    // execute in UI thread
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        cell.barPicture.image = UIImage(data: data)
                        cell.layoutSubviews()
                    })
                }
                
            }
            
            // Run task
            task.resume()

            //ImageHelper.loadImageFromUrl(venue.imageUrl, view: cell.barPicture!)
          
        
        }
        
       
        return cell;
    }
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        if annotation.isKindOfClass(MKUserLocation)
        {
            return nil;
        }
        
        var view = mapView.dequeueReusableAnnotationViewWithIdentifier("customPin");
        
        if view == nil
        {
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: "customPin");
            
            // Resize image
           // let pinImage = UIImage(named: "marker")
           /* let size = CGSize(width: 15, height: 30)
            UIGraphicsBeginImageContext(size)
            pinImage!.drawInRect(CGRectMake(0, 0, size.width, size.height))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()*/
        
            //view?.image = pinImage
           
            
        }
        let barAnnotation  = annotation as! BarAnnotation
        
        ImageHelper.loadPinImageFromUrl(barAnnotation.iconUrl, view: view!)
        view?.canShowCallout = true;

        
        return view;
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        // When the user taps a table view cell, attempt to pan to the pin in the map view
      
        if let venue = venues?[indexPath.row]
        {
            let region = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2D(latitude: Double(venue.latitude), longitude: Double(venue.longitude)), mapViewSpan, mapViewSpan);
            mapView?.setRegion(region, animated: true);
            UIPasteboard.generalPasteboard().string = venue.address;
        }
       self.performSegueWithIdentifier("MainViewToDetailView", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "MainViewToDetailView")
        {
            let indexPath:NSIndexPath = (self.tableView?.indexPathForSelectedRow)!
            let detailVC = segue.destinationViewController as! BarDetailViewController
            if let venue = venues?[indexPath.row]
            {
                detailVC.venueID = venue.id
                detailVC.venueName = venue.name
            
            }
        }
    }
    
       
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

