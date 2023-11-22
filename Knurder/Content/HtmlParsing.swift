//
//  HtmlParsing.swift
//  FirstDb
//
//  Created by Dale Seng on 5/17/18.
//  Copyright © 2018 Sengsational. All rights reserved.
//

import Foundation
import SwiftSoup

class HtmlParsing {
  static func getParamListFromReviewHtml(_ html: String, saucerName: String, beerName: String, userName: String, stars: String, reviewText: String) -> [String: String] {
    var paramList = [String: String]()
    do {
      let doc: Document = try SwiftSoup.parse(html)
      let reviewForm = try doc.getElementById("member-s-tasted-brew-node-form")
      let inputElements = try reviewForm?.getElementsByTag("input")
      
      guard inputElements != nil else {
        print(">>>>>>>>>>>>>>>>>>> THE PAGE DID NOT HAVE THE FORM INPUTS ON IT <<<<<<<<<<<<<<<<<<<<")
        return paramList
      }
      
      for inputElement in inputElements! {
        let key: String = try inputElement.attr("name")
        var value: String = try inputElement.attr("value")
        
        if key.trim().count == 0 { continue }
        if key.hasPrefix("field_brew") { continue }
        
        if key.hasPrefix("title") {
          value = saucerName + " - " + beerName + " - " + userName
        }
        paramList[key] = value
      }
      
      let textAreaElements = try reviewForm?.getElementsByTag("textarea")
      for textAreaElement in textAreaElements! {
        let key: String = try textAreaElement.attr("name")
        var value: String = try textAreaElement.attr("value")

        if key.hasPrefix("body") {
          value = reviewText
        }
        paramList[key] = value
      }

      let selectElements = try reviewForm?.getElementsByTag("select")
      for selectElement in selectElements! {
        let key: String = try selectElement.attr("name")
        var value: String = try selectElement.attr("value")
        if key.hasPrefix("field_rate") {
          if let starsInt: Int = Int(stars) {
            value = String( starsInt * 20 )
          }
        }
        paramList[key] = value
      }

      paramList["op"] = "Save"
      

      //for (key, value) in paramList {
      //  print("output debug form: \(key) : \(value)")
      //}
    } catch Exception.Error(let type, let msg) {
      print("error in the login page \(msg) type: \(type)")
    } catch {
      print("error in the login page.")
    }
    //print("message: \(message)")
    return paramList
  }

  
  
  static func getParamListFromHtml(_ html: String, _ credentials: [String: String]) -> [String: String] {
    var paramList = [String: String]()
    do {
      let doc: Document = try SwiftSoup.parse(html)
      let loginForm = try doc.getElementById("custom-login-form")
      let inputElements = try loginForm?.getElementsByTag("input")
      
      guard inputElements != nil else {
        print(">>>>>>>>>>>>>>>>>>> THE PAGE DID NOT HAVE THE FORM INPUTS ON IT <<<<<<<<<<<<<<<<<<<<")
        return paramList
      }
      
      for inputElement in inputElements! {
        let key: String = try inputElement.attr("name")
        var value: String = try inputElement.attr("value")
        
        if key.hasPrefix("username") {
          value = credentials["emailOrUsername"]! // Card Number became username 20200603
        } else if key.hasPrefix("password") {
          value = credentials["password"]! // Password
        } else if key.hasPrefix("field_mou") {
          value = credentials["mou"]! // MOU
          paramList[key] = value
        }
        paramList[key] = value
      }
      
      paramList["op"] = "Log+In"
      
      let selectElements = try loginForm?.getElementsByTag("select")
      for selectElement in selectElements! {
        let key: String = try selectElement.attr("id")
        var value: String = try selectElement.attr("value")
        let fieldName: String = try selectElement.attr("name")
        
        if key.hasPrefix("edit-field-login-store") {
          value = credentials["storeNumber"]! // Store number
        }
        paramList[fieldName] = value
      }
      
      //for (key, value) in paramList {
        //print("output debug form: \(key) : \(value)")
      //}
    } catch Exception.Error(let type, let msg) {
      print("error in the login page \(msg) type: \(type)")
    } catch {
      print("error in the login page.")
    }
    //print("message: \(message)")
    return paramList
  }

