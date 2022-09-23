//
//  Operations.swift
//  FirstDb
//
//  Created by Dale Seng on 5/20/18.
//  Copyright © 2018 Sengsational. All rights reserved.
//

import Foundation
import UIKit


class PostReviewsOperation: AsyncOperation {
  var saucerItemsx: [SaucerItem]
  var followupOp: LogoutOperation? = nil
  var formFields: [String:String] = ["":""]
  var currentSaucerItem: SaucerItem? = nil
  var mQueue: OperationQueue

  init(saucerItems: [SaucerItem], queue: OperationQueue) {
    self.saucerItemsx = saucerItems
    self.mQueue = queue
    super.init()
  }
  
  override func main() {
    print("Calling postReviews")
    postReviews(items: self.saucerItemsx)
    print("Done calling postReviews")
  }

  func postReviews(items: [SaucerItem]) {
    guard items.count > 0  else {
      print("No Reviews to post.")
      self.state = .finished
      return
    }
    print("postReviews STARTING count: \(items.count)")
    var currentUrl = URL(string: "https://www.sample.com")!
    var urlValid = false
    var pendingSaucerItems = items
    repeat { // Expect a single pass here unless the review_id is bad (not likely)
      print("postReviews with pendingSaucerItems count: \(pendingSaucerItems.count)")
      currentSaucerItem = pendingSaucerItems.removeFirst()
      if let currentSaucerItem = currentSaucerItem, let review_id = currentSaucerItem.review_id {
        let currentUrlString = ("https://www.beerknurd.com/node/" + review_id + "/edit")
        if let url = URL(string: currentUrlString) {
          currentUrl = url
          urlValid = true
        }
      }
    } while !urlValid && pendingSaucerItems.count > 0
    print("ending 'while' with urlValid \(urlValid) and pendingSaucerItems count: \(pendingSaucerItems.count)")
    
    if urlValid {
      let session = URLSession.shared
      let task = session.dataTask(with: currentUrl, completionHandler: {(data, response, error) in
        print("++++++++++++++++++dataTask getFormDataRequest starting ++++++++++++++++++")
        print("task.....")
        if let _ = error {
          print("error received")
          DispatchQueue.main.async {
            print(">>>>>>>>>> START RECURSION ERROR1<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
            self.postReviews(items: pendingSaucerItems)
            print(">>>>>>>>>> END RECURSION ERROR1<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
          }
          return
        }
        
        if let pageData = data, let response = response as? HTTPURLResponse {
          print("Response code: \(response.statusCode) with size \(pageData.count)")
          //let pageHtml = String(data: pageData, encoding: .utf8)
          //print("pageHtml\n\(pageHtml ?? "(no html provided)")")
          
        }
        
        guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
          print("server error received" )
          DispatchQueue.main.async {
            print(">>>>>>>>>> START RECURSION ERROR2<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
            self.postReviews(items: pendingSaucerItems)
            print(">>>>>>>>>> END RECURSION ERROR2<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
          }
          return
        }
        
        if let html = String(data: data, encoding: .utf8), let currentSaucerItem = self.currentSaucerItem, let stars = currentSaucerItem.user_stars, let reviewText = currentSaucerItem.user_review {
          // We got the form page! //print("The response:\n\(html)")
          
          // Pull the form fields off the page and also insert our own inputs into the form
          self.formFields = HtmlParsing.getParamListFromReviewHtml(html, saucerName: SharedPreferences.getString(PreferenceKeys.storeNamePref,"Flying Saucer"), beerName: currentSaucerItem.name!, userName: SharedPreferences.getString(PreferenceKeys.userNamePref,"Beer Knurd"), stars: stars, reviewText: reviewText)
          
          /*********************/
          /*********************/
          /*******BEGIN*********/
          /*****SECOND REQUEST**/
          /*********************/
          /*********************/
          /*********************/

          // 1) Set up URL Request.  Usually done in the TransactionDriver, but doing it here since we're doing two request in on Operation
          var postUrlRequest = URLRequest(url: currentUrl) //same url
          postUrlRequest.httpMethod = "PUT"
          postUrlRequest.timeoutInterval = 30
          for item in Constants.Http.postHeaders {
            postUrlRequest.addValue(item.value, forHTTPHeaderField: item.key)
          }
          
          // 2) Build a single string out of all of our form fields and put that into the request
          var finishedString = ""
          for item in self.formFields {
            let encItemKey = item.key.replacingOccurrences(of: "[", with: "%5B").replacingOccurrences(of: "]", with: "%5D")
            let encItemVal = item.value.replacingOccurrences(of: "+", with: "%2B")
            finishedString = finishedString + encItemKey + "=" + encItemVal + "&"
          }
          finishedString = String(finishedString.dropLast())
          postUrlRequest.placeParametersString(parameters: finishedString)
          
          // 3) Post the form to the server in order for the review text to be saved
          session.dataTask(with: postUrlRequest) {data, response, error in
            print("++++++++++++++++++dataTask postUrlRequest starting ++++++++++++++++++")
            guard let data = data, let response = response as? HTTPURLResponse,
              response.statusCode == 200 else {
                print("No data or statusCode not OK")
                print("--------------------------X1-POST FORM PAGE FAILD WITH BAD CODE ------------------------")
                return
            }
            if let html = String(data: data, encoding: .utf8) {
              if html.range(of: "Error message") != nil {
                print("Page was posted, but review NOT saved!")
              } else {
                print("Page was posted, no error text on page.  Posted successfully.")
                currentSaucerItem.review_flag = "W"
                SaucerItem.setItemAsReviewed(currentSaucerItem.review_id)
              }
            }
            print("--------------------------X2-POST FORM PAGE IS DONE-------------------------")
            }.resume() // DOES NOT BLOCK
          /*********************/
          /*********************/
          /*******END***********/
          /*****SECOND REQUEST**/
          /*********************/
          /*********************/
          /*********************/

          
        } else {
          print("ERROR: One or more of html data, currentSaucerItem, stars, or reviewText was invalid.  There will be no posting of the review.")
        }
        
        print(">>>>>>>>>> START RECURSION<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
        self.postReviews(items: pendingSaucerItems)
        print(">>>>>>>>>> END RECURSION<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")

        
      })
      task.resume() // /does not block...immediatly starts running the task defined above and returns
    } else {
      print("No more urls to work on")
    }
  }
  
  public func defineFollowOnOperation(_ followupOp: LogoutOperation) {
    print("setting followupOp")
    self.followupOp = followupOp
  }

}

class PostUserDetailsOperation: AsyncOperation {
  var postRequest: URLRequest
  var defaultSession: URLSession
  var userDetails: [String: String]
  var viewController: ViewController
  
  // MARK: Variables for successive operation
  var followupOp: FinishOperation? = nil
  var mQueue: OperationQueue

  
  init(postRequest: URLRequest, defaultSession: URLSession, userDetails: [String: String], viewController: ViewController, queue: OperationQueue) {
    self.postRequest = postRequest
    self.defaultSession = defaultSession
    self.userDetails = userDetails
    self.viewController = viewController
    self.mQueue = queue
    super.init()
  }
  
  override func main() {

    var finishedString = ""
    for item in userDetails {
      //let encItemKey = item.key.replacingOccurrences(of: "[", with: "%5B").replacingOccurrences(of: "]", with: "%5D")
      //let encItemVal = item.value.replacingOccurrences(of: "+", with: "%2B")
      let encItemVal = item.value.replacingOccurrences(of: "@", with: "%40").replacingOccurrences(of: " ", with: "+")
      finishedString = finishedString + item.key + "=" + encItemVal + "&"
    }
    finishedString = String(finishedString.dropLast())
    print("finishedString [\(finishedString)]")
    postRequest.placeParametersString(parameters: finishedString)
    
    print("--------------------------21-POST USER DETAILS PAGE IS STARTING-------------------------")
    guard userDetails.count > 3 else {
      print("PostFormOperation did have formFields pre-populated.  Can not continue.")
      print("--------------------------21-POST USER DETAILS PAGE FAILD BECAUSE IT HAD NO INPUT DATA ------------------------")
      self.cancelOperations(queue: self.mQueue)
      self.state = .finished
      return
    }
    
    /*
    let headerFields = postRequest.allHTTPHeaderFields
    let requestBody = postRequest.httpBody
    let description = postRequest.debugDescription
    let method = postRequest.httpMethod
    let shouldHandleCookies = postRequest.httpShouldHandleCookies
    let url = postRequest.url
    
    print("headerFields:\(String(describing: headerFields))  requestBody:\(String(describing: requestBody))  description:\(description)  method:\(method ?? "")   shouldHandleCookies:\(shouldHandleCookies)  url:\(String(describing: url))")
    
    print("request body: \(String(data: requestBody!, encoding: String.Encoding.utf8) ?? "nil")")
    */
    
    defaultSession.dataTask(with: postRequest) {data, response, error in
      if data != nil {
        //let html = String(data: data!, encoding: .utf8)
        //print("html: \(String(describing: html))")
      } else {
        print("data was nil")
      }

      guard let data = data, let response = response as? HTTPURLResponse,
        response.statusCode == 200 else {
          print("No data or statusCode not OK")
          print("--------------------------21-POST USER DETAILS PAGE FAILD WITH BAD CODE ------------------------")
          self.cancelOperations(queue: self.mQueue)
          self.state = .finished
          return
      }
      if let html = String(data: data, encoding: .utf8) {
        if let range = html.range(of: "<form id=\"quiz\" name=\"quiz") { //DRS 20200218 - altered 'range of' for new page content
          
          // this testing variable 1) prevents updating the quiz timestamp, 2) allows alert to happen even if already passed or old quiz
          // let testing = arc4random() > 0 // true
          let testing = arc4random() == 0 // false
          
          print("quiz page was found!!")
          let alreadyPassed = html.range(of: "you already passed") != nil
          print("alreadyPassed was \(alreadyPassed) and testing was \(testing)")
          
          let dateString = String(html[range.upperBound..<html.index(range.upperBound, offsetBy: 8)])
          let dateFormatter = DateFormatter()
          dateFormatter.dateFormat = "yyyyMMdd"
          if let quizDate = dateFormatter.date(from: dateString) {
            if let numberOfDays = Calendar.current.dateComponents([.day], from: quizDate, to: Date()).day {
              print("it has been \(numberOfDays) since the date on the quiz page.")

              // If this is a new quiz, then put the new quiz date into the preferences
              let lastQuizTimestampSecondsRecorded = SharedPreferences.getInt(PreferenceKeys.lastQuizTimestampSecPref, 0)
              let thisQuizTimestampSeconds = Int(quizDate.timeIntervalSince1970)
              if (lastQuizTimestampSecondsRecorded != thisQuizTimestampSeconds) {
                if !testing {
                  SharedPreferences.putInt(PreferenceKeys.lastQuizTimestampSecPref, Int(quizDate.timeIntervalSince1970))
                } else {
                  print("not saving the current quiz date in preferences because we're testing")
                }
                
                // if the quiz is still kind of fresh (or we're testing), then we want to alert the user
                if (!alreadyPassed && numberOfDays < 13 ) || testing {
                  if let followupOp = self.followupOp {
                    print("setting message on followupOp")
                    followupOp.message = "There is a new Captain Keight quiz!!"
                    var daysAgoMessage = " "
                    if numberOfDays > 5 {
                      daysAgoMessage = " The quiz is dated \(numberOfDays) days ago. "
                    }
                    DispatchQueue.main.async {
                      self.viewController.askAboutLaunchingQuiz(daysAgoMessage)
                    }
                  }
                } else {
                  print("No alert: already passed \(alreadyPassed), number of days \(numberOfDays), testing \(testing)")
                }
              } else {
                print("This quiz has already sent a notification.  No more notifications will be presented for \(dateString).")
              }
            }
          }
        } else {
          if let queue = OperationQueue.current {
            self.cancelOperations(queue: queue)
          }
          print("User details posted but *NO* data back on the quiz.")
          //print("----html----\n]n \(html)")
        }
      }
      print("--------------------------2-POST USER DETAILS PAGE IS DONE-------------------------")
      self.state = .finished
      }.resume()
  }
  
  
  public func defineFollowOnOperation(_ followupOp: FinishOperation) {
    print("setting followupOp")
    self.followupOp = followupOp
  }
  
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

class GetActiveOperation: AsyncOperation {
  // MARK: Variables defined during init
  var getRequest: URLRequest
  var defaultSession: URLSession
  
  // MARK: Variables for successive operation
  var followupOp: RefreshActiveInDatabaseOperation? = nil
  var returnData: String?
  var mQueue: OperationQueue

  init(getRequest: URLRequest, defaultSession: URLSession, queue: OperationQueue) {
    self.getRequest = getRequest
    self.defaultSession = defaultSession
    self.mQueue = queue
    super.init()
  }

  override func main() {
    
    defaultSession.dataTask(with: getRequest) {data, response, error in
      guard let data = data, let response = response as? HTTPURLResponse,
        response.statusCode == 200 else {
          print("No data or statusCode not OK")
          print("--------------------------1-GET ACTIVE BEERS PAGE FAILED WITH BAD STATUS------------------------")
          self.state = .finished
          self.cancelOperations(queue: self.mQueue)
          return
      }
      if let returnData = String(data: data, encoding: .utf8) {
        self.followupOp?.setWebPageString(returnData)
      } else {
        self.cancelOperations(queue: self.mQueue)
        print("No data returned from the page<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
      }
      print("--------------------------1-GET ACTIVE BEERS PAGE IS DONE-------------------------")
      self.state = .finished
      }.resume()
  }
  

  public func defineFollowOnOperation(_ followupOp: RefreshActiveInDatabaseOperation) {
    self.followupOp = followupOp
  }
}

class RefreshActiveInDatabaseOperation: AsyncOperation {
  var webPage: String?
  var storeName: String
  var storeNumber: String
  var viewController: ViewController
  
  // MARK: Variables for successive operation
  var followupOp: GetStoreOperation? = nil
  var returnData: String?
  var mQueue: OperationQueue

  
  init(storeName: String, storeNumber: String, viewController: ViewController, queue: OperationQueue) {
    self.storeName = storeName
    self.storeNumber = storeNumber
    self.viewController = viewController
    self.mQueue = queue
    super.init()
  }

  override func main() {
    if let webPage = webPage {
      print("----------------Database Load Start with \(webPage.count) characters.------------")
      let result = SaucerItem.refreshStoreList(rawItems: webPage, storeNumber: storeNumber, storeName: storeName)
      if result.hasPrefix("ERROR") {
        self.cancelOperations(queue: self.mQueue)
        print("----------------Database Load FAILED - CancelledAllOperations------------ \(result)")
        self.state = .finished
        return
      }
      print("----------------Database Load Complete------------ \(result)")
      SharedPreferences.putInt(PreferenceKeys.lastListSecPref, Int(Date().timeIntervalSince1970))
    } else {
      self.cancelOperations(queue: self.mQueue)
    }
    self.state = .finished
    return
  }
  
  func setWebPageString(_ webPage: String) {
    self.webPage = webPage
  }

  public func defineFollowOnOperation(_ followupOp: GetStoreOperation) {
    self.followupOp = followupOp
  }

}

class GetStoreOperation: AsyncOperation {
  
  // MARK: Variables defined during init
  var getRequest: URLRequest
  var defaultSession: URLSession
  
  // MARK: Variables for successive operation
  var followupOp: AsyncOperation? = nil
  var returnData: String?
  var mQueue: OperationQueue

  init(getRequest: URLRequest, defaultSession: URLSession, queue: OperationQueue) {
    self.getRequest = getRequest
    self.defaultSession = defaultSession
    self.mQueue = queue
    super.init()
  }
  
  override func main() {
    print("--------------------------1-GET STORE PAGE STARTED!!! -----------------------")
    
    defaultSession.dataTask(with: getRequest) {data, response, error in
      guard let data = data, let response = response as? HTTPURLResponse,
        response.statusCode == 200 else {
          print("No data or statusCode not OK")
          print("--------------------------1-GET STORE PAGE FAILED WITH BAD STATUS------------------------")
          self.cancelOperations(queue: self.mQueue)
          self.state = .finished
          return
      }
      if let returnData = String(data: data, encoding: .utf8) {
        let newArrivalNames = HtmlParsing.getNewArrivalsFromPage(returnData)
        if newArrivalNames.count > 0 {
            SaucerItem.refreshNewArrivals(newArrivalNames: newArrivalNames)
        } else {
          if let queue = OperationQueue.current {
            self.cancelOperations(queue: queue)
          }
        }
      }
      print("--------------------------1-GET STORE PAGE IS DONE-------------------------")
      self.state = .finished
      }.resume()
    
    self.state = .finished
  }

  public func defineFollowOnOperation(_ followupOp: AsyncOperation) {
    self.followupOp = followupOp
  }
}

class GetMenuOperation: AsyncOperation {
  // MARK: Variables defined during init
  var getRequest: URLRequest
  var defaultSession: URLSession
  
  // MARK: Variables for successive operation
  var followupOp: RefreshMenuInDatabaseOperation? = nil
  var returnData: String?
  var mQueue: OperationQueue

  init(getRequest: URLRequest, defaultSession: URLSession, queue: OperationQueue) {
    self.getRequest = getRequest
    self.defaultSession = defaultSession
    self.mQueue = queue
    super.init()
  }

  override func main() {
    print("--------------------------1-GET MENU PAGE IS STARTING------------------------------")
    
    defaultSession.dataTask(with: getRequest) {data, response, error in
      guard let data = data, let responseCheck = response as? HTTPURLResponse, responseCheck.statusCode == 200 else {
        let resp = response as? HTTPURLResponse
        if let respGood = resp {
          print("No data or statusCode not OK (" + String(respGood.statusCode) + ")")
        }
        print("--------------------------1-GET MENU PAGE FAILED WITH BAD STATUS------------------------")
        self.state = .finished
        self.cancelOperations(queue: self.mQueue)
        return
      }
      if let returnData = String(data: data, encoding: .utf8) {
        self.followupOp?.setWebPageString(returnData)
      } else {
        self.cancelOperations(queue: self.mQueue)
        print("No data returned from the page<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
      }
      print("--------------------------1-GET MENU PAGE IS DONE-------------------------")
      self.state = .finished
      }.resume()
  }
  
  public func defineFollowOnOperation(_ followupOp: RefreshMenuInDatabaseOperation) {
    self.followupOp = followupOp
  }
}

class RefreshMenuInDatabaseOperation: AsyncOperation {
  var webPage: String?
  var storeName: String
  var storeNumber: String
  var viewController: ViewController
  
  // MARK: Variables for successive operation
  var followupOp: FinishOperation? = nil
  var returnData: String?
  var mQueue: OperationQueue

  init(storeName: String, storeNumber: String, viewController: ViewController, queue: OperationQueue) {
    self.storeName = storeName
    self.storeNumber = storeNumber
    self.viewController = viewController
    self.mQueue = queue
    super.init()
  }

  override func main() {
    if let webPage = webPage {
      print("----------------Untappd web page access Start with \(webPage.count) characters.------------")
      if webPage.indexOf("container.innerHTML") < 0 {
      self.cancelOperations(queue: self.mQueue)
        print("--------web page missing key------")
        self.state = .finished
        return
      }
      let result = UntappdHelper.refreshMenuList(rawItems: webPage, storeNumber: storeNumber, storeName: storeName)
      if result.hasPrefix("ERROR") {
      self.cancelOperations(queue: self.mQueue)
        print("----------------Untappd web page access FAILED - CancelledAllOperations------------ \(result)")
        self.state = .finished
        return
      }
      // get list of UntappdItem objects from helper object
      let untappdItemList = UntappdHelper.getUntappdItemList()
      if (untappdItemList.isEmpty) {
      self.cancelOperations(queue: self.mQueue)
        print("----------------Untappd web page had zero entries - CancelledAllOperations------------ \(result)")
        self.state = .finished
        return
      }
      
      let resultValues = OcrScanHelper.matchUntappdItems(untappdItemArray: untappdItemList, storeNumber: storeNumber)
      print("result values " + resultValues.description)
      print("populated taps \(resultValues[0]), matched taps \(resultValues[1]), total taps \(resultValues[2])")
      
      print("----------------Database Menu Load Complete------------ \(result)")
    } else {
      self.cancelOperations(queue: self.mQueue)
    }
    self.state = .finished
    return
  }
  
  func setWebPageString(_ webPage: String) {
    self.webPage = webPage
  }

  public func defineFollowOnOperation(_ followupOp: FinishOperation) {
    self.followupOp = followupOp
  }

}

class FinishOperation: AsyncOperation {
  var viewController: ViewController
  var masterViewController: MasterViewController
  var message: String
  var clearLoader: Bool
  var uiParameters: [String]?
  var mQueue: OperationQueue
  var viewControllerPouplated = false

  init(viewController: ViewController, message: String, uiParameters: [String]?, clearLoader: Bool, queue: OperationQueue) {
    self.viewController = viewController
    self.viewControllerPouplated = true
    self.masterViewController = MasterViewController()
    self.message = message
    self.uiParameters = uiParameters
    self.clearLoader = clearLoader
    self.mQueue = queue
    super.init()
  }

  init(masterViewController: MasterViewController, message: String, uiParameters: [String]?, clearLoader: Bool, queue: OperationQueue) {
    self.viewController = ViewController()
    self.viewControllerPouplated = false
    self.masterViewController = masterViewController
    self.message = message
    self.uiParameters = uiParameters
    self.clearLoader = clearLoader
    self.mQueue = queue
    super.init()
  }

  func setStatus(_ message: String) {
    self.message = message
  }
  
  override func main() {
    print("FinishOperaiton.main() - message \(message) uiParameters description " + uiParameters.debugDescription + "clearLoader \(clearLoader) viewControllerPouplated \(viewControllerPouplated)")
    if clearLoader {
      if viewControllerPouplated {
        LoaderController.sharedInstance.removeLoader(viewController: self.viewController, message, uiParameters: uiParameters)
        // After the user gets done updating their list(s), we check for a quiz.  Usually it does nothing, but occasionally, it will pop a dialog asking if they want to do the quiz
        if AppDelegate.quizCheck { // Only run once per session
          DispatchQueue.main.async {
            self.viewController.runQuizCheck() // Does nothing if the user is not a logged-in UFO member
          }
          AppDelegate.quizCheck = false // Only run once per session
        }
        
      } else {
        LoaderController.sharedInstance.removeLoader(masterViewController: self.masterViewController, message, uiParameters: uiParameters)
        /*
        if SharedPreferences.getString(PreferenceKeys.mouLoginErrorPref, "") == "true" {
          DispatchQueue.main.async {
            SharedPreferences.putString(PreferenceKeys.mouLoginErrorPref, "false")
            // There was a log on attempt with MOU that failed.  Ask for help.
            print("alertMouLoginFailed() running")
            sleep(3)
            let message = "I am not able to test MOU login myself.  If you really are an MOU and you want this to work, I probably can get it working if you help me.  Look up 'ufoknurder' on Facebook, or email me at knurder.frog4food@recursor.net"
            let alertDialog = UIAlertController(title: "MOU Logon Testing", message: message, preferredStyle: .alert)
            alertDialog.addAction(UIAlertAction(title: "OK", style: .default, handler: {(action: UIAlertAction!) in
              print("OK PRESSED")
            }))
            self.masterViewController.present(alertDialog, animated: true, completion: nil)
          }
        } else {
          print("no mouLoginFailPreference")
        }
        */
        
      }
    }
    print("--------------------------1-FINISH OPERATION IS STARTING and ENDING-------------------------")
  }
}


class GetFormOperation: AsyncOperation {
  
  // MARK: Variables defined during init
  var getRequest: URLRequest
  var defaultSession: URLSession
  var credentials: [String: String]
  
  // MARK: Variables for successive operation
  var formFields: [String:String] = ["":""]
  var followupOp: PostFormOperation? = nil
  var mQueue: OperationQueue

  
  init(getRequest: URLRequest, defaultSession: URLSession, credentials: [String: String], queue: OperationQueue) {
    self.getRequest = getRequest
    self.defaultSession = defaultSession
    self.credentials = credentials
    self.mQueue = queue
    super.init()
  }
  
  override func main() {
    
    print("--------------------------1-GET FORM PAGE IS STARTING-------------------------")
    defaultSession.dataTask(with: getRequest) {data, response, error in
      guard let data = data, let response = response as? HTTPURLResponse,
        response.statusCode == 200 else {
          print("No data or statusCode not OK")
          print("--------------------------1-GET FORM PAGE FAILED WITH BAD STATUS------------------------")
          self.cancelOperations(queue: self.mQueue)
          self.state = .finished
          return
      }
      if let returnData = String(data: data, encoding: .utf8) {
        self.formFields = HtmlParsing.getParamListFromHtml(returnData, self.credentials)
      }
      
      print("we have not changed to finished state yet")
      print("form fields:  \(self.formFields)")
      self.followupOp?.setFormFields(formFields: self.formFields) // Push the form fields to the next operation
      print("--------------------------1-GET FORM PAGE IS DONE-------------------------")
      sleep(1)
      self.state = .finished
      }.resume()
  }
  

  public func defineFollowOnOperation(_ followupOp: PostFormOperation) {
    self.followupOp = followupOp
  }
  
}

class PostFormOperation: AsyncOperation {
  var postRequest: URLRequest
  var defaultSession: URLSession
  var credentials: [String: String]
  
  // MARK: Variables for successive operation
  var formFields: [String: String] = ["":""]
  var followupOp: GetTastedDataOperation? = nil
  var mQueue: OperationQueue

  
  init(postRequest: URLRequest, defaultSession: URLSession, credentials: [String: String], queue: OperationQueue) {
    self.postRequest = postRequest
    self.defaultSession = defaultSession
    self.credentials = credentials
    self.mQueue = queue
    super.init()
  }
  
  func setFormFields(formFields: [String: String]) {
    self.formFields = formFields
    //postRequest.encodeParameters(parameters: formFields)
    var finishedString = ""
    for item in formFields {
      let encItemKey = item.key.replacingOccurrences(of: "[", with: "%5B").replacingOccurrences(of: "]", with: "%5D")
      let encItemVal = item.value.replacingOccurrences(of: "+", with: "%2B")
      finishedString = finishedString + encItemKey + "=" + encItemVal + "&"
    }
    finishedString = String(finishedString.dropLast())
    postRequest.placeParametersString(parameters: finishedString)
    
  }
  
  override func main() {
    
    print("--------------------------2-POST FORM PAGE IS STARTING-------------------------")
    guard formFields.count > 3 else {
      print("PostFormOperation did have formFields pre-populated.  Can not continue.")
      print("--------------------------2-POST FORM PAGE FAILD BECAUSE IT HAD NO INPUT DATA ------------------------")
      self.cancelOperations(queue: self.mQueue)
      self.state = .finished
      return
    }
    /*
    let headerFields = postRequest.allHTTPHeaderFields
    let requestBody = postRequest.httpBody
    let description = postRequest.debugDescription
    let method = postRequest.httpMethod
    let shouldHandleCookies = postRequest.httpShouldHandleCookies
    let url = postRequest.url
    
    print("headerFields:\(String(describing: headerFields))  requestBody:\(String(describing: requestBody))  description:\(description)  method:\(method ?? "")   shouldHandleCookies:\(shouldHandleCookies)  url:\(String(describing: url))")
    
    print("request body: \(String(data: requestBody!, encoding: String.Encoding.utf8) ?? "nil")")
    */
    
    defaultSession.dataTask(with: postRequest) {data, response, error in
      guard let data = data, let response = response as? HTTPURLResponse,
        response.statusCode == 200 else {
          print("No data or statusCode not OK")
          print("--------------------------2-POST FORM PAGE FAILD WITH BAD CODE ------------------------")
      self.cancelOperations(queue: self.mQueue)
          self.state = .finished
          return
      }
      if let html = String(data: data, encoding: .utf8) {
        if html.range(of: "class=\"user-info\"") != nil {
          print("user-info found in html.  We successfully logged-in!!")
          SharedPreferences.saveValidCredentials(self.credentials)
          var userStats = HtmlParsing.getUserDataNvp(html)
          userStats["emailOrUsername"] = self.credentials["emailOrUsername"]
          self.followupOp?.setUserStats(userStats: userStats)
          SharedPreferences.saveUserStats(userStats)
        } else {
          if let queue = OperationQueue.current {
            self.cancelOperations(queue: queue)
          }
          print("Form posted but *NOT* logged in: the response page did not have 'user-info' on it.  We tried \(self.credentials["emailOrUsername"] ?? "") \(self.credentials["password"] ?? "")")

          // For MOU login attempt, set up a flag so we can ask the user to help beta test
          if let _mou = self.credentials["mou"] {
            if "1" == _mou {
              SharedPreferences.putString(PreferenceKeys.mouLoginErrorPref, "true")
            }
          }
        }
      }
      print("--------------------------2-POST FORM PAGE IS DONE-------------------------")
      self.state = .finished
      }.resume()
  }


  public func defineFollowOnOperation(_ followupOp: GetTastedDataOperation) {
    self.followupOp = followupOp
  }

}

class GetTastedDataOperation: AsyncOperation {
  
  // MARK: Variables defined during init
  var getRequest: URLRequest
  var defaultSession: URLSession
  var viewController: ViewController
  
  // MARK: Variables for successive operation
  var userStats: [String: String] = ["":""]
  var followupOp: PostReviewsOperation? = nil
  var finishupOp: FinishOperation? = nil
  var mQueue: OperationQueue

  init(getRequest: URLRequest, defaultSession: URLSession, viewController: ViewController, queue: OperationQueue) {
    self.getRequest = getRequest
    self.defaultSession = defaultSession
    self.viewController = viewController
    self.mQueue = queue
    super.init()
  }
  
  func setUserStats(userStats: [String: String]) {
    self.userStats = userStats
    self.getRequest.url?.appendPathComponent("/")
    self.getRequest.url?.appendPathComponent(userStats["loadedUser"]!) // The URL includes the user's code
  }
  
  override func main() {
    
    print("--------------------------3-GET DATA PAGE IS STARTING-------------------------")
    guard userStats.count > 3 else {
      print("User stats not present. Can not continue.")
      print("--------------------------3-GET DATA PAGE FAILD WITHOUT NETWORK ACTIVITY-------------------------")
      self.cancelOperations(queue: self.mQueue)
      self.finishupOp?.setStatus("Not able to get tasted data.  Try logging on with your web browser.")
      self.state = .finished
      return
    }
    defaultSession.dataTask(with: getRequest) {data, response, error in
      guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
          print("No data or statusCode not OK")
          self.finishupOp?.setStatus("Not able to get tasted data.  Try logging on with your web browser.")
          self.cancelOperations(queue: self.mQueue)
          self.state = .finished
          return
      }
      if let returnData = String(data: data, encoding: .utf8) {
        print("***********************THIS IS THE TASTED******************************")
        let result = SaucerItem.refreshTastedList(rawItems: returnData)
        if result.hasPrefix("ERROR") {
          if let queue = OperationQueue.current {
            self.cancelOperations(queue: queue)
          }
          print("----------------Database Tasted Load FAILED - CancelledAllOperations------------ \(result)")
          self.state = .finished
          return
        } else {
          print("Successfully loaded tasted data")
          SharedPreferences.putInt(PreferenceKeys.lastTastedSecPref, Int(Date().timeIntervalSince1970))
          //SharedPreferences.putString(PreferenceKeys.loadedUserPref, self.userStats["loadedUser"]!)
        }
      }
      print("--------------------------3-GET DATA PAGE IS ENDING-------------------------")
      self.state = .finished
      }.resume()
  }
  
  public func defineFinishupOperation(_ finishupOp: FinishOperation) {
    self.finishupOp = finishupOp
  }

  public func defineFollowOnOperation(_ followupOp: PostReviewsOperation) {
    self.followupOp = followupOp
  }

}
class LogoutOperation: AsyncOperation {
  // MARK: Variables defined during init
  var getRequest: URLRequest
  var defaultSession: URLSession
  
  // MARK: Variables for successive operation
  var followupOp: FinishOperation? = nil
  var returnData: String?
  var mQueue: OperationQueue

  init(getRequest: URLRequest, defaultSession: URLSession, queue: OperationQueue) {
    self.getRequest = getRequest
    self.defaultSession = defaultSession
    self.mQueue = queue
    super.init()
  }
  
  override func main() {
    
    defaultSession.dataTask(with: getRequest) {data, response, error in
      guard let _ = data, let response = response as? HTTPURLResponse,
        response.statusCode == 200 else {
          print("No data or statusCode not OK")
          print("--------------------------1-LOGOUT PAGE FAILED WITH BAD STATUS------------------------")
          self.state = .finished
          self.cancelOperations(queue: self.mQueue)
          return
      }
      print("--------------------------1-LOGOUT PAGE IS DONE-------------------------")
      self.state = .finished
      }.resume()
  }
  
  public func defineFollowOnOperation(_ followupOp: FinishOperation) {
    self.followupOp = followupOp
  }
}



//////////////////////////////////////////////////////////////////////////////////////////////////////////////

// #1 GO TO THE FIRST URL
class GetVisitorPageOperation: AsyncOperation {
  //var postRequest: URLRequest
  var getRequest: URLRequest
  var defaultSession: URLSession
  var credentials: [String: String]
  var followupOp: PostCardFormOperation? = nil
  var formFields: [String:String] = ["":""]
  var mQueue: OperationQueue

  init(getRequest: URLRequest, defaultSession: URLSession, credentials: [String: String], queue: OperationQueue) {
    self.getRequest = getRequest
    //self.postRequest = getRequest
    self.defaultSession = defaultSession
    self.credentials = credentials
    self.mQueue = queue
    super.init()
  }
  
  override func main() {
    print("--------------------------1-GET VISITOR PAGE IS STARTING-------------------------")
    defaultSession.dataTask(with: getRequest) {data, response, error in
      guard let data = data, let response = response as? HTTPURLResponse,
        response.statusCode == 200 else {
          print("No data or statusCode not OK")
          print("--------------------------1-GET VISITOR PAGE FAILED WITH BAD STATUS------------------------")
          self.cancelOperations(queue: self.mQueue)
          self.state = .finished
          return
      }
      print("status code: " + String(response.statusCode) + " for request: " + self.getRequest.debugDescription)
      
      if let returnData = String(data: data, encoding: .utf8) {
        self.formFields = HtmlParsing.getParamListFromVisitorHtml(returnData, self.credentials)
        //print("VISITOR HTML\n\n\n \(returnData) \n\n\nENDHTML")
        HtmlParsing.printSharedStorageCookies()
      }
      
      print("passing form fields to next operation:  \(self.formFields)")
      self.followupOp?.setFormFields(formFields: self.formFields) // Push the form fields to the next operation
      print("--------------------------1-GET VISITOR PAGE IS DONE-------------------------")
      sleep(1)
      self.state = .finished
      }.resume()
  }
  public func defineFollowOnOperation(_ followupOp:   PostCardFormOperation) {
    self.followupOp = followupOp
  }
}


// #2 POPULATE CARD NUMBER, SELECT STORE, AND SUBMIT - EXPECT PHPSESSID AS A RESULT
class PostCardFormOperation: AsyncOperation {
  var postRequest: URLRequest
  //var getRequest: URLRequest
  var defaultSession: URLSession
  var credentials: [String: String]
  var followupOp: PostCardFormLoginOperation? = nil
  var formFields: [String: String] = ["":""]
  var mQueue: OperationQueue

  init(postRequest: URLRequest, defaultSession: URLSession, credentials: [String: String], queue: OperationQueue) {
    //self.getRequest = postRequest
    self.postRequest = postRequest
    self.defaultSession = defaultSession
    self.credentials = credentials
    self.mQueue = queue
    super.init()
  }
  
  func setFormFields(formFields: [String: String]) {
    self.formFields = formFields
    var finishedString = ""
    for item in formFields {
      let encItemKey = item.key.replacingOccurrences(of: "[", with: "%5B").replacingOccurrences(of: "]", with: "%5D")
      var encItemVal = item.value.replacingOccurrences(of: "%", with: "%25")
      encItemVal = encItemVal.replacingOccurrences(of: "+", with: "%2B")
      encItemVal = encItemVal.replacingOccurrences(of: "!", with: "%21")
      encItemVal = encItemVal.replacingOccurrences(of: "=", with: "%3D")
      encItemVal = encItemVal.replacingOccurrences(of: "?", with: "%3F")
      finishedString = finishedString + encItemKey + "=" + encItemVal + "&"
    }
    finishedString = String(finishedString.dropLast())
    postRequest.placeParametersString(parameters: finishedString)
    print("#2parameterString [" + finishedString + "]")
  }

  override func main() {
    print("--------------------------1-POST CARD FORM PAGE IS STARTING-------------------------")
    defaultSession.dataTask(with: postRequest) {data, response, error in
      guard
        let responseUrl = response?.url,
        let data = data,
        let response = response as? HTTPURLResponse,
        let fields = response.allHeaderFields as? [String: String],
        response.statusCode == 200 else {
          print("No data or statusCode not OK")
          print("--------------------------1-POST CARD FORM PAGE FAILED WITH BAD STATUS------------------------")
          self.cancelOperations(queue: self.mQueue)
          self.state = .finished
          return
        }
      print("status code: " + String(response.statusCode) + " for request: " + self.postRequest.debugDescription)

      if let returnData = String(data: data, encoding: .utf8) {
        self.formFields = HtmlParsing.getParamListFromKioskHtml(returnData, self.credentials)
        HtmlParsing.manageHeaderFieldCookies(fields: fields, url: responseUrl, outputPrint: true)
        HtmlParsing.printSharedStorageCookies()
      }
      
      print("form fields:  \(self.formFields)")
      self.followupOp?.setFormFields(formFields: self.formFields) // Push the form fields to the next operation
      print("--------------------------1-POST CARD FORM PAGE IS DONE-------------------------")
      sleep(1)
      self.state = .finished
      }.resume()
  }
  public func defineFollowOnOperation(_ followupOp: PostCardFormLoginOperation) {
    self.followupOp = followupOp
  }

}


// #3
class PostCardFormLoginOperation: AsyncOperation {
  var postRequest: URLRequest
  //var getRequest: URLRequest
  var defaultSession: URLSession
  var credentials: [String: String]
  var followupOp: GetCurrentQuePageOperation? = nil
  var formFields: [String: String] = ["":""]
  var mQueue: OperationQueue
  init(postRequest: URLRequest, defaultSession: URLSession, credentials: [String: String], queue: OperationQueue) {
    //self.getRequest = postRequest
    self.postRequest = postRequest
    self.defaultSession = defaultSession
    self.credentials = credentials
    self.mQueue = queue
    super.init()
  }
  func setFormFields(formFields: [String: String]) {
    var urlField = ""
    self.formFields = formFields
    var finishedString = ""
    for item in formFields {
      if item.key == "cardData" {
        urlField += item.value
      }
      let encItemKey = item.key.replacingOccurrences(of: "[", with: "%5B").replacingOccurrences(of: "]", with: "%5D")
      var encItemVal = item.value.replacingOccurrences(of: "%", with: "%25")
      //encItemVal = encItemVal.replacingOccurrences(of: "+", with: "%2B")
      encItemVal = encItemVal.replacingOccurrences(of: "!", with: "%21")
      encItemVal = encItemVal.replacingOccurrences(of: "=", with: "%3D")
      encItemVal = encItemVal.replacingOccurrences(of: "?", with: "%3F")
      finishedString = finishedString + encItemKey + "=" + encItemVal + "&"
    }
    finishedString = String(finishedString.dropLast())
    postRequest.placeParametersString(parameters: finishedString)
    print("#3parameterString [" + finishedString + "]")
    
    //Append to the url
    print("urlField [\(urlField)]")
    //let newUrlString = postRequest.url!.absoluteString + urlField
    postRequest.url = postRequest.url?.appending("cd", value: urlField)
    //postRequest.url = postRequest.url?.appending("no", value: "0")
    //postRequest.url = URL(string: newUrlString)

    //let something = postRequest.url?.appendingQueryItem("cd", value: urlField)
    //print("result after appending cd item: \(something?.debugDescription ?? "not available")")
    //postRequest.url = URL(string: "http://www.beerknurd.com/tapthatapp/signin.php?cd=%ch21611=?")
    //postRequest.url.self.
    
    print("going to post  \(postRequest.url?.debugDescription ?? "not avail")")
  }

  override func main() {
    print("--------------------------1-POST CARD LOGIN PAGE IS STARTING-------------------------")
    defaultSession.dataTask(with: postRequest) {data, response, error in
      guard
        let responseUrl = response?.url,
        let data = data,
        let response = response as? HTTPURLResponse,
        let fields = response.allHeaderFields as? [String: String],
        response.statusCode == 200 else {
          print("No data or statusCode not OK")
          print("--------------------------1-POST CARD LOGIN PAGE FAILED WITH BAD STATUS------------------------")
          self.cancelOperations(queue: self.mQueue)
          self.state = .finished
          return
      }
      print("status code: " + String(response.statusCode) + " for request: " + self.postRequest.debugDescription)

      if let returnData = String(data: data, encoding: .utf8) {
        //must contain "member-header" to be a good page
        if returnData.indexOf("member-header") < 0 {
          print("PostCardFormLoginOperation did not retrieve page containing 'member-header'")
          print("--------------------------1-POST CARD LOGIN PAGE FAILED ------------------------")
          //print("FORM LOGIN HTML\n\n\n \(returnData) \n\n\nENDHTML")
          // TODO: Let the user know the credentials are bad
          
          // For MOU login attempt, set up a flag so we can ask the user to help beta test
          if let _mou = self.credentials["mou"] {
            if "1" == _mou {
              SharedPreferences.putString(PreferenceKeys.mouLoginErrorPref, "true")
            }
          }

          self.cancelOperations(queue: self.mQueue)
          self.state = .finished
          return
        }
        HtmlParsing.manageHeaderFieldCookies(fields: fields, url: responseUrl, outputPrint: true)
        SharedPreferences.saveValidCardCredentials(self.credentials)
      }
      print("--------------------------1-POST CARD FORM LOGIN IS DONE-------------------------")
      sleep(1)
      self.state = .finished
      }.resume()
  }
  
  
  public func defineFollowOnOperation(_ followupOp: GetCurrentQuePageOperation) {
    self.followupOp = followupOp
  }
}


class GetCurrentQuePageOperation: AsyncOperation {
  //var postRequest: URLRequest
  var getRequest: URLRequest
  var defaultSession: URLSession
  var credentials: [String: String]
  var followupOp: UploadFlaggedBeersOperation? = nil
  var mQueue: OperationQueue

  init(getRequest: URLRequest, defaultSession: URLSession, credentials: [String: String], queue: OperationQueue) {
    self.getRequest = getRequest
    //self.postRequest = getRequest
    self.defaultSession = defaultSession
    self.credentials = credentials
    self.mQueue = queue
    super.init()
  }
  
  override func main() {
    print("--------------------------1-GET CURRENT QUE PAGE IS STARTING-------------------------")
    defaultSession.dataTask(with: getRequest) {data, response, error in
      guard
        let responseUrl = response?.url,
        let data = data,
        let response = response as? HTTPURLResponse,
        let fields = response.allHeaderFields as? [String: String],
        response.statusCode == 200 else {
          print("No data or statusCode not OK")
          print("--------------------------1-GET CURRENT QUE PAGE FAILED WITH BAD STATUS------------------------")
          self.cancelOperations(queue: self.mQueue)
          self.state = .finished
          return
      }
      print("status code: " + String(response.statusCode) + " for request: " + self.getRequest.debugDescription)

      if let returnData = String(data: data, encoding: .utf8) {
        if returnData.indexOf("logged-in") < 0 {
          print("GetCurrentQuePageOperation did not retrieve page containing 'logged-in'")
          print("--------------------------1-GET CURRENT QUE FAILED ------------------------")
          self.cancelOperations(queue: self.mQueue)
          self.state = .finished
          return
        }
        let queuedBeers = HtmlParsing.getCurrentQueuedBeerNamesFromHtml(returnData, self.credentials)
        HtmlParsing.manageHeaderFieldCookies(fields: fields, url: responseUrl, outputPrint: true)
        print("found these beers were on the queued page: " + queuedBeers)
        self.followupOp?.setQueuedBeers(_queuedBeers: queuedBeers)
      }
      
      print("--------------------------1-GET CURRENT QUE PAGE IS DONE-------------------------")
      sleep(1)
      self.state = .finished
      }.resume()
  }
  
  public func defineFollowOnOperation(_ followupOp: UploadFlaggedBeersOperation) {
    self.followupOp = followupOp
  }
}


class UploadFlaggedBeersOperation: AsyncOperation {
  //var postRequest: URLRequest
  var getRequest: URLRequest
  var defaultSession: URLSession
  var credentials: [String: String]
  var brewIds: [String]
  var followupOp: FinishOperation? = nil
  var queuedBeers: String!
  var mQueue: OperationQueue
  var completedCount: Int = 0
  init(getRequest: URLRequest, defaultSession: URLSession, credentials: [String: String], brewIds: [String], queue: OperationQueue) {
    self.getRequest = getRequest
    //self.postRequest = getRequest
    self.defaultSession = defaultSession
    self.credentials = credentials
    self.brewIds = brewIds
    self.mQueue = queue
    super.init()
  }
  
  func setQueuedBeers(_queuedBeers: String) {
    queuedBeers = _queuedBeers
  }
  
  override func main() {
    print("--------------------------1-UPLOAD FLAGGED PAGE IS STARTING-- \(brewIds.count) iterations -----------------------")
    let storeNumber = SharedPreferences.getString(PreferenceKeys.storeNumberPref, "13888") //The list store number, not the cardauth store number
    
    var dataTaskList = [URLSessionDataTask]()
    
    for brewId in brewIds {
      if let queuedBeers = queuedBeers {
        if queuedBeers.indexOf(brewId) > 0 {
          print("the brewId " + brewId + " is already queued")
          continue
        } else {
          print("the brewId " + brewId + " will be posted")
        }
      }
      var eachGetRequest = getRequest
      eachGetRequest.url = eachGetRequest.url?.appending("brewID", value: brewId)
      eachGetRequest.url = eachGetRequest.url?.appending("storeID", value: storeNumber)
      
      let dataTask = defaultSession.dataTask(with: eachGetRequest) {data, response, error in
        guard
          let responseUrl = response?.url,
          let data = data,
          let response = response as? HTTPURLResponse,
          let fields = response.allHeaderFields as? [String: String],
          response.statusCode == 200 else {
          print("No data or statusCode not OK")
          print("--------------------------1-UPLOAD FLAGGED PAGE FAILED WITH BAD STATUS- \(brewId)-----------------------")
          self.cancelOperations(queue: self.mQueue)
          self.state = .finished
          self.completedCount += 1
          return
        }

        print("status code: " + String(response.statusCode) + " for request: " + self.getRequest.debugDescription)
        
        if let returnData = String(data: data, encoding: .utf8) {
          print("returned page had: " + String(returnData.count) + " characters")
          HtmlParsing.manageHeaderFieldCookies(fields: fields, url: responseUrl, outputPrint: true)
        }
        
        print("--------------------------1-UPLOAD FLAGGED PAGE IS DONE-\(brewId)------------------------")
        //This operation is not done until all beers are uploaded, so self.state is not yet .finished
        self.completedCount += 1
      }
      dataTaskList.append(dataTask)
    } // end foreach brewid

    print("There are \(dataTaskList.count) data tasks to be processed.")
    for dataTaskFromList in dataTaskList {
      dataTaskFromList.resume() //Does not block
      var maxWait = 10
      while !responseFound(dataTask: dataTaskFromList) && maxWait > 0 {
        maxWait -= 1
        sleep(1)
      }
      print("completed count \(self.completedCount)")
    }
    self.state = .finished
  }
  
  func responseFound(dataTask: URLSessionDataTask) -> Bool {
    if let _ = dataTask.response as? HTTPURLResponse {
      return true
    } else {
      return false
    }
  }
  
  public func defineFollowOnOperation(_ followupOp: FinishOperation) {
    self.followupOp = followupOp
  }
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////


extension URLRequest {
  
  private func percentEscapeString(_ string: String) -> String {
    var characterSet = CharacterSet.alphanumerics
    characterSet.insert(charactersIn: "-._* ")
    
    return string
      .addingPercentEncoding(withAllowedCharacters: characterSet)!
      .replacingOccurrences(of: " ", with: "+")
      .replacingOccurrences(of: " ", with: "+", options: [], range: nil)

  }
  
  mutating func placeParametersString(parameters: String) {
    httpMethod = "POST"
    httpBody = parameters.data(using: .utf8)
  }
  
  mutating func encodeParameters(parameters: [String : String]) {
    httpMethod = "POST"
    let parameterArray = parameters.map { (arg) -> String in
      let (key, value) = arg
      print("encodeParameters \(key) \(value) \(self.percentEscapeString(value))")
      return "\(key)=\(self.percentEscapeString(value))"
    }
    
    httpBody = parameterArray.joined(separator: "&").data(using: String.Encoding.utf8)
  }
}

