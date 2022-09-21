//
//  SharedPreferences.swift
//  KnurderLayout
//
//  Created by Dale Seng on 5/30/18.
//  Copyright © 2018 Sengsational. All rights reserved.
//

import Foundation

struct PreferenceKeys {
  // Presenation
  static let presentationModePref = "presentationModePref" 
  static let queryTastedPref = "queryTastedPref"
  static let queryGeographyPref = "queryGeographyPref"
  static let queryContainerPref = "queryContainerPref"
  
  // Logon
  static let authenticationNamePref = "cardNumberPref" //This represents the authentication name, not the card number
  static let storeNumberLogonPref = "storeNumberLogonPref"
  static let tastedCountPref = "tastedCountPref"
  static let userNamePref = "userNamePref"
  static let mouPref = "mouPref"
  static let emailOrUsername = "emailOrUsername"

  static let storeNumberPref = "storeNumberPref"
  static let storeNamePref = "storeNamePref"
  
  // Card Logon
  static let cardNumberPref = "cardNumberActualPref"
  static let cardPinPref = "cardPinPref"
  static let storeNumberCardauthPref = "storeNumberCardauthPref"

  // Quiz Control
  static let loadedUserPref = "loadedUserPref"
  static let emailPref = "emailPref"
  static let firstNamePref = "firstNamePref"
  static let lastNamePref = "lastNamePref"
  
  // Refresh Control
  static let lastListSecPref = "lastListSecPref"
  static let lastTastedSecPref = "lastTastedSecPref"
  static let lastQuizTimestampSecPref = "lastQuizTimestampSecPref"
  static let lastQuizPolledSecPref = "lastQuizPolledSecPref"
  
  // Usage Count
  static let timesRunCounter = "timesRunCounter"
  
  // Uber Eats
  static let uberEatsLinkPref = "uberEatsLinkPref"
  static let uberEatsHidePref = "uberEatsHidePref" // T or F

  // Tutorial Control
  static let firstRunTutorialPref = "firstRunTutorialPref"
  static let shakerTutorialPref = "shakerTutorialPref"
  static let positionTutorialPref = "positionTutorialPref"
  static let ocrBaseTutorialPref = "ocrBaseTutorialPref"
  static let takePictureTutorialPref = "takePictureTutorialPref"
  static let postReviewTutorialPref = "postReviewTutorialPref"
  static let tastedUploadTutorialPref = "tastedUploadTutorialPref"
  static let applicationAlertPref = "applicationAlertPref"
  static let analyticsTutorialPref = "analyticsTutorialPref"
  static let longpressTutorialPref = "longpressTutorialPref"

  // Text on Glass
  static let overlayColorPref = "overlayColorPref"
  
  // Settings
  static let hideMixPref = "hideMixPref"
  static let hideFlightPref = "hideFlightPref"
  static let currentPlatePref = "currentPlatePref"
  static let uploadReviewsPref = "uploadReviewsPref"
  
  // Last Query
  static let lastQueryIconKeyPref = "lastQueryIconKeyPref"
  static let lastQueryButtonPref = "lastQueryButtonPref"
  static let lastQuerySortByPref = "lastQuerySortByPref"
  static let lastQuerySortDirection = "lastQuerySortDirection"
  
}

struct PreferenceValues {
  // presentationModePref
  static let storePresentation = "storePresentation"
  static let userPresentation = "userPresentation"
  
  // booleans
  static let booleanTrue = "T"
  static let booleanFalse = "F"
}


class SharedPreferences {
  
  static func getInt(_ key: String, _ defaultValue: Int ) -> Int {
    var item = defaultValue
    let prefs = UserDefaults.standard
    if prefs.string(forKey: key) != nil {
      item = prefs.integer(forKey: key)
    }
    return item
  }
  
  static func putInt(_ key: String, _ value: Int) {
    let prefs = UserDefaults.standard
    prefs.set(value, forKey: key)
  }

  static func getString(_ key: String, _ defaultValue: String ) -> String {
    var item = defaultValue
    let prefs = UserDefaults.standard
    if prefs.string(forKey: key) != nil {
      item = prefs.string(forKey: key)!
    }
    return item
  }
  
  static func putString(_ key: String, _ value: String) {
    let prefs = UserDefaults.standard
    prefs.set(value, forKey: key)
  }
  
  static func removeByKey(_ key: String) {
    let prefs = UserDefaults.standard
    prefs.removeObject(forKey: key)
    
  }
  
