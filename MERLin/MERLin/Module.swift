//
//  Module.swift
//  Module
//
//  Created by Giuseppe Lanza on 05/02/18.
//  Copyright © 2018 Gilt. All rights reserved.
//

import RxSwift

public enum ViewControllerEvent: EventProtocol {
    case uninitialized
    case initialized
    case appeared
    case disappeared
}


public protocol AnyModule: class, NSObjectProtocol {
    var viewControllerEvent: Observable<ViewControllerEvent> { get }
    
    func unmanagedRootViewController() -> UIViewController
    func prepareRootViewController() -> UIViewController
    
    func toProducer() -> UntypedEventsProducer?
}

public extension AnyModule {
    public func toProducer() -> UntypedEventsProducer? {
        return self as? UntypedEventsProducer
    }
}

public protocol ModuleProtocol: AnyModule {
    associatedtype Context: ModuleBuildContextProtocol
    var context: Context { get }
    
    var routingContext: String { get }
    
    init(usingContext buildContext: Context)
}

public extension ModuleProtocol {
    public var routingContext: String { return context.routingContext }
}

private var viewControllerEventHandle: UInt8 = 0
private var disposeBagHandle:UInt8 = 0
public extension AnyModule where Self: NSObject {
    public var viewControllerEvent: Observable<ViewControllerEvent> { return _viewControllerEvent }
    private var _viewControllerEvent: BehaviorSubject<ViewControllerEvent> {
        guard let observable = objc_getAssociatedObject(self, &viewControllerEventHandle) as? BehaviorSubject<ViewControllerEvent> else {
            let observable = BehaviorSubject<ViewControllerEvent>(value: .uninitialized)
            objc_setAssociatedObject(self, &viewControllerEventHandle, observable, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return observable
        }
        return observable
    }

    public var disposeBag: DisposeBag {
        guard let bag = objc_getAssociatedObject(self, &disposeBagHandle) as? DisposeBag else {
            let bag = DisposeBag()
            objc_setAssociatedObject(self, &disposeBagHandle, bag, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return bag
        }
        return bag
    }
    
    public func prepareRootViewController() -> UIViewController {
        let controller = unmanagedRootViewController()

        _viewControllerEvent.onNext(.initialized)
        let didAppearProducer = controller.rx.sentMessage(#selector(UIViewController.viewDidAppear(_:)))
            .map { _ in ViewControllerEvent.appeared }
        
        let didDisappearProducer = controller.rx.sentMessage(#selector(UIViewController.viewDidDisappear(_:)))
            .map { _ in ViewControllerEvent.disappeared }
        
        Observable.of(didAppearProducer, didDisappearProducer)
            .merge()
            .bind(to: _viewControllerEvent)
            .disposed(by: disposeBag)
        
        return controller
    }
}

public extension AnyModule where Self: EventsProducer {
    public func toProducer() -> UntypedEventsProducer? {
        return typeErasedSelf
    }
}

public extension AnyModule where Self: RoutingEventsProducer {
    public func toProducer() -> UntypedEventsProducer? {
        return typeErasedSelf
    }
}
