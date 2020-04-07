//
//  File.swift
//  
//
//  Created by Michael Redig on 4/5/20.
//

import CoreImage
import UIKit
import VectorExtor

public enum QRettyChecker {
	static private let context = CIContext()

	public enum Readability {
		case none
		case low
		case high
	}

	/// Stress tests the qr code image to confirm it works.
	public static func verifyQuality(qrImage: UIImage, withVerificationString verificationString: String) -> (rawImage: Readability, deterioratedImage: Readability) {
		let simple = verify(qrImage: qrImage, withVerificationString: verificationString, deteriorate: false)
		let deteriorated = verify(qrImage: qrImage, withVerificationString: verificationString, deteriorate: true)

		return (simple, deteriorated)
	}

	// further testing needed to determine if it makes sense to check on both high and low settings or to just do one
	/// Allows specifically testing if the qr code image works.
	public static func verify(qrImage: UIImage, withVerificationString verificationString: String, deteriorate shouldDeteriorate: Bool) -> Readability {
		let ciImage: CIImage
		if let unwrap = qrImage.ciImage {
			ciImage = unwrap
		} else if let unwrap = qrImage.cgImage {
			ciImage = CIImage(cgImage: unwrap)
		} else {
			return .none
		}

		let lowDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: QRettyChecker.context, options: [CIDetectorAccuracy: CIDetectorAccuracyLow])
		let hiDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: QRettyChecker.context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])

		let testImage: CIImage

		if shouldDeteriorate {
			testImage = deteriorate(ciimage: ciImage) ?? ciImage
		} else {
			testImage = ciImage
		}

		let lowFeatures = lowDetector?.features(in: testImage) ?? []
		let hiFeatures = hiDetector?.features(in: testImage) ?? []

		let detectedStrings = [lowFeatures, hiFeatures].compactMap { features in
			features.compactMap { ($0 as? CIQRCodeFeature)?.messageString }
				.filter { $0 == verificationString }
				.first
		}

		switch detectedStrings.count {
		case Int.min...0:
			return .none
		case 1:
			return .low
		case 2...Int.max:
			return .high
		default:
			return .none
		}
	}

	// could use some more deterioration - layer some gradients over the top, etc
	public static func deteriorate(ciimage: CIImage?) -> CIImage? {
		guard let ciimage = ciimage else { return nil }
		let extent = ciimage.extent
		let topLeft = extent.maxXY * CGPoint(x: 0.015, y: 0.98875)
		let topRight = extent.maxXY * CGPoint(x: 0.93125, y: 0.841825)
		let botLeft = extent.maxXY * CGPoint(x: 0.03475, y: 0.05225)
		let botRight = extent.maxXY * CGPoint(x: 0.981125, y: 0.09875)

		let cornerPin = CIFilter(name: "CIPerspectiveTransform")
		cornerPin?.inputImageConvenience = ciimage
		cornerPin?.setValue(CIVector(cgPoint: topLeft), forKey: "inputTopLeft")
		cornerPin?.setValue(CIVector(cgPoint: topRight), forKey: "inputTopRight")
		cornerPin?.setValue(CIVector(cgPoint: botLeft), forKey: "inputBottomLeft")
		cornerPin?.setValue(CIVector(cgPoint: botRight), forKey: "inputBottomRight")

		let noise = NoiseGenerator()
		let over = CompositeFilter()

		over.backgroundImage = cornerPin?.outputImage
		over.inputImage = noise.outputImage
		over.compositeOperation = .overlay
		over.opacity = 1

		return cornerPin?.outputImage
	}
}