  static func getCredentials() -> [String: String] {
    let emailOrUsername = SharedPreferences.getString(PreferenceKeys.emailOrUsername,"")
    let mou = SharedPreferences.getString(PreferenceKeys.mouPref,"0")
    let storeNumber = SharedPreferences.getString(PreferenceKeys.storeNumberPref,"00000")
    let password = getPasswordFromKeychain(emailOrUsername)
    return [
      Constants.CredentialsKey.emailOrUsername:emailOrUsername,
      Constants.CredentialsKey.password:password,
      Constants.CredentialsKey.mou:mou,
      Constants.CredentialsKey.storeNumber:storeNumber
    ]
  }
  static func getCardCredentials() -> [String: String] {
    let cardNumber = SharedPreferences.getString(PreferenceKeys.cardNumberPref,"")
    let storeNumberCardauth = SharedPreferences.getString(PreferenceKeys.storeNumberCardauthPref,"00000")
    let pin = getPinFromKeychain(cardNumber)
    return [
      Constants.CredentialsKey.cardNumber:cardNumber,
      Constants.CredentialsKey.pin:pin,
      Constants.CredentialsKey.storeNumberCardauth:storeNumberCardauth
    ]
  }
  
  static func getUserDetails() -> [String: String] {
    let email = SharedPreferences.getString(PreferenceKeys.emailPref, "")
    let ufo = SharedPreferences.getString(PreferenceKeys.authenticationNamePref, "000000")
    let firstName = SharedPreferences.getString(PreferenceKeys.firstNamePref, "")
    let lastName = SharedPreferences.getString(PreferenceKeys.lastNamePref, "")
    let homeStore = SharedPreferences.getString(PreferenceKeys.storeNamePref, "")
    let emailOrUsername = SharedPreferences.getString(PreferenceKeys.emailOrUsername, "")
    return [
      Constants.UserDetailsKey.email: email,
      Constants.UserDetailsKey.UFO: ufo,
      Constants.UserDetailsKey.FirstName: firstName,
      Constants.UserDetailsKey.LastName: lastName,
      Constants.UserDetailsKey.homestore: homeStore,
      Constants.UserDetailsKey.emailOrUserName: emailOrUsername
    ]
  }
  
  static func getPasswordFromKeychain(_ userNameString: String) -> String {
    let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                kSecAttrAccount as String: userNameString,
                                kSecAttrServer as String: Constants.BaseUrl.server,
                                kSecMatchLimit as String: kSecMatchLimitOne,
                                kSecReturnAttributes as String: true,
                                kSecReturnData as String: true
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecSuccess {
      // the entry DID exist. Update the entry, even though it might not have changed, the password COULD have changed
      print("found the item in the keychain")
      if let existingItem = item as? [String: Any], let account = existingItem[kSecAttrAccount as String] as? String, let passwordData = existingItem[kSecValueData as String] as? Data, let password = String(data: passwordData, encoding: String.Encoding.utf8) {
        print("account: \(account)") // password: \(password)")
        return password
      }
    }
    print("password not found")
    return ""
  }
  
  static func getPinFromKeychain(_ cardNumberString: String) -> String {
    let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                kSecAttrAccount as String: cardNumberString,
                                kSecAttrServer as String: Constants.BaseUrl.cardauth,
                                kSecMatchLimit as String: kSecMatchLimitOne,
                                kSecReturnAttributes as String: true,
                                kSecReturnData as String: true
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecSuccess {
      // the entry DID exist. Update the entry, even though it might not have changed, the password COULD have changed
      print("found the item in the keychain")
      if let existingItem = item as? [String: Any], let pinAccount = existingItem[kSecAttrAccount as String] as? String, let pinData = existingItem[kSecValueData as String] as? Data, let pin = String(data: pinData, encoding: String.Encoding.utf8) {
        print("account: \(pinAccount)") // password: \(password)")
        return pin
      }
    }
    print("pin not found")
    return ""
  }

