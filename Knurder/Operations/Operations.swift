//
//  Operations.swift
//  FirstDb
//
//  Created by Dale Seng on 5/20/18.
//  Copyright © 2018 Sengsational. All rights reserved.
//

import Foundation

class PostReviewsOperation: AsyncOperation {
  var saucerItemsx: [SaucerItem]
  var followupOp: LogoutOperation? = nil
  var formFields: [String:String] = ["":""]
  var currentSaucerItem: SaucerItem? = nil

  init(saucerItems: [SaucerItem]) {
    self.saucerItemsx = saucerItems
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
  
  
  init(postRequest: URLRequest, defaultSession: URLSession, userDetails: [String: String], viewController: ViewController) {
    self.postRequest = postRequest
    self.defaultSession = defaultSession
    self.userDetails = userDetails
    self.viewController = viewController
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
      cancelOperations()
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
          self.cancelOperations()
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
          self.cancelOperations()
          print("User details posted but *NO* data back on the quiz.")
          print("----html----\n]n \(html)")
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
  
  init(getRequest: URLRequest, defaultSession: URLSession) {
    self.getRequest = getRequest
    self.defaultSession = defaultSession
  }

  override func main() {
    
    defaultSession.dataTask(with: getRequest) {data, response, error in
      guard let data = data, let response = response as? HTTPURLResponse,
        response.statusCode == 200 else {
          print("No data or statusCode not OK")
          print("--------------------------1-GET ACTIVE BEERS PAGE FAILED WITH BAD STATUS------------------------")
          self.state = .finished
          self.cancelOperations()
          return
      }
      if let returnData = String(data: data, encoding: .utf8) {
        self.followupOp?.setWebPageString(returnData)
      } else {
        self.cancelOperations()
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

  
  init(storeName: String, storeNumber: String, viewController: ViewController) {
    self.storeName = storeName
    self.storeNumber = storeNumber
    self.viewController = viewController
  }

  override func main() {
    if let webPage = webPage {
      print("----------------Database Load Start with \(webPage.count) characters.------------")
      let result = SaucerItem.refreshStoreList(rawItems: webPage, storeNumber: storeNumber, storeName: storeName)
      if result.hasPrefix("ERROR") {
        cancelOperations()
        print("----------------Database Load FAILED - CancelledAllOperations------------ \(result)")
        self.state = .finished
        return
      }
      print("----------------Database Load Complete------------ \(result)")
      SharedPreferences.putInt(PreferenceKeys.lastListSecPref, Int(Date().timeIntervalSince1970))
    } else {
      cancelOperations()
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
  var followupOp: FinishOperation? = nil
  var returnData: String?
  
  init(getRequest: URLRequest, defaultSession: URLSession) {
    self.getRequest = getRequest
    self.defaultSession = defaultSession
  }
  
  override func main() {

    defaultSession.dataTask(with: getRequest) {data, response, error in
      guard let data = data, let response = response as? HTTPURLResponse,
        response.statusCode == 200 else {
          print("No data or statusCode not OK")
          print("--------------------------1-GET STORE PAGE FAILED WITH BAD STATUS------------------------")
          self.cancelOperations()
          self.state = .finished
          return
      }
      if let returnData = String(data: data, encoding: .utf8) {
        let newArrivalNames = HtmlParsing.getNewArrivalsFromPage(returnData)
        if newArrivalNames.count > 0 {
            SaucerItem.refreshNewArrivals(newArrivalNames: newArrivalNames)
        } else {
          self.cancelOperations()
        }
      }
      print("--------------------------1-GET STORE PAGE IS DONE-------------------------")
      self.state = .finished
      }.resume()
  }
  

  public func defineFollowOnOperation(_ followupOp: FinishOperation) {
    self.followupOp = followupOp
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

  
  init(getRequest: URLRequest, defaultSession: URLSession, credentials: [String: String]) {
    self.getRequest = getRequest
    self.defaultSession = defaultSession
    self.credentials = credentials
  }
  
  override func main() {
    
    print("--------------------------1-GET FORM PAGE IS STARTING-------------------------")
    defaultSession.dataTask(with: getRequest) {data, response, error in
      guard let data = data, let response = response as? HTTPURLResponse,
        response.statusCode == 200 else {
          print("No data or statusCode not OK")
          print("--------------------------1-GET FORM PAGE FAILED WITH BAD STATUS------------------------")
          self.cancelOperations()
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

  
  init(postRequest: URLRequest, defaultSession: URLSession, credentials: [String: String]) {
    self.postRequest = postRequest
    self.defaultSession = defaultSession
    self.credentials = credentials
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
      cancelOperations()
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
          self.cancelOperations()
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
          self.cancelOperations()
          print("Form posted but *NOT* logged in: the response page did not have 'user-info' on it.  We tried \(self.credentials["emailOrUsername"] ?? "") \(self.credentials["password"] ?? "")")
          print("----html----\n]n \(html)")
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
  
  init(getRequest: URLRequest, defaultSession: URLSession, viewController: ViewController) {
    self.getRequest = getRequest
    self.defaultSession = defaultSession
    self.viewController = viewController
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
      cancelOperations()
      self.finishupOp?.setStatus("Not able to get tasted data.  Try logging on with your web browser.")
      self.state = .finished
      return
    }
    defaultSession.dataTask(with: getRequest) {data, response, error in
      guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
          print("No data or statusCode not OK")
          self.finishupOp?.setStatus("Not able to get tasted data.  Try logging on with your web browser.")
          self.cancelOperations()
          self.state = .finished
          return
      }
      if let returnData = String(data: data, encoding: .utf8) {
        print("***********************THIS IS THE TASTED******************************")
        let result = SaucerItem.refreshTastedList(rawItems: returnData)
        if result.hasPrefix("ERROR") {
          self.cancelOperations()
          print("----------------Database Tasted Load FAILED - CancelledAllOperations------------ \(result)")
          self.state = .finished
          return
        } else {
          print("Successfully loaded tasted data")
          SharedPreferences.putInt(PreferenceKeys.lastTastedSecPref, Int(Date().timeIntervalSince1970))
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
  
  init(getRequest: URLRequest, defaultSession: URLSession) {
    self.getRequest = getRequest
    self.defaultSession = defaultSession
  }
  
  override func main() {
    
    defaultSession.dataTask(with: getRequest) {data, response, error in
      guard let _ = data, let response = response as? HTTPURLResponse,
        response.statusCode == 200 else {
          print("No data or statusCode not OK")
          print("--------------------------1-LOGOUT PAGE FAILED WITH BAD STATUS------------------------")
          self.state = .finished
          self.cancelOperations()
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

class FinishOperation: AsyncOperation {
  var viewController: ViewController
  var message: String
  var clearLoader: Bool
  var uiParameters: [String]?
  
 
  
  init(viewController: ViewController, message: String, uiParameters: [String]?, clearLoader: Bool) {
    self.viewController = viewController
    self.message = message
    self.uiParameters = uiParameters
    self.clearLoader = clearLoader
  }
  
  func setStatus(_ message: String) {
    self.message = message
  }
  
  override func main() {
    
    if clearLoader {
      LoaderController.sharedInstance.removeLoader(viewController: self.viewController, message, uiParameters: uiParameters)
      // After the user gets done updating their list(s), we check for a quiz.  Usually it does nothing, but occasionally, it will pop a dialog asking if they want to do the quiz
      if AppDelegate.quizCheck { // Only run once per session
        DispatchQueue.main.async {
          self.viewController.runQuizCheck() // Does nothing if the user is not a logged-in UFO member
        }
        AppDelegate.quizCheck = false // Only run once per session
      }
    }
    print("--------------------------1-FINISH OPERATION IS STARTING and ENDING-------------------------")
  }
}



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
      return "\(key)=\(self.percentEscapeString(value))"
    }
    
    httpBody = parameterArray.joined(separator: "&").data(using: String.Encoding.utf8)
  }
}

