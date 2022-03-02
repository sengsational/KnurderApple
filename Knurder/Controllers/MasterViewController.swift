import UIKit
import GRDB

class MasterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  
  // MARK: - Properties
  @IBOutlet var tableView: UITableView!
  @IBOutlet var searchFooter: SearchFooter!
  
  let searchController = UISearchController(searchResultsController: nil)
  var brewController: FetchedRecordsController<SaucerItem>!
  var theSearchText: String = ""
  var theQueryText: String = ""
  
  let tastedDateDbFormatter = DateFormatter()
  let tastedDateOutputFormatter = DateFormatter()

  // MARK: - View Setup
  override func viewDidLoad() {
    super.viewDidLoad()
    fetchRecords()
    
    searchController.searchResultsUpdater = self                    //tells you when text changes in the search bar
    searchController.obscuresBackgroundDuringPresentation = false   //we dont want the search controller to obscurre the view it's presented over
    
    theQueryText = SharedPreferences.getQueryText()
    searchController.searchBar.placeholder = "Search " + theQueryText
    searchController.searchBar.barStyle = .black                    // makes the text come out white!!
    navigationItem.searchController = searchController              //the view controller has a provided navigationItem
    navigationItem.hidesSearchBarWhenScrolling = false
    definesPresentationContext = true                               //makes the search bar disappear if the user navigates away
    
    searchController.searchBar.isHidden = true
    searchFooter.setController(self)
    tableView.tableFooterView = searchFooter
    self.searchFooter.isHidden = false
    
    let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress(_:)))
    tableView?.addGestureRecognizer(longPressRecognizer)
    
    tastedDateDbFormatter.dateFormat = "yyyy MM dd"
    tastedDateOutputFormatter.dateFormat = "MMM dd, yyyy"
  }
  
  override func viewDidAppear(_ animated: Bool) {
    let visibleRows = tableView.indexPathsForVisibleRows
    for row in visibleRows! {
      let cell = tableView.cellForRow(at: row) as! BeerTableViewCell
      
      // Get the database item supporting the cell
      let saucerItem = brewController.record(at: row)
      
      // Get the highlighted flag from the database (should be the same as the cell)
      let dbHighlightedFlag = saucerItem.highlighted

      // Make a boolean
      let dbIsHighlighted = (dbHighlightedFlag == "T") ? true : false

      // Change the state of the icon in the table view cell
      cell.beerFlag.isHidden = !dbIsHighlighted

      
    }
    
    let shakerTutorial = SharedPreferences.getString(PreferenceKeys.shakerTutorialPref, "")
    if let rowCount = visibleRows?.count {
      if shakerTutorial.count == 0 && rowCount > 0 {
        SharedPreferences.putString(PreferenceKeys.shakerTutorialPref, "F")
        let alertViewController = UIAlertController(title: "Shake It!", message: "Here's the list you requested.  If you can't decide which beer to drink, just shake you phone and it will pick a random one for you!", preferredStyle: .alert)
        let okAction = UIAlertAction.init(title: "OK", style: .default) { (action) -> Void in
          //self.alertControllerActionString = "OK Welcome"
        }
        alertViewController.addAction(okAction)
        present(alertViewController, animated: true, completion: nil)
      }
    }
    
    self.becomeFirstResponder() // For shake gesture
    
  }
  
  override var canBecomeFirstResponder: Bool { // For shake gesture
    get {
      return true
    }
  }

  override func viewWillDisappear(_ animated: Bool) { // For shake gesture
    resignFirstResponder()
    super.viewWillDisappear(animated)
  }
  
  override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
    if motion == .motionShake {
      let recordCount = brewController.sections[0].numberOfRecords
      let randomNumber = Int(arc4random_uniform(UInt32(recordCount)))

      print("shake detected  with \(recordCount) records  in the list.  Randomly picked \(randomNumber) this time.")
      let indexPath = IndexPath(item: randomNumber, section: 0)
      goToDetail(indexPath)
    }
  }
  
  func fetchRecordsPreserveSearchText() {
    self.fetchRecords(searchText: self.theSearchText)
  }
  
  func fetchRecords(searchText: String = "") {
    self.theSearchText = searchText
    let queryData = AppDelegate.getCurrentQuery(searchText: searchText)
    let sqlString = queryData[0]
    let arguments = queryData.dropFirst()
    let queryInterfaceRequest = AppDelegate.getQueryInterfaceRequest()
    
    print("about to run with \(sqlString) and \(arguments)")
    brewController = try! FetchedRecordsController(dbQueue, request: queryInterfaceRequest)
    try! brewController.setRequest(sql: sqlString, arguments: StatementArguments(arguments), adapter: nil)
    try! brewController.performFetch()
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

  func filterContentForSearchText(_ searchText: String) {
    fetchRecords(searchText: searchText)
    self.theSearchText = searchText
    tableView.reloadData()
  }
  
  func reloadData() {
    tableView.reloadData()
  }
  
  func isFiltering() -> Bool {
    return true
    /*
    let searchBarIsEmpty = searchController.searchBar.text?.isEmpty ?? true
    let searchBarScopeIsFiltering = searchController.searchBar.selectedScopeButtonIndex != 0
    return searchController.isActive && (!searchBarIsEmpty || searchBarScopeIsFiltering)
     */
 }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  // MARK: - Table View
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let theCount = brewController.sections[section].numberOfRecords
    if isFiltering() {
      searchFooter.setIsFilteringToShow(itemCount: theCount, query: theQueryText, searchText: theSearchText)
      return theCount
    }
    searchFooter.setNotFiltering()
    return theCount
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "BeerTableViewCell", for: indexPath) as! BeerTableViewCell
    configure(cell, at: indexPath)
    if isFiltering() {
      self.searchFooter.isHidden = false
    } else {
      print("hiding footer")
      self.searchFooter.isHidden = true
    }
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    goToDetail(indexPath)
  }
  
  func goToDetail(_ indexPath: IndexPath) {
    guard let storyboard = storyboard, let controller = storyboard.instantiateViewController(withIdentifier: "DetailNavigationController") as? DetailNavigationController else {
      print("ERROR: didn't get the view controller we expected")
      return
    }
    
    controller.beerIndexPath = indexPath
    controller.brewController = brewController
    controller.modalTransitionStyle = .flipHorizontal
    present(controller, animated: true, completion: nil)
  }

  
  // MARK: - Segues NOT USED
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    print("prepare for segue has been disabled ")
    if segue.identifier == "showDetail" {
      if let indexPath = tableView.indexPathForSelectedRow {
        if isFiltering() {
          print("indexPath+ \(indexPath.row)")
        } else {
          print("indexPath- \(indexPath.row)")
        }
      }
    }
  }
}

