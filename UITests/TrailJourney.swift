import XCTest

final class TrailJourney: XCTestCase {
    func testReferenceRoutesAndLegacyNotebook() throws {
        XCTAssertEqual(Yard.levels.count,24)
        XCTAssertEqual(Set(Yard.levels.map(\.title)).count,24)
        for yard in Yard.levels {
            XCTAssertFalse(yard.trace(yard.initial).success,yard.title)
            let trace=yard.trace(yard.solution)
            XCTAssertTrue(trace.success,yard.title)
            let walked=Dictionary(grouping:trace.steps,by:\.chick).values.map { $0.map(\.cell) }
            XCTAssertEqual(Set(walked),Set(yard.referenceRoutes),yard.title)
        }
        let legacy:[String:Any]=["level":2,"boards":Yard.levels.prefix(3).map(\.solution),"finished":[0,1]]
        let restored=YardBook.restore(try JSONSerialization.data(withJSONObject:legacy))
        XCTAssertEqual(restored.level,2); XCTAssertEqual(restored.boards.count,24)
        XCTAssertEqual(restored.boards[2],Yard.levels[2].solution); XCTAssertEqual(restored.finished,[0,1])
        XCTAssertEqual(restored.boards[23],Yard.levels[23].initial)
    }

    @MainActor func testWalkAllTwentyFourTrails() throws {
        continueAfterFailure=false
        let app=XCUIApplication()
        app.launchEnvironment["UI_TEST_SUITE"]="test.trails."+UUID().uuidString
        app.launch()
        func shot(_ name:String) {
            let a=XCTAttachment(screenshot:app.screenshot());a.name=name;a.lifetime = .keepAlways;add(a)
        }
        let release=app.buttons["release"]
        XCTAssertTrue(release.waitForExistence(timeout:10))
        shot("01-Chalk-Downs")
        release.tap()
        XCTAssertTrue(app.descendants(matching:.any)["blocked"].firstMatch.waitForExistence(timeout:6))
        app.buttons["Hint"].tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format:"label BEGINSWITH 'Try turning'")).firstMatch.exists)
        app.buttons["track-5"].tap()
        app.buttons["Undo"].tap()
        for (index,yard) in Yard.levels.enumerated() {
            XCTAssertTrue(app.staticTexts[yard.title].waitForExistence(timeout:5),yard.title)
            for cell in yard.tiles.indices {
                let turns=yard.tiles[cell].turns
                let needed=(yard.solution[cell]-yard.initial[cell]+turns)%turns
                for _ in 0..<needed { app.buttons["track-\(cell)"].tap() }
            }
            if index==2 { app.terminate(); app.launch(); XCTAssertTrue(app.staticTexts[yard.title].waitForExistence(timeout:8)) }
            if index==13 { shot("02-Mill-crossing") }
            if index==23 { shot("03-Lantern-Orchard") }
            release.tap()
            XCTAssertTrue(app.descendants(matching:.any)["home"].firstMatch.waitForExistence(timeout:12),yard.title)
            if index==2 { shot("04-Two-chicks-home") }
            if index==23 { shot("05-Atlas-complete") }
            release.tap()
        }
        XCTAssertTrue(app.staticTexts["Trail atlas"].waitForExistence(timeout:6))
        shot("06-Trail-atlas")
        app.buttons["region-0"].tap();app.buttons["yard-0"].tap()
        XCTAssertTrue(app.staticTexts["Sunlit Lane"].waitForExistence(timeout:6))
        app.buttons["Reset"].tap();release.tap()
        XCTAssertTrue(app.descendants(matching:.any)["blocked"].firstMatch.waitForExistence(timeout:6))
        XCUIDevice.shared.orientation = .landscapeLeft
        let settled=expectation(for:NSPredicate { _,_ in
            let bounds=app.windows.firstMatch.frame
            return bounds.width > bounds.height
        }, evaluatedWith:app)
        wait(for:[settled], timeout:8)
        // An accessibility query may finish before UIKit finishes its rotation animation.
        RunLoop.current.run(until:Date(timeIntervalSinceNow:0.9))
        let landscape=XCTAttachment(screenshot:XCUIScreen.main.screenshot())
        landscape.name="07-Landscape";landscape.lifetime = .keepAlways;add(landscape)
        XCUIDevice.shared.orientation = .portrait
    }
}

final class TrailLayout: XCTestCase {
    @MainActor func testLandscapeControls() {
        continueAfterFailure=false
        let device=XCUIDevice.shared
        device.orientation = .landscapeLeft
        defer { device.orientation = .portrait }
        let app=XCUIApplication()
        app.launchEnvironment["UI_TEST_SUITE"]="test.wide."+UUID().uuidString
        app.launch()
        XCTAssertTrue(app.buttons["release"].waitForExistence(timeout:8))
        XCTAssertGreaterThan(app.windows.firstMatch.frame.width,app.windows.firstMatch.frame.height)
        let screen=XCTAttachment(screenshot:XCUIScreen.main.screenshot())
        screen.name="Landscape-field";screen.lifetime = .keepAlways;add(screen)
        app.buttons["track-5"].tap();app.buttons["release"].tap()
        XCTAssertTrue(app.descendants(matching:.any)["home"].firstMatch.waitForExistence(timeout:6))
        app.buttons["yards"].tap();app.buttons["region-1"].tap()
        XCTAssertTrue(app.buttons["yard-8"].exists)
    }
}

final class LocalizedTrails: XCTestCase {
    @MainActor func testBoardAtlasAndLanguageSwitch() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["UI_TEST_SUITE"] = "test.locale.trails." + UUID().uuidString
        for (lang, region, title, atlas, home, rightToLeft) in [
            ("ar", "ar_SA", "درب الشمس", "أطلس الدروب", "عادت كل الكتاكيت!", true),
            ("zh-Hant", "zh_TW", "晴光小徑", "小徑地圖集", "小雞都到家了！", false)
        ] {
            app.launchArguments = ["-AppleLanguages", "(\(lang))", "-AppleLocale", region]
            app.launch()
            XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 8))
            let atlasButton = app.buttons["yards"]
            let brand = app.staticTexts["Chickososik"]
            XCTAssertEqual(atlasButton.label, atlas)
            XCTAssertEqual(atlasButton.frame.midX < brand.frame.midX, rightToLeft)
            let tile = app.buttons["track-5"]
            XCTAssertTrue(tile.label.contains(rightToLeft ? "اليسار" : "欄"))
            if rightToLeft { tile.tap() } // The second launch reuses the first language's solved board.
            app.buttons["release"].tap()
            XCTAssertTrue(app.staticTexts[home].waitForExistence(timeout: 8))
            atlasButton.tap()
            XCTAssertTrue(app.staticTexts[atlas].waitForExistence(timeout: 4))
            let first = app.buttons["region-0"], last = app.buttons["region-2"]
            XCTAssertEqual(first.frame.midX > last.frame.midX, rightToLeft)
            first.tap()
            XCTAssertTrue(app.buttons["yard-0"].label.contains(rightToLeft ? "مكتمل" : "已完成"))
            app.buttons["yard-0"].tap()
            app.terminate()
        }
    }
}
