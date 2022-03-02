//
//  LoadController.swift
//  TestSpinner
//
//  Created by Dale Seng on 6/16/18.
//  Copyright © 2018 Sengsational. All rights reserved.
//

import UIKit

class LoaderController: NSObject {

  static let sharedInstance = LoaderController()
  private let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
  //private var start = DispatchTime.now()

  func showLoader(viewController: ViewController, title: String, message: String) {
    DispatchQueue.main.async {
      //self.start = DispatchTime.now()
      self.activityIndicator.hidesWhenStopped = true
      self.activityIndicator.activityIndicatorViewStyle = .gray
      let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
      self.activityIndicator.startAnimating()
      alert.view.addSubview(self.activityIndicator)
      viewController.present(alert, animated: true, completion: nil)
      //print("load indicator presented")
    }
  }
  
  func removeLoader(viewController: ViewController, _ message: String, uiParameters: [String]?){
    DispatchQueue.main.async {
      if (message == Constants.Messages.GOOD_BEER_LIST) {
        
        if let uiParameters = uiParameters {
          if (uiParameters.count > 1) {
            SharedPreferences.putString(PreferenceKeys.storeNumberPref, uiParameters[0])
            SharedPreferences.putString(PreferenceKeys.storeNamePref, uiParameters[1])
            print("setting store preferences to \(uiParameters)")
          }
        }
        if "" == SharedPreferences.getString(PreferenceKeys.presentationModePref, "") {
          SharedPreferences.putString(PreferenceKeys.presentationModePref, PreferenceValues.storePresentation)
        }
      } else if (message == Constants.Messages.GOOD_TASTED_LIST) {
        SharedPreferences.putString(PreferenceKeys.presentationModePref, PreferenceValues.userPresentation)
        
      }
      viewController.setPresentation()
      print("setting ubereats from LoaderController")
      viewController.setUbereatsButtonVisibility()
      viewController.dismiss(animated: true, completion: {
        Toast.show(message: message, controller: viewController)
      })
    }
  }
}
