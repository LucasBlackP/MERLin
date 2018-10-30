//
//  RouteEventsListening.swift
//  MERLin
//
//  Created by Giuseppe Lanza on 30/10/2018.
//  Copyright © 2018 Giuseppe Lanza. All rights reserved.
//

import Foundation
import RxSwift

public protocol AnyRouteEventsListening: AnyEventsListening {
    var router: Router { get }
    
    @discardableResult func registerToEvents(for anyProducer: UntypedRoutingEventsProducer) -> Bool
}

public extension AnyRouteEventsListening {
    @discardableResult func registerToEvents(for anyProducer: UntypedEventsProducer) -> Bool {
        guard let routing = anyProducer as? UntypedRoutingEventsProducer else { return false }
        return registerToEvents(for: routing)
    }
}

public protocol RouteEventsListening: AnyRouteEventsListening {
    associatedtype EventsType: EventProtocol
    @discardableResult func registerToSpecificEvents(for anyProducer: AnyRoutingEventsProducer<EventsType>) -> Bool
}

public extension RouteEventsListening {
    @discardableResult func registerToEvents(for anyProducer: UntypedEventsProducer) -> Bool {
        guard let producer = anyProducer as? AnyRoutingEventsProducer<EventsType> else { return false }
        return registerToSpecificEvents(for: producer)
    }
}
