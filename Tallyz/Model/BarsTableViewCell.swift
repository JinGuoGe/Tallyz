//
//  BarsTableViewCell.swift
//  Tallyz
//
//  Created by LionKing on 7/25/16.
//  Copyright © 2016 bigcity. All rights reserved.
//

import UIKit

class BarsTableViewCell: UITableViewCell {

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var barPicture: UIImageView!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var button: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
