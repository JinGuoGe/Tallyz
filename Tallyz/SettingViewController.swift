//
//  SettingViewController.swift
//  Tallyz
//
//  Created by LionKing on 8/3/16.
//  Copyright © 2016 bigcity. All rights reserved.
//

import UIKit

class SettingViewController: UIViewController {

    @IBOutlet weak var maleButton: UIButton!
    @IBOutlet weak var femaleButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBarHidden = true
        maleButton.setImage(UIImage.init(named: "male-sel"), forState: .Selected)
        maleButton.setImage(UIImage.init(named: "male"), forState: .Normal)
        femaleButton.setImage(UIImage.init(named: "female-sel"), forState: .Selected)
        femaleButton.setImage(UIImage.init(named: "female"), forState: .Normal)
       
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func maleSelected(sender: AnyObject) {
        maleButton.setImage(UIImage.init(named: "male-sel"), forState: .Normal)
      
        femaleButton.setImage(UIImage.init(named: "female"), forState: .Normal)
    }

    @IBAction func femaleSelected(sender: AnyObject) {
        maleButton.setImage(UIImage.init(named: "male"), forState: .Normal)
       
        femaleButton.setImage(UIImage.init(named: "female-sel"), forState: .Normal)

    }
  
    @IBAction func femaleTouchedUp(sender: AnyObject) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.gender = 1;
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject("female", forKey: "sex")

       self.navigationController?.popViewControllerAnimated(true)
    }
    @IBAction func maleTouchedUp(sender: AnyObject) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.gender = 0;
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject("male", forKey: "sex")
         self.navigationController?.popViewControllerAnimated(true)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
