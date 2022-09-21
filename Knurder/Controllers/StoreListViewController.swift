//
//  PopOverViewController.swift
//  PopoverListTest
//
//  Created by Dale Seng on 6/8/18.
//  Copyright © 2018 Sengsational. All rights reserved.
//

import UIKit

class StoreListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  
  @IBOutlet weak var popupView: UIView!
  @IBOutlet weak var tableView: UITableView!
  
  weak var sender: ViewController!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.dataSource = self
    tableView.delegate = self
  }
  
  override func viewDidAppear(_ animated: Bool) {
    let firstRun = SharedPreferences.getString(PreferenceKeys.firstRunTutorialPref, "")
    if firstRun.count == 0 {
      SharedPreferences.putString(PreferenceKeys.firstRunTutorialPref, "F")
      let alertViewController = UIAlertController(title: "Welcome", message: "Welcome to Knurder!\nThis application connects to the Flying Saucer web site, and that's it.  I'm not trying to make money from this app, it's just for fun.  I hope you get some mileage out of it.  Pick your saucer and you're good to go.  Cheers!\n\nPS: Search for Knurder on Facebook if you want to connect.  It would be nice to have a beta tester :)", preferredStyle: .alert)
      let okAction = UIAlertAction.init(title: "OK", style: .default) { (action) -> Void in
        SharedPreferences.putString(PreferenceKeys.applicationAlertPref, "NEW USER")
      }
      alertViewController.addAction(okAction)
      present(alertViewController, animated: true, completion: nil)
    }
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return StoreNameHelper.stores.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    //print("tableView: \(tableView)")
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    cell.textLabel?.text = StoreNameHelper.stores[indexPath.row].name
    return cell
  }
  
  func myMethod(_ sender: ViewController) {
    self.sender = sender
  }
 
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let selectedItem = StoreNameHelper.stores[indexPath.row]
    
    print("1: \(SharedPreferences.getString(PreferenceKeys.storeNumberPref, "00000"))")
    print("2: \(selectedItem.number)")

    let isNewStore = SharedPreferences.getString(PreferenceKeys.storeNumberPref, "00000") != selectedItem.number
    
    if (isNewStore) {
      dismiss(animated: false, completion: {
        LoaderController.sharedInstance.showLoader(viewController: self.sender, title: "Please Wait", message: "Getting active beers from the UFO site")
        TransactionDriver.fetchActive(storeNumber: selectedItem.number, storeName: selectedItem.name, viewController: self.sender, clearLoader: true, waitUntilFinished: false)
      })
    } else {
      dismiss(animated: false, completion: nil)
      Toast.show(message: "Same Store!", controller: self.sender)
    }
  }
}
