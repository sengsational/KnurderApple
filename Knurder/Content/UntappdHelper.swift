//
//  UntappdHelper.swift
//  Knurder
//
//  Created by Dale Seng on 8/31/22.
//  Copyright © 2022 Sengsational. All rights reserved.
//

import Foundation
import SwiftSoup

class UntappdHelper {
  static var untappdItemArray = [UntappdItem]()
  static func refreshMenuList(rawItems: String, storeNumber: String, storeName: String) -> String {
    print("refreshMenuList starting")
    var successfulLoad = false
    
    // #0 Fix escaped characters
    var untappdData = rawItems.replaceAll(of:"\\\\\\\"", with:"\"")
    untappdData = untappdData.replaceAll(of:"<\\\\", with:"<")
    untappdData = untappdData.replaceAll(of:"\\\\n", with:"")

    if let htmlLocIndex = untappdData.index(of:"container.innerHTML") {
      print("untappdData clipped from " + String(untappdData.count))
      untappdData = String(untappdData.suffix(from: htmlLocIndex))
      print("untappdData clipped to " + String(untappdData.count))
    } else {
      print("untappdData not clipped " + String(untappdData.count))
      // Leave it.. it might still work
    }
    guard let firstHtmlLocIndex = untappdData.index(of: "<") else { return "ERROR: No html found"}

    // **** TOXO: REMOVE SHORTENED AMOUNT OF DATA
    //guard let lastThingLocIndex = untappdData.index(of: "Exotic jewel") else { return "ERROR: No ending key found"}
    //untappdData = "<html><body>" + String(untappdData[firstHtmlLocIndex ... lastThingLocIndex]) + "</p></div></div></div></div></div></body></html>"

    // FULL DATA TOXO: UNCOMMENT THE NEXT TWO LINES
    guard let lastThingLocIndex = untappdData.index(of: "menu-title\">Bottles") else { return "ERROR: No ending key found"}
    untappdData = "<html><body>" + String(untappdData[firstHtmlLocIndex ... lastThingLocIndex]) + "</body></html>"

    //print("firstHtmlLoc " + String(firstHtmlLocIndex.encodedOffset) + " lastThingLoc " + String(lastThingLocIndex.encodedOffset))
    //print("unappdData length [" + String(untappdData.count) + "]")
    
    
    // #2 Get beer list elements from html
    do {
      let doc: Document = try SwiftSoup.parse(Parser.unescapeEntities(untappdData, true))
      var changable = "item"
      var untappdHtmlElementList = try doc.getElementsByClass(changable)
      if (untappdHtmlElementList.size() == 0) {
        changable = "beer"
        print("<<<<<<<<<<<<<NEVER>>>>>>>>>>>>>>>");
        untappdHtmlElementList = try doc.getElementsByClass(changable)
      }
      let beerListSize = untappdHtmlElementList.size()
      print("there were " + String(beerListSize) + " elements in the untappd data")
      
      // #3 *** sanity check of elements count
      guard beerListSize > 3 else {
        print("ERROR: There were too few items.")
        return "ERROR: There were too few items."
      }
      
      for htmlBeerElement in untappdHtmlElementList {
        let changableThing = changable
        let untappdNvpDictionary = getNvpDictionaryFromHtml(htmlBeerElement: htmlBeerElement, changable: changableThing)
        let untappdItem = UntappdItem(nvpDictionary: untappdNvpDictionary)
        //print("untappdItem: " + untappdItem.description)
        if let beerName = untappdItem.beerName {
            //print("beerName " + beerName)
        }
        untappdItemArray.append(untappdItem)
      } // END - for each raw item
      successfulLoad = true
    } catch {
      print("ERROR: catch running in the loading of menu data")
      return "ERROR: catch block ran"
    }
    
    if (successfulLoad) {
      return("")
    } else {
      print("ERROR: unsuccessful load")
      return("ERROR: unsuccessful load")
    }
  }
  
  public static func getUntappdItemList () -> [UntappdItem] {
    return untappdItemArray
  }

  // MARK: Functions for loading from SwiftSoup element
 
  public static func getNvpDictionaryFromHtml (htmlBeerElement: Element, changable: String) -> [String: String] {
    var beerName = ""
    var breweryName = ""
    var ounces = ""
    var price = ""
    var abv = ""
    var beerNumber = ""
    var breweryNumber = ""
    do {
      //print("DEBUG: beer element [" + (try beer.html()) + "]")
      
      //print("DEBUG: looking for [" + changable + "-name] in the Element")
      let beerNameElement = try htmlBeerElement.getElementsByClass(changable + "-name").first()
      //guard let paragraphElement = try beerNameElement?.getElementsByTag("p").first() else {
      //  print("problem with paragraph element")
      //  return [String:String]()
      //}
      //let debugString = try paragraphElement.html()
      //print("paragraph element " + debugString)
      
      guard let anchorElement = try beerNameElement?.getElementsByTag("a").first() else {
        print("problem with anchor element")
        return [String:String]()
      }
      beerName = try anchorElement.text()
      let urlString = try anchorElement.attr("href") // blah/blah/123  << want the 123
      let bits = urlString.split(separator: "/")
      
      if let beerNumberInt = Int(bits[bits.count - 1]) {
        beerNumber = String(beerNumberInt)
      } else {
        print("problem getting int value for untapped item")
        return [String:String]()
      }
      let metaElement = try beerNameElement?.getElementsByClass(changable + "-meta").first()
      if let metaElementGood = metaElement {
        let abvElement = try metaElementGood.getElementsByClass(changable + "abv").first()
        if let abvElementGood = abvElement {
          abv = try abvElementGood.text()
        }
      }

      let breweryNameElement = try htmlBeerElement.getElementsByClass("brewery").first()
      if let breweryNameElementGood = breweryNameElement {
        breweryName = try breweryNameElementGood.text()
        let breweryAnchor = try breweryNameElementGood.getElementsByTag("a").first()
        if let breweryAnchorGood = breweryAnchor {
          let breweryUrlString = try breweryAnchorGood.attr("href")
          let breweryBits = breweryUrlString.split(separator: "/")
          if let breweryNumberInt = Int(breweryBits[breweryBits.count - 1]) {
            breweryNumber = String(breweryNumberInt)
          } else {
            print("problem getting int value for untappd brewery")
            return [String:String]()
          }
        }
      }
      
      do {
        let typeElement = try htmlBeerElement.getElementsByClass("type").first()
        if let typeElementGood = typeElement {
          ounces = try typeElementGood.text()
        }
      } catch {
        // Not essential
      }

      do {
        let priceElement = try htmlBeerElement.getElementsByClass("price").first()
        if let priceElementGood = priceElement {
          price = try priceElementGood.text().replaceAll(of: "\\\\",with:"")
        }
      } catch {
        // Not essential
      }
      
      let nvpDictionary:[String:String] = [
        "beerName": beerName,
        "breweryName":breweryName,
        "ounces":ounces,
        "price":price,
        "abv":abv,
        "beerNumber":beerNumber,
        "breweryNumber":breweryNumber
      ]
      //print("untappd beer: " + nvpDictionary["beerName"]!)
      
      return nvpDictionary
      
    } catch {
      print("THIS NEEDS TO BE FIXED : failed trying to get stuff out of Jsoup element.")
    }
    return [String:String]()
  }

}
