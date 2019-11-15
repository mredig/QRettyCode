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

		let contextWidth = qrData.width.nearestMultipleOf8
//		if #available(iOS 13.0, *) {
//			context.setFillColor(UIColor.label.cgColor)
//		} else {
//			context.setFillColor(UIColor.white.cgColor)
//		}

		for (index, value) in qrData.data.renderedData.enumerated() {
			let scaleFactor = 10
			let x = index % (contextWidth)
			guard x < qrData.width else { continue }
			let xScaled = x * scaleFactor
			let y = index / (contextWidth)
//			guard y < qrData.height else { continue }
			let yScaled = y * scaleFactor

			if value == 1 {
				if #available(iOS 13.0, *) {
					context.setFillColor(UIColor.label.cgColor)
				} else {
					context.setFillColor(UIColor.white.cgColor)
				}
				context.fillEllipse(in: CGRect(x: xScaled, y: yScaled, width: scaleFactor, height: scaleFactor))
			} else {
				if #available(iOS 13.0, *) {
					context.setFillColor(UIColor.tertiarySystemBackground.cgColor)
				} else {
					context.setFillColor(UIColor.darkGray.cgColor)
				}
				context.fillEllipse(in: CGRect(x: xScaled, y: yScaled, width: scaleFactor, height: scaleFactor))
			}
		}

	}

	private func generateQRData() -> QRData? {
		let filter = CIFilter(name: "CIQRCodeGenerator")
		filter?.setValue(data, forKey: "inputMessage")
		filter?.setValue(correctionLevel.rawValue, forKey: "inputCorrectionLevel")

//		let theta = 17

//		let color = CIFilter(name: "CIConstantColorGenerator")
//		color?.setValue(CIColor(red: 0, green: 0, blue: 0, alpha: 1.0), forKey: kCIInputColorKey)
//		let filter = CIFilter(name: "CICrop")
//		filter?.setValue(CIVector(cgRect: CGRect(x: 0, y: 0, width: theta, height: theta)), forKey: "inputRectangle")
//		filter?.setValue(color?.outputImage, forKey: kCIInputImageKey)

		guard let image = filter?.outputImage?.convertedToCGImage else { return nil }

//		self.image = UIImage(cgImage: image, scale: 1, orientation: .up)

		UIGraphicsBeginImageContext(image.size)
		guard let context = UIGraphicsGetCurrentContext() else { return nil }
//		context.setFillColor(UIColor.white.cgColor)
//		context.fill(image.bounds)
		context.draw(image, in: image.bounds)

		// testing
//		for x in 0...theta {
//			for y in 0...theta {
//				if x.isMultiple(of: 2) && y.isMultiple(of: 2) {
//					context.fill(CGRect(x: x, y: y, width: 1, height: 1))
//				}
//			}
//		}

		if let tImg = context.makeImage() {
			self.image = UIImage(cgImage: tImg, scale: 2, orientation: .downMirrored)
		}

		let width = Int(image.size.width)
		let height = Int(image.size.height)

//		context.

		guard let data1 = context.data?.assumingMemoryBound(to: UInt8.self) else { print("No data"); return nil }
		let bytesPerPixel = image.bitsPerPixel / image.bitsPerComponent
		let data2 = UnsafeBufferPointer(start: data1, count: width * height * bytesPerPixel * 4)
		let tData = Data(buffer: data2)
		UIGraphicsEndImageContext()

		var qrBinaryData = BinaryFormatter()
		for (index, pixel) in tData.enumerated() where index.isMultiple(of: bytesPerPixel) {
			qrBinaryData.append(element: pixel == 0 ? BinaryFormatter.Byte(1) : BinaryFormatter.Byte(0))
		}

		let qrData = QRData(width: width, height: height, data: qrBinaryData)
		return qrData
	}
}

struct QRData {
	let width: Int
	let height: Int
	let data: BinaryFormatter
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
