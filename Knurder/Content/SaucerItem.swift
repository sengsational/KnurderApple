//
//  SaucerItem.swift
//  FirstDb
//
//  Created by Dale Seng on 5/15/18.
//  Copyright © 2018 Sengsational. All rights reserved.
//

import Foundation
import GRDB

class SaucerItem: Record, CustomStringConvertible {
  
  // This must match the JSON name from the UFO web response
  init(nvpDictionary: [String: String]) {
    //print("initializing from a nvp string")
    defer {
      name = nvpDictionary["name"]
      store_id = nvpDictionary["store_id"]
      brew_id = nvpDictionary["brew_id"]
      brewer = nvpDictionary["brewer"]
      city = nvpDictionary["city"]
      country = nvpDictionary["country"]
      containerx = nvpDictionary["container"]
      style = nvpDictionary["style"]
      descriptionx = nvpDictionary["description"]
      stars = nvpDictionary["stars"]
      reviews = nvpDictionary["reviews"]
      created = nvpDictionary["created"]
      brew_plate = nvpDictionary["brew_plate"]
      user_plate = nvpDictionary["user_plate"]
      created = nvpDictionary["created"]
      
      user_review = nvpDictionary["review"]
      user_stars = nvpDictionary["user_star"]
      review_id = nvpDictionary["review_id"]
      timestamp = nvpDictionary["time_stamp"]
      
    }
    
    super.init()
  }

  // MARK: Record overrides
  override class var databaseTableName: String {
    return "ufo"
  }
  
  override class var databaseSelection: [SQLSelectable] {
    return [AllColumns(), Column.rowID]
  }
  
  required init(row: Row) {
    
    id = row["rowid"]
    //print("initializing from a row  and id was \(String(describing: id))")
    name = row["name"]
    store_id = row["store_id"]
    brew_id = row["brew_id"]
    brewer = row["brewer"]
    city = row["city"]
    is_local = row["is_local"]
    country = row["country"]
    containerx = row["containerx"]
    style = row["style"]
    descriptionx = row["descriptionx"]
    abv = row["abv"]
    stars = row["stars"]
    reviews = row["reviews"]
    created = row["created"]
    active = row["active"]
    tasted = row["tasted"]
    highlighted = row["highlighted"]
    created_date = row["created_date"]
    new_arrival = row["new_arrival"]
    is_import = row["is_import"]
    glass_size = row["glass_size"]
    glass_price = row["glass_price"]
    user_review = row["user_review"]
    user_stars = row["user_stars"]
    review_id = row["review_id"]
    review_flag = row["review_flag"]
    timestamp = row["timestamp"]
    untappd_beer = row["untappd_beer"]
    untappd_brewery = row["untappd_brewery"]
    que_stamp = row["que_stamp"]
    currently_queued = row["currently_queued"]
    super.init(row: row)
  }

  override func encode(to container: inout PersistenceContainer) {
    //print("in the encode funtion with id \(String(describing: id))")
      container["rowid"] = id
      container["name"] = name
      container["store_id"] = store_id
      container["brew_id"] = brew_id
      container["brewer"] = brewer
      container["city"] = city
      container["is_local"] = is_local
      container["country"] = country
      container["containerx"] = containerx
      container["style"] = style
      container["descriptionx"] = descriptionx
      container["abv"] = abv
      container["stars"] = stars
      container["reviews"] = reviews
      container["created"] = created
      container["active"] = active
      container["tasted"] = tasted
      container["highlighted"] = highlighted
      container["created_date"] = created_date
      container["new_arrival"] = new_arrival
      container["is_import"] = is_import
      container["glass_size"] = glass_size
      container["glass_price"] = glass_price
      container["user_review"] = user_review
      container["user_stars"] = user_stars
      container["review_id"] = review_id
      container["review_flag"] = review_flag
      container["timestamp"] = timestamp
      container["untappd_beer"] = untappd_beer
      container["untappd_brewery"] = untappd_brewery
      container["que_stamp"] = que_stamp
      container["currently_queued"] = currently_queued
  }

  override func didInsert(with rowID: Int64, for column: String?) {
    id = rowID
    //print("didInsert with row: \(rowID)")
  }
  
  public var id: Int64?              //automatically assigned by database
  