  static func checkStoreListFromHtml(_ html: String, _ cardNumber: String) -> Void {
    var message = "Success"
    do {
      let doc: Document = try SwiftSoup.parse(html)
      let loginForm = try doc.getElementById("alternate-login-form-entityform-edit-form")
      let optionElements = try loginForm?.getElementsByTag("option")
      if (optionElements != nil && (optionElements?.size())! > 10) {
        var storesFromLoginPage = [String: String]()
        for optionElement in optionElements! {
          let key = try optionElement.attr("value")
          let value = try optionElement.text()
          storesFromLoginPage[key] = value
        }
        StoreNameHelper.checkForNewStores(storesFromLoginPage, cardNumber)
      }
    } catch Exception.Error(let type, let msg) {
      print("error in the login page \(msg) type: \(type)")
      message = "error in the login page: \(msg)"
    } catch {
      print("error in the login page.")
      message = "error in the login page."
    }
    print("store list message: \(message)")
    return
  }

  static func getUserDataNvp(_ html: String) -> [String: String] {
    var message = "Success"
    var statsDictionary = [String: String]()
    do {
      let doc: Document = try SwiftSoup.parse(html)
      let userInfo = try doc.getElementsByClass("user-info")
      guard userInfo.size() > 0 else {
        message = "Not Logged In"
        print("getUserDataNvp message: \(message)")
        statsDictionary["ERROR"] = "not logged in"
        return statsDictionary
      }
      
      statsDictionary["userName"] = try userInfo.get(0).text()
      
      for element in try doc.getElementsByClass("profile-item-value") {
        if try element.text().contains("brews") {
          let words = try element.text().split(separator: " ")
          if words.count > 0 {
            statsDictionary["tastedCount"] = String(words[0])
            break
          }
        }
      }

      for element in try doc.getElementsByTag("input") {
        if element.id() == "card_num" {
          statsDictionary["cardNumber"] = try element.val().trimmingCharacters(in: CharacterSet(charactersIn: "01234567890").inverted)
        } else if element.id() == "loaded_user" {
          statsDictionary["loadedUser"] = try element.val()
        }
      }
      
      var firstElement = true;
      for element in try doc.getElementsByClass("profile-item") {
        if firstElement {
          let words = try element.text().split(separator: ",")
          if words.count > 1 {
            statsDictionary["firstName"] = String(words[0])
          }
          firstElement = false
          continue
        }
        if try element.text().hasPrefix("Email") {
          for subElement in try element.getElementsByClass("profile-item-value") {
            if try subElement.text().contains("@") {
              statsDictionary["email"] = try subElement.text().trim()
            }
          }
        }
      }
    } catch Exception.Error(let type, let msg) {
      print("error in the stats page \(msg) type: \(type)")
      message = "error in the stats page: \(msg)"
    } catch {
      print("error in the stats page.")
      message = "error in the stats page."
    }
    print("stats message: \(message)")
    return statsDictionary
  }

  static func getNewArrivalsFromPage(_ storePage: String) -> [String] {
    var message = "Success"
    var returnNames = [String]()
    do {
      let doc: Document = try SwiftSoup.parse(storePage)
      let viewsTables = try doc.getElementsByClass("views-table")
      if (!viewsTables.isEmpty()) {
        let table = viewsTables.get(0)
        let tableBody = table.child(0)
        let tableRows = tableBody.children()
        for tableRow: Element in tableRows.array() {
          let tableCells = tableRow.children()
          try returnNames.append(tableCells.get(0).text())
        }
      }
      
      // DRS 20200319 - Added get ubereats link or blank if not present
      let directionDiv = try doc.getElementsByClass("directions")
      if (!directionDiv.isEmpty()) {
        let links = try directionDiv.select("a[href]")
        for link: Element in links.array() {
          let href = try link.attr("abs:href")
          if href.contains("ubereats") {
            SharedPreferences.putString(PreferenceKeys.uberEatsLinkPref, href)
          } else {
            SharedPreferences.putString(PreferenceKeys.uberEatsLinkPref, "")
          }
        }
      }
    } catch Exception.Error(let type, let msg) {
      print("error in the new arrival page \(msg) type: \(type)")
      message = "error in the new arrival page: \(msg)"
    } catch {
      print("error in the new arrival page.")
      message = "error in the new arrival page."
    }
    
    print("new arrival message: \(message)")
    return returnNames
  }

