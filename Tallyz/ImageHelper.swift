//
//  ImageHelper.swift
//  Tallyz
//
//  Created by LionKing on 7/25/16.
//  Copyright © 2016 bigcity. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class ImageHelper
{
    static func loadImageFromUrl(url: String, view: UIImageView){
        
        // Create Url from string
        let url = NSURL(string: url)!
   
        
        // Download task:
        // - sharedSession = global NSURLCache, NSHTTPCookieStorage and NSURLCredentialStorage objects.
        let task = NSURLSession.sharedSession().dataTaskWithURL(url) { (responseData, responseUrl, error) -> Void in
            // if responseData is not null...
            if let data = responseData{
                
                // execute in UI thread
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    view.image = UIImage(data: data)
                })
            }
       
        }
        
        // Run task
        task.resume()
    }
    static func makeRoundedImage(image: UIImage, radius: Float) -> UIImage {
        let imageView: UIImageView = UIImageView(image: image)
        var layer: CALayer = CALayer()
        layer = imageView.layer
        
        layer.masksToBounds = true
        layer.cornerRadius = CGFloat(radius)
        layer.backgroundColor =  UIColor(red: CGFloat((0x33a2f3 & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((0x33a2f3 & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(0x33a2f3 & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)).CGColor
        

        
        UIGraphicsBeginImageContext(imageView.bounds.size)
        layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return roundedImage
    }

    static func loadPinImageFromUrl(url: String, view: MKAnnotationView){
        
        // Create Url from string
        let url = NSURL(string: url)!
        
        
        // Download task:
        // - sharedSession = global NSURLCache, NSHTTPCookieStorage and NSURLCredentialStorage objects.
        let task = NSURLSession.sharedSession().dataTaskWithURL(url) { (responseData, responseUrl, error) -> Void in
            // if responseData is not null...
            if let data = responseData{
                
                // execute in UI thread
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    view.image = self.makeRoundedImage( UIImage(data: data)!, radius: 16)
                })
            }
            
        }
        
        // Run task
        task.resume()
    }


}