  var name: String? {                     //from web
    didSet(aValue) {
      guard let _name = name else {
        print("guard fired")
        return
      }
      self.name = _name.clean()
    }
    
    willSet(aValue) {
      //print("NAME: \(aValue ?? "")")
      if aValue!.range(of:"(CAN)") != nil || aValue!.range(of:"(BTL)") != nil {
        override_tap = true
      } else {
        override_tap = false
      }
      
      if aValue!.hasSuffix("Flight") {
        override_flight = true
        print("OVERRIDE FLIGHT!!   \(aValue ?? "")")
        self.style = "Flight"
      } else {
        override_flight = false
      }
      
      if aValue!.hasSuffix("Float") || aValue!.hasSuffix("-mosa") {
        override_mix = true
        //print("OVERRIDE MIX!!")
        self.style = "Mix"
      } else {
        override_mix = false
      }
      
    }
  }
  var store_id: String?    //from web
  var brew_id: String?     //from web
  var brewer: String?      //from web
  
  public var city: String? {                         //from web
    didSet(aValue) {
      if city == "null" || city == nil {
        city = ""
      } else {
        city = city!.trim()
        if city!.hasSuffix(".") || city!.hasSuffix(",") {
          city = city!.removeLast()
        }
        is_local = city
      }
    }
  }
  
  var is_local: String? {    //calculate from city
    didSet(aValue) {
      //print("isLocal didSet: \(isLocal)")
      guard let cityState = is_local else {
        is_local = "F"
        return
      }
      if store_id == nil {store_id = ""}
      //print("store_id: \(store_id)")
      var itemState = cityState.components(separatedBy: ",").last
      guard itemState != nil else {
        return
      }
      let states = StoreNameHelper.lookupStates(forNumber: store_id!)
      itemState = itemState!.trim()
      //print("itemState: \(itemState)")
      //print("states: \(states)")
      for state in states {
        //print("test: \(itemState) == \(state)")
        if (state == itemState) {
          //print("setting is local to true")
          is_local = "T"
          break
        }
        is_local = "F"
      }
    }
  }
  
  public var country: String? {                       //from web
    didSet(aValue) {
      guard let country = country else {
        return
      }
      let _country = country.trim()
      if _country == "United States" || _country == "UnitedStates" || _country == "USA" || _country == "None" {
        self.is_import = "F"
      } else {
        self.is_import = "T"
      }
    }
    
  }
  
  public var containerx: String? {   //from web but description could override
    didSet(aValue) {
      guard let container = containerx else {return}
      guard let override_tap = override_tap else {return}
      
      if override_tap && container == "draught" {
        self.containerx = "bottled"
      }
    }
  }
  
  public var style: String? {       //from web
    didSet(aValue) {
      //print("setting style")
      //guard let container = self.containerx else {return}
      //guard container != "draught" else {return}
      //print("container was not draught")
      if self.override_flight == nil {self.override_flight = false}
      if self.override_mix == nil {self.override_mix = false}
      //print("override_flight was \(override_flight) for \(self.name)")
      if override_flight! {
        self.style = "Flight"
        //print("setting style override: \(self.name ?? ("name not found")) override was: \(override_flight ?? false)")
      }
      if override_mix! {
        self.style = "Mix"
      }
    }
  }
  
  var descriptionx: String? {                //from web
    didSet(aValue) {
      
      guard let _desc = descriptionx else {
        print("guard fired")
        return
      }
      self.descriptionx = _desc.clean()
      //print("cleaned: \(self.descriptionx)")
      abv = descriptionx // pulls ABV out of description
      
    }
  }
  
  var user_review: String? {                //from web or from user entering it
    didSet(aValue) {
      guard let _review = user_review else {
        return
      }
      if _review == "null" { self.user_review = "" }
      else { self.user_review = _review.clean() }
    }
  }
  
  var user_stars: String? {                //from web
    didSet(aValue) {
      guard let _user_stars = user_stars else {
        return
      }
      if _user_stars == "null" { self.user_stars = "" }
      else { self.user_stars = _user_stars }
    }
  }
  
  var review_id: String? {                //from web
    didSet(aValue) {
      guard let _review_id = review_id else {
        return
      }
      if _review_id == "null" { self.review_id = "" }
      else { self.review_id = _review_id }
    }
  }
  
