//
//  QRettyCodeData.swift
//  QRettyCode
//
//  Created by Michael Redig on 11/15/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation
import UIKit
import CoreImage
import SwiftyBinaryFormatter
import VectorExtor

public enum QRCorrectionLevel: String {
	case L
	case M
	case Q
	case H

	var value: CGFloat {
		switch self {
		case .L:
			 return 0.07
		case .M:
			return 0.15
		case .Q:
			return 0.25
		case .H:
			return 0.3
		}
	}
}

public class QRettyCodeData {
	public let data: Data?
	public let correctionLevel: QRCorrectionLevel
	public var flipped: Bool {
		didSet {
			qrData?.flipped = flipped
		}
	}

	public var width: Int?
	public var height: Int?

	private var qrData: ImageChannelSampler?

	public var mask: UIImage? {
		didSet {
			resetMaskData()
		}
	}
	private var _maskData: ImageChannelSampler?
	private var maskData: ImageChannelSampler? {
		let data = _maskData ?? generateMaskData()
		_maskData = data
		return _maskData
	}
	private let maskFormat: UIGraphicsImageRendererFormat = {
		let format = UIGraphicsImageRendererFormat()
		format.preferredRange = .standard
		format.opaque = false
		format.scale = 1
		return format
	}()
	private lazy var maskRenderer: UIGraphicsImageRenderer = {
		let renderer = UIGraphicsImageRenderer(size: .zero, format: maskFormat)
		return renderer
	}()

	init(data: Data?, correctionLevel: QRCorrectionLevel = .H, flipped: Bool = false) {
		self.data = data
		self.correctionLevel = correctionLevel
		self.flipped = flipped

		self.qrData = generateQRData()
	}

	public enum NeighborDirection {
		case yPos, yNeg, xPos, xNeg
	}

	public func value(at location: CGPoint) -> Bool {
		qrData?.value(at: location) == 255 && (maskData?.value(at: location) ?? 0) <= 10
	}

	public func neighbors(at location: CGPoint) -> Set<NeighborDirection> {
		var neighbors = Set<NeighborDirection>()
		if location.x > 0 && value(at: location + CGPoint(x: -1, y: 0)) {
			neighbors.insert(.xNeg)
		}
		if location.y > 0 && value(at: location + CGPoint(x: 0, y: -1)) {
			neighbors.insert(.yNeg)
		}
		if location.y < CGFloat(height ?? 2) && value(at: location + CGPoint(x: 0, y: 1)) {
			neighbors.insert(.yPos)
		}
		if location.x < CGFloat(width ?? 2) && value(at: location + CGPoint(x: 1, y: 0)) {
			neighbors.insert(.xPos)
		}

		return neighbors
	}

	private func resetMaskData() {
		_maskData = nil
	}

	private func generateMaskData() -> ImageChannelSampler? {
		guard let maskImage = mask?.cgImage else { return nil }
		guard let sourceWidth = width, let sourceHeight = height else { return nil }

		let targetSize = CGSize(width: sourceWidth, height: sourceHeight)

		if maskRenderer.format.bounds.size != targetSize {
			maskRenderer = UIGraphicsImageRenderer(size: targetSize, format: maskFormat)
		}

		let resizedMask = maskRenderer.image { ctx in
			UIColor.clear.setFill()
			ctx.fill(CGRect(size: targetSize))
			ctx.cgContext.interpolationQuality = .none
			ctx.cgContext.draw(maskImage, in: CGRect(size: targetSize))
		}

		guard let cgMask = resizedMask.cgImage, let maskData = cgMask.dataProvider?.data as Data? else { return nil }
		let alphaOffset: Int
		switch cgMask.alphaInfo {
		case .first, .premultipliedFirst:
			alphaOffset = cgMask.byteOrderInfo == .order32Big ? 0 : 3
		case .last, .premultipliedLast:
			alphaOffset = cgMask.byteOrderInfo == .order32Big ? 3 : 0
		default:
			return nil
		}

		var rawAlpha = Data(capacity: Int(targetSize.width * targetSize.height))
		for row in 0..<cgMask.height {
			let rowOffset = row * cgMask.bytesPerRow
			for pixelOffset in 0..<cgMask.width {
				let byteOffset = rowOffset + (pixelOffset * 4) + alphaOffset
				let alpha = maskData[byteOffset]
				rawAlpha.append(alpha)
			}
		}

		return ImageChannelSampler(width: cgMask.width, height: cgMask.height, data: rawAlpha, flipped: true)
	}

	private func generateQRData() -> ImageChannelSampler? {
		let filter = CIFilter(name: "CIQRCodeGenerator")
		filter?.setValue(data, forKey: "inputMessage")
		filter?.setValue(correctionLevel.rawValue, forKey: "inputCorrectionLevel")

		guard let image = filter?.outputImage?.convertedToCGImage else { return nil }

		let width = Int(image.size.width)
		self.width = width
		let height = Int(image.size.height)
		self.height = height

		let bytesPerPixel = image.bitsPerPixel / image.bitsPerComponent

		guard let rawData = image.dataProvider?.data as Data? else { return nil }

		var qrBinaryData = Data()
		for row in 0..<height {
			let offsetStart = image.bytesPerRow * row
			for xOffset in 0..<width {
				let totalOffset = offsetStart + (xOffset + bytesPerPixel)
				guard totalOffset < rawData.count else { break }
				let pixel = rawData[offsetStart + (xOffset * bytesPerPixel)]
				qrBinaryData.append(pixel == 0 ? Byte(255) : Byte(0))
			}
		}

		let qrData = ImageChannelSampler(width: width, height: height, data: qrBinaryData, flipped: flipped)
		return qrData
	}
}

private struct ImageChannelSampler {
	let width: Int
	let height: Int
	private let data: Data

	var flipped: Bool

	private var maxHeight: Int { height - 1 }

	init(width: Int, height: Int, data: Data, flipped: Bool) {
		self.width = width
		self.height = height
		self.data = data
		self.flipped = flipped
	}

	func value(at location: CGPoint) -> UInt8 {
		let x = Int(location.x)
		let y = Int(location.y)

		let offset = flipped ?
			(maxHeight - y) * width + x :
			y * width + x

		return data[offset]
	}
}
