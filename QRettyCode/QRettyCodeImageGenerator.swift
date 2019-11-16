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
	private var scaledSize: CGFloat {
		UIScreen.main.scale * size
	}
	private var scaleFactor: CGFloat? {
		guard let qrData = qrData,
				let width = qrData.width,
				let height = qrData.height
				else { return nil }
		return scaledSize / CGFloat(max(width, height))
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
			let height = qrData.height,
			let scaleFactor = scaleFactor
			else { return nil }
		UIGraphicsBeginImageContext(CGSize(width: scaledSize, height: scaledSize))
		guard let context = UIGraphicsGetCurrentContext() else { return nil }

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
		guard let scaleFactor = scaleFactor else { return nil }
		let qrDots = CIImage(cgImage: image)

		let overBlackBackground = CIFilter(name: "CISourceOverCompositing")
		overBlackBackground?.setValue(qrDots, forKey: kCIInputImageKey)
		let solidBlack = CIFilter(name: "CIConstantColorGenerator")
		solidBlack?.setValue(CIColor(red: 0, green: 0, blue: 0), forKey: kCIInputColorKey)
		overBlackBackground?.setValue(solidBlack?.outputImage, forKey: kCIInputBackgroundImageKey)

		let inverter = CIFilter(name: "CIColorInvert")
		inverter?.setValue(overBlackBackground?.outputImage, forKey: kCIInputImageKey)

		let innerShadowOffset = CIFilter(name: "CIAffineTransform")
		let offsetValue = 0.0967741935483871 * scaleFactor
		let transform = CGAffineTransform(translationX: offsetValue, y: -offsetValue)
		innerShadowOffset?.setValue(inverter?.outputImage, forKey: kCIInputImageKey)
		innerShadowOffset?.setValue(transform, forKey: kCIInputTransformKey)

		let multiplyComposite = CIFilter(name: "CIMultiplyCompositing")
		multiplyComposite?.setValue(innerShadowOffset?.outputImage, forKey: kCIInputImageKey)
		multiplyComposite?.setValue(overBlackBackground?.outputImage, forKey: kCIInputBackgroundImageKey)

		inverter?.setValue(multiplyComposite?.outputImage, forKey: kCIInputImageKey)

		let blurFilter = CIFilter(name: "CIGaussianBlur")
		blurFilter?.setValue(inverter?.outputImage, forKey: kCIInputImageKey)
		let blurValue = 0.13548387096774195 * scaleFactor * 0.75
		blurFilter?.setValue(blurValue, forKey: kCIInputRadiusKey)

		let innerShadowComp = CIFilter(name: "CIMultiplyCompositing")
		innerShadowComp?.setValue(blurFilter?.outputImage, forKey: kCIInputImageKey)
		innerShadowComp?.setValue(qrDots, forKey: kCIInputBackgroundImageKey)

		overBlackBackground?.setValue(innerShadowComp?.outputImage, forKey: kCIInputImageKey)

		guard let ciImageResult = overBlackBackground?.outputImage, let cgImageResult = context.createCGImage(ciImageResult, from: CGRect(origin: .zero, size: image.size)) else { return nil }
		return UIImage(cgImage: cgImageResult)
	}
}