  var timestamp: String? {                //from web
    didSet(aValue) {
      guard let _timestamp = timestamp else {
        return
      }
      if _timestamp == "null" { self.timestamp = "" }
      else { self.timestamp = _timestamp }
    }
  }
  
  var abv: String? {        //calculated from description
    didSet(aValue) {
      guard let _desc = abv else {
        self.abv = aValue
        return
      }
      if (_desc.starts(with: "untappd")) {
        self.abv = _desc.getNumberStringFromString()
        //print("untappd found")
        return
        //print("abv [" + self.abv + "]")
      }
      self.abv = "0"
      let abvMatchArea = _desc.getMatchArea(match: "ABV", leftOffset: 16, rightOffset: 0)
      if !abvMatchArea.isEmpty {
        var lMatch = abvMatchArea.getMatchArea(match: "%", leftOffset: 8, rightOffset: 0)
        if lMatch.isEmpty {lMatch = abvMatchArea.getMatchArea(match: "PERCENT", leftOffset: 8, rightOffset: 0)}
        var anAbvNumber = "0"
        if !lMatch.isEmpty {
          anAbvNumber = lMatch.getNumberStringFromString()
        }
        if anAbvNumber == "0" {
          anAbvNumber = abvMatchArea.getNumberStringFromString()
        }

        //print("anAbvNumber: \(anAbvNumber) \(_desc)")
        self.abv = anAbvNumber
      }
      
      if self.abv == "0" && (_desc.hasSuffix("%") || _desc.hasSuffix("%.")) {
        let split = _desc.split(separator: " ")
        let lastWord = String(split.suffix(1).joined(separator: " "))
        self.abv = lastWord.getNumberStringFromString()
      }
      //print("var abv ran " + self.getBeerName())
    }
  }
  var stars: String?       //from web
  var reviews: String?     //from web
  
  var created: String? {     //from web
    didSet {
      guard let _created = created else {return}
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "MMM dd, yyyy"
      guard let date = dateFormatter.date(from: _created) else {return}
      dateFormatter.dateFormat = "yyyy MM dd"
      created_date = dateFormatter.string(from: date)
      
    }
  }
  
  var created_date: String? //calculated from created
  public var new_arrival: String? {
    willSet(aValue) {
      //print("created_date will set \(String(describing: aValue))")
    }
  } //added during database population
  var is_import: String?    //added during database population
  var active: String?      //added during database population
  var tasted: String?      //added during database population
  var store_name: String?         //<<added during database population
  var override_tap: Bool?         //<<added during database population
  var override_flight: Bool?      //<<added during database population
  var override_mix: Bool?         //<<added during database population
  var highlighted: String? //added by user
  var glass_size: String?   //added by menu scan process
  var glass_price: String?  //added by menu scan process
  var review_flag: String? //added during database population
  var untappd_beer: String?
  var untappd_brewery: String?
  var que_stamp: String?          //DRS20231121
  var currently_queued: String?   //DRS20231121

  var brew_plate: String? //not in the database
  var user_plate: String? //not in the database
  
  public var description: String {
    return "_id: \(id as Optional),name: \(name as Optional), store_id: \(store_id as Optional), brew_id: \(brew_id as Optional), brewer: \(brewer as Optional), city: \(city as Optional), isLocal: \(is_local as Optional), country: \(country as Optional), container: \(containerx as Optional), style: \(style as Optional), descript: \(descriptionx as Optional), abv: \(abv as Optional), stars: \(stars as Optional), reviews: \(reviews as Optional), created: \(created as Optional), createdDate: \(created_date as Optional), newArrival: \(new_arrival as Optional), isImport: \(is_import as Optional), active: \(active as Optional), tasted: \(tasted as Optional), store_name: \(store_name as Optional), override_tap: \(override_tap as Optional), override_flight: \(override_flight as Optional), overide_mix: \(override_mix as Optional), highlighted: \(highlighted as Optional), glassSize: \(glass_size as Optional), glassPrice: \(glass_price as Optional), userReview: \(user_review as Optional), userStars: \(user_stars as Optional), reviewId: \(review_id as Optional), reviewFlag: \(review_flag as Optional), timestamp: \(timestamp as Optional), untappd_beer: \(untappd_beer as Optional), untappd_brewery: \(untappd_brewery as Optional), que_stamp: \(que_stamp as Optional), currently_queued: \(currently_queued as Optional)"
  }
  
