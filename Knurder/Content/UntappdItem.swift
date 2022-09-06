//
//  UntappdItem.swift
//  Knurder
//
//  Created by Dale Seng on 8/26/22.
//  Copyright © 2022 Sengsational. All rights reserved.
//
import Foundation

class UntappdItem {

  init(nvpDictionary: [String: String]) {
      beerName = nvpDictionary["beerName"]
      breweryName = nvpDictionary["breweryName"]
      ounces = nvpDictionary["ounces"]
      price = nvpDictionary["price"]
      abv = nvpDictionary["abv"]
      beerNumber = nvpDictionary["beerNumber"]
      breweryNumber = nvpDictionary["breweryNumber"]
  }
  
  var beerName: String? {
    didSet(aValue) {
      guard let _beerName = beerName else {
        return
      }
      if _beerName == "null" { self.beerName = "" }
      else { self.beerName = _beerName }
    }
  }
  
  var breweryName: String? {
    didSet(aValue) {
      guard let _breweryName = breweryName else {
        return
      }
      if _breweryName == "null" { self.breweryName = "" }
      else { self.breweryName = _breweryName }
    }
  }

  var ounces: String? {
    didSet(aValue) {
      guard let _ounces = ounces else {
        return
      }
      if _ounces == "null" { self.ounces = "" }
      else { self.ounces = _ounces }
    }
  }

  var price: String? {
    didSet(aValue) {
      guard let _price = price else {
        return
      }
      if _price == "null" { self.price = "" }
      else { self.price = _price }
    }
  }

  var abv: String? {
    didSet(aValue) {
      guard let _abv = abv else {
        return
      }
      if _abv == "null" { self.abv = "" }
      else { self.abv = _abv }
    }
  }

  var beerNumber: String? {
    didSet(aValue) {
      guard let _beerNumber = beerNumber else {
        return
      }
      if _beerNumber == "null" { self.beerNumber = "" }
      else { self.beerNumber = _beerNumber }
    }
  }

  var breweryNumber: String? {
    didSet(aValue) {
      guard let _breweryNumber = breweryNumber else {
        return
      }
      if _breweryNumber == "null" { self.breweryNumber = "" }
      else { self.breweryNumber = _breweryNumber }
    }
  }
  public var description: String {
    return "beerName: \(beerName as Optional), breweryName: \(breweryName as Optional), ounces: \(ounces as Optional), price: \(price as Optional), abv: \(abv as Optional), beerNumber: \(beerNumber as Optional), brewryNumber: \(breweryNumber as Optional)"
  }

  public func getMatchingValues() -> [String] {
    let values:[String] = [getBeerName(), getBreweryName(), getBeerNumber(), getBreweryNumber(), getOuncesNumber(), getPriceNumber(), getAbvNumber()]
    return values
  }

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
  public func getNvpDictionaryForDb(saucerBeerId: String, saucerName: String, saucerStore: String) -> Dictionary<String,String> {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy MM dd"
    let lastUpdated = formatter.string(from: Date())

    let dbDictionary:[String:String] = [
      "name":saucerName,                      //Saucer beer name (assigned later)
      "store_id":saucerStore,                 //Saucer store (assigned later)
      "brew_id":saucerBeerId,                 //Saucer beer key (assigned later)
      "glass_size":getOuncesNumber(),         //Untapped ounces
      "glass_price":getPriceNumber(),         //Untappd price
      "added_now_flag":"Y",                   //Managed during load
      "last_updated_date":lastUpdated,        //Managed during load
      "abv":getAbvNumber(),                   //Untappd abv
      "untappd_beer":getBeerNumber(),         //Untappd beer key
      "untappd_brewery":getBreweryNumber()    //Untappd brewery key
    ]
    return dbDictionary
  }
  
  public func getBeerName() -> String {
    if let _beerName = beerName {
      return _beerName
    } else {
      return ""
    }
  }
  public func getBreweryName() -> String {
    if let _breweryName = breweryName {
      return _breweryName
    } else {
      return ""
    }
  }
  public func getBeerNumber() -> String {
    if let _beerNumber = beerNumber {
      return _beerNumber
    } else {
      return ""
    }
  }
  public func getBreweryNumber() -> String {
    if let _breweryNumber = breweryNumber {
      return _breweryNumber
    } else {
      return ""
    }
  }
  public func getOuncesNumber() -> String {
    if let _ounces = ounces {
      return _ounces.replaceAll(of: "[^0-9.]", with:"")
    } else {
      return ""
    }
  }
  public func getPriceNumber() -> String {
    if let _price = price {
      return _price.replaceAll(of: "[^0-9.]", with:"")
    } else {
      return ""
    }
  }
  public func getAbvNumber() -> String {
    if var _abv = abv {
      _abv = _abv.replacingOccurrences(of: "%", with: "")
      _abv = _abv.replacingOccurrences(of: "ABV", with: "")
      return _abv.trim()
    } else {
      return ""
    }

  }

}
