//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import XCTest
import TestHelpers
import ArgumentParser

final class FlagsEndToEndTests: XCTestCase {
}

// MARK: -

fileprivate struct Bar: ParsableArguments {
  @Flag()
  var verbose: Bool
  
  @Flag(inversion: .prefixedNo)
  var extattr: Bool
}

extension FlagsEndToEndTests {
  func testParsing_defaultValue() throws {
    AssertParse(Bar.self, []) { options in
      XCTAssertEqual(options.verbose, false)
      XCTAssertEqual(options.extattr, false)
    }
  }
  
  func testParsing_settingValue() throws {
    AssertParse(Bar.self, ["--verbose"]) { options in
      XCTAssertEqual(options.verbose, true)
      XCTAssertEqual(options.extattr, false)
    }
    
    AssertParse(Bar.self, ["--extattr"]) { options in
      XCTAssertEqual(options.verbose, false)
      XCTAssertEqual(options.extattr, true)
    }
  }
  
  func testParsing_invert() throws {
    AssertParse(Bar.self, ["--no-extattr"]) { options in
      XCTAssertEqual(options.extattr, false)
    }
    AssertParse(Bar.self, ["--extattr", "--no-extattr"]) { options in
      XCTAssertEqual(options.extattr, false)
    }
    AssertParse(Bar.self, ["--extattr", "--no-extattr", "--no-extattr"]) { options in
      XCTAssertEqual(options.extattr, false)
    }
    AssertParse(Bar.self, ["--no-extattr", "--no-extattr", "--extattr"]) { options in
      XCTAssertEqual(options.extattr, true)
    }
    AssertParse(Bar.self, ["--extattr", "--no-extattr", "--extattr"]) { options in
      XCTAssertEqual(options.extattr, true)
    }
  }
}

fileprivate struct Foo: ParsableArguments {
  @Flag(default: false, inversion: .prefixedEnableDisable)
  var index: Bool
  @Flag(default: true, inversion: .prefixedEnableDisable)
  var sandbox: Bool
  @Flag(default: nil, inversion: .prefixedEnableDisable)
  var requiredElement: Bool
}

extension FlagsEndToEndTests {
  func testParsingEnableDisable_defaultValue() throws {
    AssertParse(Foo.self, ["--enable-required-element"]) { options in
      XCTAssertEqual(options.index, false)
      XCTAssertEqual(options.sandbox, true)
      XCTAssertEqual(options.requiredElement, true)
    }
  }
  
  func testParsingEnableDisable_disableAll() throws {
    AssertParse(Foo.self, ["--disable-index", "--disable-sandbox", "--disable-required-element"]) { options in
      XCTAssertEqual(options.index, false)
      XCTAssertEqual(options.sandbox, false)
      XCTAssertEqual(options.requiredElement, false)
    }
  }
  
  func testParsingEnableDisable_enableAll() throws {
    AssertParse(Foo.self, ["--enable-index", "--enable-sandbox", "--enable-required-element"]) { options in
      XCTAssertEqual(options.index, true)
      XCTAssertEqual(options.sandbox, true)
      XCTAssertEqual(options.requiredElement, true)
    }
  }
  
  func testParsingEnableDisable_Fails() throws {
    XCTAssertThrowsError(try Foo.parse([]))
    XCTAssertThrowsError(try Foo.parse(["--disable-index"]))
    XCTAssertThrowsError(try Foo.parse(["--disable-sandbox"]))
  }
}

enum Color: String, EnumerableFlag {
  case pink
  case purple
  case silver
}

enum Size: String, EnumerableFlag {
  case small
  case medium
  case large
  case extraLarge
  case humongous
  
  static func name(for value: Size) -> NameSpecification {
    switch value {
    case .humongous: return .customLong("huge")
    default: return .long
    }
  }
}

enum Shape: String, EnumerableFlag {
  case round
  case square
  case oblong
}

fileprivate struct Baz: ParsableArguments {
  @Flag()
  var color: Color
  
  @Flag(default: .small)
  var size: Size
  
  @Flag()
  var shape: Shape?
}

extension FlagsEndToEndTests {
  func testParsingCaseIterable_defaultValues() throws {
    AssertParse(Baz.self, ["--pink"]) { options in
      XCTAssertEqual(options.color, .pink)
      XCTAssertEqual(options.size, .small)
      XCTAssertEqual(options.shape, nil)
    }
    
    AssertParse(Baz.self, ["--pink", "--medium"]) { options in
      XCTAssertEqual(options.color, .pink)
      XCTAssertEqual(options.size, .medium)
      XCTAssertEqual(options.shape, nil)
    }
    
    AssertParse(Baz.self, ["--pink", "--round"]) { options in
      XCTAssertEqual(options.color, .pink)
      XCTAssertEqual(options.size, .small)
      XCTAssertEqual(options.shape, .round)
    }
  }
  