  // MARK - Derived outputs
  
  public func isOnCurrentPlate() -> Bool {
    if let user_plate = user_plate, let brew_plate = brew_plate, let currentPlate = Int(user_plate), let beerPlate = Int(brew_plate) {
      //print("currentPlate: \(beerPlate > currentPlate)")
      return beerPlate > currentPlate
    } else {
      //print("currentPlate: autotrue")
      return true
    }
  }
  
  /*
  public func getIdString() -> String {
    return String(describing: _id ?? -1)
  }
 */
  
  public func getCleanBrewer() -> String? {
    guard brewer != nil else {
      return nil
    }
    var cleanBrewer = brewer!
    for match in brewery_cleanup {
      if cleanBrewer.hasPrefix(match) {
        cleanBrewer = String(cleanBrewer.dropFirst(match.count))
        return cleanBrewer.trim()
      } else if cleanBrewer.range(of: match) != nil {
        let foundCrapRange = cleanBrewer.range(of: match)
        let notherRange = foundCrapRange!.lowerBound
        cleanBrewer = String(cleanBrewer.prefix(upTo: notherRange))
        return cleanBrewer.trim()
      }
      
    }
    return brewer
    
  }
  
  func getBeerName() -> String {
    var saucerName = "(undefined)"
    if let _saucerName = name {
      saucerName = _saucerName
    }
    return saucerName
  }
  
  func getBrewId() -> String {
    var saucerId = "000"
    if let _saucerId = brew_id {
      saucerId = _saucerId
    }
    return saucerId
  }
  
  func setAbvNumber(abvNumber: String) {
    self.abv = abvNumber
  }
  
  func getGlassName() -> String {
    var glassName = ""
    if let ounces = self.glass_size {
      switch ounces {
      case "16":
        glassName = "pint"
      case "13":
        fallthrough
      case "11.5":
        glassName = "snifter"
      case "10":
        fallthrough
      case "9":
        glassName = "wine"
      case "1":
        glassName = "stein"
      default:
        print("the beer " + self.getBeerName() + " had " + ounces + " unexpectedly")
          glassName = ""
      }
    }
    return glassName
  }
  
  let brewery_cleanup = ["Winery & Distillery","Beverage Associates","der Trappisten van","Brewing Company","Artisanal Ales","Hard Cider Co.","& Co. Brewing","Craft Brewery","Beer Company","Gosebrauerei","Brasserie d'","and Company","Cooperative","Brewing Co.","Brewing Co","& Son Co.","Brasserir","Brasserie","Brasseurs","Brau-haus","Brouwerji","Brauerei","BrewWorks","Breweries","Brouwerj","and Co.","Brewery","Brewing","Beer Co","Company","& Sohn","(Palm)","and Co","Cidery","& Sons","Beers","& Son","Ales","Brau","GmbH","Co.","Ltd","LTD","& co"]

  /*
  public func getRatingFormUrl() throws -> URL {
    if let review_id = self.review_id {
      if let url = URL(string: "https://www.beerknurd.com/note/" + review_id + "/edit") {
        return url
      }
    }
    throw SaucerUrlError.reviewIdNotFound
  }
  
  enum SaucerUrlError: Error {
    case reviewIdNotFound
  }
  */
  
  // MARK: Functions for loading from string
  
  public static func getNvpDictionary (_ rawInput: String) -> [String: String] {
    var rawInput = rawInput.deletePrefix("[{") //first item has this.  Remove it.
    rawInput = rawInput.wrapInQuotes("null")
    rawInput = rawInput.wrapStars()
    rawInput = rawInput.removeFirstAndLast()
    
    let nvpa = rawInput.components(separatedBy: "\",\"")
    var nvpDictionary = [String: String]()
  
    for nvpString in nvpa {
      let nvpItem = nvpString.components(separatedBy: "\":\"")
      if nvpItem.count < 2 {
        continue
      }
      nvpDictionary[nvpItem[0]] = nvpItem[1]
      //print("test: \(nvpItem[0]) - \(nvpItem[1])")
      
    }

    return nvpDictionary
  }
  
