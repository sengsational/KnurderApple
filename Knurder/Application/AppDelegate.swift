//
//  AppDelegate.swift
//  FirstDb
//
//  Created by Dale Seng on 5/14/18.
//  Copyright © 2018 Sengsational. All rights reserved.
//

import UIKit
import GRDB

var dbQueue: DatabaseQueue!

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  static var oldListCheck = true // ONLY FALSE FOR QUICKER TESTING TOXO: RE ENABLE
  
  static var quizCheck = true
  
  //static var queryCaller: String!
  static var brewController: FetchedRecordsController<SaucerItem>!
  static var beerIndexPath: IndexPath!
  
  static var tastedDateFormatInput = DateFormatter()
  static var tastedDateFormatOutput = DateFormatter()
  
  static var toastMessage = ""
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    try! setupDatabase(application)
    AppDelegate.tastedDateFormatInput.dateFormat = "yyyy MM dd"
    AppDelegate.tastedDateFormatOutput.dateStyle = DateFormatter.Style.long
    UISearchBar.appearance().tintColor = UIColor.white
    AppDelegate.incrementUsageCounter(force: false)
    //SharedPreferences.removeString(PreferenceKeys.shakerTutorialPref)
    //SharedPreferences.removeByKey(PreferenceKeys.lastListSecPref)
    //SharedPreferences.removeByKey(PreferenceKeys.lastTastedSecPref)
    
    if SharedPreferences.getString(PreferenceKeys.uberEatsHidePref,"") == "" {
      SharedPreferences.putString(PreferenceKeys.uberEatsHidePref, "F")
    }
    
    return true
  }
  
  static func incrementUsageCounter(force: Bool) {
    let timesRun = SharedPreferences.getInt(PreferenceKeys.timesRunCounter, 0)
    print("timesRun \(timesRun)")
    if (timesRun == 5 || timesRun == 25 || timesRun == 62 || timesRun == 100) && !force { return } // The counter "sticks" at 5 and 25 and only is forced past those when an alert message is presented
    SharedPreferences.putInt(PreferenceKeys.timesRunCounter, timesRun + 1)
  }

  private func setupDatabase(_ application: UIApplication) throws {
    let databaseURL = try FileManager.default
      .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      .appendingPathComponent("db.sqlite")
    dbQueue = try AppDatabase.openDatabase(atPath: databaseURL.path)
    dbQueue.setupMemoryManagement(in: application)
  }
  
  static func currentQueryIsTasted() -> Bool {
    let queryCaller = SharedPreferences.getString(PreferenceKeys.lastQueryButtonPref, Constants.QUERY_CUSTOM)
    if !(Constants.QUERY_CUSTOM == queryCaller)  { return false }
    let queryTastedKey = SharedPreferences.getString(PreferenceKeys.queryTastedPref, "B")
    return queryTastedKey == "L"
  }
  
  static func getCurrentQuery(searchText: String = "") -> [String] {

    let querySortOrder = SharedPreferences.getString(PreferenceKeys.lastQuerySortByPref, Constants.SORT_NAME)
    let querySortDirection = SharedPreferences.getString(PreferenceKeys.lastQuerySortDirection, Constants.SORT_ASC)

    let queryCaller = SharedPreferences.getString(PreferenceKeys.lastQueryButtonPref, Constants.QUERY_CUSTOM)
    
    if queryCaller == Constants.QUERY_JUST_LANDED { return getSingleItemQuery("new_arrival", "T", searchText, querySortOrder, querySortDirection)}
    else if queryCaller == Constants.QUERY_FLAGGED { return getSingleItemQuery("highlighted", "T", searchText, querySortOrder, querySortDirection)}
    
    let queryContainerKey = SharedPreferences.getString(PreferenceKeys.queryContainerPref, "B")
    let queryTastedKey = SharedPreferences.getString(PreferenceKeys.queryTastedPref, "B")
    let queryGeographyKey = SharedPreferences.getString(PreferenceKeys.queryGeographyPref, "B")
    let hideMix = SharedPreferences.getString(PreferenceKeys.hideMixPref, "T")
    let hideFlight = SharedPreferences.getString(PreferenceKeys.hideFlightPref , "T")
    
    let tastedQuery = currentQueryIsTasted()
    
    print("querySortOrder \(querySortOrder)   \(querySortDirection) isTasted: \(tastedQuery)")

    var sqlString = "SELECT *, rowid  FROM ufo where "
    var arguments: [String] = [sqlString]
    var andText = ""
    var showOnlyActive = true
    //var orderByString = ""
    
    // Container
    if queryContainerKey == "L" {
      sqlString += "containerx = ? "
      arguments.append("draught")
      andText = "AND "
    } else if queryContainerKey == "R" {
      sqlString += "containerx = ? "
      arguments.append("bottled")
      andText = "AND "
    }
    
    // Tasted
    if queryTastedKey == "L" {
      sqlString += andText + "tasted = ? "
      arguments.append("T")
      andText = "AND "
      showOnlyActive = false
    } else if queryTastedKey == "R" {
      sqlString += andText + "tasted != ? "
      arguments.append("T")
      andText = "AND "
    }
    
    // Geography
    if queryGeographyKey == "L" {
      sqlString += andText + "is_local = ? "
      arguments.append("T")
      andText = "AND "
    } else if queryGeographyKey == "R" {
      sqlString += andText + "is_import = ? "
      arguments.append("T")
      andText = "AND "
    }
    
    // Hide Mix
    if hideMix == "T" && !tastedQuery {
      sqlString += andText + "style <> ? "
      arguments.append("Mix")
      andText = "AND "
    }
      
    // Hide Mix
    if hideFlight == "T" && !tastedQuery {
      sqlString += andText + "style <> ? "
      arguments.append("Flight")
      andText = "AND "
    }
    
    if showOnlyActive {
      sqlString += andText + "active = ? "
      arguments.append("T")
      andText = "AND "
    }

    if searchText.count > 0 {
      sqlString += "AND (name LIKE ? OR style LIKE ? OR descriptionx LIKE ?) "
      let wildCard = "%" + searchText + "%"
      arguments.append(wildCard)
      arguments.append(wildCard)
      arguments.append(wildCard)
    }
    
    sqlString += " order by " + querySortOrder + " " + querySortDirection
    
    arguments[0] = sqlString
    return arguments
  }

  static func getSingleItemQuery(_ field: String, _ value: String, _ searchText: String, _ querySortOrder: String, _ querySortDirection: String) -> [String] {
    var sqlString = "SELECT *, rowid  FROM ufo where "
    var arguments: [String] = [sqlString]
    sqlString += field + " = ? "
    arguments.append(value)
    
    if searchText.count > 0 {
      sqlString += "AND (name LIKE ? OR style LIKE ? OR descriptionx LIKE ?)"
      let wildCard = "%" + searchText + "%"
      arguments.append(wildCard)
      arguments.append(wildCard)
      arguments.append(wildCard)
    }
    
    sqlString += " order by " + querySortOrder + " " + querySortDirection
    
    arguments[0] = sqlString
    return arguments
  }
  
  static func getQueryInterfaceRequest() -> QueryInterfaceRequest<SaucerItem> {
    //TODO: Allow the user to specify sort order
    return SaucerItem.order(Column("name").asc, Column("name"))
  }
  
  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }


}

