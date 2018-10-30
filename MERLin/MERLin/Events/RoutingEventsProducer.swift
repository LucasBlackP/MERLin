//
//  RoutingEventsProducer.swift
//  MERLin
//
//  Created by Giuseppe Lanza on 30/10/2018.
//  Copyright © 2018 Giuseppe Lanza. All rights reserved.
//

import Foundation
import RxSwift

public protocol UntypedRoutingEventsProducer: UntypedEventsProducer {
    var viewControllerEvent: Observable<ViewControllerEvent> { get }
    
    var routingContext: String { get }
    var currentViewController: UIViewController? { get }
}

public protocol RoutingEventsProducer: UntypedRoutingEventsProducer {
    associatedtype EventType: EventProtocol
    var events: Observable<EventType> { get }
}

private var typeErasedSelfHandle: UInt8 = 0
public extension RoutingEventsProducer {
    public var anyEvents: Observable<EventProtocol> { return events.toEventProtocol() }
    
    public var typeErasedSelf: AnyRoutingEventsProducer<EventType> {
        guard let erasedProducer = objc_getAssociatedObject(self, &typeErasedSelfHandle) as? AnyRoutingEventsProducer<EventType> else {
            let erasedProducer = AnyRoutingEventsProducer(self)
            objc_setAssociatedObject(self, &typeErasedSelfHandle, erasedProducer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return erasedProducer
        }
        return erasedProducer
    }
}

//Type erasure
private class AnyRoutingEventsProducerBase<E: EventProtocol>: RoutingEventsProducer {
    var moduleName: String { fatalError() }
    var moduleSection: String { fatalError() }
    var moduleType: String { fatalError() }

    var viewControllerEvent: Observable<ViewControllerEvent> { fatalError() }
    
    var routingContext: String { fatalError() }
    var currentViewController: UIViewController? { fatalError() }

    var disposeBag: DisposeBag { fatalError() }
    var events: Observable<E> { fatalError() }
}

private class AnyRoutingEventsProducerBox<EP: RoutingEventsProducer>: AnyRoutingEventsProducerBase<EP.EventType> {
    let boxedEventsProducer: EP
    override var moduleName: String { return boxedEventsProducer.moduleName }
    override var moduleSection: String { return boxedEventsProducer.moduleSection }
    override var moduleType: String { return boxedEventsProducer.moduleType }

    override var disposeBag: DisposeBag { return boxedEventsProducer.disposeBag }
    override var events: Observable<EP.EventType> { return boxedEventsProducer.events }
    
    init(_ producer: EP) {
        boxedEventsProducer = producer
    }
}

final public class AnyRoutingEventsProducer<E: EventProtocol>: RoutingEventsProducer {
    private let box: AnyRoutingEventsProducerBase<E>
    public var moduleName: String { return box.moduleName }
    public var moduleSection: String { return box.moduleSection }
    public var moduleType: String { return box.moduleType }

    public var viewControllerEvent: Observable<ViewControllerEvent> { return box.viewControllerEvent }
    
    public var routingContext: String { return box.routingContext }
    public var currentViewController: UIViewController? { return box.currentViewController }
    
    public var disposeBag: DisposeBag { return box.disposeBag }
    public var events: Observable<E> { return box.events }
    
    public init<EP: RoutingEventsProducer>(_ producer: EP) where EP.EventType == E {
        box = AnyRoutingEventsProducerBox(producer)
    }
}
