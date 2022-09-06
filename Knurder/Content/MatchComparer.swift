//
//  MatchComparer.swift
//  Knurder
//
//  Created by Dale Seng on 8/31/22.
//  Copyright © 2022 Sengsational. All rights reserved.
//

import Foundation

class MatchComparer {
  var saucerItem = MatchItem()
  var untappdItem = MatchItem()
  var cleanedSaucer = ""
  var cleanedUntappd = ""
  var lastTechnique = ""
  var populated = false

  init() {}
  
  init(_saucerItem: MatchItem, _untappdItem: MatchItem) {
    saucerItem = _saucerItem
    untappdItem = _untappdItem
    populated = true
  }
  
  func isPopulated() -> Bool {
    return populated
  }
  
  func isExactMatch() -> Bool {
    cleanedSaucer = saucerItem.getExactTextMatch()
    cleanedUntappd = untappdItem.getExactTextMatch()
    lastTechnique = "EXACT"
    //print("[" + cleanedSaucer + "][" + cleanedUntappd + "]" + String(cleanedSaucer == cleanedUntappd) + lastTechnique)
    return cleanedSaucer == cleanedUntappd
  }
  
  func isNonStyleMatch() -> Bool {
    if cleanedSaucer.isEmpty || cleanedUntappd.isEmpty {
      let _ = isExactMatch() // Populates fields
    }
    cleanedSaucer = saucerItem.getNonStyleTextMatch()
    cleanedUntappd = untappdItem.getNonStyleTextMatch()
    lastTechnique = "STYLE_REMOVED"
    //print("[" + cleanedSaucer + "][" + cleanedUntappd + "]" + String(cleanedSaucer == cleanedUntappd) + lastTechnique)
    return cleanedSaucer == cleanedUntappd
  }
  
  func isFullyContained() -> Bool {
    if cleanedSaucer.isEmpty || cleanedUntappd.isEmpty {
      let _ = isNonStyleMatch() // Populates fields
    }
    lastTechnique = "CONTAINED_ALL"
    if cleanedSaucer.contains(cleanedUntappd) || cleanedUntappd.contains(cleanedSaucer) {
      //print("[" + cleanedSaucer + "][" + cleanedUntappd + "] TRUE" + lastTechnique)
      return true
    } else {
      //print("[" + cleanedSaucer + "][" + cleanedUntappd + "]" + String(hasAllWords(stringOne: cleanedSaucer, stringTwo: cleanedUntappd)) + lastTechnique + "HASALL")
      return hasAllWords(stringOne: cleanedSaucer, stringTwo: cleanedUntappd)
    }
  }
  
  func hasAllWords(stringOne: String, stringTwo: String) -> Bool {
    let listOne = stringOne.components(separatedBy: " ")
    let listTwo = stringTwo.components(separatedBy: " ")
    
    var allFound = true
    for (_, word) in listOne.enumerated() {
      if let _ = listTwo.index(of: word) {
      } else {
        allFound = false
        break
      }
    }
    if allFound {
      return true
    }
    allFound = true
    for (_, word) in listTwo.enumerated() {
      if let _ = listOne.index(of: word) {
      } else {
        allFound = false
        break
      }
    }
    return allFound
  }
  
  func isFuzzyMatch(minValue: Float) -> Bool {
    let value = cleanedSaucer.levenshteinDistanceScore(to: cleanedUntappd, ignoreCase: true, trimWhiteSpacesAndNewLines: true)
    lastTechnique = "FUZZY_" + String(Float(round(value * 100)/100))
    return value > minValue
  }
  
  func getFuzzyMatchScore() -> Float {
    let value = cleanedSaucer.levenshteinDistanceScore(to: cleanedUntappd, ignoreCase: true, trimWhiteSpacesAndNewLines: true)
    lastTechnique = "FUZZY_" + String(Float(round(value * 100)/100))
    return value
  }
  
  func getLastTechnique() -> String {
    return lastTechnique
  }
  
  func getUntappdItem() -> MatchItem {
    return untappdItem
  }
  
  func getSaucerItem() -> MatchItem {
    return saucerItem
  }
  
  func getDebugCompare() -> String {
    return "saucer [" + saucerItem.beer + "] untappd [" + untappdItem.beer + "]"
  }
  
  
}
