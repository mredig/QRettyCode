//
//  File.swift
//  
//
//  Created by Michael Redig on 4/5/20.
//

import CoreImage
import UIKit

public enum QRettyChecker {
	static private let context = CIContext()

	public enum Readability {
		case none
		case low
		case high
	}

	public static func verify(qrImage: UIImage, withVerificationString verificationString: String, deteriorate: Bool) -> Readability {
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

		let lowFeatures = lowDetector?.features(in: ciImage) ?? []
		let hiFeatures = hiDetector?.features(in: ciImage) ?? []

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

}
