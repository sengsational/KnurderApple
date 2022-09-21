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
  static var activeTapsCount = 0
  static var brewController: FetchedRecordsController<SaucerItem>!

  static func matchUntappdItems(untappdItemArray: [UntappdItem], storeNumber: String) -> [Int] {
    storeNumberIn = storeNumber
    matchGroup = matchGroup.load(allTapsNames: getAllTapsForMatching(), storeNumberIn: storeNumber)
    matchGroup = matchGroup.load(untappdItemArray: untappdItemArray)
    foundResults = matchGroup.match()
    return getResults()
  }
  
  static func getResults() -> [Int] {
    let populatedActiveTapsCount = updateFoundTaps()
    let resultsInts = [populatedActiveTapsCount, foundResults.count, activeTapsCount]
    return resultsInts
  }
  
  static func updateFoundTaps() -> Int {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy MM dd"
    let lastUpdated = formatter.string(from: Date())
    //var menuDbItemsToUpdate = [MenuDbItem]()
    do {
      try dbQueue.inDatabase({db in
        try db.execute("update UFOLOCAL set ADDED_NOW_FLAG = ''")
        //try db.execute("delete from UFOLOCAL")
        var insertCount = 0
        var updateCount = 0
        for (_, aResult) in foundResults.enumerated() {
          let aBeerName = aResult[0]
          let aGlassSize = aResult[1]
          let aPriceString = aResult[2]
          let aAbv = aResult[3]
          let aBeerNumber = aResult[4]
          let aBreweryNumber = aResult[5]

          // Look-up aBeerName in the UFO table
          let selectSaucerItem = "SELECT * FROM ufo WHERE active = ? and containerx = ? and style <> ? and style <> ? and store_id = ? and name = ?"
          let args = StatementArguments(["T","draught","Mix","Flight",storeNumberIn,aBeerName])

          let selectSaucerItemStatement = try db.makeSelectStatement(selectSaucerItem)
          guard let saucerItem = try SaucerItem.fetchOne(selectSaucerItemStatement, arguments: args) else {
            print("explosion happens here")
            return
          }
          // We found the beer, by name, in the UFO table.  Now we put the key into the UFOLOCAL table

          // find and existing item in the UFOLOCAL table
          let selectMenuItem = "SELECT *, rowid from UFOLOCAL where untappd_beer = ? AND untappd_brewery = ?"
          let menuArgs = StatementArguments([aBeerNumber, aBreweryNumber])
          let selectMenuItemStatement = try db.makeSelectStatement(selectMenuItem)
          if let existingMenuItem = try MenuDbItem.fetchOne(selectMenuItemStatement, arguments: menuArgs) {
            //print("existing menu item ")// + existingMenuItem.id?.description)!)
            existingMenuItem.name = saucerItem.getBeerName()
            existingMenuItem.store_id = storeNumberIn
            existingMenuItem.brew_id = saucerItem.getBrewId()
            existingMenuItem.glass_size = aGlassSize
            existingMenuItem.glass_price = aPriceString
            existingMenuItem.added_now_flag = "Y"
            existingMenuItem.last_updated_date = lastUpdated
            existingMenuItem.abv = aAbv
            existingMenuItem.untappd_beer = aBeerNumber
            existingMenuItem.untappd_brewery = aBreweryNumber
            try existingMenuItem.save(db)
            updateCount += 1
          } else {
            //print("non existing menu item")
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
            //menuDbItemsToUpdate.append(menuDbItem)
            //menuDbItem.loadOrUpdateDatabase() // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< DATABASE UPDATE FOR UFOLOCAL <<<<<<<<<<<<<<<<<<
            try menuDbItem.save(db)
            insertCount += 1
          }
        } //End looping found result matches
        print("there were \(insertCount) items inserted to the UFOLOCAL menu database")
        print("there were \(updateCount) items updated in the UFOLOCAL menu database")
      })
   } catch {
     print("jammitch")
   }
    
    //for (_, menuDbItem)  in menuDbItemsToUpdate {
    //  menuDbItem.loadOrUpdateDatabase()
    //}
    
    // The UFOLOCAL table is now updated with all of the matches.
    // We need to push the contents of the UFOLOCAL table into the UFO table
    var saucerItemsToSave = [SaucerItem]()
    var count = 0
    do {
      try dbQueue.write({db in
        let menuRows = try Row.fetchAll(db, "SELECT *, rowid from UFOLOCAL")
        print("There were \(menuRows.count)  menuRows found in the UFOLOCAL table")
        var brew_id = ""
        var store_id = ""
        var abv = ""
        //var name = ""
        for menuRow in menuRows {
          brew_id = String.fromDatabaseValue(menuRow["brew_id"])!
          store_id = String.fromDatabaseValue(menuRow["store_id"])!
          //name = String.fromDatabaseValue(menuRow["name"])!
          abv = String.fromDatabaseValue(menuRow["abv"])!
          //print("need to look-up the saucer item matching [" + String(brew_id) + " " + String(store_id) + " then add menu details glass size, price, etc, then save.")
          //print ("menuRow print: " + menuRow.description)
          
          // Look up matching saucer item
          if let row = try Row.fetchOne(db, "SELECT *, rowid from UFO where brew_id = ? and store_id = ?", arguments: [brew_id, store_id]) {
            // -------- record exists, update it -----------
            let saucerItem = SaucerItem(row: row)
            saucerItem.untappd_beer = menuRow["untappd_beer"]
            saucerItem.untappd_brewery = menuRow["untappd_brewery"]
            saucerItem.glass_size = menuRow["glass_size"]
            saucerItem.glass_price = menuRow["glass_price"]
            
            if let _ = saucerItem.abv {
              //print("*** abv on the saucer record was " + _abv + ", and the untappd record said " + abv.debugDescription)
              if !("" == abv) {
                if "0" == saucerItem.abv {
                  //print("UPDATING THE SAUCER ABV!!! for " + name + " [" + abv + "]")
                  let abvString = "untappd" + abv
                  saucerItem.setAbvNumber(abvNumber: abvString)
                } else {
                  //print("no update required         for " + name + " [" + saucerItem.abv! + "]")
                }
              } else {
                //print ("saucer item had for " + name + " [" + saucerItem.abv! + "]")
              }
            } else {
              //print(">>> abv on the saucer record was , and the untappd record said " + abv.debugDescription)
            }
            
            //try saucerItem.save(db) // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< Save updated saucer item to the database
            
            //print("saucer item saved: " + saucerItem.description)
            saucerItemsToSave.append(saucerItem)
            count+=1
          } else {
            //print("ERROR: Did not find [" + menuRow["brew_id"] + "] in the UFO database")
            print("ERROR: Did not find [" + brew_id + " " + store_id + "] in the UFO database")
          }
        } // end for loop
        print("There were \(count) items processed. \(saucerItemsToSave.count) items in saucerItemsToSave")
      })
    } catch {
      print("error in updating the saucer item \(error)")
      
    }

    do {
      try dbQueue.inDatabase ({db in
        for (saucerItem) in saucerItemsToSave {
          try saucerItem.update(db)
        }
      })
    } catch {
     print("I've got to be doing this wrong")
    }
    
    do {
      let brewController = try! FetchedRecordsController(dbQueue, request: AppDelegate.getQueryInterfaceRequest())
      try! brewController.setRequest(sql: "Select *, rowid from UFO")
      try! brewController.performFetch()
      print("fetched " + String(brewController.sections[0].numberOfRecords) + " records.")
      let saucerItems = brewController.fetchedRecords
      for (saucerItem) in saucerItems {
        if let _ = saucerItem.untappd_beer, let _ = saucerItem.abv {
          //print("db read saucerItem " + saucerItem.getBeerName() + " "  + _untappdBeer + " " + _abv)
        } else {
          if let _ = saucerItem.abv {
            //print("db read saucerItem " + saucerItem.getBeerName() + " " + _abv)

          } else {
           //print("db read saucerItem " + saucerItem.getBeerName())
          }

        }
      }
    }
 
    return count
  }
 
  static func getAllTapsForMatching() -> [[String]] {
    var allTaps = [[String]]()
    
    let sqlString = "SELECT *, rowid  FROM ufo where containerx = 'draught' AND style <> 'Mix' AND style <> 'Flight' AND active = 'T'"
    do {
      try dbQueue.inDatabase { db in
        let activeRows = try Row.fetchAll(db, sqlString)
        print("active rows " + String(activeRows.count))
        activeTapsCount = activeRows.count
        for activeRow in activeRows {
          var aTap = [String]()
          let beerName = String.fromDatabaseValue(activeRow["name"])
          let breweryName = String.fromDatabaseValue(activeRow["brewer"])
          let beerNumber = String.fromDatabaseValue(activeRow["brew_id"])
          aTap.append(beerName!)
          aTap.append(breweryName!)
          aTap.append(beerNumber!)
          allTaps.append(aTap)
        }
      }
    } catch {
      print("Failed to get match keys from UFO table")
    }
    //let tapOne:[String] = ["Highland Gaelic", "Highland Brewing Co.", "7228824"]
    //let tapTwo:[String] = ["Bells Two Hearted Ale", "Bells Brewery", "7230770"]
    //let tapThree:[String] = ["Olde Mecklenburg Copper", "Olde Mecklenburg Brewery", "7231033"]
    //let tapFour:[String] = ["Sierra Nevada Pale Ale", "Sierra Nevada Brewing Co.", "7227893"]
    
    //allTaps.append(tapOne)
    //allTaps.append(tapTwo)
    //allTaps.append(tapThree)
    //allTaps.append(tapFour)
    print("There were " + String(allTaps.count) + " active taps pulled for matching")
    return allTaps
  }

}
