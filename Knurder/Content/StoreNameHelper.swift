//
//  StoreNameHelper.swift
//  FirstDb
//
//  Created by Dale Seng on 5/15/18.
//  Copyright © 2018 Sengsational. All rights reserved.
//

import Foundation

public class StoreNameHelper {
  
  static var stores = [
    (name: "Addison Flying Saucer", number: "13887", states: ["TX","Texas"]),
    (name: "Charlotte Flying Saucer", number: "13888", states: ["NC","North Carolina"]),
    (name: "Columbia Flying Saucer", number: "13878", states: ["SC","South Carolina"]),
    (name: "Cordova Flying Saucer", number: "13883", states: ["TN","Tennessee"]),
    (name: "Cypress Waters Flying Saucer", number: "18686214", states: ["TX","Texas"]),
    (name: "DFW Airport Flying Saucer", number: "18262641", states: ["TX","Texas"]),
    (name: "Fort Worth Flying Saucer", number: "13891", states: ["TX","Texas"]),
    (name: "Houston Flying Saucer", number: "13880", states: ["TX","Texas"]),
    (name: "Kansas City Flying Saucer", number: "13892", states: ["MO","Missouri","KS","Kansas"]),
    (name: "Little Rock Flying Saucer", number: "13885", states: ["AR","Arkansas"]),
    (name: "Memphis Flying Saucer", number: "13881", states: ["TN","Tennessee"]),
    (name: "Nashville Flying Saucer", number: "13886", states: ["TN","Tennessee"]),
    (name: "Raleigh Flying Saucer", number: "13877", states: ["NC","North Carolina"]),
    (name: "San Antonio Flying Saucer", number: "13882", states: ["TX","Texas"]),
    (name: "Sugar Land Flying Saucer", number: "13879", states: ["TX","Texas"]),
    (name: "The Lake Flying Saucer", number: "13884", states: ["TX","Texas"])
  ]
  
  public static func printAll() {
    for store in stores {
      print("a store name: \(store.name)")
      print("a store numb: \(store.number)")
      let sArray = store.states
      for state in sArray {
        print("a state: \(state)")
      }
    }
  }
  
  public static func lookupStates(forName storeName: String) -> [String] {
    for store in stores {
      if (store.name == storeName) {
        return store.states
      }
      
    }
    return []
  }
  
  public static func lookupStates(forNumber storeNumber: String) -> [String] {
    for store in stores {
      //print("test: \(storeNumber) == \(store.number)")
      if (store.number == storeNumber) {
        return store.states
      }
    }
    return []
  }
  
  public static func lookupStoreNumber(forName storeName: String) -> (String) {
    for store in stores {
      if (store.name == storeName) {
        return store.number
      }
    }
    return "13888"
  }
  
  public static func lookupStoreName(forNumber storeNumber: String, urlStyle: Bool) -> (String) {
    for store in stores {
      if (store.number == storeNumber) {
        if urlStyle {
          var storeName = store.name.lowercased().replacingOccurrences(of: " ", with: "-").trimmingCharacters(in: .whitespaces)
          if storeName.hasPrefix("the-") {
            storeName = String(storeName.dropFirst(4))
          }
          return storeName
        } else {
          return store.name
        }
      }
    }
    return ""
  }
  
  public static func checkForNewStores(_ pageDic: [String:String], _ cardNumber: String) {
    definedStores: for item in pageDic {
      if ((item.key == "_none") || (item.key == "13889") || (item.key == "13890")) {continue} // 13889 and 13890 are Austin and St Louis, which closed
      var found  = false;
      for store in stores {
        if store.number == item.key {
          found = true
          continue definedStores
        }
      }
      if !found && cardNumber == "10126" {
        // TODO: Make MY phone get an alert if there is a new store added!!
        print("send alert to phone for store needs to be added: \(item.key) \(item.value)")
      }
    }
  }
  
}
