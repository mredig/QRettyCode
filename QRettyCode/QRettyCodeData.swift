//
//  QRettyCodeData.swift
//  QRettyCode
//
//  Created by Michael Redig on 11/15/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation
import CoreImage
import SwiftyBinaryFormatter

public enum QRCorrectionLevel: String {
	case L
	case M
	case Q
	case H
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

	init(data: Data?, correctionLevel: QRCorrectionLevel = .H, flipped: Bool = true) {
		self.data = data
		self.correctionLevel = correctionLevel
		self.flipped = flipped

		self.qrData = generateQRData()
	}

	public func value(at location: CGPoint) -> Bool {
		return qrData?.value(at: location) == 1
	}

	private func generateQRData() -> QRData? {
		let filter = CIFilter(name: "CIQRCodeGenerator")
		filter?.setValue(data, forKey: "inputMessage")
		filter?.setValue(correctionLevel.rawValue, forKey: "inputCorrectionLevel")

		guard let image = filter?.outputImage?.convertedToCGImage else { return nil }

		UIGraphicsBeginImageContext(image.size)
		guard let context = UIGraphicsGetCurrentContext() else { return nil }
		context.draw(image, in: image.bounds)

		let width = Int(image.size.width)
		self.width = width
		let height = Int(image.size.height)
		self.height = height

		guard let data1 = context.data?.assumingMemoryBound(to: UInt8.self) else { print("No data"); return nil }
		let bytesPerPixel = image.bitsPerPixel / image.bitsPerComponent
		let contextWidth = width.nearestMultipleOf8
		let data2 = UnsafeBufferPointer(start: data1, count: contextWidth * height * bytesPerPixel)
		let tData = Data(buffer: data2)
		UIGraphicsEndImageContext()

		var qrBinaryData = BinaryFormatter()
		for (index, pixel) in tData.enumerated() where index.isMultiple(of: bytesPerPixel) {
			qrBinaryData.append(element: pixel == 0 ? BinaryFormatter.Byte(1) : BinaryFormatter.Byte(0))
		}

		let qrData = QRData(width: width, height: height, data: qrBinaryData, flipped: flipped)
		return qrData
	}
}

struct QRData {
	let width: Int
	let height: Int
	let data: BinaryFormatter

	private var renderedData: Data

	init(width: Int, height: Int, data: BinaryFormatter, flipped: Bool) {
		self.width = width
		self.height = height
		self.data = data
		self.renderedData = data.renderedData
		self.flipped = flipped
	}

	var flipped: Bool

	private var maxHeight: Int {
		return height - 1
	}
	func value(at location: CGPoint) -> UInt8 {
		let x = Int(location.x)
		let y = Int(location.y)

		let contextWidth = width.nearestMultipleOf8
		let offset = flipped ?
			(maxHeight - y) * contextWidth + x :
			y * contextWidth + x

		return renderedData[offset]
	}
}
