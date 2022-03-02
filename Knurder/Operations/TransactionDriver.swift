//
//  TransactionDriver.swift
//  FirstDb
//
//  Created by Dale Seng on 5/20/18.
//  Copyright © 2018 Sengsational. All rights reserved.
//

import Foundation
import UIKit
import GRDB

class TransactionDriver {
  
  static func checkForQuiz(_ userDetails: [String: String], _ viewController: ViewController) {
    // MARK: Define the URLSession
    let config = URLSessionConfiguration.default
    config.waitsForConnectivity = false
    let defaultSession = URLSession(configuration: config)
    
    // MARK: **POST USER DETAILS OPERATION**
    let url = URL(string: Constants.BaseUrl.quizPage)
    var postUrlRequest = URLRequest(url: url!)
    postUrlRequest.httpMethod = "PUT"
    postUrlRequest.timeoutInterval = 30
    for item in Constants.Http.postHeaders {
      if item.key == "Host" {
        postUrlRequest.addValue("www.saucerknurd.com", forHTTPHeaderField: item.key)
      } else if item.key == "Referer" {
        postUrlRequest.addValue("https://www.saucerknurd.com/user", forHTTPHeaderField: item.key)
      } else {
        postUrlRequest.addValue(item.value, forHTTPHeaderField: item.key)
      }
    }
    let postUserDetailsOp = PostUserDetailsOperation(postRequest: postUrlRequest, defaultSession: defaultSession, userDetails: userDetails, viewController: viewController)
    postUserDetailsOp.name = "PostUserDetailsOperation"
    
    // MARK: **FINISH OPERATION**
    let finishOp = FinishOperation(viewController: viewController, message: "Quiz Check Done", uiParameters: nil, clearLoader: false)
    finishOp.name = "FinishOperation"
 
    finishOp.addDependency(postUserDetailsOp)
    postUserDetailsOp.defineFollowOnOperation(finishOp)

    // MARK: **********************ADD OPERATIONS************************************
    OperationQueue().addOperations([postUserDetailsOp, finishOp], waitUntilFinished: false)
    print("all operations added and running")

  }
  
