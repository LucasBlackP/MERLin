//
//  EventManager.swift
//  TheBay
//
//  Created by Giuseppe Lanza on 08/02/18.
//  Copyright © 2018 Gilt. All rights reserved.
//

import Foundation

public protocol AnyEventsListening: class {
    ///This method allows the event manager to register to a module's events.
    ///- parameter moduel: The module exposing the events
    ///- returns: Bool indicating if the module's events can be handled by the event manager
    @discardableResult func registerToEvents(for anyProducer: UntypedEventsProducer) -> Bool
}

public protocol EventsListening: AnyEventsListening {
    associatedtype EventsType: EventProtocol
    @discardableResult func registerToSpecificEvents(for producer: AnyEventsProducer<EventsType>) -> Bool
}

public extension EventsListening {
    @discardableResult func registerToEvents(for anyProducer: UntypedEventsProducer) -> Bool {
        guard let producer = anyProducer as? AnyEventsProducer<EventsType> else { return false }
        return registerToSpecificEvents(for: producer)
    }
}
