//
//  ViewController.swift
//  KnurderLayout
//
//  Created by Dale Seng on 5/26/18.
//  Copyright © 2018 Sengsational. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController, UIGestureRecognizerDelegate {

  @IBOutlet weak var tapButton: UIButton!
  @IBOutlet weak var bottleButton: UIButton!
  @IBOutlet weak var tastedButton: UIButton!
  @IBOutlet weak var untastedButton: UIButton!
  @IBOutlet weak var localButton: UIButton!
  @IBOutlet weak var worldButton: UIButton!
  
  @IBOutlet weak var queryButton: UIButton!
  @IBOutlet weak var ubereatsButton: UIButton!
  
  @IBOutlet weak var alternateLocationLabel: UILabel!
  @IBOutlet weak var tastedCountText: UILabel!
  @IBOutlet weak var pageHeadline: UILabel!
  @IBOutlet weak var rightSpacer: UIImageView!
  @IBOutlet weak var leftSpacer: UIImageView!
  
  var alertControllerActionString = ""
  // var longGesture = UILongPressGestureRecognizer()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let runDebug = arc4random() == 0 // FALSE
    //let runDebug = arc4random() > 0 // TRUE
    if runDebug {
      print("FOR DEBUG: Forcing presentation mode to new user")
      SharedPreferences.removeByKey(PreferenceKeys.presentationModePref)
      SharedPreferences.removeByKey(PreferenceKeys.storeNumberPref)
      SharedPreferences.removeByKey(PreferenceKeys.storeNamePref)
    }
    
    rightSpacer.tintColor = UIColor(named: "colorsetIconNotActive")
    leftSpacer.tintColor = UIColor(named: "colorsetIconNotActive")
    changeSelection(sender: queryButton)

    // First time through, no store will be selected and presentationModePref will be blank, so get user to select a store
    let lastPresentationMode = SharedPreferences.getString(PreferenceKeys.presentationModePref, "")
    if lastPresentationMode == "" {
      perform(#selector(presentStoresOverlay), with: nil, afterDelay: 0)
    } else if lastPresentationMode == PreferenceValues.storePresentation {
      setToStorePresentation()
    } else {
      setToUserPresentation()
    }
    // longGesture = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.longPress(_:)))
    // longGesture.minimumPressDuration = 1
    // pageHeadline.addGestureRecognizer(longGesture)
    // print("recognizer added")
  }
  
  /*
  @objc func longPress(_ sender: UILongPressGestureRecognizer) {
    print("longPress ran")
    let alertC = UIAlertController(title: "Long Press", message: "Long press gesture", preferredStyle: UIAlertControllerStyle.alert)
    let ok = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (alert) in
      
    }
    alertC.addAction(ok)
    self.present(alertC, animated:true, completion: nil)
    
  }
  */
  
  override func viewDidAppear(_ animated: Bool) {
    print("ViewController viewDidAppear()")
    let timesUsed = SharedPreferences.getInt(PreferenceKeys.timesRunCounter, 0)

    let applicationAlert = SharedPreferences.getString(PreferenceKeys.applicationAlertPref, "")
    let alertNeverPresented = applicationAlert == ""

    let authenticationNamePref = SharedPreferences.getString(PreferenceKeys.authenticationNamePref, "1")
    let isBrandNewUserOrNeverLoggedIn = authenticationNamePref == "1"
    
    var listUpdateAsked = false

    if alertNeverPresented && !isBrandNewUserOrNeverLoggedIn {
      SharedPreferences.putString(PreferenceKeys.applicationAlertPref, "DONE")
      let alertViewController = UIAlertController(title: "IMPORTANT LOGON INFORMATION", message: "If you haven't done so, please update your login to use your email address or usename.\n\nCard number is no longer going to work.\n\nClick settings > Log Out, then log on with your email or username.", preferredStyle: .alert)
      let okAction = UIAlertAction.init(title: "OK", style: .default) { (action) -> Void in
        
        if (CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: authenticationNamePref))) {
          SharedPreferences.putString(PreferenceKeys.authenticationNamePref, "")
        }
      }
      alertViewController.addAction(okAction)
      present(alertViewController, animated: true, completion: nil)
    } else if AppDelegate.oldListCheck { // always true on app startup
      listUpdateAsked = runOldListCheck()
      AppDelegate.oldListCheck = false
    }
    if SharedPreferences.getString(PreferenceKeys.mouLoginErrorPref, "") == "true" {
        SharedPreferences.putString(PreferenceKeys.mouLoginErrorPref, "false")
        // There was a log on attempt with MOU that failed.  Ask for help.
            print("alertMouLoginFailed() running")
            let message = "I am not able to test MOU login myself, because I'm not there yet.  If you really are an MOU and you want this to work, I probably can get it working if you help me.  Look up 'ufoknurder' on Facebook, or email me at knurder.frog4food@recursor.net"
            let alertDialog = UIAlertController(title: "MOU Logon Testing", message: message, preferredStyle: .alert)
            alertDialog.addAction(UIAlertAction(title: "OK", style: .default, handler: {(action: UIAlertAction!) in
              print("OK PRESSED")
            }))
          present(alertDialog, animated: true, completion: nil)
    } else {
      print("no mouLoginFailPreference")
    }
    if !listUpdateAsked && (timesUsed == 5 || timesUsed == 25 || timesUsed == 62 || timesUsed == 100) {
      AppDelegate.incrementUsageCounter(force: true)
      var title = "Tell Your Friends"
      var message = "Did you know that Knurder is availble on iPhone and Android?  Since it's unofficial, the only way people know is if YOU tell them! Tweet #knurder"
      if timesUsed == 25 {
        title = "Spread the Word"
        message = "You seem to be getting some mileage out the Knurder app, and I'm glad to see it.  Don't forget to spread the word...it's the only way your fellow beerknurds can find out about it."
      } else if timesUsed == 62 {
        title = "Knurder Wizard!"
        message = "Your a phD level Knurder user.  It's amazing how little feedback I get.  Please touch base on the Facebook \"ufoknurder\" page.  And don't forget to tell others about the app."
      } else if timesUsed == 100 {
        title = "You Are a Master!"
        message = "You probably know more about using Knurder than anybody!  It's amazing how little feedback I get.  Have you considered searching \"ufoknurder\" to find the Facebook page, then telling me what the next feature should be, or what you find annoying?"
      }
      let alertViewController = UIAlertController(title: title, message: message, preferredStyle: .alert)
      let okAction = UIAlertAction.init(title: "OK", style: .default) { (action) -> Void in
        //self.alertControllerActionString = "OK Welcome"
      }
      alertViewController.addAction(okAction)
      present(alertViewController, animated: true, completion: nil)
    }

    setUbereatsButtonVisibility()

  }
  
  func runQuizCheck() {
    // Don't do quiz check unless they're logged in as UFO member
    let presentationMode = SharedPreferences.getString(PreferenceKeys.presentationModePref, "")
    if presentationMode != PreferenceValues.userPresentation {
      return
    }
    
    // TOXO: REMOVE THIS AFTER I GET DONE TESTING
    //return
    
    // Only check the quiz once per day maximum
    let lastQuizPollSeconds = SharedPreferences.getInt(PreferenceKeys.lastQuizPolledSecPref , 0)
    let secondsSinceCheckedQuiz = Int(Date().timeIntervalSince1970) - lastQuizPollSeconds
    let needsQuizCheck = secondsSinceCheckedQuiz > Constants.ONE_DAY_IN_SECONDS
    if (needsQuizCheck) {
      print("Checking for quiz --------------------------------------------------------")
      TransactionDriver.checkForQuiz(SharedPreferences.getUserDetails(), self)
    }
  }
  
  func runOldListCheck() -> Bool {
    var alertPresented = false;
    let debugTestingTwoDays = 0 // Constants.ONE_DAY_IN_SECONDS * 2
    let presentationMode = SharedPreferences.getString(PreferenceKeys.presentationModePref, "")

    let lastListSeconds = SharedPreferences.getInt(PreferenceKeys.lastListSecPref , 0)
    let secondsSinceRefreshedList = Int(Date().timeIntervalSince1970) - lastListSeconds + debugTestingTwoDays
    let daysSinceRefreshedList = secondsSinceRefreshedList / Constants.ONE_DAY_IN_SECONDS
    let needsStoreListDialog = secondsSinceRefreshedList > Constants.ONE_DAY_IN_SECONDS
    
    let lastTastedSeconds = SharedPreferences.getInt(PreferenceKeys.lastTastedSecPref, 0)
    let secondsSinceRefreshedTasted = Int(Date().timeIntervalSince1970) - lastTastedSeconds + debugTestingTwoDays
    let daysSinceRefreshedTasted = secondsSinceRefreshedTasted / Constants.ONE_DAY_IN_SECONDS
    let needsTastedDialog = presentationMode == PreferenceValues.userPresentation && secondsSinceRefreshedTasted > Constants.ONE_DAY_IN_SECONDS
    
    if (needsStoreListDialog && needsTastedDialog) {
      let lastPresentationMode = SharedPreferences.getString(PreferenceKeys.presentationModePref, "")
      print("1lastPresentationMode \(lastPresentationMode)")
      alertPresented = true
      askAboutUpdatingBoth(daysSinceRefreshedList, daysSinceRefreshedTasted)
      
    } else if needsStoreListDialog {
      let lastPresentationMode = SharedPreferences.getString(PreferenceKeys.presentationModePref, "")
      print("2lastPresentationMode \(lastPresentationMode)")
      if lastPresentationMode == "" {
        setToStorePresentation()
        perform(#selector(presentStoresOverlay), with: nil, afterDelay: 0)
      } else {
        alertPresented = true
        askAboutUpdatingOneList("storeList", daysSinceRefreshedList)
      }
    } else if needsTastedDialog {
      alertPresented = true
      askAboutUpdatingOneList("tastedList", daysSinceRefreshedTasted)
    }
    return alertPresented
  }

  func askAboutUpdatingBoth(_ daysSinceList: Int, _ daysSinceTasted: Int) {
    //print("WHEREOWHWER")
    //print(Thread.callStackSymbols.forEach{print($0)})
    let alertDialogStore = UIAlertController(title: "Refresh now?", message: getMessage("storeList", daysSinceList), preferredStyle: .alert)
    let alertDialogTasted = UIAlertController(title: "Refresh now?", message: getMessage("tastedList", daysSinceTasted), preferredStyle: .alert)
    var requestedTastedRefresh = false
    var requestedStoreRefresh = false
    
    // Add REFRESH and CANCEL for TASTED
    let updateActionTasted = UIAlertAction(title: "REFRESH", style: .default, handler: {(action: UIAlertAction!) in
      print("REFRESH PRESSED TASTED")
      requestedTastedRefresh = true
      self.runUpdates(requestedStoreRefresh, requestedTastedRefresh)
    })
    alertDialogTasted.addAction(updateActionTasted)
    let dismissActionTasted = UIAlertAction(title: "CANCEL", style: .cancel, handler: {(action: UIAlertAction!) in
      print("CANCEL PRESSED")
      self.runUpdates(requestedStoreRefresh, requestedTastedRefresh)
    })
    alertDialogTasted.addAction(dismissActionTasted)

    // Add REFRESH and CANCEL for STORE (also includes presenting TASTED)
    let refreshActionStore = UIAlertAction(title: "REFRESH", style: .default, handler: {(action: UIAlertAction!) in
      print("REFRESH PRESSED STORE")
      requestedStoreRefresh = true
      self.present(alertDialogTasted, animated: true, completion: nil)
      
    })
    alertDialogStore.addAction(refreshActionStore)
    let dismissActionStore = UIAlertAction(title: "CANCEL", style: .cancel, handler: {(action: UIAlertAction!) in
      print("CANCEL PRESSED")
      self.present(alertDialogTasted, animated: true, completion: nil)
    })
    alertDialogStore.addAction(dismissActionStore)
    
    present(alertDialogStore, animated: true, completion: nil)
  }
  
  func askAboutUpdatingOneList(_ listType: String, _ daysSinceRefresh: Int) {
    let message = getMessage(listType, daysSinceRefresh)

    let alertDialog = UIAlertController(title: "Refresh now?", message: message, preferredStyle: .alert)
    alertDialog.addAction(UIAlertAction(title: "REFRESH", style: .default, handler: {(action: UIAlertAction!) in
      print("REFRESH PRESSED")
      var refreshStore = false
      var refreshTasted = false
      if listType == "storeList" {
        refreshStore = true
      }
      if listType == "tastedList" {
        refreshTasted = true
      }
      self.runUpdates(refreshStore, refreshTasted)
    }))
    alertDialog.addAction(UIAlertAction(title: "CANCEL", style: .cancel, handler: {(action: UIAlertAction!) in
      print("CANCEL PRESSED")
    }))
    present(alertDialog, animated: true, completion: nil)

  }
  
  func askAboutLaunchingQuiz( _ daysAgoMessage: String) {
    let message = "There appears to be a Captain Keith quiz available.\(daysAgoMessage) Would you like to go there now?"
    let alertDialog = UIAlertController(title: "Captain Keith Quiz", message: message, preferredStyle: .alert)
    alertDialog.addAction(UIAlertAction(title: "GO", style: .default, handler: {(action: UIAlertAction!) in
      print("GO PRESSED")
      let userDetails = SharedPreferences.getUserDetails()
      //var urlString =
      //for (name, value) in userDetails {
        //if value == "" { continue }
        //urlString += name + "=" + value + "&"
      //}
      //urlString = String(urlString.dropLast())
      //print("the urlString [\(urlString)]")
      if var url = URL(string: Constants.BaseUrl.quizUserLandingPage) {
        //var resultString = ""
        for (name, value) in userDetails {
          if value == "" { continue }
          let buildString = url.appendingQueryItem(name,value: value)
          url = URL(string: buildString)!
        }
        UIApplication.shared.open(url, options: [:])
      } else {
        print("the url wasn't good")
      }
      
    }))
    alertDialog.addAction(UIAlertAction(title: "CANCEL", style: .cancel, handler: {(action: UIAlertAction!) in
      print("CANCEL PRESSED")
    }))
    present(alertDialog, animated: true, completion: nil)
  }
  
  func getMessage(_ listType: String, _ daysSinceRefresh: Int) -> String {
    var message = ""
    if listType == "storeList" {
      message = "Your BEER list "
    } else {
      message = "Your TASTED list "
    }
    
    if daysSinceRefresh == 1 {
      message += "is 1 day old."
    } else if daysSinceRefresh > 10 {
      message += "is really old."
    } else {
      message += "is " + String(daysSinceRefresh) + " days old."
    }
    return message
  }
  
  func runUpdates(_ store: Bool,_ tasted: Bool) {
    print("completion with \(store) \(tasted)")
    if store || tasted {
      LoaderController.sharedInstance.showLoader(viewController: self, title: "Please Wait", message: "Getting your information from the UFO site.  This has been taking a long time lately.")
    }
    let clearLoader = !(store && tasted) // don't clear the loader if tasted process will be following
    
    if store {
      TransactionDriver.fetchActive(storeNumber: SharedPreferences.getString(PreferenceKeys.storeNumberPref, "13888"), storeName: SharedPreferences.getString(PreferenceKeys.storeNamePref, "Charlotte Flying Saucer"), viewController: self, clearLoader: clearLoader, waitUntilFinished: false)
    }
    if tasted {
      TransactionDriver.fetchTasted(SharedPreferences.getCredentials(), self)
    }
  }
  
  @objc func presentStoresOverlay() {
    let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
    let storesViewController = storyBoard.instantiateViewController(withIdentifier: "storesList")
    storesViewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
    (storesViewController as! StoreListViewController).myMethod(self)
    self.present(storesViewController, animated: false)
  }
  
  @objc func presentLogonOverlay() {
    let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
    let logonViewController = storyBoard.instantiateViewController(withIdentifier: "logonForm")
    logonViewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
    (logonViewController as! LogonViewController).myMethod(self)
    self.present(logonViewController, animated: false)
  }
  
  @objc func loadExternalWebPage() {
    let loadedUser = SharedPreferences.getString(PreferenceKeys.loadedUserPref, "")
    if let url = URL(string: Constants.BaseUrl.analytics + loadedUser) {
      UIApplication.shared.open(url)
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    if let segueId = segue.identifier {
      if segueId == "BeerListSegue" {
        let destination = segue.destination
        print("ViewController.prepare(for seque:, sender:) DEST\(destination)")
      } else if segueId == "FlaggedListSegue" {
        print("Flagged List Segue")
      } else if segueId == "JustLandedListSegue" {
        print("Just Landed List Segue")
      } else if segueId == "settingsSegue" {
        print("Settings Segue")
      } else {
        print("ViewController.prepare(for seque:, sender:) ID  [\(segueId)]")
      }
      
    } else {
      print("ViewController.prepare(for seque:, sender:) NO ID PROVIDED")
    }
  }

  @IBAction func orderFoodButtonAction(_ sender: UIButton) {
    print("orderFoodButtonAction")
    let uberEatsLink = SharedPreferences.getString(PreferenceKeys.uberEatsLinkPref , "")
    if uberEatsLink != "" {
      if let uberEatsUrl = URL(string: uberEatsLink) {
        UIApplication.shared.open(uberEatsUrl, options: [:])
      } 
    } else {
      print("ERROR: The link should be hidden if its blank")
    }
  }

  @IBAction func queryButtonAction(sender: UIButton) {
    SharedPreferences.putString(PreferenceKeys.lastQueryButtonPref, Constants.QUERY_CUSTOM)
    if !AppDelegate.currentQueryIsTasted() {
      SharedPreferences.putString(PreferenceKeys.lastQuerySortByPref, Constants.SORT_NAME)
      SharedPreferences.putString(PreferenceKeys.lastQuerySortDirection, Constants.SORT_ASC)
    } else {
      SharedPreferences.putString(PreferenceKeys.lastQuerySortByPref, Constants.SORT_TASTED_DATE)
      SharedPreferences.putString(PreferenceKeys.lastQuerySortDirection, Constants.SORT_DESC)
    }
    print("queryButtonAction")
  }

  @IBAction func justLandedButtonAction(sender: UIButton) {
    SharedPreferences.putString(PreferenceKeys.lastQueryButtonPref, Constants.QUERY_JUST_LANDED)
    SharedPreferences.putString(PreferenceKeys.lastQuerySortByPref, Constants.SORT_NAME)
    SharedPreferences.putString(PreferenceKeys.lastQuerySortDirection, Constants.SORT_ASC)
    print("justLandedButtonAction")
  }
  
  @IBAction func flaggedBeerListAction(sender: UIButton) {
    SharedPreferences.putString(PreferenceKeys.lastQueryButtonPref, Constants.QUERY_FLAGGED)
    SharedPreferences.putString(PreferenceKeys.lastQuerySortByPref, Constants.SORT_NAME)
    SharedPreferences.putString(PreferenceKeys.lastQuerySortDirection, Constants.SORT_ASC)
    print("flaggedBeerListAction")
  }
  
  @IBAction func showAppMenuActionSheet(_ sender: UIBarButtonItem) {
    let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
    
    let refreshActive = UIAlertAction(title: "Refresh Active", style: .default, handler: { (alert: UIAlertAction!) -> Void in
      print("refresh active action")
      LoaderController.sharedInstance.showLoader(viewController: self, title: "Please Wait", message: "Getting active beers from the UFO site")
     
      TransactionDriver.fetchActive(storeNumber: SharedPreferences.getString(PreferenceKeys.storeNumberPref, "13888"), storeName: SharedPreferences.getString(PreferenceKeys.storeNamePref, "Charlotte Flying Saucer"), viewController: self, clearLoader: true, waitUntilFinished: false)
    })
    let refreshTasted = UIAlertAction(title: "Refresh Tasted", style: .default, handler: { (alert: UIAlertAction!) -> Void in
      print("refresh tasted action")
      LoaderController.sharedInstance.showLoader(viewController: self, title: "Please Wait", message: "Getting your tasted list from the UFO site. Lately, the Saucer site has been taking several minutes to authenticate.")
      let credentials = SharedPreferences.getCredentials()
      TransactionDriver.fetchTasted(credentials, self)
    })
    let logOn = UIAlertAction(title: "Log On", style: .default, handler: { (alert: UIAlertAction!) -> Void in
      print("log on action")
      self.perform(#selector(self.presentLogonOverlay), with: nil, afterDelay: 0)
      
    })
    let logOut = UIAlertAction(title: "Log Out", style: .default, handler: { (alert: UIAlertAction!) -> Void in
      print("log out action")
      SharedPreferences.removePassword()
      do {
        try dbQueue.inDatabase({db in
          try db.execute("update UFO set TASTED = ''")
          try db.execute("update UFO set CREATED_DATE = ''")
        })
      } catch {
          print("djammitch!")
      }

      self.setToStorePresentation()
    })
    let changeLocation = UIAlertAction(title: "Change Location", style: .default, handler: { (alert: UIAlertAction!) -> Void in
      print("change location action")
      self.perform(#selector(self.presentStoresOverlay), with: nil, afterDelay: 0)
    })
    
    let showAnalyticsOnWeb = UIAlertAction(title: "Tasted Analytics", style: .default, handler: { (alert: UIAlertAction!) -> Void in
      print("show analytics action")
      self.perform(#selector(self.loadExternalWebPage), with: nil, afterDelay: 0)
    })
    //let rateApp = UIAlertAction(title: "Rate this app", style: .default, handler: { (alert: UIAlertAction!) -> Void in
    //  print("rate app action")
    //
    //})
    let showSettings = UIAlertAction(title: "Settings", style: .default, handler: { (alert: UIAlertAction!) -> Void in
      print("settings action")

      self.performSegue(withIdentifier: "settingsSegue", sender: self)
      
    })
    //let showAbout = UIAlertAction(title: "About", style: .default, handler: { (alert: UIAlertAction!) -> Void in
    //  print("about action")
    //
    //})
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (alert: UIAlertAction!) -> Void in
      print("cancelAction happened")
      
    })

    let currentPresentationMode = SharedPreferences.getString(PreferenceKeys.presentationModePref, "")
    let loadedUserPref = SharedPreferences.getString(PreferenceKeys.loadedUserPref, "")
    
    
    if currentPresentationMode == PreferenceValues.storePresentation {
      alertController.addAction(refreshActive)
      alertController.addAction(refreshTasted); refreshTasted.isEnabled = false
      alertController.addAction(logOn)
      alertController.addAction(logOut); logOut.isEnabled = false
      alertController.addAction(changeLocation)
      // alertController.addAction(rateApp)
      alertController.addAction(showSettings)
      // alertController.addAction(showAbout)
      alertController.addAction(cancelAction)
    } else if currentPresentationMode == PreferenceValues.userPresentation {
      alertController.addAction(refreshActive)
      alertController.addAction(refreshTasted)
      alertController.addAction(logOn); logOn.isEnabled = false
      alertController.addAction(logOut)
      alertController.addAction(changeLocation)
      if (loadedUserPref != "") {
        alertController.addAction(showAnalyticsOnWeb)
      }
      // alertController.addAction(rateApp)
      alertController.addAction(showSettings)
      // alertController.addAction(showAbout)
      alertController.addAction(cancelAction)
    }

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad) {
      if let popoverController = alertController.popoverPresentationController {
        popoverController.barButtonItem = sender
        popoverController.sourceRect = sender.accessibilityFrame
        self.present(alertController, animated: true, completion: nil)
      }
    } else {
      self.present(alertController, animated: true, completion: nil)
    }
  }
  
  func setPresentation() {
    print("ViewController.setPresentation()")
    let currentPresentationMode = SharedPreferences.getString(PreferenceKeys.presentationModePref, "")
    if currentPresentationMode == PreferenceValues.userPresentation { setToUserPresentation() }
    else { setToStorePresentation() }
  }
  
  func setUbereatsButtonVisibility() {
    let noUbereatsLinkFound = "" == SharedPreferences.getString(PreferenceKeys.uberEatsLinkPref,"")
    let hideUbereatsButton = "T" == SharedPreferences.getString(PreferenceKeys.uberEatsHidePref,"F")
    if ubereatsButton != nil {
      if (!noUbereatsLinkFound && !hideUbereatsButton) {
        ubereatsButton.isHidden = false
      } else {
        ubereatsButton.isHidden = true
      }
    } else {
      print("could not set the button because it was not initialized")
    }
  }
  
  func setToStorePresentation() {
    print("setToStorePresentation")
    tastedButton.isHidden = true
    untastedButton.isHidden = true
    tastedCountText.isHidden = true
    pageHeadline.text = SharedPreferences.getString(PreferenceKeys.storeNamePref, "??")
    alternateLocationLabel.isHidden = true
    rightSpacer.isHidden = true
    SharedPreferences.putString(PreferenceKeys.presentationModePref, PreferenceValues.storePresentation)
  }
  
  func setToUserPresentation() {
    let homeStoreLoaded = SharedPreferences.homeStoreLoaded()
    if !homeStoreLoaded { alternateLocationLabel.text = SharedPreferences.getString(PreferenceKeys.storeNamePref, "??") }
    alternateLocationLabel.isHidden = homeStoreLoaded
    tastedButton.isHidden = false
    untastedButton.isHidden = false
    tastedCountText.isHidden = false
    pageHeadline.text = SharedPreferences.getString(PreferenceKeys.userNamePref, "")
    tastedCountText.text = "TASTED \(SharedPreferences.getString(PreferenceKeys.tastedCountPref, "?")) SO FAR"
    rightSpacer.isHidden = false
    SharedPreferences.putString(PreferenceKeys.presentationModePref, PreferenceValues.userPresentation)
    
  }
  
  // MARK: Things to do with the "query icons"
  
  @IBAction func changeSelection(sender: UIButton) {
    let contKey = PreferenceKeys.queryContainerPref
    let tastKey = PreferenceKeys.queryTastedPref
    let geogKey = PreferenceKeys.queryGeographyPref
    
    var queryContainerKey = SharedPreferences.getString(contKey, "B")
    var queryTastedKey = SharedPreferences.getString(tastKey, "B")
    var queryGeographyKey = SharedPreferences.getString(geogKey, "B")
    
    var nextKey: String = ""
    
    if sender == tapButton {
      nextKey = getNextKeyLeft(queryContainerKey)
      SharedPreferences.putString(contKey, nextKey)
      setQueryIconColors(nextKey, tapButton, bottleButton)
    } else if sender == bottleButton {
      nextKey = getNextKeyRight(queryContainerKey)
      SharedPreferences.putString(contKey, nextKey)
      setQueryIconColors(nextKey, tapButton, bottleButton)
    } else if sender == tastedButton {
      nextKey = getNextKeyLeft(queryTastedKey)
      SharedPreferences.putString(tastKey, nextKey)
      setQueryIconColors(nextKey, tastedButton, untastedButton)
    } else if sender == untastedButton {
      nextKey = getNextKeyRight(queryTastedKey)
      SharedPreferences.putString(tastKey, nextKey)
      setQueryIconColors(nextKey, tastedButton, untastedButton)
    } else if sender == localButton {
      nextKey = getNextKeyLeft(queryGeographyKey)
      SharedPreferences.putString(geogKey, nextKey)
      setQueryIconColors(nextKey, localButton, worldButton)
    } else if sender == worldButton {
      nextKey = getNextKeyRight(queryGeographyKey)
      SharedPreferences.putString(geogKey, nextKey)
      setQueryIconColors(nextKey, localButton, worldButton)
    } else if sender == queryButton {
      setQueryIconColors(queryContainerKey, tapButton, bottleButton)
      setQueryIconColors(queryTastedKey, tastedButton, untastedButton)
      setQueryIconColors(queryGeographyKey, localButton, worldButton)
    }
  

    queryContainerKey = SharedPreferences.getString(contKey, "B")
    queryTastedKey = SharedPreferences.getString(tastKey, "B")
    queryGeographyKey = SharedPreferences.getString(geogKey, "B")
    let iconState = queryContainerKey + queryTastedKey + queryGeographyKey
    
    
    if iconState.hasPrefix("X") {
      setButtonText(queryButton, "(select tap, bottle or both)", false)
    } else if iconState.hasSuffix("X") {
      setButtonText(queryButton, "(select local, imported or both)", false)
    } else if iconState.range(of: "X") != nil {
      setButtonText(queryButton, "(select tasted, untasted or both)", false)
    } else {
      SharedPreferences.putString(PreferenceKeys.lastQueryIconKeyPref, iconState)
      setButtonText(queryButton, "LIST " + Constants.QUERY_BUTTON_DICTIONARY[iconState]!.uppercased(), true)
    }
  }
  
  func setButtonText(_ button: UIButton, _ buttonText: String, _ enabled: Bool) {
    button.setTitle(buttonText, for: .normal)
    if (!enabled) {
      button.setTitleColor(UIColor.red, for: .normal)
    } else {
      button.setTitleColor(UIColor(named: "colorsetText"), for: .normal)
    }
    button.isEnabled = enabled
  }
  
  //MARK: Button "active status" functions
  
  func setQueryIconColors(_ key: String, _ leftItem: UIButton, _ rightItem: UIButton) {
    if key == "B" {
      leftItem.imageView?.tintColor = UIColor(named: "colorsetIconActive")
      rightItem.imageView?.tintColor = UIColor(named: "colorsetIconActive")
    } else if key == "R" {
      leftItem.imageView?.tintColor = UIColor(named: "colorsetIconNotActive")
      rightItem.imageView?.tintColor = UIColor(named: "colorsetIconActive")
    } else if key == "L" {
      leftItem.imageView?.tintColor = UIColor(named: "colorsetIconActive")
      rightItem.imageView?.tintColor = UIColor(named: "colorsetIconNotActive")
    } else {
      leftItem.imageView?.tintColor = UIColor(named: "colorsetIconNotActive")
      rightItem.imageView?.tintColor = UIColor(named: "colorsetIconNotActive")
    }
  }
  
  func getNextKeyLeft(_ pairStateLetter: String) -> String {
    if pairStateLetter == "B" { return "R" }
    else if pairStateLetter == "L" { return "X" }
    else if pairStateLetter == "R" { return "B" }
    else { return "L" }
  }

  func getNextKeyRight(_ pairStateLetter: String) -> String {
    if pairStateLetter == "B" { return "L" }
    else if pairStateLetter == "R" { return "X" }
    else if pairStateLetter == "L" { return "B" }
    else { return "R" }
  }

  
}




