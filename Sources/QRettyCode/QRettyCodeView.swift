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

	public var data: Data? {
		didSet {
			updateQRData()
			setNeedsDisplay()
		}
	}
	public var correctionLevel = QRCorrectionLevel.H
	public var image: UIImage?

	var qrData: QRettyCodeData?

	private func updateQRData() {
		qrData = QRettyCodeData(data: data, correctionLevel: correctionLevel, flipped: true)
	}

	public override func draw(_ rect: CGRect) {
		guard let qrData = qrData,
			let width = qrData.width,
			let height = qrData.height
			else { return }
		guard let context = UIGraphicsGetCurrentContext() else { return }

		let scaleFactor = min(bounds.maxX, bounds.maxY) / CGFloat(max(width, height))

		for x in 0..<width {
			for y in 0..<height {
				let point = CGPoint(x: x, y: y)
				let value = qrData.value(at: point)
				let xScaled = CGFloat(x) * scaleFactor
				let yScaled = CGFloat(y) * scaleFactor
				if value {
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
}