  static func loadOrUpdateDatabase(rawItem: String) {
    let nvps = SaucerItem.getNvpDictionary(rawItem)
    let oneItem = SaucerItem(nvpDictionary: nvps)
    print("oneItem: \(oneItem)\n")
    try! dbQueue.inDatabase { db in
      try oneItem.save(db)
    }
  }
  
  static func loadOrUpdateDatabase(rawItems: String, max: Int) {
    let items = rawItems.components(separatedBy: "},{")
    var localMax = max
    for item in items {
      if item.count < 10 {
          continue
      }
      print("attempting to load item [\(item)]")
      loadOrUpdateDatabase(rawItem: item)
      localMax = localMax - 1
      if localMax <= 0 {
        break
      }
    }
  }

  // DRS 20231121
  static func brewIdIsTasted(brewId: String) -> Bool {
    var successfulTransaction = "false"
    var isTasted = false
    do {
      try dbQueue.read({db in
        //try db.execute("select tasted from UFO where swhere brew_id ='" + brewId + "'")
        if let row = try Row.fetchOne(db, "SELECT tasted from UFO where brew_id = ?", arguments: [brewId]) {
          // -------- record exists -----------
          if "T" == row["tasted"] {
            isTasted = true
          }
        }
        successfulTransaction  = "true"
      })
      print("successful Transaction " + successfulTransaction)
    } catch {
        print("ERROR: brewIdIsTasted() database inquiry failed.")
    }
    print("brewIdIsTasted returning \(isTasted)")
    return isTasted
  }
  
  // DRS 20231121
  static func hasCurrentTimestamp(brewId: String) -> Bool {
    print("hasCurrentTimestamp(" + brewId + ")")
    var dbTimestampIsCurrent = false
    do {
      try _ = dbQueue.read({db in
        if let row = try Row.fetchOne(db, "SELECT * from UFO where brew_id = ?", arguments: [brewId]) {
          // -------- record exists -----------
          if let queueStamp: String = row["que_stamp"] { //2023 11 11 13 13
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy MM dd HH mm"
            if let startDate = dateFormatter.date(from: queueStamp) {
              let ageInSeconds = Date().timeIntervalSince(startDate);
              print(String(format: "ageInSeconds: %.0f", ageInSeconds))
              print(String(format: "fourhours: %.0f", Constants.FOUR_HOURS_IN_SECONDS))
              if (ageInSeconds > 0 && ageInSeconds < Constants.FOUR_HOURS_IN_SECONDS) {
                print("#Has current timestamp")
                dbTimestampIsCurrent = true
              } else {
                print("#Has older timestamp")
              }
            } else {
              print("Could not format date [" + queueStamp + "]")
            }
          } else {
            print("Has no timestamp")
          }
        } else {
          print("brewId " + brewId + " not found in the database")
        }
        return false
      })
    } catch {
        print("ERROR: brewIdIsTasted() database inquiry failed.")
    }
    print("returning \(dbTimestampIsCurrent) from hasCurrentTimestamp")
    return dbTimestampIsCurrent
  }
  
  // DRS 20231121
  static func setAllItemsToNotCurrentlyQueued() {
    var successfulTransaction = "false"
    do {
      try dbQueue.inDatabase({db in
        try db.execute("update UFO set currently_queued = 'F'")
        successfulTransaction  = "true"
      })
      print("resetQueued() successful Transaction " + successfulTransaction)
    } catch {
        print("ERROR: resetQueued() database activity failed.")
    }
  }

  // DRS 20231121
  static func resetQueuedDbUpdateNOTUSED(currentQueuedBeerIds: String) { //static function updating database - CALLED FROM SUB LIST PROCESS!
    var successfulTransaction = "false"
    do {
      try dbQueue.inDatabase({db in
        let queuedArray = currentQueuedBeerIds.components(separatedBy: ",")
        for brewId in queuedArray {
          let brewId = brewId.trim()
          try db.execute("update UFO set currently_queued = 'T' where brew_id = '" + brewId + "'")
        }
        successfulTransaction  = "true"
      })
      print("resetQueued() successful Transaction " + successfulTransaction)
    } catch {
        print("ERROR: resetQueued() database activity failed.")
    }
  }
  
  // DRS 20231128
  func setQueuedTimestamp() {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy MM dd HH mm"
    let nowString = dateFormatter.string(from: Date())
    self.que_stamp = nowString
    self.currently_queued = "T"
  }
  
