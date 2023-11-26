//
//  LogonViewController.swift
//  Knurder
//
//  Created by Dale Seng on 7/1/18.
//  Copyright © 2018 Sengsational. All rights reserved.
//

import UIKit

class CardauthViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

  @IBOutlet weak var buttonSelectStoreCa: UIButton!
  @IBOutlet weak var popupViewCa: UIView!
  @IBOutlet weak var tableViewSelectStoreCa: UITableView!
  
  @IBOutlet weak var hightTableViewCa: NSLayoutConstraint!
  @IBOutlet weak var buttonShowPinCheckbox: UIButton!
  @IBOutlet weak var textFieldCardNumber: UITextField!
  @IBOutlet weak var textFieldPin: UITextField!
  @IBOutlet weak var buttonMouCheckbox: UIButton!
  @IBOutlet weak var labelMou: UILabel!

  @IBOutlet weak var labelBackCa: UILabel!
//
  weak var masterViewController: MasterViewController!
  
  var brewIds = [String]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableViewSelectStoreCa.isHidden = true
    self.tableViewSelectStoreCa.delegate = self
    self.tableViewSelectStoreCa.dataSource = self
    
    initializeLogonStoreButton()
    labelMou.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(CardauthViewController.tapFunction)))
    labelBackCa.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(CardauthViewController.backFunction)))
    
    populateUserInfo()

  }
  
  func populateUserInfo() {
    let cardNumber = SharedPreferences.getString(PreferenceKeys.cardNumberPref, "")
    if "" != cardNumber {
      textFieldCardNumber.text = cardNumber
    }
    let cardPin = SharedPreferences.getPinFromKeychain(cardNumber)
    if "" != cardPin {
      textFieldPin.text = cardPin
    }
  }

  @objc func tapFunction(sender:UITapGestureRecognizer) {
    Toast.show(message: "Leave unchecked unless you know what MOU is and are one.", controller: self)
  }
  
  @objc func backFunction(sender:UITapGestureRecognizer) {
    dismiss(animated: false, completion: nil)
  }
  
  func initializeLogonStoreButton() {
    let currentStore = SharedPreferences.getString(PreferenceKeys.storeNamePref, "(empty)")
    let logonStore = SharedPreferences.getString(PreferenceKeys.storeNumberCardauthPref, "(empty)")
    if "(empty)" == logonStore {
      buttonSelectStoreCa.setTitle(currentStore, for: .normal)
    } else {
      buttonSelectStoreCa.setTitle(StoreNameHelper.lookupStoreName(forNumber: logonStore, urlStyle: false) , for: .normal)
    }
    self.hightTableViewCa.constant = 0
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
    
//
  @IBAction func onClickSelectStore(_ sender: Any) {
    UIView.animate(withDuration: 0.3, animations: {
      self.tableViewSelectStoreCa.isHidden = !self.tableViewSelectStoreCa.isHidden
      if self.tableViewSelectStoreCa.isHidden {
        self.hightTableViewCa.constant = 0
      } else {
        self.hightTableViewCa.constant = 170
      }
    })
  }
  @IBAction func onClickMouCheckbox(_ sender: Any) {
    swapCheckbox(self.buttonMouCheckbox)
  }
  
  //@IBAction func onClickShowPasswordCheckbox(_ sender: Any) {

  @IBAction func onClickShowPinCheckbox(_ sender: Any) {
    print("onclickShowPinCheckbox()")
    swapCheckbox(self.buttonShowPinCheckbox)
  }

  //func swapCheckbox(_ button: UIButton) {
  func swapCheckbox(_ button: UIButton) {
    print("swapCheckbox()")
    let initialText = button.currentTitle
    if "√" == initialText {
      button.setTitle("", for: .normal)
    } else {
      button.setTitle("√", for: .normal)
    }
    
    if button == buttonShowPinCheckbox {
      if "√" == initialText {
        textFieldPin.isSecureTextEntry = true
      } else {
        textFieldPin.isSecureTextEntry = false
      }
    }
  }
  
  //@IxBAction func onClickCardauthSignIn(_ sender: Any) {
  @IBAction func onClickCardauthSignIn(_ sender: Any) {
    let cardNumber = self.textFieldCardNumber.text
    let pin = self.textFieldPin.text
    let mou = (self.buttonMouCheckbox.currentTitle == "√") ? "1":"0"
    let storeName = self.buttonSelectStoreCa.currentTitle
    
    
    if let cardNumber = cardNumber, let pin = pin, let storeName = storeName {
      if cardNumber.count < 4 || pin.count < 4 {
        Toast.show(message: "card number or password looks like it probably wouldn't work", controller: self )
      } else {
        let storeNumberCardauth = StoreNameHelper.lookupStoreNumber(forName: storeName)
        Toast.show(message: "trying to log in using \(cardNumber) on issued by \(storeName)", controller: self)
        print("logging in with \(cardNumber) \(pin) \(storeName) \(storeNumberCardauth)")
        dismiss(animated: false, completion: nil)
        let brewCount = String(brewIds.count)
        LoaderController.sharedInstance.showLoader(masterViewController: masterViewController, title: "Please Wait", message: "Checking \(brewCount) flagged beers with brews on queue...")
        let credentialsCa = [Constants.CredentialsKey.cardNumber:cardNumber,Constants.CredentialsKey.pin:pin,Constants.CredentialsKey.storeNumberCardauth:storeNumberCardauth,Constants.CredentialsKey.mou:mou]
        TransactionDriver.uploadBrewsOnQueue(credentialsCa, masterViewController, brewIds)
      }
    }
  }
  func setBrewIds(_ _brewIds: [String]) {
    brewIds = _brewIds
  }
  
  func myMethod(_ sender: MasterViewController) {
    masterViewController = sender
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return StoreNameHelper.stores.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    cell.textLabel?.text = StoreNameHelper.stores[indexPath.row].name
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    buttonSelectStoreCa.setTitle(StoreNameHelper.stores[indexPath.row].name, for: .normal)
    onClickSelectStore("")
  }
}
