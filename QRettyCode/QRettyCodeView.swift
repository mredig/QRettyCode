//
//  QRettyCodeView.swift
//  QRettyCode
//
//  Created by Michael Redig on 11/13/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import UIKit
import CoreImage
import SwiftyBinaryFormatter

public class QRettyCodeView: UIView {

	public enum CorrectionLevel: String {
		case L
		case M
		case Q
		case H
	}

	public var data: Data? {
		didSet {
			setNeedsDisplay()
		}
	}
	public var correctionLevel = CorrectionLevel.H
	public var image: UIImage?

	public override func draw(_ rect: CGRect) {
		guard let qrData = generateQRData() else { return }
		guard let context = UIGraphicsGetCurrentContext() else { return }

		let scaleFactor = min(bounds.maxX, bounds.maxY) / CGFloat(max(qrData.width, qrData.height))

		for x in 0..<qrData.width {
			for y in 0..<qrData.height {
				let point = CGPoint(x: x, y: y)
				let value = qrData.value(at: point)
				let xScaled = CGFloat(x) * scaleFactor
				let yScaled = CGFloat(y) * scaleFactor
				if value == 1 {
					if #available(iOS 13.0, *) {
						context.setFillColor(UIColor.label.cgColor)
					} else {
						context.setFillColor(UIColor.white.cgColor)
					}
					context.fillEllipse(in: CGRect(x: xScaled, y: yScaled, width: scaleFactor, height: scaleFactor))
				}
			}
		}
	}

	private func generateQRData() -> QRData? {
		let filter = CIFilter(name: "CIQRCodeGenerator")
		filter?.setValue(data, forKey: "inputMessage")
		filter?.setValue(correctionLevel.rawValue, forKey: "inputCorrectionLevel")

		guard let image = filter?.outputImage?.convertedToCGImage else { return nil }

		UIGraphicsBeginImageContext(image.size)
		guard let context = UIGraphicsGetCurrentContext() else { return nil }
		context.draw(image, in: image.bounds)

		if let tImg = context.makeImage() {
			self.image = UIImage(cgImage: tImg, scale: 2, orientation: .downMirrored)
		}

		let width = Int(image.size.width)
		let height = Int(image.size.height)

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

		let qrData = QRData(width: width, height: height, data: qrBinaryData, flipped: true)
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

	let flipped: Bool

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

extension CIImage {
	var convertedToCGImage: CGImage? {
		let context = CIContext(options: nil)
		return context.createCGImage(self, from: extent)
	}
}

extension CGImage {
	var size: CGSize {
		CGSize(width: width, height: height)
	}

	var bounds: CGRect {
		CGRect(origin: .zero, size: size)
	}
}

extension FixedWidthInteger {
	var nearestMultipleOf8: Self {
		var value = self
		while !value.isMultiple(of: 8) {
			value += 1
		}
		return value
	}
}
