//
//  ManagePageViewController.swift
//  GRDBDemoiOS
//
//  Created by Dale Seng on 6/7/18.
//  Copyright © 2018 Gwendal Roué. All rights reserved.
//

import UIKit
import GRDB

class ManagePageViewController: UIPageViewController {
  
  var brewController: FetchedRecordsController<SaucerItem>!
  var currentIndexPath: IndexPath!
  //var currentIndex: Int!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let beerIndexPath = AppDelegate.beerIndexPath
    print("viewDidLoad ManagePageViewController \(String(describing: beerIndexPath))")
    
    if let beerIndexPath = beerIndexPath, let viewController = viewPhotoCommentController(beerIndexPath.row) {
      currentIndexPath = beerIndexPath
      print("viewController in ManagePageViewController vdl: \(viewController) with current index \(currentIndexPath.row)")
      if let brewController = AppDelegate.brewController {
        viewController.brewController = brewController
        self.brewController = brewController
      } else {
        print("ManagePageViewController viewDidLoad brewController.performFetch")
        let brewsSortedByName = SaucerItem.order(Column("name").asc, Column("name"))
        let brewController = try! FetchedRecordsController(dbQueue, request: brewsSortedByName)
        try! brewController.performFetch()
        viewController.brewController = brewController
        self.brewController = brewController
      }
      setViewControllers([viewController], direction: .forward, animated: false, completion: nil)
    }
    dataSource = self
  }

  @IBAction func onClickBack(_ sender: Any) {
      dismiss(animated: true, completion: nil)
  }
  
  @IBAction func onClickRate(_ sender: Any) {
    print("Rate button clicked")
    
    guard let storyboard = storyboard, let ratingsViewController = storyboard.instantiateViewController(withIdentifier: "RateViewController") as? RateViewController else {
      print("ERROR: didn't get the view controller we expected")
      return
    }

    ratingsViewController.saucerItem =  brewController.record(at: currentIndexPath)
    
    if let navigator = navigationController {
      navigator.pushViewController(ratingsViewController, animated: true)
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if (segue.identifier == "RatingsSegue") {
      print("This never runs")
    }
    print("This method doesn't get called")
  }
  
  func viewPhotoCommentController(_ index: Int) -> KnurderPageViewController? {
    guard let storyboard = storyboard, let page = storyboard.instantiateViewController(withIdentifier: "KnurderPageViewController") as? KnurderPageViewController else {
      print("ERROR: didn't get the view controller we expected")
      return nil
    }
    print("ManagePageViewController initializing the newly created page view controller with index \(index)")
    page.brewController = brewController
    page.beerIndexPath = IndexPath(item: index, section: 0)
    return page
  }

}

extension ManagePageViewController : UIPageViewControllerDataSource {
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    if let viewController = viewController as? KnurderPageViewController, let indexPath = viewController.beerIndexPath {
      let index = indexPath.row
      currentIndexPath = indexPath
      if index > 0 {
        print("Before beerName: \(viewController.beerName.text ?? "(undefined)")")
        print("Before index: \(viewController.beerIndexPath.row)")
        return viewPhotoCommentController(index - 1)

      }
      print("13452")
      return nil
    }
    print("4567809")
    return nil
  }
  
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    if let viewController = viewController as? KnurderPageViewController, let indexPath = viewController.beerIndexPath {
      let index = indexPath.row
      currentIndexPath = indexPath
      if (index + 1) < viewController.recordCount {
        print("After beerName: \(viewController.beerName.text ?? "(undefined)")")
        print("After index: \(viewController.beerIndexPath.row)")
        return viewPhotoCommentController(index + 1)

      }
      print("435909")
      return nil
    }
    print("4465256")
    return nil
  }
  

}
