//
//  AsyncOperation.swift
//  FirstDb
//
//  Created by Dale Seng on 5/20/18.
//  Copyright © 2018 Sengsational. All rights reserved.
//

import Foundation

open class AsyncOperation: Operation {
  public enum State: String {
    case ready, executing, finished
    
    fileprivate var keyPath: String {
      return "is" + rawValue.capitalized
    }
  }
  
  open var state = State.ready {
    willSet {
      willChangeValue(forKey: newValue.keyPath)
      willChangeValue(forKey: state.keyPath)
    }
    didSet {
      didChangeValue(forKey: oldValue.keyPath)
      didChangeValue(forKey: state.keyPath)
    }
  }
}


extension AsyncOperation {
  //: Operation Overrides
  override open var isReady: Bool {
    return super.isReady && state == .ready
  }
  
  override open var isExecuting: Bool {
    return state == .executing
  }
  
  override open var isFinished: Bool {
    return state == .finished
  }
  
  override open var isAsynchronous: Bool {
    return true
  }
  
  override open func start() {
    if isCancelled {
      state = .finished
      return
    }
    //print("operation queue: " + OperationQueue.current.debugDescription + " " + OperationQueue().debugDescription)
    if let queue = OperationQueue.current {
      print(getRemainingOperations(queue: queue))
    } else {
      print("unable to get list of operations")
    }
    main()
    state = .executing
  }
  
  override open func cancel() {
    super.cancel()
    state = .finished
  }

  func getRemainingOperations(queue: OperationQueue) -> String {
    var resultList = ""
    for op in queue.operations {
        resultList += (op.name ?? "(name not found)") + ", "
    }
    return resultList
  }
  
  func cancelOperations(queue: OperationQueue) {
    print("cancelOperations(OperationQueue) Cancelling " + String(queue.operations.count) + " operations.")
    
    for operation in queue.operations.reversed() {
      print("handling " + (operation.name ?? "(unknown)"))
      if operation.name != "FinishOperation" {
        print("cancelling \(operation.name ?? "(no name)")")
        operation.cancel()
      } else {
        let finishOp = operation as! FinishOperation
        finishOp.message = "The update failed."
        finishOp.uiParameters = [String]()
      }
    }
  }
  
  func xcancelOperations() {
    print("cancelOperations() <<<<<<<<<<<<<<<<<<<<<<<<<<<< NO LONGER WORKS")

    if let operations: [Operation] = OperationQueue.current?.operations {
      for operation in operations.reversed() {
        if operation.name != "FinishOperation" {
          print("cancelling \(operation.name ?? "(no name)")")
          operation.cancel()
        } else {
          let finishOp = operation as! FinishOperation
          finishOp.message = "The update failed."
          finishOp.uiParameters = [String]()
        }
      }
    } else {
        print("there was no current operation queue")
    }
    
  }
}