  static func removePassword() {
    let credentials = SharedPreferences.getCredentials()
    guard let userNameString: String =  credentials[Constants.CredentialsKey.emailOrUsername] else {
      return
    }
    let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                kSecAttrAccount as String: userNameString,
                                kSecAttrServer as String: Constants.BaseUrl.server,
                                kSecMatchLimit as String: kSecMatchLimitOne,
                                kSecReturnAttributes as String: true,
                                kSecReturnData as String: true
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecSuccess {
      // the entry DID exist. Delete the entry
      print("found the item in the keychain")
      let deleteQuery: [String: Any]  = [kSecClass as String: kSecClassInternetPassword,
                                         kSecAttrAccount as String: userNameString,
                                         kSecAttrServer as String: Constants.BaseUrl.server]
      let deleteStatus = SecItemDelete(deleteQuery as CFDictionary)
      if deleteStatus == errSecSuccess {
        print("password removed from the keychain")
      } else {
        print("failed to remove the password from the keychain \(deleteStatus)")
      }
    } else {
      print("password entry was not found")
    }
  }
  static func removePin() {
    let cardCredentials = SharedPreferences.getCardCredentials()
    guard let cardNumberString: String =  cardCredentials[Constants.CredentialsKey.cardNumber] else {
      return
    }
    let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                kSecAttrAccount as String: cardNumberString,
                                kSecAttrServer as String: Constants.BaseUrl.cardauth,
                                kSecMatchLimit as String: kSecMatchLimitOne,
                                kSecReturnAttributes as String: true,
                                kSecReturnData as String: true
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecSuccess {
      // the entry DID exist. Delete the entry
      print("found the item in the keychain")
      let deleteQuery: [String: Any]  = [kSecClass as String: kSecClassInternetPassword,
                                         kSecAttrAccount as String: cardNumberString,
                                         kSecAttrServer as String: Constants.BaseUrl.cardauth]
      let deleteStatus = SecItemDelete(deleteQuery as CFDictionary)
      if deleteStatus == errSecSuccess {
        print("pin removed from the keychain")
      } else {
        print("failed to remove the pin from the keychain \(deleteStatus)")
      }
    } else {
      print("pin entry was not found")
    }
  }

