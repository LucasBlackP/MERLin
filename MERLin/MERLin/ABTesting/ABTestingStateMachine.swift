//
//  ABTestingStateMachine.swift
//  TheBay
//
//  Created by Giuseppe Lanza on 09/03/18.
//  Copyright © 2018 Giuseppe Lanza. All rights reserved.
//

import Foundation

@objc public enum ReadyState: Int {
    case uninitialized, preparing, ready, error
}

open class ABTestingManagerStateMachine: NSObject {
    @objc public dynamic var state: ReadyState = .uninitialized
    public var error: Error?
}