  func testParsingCaseIterable_AllValues() throws {
    AssertParse(Baz.self, ["--pink", "--small", "--round"]) { options in
      XCTAssertEqual(options.color, .pink)
      XCTAssertEqual(options.size, .small)
      XCTAssertEqual(options.shape, .round)
    }
    
    AssertParse(Baz.self, ["--purple", "--medium", "--square"]) { options in
      XCTAssertEqual(options.color, .purple)
      XCTAssertEqual(options.size, .medium)
      XCTAssertEqual(options.shape, .square)
    }
    
    AssertParse(Baz.self, ["--silver", "--large", "--oblong"]) { options in
      XCTAssertEqual(options.color, .silver)
      XCTAssertEqual(options.size, .large)
      XCTAssertEqual(options.shape, .oblong)
    }
  }
  
  func testParsingCaseIterable_CustomName() throws {
    AssertParse(Baz.self, ["--pink", "--extra-large"]) { options in
      XCTAssertEqual(options.color, .pink)
      XCTAssertEqual(options.size, .extraLarge)
      XCTAssertEqual(options.shape, nil)
    }
    
    AssertParse(Baz.self, ["--pink", "--huge"]) { options in
      XCTAssertEqual(options.color, .pink)
      XCTAssertEqual(options.size, .humongous)
      XCTAssertEqual(options.shape, nil)
    }
  }
  
  func testParsingCaseIterable_Fails() throws {
    // Missing color
    XCTAssertThrowsError(try Baz.parse([]))
    XCTAssertThrowsError(try Baz.parse(["--large", "--square"]))
    // Repeating flags
    XCTAssertThrowsError(try Baz.parse(["--pink", "--purple"]))
    XCTAssertThrowsError(try Baz.parse(["--pink", "--small", "--large"]))
    XCTAssertThrowsError(try Baz.parse(["--pink", "--round", "--square"]))
    // Case name instead of raw value
    XCTAssertThrowsError(try Baz.parse(["--pink", "--extraLarge"]))
  }
}

fileprivate struct Qux: ParsableArguments {
  @Flag()
  var color: [Color]
  
  @Flag()
  var size: [Size]
}

extension FlagsEndToEndTests {
  func testParsingCaseIterableArray_Values() throws {
    AssertParse(Qux.self, []) { options in
      XCTAssertEqual(options.color, [])
      XCTAssertEqual(options.size, [])
    }
    AssertParse(Qux.self, ["--pink"]) { options in
      XCTAssertEqual(options.color, [.pink])
      XCTAssertEqual(options.size, [])
    }
    AssertParse(Qux.self, ["--pink", "--purple", "--small"]) { options in
      XCTAssertEqual(options.color, [.pink, .purple])
      XCTAssertEqual(options.size, [.small])
    }
    AssertParse(Qux.self, ["--pink", "--small", "--purple", "--medium"]) { options in
      XCTAssertEqual(options.color, [.pink, .purple])
      XCTAssertEqual(options.size, [.small, .medium])
    }
    AssertParse(Qux.self, ["--pink", "--pink", "--purple", "--pink"]) { options in
      XCTAssertEqual(options.color, [.pink, .pink, .purple, .pink])
      XCTAssertEqual(options.size, [])
    }
  }
  
  func testParsingCaseIterableArray_Fails() throws {
    XCTAssertThrowsError(try Qux.parse(["--pink", "--small", "--bloop"]))
  }
}


fileprivate struct DeprecatedFlags: ParsableArguments {
  enum One: String, CaseIterable {
    case one
  }
  enum Two: String, CaseIterable {
    case two
  }
  enum Three: String, CaseIterable {
    case three
    case four
  }

  @Flag() var single: One
  @Flag() var optional: Two?
  @Flag() var array: [Three]
}

extension FlagsEndToEndTests {
  func testParsingDeprecatedFlags() throws {
    AssertParse(DeprecatedFlags.self, ["--one"]) { options in
      XCTAssertEqual(options.single, .one)
      XCTAssertNil(options.optional)
      XCTAssertTrue(options.array.isEmpty)
    }

    AssertParse(DeprecatedFlags.self, ["--one", "--two", "--three", "--four", "--three"]) { options in
      XCTAssertEqual(options.single, .one)
      XCTAssertEqual(options.optional, .two)
      XCTAssertEqual(options.array, [.three, .four, .three])
    }
  }
}