  // DRS 20231121
  func getQueText() -> String {
    var returnQueText = ""
    if let que_stamp = que_stamp {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy MM dd HH mm"
      if let queueDate = dateFormatter.date(from: que_stamp) {
        let ageInSeconds = Date().timeIntervalSince(queueDate);
        if (ageInSeconds > 0 && ageInSeconds < Constants.FOUR_HOURS_IN_SECONDS) {
          print((name ?? "???") + " has current timestamp")
          if (tasted == "T") {
            returnQueText = "" // tasted beers never queued
          } else if let currently_queued = currently_queued {
            if currently_queued == "T" {
              returnQueText = "      [QUEUED]"
            } else {
              returnQueText = "      [APPLIED]"
            }
          }
        } else {
          //print((name ?? "???") + " has old timestamp")
          returnQueText = ""
        }
      }
    } else {
      //print("que_stamp was not populated for " + (name ?? "???"))
    }
    return returnQueText
  }

  static func refreshTastedList(rawItems: String) -> String { //static function updating database - Called before list is displayed - OK
    var updateCount = 0
    var insertCount = 0
    var successfulLoad = false
    let showOnlyCurrentTasted = SharedPreferences.getString(PreferenceKeys.currentPlatePref, PreferenceValues.booleanTrue)
    
    // #0 *** Sanity Check of rawItems
    let items = rawItems.components(separatedBy: "},{")
    guard items.count > 0 else {
      //print(rawItems)
      return "ERROR: There were too few items."
    }
  
    do {
      try dbQueue.inDatabase({db in
        // #1 *** Set active flag to not yet determined
        try db.execute("update UFO set TASTED = 'D'")
        
        // #2 *** Load tasted beers
        
        for item in items {
          if item.count < 10 {
            continue
          }
          let nvps = SaucerItem.getNvpDictionary(item)
          let webItemToSave = SaucerItem(nvpDictionary: nvps)
          //print("Working on \(webItemToSave.name) and it has review  \(webItemToSave.user_review)")
          //print("item \(item)")
          
          //let onCurrent = tastedItem.isOnCurrentPlate()
          //print("showOnlyCurrentTasted: \(showOnlyCurrentTasted) ??? \(PreferenceValues.booleanTrue) --- onCurrent \(onCurrent)")
          
          if (showOnlyCurrentTasted == PreferenceValues.booleanTrue) && (!webItemToSave.isOnCurrentPlate()) {
            continue
            
          } // Do no load tasted from earlier plates
          
          webItemToSave.tasted = "T"
          
          // Try to find a brewId in our database that matches the one from the JSON pulled off the user's web account
          if let brewId = webItemToSave.brew_id {
            if let row = try Row.fetchOne(db, "SELECT *, rowid from UFO where brew_id = ?", arguments: [brewId]) {
              // -------- record exists, update it -----------
              
              // create a SaucerItem that is what we already have in our database
              let databaseItem = SaucerItem.init(row: row)
              
              // Assign the rowid
              webItemToSave.id = databaseItem.id
              
              // Preserve highlighted
              if let highlighted = databaseItem.highlighted {
                if highlighted == "T" {
                  webItemToSave.highlighted = "T"
                } else if highlighted == "X" {
                  webItemToSave.highlighted = "X"
                } else {
                  webItemToSave.highlighted = "F"
                }
              } else {
                webItemToSave.highlighted = "F"
              }
              
              // Preserve city (doesn't show up well for some reason)
              if let city = databaseItem.city {
                webItemToSave.city = city
              }
              
              // Preserve brewer (doesn't show up well for some reason)
              if let brewer = databaseItem.brewer {
                webItemToSave.brewer = brewer
              }
              
              // Preserve active
              if let active = databaseItem.active {
                webItemToSave.active = active
              }
              
              // Preserve new arrival
              if let newArrival = databaseItem.new_arrival {
                webItemToSave.new_arrival = newArrival
              }
              
              // Preserve local review, but only if web review doesn't exist
              if let userReviewLocal = databaseItem.user_review {
                //print("0 review_flag started as \(String(describing: webItemToSave.review_flag))")
                if let userReviewWeb = webItemToSave.user_review {
                  let webReviewExists = !("null" == userReviewWeb) && !("" == userReviewWeb)
                  if webReviewExists {
                    webItemToSave.review_flag = "W" // W is for "Web"
                    //print("1 review_flag set to \(String(describing: webItemToSave.review_flag)) for \(webItemToSave.name ?? "(unknown)") Web Review existed.")
                  } else if "L" == databaseItem.review_flag {  // "L" for local, should have been set when user edited it on their phone
                    webItemToSave.user_review = userReviewLocal
                    webItemToSave.user_stars = databaseItem.user_stars
                    webItemToSave.review_flag = databaseItem.review_flag
                    //print("2 web review was blank and review_flag in our database was \(String(describing: webItemToSave.review_flag)) for \(webItemToSave.name ?? "(unknown)") Local Review Precided.")
                  } else {
                    //print("3 web review doesn't exist and review_flag not \"L\" in our database. User review web [\(String(describing: userReviewWeb))]")
                  }
                }
              }
              
              try webItemToSave.updateChanges(db)
              //print("tastedItem updated")
              updateCount += 1
            } else {
              // new record, just save it
              webItemToSave.active = "F"
              webItemToSave.highlighted = "F"
              webItemToSave.new_arrival = "F"
              //print("tastedItem: \(tastedItem)")
              try webItemToSave.save(db)
              //print("tastedItem saved")
              insertCount += 1
            }
          } else {
            print("could not look up \(webItemToSave.brew_id ?? "(no brew_id available)")")
          }
        } // END - for each raw item
        
        // #3 ** Manage Entries Not Just Refreshed
        
        successfulLoad = (insertCount + updateCount) > 0
        if (successfulLoad) {
          // if the beer wasn't just updated and it isn't tasted or highlighted, delete it.
          try db.execute("update UFO set TASTED = 'F' where TASTED = 'D' and ACTIVE = 'T'")
          try db.execute("update UFO set TASTED = 'F' where TASTED = 'D' and (HIGHLIGHTED='T' or HIGHLIGHTED='X')")
          try db.execute("delete from UFO where TASTED='D'")
        }
        let count = try SaucerItem.fetchCount(db)
        print("there were \(insertCount) new records and \(updateCount) updated records. The database has \(count) records.")
      })
      if successfulLoad {
        return ""
      } else {
        return "ERROR: Load not successful"
      }
      //} catch Exception.Error(let type, let msg) {
      //  print("error in the new arrival page \(msg) type: \(type)")
      //message = "error in the new arrival page: \(msg)"
      //
    } catch {
      print("ERROR: catch running in the loading of tasted beers")
      print("ERROR: Fell through. \(updateCount)\(insertCount)\(successfulLoad)")
      return "ERROR: catch block ran"
    }
    
    
    
  }
  
