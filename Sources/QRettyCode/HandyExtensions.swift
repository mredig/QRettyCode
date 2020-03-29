//
//  HandyExtensions.swift
//  QRettyCode
//
//  Created by Michael Redig on 11/15/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import CoreImage

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

internal extension FixedWidthInteger {
	var nearestMultipleOf8: Self {
		var value = self
		#if targetEnvironment(macCatalyst)
		while !value.isMultiple(of: 16) {
			value += 1
		}
		#else
		while !value.isMultiple(of: 8) {
			value += 1
		}
		#endif
		return value
	}
}
