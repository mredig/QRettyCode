//
//  HandyExtensions.swift
//  QRettyCode
//
//  Created by Michael Redig on 11/15/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import CoreImage

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

extension CGFloat {
	var squaredSize: CGSize {
		CGSize(width: self, height: self)
	}
}

extension CGPoint {
	func convertFromNormalized(to size: CGSize) -> CGPoint {
		CGPoint(x: size.width * x, y: size.height * y)
	}

	func convertToNormalized(in size: CGSize) -> CGPoint {
		CGPoint(x: x / size.width, y: y / size.height)
	}

	func distanceTo(pointB: CGPoint) -> CGFloat {
//		return sqrt((pointB.x - pointA.x) * (pointB.x - pointA.x) + (pointB.y - pointA.y) * (pointB.y - pointA.y)); //fastest - see the old SKUtilities to see less efficient versions
		sqrt((pointB.x - x) * (pointB.x - x) + (pointB.y - y) * (pointB.y - y))
	}
}
