//
//  HandyExtensions.swift
//  QRettyCode
//
//  Created by Michael Redig on 11/15/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import CoreImage
import UIKit
import VectorExtor

internal extension CIImage {
	var convertedToCGImage: CGImage? {
		let context = CIContext(options: nil)
		return context.createCGImage(self, from: extent)
	}

	func fitInside(_ size: CGSize) -> CIImage {
		let downScale = CIFilter(name: "CILanczosScaleTransform")
		downScale?.setValue(self, forKey: kCIInputImageKey)
		var scaleValue: CGFloat = 1
		if size.width < extent.size.width {
			scaleValue = size.width / extent.size.width
		}
		if size.height < extent.size.height {
			scaleValue = min(scaleValue, size.height / extent.size.height)
		}
		downScale?.setValue(scaleValue, forKey: kCIInputScaleKey)
		return downScale?.outputImage ?? self
	}
}

public extension CIFilter {
	/// May not contain an underlying property on all CIFilters
	@objc var inputImageConvenience: CIImage? {
		get { value(forKey: kCIInputImageKey) as? CIImage }
		set { setValue(newValue, forKey: kCIInputImageKey) }
	}
}

internal extension CGImage {
	var size: CGSize {
		CGSize(width: width, height: height)
	}

	var bounds: CGRect {
		CGRect(origin: .zero, size: size)
	}
}

public extension CGPath {
	enum PathElement {
		case moveTo(point: CGPoint)
		case addLineTo(point: CGPoint)
		case addQuadCurveTo(point: CGPoint, controlPoint: CGPoint)
		case addCurveTo(point: CGPoint, controlPoint1: CGPoint, controlPoint2: CGPoint)
		case close
	}

	var elements: [PathElement] {
		var store = [PathElement]()
		applyWithBlock { elementsPointer in
			let element = elementsPointer[0]
			switch element.type {
			case .moveToPoint:
				let point = element.points[0]
				store.append(.moveTo(point: point))
			case .addLineToPoint:
				let point = element.points[0]
				store.append(.addLineTo(point: point))
			case .addQuadCurveToPoint:
				let point = element.points[1]
				let control = element.points[0]
				store.append(.addQuadCurveTo(point: point, controlPoint: control))
			case .addCurveToPoint:
				let point = element.points[2]
				let control1 = element.points[0]
				let control2 = element.points[1]
				store.append(.addCurveTo(point: point, controlPoint1: control1, controlPoint2: control2))
			case .closeSubpath:
				store.append(.close)
			@unknown default:
				print("Unknown path element type: \(element.type) \(element.type.rawValue)")
			}
		}
		return store
	}

	var svgString: String {
		toSVGString()
	}

	private func toSVGString() -> String {
		let components = elements

		return components.reduce("") {
			switch $1 {
			case .moveTo(point: let point):
				return $0 + "M\(point.x),\(point.y) "
			case .addLineTo(point: let point):
				return $0 + "L\(point.x),\(point.y) "
			case .addQuadCurveTo(point: let point, controlPoint: let control):
				return $0 + "Q\(control.x),\(control.y) \(point.x),\(point.y) "
			case .addCurveTo(point: let point, controlPoint1: let control1, controlPoint2: let control2):
				return $0 + "C\(control1.x),\(control1.y) \(control2.x),\(control2.y) \(point.x),\(point.y) "
			case .close:
				return $0 + "z "
			}
		}
	}
}
