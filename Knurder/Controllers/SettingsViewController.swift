//
//  SettingsViewController.swift
//  Knurder
//
//  Created by Dale Seng on 7/2/18.
//  Copyright © 2018 Sengsational. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

  @IBOutlet weak var labelBack2: UILabel!
  @IBOutlet weak var labelBack: UIView!
  @IBOutlet weak var hideMixSwitch: UISwitch!
  @IBOutlet weak var hideFlightSwitch: UISwitch!
  @IBOutlet weak var currentPlateSwitch: UISwitch!
  @IBOutlet weak var uploadReviewsSwitch: UISwitch!
  @IBOutlet weak var hideDeliveryButtonSwitch: UISwitch!
  @IBOutlet weak var resetHelpButton: UIButton!

  
  override func viewDidLoad() {
    super.viewDidLoad()
    labelBack2.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LogonViewController.backFunction)))
    setSwitches()
  }
  
  func setSwitches() {
    let hideMix = SharedPreferences.getString(PreferenceKeys.hideMixPref, "")
    let hideFlight = SharedPreferences.getString(PreferenceKeys.hideFlightPref, "")
    let currentPlate = SharedPreferences.getString(PreferenceKeys.currentPlatePref, "")
    let uploadReviews = SharedPreferences.getString(PreferenceKeys.uploadReviewsPref, "")
    let hideUberEats = SharedPreferences.getString(PreferenceKeys.uberEatsHidePref, "")
    (hideMix == "F") ? (hideMixSwitch.isOn = false) : (hideMixSwitch.isOn = true)
    (hideFlight == "F") ? (hideFlightSwitch.isOn = false) : (hideFlightSwitch.isOn = true)
    (currentPlate == "F") ? (currentPlateSwitch.isOn = false) : (currentPlateSwitch.isOn = true)
    (uploadReviews == "F") ? (uploadReviewsSwitch.isOn = false) : (uploadReviewsSwitch.isOn = true)
    (hideUberEats == "F") ? (hideDeliveryButtonSwitch.isOn = false) : (hideDeliveryButtonSwitch.isOn = true)
  }
  
  @objc func backFunction(sender:UITapGestureRecognizer) {
    dismiss(animated: false, completion: nil)
    if let senderView = sender.view {
      print("1:\(senderView)")
      let children = senderView.subviews
      for child in children {
        print("child: \(child)")
      }
      if let senderId = senderView.restorationIdentifier {
      print("2:\(senderId)")
        if (senderId == "backLabel") {
        print("3")
          
        }
      }
    }
  }

  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
  }
    
  @IBAction func onSwitchChanged(_ sender: Any) {
    if let senderSwitch = sender as? UISwitch {
      if senderSwitch == hideMixSwitch {
        if hideMixSwitch.isOn {SharedPreferences.putString(PreferenceKeys.hideMixPref, "T")} else {SharedPreferences.putString(PreferenceKeys.hideMixPref, "F")}
      } else if senderSwitch == hideFlightSwitch {
        if hideFlightSwitch.isOn {SharedPreferences.putString(PreferenceKeys.hideFlightPref, "T")} else {SharedPreferences.putString(PreferenceKeys.hideFlightPref, "F")}
      } else if senderSwitch == currentPlateSwitch {
        if currentPlateSwitch.isOn {SharedPreferences.putString(PreferenceKeys.currentPlatePref, "T")} else {SharedPreferences.putString(PreferenceKeys.currentPlatePref, "F")}
        Toast.show(message: "To make this setting effective, you need to run 'refresh tasted'", controller: self)
      } else if senderSwitch == self.uploadReviewsSwitch {
        if uploadReviewsSwitch.isOn {SharedPreferences.putString(PreferenceKeys.uploadReviewsPref, "T")} else {SharedPreferences.putString(PreferenceKeys.uploadReviewsPref, "F")}
      } else if senderSwitch == self.hideDeliveryButtonSwitch {
        if hideDeliveryButtonSwitch.isOn {SharedPreferences.putString(PreferenceKeys.uberEatsHidePref, "T")} else {SharedPreferences.putString(PreferenceKeys.uberEatsHidePref, "F")}
      }
    }
  }
  
  @IBAction func onResetButton(_ sender: Any) {
    SharedPreferences.removeByKey(PreferenceKeys.firstRunTutorialPref)
    SharedPreferences.removeByKey(PreferenceKeys.shakerTutorialPref)
    SharedPreferences.removeByKey(PreferenceKeys.postReviewTutorialPref)
    SharedPreferences.removeByKey(PreferenceKeys.tastedUploadTutorialPref)
    Toast.show(message: "Help screens formerly marked \"don't show again\" will now show", controller: self)
  }
  
}