  static func refreshStoreList(rawItems: String, storeNumber: String, storeName: String) -> String { //static function updating database - Called before list is displayed - OK
    var updateCount = 0
    var insertCount = 0
    var successfulLoad = false

    // #0 *** Sanity Check of rawItems
    let items = rawItems.components(separatedBy: "},{")
    guard items.count > 20 else {
      return "ERROR: There were too few items."
    }
    
    do {
      try dbQueue.inDatabase({db in
        // #1 *** Set active flag to not yet determined
        try db.execute("update UFO set ACTIVE = 'D'")

        // #2 *** Load active beers
        
        for item in items {
          if item.count < 10 {
            continue
          }
          let nvps = SaucerItem.getNvpDictionary(item)
          let webItem = SaucerItem(nvpDictionary: nvps)
          webItem.active = "T"
          webItem.new_arrival = "F"
          
          if let brewId = webItem.brew_id {
            if let row = try Row.fetchOne(db, "SELECT *, rowid from UFO where brew_id = ?", arguments: [brewId]) {
              // -------- record exists, update it -----------
              
              let databaseItem = SaucerItem.init(row: row)
              //print("databaseItem \(databaseItem)")
              
              // Assign the rowid
              webItem.id = databaseItem.id
              
              // Preserve highlighted
              if let highlighted = databaseItem.highlighted {
                if highlighted == "T" {
                  webItem.highlighted = "T"
                } else if highlighted == "X" {
                  webItem.highlighted = "X"
                } else {
                  webItem.highlighted = "F"
                }
              } else {
                webItem.highlighted = "F"
              }
              
              // Preserve tasted
              if let tasted = databaseItem.tasted {
                if tasted == "T" {
                  webItem.tasted = "T"
                } else {
                  webItem.tasted = "F"
                }
              } else {
                webItem.tasted = "F"
              }
              
              try webItem.updateChanges(db)
              //print("webItem updated")
              updateCount += 1
            } else {
              // new record, just save it
              webItem.tasted = "F"
              webItem.highlighted = "F"
              webItem.new_arrival = "F"
              //print("webItem: \(webItem)")
              try webItem.save(db)
              //print("webItem saved")
              insertCount += 1
            }
          } else {
            print("could not look up \(webItem.brew_id ?? "(no brew_id available)")")
          }
        } // END - for each raw item
        
        // #3 ** Manage Entries Not Just Refreshed
        print("checking successfulLoad \(insertCount)  \(updateCount)")
        successfulLoad = (insertCount + updateCount) > 20
        if (successfulLoad) {
          // if the beer wasn't just updated and it isn't tasted or highlighted, delete it.
          try db.execute("update UFO set ACTIVE = 'F' where TASTED = 'T' and ACTIVE = 'D'")
          try db.execute("update UFO set ACTIVE = 'F' where (HIGHLIGHTED='T' or HIGHLIGHTED='X') and ACTIVE='D'")
          try db.execute("delete from UFO where ACTIVE='D'")
          
        }
        let count = try SaucerItem.fetchCount(db)
        print("there were \(insertCount) new records and \(updateCount) updated records. The database has \(count) records.")
      })
      if successfulLoad {
        return ""
      } else {
        return "ERROR: Load not successful"
      }
    //} catch Exception.Error(let type, let msg) {
    //  print("error in the new arrival page \(msg) type: \(type)")
      //message = "error in the new arrival page: \(msg)"
    } catch {
      print("ERROR: catch running in the loading of active beers")
      return "ERROR: catch block ran"
    }
  }
  
