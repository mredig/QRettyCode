//
//  QRettyCodeImage.swift
//  QRettyCode
//
//  Created by Michael Redig on 11/13/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import UIKit
import VectorExtor

public enum QRettyStyle {
	case blocks
	case dots
	case curvedCorners
}

public enum QRGradientStyle {
	case linear
	case radial
}

public class QRettyCodeImageGenerator {
	public var correctionLevel: QRCorrectionLevel {
		didSet {
			guard oldValue != correctionLevel else { return }
			updateQRData()
		}
	}
	public var data: Data? {
		didSet {
			guard oldValue != data else { return }
			updateQRData()
		}
	}
	/// In points
	public var size: CGFloat 
	public var style: QRettyStyle {
		didSet {
			guard oldValue != style else { return }
			updateQRData()
		}
	}
	public var renderEffects = false

	// gradient
	public var gradientStartColor = UIColor(red: CGFloat(0x8e) / 255, green: CGFloat(0x2d) / 255, blue: CGFloat(0xe2) / 255, alpha: 1)
	public var gradientEndColor = UIColor(red: CGFloat(0x4a) / 255, green: CGFloat(0x00) / 255, blue: CGFloat(0xe0) / 255, alpha: 1)
	public var gradientStartPoint = CGPoint.zero
	public var gradientEndPoint = CGPoint(x: 1, y: 1)
	public var gradientStyle = QRGradientStyle.linear

	public var gradientBackgroundVisible = false
	public var gradientBackgroundStrength: CGFloat = 0.25
	private var _gradientBackgroundStrength: CIColor {
		CIColor(red: gradientBackgroundStrength, green: gradientBackgroundStrength, blue: gradientBackgroundStrength)
	}

	// inner shadow
	/// use caution with this - can break qr code readability
	public var shadowOffset = CGPoint(x: 0.0967741935483871, y: -0.0967741935483871)
	/// use caution with this - can break qr code readability
	public var shadowSoftness: CGFloat = 0.75

	// icon overlay
	public var iconImage: UIImage?
	public var iconImageScale: CGFloat = 1

	// interal stuff
	private(set) var qrData: QRettyCodeData?
	private lazy var context: CIContext = {
		return CIContext()
	}()
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

	private var rawQRImage: UIImage?

	//output
	public var image: UIImage? {
		generateOutputImage()
	}

	private var renderer: UIGraphicsImageRenderer?

	public init(data: Data?, correctionLevel: QRCorrectionLevel = .Q, size: CGFloat = 100, style: QRettyStyle = .dots) {
		self.data = data
		self.correctionLevel = correctionLevel
		self.size = size
		self.style = style
		updateQRData()
	}

	private func updateQRData() {
		qrData = QRettyCodeData(data: data, correctionLevel: correctionLevel, flipped: false)
		rawQRImage = nil
	}

	private func generateRawQRImage() -> UIImage? {
		guard let qrData = qrData,
			let width = qrData.width,
			let height = qrData.height,
			let scaleFactor = scaleFactor
			else { return nil }

		let localRenderer: UIGraphicsImageRenderer
		if let renderer = renderer, renderer.format.bounds.size == CGSize(width: scaledSize, height: scaledSize) {
			localRenderer = renderer
		} else {
			let format = UIGraphicsImageRendererFormat()
			if #available(iOS 12.0, *) {
				format.preferredRange = .standard
			} else {
				format.prefersExtendedRange = false
			}
			let newRenderer = UIGraphicsImageRenderer(size: CGSize(width: scaledSize, height: scaledSize))
			localRenderer = newRenderer
			renderer = newRenderer
		}

