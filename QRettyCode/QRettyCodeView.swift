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

	public override func draw(_ rect: CGRect) {
		guard let qrData = generateQRData() else { return }
		guard let context = UIGraphicsGetCurrentContext() else { return }

		context.setFillColor(UIColor.red.cgColor)
		for (index, value) in qrData.data.renderedData.enumerated() {
			let x = index % (qrData.width + 1)
			let y = qrData.width - index / (qrData.width + 1)

			if value == 1 {
				context.fill(CGRect(x: x, y: y, width: 1, height: 1))
			}
		}

	}

	private func generateQRData() -> QRData? {
		let filter = CIFilter(name: "CIQRCodeGenerator")!
		filter.setValue(data, forKey: "inputMessage")
		filter.setValue(correctionLevel.rawValue, forKey: "inputCorrectionLevel")
		guard let image = filter.outputImage?.convertedToCGImage else { return nil }

		UIGraphicsBeginImageContext(image.size)
		guard let context = UIGraphicsGetCurrentContext() else { return nil }
		context.setFillColor(UIColor.white.cgColor)
		context.fill(image.bounds)
		context.draw(image, in: image.bounds)

		let width = Int(image.size.width)
		let height = Int(image.size.height)

		guard let data1 = context.data?.assumingMemoryBound(to: UInt8.self) else { print("No data"); return nil }
		let data2 = UnsafeBufferPointer(start: data1, count: width * height * 4)
		let rData = Data(buffer: data2)
		UIGraphicsEndImageContext()

		var qrBinaryData = BinaryFormatter()
		for pixel in stride(from: 1, through: rData.count, by: 4) {
			qrBinaryData.append(element: rData[pixel] == 0 ? BinaryFormatter.Byte(1) : BinaryFormatter.Byte(0))
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
