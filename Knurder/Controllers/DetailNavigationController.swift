//
//  DetailNavigationController.swift
//  Knurder
//
//  Created by Dale Seng on 7/6/18.
//  Copyright © 2018 Sengsational. All rights reserved.
//

import UIKit
import GRDB


class DetailNavigationController: UINavigationController {
  var brewController: FetchedRecordsController<SaucerItem>!
  var beerIndexPath: IndexPath!

  override func viewDidLoad() {
    super.viewDidLoad()
    /*
    print("DetailNavigationController vdl and index \(beerIndexPath.row)")
    guard let storyboard = storyboard, let controller = storyboard.instantiateViewController(withIdentifier: "ManagePageViewController") as? ManagePageViewController else {
      print("ERROR: didn't get the view controller we expected")
      return
    }
    print("controller in DetailNavigationController vdl: \(controller)")
 
    controller.beerIndexPath = beerIndexPath
    controller.brewController = brewController
    */
    
    AppDelegate.beerIndexPath = beerIndexPath
    AppDelegate.brewController = brewController
 }
}