extension MasterViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    filterContentForSearchText(searchController.searchBar.text!)
  }
  
  func configure(_ cell: BeerTableViewCell, at indexPath: IndexPath) {
    let saucerItem = brewController.record(at: indexPath)
    
    if !AppDelegate.currentQueryIsTasted() {
      let abvText = SaucerItem.getAbvText(saucerItem.abv)
      if abvText.count > 0 {
        cell.beerStyle?.text = abvText + " - " + saucerItem.style!
      } else {
        cell.beerStyle?.text = saucerItem.style!
      }
    } else { // If it's a tasted query, show the date, not the style
      if let tastedDateString = saucerItem.created_date { // yyyy MM dd
        if let tastedDate = tastedDateDbFormatter.date(from: tastedDateString) {
          cell.beerStyle?.text = tastedDateOutputFormatter.string(from: tastedDate)
        }
      }
    }
    
    cell.beerName?.text = saucerItem.name
    cell.beerPrice?.text = ""
    cell.beerFlag.isHidden = (saucerItem.highlighted == "F" || saucerItem.highlighted == nil) ? true : false
    // DRS 20181217 - Indicate beer unavailable
    cell.beerAvailable.isHidden = (saucerItem.active == "T" || saucerItem.active == nil) ? true : false
    
    let tastedText = SaucerItem.getTastedText(saucerItem.created_date)
    let tasted = (tastedText.count == 0) ? false : true
    
    if tasted {
      cell.beerName?.textColor = UIColor(named: "colorsetTastedText")
      cell.beerStyle?.textColor = UIColor(named: "colorsetTastedText")
    } else {
      cell.beerName?.textColor = UIColor(named: "colorsetUntastedText")
      cell.beerStyle?.textColor = UIColor(named: "colorsetUntastedText")
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
      
      // Get the table view cell
      let cell = tableView.cellForRow(at: indexPath!) as! BeerTableViewCell
      
      // Get the database item supporting the cell
      let saucerItem = brewController.record(at: indexPath!)
      
      // Get the highlighted flag from the database (should be the same as the cell)
      let beerFlag = saucerItem.highlighted
      
      // Toggle the highlighted state
      let isHighlighted = (beerFlag == "T") ? false : true

      // Change the state of the icon in the table view cell
      cell.beerFlag.isHidden = !isHighlighted

      // Change the state of the hightlighted variable in the database
      saucerItem.highlighted = isHighlighted ? "T" : "F"
      try! dbQueue.inDatabase { db in
        try saucerItem.update(db)
      }
    }
  }
}

