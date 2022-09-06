//
//  MatchItem.swift
//  Knurder
//
//  Created by Dale Seng on 8/31/22.
//  Copyright © 2022 Sengsational. All rights reserved.
//

import Foundation

class MatchItem {
  
  var source = ""
  var beer = ""
  var brewery = ""
  var beerNumber = ""
  var breweryNumber = ""
  var ounces = ""
  var price = ""
  var abv = ""
  
  var storeNumber = ""
  var breweryCleaned = ""
  var upperUniform = ""
  var nonStyleUniform = ""
  var saucerBeerName = ""
  
  public var description: String {
    return "source: \(source) beer: \(beer) brewery: \(brewery) beerNumber: \(beerNumber) breweryNumber: \(breweryNumber) ounces: \(ounces) price: \(price) abv: \(abv) storeNumber: \(storeNumber) breweryCleaned: \(breweryCleaned) upperUniform: \(upperUniform) nonStyleUniform: \(nonStyleUniform)"
  }
  
  init(){
    
  }
  
  init(saucerValues: [String], storeNumberIn: String) {
    source = "SAUCER"
    beer = saucerValues[0]
    brewery = saucerValues[1]
    beerNumber = saucerValues[2]
    storeNumber = storeNumberIn
    breweryCleaned = setCleanedBreweryAlt(_brewery: brewery)
  }

  init(matchingValues: [String]) {
    source = "UNTAPPD"
    beer = matchingValues[0]
    brewery = matchingValues[1]
    beerNumber = matchingValues[2]
    breweryNumber = matchingValues[3]
    ounces = matchingValues[4]
    price = matchingValues[5]
    abv = matchingValues[6]
    breweryCleaned = setCleanedBreweryAlt(_brewery: brewery)
  }

  static let BREWERY_CLEANING = [" Brewing Co. (Utah, Colorado)"," Brewing & Distilling Co.","  & Sons Brewing Company", " Brew's Brewing Company"," Brewers Cooperative"," Brewing Cooperative",
           " Brewing  Company"," Brewing Company","  & Sons Brewery", "Brewing Project","Privat-Brauerei "," de Brandandere"," Brewing Co-Op"," Hard Cider Co.", " Craft Brewery"," Hard Kombucha", "Brouwerij De "," Artisan Ales"," Beer Company", " Brewing Co."," Brewing Co","Hard Cider",
           " Ale Works"," Beerworks"," Salisbury","Bières de ","Brasserie "," Brau-haus"," Brewery -","Brouwerij "," Beer Co.", " Cider Co","Brauerei "," Beer Co"," Brew Co"," Brewery","Brewery "," Brewing"," Company"," & Sohn"," Cidery",
           " Brews"," & Sons", " & Son"," &Sons", " &Son"," Co-op"," Ales"," Beer "," Brau"," COOP"," Co."," LTD","The "]
  
  static let STYLE_REMOVE = ["IMPERIAL HAZY IPA", "BEER COMPANY", "WEST COAST IPA", "HEFEWEIZEN", "HARD CIDER","HEFE WEISS","IMPERIAL IPA", "HEFE WEIZEN", "SESSION SOUR","SESSION IPA","BEER CO.","BEER CO", "QUADRUPEL","TRIPEL", "BREWING", "HAZY PALE ALE", "IRISH ALE", "HAZY IPA", "PALE ALE", "PILSNER","PORTER", "KOLSCH", "LAGER", "SOUR", "CIDER","BEER ","HAZY","COOP", "GOSE", "QUAD", "HEFE", "PILS", "ALE", "IPA"]
  
  
  func setCleanedBreweryAlt(_brewery: String) -> String {
    var _breweryCleaned = _brewery.uppercased()
    for (_, companyText) in MatchItem.BREWERY_CLEANING.enumerated() {
      let upperCompany = companyText.uppercased()
      _breweryCleaned = _breweryCleaned.replaceAll(of: upperCompany, with: "")
      _breweryCleaned = _breweryCleaned.trim()
      _breweryCleaned = _breweryCleaned.replaceAll(of: "'S", with: "S")
    }
    return _breweryCleaned
  }
  
  func isSaucer() -> Bool {
    return source == "SAUCER"
  }
  
  func isUntappd() -> Bool {
    return source == "UNTAPPD"
  }
  
  func getExactTextMatch() -> String {
    if (isSaucer()) {
      upperUniform = beer.deAccent()
    } else if isUntappd() {
      upperUniform = (breweryCleaned + " " + beer).deAccent()
      //print("getExactTextMatch for untappd " + breweryCleaned + "< no extra stuff expected!!")
    } else {
      print("logic problem with isSaucer or isUntappd")
    }
    upperUniform = upperUniform.uppercased()
    upperUniform = upperUniform.replaceAll(of: "-", with: " ")
    upperUniform = upperUniform.replaceAll(of: "[^A-Z0-9 ]+", with: "")
    upperUniform = upperUniform.trim()
    upperUniform = upperUniform.replaceAll(of: " +", with: " ")
    return upperUniform
  }
  
  func getNonStyleTextMatch() -> String {
    var nonStyleLocal = upperUniform
    for (_, styleText) in MatchItem.STYLE_REMOVE.enumerated() {
      let _styleText = styleText.uppercased()
      nonStyleLocal = nonStyleLocal.replaceAll(of: _styleText, with: "")
      nonStyleLocal = nonStyleLocal.trim()
      nonStyleLocal = nonStyleLocal.replaceAll(of: " +", with: " ")
    }
    
    if !brewery.isEmpty {
      //print("[" + nonStyleLocal + "]" + String(nonStyleLocal.count) + " [" + breweryCleaned + "]" + String(breweryCleaned.count))
      let extraLengthBeyondBrewery = nonStyleLocal.count - breweryCleaned.count
      //print("extraLengthBeyondBrewery " + String(extraLengthBeyondBrewery))
      if extraLengthBeyondBrewery < 3 {
        //print("no style removal")
        //what's left after removing the brewery was too short
        nonStyleLocal = upperUniform  // return what we start with, no change
      } else {
        //print("style removed")
        //what's left after removing the brewery was substantial.  Use the work we did above.
      }
    }
    
    //print ("started with [" + upperUniform + "] ended with [" + nonStyleLocal +  "]")
    return nonStyleLocal
  }
  
  func getName() -> String {
    return beer
  }
  
  func setSaucerBeerName(_saucerBeerName: String) {
    saucerBeerName = _saucerBeerName
  }
  
  func getSaucerBeerName() -> String {
    return saucerBeerName
  }
  
  func getOriginal() -> String {
    if nonStyleUniform == "" {
      return getNonStyleTextMatch()
    }
    return "[" + source + ", " + beer + ", " + brewery + ", " + "{" + nonStyleUniform + "}]"
  }
  
  func matchFieldArray(saucerName: String) -> [String] {
    let fieldArray = [saucerName, ounces, price, abv, beerNumber, breweryNumber]
    return fieldArray
  }
  
}

// The purpose of this is to be able to remove items from an array because Swift only does it by index
extension MatchItem: Equatable {
  static func == (lhs: MatchItem, rhs: MatchItem) -> Bool {
    let theSame = (
        lhs.source == rhs.source &&
        lhs.beer == rhs.beer &&
        lhs.brewery == rhs.brewery &&
        lhs.beerNumber == rhs.beerNumber &&
        lhs.breweryNumber == rhs.breweryNumber
    )
    return theSame
  }

}
