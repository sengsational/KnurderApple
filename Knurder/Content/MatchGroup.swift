//
//  MatchGroup.swift
//  Knurder
//
//  Created by Dale Seng on 8/31/22.
//  Copyright © 2022 Sengsational. All rights reserved.
//

import Foundation

class MatchGroup {
  var untappdMatchItems = [MatchItem]()
  var saucerMatchItems = [MatchItem]()
  var foundResults = [[String]]()

  func load(untappdItemArray: [UntappdItem]) -> MatchGroup {
    for (_, untappdItem) in untappdItemArray.enumerated() {
      let matchingValues = untappdItem.getMatchingValues()
      let matchItem = MatchItem(matchingValues: matchingValues)
      untappdMatchItems.append(matchItem)
    }
    return self
  }
  
  func load(allTapsNames: [[String]], storeNumberIn: String) -> MatchGroup {
    for (_, tapName) in allTapsNames.enumerated(){
      let matchItem = MatchItem(saucerValues: tapName, storeNumberIn: storeNumberIn)
      saucerMatchItems.append(matchItem)
    }
    return self
  }
  
  func match() -> [[String]] {
    var saucerItemsFound = [MatchItem]()
    var untappdItemsFound = [MatchItem]()
    
    for (_, saucerItem) in saucerMatchItems.enumerated() {
      var fuzzyFoundList = [MatchComparer]()
      var found = false
      for (_, untappdItem) in untappdMatchItems.enumerated(){
        let comparer = MatchComparer(_saucerItem: saucerItem, _untappdItem: untappdItem)
        //print(">>>>> COMPARE <<<<<<<<<" + comparer.getDebugCompare())
        if comparer.isExactMatch() || comparer.isNonStyleMatch() {
          saucerItemsFound.append(saucerItem)
          untappdItemsFound.append(untappdItem)
          foundResults.append(untappdItem.matchFieldArray(saucerName: saucerItem.getName()))
          if let index = untappdMatchItems.index(where: {$0 == untappdItem}) {
            untappdMatchItems.remove(at: index)
          }
          found = true
          break
        }
        //print("Exact found was " + String(found) + " comparer technique " + comparer.getLastTechnique())
      }
      
      if (found) {
        //print("FOUND!!!!! " + saucerItem.getSaucerBeerName())
        continue // This saucer item has been found above, no need to continue
      }
      
      for (_, untappdItem) in untappdMatchItems.enumerated(){
        let comparer = MatchComparer(_saucerItem: saucerItem, _untappdItem: untappdItem)
        if (comparer.isFullyContained() || comparer.isHardMatch()) {
          saucerItemsFound.append(saucerItem)
          untappdItemsFound.append(untappdItem)
          foundResults.append(untappdItem.matchFieldArray(saucerName: saucerItem.getName()))
          if let index = untappdMatchItems.index(where: {$0 == untappdItem}) {
            untappdMatchItems.remove(at: index)
          }
          found = true
          break
        }
        if (!found && comparer.isFuzzyMatch(minValue: 0.7)) {
          let savedComparer = MatchComparer(_saucerItem: saucerItem, _untappdItem: untappdItem)
          _ = savedComparer.isNonStyleMatch() //Populates fields
          fuzzyFoundList.append(savedComparer)
        }
        //print("Fully contained found was " + String(found) + " comparer technique " + comparer.getLastTechnique())
      }

      // ^We have looped all of the untappd items against this saucer item, twice
      
      if !found && fuzzyFoundList.count > 0 {
        //We don't have a solid find, but we do have one or more fuzzy matches.  We want the best fuzzy match.
        var highestMatchComparer = MatchComparer()
        var highestScore:Float = 0;
        for (_, fuzzyComparer) in fuzzyFoundList.enumerated() {
          let score = fuzzyComparer.getFuzzyMatchScore()
          if score > highestScore {
            highestMatchComparer = fuzzyComparer
            highestScore = score
          }
        }
        if highestMatchComparer.isPopulated() {
          found = true
          saucerItemsFound.append(saucerItem)
          untappdItemsFound.append(highestMatchComparer.getUntappdItem())
          foundResults.append(highestMatchComparer.getUntappdItem().matchFieldArray(saucerName: saucerItem.getName()))
          if let index = untappdMatchItems.index(where: {$0 == highestMatchComparer.getUntappdItem()}) {
            untappdMatchItems.remove(at: index)
          }
          //print("Fuzzy contained found was " + String(found) + " comparer technique " + highestMatchComparer.getLastTechnique())

        }
        //print("FOUND>>> " + saucerItem.getSaucerBeerName())

      }
    } // End looping saucer items
    
    // Remove the items we found
    print("removing " + String(saucerItemsFound.count) + " from saucer list")
    for (_, saucerItemFound) in saucerItemsFound.enumerated() {
      if let index = saucerMatchItems.index(where: {$0 == saucerItemFound}) {
        saucerMatchItems.remove(at: index)
      }
    }
    print("removing " + String(untappdItemsFound.count) + " from untappd list")
    for (_, untappdItemFound) in untappdItemsFound.enumerated() {
      if let index = untappdMatchItems.index(where: {$0 == untappdItemFound}) {
        untappdMatchItems.remove(at: index)
      }
    }
    return foundResults
  }
}
