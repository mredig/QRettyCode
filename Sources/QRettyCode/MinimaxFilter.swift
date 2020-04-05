//
//  File.swift
//
//
//  Created by Michael Redig on 4/4/20.
//

import CoreImage

// I looked into using metal for this, but I'm not seeing a way to use metal with SPM right now. I don't think that's accurate, but I'll look further another time.
class MinimaxFilter: CIFilter {
	@objc var inputImage: CIImage?
	@objc var radius: CGFloat = 20

	override var outputImage: CIImage? {
		let minimaxKernel = CIKernel(source: .minimaxKernel)
		guard let inputImage = inputImage else { return nil }
		return minimaxKernel?.apply(extent: inputImage.extent, roiCallback: { _, rect -> CGRect in
			rect
		}, arguments: [inputImage, radius])
	}
}


// MARK: - Kernel
fileprivate extension String {
	static let minimaxKernel = """
bool distanceWithin(float threshold, vec2 origin, vec2 point) {
	return distance(origin, point) <= threshold;
}

kernel vec4 minimax(sampler image, float amount) {
    vec2 dc = destCoord();
	vec4 result = sample(image, samplerTransform(image, dc));
	if (amount == 0) {
		return result;
	}

	float absAmount = abs(amount);
	bool pos = amount >= 0;

	for (float y = -absAmount; y < absAmount; y += 1) {
		for (float x = -absAmount; x < absAmount; x += 1) {
			vec2 thisPosition = vec2(x, y);
			if (distanceWithin(absAmount, dc, dc + thisPosition)) {
				vec4 thisPixel = unpremultiply(sample(image, samplerTransform(image, dc + thisPosition)));
				if (pos) {
					result = max(result, thisPixel);
				} else {
					result = min(result, thisPixel);
				}
			}
		}
	}

	return premultiply(result);
}
"""
}
