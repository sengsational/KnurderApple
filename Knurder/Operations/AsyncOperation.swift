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
    
    main()
    state = .executing
  }
  
  override open func cancel() {
    super.cancel()
    state = .finished
  }
  
  func cancelOperations() {
    if let operations: [Operation] = (OperationQueue.current?.operations) {
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
        print("there were no operations")
    }
  }
}
