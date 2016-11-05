//
//  BarDetailViewController.swift
//  Tallyz
//
//  Created by LionKing on 7/26/16.
//  Copyright © 2016 bigcity. All rights reserved.
//

import UIKit
import QuadratTouch
import Firebase

class BarDetailViewController: ThemeCustomViewController, UIPageViewControllerDataSource {

    var venueID:String=""
    var venueName:String=""
    var pageImages:NSMutableArray = []
    var pageViewController:UIPageViewController!
    let ref = Firebase(url: "https://tallyz-e2313.firebaseio.com/venue-items")
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var infoView: UIView!
    
    @IBOutlet weak var maleCountLabel: UILabel!
    
    @IBOutlet weak var femaleCountLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = venueName
        getBarPhoto(venueID)
        getCheckInInfo(venueID)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getBarPhoto(venueId:String) {
      
        if let session = BarAPI.sharedInstance.session {
            let parameters = ["limit":"5"];
            
            let photoTask = session.venues.photos(venueId, parameters:parameters )
                {
                    (result) -> Void in
                  
                    if let response = result.response {
                        if let photos = response["photos"] as? [String: AnyObject]
                        {
                            if let items = photos["items"] as? [[String:AnyObject]] {
                                 for photo:[String: AnyObject] in items
                                 {
                                    let imgURL:String = photo["prefix"] as! String+"original"+(photo["suffix"] as! String)
                                    self.pageImages.addObject(imgURL)
                                    NSLog("%@",imgURL)
                                    
                                }
                            }
                        }
                        if (self.pageImages.count > 0) {
                            self.pageViewController = self.storyboard?.instantiateViewControllerWithIdentifier("MyPageViewController") as! UIPageViewController
                            self.pageViewController.dataSource = self

                            let initialVC = self.pageAtIndex(0)! as PageContentViewController
                            let viewControllers = NSArray(object: initialVC)
                            self.pageViewController.setViewControllers(viewControllers as? [UIViewController], direction: .Forward, animated: true, completion: nil)
                            
                           // self.pageViewController.view.frame = CGRectMake(50, 50, self.view.frame.size.width-50, self.view.frame.size.height/2-50)
                            self.pageViewController.view.frame = self.imageView.frame
                            self.addChildViewController(self.pageViewController)
                            self.view.addSubview(self.pageViewController.view)
                            self.pageViewController.didMoveToParentViewController(self)

                        }
                    }
                   
            }
            
            photoTask.start()
        }
        
    }
    
    func getCheckInInfo(venueID:String) {
        
        ref.childByAppendingPath(venueID).observeSingleEventOfType(.Value, withBlock: { snap in
            if snap.value is NSNull {
                // The value is null
                // Create the venue item from the struct
                self.maleCountLabel.text = "Male " + "0"
                self.femaleCountLabel.text = "Female " + "0"
            }
            else {
                let venueItem = VenueItem(snapshot: snap)
                
                self.maleCountLabel.text = "Male " + String(venueItem.maleCount)
                self.femaleCountLabel.text = "Female " + String(venueItem.femaleCount)
            }
           
        })

    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    func pageAtIndex(index:Int)->PageContentViewController?
    {
        if self.pageImages.count == 0 || index >= self.pageImages.count
        {
            return nil
        }
        
        let pageVC = self.storyboard?.instantiateViewControllerWithIdentifier("PageContentViewController") as! PageContentViewController
        pageVC.imageFileUrl = pageImages[index] as! String
        pageVC.pageIndex = index
        print(index)
        return pageVC
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController?
    {
        let pageVC = viewController as! PageContentViewController
        var index = pageVC.pageIndex as Int
        if (index == 0 || index == NSNotFound)
        {
            return nil
        }
        index--
        NSLog("before - %d", index)
        return self.pageAtIndex(index)
    }
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController?
    {
        let pageVC = viewController as! PageContentViewController
        var index = pageVC.pageIndex as Int
        if (index == NSNotFound)
        {
            return nil
        }
        index++
        
        if (index == pageImages.count)
        {
            return nil
        }
          NSLog("after - %d", index)
        return self.pageAtIndex(index)

    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int
    {
        return pageImages.count
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int
    {
        return 0
    }

}