  static func refreshNewArrivals(newArrivalNames names: [String]) { //static function updating database - Called before list is displayed - OK

    do {
      try dbQueue.inDatabase({db in
        // #1 *** Clear new arrivals from database
        try db.execute("update UFO set NEW_ARRIVAL = 'F'")

        // #2 *** Update new arrivals using exact beer name
        for name: String in names {
          let name = name.replacingOccurrences(of: "'", with: " ").replacingOccurrences(of: "\"", with: " ").replacingOccurrences(of: "<", with: " ").replacingOccurrences(of: ">", with: " ")
          try db.execute("update UFO set NEW_ARRIVAL = 'T' where NAME = '\(name)'")
        }
      })
    } catch {
      print("ERROR: catch running in the loading of new arrivals")
    }
  }
  
  static func setItemAsReviewed(_ review_id: String?) { //static function updating database - Not sure about safety of this one
    do {
      try dbQueue.inDatabase({db in
        try db.execute("update UFO set REVIEW_FLAG = 'W' where REVIEW_ID = \(review_id ?? "99999999999999")")
      })
    } catch {
      print("ERROR: Unable to update the review_flag on review_id [\(review_id ?? "99999999999999")]")
    }
  }

  
  
  // MARK: Static convenience methods
  
  static func getAbvText(_ abv: String?) -> String {
    var beerAbvText = ""
    if let stringAbv = abv, let floatAbv = Float(stringAbv) {
      if floatAbv > 0 && floatAbv < 20 {
        beerAbvText = String(format: "%.1f", floatAbv) + "%"
      }
    }
    return beerAbvText
  }
  static func getPriceText(_ price: String?) -> String {
    var beerPriceText = ""
    if let stringPrice = price, let floatPrice = Float(stringPrice) {
      if floatPrice > 0 && floatPrice < 50 {
        beerPriceText = String(format: "$%.02f", floatPrice)
      }
    }
    return beerPriceText
  }
  
  static func getTastedText(_ created_date: String? ) -> String {
    var beerTastedDateText = ""
    if let createdDate = created_date, let date = AppDelegate.tastedDateFormatInput.date(from: createdDate) {
      beerTastedDateText = "Tasted " + AppDelegate.tastedDateFormatOutput.string(from: date)
    }
    return beerTastedDateText
  }
  
}
