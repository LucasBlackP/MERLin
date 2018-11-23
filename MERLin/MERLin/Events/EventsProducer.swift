//
//  EventsProducer.swift
//  TheBay
//
//  Created by Giuseppe Lanza on 20/03/18.
//  Copyright © 2018 Giuseppe Lanza. All rights reserved.
//

import RxSwift


public class EventsProxy<E: EventProtocol> {
    public var events: Observable<E>
    fileprivate init(events: Observable<E>) {
        self.events = events
    }
    
    public func capture(event target: E) -> Observable<E> {
        return events.capture(event: target)
    }
    
    public func capture<Payload>(event pattern: @escaping (Payload) -> E) -> Observable<Payload> {
        return events.capture(event: pattern)
    }
    
    public subscript(event target: E) -> Observable<E> {
        return capture(event: target)
    }
    
    public subscript<Payload>(event pattern: @escaping (Payload) -> E) -> Observable<Payload> {
        return capture(event: pattern)
    }

}

public class RoutingEventsProxy<E: EventProtocol>: EventsProxy<E> {
    var viewControllerEvent: Observable<ViewControllerEvent>
    
    var routingContext: String
    var currentViewController: UIViewController? { return currentVCGetter() }
    
    var currentVCGetter: ()->UIViewController?
    
    fileprivate init(ctx: String, currentVC: @escaping ()->UIViewController?, vcEvents: Observable<ViewControllerEvent>, events: Observable<E>) {
        routingContext = ctx
        currentVCGetter = currentVC
        viewControllerEvent = vcEvents
        super.init(events: events)
    }
}


public protocol AnyEventsProducer: class {
    var moduleName: String { get }
    var moduleSection: String { get }
    var moduleType: String { get }

    var disposeBag: DisposeBag { get }
    var anyEvents: Observable<EventProtocol> { get }
    
    func eventsProxy<E: EventProtocol>(_ type: E.Type) -> EventsProxy<E>?
}

public protocol EventsProducer: AnyEventsProducer {
    associatedtype EventsType: EventProtocol
    
    var events: Observable<EventsType> { get }
}

public protocol RoutingEventsProducer: EventsProducer {
    var viewControllerEvent: Observable<ViewControllerEvent> { get }
    
    var routingContext: String { get }
    var currentViewController: UIViewController? { get }
}

public extension AnyEventsProducer {
    public func capture<E: EventProtocol>(event target: E) -> Observable<E> {
        return anyEvents.capture(event: target)
    }
    
    public func capture<E: EventProtocol, Payload>(event pattern: @escaping (Payload) -> E) -> Observable<Payload> {
        return anyEvents.capture(event: pattern)
    }
    
    public subscript<E: EventProtocol>(event target: E) -> Observable<E> {
        return capture(event: target)
    }
    
    public subscript<E: EventProtocol, Payload>(event pattern: @escaping (Payload) -> E) -> Observable<Payload> {
        return capture(event: pattern)
    }
}

public extension EventsProducer {
    public var anyEvents: Observable<EventProtocol> { return events.toEventProtocol() }
    
    public func eventsProxy<E: EventProtocol>(_ type: E.Type) -> EventsProxy<E>? {
        guard let e = events as? Observable<E> else { return nil }
        return EventsProxy(events: e)
    }
}

public extension RoutingEventsProducer {
    public func eventsProxy<E: EventProtocol>(_ type: E.Type) -> EventsProxy<E>? {
        guard let e = events as? Observable<E> else { return nil }
        return RoutingEventsProxy(ctx: routingContext, currentVC: { [weak self] in self?.currentViewController }, vcEvents: viewControllerEvent, events: e)
    }
}
