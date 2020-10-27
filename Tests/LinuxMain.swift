import XCTest

import ExpressibleTests

var tests = [XCTestCaseEntry]()
tests += ExpressibleTests.allTests()
XCTMain(tests)
