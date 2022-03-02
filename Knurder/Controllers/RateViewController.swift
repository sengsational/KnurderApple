//
//  RatingsViewController.swift
//  Knurder
//
//  Created by Dale Seng on 11/13/18.
//  Copyright © 2018 Sengsational. All rights reserved.
//

import UIKit
import Cosmos
import TinyConstraints
import GRDB

class RateViewController: UIViewController, UITextViewDelegate {
  
  @IBOutlet weak var beerName: UILabel!
  @IBOutlet weak var starsView: UIView!
  @IBOutlet weak var beerDescription: UILabel!
  @IBOutlet weak var ratingEditText: UITextView!
  
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var saveButton: UIButton!
  
  var saucerItem: SaucerItem!
  
  lazy var cosmosView: CosmosView = {
    var view = CosmosView()
    view.settings.filledImage = UIImage(named: "RatingStarFilled")?.withRenderingMode(.alwaysOriginal)
    view.settings.emptyImage = UIImage(named: "RatingStarEmpty")?.withRenderingMode(.alwaysOriginal)
    view.settings.starSize = 40
    view.settings.starMargin = 10
    view.settings.updateOnTouch = true
    return view
  }()
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    ratingEditText.delegate = self

    // Manage Stars
    starsView.addSubview(cosmosView)
    cosmosView.centerInSuperview()
    
    // Pull item from the database
    if let saucerItem = saucerItem {
      beerName.text = saucerItem.name
      beerDescription.text = saucerItem.descriptionx
      ratingEditText.text = saucerItem.user_review
      
      // default star count to 3 if not present in the database
      cosmosView.rating = 3
       
      if let userStarsString = saucerItem.user_stars, let userStarsInt = Int(userStarsString) {
        if userStarsInt > 0 {
          cosmosView.rating = Double(userStarsInt)
        }
      }
      
      // disable stuff if it's a web review
      if saucerItem.review_flag == "W" {
        //print("user review in the database was from the web")
        //ratingEditText.isEditable = false
        ratingEditText.textColor = UIColor(named: "colorsetRatingTextDisabled")
        beerDescription.isHidden = true
        saveButton.isHidden = true
        cosmosView.isUserInteractionEnabled = false
      } else {
        ratingEditText.isEditable = true
        ratingEditText.textColor = UIColor(named: "colorsetRatingTextEnabled")
        beerDescription.isHidden = false
        saveButton.isHidden = false
        cosmosView.isUserInteractionEnabled = true
      }
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    let reviewTutorial = SharedPreferences.getString(PreferenceKeys.postReviewTutorialPref, "")
    print("reviewTutorial count \(reviewTutorial.count) [\(reviewTutorial)]" )
    if reviewTutorial.count == 0 {
      SharedPreferences.putString(PreferenceKeys.postReviewTutorialPref, "F")
      let alertViewController = UIAlertController(title: "Saving Your Ratings", message: "If you're a UFO member, by default, your ratings will be saved to the Saucer site next time you update your 'tasted' list.  Once it's saved there, they are no longer editable.\n\nYou can go into Knurder settings and set it so it does not upload, if you'd like.\n\nBut if you decide not to upload (or are not a UFO member), then the ratings are ONLY on your phone, so could be lost if you get a new phone.\n\nI just wanted to be sure you knew the deal.", preferredStyle: .alert)
      let okAction = UIAlertAction.init(title: "OK", style: .default) { (action) -> Void in
        //self.alertControllerActionString = "OK Welcome"
      }
      alertViewController.addAction(okAction)
      present(alertViewController, animated: true, completion: nil)
    }
  }
  
  public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
    if saucerItem.review_flag == "W" {
      Toast.show(message: "Once a review is on the Saucer site, it can't be updated.", controller: self)
      ratingEditText.isEditable = false
      return false
    }
    return true
  }
  
  @IBAction func actionSaveButton(_ sender: Any) {
    let clearItem = ratingEditText.text.contains("CLEARCLEAR")
    let hasExistingReview = !(saucerItem.review_flag == nil)
    if (clearItem && !hasExistingReview) {
      actionCancelButton(sender)
      return
    }
    
    var navigationDone = false
    
    if (!clearItem) {
      saucerItem.user_stars = "\(Int(cosmosView.rating))"
      print("user_stars \(saucerItem.user_stars ?? "(unavailable)")")
      saucerItem.user_review = ratingEditText.text
      saucerItem.review_flag = "L"
      
      // Run once alert if item not tasted
      let tastedFlag = saucerItem.tasted
      let tastedUploadTutorial = SharedPreferences.getString(PreferenceKeys.tastedUploadTutorialPref, "")
      print("tastedUploadTutorial count \(tastedUploadTutorial.count) [\(tastedUploadTutorial)]" )
      if tastedFlag != "T" && tastedUploadTutorial.count == 0 {
        navigationDone = true
        SharedPreferences.putString(PreferenceKeys.tastedUploadTutorialPref, "F")
        let alertViewController = UIAlertController(title: "Not Yet Tasted", message: "You can add a review to a beer, like this one, that the Saucer doesn't yet consider 'tasted'.  It will be saved locally for now.  If the Saucer flips the 'tasted bit', we'll upload the review.", preferredStyle: .alert)
        let okAction = UIAlertAction.init(title: "OK", style: .default) { (action) -> Void in
          self.saveSaucerItem(saucerItem: self.saucerItem)
          self.navigationController?.popViewController(animated: true)
        }
        alertViewController.addAction(okAction)
        present(alertViewController, animated: true, completion: nil)
      } else if ratingEditText.text.uppercased().contains("KNURDER") {
        navigationDone = true
        let randomElementThanks = Constants.KNURDER_MENTION_THANKS[Int(arc4random_uniform(UInt32(Constants.KNURDER_MENTION_THANKS.count)))]
        let alertViewController = UIAlertController(title: "Thanks!", message: randomElementThanks, preferredStyle: .alert)
        let okAction = UIAlertAction.init(title: "OK", style: .default) { (action) -> Void in
          self.saveSaucerItem(saucerItem: self.saucerItem)
          self.navigationController?.popViewController(animated: true)
        }
        alertViewController.addAction(okAction)
        present(alertViewController, animated: true, completion: nil)
      }
    } else { // clear item (for testing)
      saucerItem.user_stars = nil
      saucerItem.user_review = nil
      saucerItem.review_flag = nil
    }

    if !navigationDone {
      saveSaucerItem(saucerItem: saucerItem)
      self.navigationController?.popViewController(animated: true)
    }
  }

  func saveSaucerItem(saucerItem: SaucerItem) {
    do {
      try dbQueue.inDatabase({db in
        try saucerItem.update(db)
        print("saucer item updated")
      })
    } catch {
      print("Failed to update review in database")
    }
  }
  
  @IBAction func actionCancelButton(_ sender: Any) {
    //AppDelegate.toastMessage = ""
    self.navigationController?.popViewController(animated: true)
  }
  
  func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
    let numberOfChars = newText.count
    return numberOfChars < 248    
  }
}

