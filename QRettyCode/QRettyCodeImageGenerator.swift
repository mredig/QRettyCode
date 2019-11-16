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
	public var shadowOffset = CGPoint(x: 0.0967741935483871, y: -0.0967741935483871)
	public var shadowSoftness: CGFloat = 0.75

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

		let solidBlack = CIFilter(name: "CIConstantColorGenerator")
		let overComposite = CIFilter(name: "CISourceOverCompositing")
		let multiplyComposite = CIFilter(name: "CIMultiplyCompositing")
		let inverter = CIFilter(name: "CIColorInvert")
		let affineTransform = CIFilter(name: "CIAffineTransform")
		let gaussianBlur = CIFilter(name: "CIGaussianBlur")

		// render over black
		overComposite?.setValue(qrDots, forKey: kCIInputImageKey)
		solidBlack?.setValue(CIColor(red: 0, green: 0, blue: 0), forKey: kCIInputColorKey)
		overComposite?.setValue(solidBlack?.outputImage, forKey: kCIInputBackgroundImageKey)
		let dotsOnBlack = overComposite?.outputImage

		// create a black on white variant
		inverter?.setValue(dotsOnBlack, forKey: kCIInputImageKey)
		let dotsOnWhite = inverter?.outputImage

		// slightly offset inverted for an inner shadow
		let transform = CGAffineTransform(translationX: shadowOffset.x * scaleFactor, y: shadowOffset.y * scaleFactor)
		affineTransform?.setValue(dotsOnWhite, forKey: kCIInputImageKey)
		affineTransform?.setValue(transform, forKey: kCIInputTransformKey)
		let invertedOffset = affineTransform?.outputImage

		// multiply the offset inversion on top of original (on black)
		// this creates a white half moon effect
		multiplyComposite?.setValue(invertedOffset, forKey: kCIInputImageKey)
		multiplyComposite?.setValue(dotsOnBlack, forKey: kCIInputBackgroundImageKey)
		let whiteHalfMoon = multiplyComposite?.outputImage

		// invert the white half moon effect to become a black half moon effect on white
		inverter?.setValue(whiteHalfMoon, forKey: kCIInputImageKey)
		let blackHalfMoon = inverter?.outputImage

		// blur the black half moon
		gaussianBlur?.setValue(blackHalfMoon, forKey: kCIInputImageKey)
		let blurValue = 0.13548387096774195 * scaleFactor * shadowSoftness
		gaussianBlur?.setValue(blurValue, forKey: kCIInputRadiusKey)
		let blurredBlackHalfMoon = gaussianBlur?.outputImage

		// multiply on top of original (on black)
		multiplyComposite?.setValue(blurredBlackHalfMoon, forKey: kCIInputImageKey)
//		multiplyComposite?.setValue(dotsOnBlack, forKey: kCIInputBackgroundImageKey)
		multiplyComposite?.setValue(qrDots, forKey: kCIInputBackgroundImageKey)
		let finalComp = multiplyComposite?.outputImage

		guard let ciImageResult = finalComp,
			let cgImageResult = context.createCGImage(ciImageResult, from: CGRect(origin: .zero, size: image.size))
			else { return nil }
		return UIImage(cgImage: cgImageResult)
	}
}
