//
//  QRettyCodeData.swift
//  QRettyCode
//
//  Created by Michael Redig on 11/15/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation
import UIKit
import CoreImage
import SwiftyBinaryFormatter

public enum QRCorrectionLevel: String {
	case L
	case M
	case Q
	case H

	var value: CGFloat {
		switch self {
		case .L:
			 return 0.07
		case .M:
			return 0.15
		case .Q:
			return 0.25
		case .H:
			return 0.3
		}
	}
}

public class QRettyCodeData {
	public let data: Data?
	public let correctionLevel: QRCorrectionLevel
	public var flipped: Bool {
		didSet {
			qrData?.flipped = flipped
		}
	}

	public var width: Int?
	public var height: Int?

	var qrData: QRData?

	init(data: Data?, correctionLevel: QRCorrectionLevel = .H, flipped: Bool = false) {
		self.data = data
		self.correctionLevel = correctionLevel
		self.flipped = flipped

		self.qrData = generateQRData()
	}

	public func value(at location: CGPoint) -> Bool { qrData?.value(at: location) == 255 }

	private func generateQRData() -> QRData? {
		let filter = CIFilter(name: "CIQRCodeGenerator")
		filter?.setValue(data, forKey: "inputMessage")
		filter?.setValue(correctionLevel.rawValue, forKey: "inputCorrectionLevel")

		guard let image = filter?.outputImage?.convertedToCGImage else { return nil }

		let width = Int(image.size.width)
		self.width = width
		let height = Int(image.size.height)
		self.height = height

		let bytesPerPixel = image.bitsPerPixel / image.bitsPerComponent

		guard let rawData = image.dataProvider?.data as Data? else { return nil }

		var qrBinaryData = Data()
		for row in 0..<height {
			let offsetStart = image.bytesPerRow * row
			for xOffset in 0..<width {
				let totalOffset = offsetStart + (xOffset + bytesPerPixel)
				guard totalOffset < rawData.count else { break }
				let pixel = rawData[offsetStart + (xOffset * bytesPerPixel)]
				qrBinaryData.append(pixel == 0 ? Byte(255) : Byte(0))
			}
		}

		let qrData = QRData(width: width, height: height, data: qrBinaryData, flipped: flipped)
		return qrData
	}
}

struct QRData {
	let width: Int
	let height: Int
	private let data: Data

	var flipped: Bool

	private var maxHeight: Int { height - 1 }

	init(width: Int, height: Int, data: Data, flipped: Bool) {
		self.width = width
		self.height = height
		self.data = data
		self.flipped = flipped
	}

	func value(at location: CGPoint) -> UInt8 {
		let x = Int(location.x)
		let y = Int(location.y)

		let offset = flipped ?
			(maxHeight - y) * width + x :
			y * width + x

		return data[offset]
	}
}
