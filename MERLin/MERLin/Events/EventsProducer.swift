//
//  EventsProducer.swift
//  TheBay
//
//  Created by Giuseppe Lanza on 20/03/18.
//  Copyright © 2018 Gilt. All rights reserved.
//

import RxSwift

public protocol UntypedEventsProducer: class {
    var moduleName: String { get }
    var moduleSection: String { get }
    var moduleType: String { get }

    var anyEvents: Observable<EventProtocol> { get }
    var disposeBag: DisposeBag { get }
}

public protocol EventsProducer: UntypedEventsProducer {
    associatedtype EventType: EventProtocol
    var events: Observable<EventType> { get }
}

private var typeErasedSelfHandle: UInt8 = 0
public extension EventsProducer {
    public var anyEvents: Observable<EventProtocol> { return events.toEventProtocol() }
    
    public var typeErasedSelf: AnyEventsProducer<EventType> {
        guard let erasedProducer = objc_getAssociatedObject(self, &typeErasedSelfHandle) as? AnyEventsProducer<EventType> else {
            let erasedProducer = AnyEventsProducer(self)
            objc_setAssociatedObject(self, &typeErasedSelfHandle, erasedProducer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return erasedProducer
        }
        return erasedProducer
    }
}

public extension UntypedEventsProducer {
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

//Type erasure
private class AnyEventsProducerBase<E: EventProtocol>: EventsProducer {
    var moduleName: String { fatalError() }
    var moduleSection: String { fatalError() }
    var moduleType: String { fatalError() }

    var disposeBag: DisposeBag { fatalError() }
    var events: Observable<E> { fatalError() }
}

private class AnyEventsProducerBox<EP: EventsProducer>: AnyEventsProducerBase<EP.EventType> {
    weak var boxedEventsProducer: EP!
    
    override var moduleName: String { return boxedEventsProducer.moduleName }
    override var moduleSection: String { return boxedEventsProducer.moduleSection }
    override var moduleType: String { return boxedEventsProducer.moduleType }

    override var disposeBag: DisposeBag { return boxedEventsProducer.disposeBag }
    override var events: Observable<EP.EventType> { return boxedEventsProducer.events }
    
    init(_ producer: EP) {
        boxedEventsProducer = producer
    }
}

final public class AnyEventsProducer<E: EventProtocol>: EventsProducer {
    private let box: AnyEventsProducerBase<E>
    public var moduleName: String { return box.moduleName }
    public var moduleSection: String { return box.moduleSection }
    public var moduleType: String { return box.moduleType }

    public var events: Observable<E> { return box.events }
    public var disposeBag: DisposeBag { return box.disposeBag }
    
    init<EP: EventsProducer>(_ producer: EP) where EP.EventType == E {
        box = AnyEventsProducerBox(producer)
    }
}
