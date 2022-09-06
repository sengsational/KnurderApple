//
//  MenuDbItem.swift
//  Knurder
//
//  Created by Dale Seng on 9/2/22.
//  Copyright © 2022 Sengsational. All rights reserved.
//

import Foundation
import GRDB

class MenuDbItem: Record, CustomStringConvertible {
  

  /*
   t.column("name", .text).notNull()
   t.column("store_id", .text).notNull()
   t.column("brew_id", .text).notNull()
   t.column("glass_size", .text)
   t.column("glass_price", .text)
   t.column("added_now_flag", .text)
   t.column("last_updated_date", .text)
   t.column("abv", .text)
   t.column("untappd_beer", .text)
   t.column("untappd_brewery", .text)
   */
  init(untappdItem: UntappdItem, saucerBeerId: String, saucerName: String, saucerStore: String) {
    defer {
      let dbDictionary = untappdItem.getNvpDictionaryForDb(saucerBeerId: saucerBeerId, saucerName:saucerName, saucerStore: saucerStore)
      name = dbDictionary["name"]
      store_id = dbDictionary["store_id"]
      brew_id = dbDictionary["brew_id"]
      glass_size = dbDictionary["glass_size"]
      glass_price = dbDictionary["glass_price"]
      added_now_flag = dbDictionary["added_now_flag"]
      last_updated_date = dbDictionary["last_updated_date"]
      abv = dbDictionary["abv"]
      untappd_beer = dbDictionary["untappd_beer"]
      untappd_brewery = dbDictionary["untappd_brewery"]
      
    }
    super.init()
  }
  
  init(dbDictionary: [String: String]) {
    defer {
      name = dbDictionary["name"]
      store_id = dbDictionary["store_id"]
      brew_id = dbDictionary["brew_id"]
      glass_size = dbDictionary["glass_size"]
      glass_price = dbDictionary["glass_price"]
      added_now_flag = dbDictionary["added_now_flag"]
      last_updated_date = dbDictionary["last_updated_date"]
      abv = dbDictionary["abv"]
      untappd_beer = dbDictionary["untappd_beer"]
      untappd_brewery = dbDictionary["untappd_brewery"]
    }
    super.init()
  }

  // MARK: Record overrides
  override class var databaseTableName: String {
    return "ufolocal"
  }
  
  override class var databaseSelection: [SQLSelectable] {
    return [AllColumns(), Column.rowID]
  }
  
  required init(row: Row) {
    id = row["rowid"]
    name = row["name"]
    store_id = row["store_id"]
    brew_id = row["brew_id"]
    glass_size = row["glass_size"]
    glass_price = row["glass_price"]
    added_now_flag = row["added_now_flag"]
    last_updated_date = row["last_updated_date"]
    abv = row["abv"]
    untappd_beer = row["untappd_beer"]
    untappd_brewery = row["untappd_brewery"]
    super.init(row: row)
  }

  override func encode(to container: inout PersistenceContainer) {
      container["rowid"] = id
      container["name"] = name
      container["store_id"] = store_id
      container["brew_id"] = brew_id
      container["glass_size"] = glass_size
      container["glass_price"] = glass_price
      container["added_now_flag"] = added_now_flag
      container["last_updated_date"] = last_updated_date
      container["abv"] = abv
      container["untappd_beer"] = untappd_beer
      container["untappd_brewery"] = untappd_brewery
  }

  override func didInsert(with rowID: Int64, for column: String?) {
    id = rowID
  }

  //MARK: Class variables
  public var id: Int64?              //automatically assigned by database
  var name: String?
  var store_id: String?
  var brew_id: String?
  var glass_size: String?
  var glass_price: String?
  var added_now_flag: String?
  var last_updated_date: String?
  var abv: String?
  var untappd_beer: String?
  var untappd_brewery: String?

  public var description: String {
    return "_id: \(id as Optional),name: \(name as Optional), store_id: \(store_id as Optional), brew_id: \(brew_id as Optional), glassSize: \(glass_size as Optional), glassPrice: \(glass_price as Optional), added_now_flag: \(added_now_flag as Optional), last_updated: \(last_updated_date as Optional), abv: \(abv as Optional), untappd_beer: \(untappd_beer as Optional), untappd_brewery: \(untappd_brewery as Optional)"
  }
  
  //MARK: Database actions
  func loadOrUpdateDatabase() {
    try! dbQueue.inDatabase { db in
      try self.save(db)
    }
  }

}
