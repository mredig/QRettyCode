//
//  HandyExtensions.swift
//  QRettyCode
//
//  Created by Michael Redig on 11/15/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import CoreImage
import UIKit
import VectorExtor

internal extension CIImage {
	var convertedToCGImage: CGImage? {
		let context = CIContext(options: nil)
		return context.createCGImage(self, from: extent)
	}

	func fitInside(_ size: CGSize) -> CIImage {
		let downScale = CIFilter(name: "CILanczosScaleTransform")
		downScale?.setValue(self, forKey: kCIInputImageKey)
		var scaleValue: CGFloat = 1
		if size.width < extent.size.width {
			scaleValue = size.width / extent.size.width
		}
		if size.height < extent.size.height {
			scaleValue = min(scaleValue, size.height / extent.size.height)
		}
		downScale?.setValue(scaleValue, forKey: kCIInputScaleKey)
		return downScale?.outputImage ?? self
	}
}

internal extension CGImage {
	var size: CGSize {
		CGSize(width: width, height: height)
	}

	var bounds: CGRect {
		CGRect(origin: .zero, size: size)
	}
}

extension UIBezierPath {
	func addRect(_ rect: CGRect) {
		move(to: rect.origin)
		addLine(to: rect.origin + CGPoint(x: rect.size.width, y: 0))
		addLine(to: rect.origin + CGPoint(x: rect.size.width, y: rect.size.height))
		addLine(to: rect.origin + CGPoint(x: 0, y: rect.size.height))
		addLine(to: rect.origin + CGPoint(x: 0, y: 0))
	}

	func addCircle(center: CGPoint, radius: CGFloat, clockwise: Bool = true) {
		addArc(withCenter: center, radius: radius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: clockwise)
	}
}
