//
//  LogonViewController.swift
//  Knurder
//
//  Created by Dale Seng on 7/1/18.
//  Copyright © 2018 Sengsational. All rights reserved.
//

import UIKit

class LogonViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

  @IBOutlet weak var buttonSelectStore: UIButton!
  @IBOutlet weak var popupView: UIView!
  @IBOutlet weak var tableViewSelectStore: UITableView!
  @IBOutlet weak var hightTableView: NSLayoutConstraint!

  @IBOutlet weak var buttonMouCheckbox: UIButton!
  @IBOutlet weak var buttonShowPasswordCheckbox: UIButton!
  
  @IBOutlet weak var textFieldEmailOrUsername: UITextField!
  @IBOutlet weak var textFieldPassword: UITextField!
  
  @IBOutlet weak var labelMou: UILabel!
  @IBOutlet weak var labelBack: UILabel!
  
  weak var viewController: ViewController!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableViewSelectStore.isHidden = true
    self.tableViewSelectStore.delegate = self
    self.tableViewSelectStore.dataSource = self
    
    initializeLogonStoreButton()
    labelMou.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LogonViewController.tapFunction)))
    labelBack.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LogonViewController.backFunction)))
    
    populateUserInfo()

  }
  
  func populateUserInfo() {
    let emailOrUsername = SharedPreferences.getString(PreferenceKeys.emailOrUsername, "")
    if "" != emailOrUsername {
      textFieldEmailOrUsername.text = emailOrUsername
    }
    let password = SharedPreferences.getPasswordFromKeychain(emailOrUsername)
    if "" != password {
      textFieldPassword.text = password
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
    let logonStore = SharedPreferences.getString(PreferenceKeys.storeNumberLogonPref, "(empty)")
    if "(empty)" == logonStore {
      buttonSelectStore.setTitle(currentStore, for: .normal)
    } else {
      buttonSelectStore.setTitle(StoreNameHelper.lookupStoreName(forNumber: logonStore, urlStyle: false) , for: .normal)
    }
    self.hightTableView.constant = 0
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
    
  @IBAction func onClickSelectStore(_ sender: Any) {
    UIView.animate(withDuration: 0.3, animations: {
      self.tableViewSelectStore.isHidden = !self.tableViewSelectStore.isHidden
      if self.tableViewSelectStore.isHidden {
        self.hightTableView.constant = 0
      } else {
        self.hightTableView.constant = 170
      }
    })
  }
  
  @IBAction func onClickMouCheckbox(_ sender: Any) {
    swapCheckbox(self.buttonMouCheckbox)
  }
  
  @IBAction func onClickShowPasswordCheckbox(_ sender: Any) {
    swapCheckbox(self.buttonShowPasswordCheckbox)
  }

  func swapCheckbox(_ button: UIButton) {
    let initialText = button.currentTitle
    if "√" == initialText {
      button.setTitle("", for: .normal)
    } else {
      button.setTitle("√", for: .normal)
    }
    
    if button == buttonShowPasswordCheckbox {
      if "√" == initialText {
        textFieldPassword.isSecureTextEntry = true
      } else {
        textFieldPassword.isSecureTextEntry = false
      }
    }
  }
  
  @IBAction func onClickSignIn(_ sender: Any) {
    let cardNumber = self.textFieldEmailOrUsername.text
    let password = self.textFieldPassword.text
    let mou = (self.buttonMouCheckbox.currentTitle == "√") ? "1":"0"
    let storeName = self.buttonSelectStore.currentTitle
    
    
    if let cardNumber = cardNumber, let password = password, let storeName = storeName {
      if cardNumber.count < 4 || password.count < 4 {
        Toast.show(message: "card number or password looks like it probably wouldn't work", controller: self )
      } else {
        let storeNumber = StoreNameHelper.lookupStoreNumber(forName: storeName)
        Toast.show(message: "trying to log in using \(cardNumber) on issued by \(storeName)", controller: self)
        print("logging in with \(cardNumber) \(password) \(mou) \(storeName) \(storeNumber)")
        dismiss(animated: false, completion: nil)
        LoaderController.sharedInstance.showLoader(viewController: viewController, title: "Please Wait", message: "Getting your tasted list from the UFO site")
        let credentials = [Constants.CredentialsKey.emailOrUsername:cardNumber,Constants.CredentialsKey.password:password,Constants.CredentialsKey.mou:mou, Constants.CredentialsKey.storeNumber:storeNumber]
        TransactionDriver.fetchTasted(credentials, viewController)
      }
    }
  }
  
  func myMethod(_ sender: ViewController) {
    viewController = sender
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
    buttonSelectStore.setTitle(StoreNameHelper.stores[indexPath.row].name, for: .normal)
    onClickSelectStore("")
  }
}

// MARK: To manage the button look and feel
@IBDesignable extension UIButton {
  
  @IBInspectable var borderWidth: CGFloat {
    set {
      layer.borderWidth = newValue
    }
    get {
      return layer.borderWidth
    }
  }
  
  @IBInspectable var cornerRadius: CGFloat {
    set {
      layer.cornerRadius = newValue
    }
    get {
      return layer.cornerRadius
    }
  }
  
  @IBInspectable var borderColor: UIColor? {
    set {
      guard let uiColor = newValue else { return }
      layer.borderColor = uiColor.cgColor
    }
    get {
      guard let color = layer.borderColor else { return nil }
      return UIColor(cgColor: color)
    }
  }
}


