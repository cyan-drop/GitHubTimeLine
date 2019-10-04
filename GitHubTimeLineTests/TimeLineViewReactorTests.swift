//
//  TimeLineViewReactorTests.swift
//  GitHubTimeLineTests
//
//  Created by Rinna Izumi on 2019/10/01.
//  Copyright © 2019 cyan. All rights reserved.
//

import XCTest
@testable import GitHubTimeLine

import RxCocoa
import RxSwift
import RxTest
import RxExpect

class TimeLineViewReactorTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testloadRepository() {
        let test = RxExpect()
        let reactor = test.retain(TimeLineViewReactor())
        
        test.input(reactor.action, [Recorded.next(100, .loadRepository)])
        
        let queryData = reactor.state.map { $0.query }
        test.assert(queryData) { query in
            XCTAssertEqual(query, [
                Recorded.next(0, nil),
                Recorded.next(100, "")
                ])
        }
        
        let sinceData = reactor.state.map { $0.since }
        test.assert(sinceData) { since in
            XCTAssertEqual(since, [
                Recorded.next(0, 0),
                Recorded.next(100, 0)
                ])
        }

    }
    
    func testSearchRepository() {
        let test = RxExpect()
        let reactor = test.retain(TimeLineViewReactor())
        test.input(reactor.action, [Recorded.next(100, .searchRepository("Test"))])
        
        let queryData = reactor.state.map { $0.query }
        test.assert(queryData) { query in
            XCTAssertEqual(query, [
                Recorded.next(0, nil),
                Recorded.next(100, "Test")
                ])
        }
        
        let pages = reactor.state.map { $0.nextPage }
        test.assert(pages) { page in
            XCTAssertEqual(page, [
                Recorded.next(0, 0),
                Recorded.next(100, 0)
                ])
        }
    }
    
    
    
    func testloadNextPage() {
        let test = RxExpect()
        let reactor = test.retain(TimeLineViewReactor())

        // input
        test.input(reactor.action, [Recorded.next(100, .loadNextPage)])

        let isLoading = reactor.state.map { $0.isLoadingNextPage }

        // assertion
        test.assert(isLoading) { events in
            XCTAssertEqual(events, [
                Recorded.next(0, false),
                Recorded.next(100, true)
                ])
        }
    }
    
}
