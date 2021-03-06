//
//  Constants.swift
//  KnurderLayout
//
//  Created by Dale Seng on 5/30/18.
//  Copyright © 2018 Sengsational. All rights reserved.
//

import Foundation
struct Constants {

  struct Http {
    static let getHeaders = [
      "Host": "www.beerknurd.com",
      "User-Agent": "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:52.0) Gecko/20100101 Firefox/52.0",
      "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      "Accept-Language": "en-US,en;q=0.5",
      "Accept-Encoding": "gzip, deflate, br",
      "Connection": "keep-alive",
      "Upgrade-Insecure-Requests": "1"
    ]
    
    static let postHeaders = [
      "Host": "www.beerknurd.com",
      "User-Agent": "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:52.0) Gecko/20100101 Firefox/52.0",
      "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      "Accept-Language": "en-US,en;q=0.5",
      "Referer": "http://www.beerknurd.com/user",
      "Connection": "keep-alive",
      "Content-Type": "application/x-www-form-urlencoded"
    ]
  }

  static let QUERY_BUTTON_DICTIONARY = [
    "BBB" : "All Beers",
    "BBL" : "All Local Beers",
    "BBR" : "All Imported Beers",
    "BLB" : "All Tasted Beers",
    "BLL" : "All Local Tasted Beers",
    "BLR" : "All Tasted Imported Beers",
    
    "BRB" : "Untasted Beers",
    "BRL" : "Untasted Local Beers",
    "BRR" : "Untasted Imported Beers",
    "LBB" : "All Taps",
    "LBL" : "Local Taps",
    "LBR" : "Imported Taps",
    
    "LLB" : "Tasted Taps",
    "LLL" : "Tasted Local Taps",
    "LLR" : "Tasted Imported Taps",
    "LRB" : "Untasted Taps",
    "LRL" : "Untasted Local Taps",
    "LRR" : "Untasted Imported Taps",
    
    "RBB" : "All Bottles",
    "RBL" : "Local Bottles",
    "RBR" : "Imported Bottles",
    "RLB" : "Tasted Bottles",
    "RLL" : "Tasted Local Bottles",
    "RLR" : "Tasted Imported Bottles",
    
    "RRB" : "Untasted Bottles",
    "RRL" : "Untasted Local Bottles",
    "RRR" : "Untasted Imported Bottles"]

  struct CredentialsKey {
    static let emailOrUsername = "emailOrUsername"
    static let password = "password"
    static let mou = "mou"
    static let storeNumber = "storeNumber"
  }
  
  struct UserDetailsKey {
    static let email = "email"
    static let UFO = "UFO"
    static let FirstName = "FirstName"
    static let LastName = "LastName"
    static let homestore = "homestore"
    static let emailOrUserName = "emailOrUsername"
  }
  
  struct BaseUrl {
    static let server = "www.beerknurd.com"
    static let locations = "https://www.beerknurd.com/locations"
    static let loginForm = "https://www.beerknurd.com/user"
    static let tasted = "https://www.beerknurd.com/api/tasted/list_user"
    static let active = "https://www.beerknurd.com/api/brew/list"
    static let logout = "https://www.beerknurd.com/user/logout"
    static let quizPage = "https://www.saucerknurd.com/glassnite/quiz/"
    static let quizUserLandingPage = "http://www.saucerknurd.com/glassnite/beerknurd-glassnite.php?"
  }
  
  struct Messages {
    static let GOOD_BEER_LIST = "You've got the current beer list!"
    static let GOOD_TASTED_LIST = "You've got your tasted list!"
  }
  
  static let ONE_DAY_IN_SECONDS = 24 * 60 * 60
  
  static let QUERY_JUST_LANDED = "queryJustLanded"
  static let QUERY_FLAGGED = "queryFlagged"
  static let QUERY_CUSTOM = "queryCustom"
  
  // SQL column names
  static let SORT_NAME = "name"
  static let SORT_ABV = "cast(abv as number)"
  static let SORT_STYLE = "style"
  static let SORT_TASTED_DATE = "created_date"
  static let SORT_ASC = "asc"
  static let SORT_DESC = "desc"
  
  static let KNURDER_MENTION_THANKS = [
    "Thanks for spreading the word!",
    "Glad to see you're lovin' the Knurder",
    "Props to you for telling your fellow knurds about Knurder :)",
    "You are fantastic!  Knurder gods smile upon thee",
    "Wow! You are the best!  Spreading the Knurder love.",
    "Knurder gets a mention! Noice!  :)",
    "Thanks for putting 'Knurder' in your review.  Karma is a thing.",
    "Beer gods smile upon thee.",
    "Who knows how many beer knurds will read your review, but if they do, they'll learn about Knurder! Thanks!"
  ]

}