  static func getParamListFromVisitorHtml(_ html: String, _ credentials: [String: String]) -> [String: String] {
    var paramList = [String: String]()
    let storeNumber = credentials["storeNumberCardauth"] ?? "13888"
    let storeTwoChar = StoreNameHelper.lookupStoreTwochar(forNumber: storeNumber)
    let cardNumber = credentials["cardNumber"] ?? "000000"
    paramList["homestore"] = "%" + storeTwoChar
    paramList["cardNumber"] = cardNumber
    paramList["mouOpt"] = "no"
    paramList["submit"] = "Beam+Me+Up!"
    if (credentials["mou"] == "no" || credentials["mou"] == "0") {
      paramList["cardNum"] = "%" + storeTwoChar + cardNumber + "=?"
    } else {
      paramList["cardNum"] = "%mou" + cardNumber + "=?"
      paramList["mouOpt"] = "yes"
    }
    return paramList
  }
  static func getParamListFromKioskHtml(_ html: String, _ credentials: [String: String]) -> [String: String] {
    var paramList = [String: String]()
    let storeNumber = credentials["storeNumberCardauth"] ?? "13888"
    let storeTwoChar = StoreNameHelper.lookupStoreTwochar(forNumber: storeNumber)
    let cardNumber = credentials["cardNumber"] ?? "000000"
    let cardPin = credentials["pin"] ?? "0000"
    //print("credentials[mou] \(credentials["mou"])")
    if (credentials["mou"] == "no" || credentials["mou"] == "0") {
      paramList["cardData"] = "%25" + storeTwoChar + cardNumber
    } else {
      paramList["cardData"] = "%mou" + cardNumber
    }
    paramList["signinPinNumber"] = cardPin
    paramList["submitPin"] = "Beam+Me+Up!"
    return paramList
  }
  
  static func getCurrentQueuedBeerNamesFromHtml(_ html: String, _ credentials: [String: String]) -> String {
    var message = "Success"
    var foundBeerIds = ""
    do {
      let doc: Document = try SwiftSoup.parse(html)
      let accordionDiv = try doc.getElementById("accordion")
      let cardList = try accordionDiv?.getElementsByClass("card")
      if (cardList != nil) {
        for card in cardList! {
          do {
            let collapseList = try card.getElementsByClass("collapse")
            let removeQueueList = try collapseList.get(0).getElementsByClass("removeQueuedBrewIcon")
            let brewId = try removeQueueList.get(0).attr("brewid")
            print("found queued beer: " + brewId);
            foundBeerIds += brewId + ", "
          } catch {
            print("failed for \(card.debugDescription)")
          }
        }
      }
    } catch Exception.Error(let type, let msg) {
      print("error in the queued beer page \(msg) type: \(type)")
      message = "error in the queued beer: \(msg)"
    } catch {
      print("error in the queued beer.")
      message = "error in the queued beer."
    }
    print("queued beer message: \(message)")
    return foundBeerIds
  }

  static func manageHeaderFieldCookies(fields: [String: String], url: URL, outputPrint: Bool) {
    let cookies = HTTPCookie.cookies(withResponseHeaderFields: fields, for: url)
    if (outputPrint) {
      print("There were \(String(cookies.count)) cookies in the header fields.")
    }
    HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: nil)
    for cookie in cookies {
      var cookieProperties = [HTTPCookiePropertyKey: Any]()
      cookieProperties[.name] = cookie.name
      cookieProperties[.value] = cookie.value
      cookieProperties[.domain] = cookie.domain
      cookieProperties[.path] = cookie.path
      cookieProperties[.version] = cookie.version
      cookieProperties[.expires] = Date().addingTimeInterval(31536000)

      let newCookie = HTTPCookie(properties: cookieProperties)
      HTTPCookieStorage.shared.setCookie(newCookie!)
      
      if outputPrint {
        print("cookie name: \(cookie.name) value: \(cookie.value)")
      }
    }
  }
  
  static func printSharedStorageCookies() -> Void {
    if let cookies = URLSession.shared.configuration.httpCookieStorage?.cookies {
      for cookie in cookies {
        print("name: \(cookie.name) value: \(cookie.value)")
      }
    } else {
      print("no shared configuration cookies available.")
    }
  }
}

class DelegateForRedirects: NSObject, URLSessionTaskDelegate {
  func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
    print("delegate activated")
    urlSession(session, task: task, willPerformHTTPRedirection: response, newRequest: request, completionHandler: completionHandler)
  }
}
