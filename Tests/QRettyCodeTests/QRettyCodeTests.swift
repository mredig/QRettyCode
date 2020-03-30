//
//  QRettyCodeTests.swift
//  QRettyCodeTests
//
//  Created by Michael Redig on 11/15/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import XCTest
@testable import QRettyCode

class QRettyCodeTests: XCTestCase {
    func testQRGenEmptyData() {
		let qrData = QRettyCodeData(data: "".data(using: .utf8))

		XCTAssertEqual(23, qrData.width)
		XCTAssertEqual(23, qrData.height)

		var rawQRData = [UInt8]()
		for y in 0..<qrData.height! {
			for x in 0..<qrData.width! {
				rawQRData.append(qrData.value(at: CGPoint(x: x, y: y)) ? 255 : 0)
			}
		}

		XCTAssertEqual(emptyQRDataHex, Data(rawQRData).hexString)
    }

	func testShortString() {
		let qrData = QRettyCodeData(data: "Test".data(using: .utf8))

		XCTAssertEqual(23, qrData.width)
		XCTAssertEqual(23, qrData.height)

		var rawQRData = [UInt8]()
		for y in 0..<qrData.height! {
			for x in 0..<qrData.width! {
				rawQRData.append(qrData.value(at: CGPoint(x: x, y: y)) ? 255 : 0)
			}
		}

		XCTAssertEqual(shortQRDataHex, Data(rawQRData).hexString)
	}

	func testMediumString() {
		let qrData = QRettyCodeData(data: "https://swaap.co/connect/974A2B4C-2A6C-473D-8B15-639BDCB4A70B".data(using: .utf8))

		XCTAssertEqual(47, qrData.width)
		XCTAssertEqual(47, qrData.height)

		var rawQRData = [UInt8]()
		for y in 0..<qrData.height! {
			for x in 0..<qrData.width! {
				rawQRData.append(qrData.value(at: CGPoint(x: x, y: y)) ? 255 : 0)
			}
		}

		XCTAssertEqual(mediumQRDataHex, Data(rawQRData).hexString)
	}

	func testLongString() {
		let qrData = QRettyCodeData(data: "This is the song that doesn't end. Yes, it goes on and on my friends. Some people started singing it, not knowing what it was, And they'll continue singing it forever just because This is the song that doesn't end. Yes, it goes on and on my friends. Some people started singing it, not knowing what it was, And they'll continue singing it forever just because this is the song that doesn’t end. Yes it goes on and on my friends. Some people started singing it, not knowing what it was, and they’ll continue singing it forever just because".data(using: .utf8))

		XCTAssertEqual(123, qrData.width)
		XCTAssertEqual(123, qrData.height)

		var rawQRData = [UInt8]()
		for y in 0..<qrData.height! {
			for x in 0..<qrData.width! {
				rawQRData.append(qrData.value(at: CGPoint(x: x, y: y)) ? 255 : 0)
			}
		}

		XCTAssertEqual(longQRDataHex, Data(rawQRData).hexString)
	}
}
