//
//  SearchFooter.swift
//  Knurder
//
//  Created by Dale Seng on 5/30/18.
//  Copyright © 2018 Sengsational. All rights reserved.
//

import UIKit

class SearchFooter: UIView {
  
  @IBOutlet weak var label: UILabel!
  @IBOutlet weak var sortButton: UIButton!

  
  var controller: MasterViewController!
  
  @IBAction func actionSortButton(_ sender: Any) {
    print("sortButtonPressed")
    //if let controller = self.controller {
    //  controller.filterContentForSearchText("hops")
    //}
    let querySortOrder = SharedPreferences.getString(PreferenceKeys.lastQuerySortByPref, Constants.SORT_NAME)
    let querySortDirection = SharedPreferences.getString(PreferenceKeys.lastQuerySortDirection, Constants.SORT_ASC)

    let sortNameAction = UIAlertAction(title: "Sort by Name", style: .default) { (action) -> Void in
      if Constants.SORT_NAME == querySortOrder {
        self.flipAscDesc(querySortDirection)
      } else {
        SharedPreferences.putString(PreferenceKeys.lastQuerySortByPref, Constants.SORT_NAME)
        SharedPreferences.putString(PreferenceKeys.lastQuerySortDirection, Constants.SORT_ASC)
      }
      self.controller.fetchRecordsPreserveSearchText()
      self.controller.reloadData()
    }
    
    let sortStyleAction = UIAlertAction(title: "Sort by Style", style: .default) { (action) -> Void in
      if Constants.SORT_STYLE == querySortOrder {
        self.flipAscDesc(querySortDirection)
      } else {
        SharedPreferences.putString(PreferenceKeys.lastQuerySortByPref, Constants.SORT_STYLE)
        SharedPreferences.putString(PreferenceKeys.lastQuerySortDirection, Constants.SORT_ASC)
      }
      self.controller.fetchRecordsPreserveSearchText()
      self.controller.reloadData()
    }
    
    let sortAbvAction = UIAlertAction(title: "Sort by ABV", style: .default) { (action) -> Void in
      if Constants.SORT_ABV == querySortOrder {
        self.flipAscDesc(querySortDirection)
      } else {
        SharedPreferences.putString(PreferenceKeys.lastQuerySortByPref, Constants.SORT_ABV)
        SharedPreferences.putString(PreferenceKeys.lastQuerySortDirection, Constants.SORT_DESC)
      }
      self.controller.fetchRecordsPreserveSearchText()
      self.controller.reloadData()
    }
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
      //self.alertControllerActionString = "OK Welcome"
    }
    
    let sortAction = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    sortAction.addAction(sortNameAction)
    sortAction.addAction(sortStyleAction)
    sortAction.addAction(sortAbvAction)
    sortAction.addAction(cancelAction)
    
    sortAction.popoverPresentationController?.sourceView = self
    
    self.controller.present(sortAction, animated: true) {
      print("alert was presented")
    }
  }
  
  private func flipAscDesc(_ querySortDirection: String) {
    if querySortDirection == Constants.SORT_ASC {
      SharedPreferences.putString(PreferenceKeys.lastQuerySortDirection, Constants.SORT_DESC)
    } else {
      SharedPreferences.putString(PreferenceKeys.lastQuerySortDirection, Constants.SORT_ASC)
    }
  }
  
  override public init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }
  
  required public init?(coder: NSCoder) {
    super.init(coder: coder)
    configureView()
  }
  
  func setController(_ controller: MasterViewController) {
    self.controller = controller
  }
  
  func configureView() {
    //self.backgroundColor = UIColor.blue
    self.alpha = 0.0
    //sortView.alpha = 0.0
    
    // Configure label
    //label.textAlignment = .center
    //label.textColor = UIColor.white
    //addSubview(label)
  }
  
  override func draw(_ rect: CGRect) {
    //label.frame = self.bounds
  }
  
  //MARK: - Animation
  
  fileprivate func hideFooter() {
    UIView.animate(withDuration: 0.7) {[unowned self] in
      self.alpha = 0.0
    }
  }
  
  fileprivate func showFooter() {
    UIView.animate(withDuration: 0.7) {[unowned self] in
      self.alpha = 1.0
    }
  }
}

extension SearchFooter {
  //MARK: - Public API
  
  public func setNotFiltering() {
    label.text = ""
    hideFooter()
  }
  
  public func setIsFilteringToShow(itemCount: Int, query: String, searchText: String) {
    if (itemCount == 0) {
      if (searchText.count > 0) {
        label.text = "Nothing in '" + query + "' matched '" + searchText + "'"
      } else {
        label.text = "Nothing in '" + query + "'"
      }
      showFooter()
    } else {
      if (searchText.count > 0) {
        label.text = "\(itemCount) items in '" + query + "' matching '" + searchText + "'"
      } else {
        label.text = "\(itemCount) items in '" + query + "'"
      }
      showFooter()
    }
  }

}
