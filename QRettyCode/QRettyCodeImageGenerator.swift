//
//  QRettyCodeImage.swift
//  QRettyCode
//
//  Created by Michael Redig on 11/13/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import UIKit

public enum QRettyStyle {
	case blocks
	case dots
}

public class QRettyCodeImageGenerator {
	public var correctionLevel: QRCorrectionLevel {
		didSet {
			updateQRData()
		}
	}
	public var data: Data? {
		didSet {
			updateQRData()
		}
	}
	/// In points
	public var size: CGFloat 
	public var style: QRettyStyle{
		didSet {
			updateQRData()
		}
	}
	// gradient
	// inner shadow

	private(set) var qrData: QRettyCodeData?

	public var image: UIImage? {
		generateImage()
	}

	public init(data: Data?, correctionLevel: QRCorrectionLevel = .Q, size: CGFloat = 100, style: QRettyStyle = .dots) {
		self.data = data
		self.correctionLevel = correctionLevel
		self.size = size
		self.style = style
		updateQRData()
	}

	private func updateQRData() {
		qrData = QRettyCodeData(data: data, correctionLevel: correctionLevel, flipped: true)
	}

	private func generateImage() -> UIImage? {
		guard let qrData = qrData,
			let width = qrData.width,
			let height = qrData.height
			else { return nil }
		let scaledSize = UIScreen.main.scale * size
		UIGraphicsBeginImageContext(CGSize(width: scaledSize, height: scaledSize))
		guard let context = UIGraphicsGetCurrentContext() else { return nil }

		let scaleFactor = scaledSize / CGFloat(max(width, height))

		for x in 0..<width {
			for y in 0..<height {
				let point = CGPoint(x: x, y: y)
				let value = qrData.value(at: point)
				let xScaled = CGFloat(x) * scaleFactor
				let yScaled = CGFloat(y) * scaleFactor
				if value {
					context.setFillColor(UIColor.white.cgColor)
					switch style {
					case .dots:
						context.fillEllipse(in: CGRect(x: xScaled, y: yScaled, width: scaleFactor, height: scaleFactor))
					case .blocks:
						context.fill(CGRect(x: xScaled, y: yScaled, width: scaleFactor + 0.75, height: scaleFactor + 0.75))
					}
				}
			}
		}

		guard let cgImage = context.makeImage() else { return nil }
		UIGraphicsEndImageContext()
		return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
	}
}