  static func saveValidCredentials(_ credentials: [String: String]) {
    guard let userNameString = credentials[Constants.CredentialsKey.emailOrUsername], let passwordString = credentials[Constants.CredentialsKey.password] else { return }
    
    print("saveValidCredentials \(userNameString) / \(passwordString)")
    let mouString = credentials[Constants.CredentialsKey.mou]
    let storeNumberString = credentials[Constants.CredentialsKey.storeNumber]
    
    // This user name, etc, has been accepted by the server, so save it in shared preferences
    SharedPreferences.putString(PreferenceKeys.userNamePref, userNameString)
    SharedPreferences.putString(PreferenceKeys.emailOrUsername, userNameString)
    SharedPreferences.putString(PreferenceKeys.mouPref, mouString!)
    SharedPreferences.putString(PreferenceKeys.storeNumberLogonPref, storeNumberString!)
    
    // Now work on the password in the keychain
    
    // first check for existing entry in the keychain
    let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                kSecAttrAccount as String: userNameString,
                                kSecAttrServer as String: Constants.BaseUrl.server,
                                kSecMatchLimit as String: kSecMatchLimitOne,
                                kSecReturnAttributes as String: true,
                                kSecReturnData as String: true
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecSuccess {
      // the entry DID exist. Update the entry, even though it might not have changed, the password COULD have changed
      print("found the item in the keychain")
      if let existingItem = item as? [String: Any], let account = existingItem[kSecAttrAccount as String] as? String, let passwordData = existingItem[kSecValueData as String] as? Data, let _ = String(data: passwordData, encoding: String.Encoding.utf8) {
        print("account: \(account)") // password: \(password)")
      }
      let passwordData = passwordString.data(using: String.Encoding.utf8)!
      let updateQuery: [String: Any]  = [kSecClass as String: kSecClassInternetPassword,
                                         kSecAttrAccount as String: userNameString,
                                         kSecAttrServer as String: Constants.BaseUrl.server]
      let updateAttributes: [String: Any] = [kSecAttrAccount as String: userNameString,
                                             kSecAttrServer as String: Constants.BaseUrl.server,
                                             kSecValueData as String: passwordData]
      let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
      if updateStatus == errSecSuccess {
        print("userid password updated in keychain")
      } else {
        print("failed to update password in keychain \(updateStatus)")
      }
    } else {
      // the entry DID NOT exist, so create it
      print("item NOT found in the keychain")
      let passwordData = passwordString.data(using: String.Encoding.utf8)!
      let addQuery: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                     kSecAttrAccount as String: userNameString,
                                     kSecAttrServer as String: Constants.BaseUrl.server,
                                     kSecValueData as String: passwordData]
      let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
      if addStatus == errSecSuccess {
        print("userid password added to keychain")
      } else {
        print("userid password failed to get added to keychain \(addStatus)")
      }
    }
  }

  static func saveValidCardCredentials(_ credentials: [String: String]) {
    guard let cardNumberString = credentials[Constants.CredentialsKey.cardNumber], let pinString = credentials[Constants.CredentialsKey.pin] else { return }
    
    print("saveValidCardCredentials \(cardNumberString) / \(pinString)")
    let storeNumberCardAuthString = credentials[Constants.CredentialsKey.storeNumberCardauth]
    
    // This user name, etc, has been accepted by the server, so save it in shared preferences
    SharedPreferences.putString(PreferenceKeys.cardNumberPref, cardNumberString)
    SharedPreferences.putString(PreferenceKeys.storeNumberCardauthPref, storeNumberCardAuthString!)
    
    // Now work on the password in the keychain
    
    // first check for existing entry in the keychain
    let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                kSecAttrAccount as String: cardNumberString,
                                kSecAttrServer as String: Constants.BaseUrl.cardauth,
                                kSecMatchLimit as String: kSecMatchLimitOne,
                                kSecReturnAttributes as String: true,
                                kSecReturnData as String: true
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecSuccess {
      // the entry DID exist. Update the entry, even though it might not have changed, the password COULD have changed
      print("found the item in the keychain")
      if let existingItem = item as? [String: Any], let account = existingItem[kSecAttrAccount as String] as? String, let pinData = existingItem[kSecValueData as String] as? Data, let _ = String(data: pinData, encoding: String.Encoding.utf8) {
        print("account: \(account)") // password: \(password)")
      }
      let pinData = pinString.data(using: String.Encoding.utf8)!
      let updateQuery: [String: Any]  = [kSecClass as String: kSecClassInternetPassword,
                                         kSecAttrAccount as String: cardNumberString,
                                         kSecAttrServer as String: Constants.BaseUrl.cardauth]
      let updateAttributes: [String: Any] = [kSecAttrAccount as String: cardNumberString,
                                             kSecAttrServer as String: Constants.BaseUrl.cardauth,
                                             kSecValueData as String: pinData]
      let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
      if updateStatus == errSecSuccess {
        print("cardnumber pin updated in keychain")
      } else {
        print("failed to update pin in keychain \(updateStatus)")
      }
    } else {
      // the entry DID NOT exist, so create it
      print("item NOT found in the keychain")
      let pinData = pinString.data(using: String.Encoding.utf8)!
      let addQuery: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                     kSecAttrAccount as String: cardNumberString,
                                     kSecAttrServer as String: Constants.BaseUrl.cardauth,
                                     kSecValueData as String: pinData]
      let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
      if addStatus == errSecSuccess {
        print("cardnumber pin added to keychain")
      } else {
        print("cardnumber ping failed to get added to keychain \(addStatus)")
      }
    }
  }

  static func saveUserStats(_ userStats: [String: String]?) {
    if let stats = userStats {
      for stat in stats {
        let prefKey = stat.key + "Pref"
        SharedPreferences.putString(prefKey, stat.value)
        print("saved \(prefKey):\(stat.value)")
      }
    }
  }
  
  static func getQueryText() -> String {
    let queryButton = SharedPreferences.getString(PreferenceKeys.lastQueryButtonPref, Constants.QUERY_CUSTOM)
    if queryButton == Constants.QUERY_CUSTOM {
      let iconState = SharedPreferences.getString(PreferenceKeys.lastQueryIconKeyPref,"BBB")
      return Constants.QUERY_BUTTON_DICTIONARY[iconState]!
    } else if queryButton == Constants.QUERY_FLAGGED {
      return "Flagged Beers"
    } else if queryButton == Constants.QUERY_JUST_LANDED {
      return "Just Landed Beers"
    }
    return ""
  }
  
  static func homeStoreLoaded() -> Bool {
    let loadedStoreNumber = SharedPreferences.getString(PreferenceKeys.storeNumberPref, "")
    let loginStoreNumber = SharedPreferences.getString(PreferenceKeys.storeNumberLogonPref, "")
    if (loadedStoreNumber.count < 5 || loginStoreNumber.count < 5) {
      print("unexpected pull from preferences: [\(loadedStoreNumber)] [\(loginStoreNumber)]")
      return true
    }
    print("loaded: [\(loadedStoreNumber)] logon: [\(loginStoreNumber)]")
    return loadedStoreNumber == loginStoreNumber
  }
}
