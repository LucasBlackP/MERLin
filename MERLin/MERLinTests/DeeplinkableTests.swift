//
//  DeeplinkableTests.swift
//  DeeplinkableTests
//
//  Created by Giuseppe Lanza on 06/03/18.
//  Copyright © 2018 Gilt. All rights reserved.
//

import XCTest
@testable import MERLin

class MockController: UIViewController { }

class MockDeeplinkable: NSObject, ModuleProtocol, Deeplinkable {
    var viewController: UIViewController = MockViewController()
    var context: ModuleBuildContextProtocol
    
    static var deeplinkSchemaNames: [String] = ["test"]

    static func classForDeeplinkingViewController() -> UIViewController.Type {
        return MockController.self
    }
    
    init(withBuildContext context: ModuleContext) {
        self.context = context
    }
    
    static func module(fromDeeplink deeplink: String) -> (ModuleProtocol, UIViewController)? {
        let module = MockDeeplinkable(withBuildContext: ModuleContext())
        return (module, module.prepareRootViewController())
    }
    
    func deeplinkURL() -> URL? {
        return URL(string: "test://mock")
    }
    
    static func deeplinkRegexes() -> [NSRegularExpression]? {
        let regEx = try! NSRegularExpression(pattern: "\\btest\\:\\/\\/mock\\/?([0-9]*)", options: .caseInsensitive)
        let productRegEx = try! NSRegularExpression(pattern: "\\btest\\:\\/\\/product\\/?([0-9]+)", options: .caseInsensitive)
        return [regEx, productRegEx]
    }
}

class DeeplinkableTests: XCTestCase {
    
    func testThatMockIsIncludedInAvailableDeeplinkHandlers() {
        let mockType = DeeplinkMatcher.typedAvailableDeeplinkHandlers.values.filter { (type) -> Bool in
            return type == MockDeeplinkable.self
        }
        XCTAssertEqual(mockType.count, MockDeeplinkable.deeplinkRegexes()!.count)
    }
    
    func testThatMockRegularExpressionsAreInAvailableDeeplinkHandlers() {
        let regExp = DeeplinkMatcher.typedAvailableDeeplinkHandlers.keys.filter { (regEx) -> Bool in
            return DeeplinkMatcher.typedAvailableDeeplinkHandlers[regEx] == MockDeeplinkable.self
        }
        
        XCTAssertEqual(Set(regExp), Set(MockDeeplinkable.deeplinkRegexes()!))
    }
    
    func testDeeplinkRemainder() {
        let deeplink = "test://mock/product/1234"
        let expectedRemainder = "test://product/1234"
        
        let remainder = MockDeeplinkable.remainderDeeplink(fromDeeplink: deeplink)
        XCTAssertNotNil(remainder)
        
        XCTAssertEqual(remainder, expectedRemainder)
    }

    func testDeeplinkRemainderWithMatchingGroup() {
        let deeplink = "test://mock/2341234/product/1234"
        let expectedRemainder = "test://product/1234"
        
        let remainder = MockDeeplinkable.remainderDeeplink(fromDeeplink: deeplink)
        XCTAssertNotNil(remainder)
        
        XCTAssertEqual(remainder, expectedRemainder)
    }

    func testNoRemainder() {
        let deeplink = "test://mock/"
        let remainder = MockDeeplinkable.remainderDeeplink(fromDeeplink: deeplink)
        
        XCTAssertNil(remainder)
    }
    
    func testThatDefaultImplementationCanBeAccessedByDeeplinkableType() {
        let type: Deeplinkable.Type = MockDeeplinkable.self
        
        let deeplink = "test://mock/2341234/product/1234"
        let expectedRemainder = "test://product/1234"
        
        let remainder = type.remainderDeeplink(fromDeeplink: deeplink)
        XCTAssertNotNil(remainder)
        
        XCTAssertEqual(remainder, expectedRemainder)
    }
    
    func testThatItCanExaustRemainders() {
        let deeplink = "test://mock/2341234/product/1234"
        let expectedRemainder = "test://product/1234"
        
        let remainder = MockDeeplinkable.remainderDeeplink(fromDeeplink: deeplink)
        XCTAssertNotNil(remainder)
        XCTAssertEqual(remainder, expectedRemainder)

        guard let newDeepLink = remainder else {
            XCTFail()
            return
        }
        let secondRemainder = MockDeeplinkable.remainderDeeplink(fromDeeplink: newDeepLink)
        XCTAssertNil(secondRemainder)
    }
}
