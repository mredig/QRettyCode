//
//  QRettyCodeImage.swift
//  QRettyCode
//
//  Created by Michael Redig on 11/13/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import UIKit
import VectorExtor

/// Used to define the shape of the QR code nodes. Can be combined. All values range from 0.0 to 1.0. Values exceeeding this range are unsupported and may result in inconsistent behavior.
public enum QRettyStyle: Hashable {
	/// `scale` determines how large each dot is, `cornerRadius` determines how curved their corners are. Range for both is `0.0` to `1.0`.
	case dot(scale: CGFloat, cornerRadius: CGFloat)
	/// `curve` determines how much the lines of the diamond bulge in or out. Range is `0.0` to `1.0`, with `0.5` representing a straight line.
	case diamond(curve: CGFloat)
	/// `width` determines how wide the gap filler will be. Range is `0.0` to `1.0`.
	case chain(width: CGFloat)
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
	public var size: CGFloat {
		didSet {
			guard oldValue != size else { return }
			updateQRData()
		}
	}
	public var style: Set<QRettyStyle> {
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

	public enum IconImageInsert: Equatable {
		case none
		case inside(image: UIImage, borderRadius: CGFloat, scale: CGFloat = 1)
		case over(image: UIImage, scale: CGFloat = 1)
	}

	// icon overlay
	public var iconImage: IconImageInsert = .none {
		didSet {
			guard oldValue != iconImage else { return }
			updateQRData()
		}
	}

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
	public var image: UIImage? {
		generateOutputImage()
	}

	private var renderer: UIGraphicsImageRenderer?

	public init(data: Data?, correctionLevel: QRCorrectionLevel = .Q, size: CGFloat = 100, style: Set<QRettyStyle> = [.dot(scale: 1, cornerRadius: 0)]) {
		self.data = data
		self.correctionLevel = correctionLevel
		self.size = size
		self.style = style
		updateQRData()
	}

	private func updateQRData() {
		if qrData == nil {
			qrData = QRettyCodeData(data: data, correctionLevel: correctionLevel, flipped: false)
		}
		qrData?.data = data
		qrData?.correctionLevel = correctionLevel

		switch iconImage {
		case .inside(image: let icon, borderRadius: let borderRadius, scale: let scale):
			// performance could be drastically increased by performing minimax after scaling down to the qr data size. (scale the border radius to match)
			let minimaxFilter = MinimaxFilter()
			minimaxFilter.inputImageConvenience = scaledOverlay(of: icon, scaledTo: scale, destinationCanvasSize: CGSize(scalar: scaledSize))
			minimaxFilter.radius = borderRadius * scaledSize * 0.1
			if let scaledOverlay = minimaxFilter.outputImage {
				qrData?.mask = UIImage(ciImage: scaledOverlay)
			}
		default:
			qrData?.mask = nil
		}
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
						let path = CGMutablePath()

						for combo in style {
							switch combo {
							case .dot(scale: let normalScale, cornerRadius: let normalCornerRadius):
								let scale = normalScale * scaledSize
								let cornerRadius = normalCornerRadius * (scale / 2)
								let baseRect = CGRect(origin: scaledPoint, size: CGSize(scalar: scaledSize))
								let origin = baseRect.midPoint.interpolation(to: scaledPoint, location: normalScale)
								let drawRect = CGRect(origin: origin, size: CGSize(scalar: scaledSize * normalScale))
								path.move(to: origin)
								if cornerRadius > 0 {
									path.addRoundedRect(in: drawRect,
														cornerWidth: cornerRadius,
														cornerHeight: cornerRadius)
								} else {
									path.addRect(drawRect)
								}
							case .chain(width: let normalWidth):
								let width = normalWidth * scaledSize
								let halfSpace = (scaledSize - width) / 2
								let neighbors = qrData.neighbors(at: point)

								if neighbors.contains(.yPos) {
									path.addRect(CGRect(origin: scaledPoint + CGPoint(x: halfSpace, y: halfScale), size: CGSize(width: width, height: halfScale)))
									path.closeSubpath()
								}
								if neighbors.contains(.yNeg) {
									path.addRect(CGRect(origin: scaledPoint + CGPoint(x: halfSpace, y: 0), size: CGSize(width: width, height: halfScale)))
									path.closeSubpath()
								}
								if neighbors.contains(.xPos) {
									path.addRect(CGRect(origin: scaledPoint + CGPoint(x: halfScale, y: halfSpace), size: CGSize(width: halfScale, height: width)))
									path.closeSubpath()
								}
								if neighbors.contains(.xNeg) {
									path.addRect(CGRect(origin: scaledPoint + CGPoint(x: 0, y: halfSpace), size: CGSize(width: halfScale, height: width)))
									path.closeSubpath()
								}
							case .diamond(curve: let normalCurve):
								let center = scaledPoint + CGPoint(scalar: halfScale)

								// points
								let noon = scaledPoint + CGPoint(x: halfScale, y: 0)
								let three = scaledPoint + CGPoint(x: scaledSize, y: halfScale)
								let six = scaledPoint + CGPoint(x: halfScale, y: scaledSize)
								let nine = scaledPoint + CGPoint(x: 0, y: halfScale)

								// corners
								let topLeft = scaledPoint
								let topRight = scaledPoint + CGPoint(x: scaledSize, y: 0)
								let bottomRight = scaledPoint + CGPoint(x: scaledSize, y: scaledSize)
								let bottomLeft = scaledPoint + CGPoint(x: 0, y: scaledSize)

								// create diamond
								path.move(to: noon)
								let control1 = center.interpolation(to: topRight, location: normalCurve)
								path.addQuadCurve(to: three, control: control1)
								let control2 = center.interpolation(to: bottomRight, location: normalCurve)
								path.addQuadCurve(to: six, control: control2)
								let control3 = center.interpolation(to: bottomLeft, location: normalCurve)
								path.addQuadCurve(to: nine, control: control3)
								let control4 = center.interpolation(to: topLeft, location: normalCurve)
								path.addQuadCurve(to: noon, control: control4)
								path.closeSubpath()
							}
						}

						context.addPath(path)
						context.fillPath() // draw into context
						context.beginPath() // deletes path from context, so subsequent draws are faster
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

		switch iconImage {
		case .none:
			finalComp = gradientOutput
		case .inside(image: let icon, borderRadius: _, scale: let scale):
			guard let gradientOutput = gradientOutput else { return nil }
			let scaledOverlayImage = scaledOverlay(of: icon, scaledTo: scale, destinationCanvasSize: image.size)
			overComposite?.setValue(scaledOverlayImage, forKey: kCIInputImageKey)
			overComposite?.setValue(gradientOutput, forKey: kCIInputBackgroundImageKey)

			finalComp = overComposite?.outputImage
		case .over(image: let icon, scale: let scale):
			guard let gradientOutput = gradientOutput else { return nil }
			let scaledOverlayImage = scaledOverlay(of: icon, scaledTo: scale, destinationCanvasSize: image.size)
			overComposite?.setValue(scaledOverlayImage, forKey: kCIInputImageKey)
			overComposite?.setValue(gradientOutput, forKey: kCIInputBackgroundImageKey)

			finalComp = overComposite?.outputImage
		}

		guard let ciImageResult = finalComp,
			let cgImageResult = context.createCGImage(ciImageResult, from: CGRect(origin: .zero, size: image.size))
			else { return nil }
		return UIImage(cgImage: cgImageResult)
	}

	private func scaledOverlay(of image: UIImage, scaledTo scale: CGFloat, destinationCanvasSize size: CGSize) -> CIImage? {
		let affineTransform = CIFilter(name: "CIAffineTransform")
		let clearCanvas = CIFilter(name: "CIConstantColorGenerator")
		let overComposite = CIFilter(name: "CISourceOverCompositing")
		let crop = CIFilter(name: "CICrop")

		clearCanvas?.setValue(CIColor(red: 0, green: 0, blue: 0, alpha: 0), forKey: kCIInputColorKey)

		let ciIconImage: CIImage
		if let unwrapped = image.ciImage {
			ciIconImage = unwrapped
		} else {
			guard let unwrappedCG = image.cgImage else { fatalError("Could NOT create a CIImage from icon image") }
			let unwrapped = CIImage(cgImage: unwrappedCG)
			ciIconImage = unwrapped
		}

		let scaledImage = ciIconImage.fitInside(maximumIconSize() * scale)
		let centerOriginOffsetX = size.width / 2 - (scaledImage.extent.size.width / 2)
		let centerOriginOffsetY = size.height / 2 - (scaledImage.extent.size.height / 2)
		let transform = CGAffineTransform(translationX: centerOriginOffsetX, y: centerOriginOffsetY)
		affineTransform?.setValue(scaledImage, forKey: kCIInputImageKey)
		affineTransform?.setValue(transform, forKey: kCIInputTransformKey)

		overComposite?.setValue(affineTransform?.outputImage, forKey: kCIInputImageKey)
		overComposite?.setValue(clearCanvas?.outputImage, forKey: kCIInputBackgroundImageKey)

		crop?.setValue(overComposite?.outputImage, forKey: kCIInputImageKey)
		crop?.setValue(CIVector(cgRect: CGRect(size: size)), forKey: "inputRectangle")

		return crop?.outputImage
	}

	private func maximumIconSize() -> CGSize {
		let maximumCoverage = (scaledSize * scaledSize) * correctionLevel.value * 0.5
		let maxCoverageDimensions = sqrt(maximumCoverage)
		return CGSize(width: maxCoverageDimensions, height: maxCoverageDimensions)
	}
}
