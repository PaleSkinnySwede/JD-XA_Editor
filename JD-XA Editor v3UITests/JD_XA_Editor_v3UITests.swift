//
//  JD_XA_Editor_v3UITests.swift
//  JD-XA Editor v3UITests
//
//  Created by David Lilja on 2024-12-27.
//

import XCTest

final class JD_XA_Editor_v3UITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    /// ⌘1–⌘3 select a partial and must not flip its on/off switch.
    func testCommandNumberSelectsPartialWithoutTogglingIt() throws {
        let app = XCUIApplication()
        app.launch()
        let window = app.windows.firstMatch
        XCTAssertTrue(window.staticTexts["Editing Partial 1"].waitForExistence(timeout: 5))

        for partial in [2, 3, 1] {
            window.typeKey("\(partial)", modifierFlags: .command)
            XCTAssertTrue(window.staticTexts["Editing Partial \(partial)"].waitForExistence(timeout: 2),
                          "⌘\(partial) should select Partial \(partial)")
        }

        for partial in 1...3 {
            let toggle = window.descendants(matching: .any)["partial-\(partial)-switch"]
            XCTAssertTrue(toggle.exists, "Partial \(partial) switch not found")
            XCTAssertEqual(toggle.value as? Int, 1, "Partial \(partial) should still be on")
        }
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
