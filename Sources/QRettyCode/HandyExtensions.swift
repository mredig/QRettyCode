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

public extension CIFilter {
	/// May not contain an underlying property on all CIFilters
	@objc var inputImageConvenience: CIImage? {
		get { value(forKey: kCIInputImageKey) as? CIImage }
		set { setValue(newValue, forKey: kCIInputImageKey) }
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
