//
//  EventsTests.swift
//  MERLinTests
//
//  Created by Giuseppe Lanza on 09/09/2018.
//  Copyright © 2018 Giuseppe Lanza. All rights reserved.
//

import XCTest
import RxSwift
import RxTest
@testable import MERLin

enum MockEvent: EventProtocol {
    case noPayload
    case withAnonymousPayload(String)
    case withNamedPayload(payload: String)
}

class EventsTests: XCTestCase {
    var disposeBag: DisposeBag!
    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
    }
    
    override func tearDown() {
        disposeBag = nil
        super.tearDown()
    }
    
    func testThatItCanCaptureAnonymousPayloadEvents() {
        let scheduler = TestScheduler(initialClock: 0)
        let events = scheduler.createHotObservable([
            next(100, MockEvent.withAnonymousPayload("100")),
            next(200, MockEvent.withAnonymousPayload("200")),
            next(300, MockEvent.withNamedPayload(payload: "100")),
            next(400, MockEvent.withAnonymousPayload("400")),
            next(300, MockEvent.noPayload)
            ])
        let results = scheduler.createObserver(String.self)
        
        events.capture(event: MockEvent.withAnonymousPayload)
            .subscribe(results)
            .disposed(by: disposeBag)
        
        scheduler.start()
        
        let expected: [Recorded<Event<String>>] = [
            next(100, "100"),
            next(200, "200"),
            next(400, "400"),
        ]
        
        XCTAssertEqual(results.events, expected)
    }
    
    func testThatItCanCaptureNamedPayloadEvents() {
        let scheduler = TestScheduler(initialClock: 0)
        let events = scheduler.createHotObservable([
            next(100, MockEvent.withNamedPayload(payload: "100")),
            next(200, MockEvent.withAnonymousPayload("200")),
            next(300, MockEvent.withNamedPayload(payload: "100")),
            next(400, MockEvent.withAnonymousPayload("400")),
            next(300, MockEvent.noPayload)
            ])
        let results = scheduler.createObserver(String.self)
        
        events.capture(event: MockEvent.withNamedPayload)
            .subscribe(results)
            .disposed(by: disposeBag)
        
        scheduler.start()
        
        let expected: [Recorded<Event<String>>] = [
            next(100, "100"),
            next(300, "100"),
            ]
        
        XCTAssertEqual(results.events, expected)
    }
    
    func testThatItCanCaptureNoPayloadEvents() {
        let scheduler = TestScheduler(initialClock: 0)
        let events = scheduler.createHotObservable([
            next(100, MockEvent.noPayload),
            next(200, MockEvent.noPayload),
            next(300, MockEvent.withNamedPayload(payload: "100")),
            next(400, MockEvent.withAnonymousPayload("400")),
            next(300, MockEvent.noPayload)
            ])
        let results = scheduler.createObserver(String.self)
        
        events.capture(event: MockEvent.noPayload)
            .map { _ in "" }
            .subscribe(results)
            .disposed(by: disposeBag)
        
        scheduler.start()
        
        let expected: [Recorded<Event<String>>] = [
            next(100, ""),
            next(200, ""),
            next(300, ""),
            ]
        
        XCTAssertEqual(results.events, expected)
    }
}
