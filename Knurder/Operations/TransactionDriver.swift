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
  
  static var opQueue = OperationQueue()
  
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
    let postUserDetailsOp = PostUserDetailsOperation(postRequest: postUrlRequest, defaultSession: defaultSession, userDetails: userDetails, viewController: viewController, queue: opQueue)
    postUserDetailsOp.name = "PostUserDetailsOperation"
    
    // MARK: **FINISH OPERATION**
    let finishOp = FinishOperation(viewController: viewController, message: "Quiz Check Done", uiParameters: nil, clearLoader: false, queue: opQueue)
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
    //                  ==================
    let getActiveOp =   GetActiveOperation(getRequest: getUrlRequest, defaultSession: defaultSession, queue: opQueue)
    getActiveOp.name = "GetActiveOperation"
    //                  ==================

    // MARK: **ENTER PAGE INTO THE DATABASE**
    //       ********************************
    //                                ================================
    let refreshActiveInDatabaseOp =   RefreshActiveInDatabaseOperation(storeName: storeName, storeNumber: storeNumber, viewController: viewController, queue: opQueue)
    refreshActiveInDatabaseOp.name = "RefreshActiveInDatabaseOperation"
    //                                ================================
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
    //                 =================
    let getStoreOp =   GetStoreOperation(getRequest: getUrlRequestLocations, defaultSession: defaultSession, queue: opQueue)
    getStoreOp.name = "GetStoreOperation"
    //                 =================
    getStoreOp.addDependency(refreshActiveInDatabaseOp)
    refreshActiveInDatabaseOp.defineFollowOnOperation(getStoreOp)

    // MARK: **GET MENU PAGE**
    //       *****************
    var urlStringMenu = "" // variable will remain empty if store name has no untappd url
    for item in Constants.untappdByStore {
      if item.key == storeNumber {
        if item.value.isEmpty {
          break;
        }
        urlStringMenu = Constants.BaseUrl.untappd + item.value
        break;
      }
    }
    print("Calculated urlStringMenu [\(urlStringMenu)]")
    
    if urlStringMenu.isEmpty {
      // MARK: **FINISH OPERATION**
      //               ===============
      let finishOp = FinishOperation(viewController: viewController, message: Constants.Messages.GOOD_BEER_LIST, uiParameters: [storeNumber, storeName], clearLoader: clearLoader, queue: opQueue)
      finishOp.name = "FinishOperation"
      //               ===============
      finishOp.addDependency(getStoreOp)
      getStoreOp.defineFollowOnOperation(finishOp)
      
      // MARK: **********************ADD OPERATIONS************************************
      OperationQueue().addOperations([getActiveOp, refreshActiveInDatabaseOp, getStoreOp, finishOp], waitUntilFinished: waitUntilFinished)
      print("three operations added and running. Not running menu update due to not having a url.")
      return
    }
    
    let urlMenu = URL(string: urlStringMenu)
    var getUrlRequestMenu = URLRequest(url: urlMenu!)
    getUrlRequestMenu.httpMethod = "GET"
    getUrlRequestMenu.timeoutInterval = 30
    for item in Constants.Http.getHeaders {
      if item.key == "Host" {
        getUrlRequestMenu.addValue("business.untappd.com", forHTTPHeaderField: item.key)
      } else {
        getUrlRequestMenu.addValue(item.value, forHTTPHeaderField: item.key)
      }
    }
    let defaultMenuSession = URLSession(configuration: config)
    //                ================
    let getMenuOp =   GetMenuOperation(getRequest: getUrlRequestMenu, defaultSession: defaultMenuSession, queue: opQueue)
    getMenuOp.name = "GetMenuOperation"
    //                ================
    getMenuOp.addDependency(getStoreOp)
    getStoreOp.defineFollowOnOperation(getMenuOp)
    
    // MARK: **ENTER MENU INFO INTO THE DATABASE**
    //       *************************************
    //                              ==============================
    let refreshMenuInDatabaseOp =   RefreshMenuInDatabaseOperation(storeName: storeName, storeNumber: storeNumber, viewController: viewController, queue: opQueue)
    refreshMenuInDatabaseOp.name = "RefreshMenuInDatabaseOperation"
    //                              ==============================
    refreshMenuInDatabaseOp.addDependency(getMenuOp)
    getMenuOp.defineFollowOnOperation(refreshMenuInDatabaseOp)
    
    // MARK: **FINISH OPERATION**
    //               ===============
    let finishOp =   FinishOperation(viewController: viewController, message: Constants.Messages.GOOD_BEER_MENU_LIST, uiParameters: [storeNumber, storeName], clearLoader: clearLoader, queue: opQueue)
    finishOp.name = "FinishOperation"
    //               ===============
    finishOp.addDependency(refreshMenuInDatabaseOp)
    
    // MARK: **********************ADD OPERATIONS************************************
    OperationQueue().addOperations([getActiveOp, refreshActiveInDatabaseOp, getStoreOp, getMenuOp, refreshMenuInDatabaseOp, finishOp], waitUntilFinished: waitUntilFinished)
    print("all operations added and running " + OperationQueue().operations.debugDescription)
  }
  
  static func uploadBrewsOnQueue(_ credentials: [String: String], _ viewController: MasterViewController, _ brewIds: [String], _ saucerItems: [SaucerItem]) {
    let uploadOpQueue = OperationQueue()
    print("credentials \(credentials.debugDescription)")
    print("brewIds: \(brewIds.debugDescription)")
    //let storeNumber = credentials["storeNumberCardauth"] ?? "13888" //WRONG!  Use the store number of the BEER LIST, not card auth
    let storeNumber = SharedPreferences.getString(PreferenceKeys.storeNumberPref, "13888")
    let storeVarChar = StoreNameHelper.lookupStoreVarchar(forNumber: storeNumber)
    
    // MARK: Define the URLSession
    let config = URLSessionConfiguration.default
    config.waitsForConnectivity = false
    //let delegateForRedirect = DelegateForRedirects()
    //let defaultSession = URLSession(configuration: config, delegate: delegateForRedirect, delegateQueue: nil) //This went into an infinite loop
    let defaultSession = URLSession(configuration: config)
    // MARK: **GET VISITOR PAGE OPERATION** : Define the URLRequest and construct the Operation
    let url = URL(string: Constants.BaseUrl.visitorForm + storeVarChar)
    
    var getUrlRequest = URLRequest(url: url!)
    getUrlRequest.httpMethod = "GET"
    getUrlRequest.timeoutInterval = 20
    for item in Constants.Http.getHeaders {
      getUrlRequest.addValue(item.value, forHTTPHeaderField: item.key)
    }
    let getVisitorPageOp = GetVisitorPageOperation(getRequest: getUrlRequest, defaultSession: defaultSession, credentials: credentials, queue: uploadOpQueue)
    getVisitorPageOp.name = "GetVisitorPageOperation"

    // MARK: **SUMBIT TO VISITOR PAGE WITH CARD NUMBER OPERATION**
    let postUrl = URL(string: Constants.BaseUrl.kiosk)
    var postUrlRequest = URLRequest(url: postUrl!)
    postUrlRequest.httpMethod = "PUT"
    postUrlRequest.timeoutInterval = 75
    for item in Constants.Http.postHeaders {
      postUrlRequest.addValue(item.value, forHTTPHeaderField: item.key)
    }
    postUrlRequest.setValue("https://www.beerknurd.com/tapthatapp", forHTTPHeaderField: "Referer")
    let postCardFormOp = PostCardFormOperation(postRequest: postUrlRequest, defaultSession: defaultSession, credentials: credentials, queue: uploadOpQueue)
    postCardFormOp.name = "PostCardFormOperation"

    // MARK: **SUMBIT TO SIGNON PAGE WITH CARD CREDENTIALS**
    let cardLogonUrl = URL(string: Constants.BaseUrl.cardLoginForm)
    var postCardLogonUrlRequest = URLRequest(url: cardLogonUrl!)
    postCardLogonUrlRequest.httpMethod = "PUT"
    postCardLogonUrlRequest.timeoutInterval = 75
    for item in Constants.Http.postHeaders {
      postCardLogonUrlRequest.addValue(item.value, forHTTPHeaderField: item.key)
    }
    postCardLogonUrlRequest.setValue("https://www.beerknurd.com/tapthatapp", forHTTPHeaderField: "Referer")
    let postCardFormLoginOp = PostCardFormLoginOperation(postRequest: postCardLogonUrlRequest, defaultSession: defaultSession, credentials: credentials, queue: uploadOpQueue)
    postCardFormLoginOp.name = "PostCardFormLoginOperation"

    // MARK: **GET QUEUED BEER NAMES OPERATION** : Define the URLRequest and construct the Operation
    let urlMemberQueue = URL(string: Constants.BaseUrl.cardauth)
    var getMemberUrlRequest = URLRequest(url: urlMemberQueue!)
    getMemberUrlRequest.httpMethod = "GET"
    getMemberUrlRequest.timeoutInterval = 20
    for item in Constants.Http.getHeaders {
      getMemberUrlRequest.addValue(item.value, forHTTPHeaderField: item.key)
    }
    let getCurrentQuePageOp = GetCurrentQuePageOperation(getRequest: getMemberUrlRequest, defaultSession: defaultSession, credentials: credentials, queue: uploadOpQueue)
    getCurrentQuePageOp.name = "GetCurrentQuePageOperation"

    // MARK: **SAVE QUEUED BEERS OPERATION** : Define the URLRequest and construct the Operation
    let urlQueueSave = URL(string: Constants.BaseUrl.queSave)
    var getQueUrlRequest = URLRequest(url: urlQueueSave!)
    getQueUrlRequest.httpMethod = "GET"
    getQueUrlRequest.timeoutInterval = 50
    for item in Constants.Http.getHeaders {
      getQueUrlRequest.addValue(item.value, forHTTPHeaderField: item.key)
    }
    let uploadFlaggedBeersOp = UploadFlaggedBeersOperation(getRequest: getQueUrlRequest, defaultSession: defaultSession, credentials: credentials, brewIds: brewIds, saucerItems: saucerItems, queue: uploadOpQueue)
    uploadFlaggedBeersOp.name = "UploadFlaggedBeersOperation"

    // MARK: **FINISH OPERATION**
    let finishOp = FinishOperation(masterViewController: viewController, message: Constants.Messages.GOOD_UPLOAD, uiParameters: nil, clearLoader: true, queue: uploadOpQueue)
    finishOp.name = "FinishOperation"

    /* 1 */
    postCardFormOp.addDependency(getVisitorPageOp) // The POST is dependent on the GET finishing
    getVisitorPageOp.defineFollowOnOperation(postCardFormOp) // Tell the earlier operation the follow-on operation, so that it can send data to it

    /* 2 */
    postCardFormLoginOp.addDependency(postCardFormOp) // The POST is dependent on the GET finishing
    postCardFormOp.defineFollowOnOperation(postCardFormLoginOp) // Tell the earlier operation the follow-on operation, so that it can send data to it

    /* 3 */
    getCurrentQuePageOp.addDependency(postCardFormLoginOp) // The POST is dependent on the GET finishing
    postCardFormLoginOp.defineFollowOnOperation(getCurrentQuePageOp) // Tell the earlier operation the follow-on operation, so that it can send data to it

    /* 4 */
    uploadFlaggedBeersOp.addDependency(getCurrentQuePageOp) // The POST is dependent on the GET finishing
    getCurrentQuePageOp.defineFollowOnOperation(uploadFlaggedBeersOp) // Tell the earlier operation the follow-on operation, so that it can send data to it

    /* 5 */
    finishOp.addDependency(uploadFlaggedBeersOp) // The POST is dependent on the GET finishing
    uploadFlaggedBeersOp.defineFollowOnOperation(finishOp) // Tell the earlier operation the follow-on operation, so that it can send data to it

    print("addding all operations and starting the first")
    uploadOpQueue.addOperations([getVisitorPageOp, postCardFormOp, postCardFormLoginOp, getCurrentQuePageOp, uploadFlaggedBeersOp, finishOp], waitUntilFinished: false)
    print("all operations added and running " + OperationQueue.current.debugDescription)

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
    let getFormOp = GetFormOperation(getRequest: getUrlRequest, defaultSession: defaultSession, credentials: credentials, queue: opQueue)
    getFormOp.name = "GetFormOperation"

    /* 1 */
    //postFormOp.addDependency(getFormOp) // The POST is dependent on the GET finishing
    //getFormOp.defineFollowOnOperation(postFormOp) // Tell the earlier operation the follow-on operation, so that it can send data to it

    // MARK: **FORM SUBMIT OPERATION**
    var postUrlRequest = URLRequest(url: url!) //same url
    postUrlRequest.httpMethod = "PUT"
    postUrlRequest.timeoutInterval = 240
    for item in Constants.Http.postHeaders {
      postUrlRequest.addValue(item.value, forHTTPHeaderField: item.key)
    }
    let postFormOp = PostFormOperation(postRequest: postUrlRequest, defaultSession: defaultSession, credentials: credentials, queue: opQueue)
    postFormOp.name = "PostFormOperation"
    
    // MARK: **DATA PULL OPERATION**
    let dataUrl = URL(string: Constants.BaseUrl.tasted)
    var dataUrlRequest = URLRequest(url: dataUrl!)
    dataUrlRequest.httpMethod = "GET"
    dataUrlRequest.timeoutInterval = 75
    for item in Constants.Http.getHeaders {
      dataUrlRequest.addValue(item.value, forHTTPHeaderField: item.key)
    }
    let dataGetOp = GetTastedDataOperation(getRequest: dataUrlRequest, defaultSession: defaultSession, viewController: viewController, queue: opQueue)
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
    let postReviewsOp = PostReviewsOperation(saucerItems: saucerItems, queue: opQueue)
    postReviewsOp.name = "PostReviewsOperation"

    // MARK: **LOGOFF OPERATION**
    let logoutUrl = URL(string: Constants.BaseUrl.logout)
    var logoutUrlRequest = URLRequest(url: logoutUrl!)
    logoutUrlRequest.httpMethod = "GET"
    logoutUrlRequest.timeoutInterval = 3
    for item in Constants.Http.getHeaders {
      logoutUrlRequest.addValue(item.value, forHTTPHeaderField: item.key)
    }
    let logoutOp = LogoutOperation(getRequest: logoutUrlRequest, defaultSession: defaultSession, queue: opQueue)
    logoutOp.name = "LogoutOperation"
    
    // MARK: **FINISH OPERATION**
    let finishOp = FinishOperation(viewController: viewController, message: Constants.Messages.GOOD_TASTED_LIST, uiParameters: nil, clearLoader: true, queue: opQueue)
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


