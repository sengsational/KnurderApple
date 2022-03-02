//
//  KnurderViewController.swift
//  GRDBDemoiOS
//
//  Created by Dale Seng on 6/4/18.
//

import UIKit
import GRDB

private let reuseIdentifier = "BeerTableViewCell"

class KnurderViewController: UITableViewController {

  @IBOutlet weak var itemTableViewCell: BeerTableViewCell!
  @IBOutlet var searchFooter: SearchFooter!
  
  var brewController: FetchedRecordsController<SaucerItem>!
  let searchController = UISearchController(searchResultsController: nil)
  
  override func viewDidLoad() {
    super.viewDidLoad()
    print("CLASS NO LONGER IN USE")
    print("CLASS NO LONGER IN USE")
    print("CLASS NO LONGER IN USE")
    print("CLASS NO LONGER IN USE")
    print("CLASS NO LONGER IN USE")
    print("CLASS NO LONGER IN USE")
    print("CLASS NO LONGER IN USE")
    print("CLASS NO LONGER IN USE")
    print("CLASS NO LONGER IN USE")
    print("CLASS NO LONGER IN USE")
    print("CLASS NO LONGER IN USE")
    print("CLASS NO LONGER IN USE")
    print("CLASS NO LONGER IN USE")
    print("CLASS NO LONGER IN USE")
    print("CLASS NO LONGER IN USE")
    print("CLASS NO LONGER IN USE")
    print("CLASS NO LONGER IN USE")
    print("CLASS NO LONGER IN USE")
    print("CLASS NO LONGER IN USE")
    print("CLASS NO LONGER IN USE")
    let queryData = AppDelegate.getCurrentQuery()
    let sqlString = queryData[0]
    let arguments = queryData.dropFirst()
    
    print("about to run with \(sqlString) and \(arguments)")
    let brewsSortedByName = SaucerItem.order(Column("name").asc, Column("name"))
    brewController = try! FetchedRecordsController(dbQueue, request: brewsSortedByName)
    try! brewController.setRequest(sql: sqlString, arguments: StatementArguments(arguments), adapter: nil)
    try! brewController.performFetch()

    searchController.searchResultsUpdater = self as? UISearchResultsUpdating                    //tells you when text changes in the search bar
    searchController.obscuresBackgroundDuringPresentation = false   //we dont want the search controller to obscurre the view it's presented over
    searchController.searchBar.placeholder = "Search Candies"
    navigationItem.searchController = searchController              //the view controller has a provided navigationItem
    navigationItem.hidesSearchBarWhenScrolling = false
    definesPresentationContext = true                               //makes the search bar disappear if the user navigates away
    
    searchController.searchBar.isHidden = true
    
    tableView.tableFooterView = searchFooter

  
    let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress(_:)))
    tableView?.addGestureRecognizer(longPressRecognizer)
  }
  
  @IBAction func onBackClicked(_ sender: Any) {
    dismiss(animated: false, completion: nil)
  }
  
  @IBAction func onSearchIconClick(_ sender: Any) {
    searchController.searchBar.isHidden = !searchController.searchBar.isHidden
    if (searchController.searchBar.isHidden) {
      navigationItem.hidesSearchBarWhenScrolling = true
    } else {
      navigationItem.hidesSearchBarWhenScrolling = false
    }
  }
  
  // MARK: Private instance methods
  func searchBarIsEmpty() -> Bool {
    return searchController.searchBar.text?.isEmpty ?? true
  }
  
  func filterContentForSearchText(_ searchText: String) {
    print("TODO: implement search")
    //tableView.reloadData()
  }
  
  func isFiltering() -> Bool {
    let searchBarScopeIsFiltering = searchController.searchBar.selectedScopeButtonIndex != 0
    return searchController.isActive && (!searchBarIsEmpty() || searchBarScopeIsFiltering)
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if isFiltering() {
      print("Number of rows in section might need work.")
    } else {
      searchFooter.setNotFiltering()
    }
    return brewController.sections[section].numberOfRecords
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    //print("cellForRowAt dequeueReusable cell")
    if isFiltering() {
      
    }
    let cell = tableView.dequeueReusableCell(withIdentifier: "BeerTableViewCell", for: indexPath) as! BeerTableViewCell
    configure(cell, at: indexPath)
    return cell
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    print("Here we go to the detail screen, send along the brewController and the indexPath")
    guard let storyboard = storyboard, let controller = storyboard.instantiateViewController(withIdentifier: "DetailNavigationController") as? DetailNavigationController else {
      print("ERROR: didn't get the view controller we expected")
      return
    }

    print("KnurderViewControlelr initializing the newly created page view controller with index \(indexPath.row)")
    
    controller.beerIndexPath = indexPath
    controller.brewController = brewController
    controller.modalTransitionStyle = .flipHorizontal
    present(controller, animated: true, completion: nil)
  }
}

extension KnurderViewController {
  
  func updateSearchResults(for searchController: UISearchController) {
    filterContentForSearchText(searchController.searchBar.text!)
  }
  
  func configure(_ cell: BeerTableViewCell, at indexPath: IndexPath) {
    let saucerItem = brewController.record(at: indexPath)

    let abvText = SaucerItem.getAbvText(saucerItem.abv)
    if abvText.count > 0 {
      cell.beerStyle?.text = abvText + " - " + saucerItem.style!
    } else {
      cell.beerStyle?.text = saucerItem.style!
    }
    
    cell.beerName?.text = saucerItem.name
    cell.beerPrice?.text = ""
    cell.beerFlag.isHidden = (saucerItem.highlighted == "F" || saucerItem.highlighted == nil) ? true : false
  
    let tastedText = SaucerItem.getTastedText(saucerItem.created_date)
    let tasted = (tastedText.count == 0) ? false : true
    
    //CLASS NO LONGER IN USE
    if tasted {
      cell.beerName?.textColor = UIColor.darkGray
      cell.beerStyle?.textColor = UIColor.darkGray
    } else {
      cell.beerName?.textColor = UIColor.black
      cell.beerStyle?.textColor = UIColor.black
    }
    
    if saucerItem.new_arrival == "T" {
      cell.beerName.font = UIFont.boldSystemFont(ofSize: cell.beerName.font.pointSize)
    } else {
      cell.beerName.font = UIFont.systemFont(ofSize: cell.beerName.font.pointSize)
    }
    
  }
  
  @objc func longPress(_ gesture: UILongPressGestureRecognizer) {
    if gesture.state == UIGestureRecognizerState.began {
      // Get the indexPath for the long press item
      let point = gesture.location(in: tableView)
      let indexPath = tableView.indexPathForRow(at: point)
      // Get the table vew cell
      let cell = tableView.cellForRow(at: indexPath!) as! BeerTableViewCell
      // Get the database item supporting the cell
      let saucerItem = brewController.record(at: indexPath!)
      // Get the highlighted flag from the database (should be the same as the cell)
      let beerFlag = saucerItem.highlighted
      //print("beerFlag \(String(describing: beerFlag))")
      // Toggle the highlighted state
      let isHighlighted = (beerFlag == "T") ? false : true
      //print("isHighlighted \(isHighlighted)")
      // Change the state of the icon in the table view cell
      cell.beerFlag.isHidden = !isHighlighted
      // Change the state of the hightlighted variable in the database
      saucerItem.highlighted = isHighlighted ? "T" : "F"

      try! dbQueue.inDatabase { db in
        print("last inserted \(db.lastInsertedRowID)")
        try saucerItem.update(db)
        print("last inserted \(db.lastInsertedRowID)")
      //  try saucerItem.save(db)
      }
    }
  }

}
