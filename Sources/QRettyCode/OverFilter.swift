//
//  OverFilter.swift
//  CIFilterTesting
//
//  Created by Michael Redig on 4/6/20.
//  Copyright © 2020 Michael Redig. All rights reserved.
//

import CoreImage

class OverFilter: CIFilter {
	@objc var inputImage: CIImage?
	@objc var backgroundImage: CIImage?

	@objc var opacity: CGFloat = 1

	private let kernel = CIColorKernel(source: .overKernel)!


	override init() {
		super.init()
		setDefaults()
	}

	override func setDefaults() {
		super.setDefaults()
		opacity = 1
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init coder not implemented")
	}

	override var outputImage: CIImage? {
		let union = inputImage?.extent.union(backgroundImage?.extent ?? .zero) ?? backgroundImage?.extent ?? .zero
		let bgImage = backgroundImage ?? CIImage()
		let foreground = inputImage ?? CIImage()
		let args: [Any] = [foreground, bgImage, opacity]
		return kernel.apply(extent: union, arguments: args)
	}
}

// MARK: - Kernel
fileprivate extension String {
	static let overKernel = """
kernel vec4 opacity_over(__sample image_pixel_foreground, __sample image_pixel_background, float opacity) {
	vec4 foreground = unpremultiply(image_pixel_foreground);
	vec4 background = unpremultiply(image_pixel_background);
	vec4 outPixel = (foreground * opacity) + (background * (1.0 - opacity));

	return premultiply(outPixel);
}
"""
}

class CompositeFilter: CIFilter {
	@objc var inputImage: CIImage? {
		get { overFilter.inputImage }
		set { overFilter.inputImage = newValue }
	}
	@objc var backgroundImage: CIImage? = CIImage()

	@objc var opacity: CGFloat {
		get { overFilter.opacity }
		set { overFilter.opacity = newValue }
	}

	private let overFilter = OverFilter()

	private var _cachedFilter: CIFilter?
	var compositeOperation: CompositeOperation = .over {
		didSet {
			guard oldValue != compositeOperation else { return }
			_cachedFilter = nil
		}
	}

	enum CompositeOperation: String {
		case over = "CISourceOverCompositing"
		case add = "CIAdditionCompositing"
		case multiply = "CIMultiplyBlendMode"
		case subtract = "CISubtractBlendMode"
		case overlay = "CIOverlayBlendMode"
		case screen = "CIScreenBlendMode"

		var filter: CIFilter? {
			CIFilter(name: self.rawValue)
		}
	}

	override var outputImage: CIImage? {
		if _cachedFilter == nil {
			_cachedFilter = compositeOperation.filter
		}
		_cachedFilter?.setValue(overFilter.outputImage, forKey: kCIInputImageKey)
		_cachedFilter?.setValue(backgroundImage, forKey: kCIInputBackgroundImageKey)
		return _cachedFilter?.outputImage
	}
}
