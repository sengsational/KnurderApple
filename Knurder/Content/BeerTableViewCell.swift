//
//  BeerTableViewCell.swift
//  GRDBDemoiOS
//
//  Created by Dale Seng on 6/3/18.
//  Copyright © 2018 Gwendal Roué. All rights reserved.
//

import UIKit
import GRDB

class BeerTableViewCell: UITableViewCell {
  
  @IBOutlet weak var beerName: UILabel!
  @IBOutlet weak var beerStyle: UILabel!
  @IBOutlet weak var beerPrice: UILabel!
  @IBOutlet weak var beerFlag: UIImageView!
  @IBOutlet weak var beerGlass: UIImageView!
  @IBOutlet weak var beerAvailable: UIImageView!

  var saucerItem: SaucerItem? {
    // THIS METHOD APPEARS NOT TO RUN
    // See: MasterViewController.configure()
    didSet {
      print("BeerTableViewCell.didSet saucerItem << THIS IS NEVER CALLED")
      guard saucerItem != nil else {
        print("BeerTableViewCell didSet() with bad saucerItem")
        return
        
      }
      //beerName.text = saucerItem.name
      //beerStyle.text = saucerItem.style
      //beerPrice.text = saucerItem.glass_price
    }
  }

  /*
  var brewController: FetchedRecordsController<SaucerItem>! {
    didSet {
      guard let brewController = brewController else { return }
      //print("set brewController \(brewController)")
    }
  }
  */

  override func awakeFromNib() {
    super.awakeFromNib()
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    //super.setSelected(selected, animated: animated)
  }
}


