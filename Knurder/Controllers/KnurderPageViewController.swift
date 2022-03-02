//
//  KnurderPageViewController.swift
//
//  Created by Dale Seng on 6/4/18.
//

import UIKit
import GRDB

class KnurderPageViewController: UIViewController {

  @IBOutlet weak var scrollView: UIScrollView!
  
  @IBOutlet weak var beerName: UILabel!
  @IBOutlet weak var beerStyle: UILabel!
  @IBOutlet weak var beerDescription: UILabel!
  @IBOutlet weak var beerNewState: UILabel!
  @IBOutlet weak var beerAbv: UILabel!
  @IBOutlet weak var beerPlace: UILabel!
  @IBOutlet weak var beerTastedDate: UILabel!
  @IBOutlet weak var beerFlagged: UIImageView!
  
  var beerIndexPath: IndexPath!
  var recordCount: Int!
  var brewController: FetchedRecordsController<SaucerItem>!
  static let dateFormatter = DateFormatter()
  var pinchD: CGFloat = 1.0;

    override func viewDidLoad() {
      super.viewDidLoad()
      
      let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress(_:)))
      scrollView?.addGestureRecognizer(longPressRecognizer)

      
      self.recordCount = brewController.sections[0].numberOfRecords
      if beerIndexPath == nil {
        print("THIS SHOULD NOT BE HAPPENING EXCEPT IN TESTING (we will have a record we came from)")
        beerIndexPath = IndexPath(item: 0, section: 0)
      }
      let saucerItem = brewController.record(at: beerIndexPath)
      beerName.text = saucerItem.name
      beerDescription.text = saucerItem.descriptionx
      beerPlace.text = saucerItem.city
      beerStyle.text = saucerItem.style
      
      beerTastedDate.text = SaucerItem.getTastedText(saucerItem.created_date)
      let tasted = (beerTastedDate.text?.count == 0) ? false : true

      beerAbv.text = SaucerItem.getAbvText(saucerItem.abv)

      if saucerItem.new_arrival == "T" {
        beerNewState.text = "New Arrival"
        beerName.font = UIFont.boldSystemFont(ofSize: beerName.font.pointSize)
      } else {
        beerNewState.text = ""
      }
      
      if saucerItem.highlighted == "T" {
        beerFlagged.isHidden = false
      } else {
        beerFlagged.isHidden = true
      }
      
      if tasted {
        beerName.textColor = UIColor(named: "colorsetTastedText")
        beerDescription.textColor = UIColor(named: "colorsetTastedText")
        beerStyle.textColor = UIColor(named: "colorsetTastedText")
        beerPlace.textColor = UIColor(named: "colorsetTastedText")
        beerAbv.textColor = UIColor(named: "colorsetTastedText")
      }
    }

  
    @IBAction func handlePinch(_ gesture: UIPinchGestureRecognizer) {
      guard let gestureView = gesture.view else {
        return;
      }

      gestureView.transform = gestureView.transform.scaledBy(x: gesture.scale, y: gesture.scale)
      
      if (gesture.state == UIPinchGestureRecognizer.State.began) {
        pinchD = gestureView.transform.d
      }

      if (gesture.state == UIPinchGestureRecognizer.State.ended) {
        let larger = gestureView.transform.d > pinchD
        let fontSize = beerDescription.font.pointSize
        if (larger) {
          if (fontSize < 28) {
            let calculatedFont = UIFont(name: beerDescription.font.fontName, size: fontSize + 4)
            beerDescription.font = calculatedFont
          }
        } else {
          if (fontSize > 12) {
            let calculatedFont = UIFont(name: beerDescription.font.fontName, size: fontSize - 4)
            beerDescription.font = calculatedFont
          }
        }
      }
    }
  
}



extension KnurderPageViewController {
  @objc func longPress(_ gesture: UILongPressGestureRecognizer) {
    if gesture.state == UIGestureRecognizerState.began {
      let saucerItem = brewController.record(at: beerIndexPath!)
      // Get the highlighted flag from the database (should be the same as the cell)
      let dbFlag = saucerItem.highlighted
      //print("beerFlag \(String(describing: beerFlag))")
      // Toggle the highlighted state
      let isHighlighted = (dbFlag == "T") ? false : true
      //print("isHighlighted \(isHighlighted)")
      // Change the state of the icon in the table view cell
      beerFlagged.isHidden = !isHighlighted
      // Change the state of the hightlighted variable in the database
      saucerItem.highlighted = isHighlighted ? "T" : "F"
      try! dbQueue.inDatabase { db in
        try saucerItem.update(db)
      }
    }
  }
}
