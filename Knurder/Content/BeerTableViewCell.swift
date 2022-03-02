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
    didSet {
      //print("BeerTableViewCell didSet{)")
      guard let saucerItem = saucerItem else {return}
      //print("BeerTableViewCell didSet()")
      beerName.text = saucerItem.name
      beerStyle.text = saucerItem.style
      beerPrice.text = saucerItem.glass_price
      // TODO: manage image views
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
    //print("BeerTableViewCell awake")
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    //super.setSelected(selected, animated: animated)
    //print("BeerTableViewCell setSelected")
    //print("use brewController \(brewController)")
    // Configure the view for the selected state
  }

}


