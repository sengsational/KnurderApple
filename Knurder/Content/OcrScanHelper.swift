//
//  OcrScanHelper.swift
//  Knurder
//
//  Created by Dale Seng on 8/31/22.
//  Copyright © 2022 Sengsational. All rights reserved.
//

import Foundation
import GRDB
class OcrScanHelper {

  static var matchGroup = MatchGroup.init()
  static var foundResults = [[String]]()
  static var storeNumberIn = ""

  static func matchUntappdItems(untappdItemArray: [UntappdItem], storeNumber: String) -> String {
    storeNumberIn = storeNumber
    matchGroup = matchGroup.load(allTapsNames: getAllTapsForMatching(), storeNumberIn: storeNumber)
    matchGroup = matchGroup.load(untappdItemArray: untappdItemArray)
    foundResults = matchGroup.match()
    
    
    return "shazam!"
  }
  
  static func getResults() -> [Int] {
    let populatedActiveTapsCount = updateFoundTaps()
    var resultsInts = [4, 4, 4]
    return resultsInts
  }
  
  static func updateFoundTaps() -> Int {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy MM dd"
    let lastUpdated = formatter.string(from: Date())
    do {
      try dbQueue.inDatabase({db in
        try db.execute("update UFOLOCAL set ADDED_NOW_FLAG = ''")
      })
    } catch {
        print("djammitch!")
    }
    
    for (_, aResult) in foundResults.enumerated() {
      let aBeerName = aResult[0]
      //let aBreweryName = aResult[1]
      let aGlassSize = aResult[2]
      let aPriceString = aResult[3]
      let aAbv = aResult[4]
      let aBeerNumber = aResult[5]
      let aBreweryNumber = aResult[6]

      // Look-up aBeerName in the UFO table
      let selectSaucerItem = "SELECT * FROM ufo WHERE active = ? and container = ? and style <> ? and style <> ? and store_id = ? and name = ?"
      let args = StatementArguments(["T","draught","Mix","Flight",storeNumberIn,aBeerName])
      do {
        try dbQueue.inDatabase({db in
          let selectSaucerItemStatement = try db.makeSelectStatement(selectSaucerItem)
          guard let saucerItem = try SaucerItem.fetchOne(selectSaucerItemStatement, arguments: args) else {
            print("explosion happens here")
            return
          }
          // We found the beer, by name, in the UFO table.  Now we put the key into the UFOLOCAL table
          
          let dbDictionary:[String:String] = [
            "name":saucerItem.getBeerName(),                      //Saucer beer name (assigned later)
            "store_id":storeNumberIn,                 //Saucer store (assigned later)
            "brew_id":saucerItem.getBrewId(),                 //Saucer beer key (assigned later)
            "glass_size":aGlassSize,         //Untapped ounces
            "glass_price":aPriceString,         //Untappd price
            "added_now_flag":"Y",                   //Managed during load
            "last_updated_date":lastUpdated,        //Managed during load
            "abv":aAbv,                   //Untappd abv
            "untappd_beer":aBeerNumber,         //Untappd beer key
            "untappd_brewery":aBreweryNumber    //Untappd brewery key
          ]

          // push the contents of aResult (from foundResults) into UFOLOCAL table.  Up to this point, it's been in a memory object
          // along with untappd menu data, include the saucer's key too
          let menuDbItem = MenuDbItem.init(dbDictionary: dbDictionary)
          
          menuDbItem.loadOrUpdateDatabase() // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< DATABASE UPDATE FOR UFOLOCAL <<<<<<<<<<<<<<<<<<
        })
      } catch {
        print("jammitch")
      }
    } //End looping found result matches
    
    // The UFOLOCAL table is now updated with all of the matches.
    // We need to push the contents of the UFOLOCAL table into the UFO table
    
    do {
      try dbQueue.read({db in
        let menuRows = try Row.fetchAll(db, "SELECT *, rowid from UFOLOCAL")
        let limit = 5
        var count = 0
        for menuRow in menuRows {
          let brew_id = menuRow["brew_id"]
          let store_id = menuRow["store_id"]
          let abv = menuRow["abv"]
          //print("need to look-up the saucer item matching [" + String(brew_id) + " " + String(store_id) + " then add menu details glass size, price, etc, then save.")
          print (menuRow.description)
          
          // Look up matching saucer item
          if let row = try Row.fetchOne(db, "SELECT *, rowid from UFO where brew_id = ? and store_id = ?", arguments: [brew_id, store_id]) {
            // -------- record exists, update it -----------
            let saucerItem = SaucerItem(row: row)
            saucerItem.untappd_beer = menuRow["untappd_beer"]
            saucerItem.untappd_brewery = menuRow["untappd_brewery"]
            saucerItem.glass_size = menuRow["glass_size"]
            saucerItem.glass_price = menuRow["glass_price"]
            
            if let _abv = saucerItem.abv {
              print("abv on the saucer record was " + _abv + ", and the untappd record said " + abv.debugDescription)
            } else {
              print("no abv on the saucer record, but untappd record said " + abv.debugDescription)
            }
            
            try saucerItem.save(db) // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< Save updated saucer item to the database
            
            print("saucer item saved: " + saucerItem.description)
            
          } else {
            //print("ERROR: Did not find [" + menuRow["brew_id"] + "] in the UFO database")
            //print("ERROR: Did not find [" + String(brew_id) + " " + String(store_id) + "] in the UFO database")
          }
          
          count+=1
          if count > limit {
            break
          }
        }
      })
    } catch {
      print("well, yet another thing to do")
    }
    
    // TODO: get a cursor of all elements of the UFOLOCAL table.
    // TODO: for each element, use the store_id and brew_id to update (ie update UFO where store_id=? and brew_id=? set glass_size, glass_price, untappd_beer, untappd_brewery)
    
    return 0 // TODO: return the number of taps that have menu details
  }
  
  //TODO: Update function so that it performs a databaes query for all taps and returns appropriate fields in a string array
  static func getAllTapsForMatching() -> [[String]] {
    let tapOne:[String] = ["Highland Gaelic", "Highland Brewing Co.", "7228824"]
    let tapTwo:[String] = ["Bells Two Hearted Ale", "Bells Brewery", "7230770"]
    let tapThree:[String] = ["Olde Mecklenburg Copper", "Olde Mecklenburg Brewery", "7231033"]
    let tapFour:[String] = ["Sierra Nevada Pale Ale", "Sierra Nevada Brewing Co.", "7227893"]
    var allTaps = [[String]]()
    allTaps.append(tapOne)
    allTaps.append(tapTwo)
    allTaps.append(tapThree)
    allTaps.append(tapFour)
    return allTaps
  }

}