		let image = localRenderer.image { gContext in
			let context = gContext.cgContext
			context.setFillColor(UIColor.white.cgColor)

			let bezier = UIBezierPath()
			let scaledSize = scaleFactor + 0.75
			let halfScale = scaledSize / 2

			for x in 0..<width {
				for y in 0..<height {
					let point = CGPoint(x: x, y: y)
					let value = qrData.value(at: point)
					let xScaled = CGFloat(x) * scaleFactor
					let yScaled = CGFloat(y) * scaleFactor
					let scaledPoint = CGPoint(x: xScaled, y: yScaled)
					if value {
						switch style {
						case .curvedCorners:
							// FIXME: can be done more efficiently by going corner by corner
							let neighbors = qrData.neighbors(at: point)

							if neighbors.contains(.yPos) {
								bezier.addRect(CGRect(origin: CGPoint(x: xScaled, y: yScaled + halfScale), size: CGSize(width: scaledSize, height: halfScale)))
								bezier.close()
							}
							if neighbors.contains(.yNeg) {
								bezier.addRect(CGRect(origin: CGPoint(x: xScaled, y: yScaled), size: CGSize(width: scaledSize, height: halfScale)))
								bezier.close()
							}
							if neighbors.contains(.xPos) {
								bezier.addRect(CGRect(origin: CGPoint(x: xScaled + halfScale, y: yScaled), size: CGSize(width: halfScale, height: scaledSize)))
								bezier.close()
							}
							if neighbors.contains(.xNeg) {
								bezier.addRect(CGRect(origin: CGPoint(x: xScaled, y: yScaled), size: CGSize(width: halfScale, height: scaledSize)))
								bezier.close()
							}
							let center = CGPoint(x: xScaled, y: yScaled) + CGPoint(scalar: halfScale)
							bezier.move(to: center)
							bezier.addCircle(center: center, radius: halfScale)
						case .dots:
							let center = scaledPoint + CGPoint(scalar: halfScale)
							bezier.move(to: center)
							bezier.addCircle(center: center, radius: halfScale)
						case .blocks:
							bezier.addRect(CGRect(origin: scaledPoint, size: CGSize(scalar: scaledSize)))
						}
						bezier.close()
						bezier.fill()
						bezier.removeAllPoints()
					}
				}
			}
		}
		return image
	}

	private func generateOutputImage() -> UIImage? {
		if renderEffects {
			guard let rawImage = rawQRImage ?? generateRawQRImage(), let cgImage = rawImage.cgImage else { return nil }
			rawQRImage = rawImage
			return addEffectsToImage(cgImage)
		} else {
			guard let rawImage = rawQRImage ?? generateRawQRImage() else { return nil }
			rawQRImage = rawImage
			return rawQRImage
		}
	}

	private func addEffectsToImage(_ image: CGImage) -> UIImage? {
		guard let scaleFactor = scaleFactor else { return nil }
		let qrDots = CIImage(cgImage: image)

		// FIXME: might want to rename or redistribute the original
		let squaredSize = image.size

		let solidBlack = CIFilter(name: "CIConstantColorGenerator")
		let overComposite = CIFilter(name: "CISourceOverCompositing")
		let multiplyComposite = CIFilter(name: "CIMultiplyCompositing")
		let inverter = CIFilter(name: "CIColorInvert")
		let affineTransform = CIFilter(name: "CIAffineTransform")
		let gaussianBlur = CIFilter(name: "CIGaussianBlur")
		let linearGradient = CIFilter(name: "CISmoothLinearGradient")
		let radialGradient = CIFilter(name: "CIGaussianGradient")

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
		let shadedDots = multiplyComposite?.outputImage

		overComposite?.setValue(shadedDots, forKey: kCIInputImageKey)
		solidBlack?.setValue(_gradientBackgroundStrength, forKey: kCIInputColorKey)
		overComposite?.setValue(solidBlack?.outputImage, forKey: kCIInputBackgroundImageKey)
		let gradientBackground = overComposite?.outputImage

		linearGradient?.setValue(CIVector(cgPoint: squaredSize.normalPointToAbsolute(normalPoint: gradientStartPoint)), forKey: "inputPoint0")
		linearGradient?.setValue(CIVector(cgPoint: squaredSize.normalPointToAbsolute(normalPoint: gradientEndPoint)), forKey: "inputPoint1")
		linearGradient?.setValue(CIColor(color: gradientStartColor), forKey: "inputColor0")
		linearGradient?.setValue(CIColor(color: gradientEndColor), forKey: "inputColor1")

		radialGradient?.setValue(CIVector(cgPoint: squaredSize.normalPointToAbsolute(normalPoint: gradientStartPoint)), forKey: kCIInputCenterKey)
		let distance = squaredSize.normalPointToAbsolute(normalPoint: gradientStartPoint)
			.distance(to: squaredSize.normalPointToAbsolute(normalPoint: gradientEndPoint))
		radialGradient?.setValue(distance, forKey: kCIInputRadiusKey)
		radialGradient?.setValue(CIColor(color: gradientStartColor), forKey: "inputColor0")
		radialGradient?.setValue(CIColor(color: gradientEndColor), forKey: "inputColor1")

		switch gradientStyle {
		case .linear:
			multiplyComposite?.setValue(linearGradient?.outputImage, forKey: kCIInputImageKey)
		case .radial:
			multiplyComposite?.setValue(radialGradient?.outputImage, forKey: kCIInputImageKey)
		}
		if gradientBackgroundVisible {
			multiplyComposite?.setValue(gradientBackground, forKey: kCIInputBackgroundImageKey)
		} else {
			multiplyComposite?.setValue(shadedDots, forKey: kCIInputBackgroundImageKey)
		}
		let gradientOutput = multiplyComposite?.outputImage

		let finalComp: CIImage?
		if let iconImage = iconImage {
			let ciIconImage: CIImage
			if let unwrapped = iconImage.ciImage {
				ciIconImage = unwrapped
			} else {
				guard let unwrappedCG = iconImage.cgImage else { fatalError("Could NOT create a CIImage from icon image") }
				let unwrapped = CIImage(cgImage: unwrappedCG)
				ciIconImage = unwrapped
			}
			guard let gradientOutput = gradientOutput else { return nil }

			let scaledImage = ciIconImage.fitInside(maximumIconSize() * iconImageScale)
			let centerOriginOffsetX = image.size.width / 2 - (scaledImage.extent.size.width / 2)
			let centerOriginOffsetY = image.size.height / 2 - (scaledImage.extent.size.height / 2)
			let transform = CGAffineTransform(translationX: centerOriginOffsetX, y: centerOriginOffsetY)
			affineTransform?.setValue(scaledImage, forKey: kCIInputImageKey)
			affineTransform?.setValue(transform, forKey: kCIInputTransformKey)

			overComposite?.setValue(affineTransform?.outputImage, forKey: kCIInputImageKey)
			overComposite?.setValue(gradientOutput, forKey: kCIInputBackgroundImageKey)

			finalComp = overComposite?.outputImage
		} else {
			finalComp = gradientOutput
		}

		guard let ciImageResult = finalComp,
			let cgImageResult = context.createCGImage(ciImageResult, from: CGRect(origin: .zero, size: image.size))
			else { return nil }
		return UIImage(cgImage: cgImageResult)
	}

	private func maximumIconSize() -> CGSize {
		let maximumCoverage = (scaledSize * scaledSize) * correctionLevel.value
		let maxCoverageDimensions = sqrt(maximumCoverage)
		return CGSize(width: maxCoverageDimensions, height: maxCoverageDimensions)
	}
}
