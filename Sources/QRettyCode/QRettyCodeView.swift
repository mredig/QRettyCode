//
//  QRettyCodeView.swift
//  QRettyCode
//
//  Created by Michael Redig on 11/13/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import UIKit
import CoreImage
import SwiftyBinaryFormatter

public class QRettyCodeView: UIView {

	public var data: Data? {
		get { qrGenerator.data }
		set {
			qrGenerator.data = newValue
			updateQRData()
		}
	}
	public var correctionLevel: QRCorrectionLevel {
		get { qrGenerator.correctionLevel }
		set {
			qrGenerator.correctionLevel = newValue
			updateQRData()
		}
	}
	public var style: Set<QRettyStyle> {
		get { qrGenerator.style }
		set {
			qrGenerator.style = newValue
			updateQRData()
		}
	}
	public var renderEffects: Bool {
		get { qrGenerator.renderEffects }
		set {
			qrGenerator.renderEffects = newValue
			updateQRData()
		}
	}

	public var gradientStartColor: UIColor {
		get { qrGenerator.gradientStartColor }
		set {
			qrGenerator.gradientStartColor = newValue
			updateQRData()
		}
	}
	public var gradientEndColor: UIColor {
		get { qrGenerator.gradientEndColor }
		set {
			qrGenerator.gradientEndColor = newValue
			updateQRData()
		}
	}
	public var gradientStartPoint: CGPoint {
		get { qrGenerator.gradientStartPoint }
		set {
			qrGenerator.gradientStartPoint = newValue
			updateQRData()
		}
	}
	public var gradientEndPoint: CGPoint {
		get { qrGenerator.gradientEndPoint }
		set {
			qrGenerator.gradientEndPoint = newValue
			updateQRData()
		}
	}
	public var gradientStyle: QRGradientStyle {
		get { qrGenerator.gradientStyle }
		set {
			qrGenerator.gradientStyle = newValue
			updateQRData()
		}
	}
	public var gradientBackgroundVisible: Bool {
		get { qrGenerator.gradientBackgroundVisible }
		set {
			qrGenerator.gradientBackgroundVisible = newValue
			updateQRData()
		}
	}
	public var gradientBackgroundStrength: CGFloat {
		get { qrGenerator.gradientBackgroundStrength }
		set {
			qrGenerator.gradientBackgroundStrength = newValue
			updateQRData()
		}
	}

	public var shadowOffset: CGPoint {
		get { qrGenerator.shadowOffset }
		set {
			qrGenerator.shadowOffset = newValue
			updateQRData()
		}
	}
	public var shadowSoftness: CGFloat {
		get { qrGenerator.shadowSoftness }
		set {
			qrGenerator.shadowSoftness = newValue
			updateQRData()
		}
	}

	public var iconImage: QRettyCodeImageGenerator.IconImageInsert {
		get { qrGenerator.iconImage }
		set {
			qrGenerator.iconImage = newValue
			updateQRData()
		}
	}

	private var batchUpdating: Bool = false

	public var renderedImage: UIImage? { qrGenerator.image }

	private let qrGenerator: QRettyCodeImageGenerator
	private let imageView = UIImageView()

	public override init(frame: CGRect) {
		qrGenerator = QRettyCodeImageGenerator(data: Data(), correctionLevel: .Q, size: .zero, style: [.dot(scale: 1, cornerRadius: 0)])
		super.init(frame: frame)
		commonInit()
	}

	public required init?(coder: NSCoder) {
		qrGenerator = QRettyCodeImageGenerator(data: Data(), correctionLevel: .Q, size: .zero, style: [.dot(scale: 1, cornerRadius: 0)])
		super.init(coder: coder)
		commonInit()
	}

	public init(qrGenerator: QRettyCodeImageGenerator) {
		self.qrGenerator = qrGenerator
		super.init(frame: .zero)
		commonInit()
	}

	private func commonInit() {
		addSubview(imageView)
		imageView.translatesAutoresizingMaskIntoConstraints = false
		let constraints = [
			imageView.topAnchor.constraint(equalTo: topAnchor),
			imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
			imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
			imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
		]
		constraints.forEach { $0.isActive = true }
		qrGenerator.data = "QRettyCodeView".data(using: .utf8)
		updateQRData()
	}

	public func beginBatchUpdates() {
		batchUpdating = true
	}

	public func finishBatchUpdates() {
		batchUpdating = false
		updateQRData()
	}

	private func updateQRData() {
		guard batchUpdating == false else { return }
		qrGenerator.size = min(bounds.size.width, bounds.size.height)
		imageView.image = qrGenerator.image
	}
}
