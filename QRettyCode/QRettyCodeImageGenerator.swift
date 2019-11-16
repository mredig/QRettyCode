//
//  QRettyCodeImage.swift
//  QRettyCode
//
//  Created by Michael Redig on 11/13/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import UIKit

public enum QRettyStyle {
	case blocks
	case dots
}

public class QRettyCodeImageGenerator {
	public var correctionLevel: QRCorrectionLevel {
		didSet {
			updateQRData()
		}
	}
	public var data: Data? {
		didSet {
			updateQRData()
		}
	}
	/// In points
	public var size: CGFloat 
	public var style: QRettyStyle{
		didSet {
			updateQRData()
		}
	}
	// gradient
	// inner shadow

	private(set) var qrData: QRettyCodeData?
	private lazy var context: CIContext = {
		return CIContext()
	}()

	public var image: UIImage? {
		generateImage()
	}

	public init(data: Data?, correctionLevel: QRCorrectionLevel = .Q, size: CGFloat = 100, style: QRettyStyle = .dots) {
		self.data = data
		self.correctionLevel = correctionLevel
		self.size = size
		self.style = style
		updateQRData()
	}

	private func updateQRData() {
		qrData = QRettyCodeData(data: data, correctionLevel: correctionLevel, flipped: true)
	}

	private func generateImage() -> UIImage? {
		guard let qrData = qrData,
			let width = qrData.width,
			let height = qrData.height
			else { return nil }
		let scaledSize = UIScreen.main.scale * size
		UIGraphicsBeginImageContext(CGSize(width: scaledSize, height: scaledSize))
		guard let context = UIGraphicsGetCurrentContext() else { return nil }

		let scaleFactor = scaledSize / CGFloat(max(width, height))

		for x in 0..<width {
			for y in 0..<height {
				let point = CGPoint(x: x, y: y)
				let value = qrData.value(at: point)
				let xScaled = CGFloat(x) * scaleFactor
				let yScaled = CGFloat(y) * scaleFactor
				if value {
					context.setFillColor(UIColor.white.cgColor)
					switch style {
					case .dots:
						context.fillEllipse(in: CGRect(x: xScaled, y: yScaled, width: scaleFactor, height: scaleFactor))
					case .blocks:
						context.fill(CGRect(x: xScaled, y: yScaled, width: scaleFactor + 0.75, height: scaleFactor + 0.75))
					}
				}
			}
		}

		guard let cgImage = context.makeImage() else { return nil }
		UIGraphicsEndImageContext()
//		return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
		return addEffectsToImage(cgImage)
	}

	private func addEffectsToImage(_ image: CGImage) -> UIImage? {
		let qrDots = CIImage(cgImage: image)
		let scaledSize = UIScreen.main.scale * size

		let overBlackBackground = CIFilter(name: "CISourceOverCompositing")
		overBlackBackground?.setValue(qrDots, forKey: kCIInputImageKey)
		let solidBlack = CIFilter(name: "CIConstantColorGenerator")
		solidBlack?.setValue(CIColor(red: 0, green: 0, blue: 0), forKey: kCIInputColorKey)
		overBlackBackground?.setValue(solidBlack?.outputImage, forKey: kCIInputBackgroundImageKey)

		let blurFilter = CIFilter(name: "CIGaussianBlur")
		blurFilter?.setValue(overBlackBackground?.outputImage, forKey: kCIInputImageKey)
		blurFilter?.setValue(0.0130859375 * scaledSize * 0.5, forKey: kCIInputRadiusKey)

		let innerShadowOffset = CIFilter(name: "CIAffineTransform")
		let transform = CGAffineTransform(translationX: 0.0111328125 * scaledSize * 0.5, y: -0.0111328125 * scaledSize * 0.5)
		innerShadowOffset?.setValue(blurFilter?.outputImage, forKey: kCIInputImageKey)
		innerShadowOffset?.setValue(transform, forKey: kCIInputTransformKey)

		let innerShadowComp = CIFilter(name: "CIMultiplyCompositing")
		innerShadowComp?.setValue(innerShadowOffset?.outputImage, forKey: kCIInputImageKey)
		innerShadowComp?.setValue(qrDots, forKey: kCIInputBackgroundImageKey)

		overBlackBackground?.setValue(innerShadowComp?.outputImage, forKey: kCIInputImageKey)

		guard let ciImageResult = overBlackBackground?.outputImage, let cgImageResult = context.createCGImage(ciImageResult, from: CGRect(origin: .zero, size: image.size)) else { return nil }
		return UIImage(cgImage: cgImageResult)
	}
}
