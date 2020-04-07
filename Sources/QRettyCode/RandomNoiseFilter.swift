//
//  RandomNoiseFilter.swift
//  CIFilterTesting
//
//  Created by Michael Redig on 4/6/20.
//  Copyright © 2020 Michael Redig. All rights reserved.
//

import CoreImage

class NoiseGenerator: CIFilter {
	var extent: CGRect?

	private let kernel = CIColorKernel(source: .straightAlpha)!
	private let randomNoise = CIFilter(name: "CIRandomGenerator")!

	override init() {
		super.init()
		setDefaults()
	}

	override func setDefaults() {
		super.setDefaults()
		extent = nil
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init coder not implemented")
	}

	override var outputImage: CIImage? {
		let args: [Any] = [randomNoise.outputImage as Any]
		return kernel.apply(extent: extent ?? .zero, arguments: args)
	}
}

// MARK: - Kernel
fileprivate extension String {
	static let straightAlpha = """
kernel vec4 opacity_over(__sample image_pixel) {
	return vec4(image_pixel.rgb, 1.0);
}
"""
}
