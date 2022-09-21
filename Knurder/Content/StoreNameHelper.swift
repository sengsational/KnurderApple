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
    //(name: "Addison Flying Saucer", number: "13887", states: ["TX","Texas"]),
    (name: "Charlotte Flying Saucer", number: "13888", states: ["NC","North Carolina"]), //OK
    //(name: "Columbia Flying Saucer", number: "13878", states: ["SC","South Carolina"]),
    (name: "Cordova Flying Saucer", number: "13883", states: ["TN","Tennessee"]), //OK
    (name: "Cypress Waters Flying Saucer", number: "18686214", states: ["TX","Texas"]), //OK
    (name: "DFW Airport Flying Saucer", number: "18262641", states: ["TX","Texas"]), //OK
    (name: "Fort Worth Flying Saucer", number: "13891", states: ["TX","Texas"]), //OK
    (name: "Houston Flying Saucer", number: "13880", states: ["TX","Texas"]), //OK
    (name: "Kansas City Flying Saucer", number: "13892", states: ["MO","Missouri","KS","Kansas"]),
    (name: "Little Rock Flying Saucer", number: "13885", states: ["AR","Arkansas"]), //OK
    (name: "Memphis Flying Saucer", number: "13881", states: ["TN","Tennessee"]), //OK
    //(name: "Nashville Flying Saucer", number: "13886", states: ["TN","Tennessee"]),
    (name: "Raleigh Flying Saucer", number: "13877", states: ["NC","North Carolina"]), //OK
    (name: "San Antonio Flying Saucer", number: "13882", states: ["TX","Texas"]), //OK
    (name: "Sugar Land Flying Saucer", number: "13879", states: ["TX","Texas"]), //OK
    (name: "The Lake Flying Saucer", number: "13884", states: ["TX","Texas"]) //OK
  ]
  
  static var storesVarchar = [
    (number: "13888", abbreviation: "char"),
    (number: "13883", abbreviation: "cor"),
    (number: "18686214", abbreviation: "cypress"),
    (number: "18262641", abbreviation: "dfw"),
    (number: "13891", abbreviation: "fw"),
    (number: "13880", abbreviation: "hou"),
    (number: "13892", abbreviation: "kc"),
    (number: "13885", abbreviation: "lr"),
    (number: "99999", abbreviation: "moth"), //Weird that this is still in there.  The moth is not in the list of sites.
    (number: "13881", abbreviation: "mem"),
    (number: "13877", abbreviation: "ral"),
    (number: "13882", abbreviation: "sa"),
    (number: "13879", abbreviation: "sl"),
    (number: "13884", abbreviation: "lake"),
  ]

  static var storesTwochar = [
    (number: "13887", abbreviation: "ad"), // closed
    (number: "13888", abbreviation: "ch"),
    (number: "13878", abbreviation: "co"), // closed
    (number: "13883", abbreviation: "cv"),
    (number: "18686214", abbreviation: "cw"),
    (number: "18262641", abbreviation: "df"),
    (number: "13891", abbreviation: "fw"),
    (number: "13880", abbreviation: "ab"),
    (number: "13892", abbreviation: "kc"),
    (number: "13885", abbreviation: "lr"),
    (number: "99999", abbreviation: "xx"), //Weird that this is still in there.  The moth is not in the list of sites.
    (number: "13881", abbreviation: "mt"),
    (number: "13886", abbreviation: "nv"), // closed
    (number: "13877", abbreviation: "aa"),
    (number: "13882", abbreviation: "sa"),
    (number: "13879", abbreviation: "sl"),
    (number: "13884", abbreviation: "rh"),
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

  public static func lookupStoreTwochar(forNumber storeNumber: String) -> (String) {
    for storeTwochar in storesTwochar {
      if (storeTwochar.number == storeNumber) {
        return storeTwochar.abbreviation
      }
    }
    return "ch"
  }
  public static func lookupStoreVarchar(forNumber storeNumber: String) -> (String) {
    for storeVarchar in storesVarchar {
      if (storeVarchar.number == storeNumber) {
        return storeVarchar.abbreviation
      }
    }
    return "char"
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
        // TOXO: Make MY phone get an alert if there is a new store added!!
        print("send alert to phone for store needs to be added: \(item.key) \(item.value)")
      }
    }
  }
  
}