  static func fetchActive(storeNumber: String, storeName: String, viewController: ViewController, clearLoader: Bool, waitUntilFinished: Bool) {
    // MARK: Define the URLSession
    let config = URLSessionConfiguration.default
    config.waitsForConnectivity = false
    let defaultSession = URLSession(configuration: config)
    
    // MARK: **GET ACTIVE BEERS PAGE**
    //       *************************
    let urlStringActive = Constants.BaseUrl.active + "/" + storeNumber

    print("Calculated urlStringActive [\(urlStringActive)]")
    let url = URL(string: urlStringActive)
    var getUrlRequest = URLRequest(url: url!)
    getUrlRequest.httpMethod = "GET"
    getUrlRequest.timeoutInterval = 30
    for item in Constants.Http.getHeaders {
      getUrlRequest.addValue(item.value, forHTTPHeaderField: item.key)
    }
    let getActiveOp = GetActiveOperation(getRequest: getUrlRequest, defaultSession: defaultSession)
    getActiveOp.name = "GetActiveOperation"

    // MARK: **ENTER PAGE INTO THE DATABASE**
    //       ********************************
    let refreshActiveInDatabaseOp = RefreshActiveInDatabaseOperation(storeName: storeName, storeNumber: storeNumber, viewController: viewController)
    refreshActiveInDatabaseOp.name = "RefreshActiveInDatabaseOperation"
    
    refreshActiveInDatabaseOp.addDependency(getActiveOp)
    getActiveOp.defineFollowOnOperation(refreshActiveInDatabaseOp)
    
    // MARK: **GET STORE PAGE**
    //       ******************
    let urlStringLocations = Constants.BaseUrl.locations + "/" + storeName.replacingOccurrences(of: " ", with: "-").lowercased().replacingOccurrences(of: "the-", with: "")
    print("Calculated urlString [\(urlStringLocations)]")
    let urlLocations = URL(string: urlStringLocations)
    var getUrlRequestLocations = URLRequest(url: urlLocations!)
    getUrlRequestLocations.httpMethod = "GET"
    getUrlRequestLocations.timeoutInterval = 30
    for item in Constants.Http.getHeaders {
      getUrlRequestLocations.addValue(item.value, forHTTPHeaderField: item.key)
    }
    let getStoreOp = GetStoreOperation(getRequest: getUrlRequestLocations, defaultSession: defaultSession)
    getStoreOp.name = "GetStoreOperation"
    
    getStoreOp.addDependency(refreshActiveInDatabaseOp)
    
    // MARK: **FINISH OPERATION**
    let finishOp = FinishOperation(viewController: viewController, message: Constants.Messages.GOOD_BEER_LIST, uiParameters: [storeNumber, storeName], clearLoader: clearLoader)
    finishOp.name = "FinishOperation"
    
    finishOp.addDependency(getStoreOp)
    
    // MARK: **********************ADD OPERATIONS************************************
    OperationQueue().addOperations([getActiveOp, refreshActiveInDatabaseOp, getStoreOp, finishOp], waitUntilFinished: waitUntilFinished)
    print("all operations added and running")
  }
  
  
  static func fetchTasted(_ credentials: [String: String], _ viewController: ViewController) {

    // MARK: Define the URLSession
    let config = URLSessionConfiguration.default
    config.waitsForConnectivity = false
    let defaultSession = URLSession(configuration: config)
  
    // MARK: **FORM PAGE OPERATION** : Define the URLRequest and construct the Operation
    let url = URL(string: Constants.BaseUrl.loginForm)
    var getUrlRequest = URLRequest(url: url!)
    getUrlRequest.httpMethod = "GET"
    getUrlRequest.timeoutInterval = 20
    for item in Constants.Http.getHeaders {
      getUrlRequest.addValue(item.value, forHTTPHeaderField: item.key)
    }
    let getFormOp = GetFormOperation(getRequest: getUrlRequest, defaultSession: defaultSession, credentials: credentials)
    getFormOp.name = "GetFormOperation"
    
    // MARK: **FORM SUBMIT OPERATION**
    var postUrlRequest = URLRequest(url: url!) //same url
    postUrlRequest.httpMethod = "PUT"
    postUrlRequest.timeoutInterval = 30
    for item in Constants.Http.postHeaders {
      postUrlRequest.addValue(item.value, forHTTPHeaderField: item.key)
    }
    let postFormOp = PostFormOperation(postRequest: postUrlRequest, defaultSession: defaultSession, credentials: credentials)
    postFormOp.name = "PostFormOperation"
    
    // MARK: **DATA PULL OPERATION**
    let dataUrl = URL(string: Constants.BaseUrl.tasted)
    var dataUrlRequest = URLRequest(url: dataUrl!)
    dataUrlRequest.httpMethod = "GET"
    dataUrlRequest.timeoutInterval = 40
    for item in Constants.Http.getHeaders {
      dataUrlRequest.addValue(item.value, forHTTPHeaderField: item.key)
    }
    let dataGetOp = GetTastedDataOperation(getRequest: dataUrlRequest, defaultSession: defaultSession, viewController: viewController)
    dataGetOp.name = "GetTastedDataOperation"
    
    // MARK: **CHECK TO SEE IF ANY REVIEWS TO UPLOAD**
    let sqlString = "select *, rowid from UFO where review_flag = ? and tasted = ?"
    var arguments: [String] = ["XX","XX"] // Default is to fetch no records for upload
    let uploadReviewsPref = SharedPreferences.getString(PreferenceKeys.uploadReviewsPref, "T")
    if (uploadReviewsPref == "T"){
      arguments = ["L", "T"] // Select "L"ocal and "T"asted.
    }
    let brewController = try! FetchedRecordsController(dbQueue, request: AppDelegate.getQueryInterfaceRequest())
    try! brewController.setRequest(sql: sqlString, arguments: StatementArguments(arguments), adapter: nil)
    try! brewController.performFetch()
    let recordCount = brewController.sections[0].numberOfRecords
    //let boolean uploadReviewsStep = recordCount != 0
    
    // MARK: **UPLOAD ALL REVIEWS OPERATION**
    print("**** There were \(recordCount) reviews that needed to be uploaded ****")
    let saucerItems = brewController.fetchedRecords
    let postReviewsOp = PostReviewsOperation(saucerItems: saucerItems)
    postReviewsOp.name = "PostReviewsOperation"

    // MARK: **LOGOFF OPERATION**
    let logoutUrl = URL(string: Constants.BaseUrl.logout)
    var logoutUrlRequest = URLRequest(url: logoutUrl!)
    logoutUrlRequest.httpMethod = "GET"
    logoutUrlRequest.timeoutInterval = 3
    for item in Constants.Http.getHeaders {
      logoutUrlRequest.addValue(item.value, forHTTPHeaderField: item.key)
    }
    let logoutOp = LogoutOperation(getRequest: logoutUrlRequest, defaultSession: defaultSession)
    logoutOp.name = "LogoutOperation"
    
    // MARK: **FINISH OPERATION**
    let finishOp = FinishOperation(viewController: viewController, message: Constants.Messages.GOOD_TASTED_LIST, uiParameters: nil, clearLoader: true)
    finishOp.name = "FinishOperation"
    

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    /* 1 */
    postFormOp.addDependency(getFormOp) // The POST is dependent on the GET finishing
    getFormOp.defineFollowOnOperation(postFormOp) // Tell the earlier operation the follow-on operation, so that it can send data to it
    
    /* 2 */
    dataGetOp.addDependency(postFormOp) // The DATA is dependent on the POST finishing
    postFormOp.defineFollowOnOperation(dataGetOp) // Tell the earlier operation the follow-on operation, so that it can send data to it

    /* 3 */
    postReviewsOp.addDependency(dataGetOp)
    dataGetOp.defineFollowOnOperation(postReviewsOp)
    
    /* 4 */
    logoutOp.addDependency(postReviewsOp)
    postReviewsOp.defineFollowOnOperation(logoutOp)
    
    /* 5 */
    finishOp.addDependency(logoutOp)
    logoutOp.defineFollowOnOperation(finishOp)
    
    print("addding all operations and starting the first")
    OperationQueue().addOperations([getFormOp, postFormOp, dataGetOp, postReviewsOp, logoutOp, finishOp], waitUntilFinished: false)
    print("all operations added and running")
      
    
  }
}


