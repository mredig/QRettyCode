//
//  ViewController.swift
//  QRettyCodeDemo
//
//  Created by Michael Redig on 11/13/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import UIKit
import QRettyCode

class ViewController: UIViewController {

	@IBOutlet weak var qrettyView: QRettyCodeView!
	@IBOutlet weak var qrTextDataInput: UITextField!
	@IBOutlet weak var correctionSegment: UISegmentedControl!

	@IBOutlet weak var qrStyleDotSwitch: UISwitch!
	@IBOutlet weak var qrStyleDotScale: UISlider!
	@IBOutlet weak var qrStyleDotCornerRadius: UISlider!
	@IBOutlet weak var qrStyleChainSwitch: UISwitch!
	@IBOutlet weak var qrStyleChainWidth: UISlider!
	@IBOutlet weak var qrStyleDiamondCurve: UISlider!
	@IBOutlet weak var qrStyleDiamondSwitch: UISwitch!

	@IBOutlet weak var renderEffectsSwitch: UISwitch!
	@IBOutlet weak var gradStyleSwitch: UISwitch!
	@IBOutlet weak var gradBackgroundToggle: UISwitch!
	@IBOutlet weak var gradBGStrength: UISlider!

	@IBOutlet weak var startHue: UISlider!
	@IBOutlet weak var startSat: UISlider!
	@IBOutlet weak var startBrightness: UISlider!

	@IBOutlet weak var endHue: UISlider!
	@IBOutlet weak var endSat: UISlider!
	@IBOutlet weak var endBrightness: UISlider!

	@IBOutlet weak var startX: UISlider!
	@IBOutlet weak var startY: UISlider!

	@IBOutlet weak var endX: UISlider!
	@IBOutlet weak var endY: UISlider!

	@IBOutlet weak var offsetX: UISlider!
	@IBOutlet weak var offsetY: UISlider!

	@IBOutlet weak var softnessSlider: UISlider!

	@IBOutlet weak var iconStyleSegment: UISegmentedControl!
	@IBOutlet weak var selectedIconSegment: UISegmentedControl!
	@IBOutlet weak var iconScale: UISlider!
	@IBOutlet weak var iconBorderRadius: UISlider!


//	let qrettyView = QRettyCodeImageGenerator(data: "testing".data(using: .utf8), correctionLevel: .H, size: 212)
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		qrettyView.renderEffects = true
		qrettyView.gradientBackgroundVisible = true
		setUI()
		updateQRCode()
//		imageView.image = qrettyView.image
	}

	@IBAction func textFieldChanged(_ sender: UITextField) {
		updateQRCode()
	}

	private func setUI() {
		gradBGStrength.value = qrettyView.gradientBackgroundStrength.float

		var (h, s, b): (CGFloat, CGFloat, CGFloat) = (0, 0, 0)
		qrettyView.gradientStartColor.getHue(&h, saturation: &s, brightness: &b, alpha: nil)
		startHue.value = h.float
		startSat.value = s.float
		startBrightness.value = b.float

		qrettyView.gradientEndColor.getHue(&h, saturation: &s, brightness: &b, alpha: nil)
		endHue.value = h.float
		endSat.value = s.float
		endBrightness.value = b.float

		offsetX.value = qrettyView.shadowOffset.x.float
		offsetY.value = qrettyView.shadowOffset.y.float
		softnessSlider.value = qrettyView.shadowSoftness.float

	}

	private func updateQRCode() {
		qrettyView.beginBatchUpdates()

		qrettyView.data = qrTextDataInput.text?.data(using: .utf8)
		qrettyView.correctionLevel = QRCorrectionLevel(rawValue: correctionSegment.titleForSegment(at: correctionSegment.selectedSegmentIndex) ?? "") ?? .H
		var styleInfo = Set<QRettyStyle>()
		if qrStyleDotSwitch.isOn {
			let scale = qrStyleDotScale.cgValue
			let cornerRadius = qrStyleDotCornerRadius.cgValue
			styleInfo.insert(.dot(scale: scale, cornerRadius: cornerRadius))
		}
		if qrStyleChainSwitch.isOn {
			let chainWidth = qrStyleChainWidth.cgValue
			styleInfo.insert(.chain(width: chainWidth))
		}
		if qrStyleDiamondSwitch.isOn {
			let curve = qrStyleDiamondCurve.cgValue
			styleInfo.insert(.diamond(curve: curve))
		}
		qrettyView.style = styleInfo

		qrettyView.renderEffects = renderEffectsSwitch.isOn
		qrettyView.gradientStyle = gradStyleSwitch.isOn ? .linear : .radial
		qrettyView.gradientBackgroundVisible = gradBackgroundToggle.isOn
		qrettyView.gradientBackgroundStrength = CGFloat(gradBGStrength.value)
		qrettyView.gradientStartColor = UIColor(hue: startHue.cgValue, saturation: startSat.cgValue, brightness: startBrightness.cgValue, alpha: 1.0)
		qrettyView.gradientEndColor = UIColor(hue: endHue.cgValue, saturation: endSat.cgValue, brightness: endBrightness.cgValue, alpha: 1.0)

		let startPoint = CGPoint(x: startX.cgValue, y: startY.cgValue)
		let endPoint = CGPoint(x: endX.cgValue, y: endY.cgValue)
		qrettyView.gradientStartPoint = startPoint
		qrettyView.gradientEndPoint = endPoint

		let offset = CGPoint(x: offsetX.cgValue, y: offsetY.cgValue)
		qrettyView.shadowOffset = offset
		qrettyView.shadowSoftness = softnessSlider.cgValue

//		qrettyView.size = imageView.frame.maxX

		if let name = selectedIconSegment.titleForSegment(at: selectedIconSegment.selectedSegmentIndex), let image = UIImage(named: name) {
			switch iconStyleSegment.selectedSegmentIndex {
			case 1:
				qrettyView.iconImage = .over(image: image, scale: iconScale.cgValue)
			case 2:
				qrettyView.iconImage = .inside(image: image, borderRadius: iconBorderRadius.cgValue, scale: iconScale.cgValue)
			default:
				qrettyView.iconImage = .none
			}
		}

//		imageView.image = qrettyView.image
		qrettyView.finishBatchUpdates()

		guard let image = qrettyView.renderedImage, let verifiedData = qrettyView.data, let verifiedString = String(data: verifiedData, encoding: .utf8) else { return }


		DispatchQueue.global().async {
			print("\(self.counter)", QRettyChecker.verifyQuality(qrImage: image, withVerificationString: verifiedString))
			self.counter += 1
		}
	}
	var counter = 0

	@IBAction func inputChanged(_ sender: Any) {
		updateQRCode()
	}
}

extension ViewController: UITextFieldDelegate {
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
}

extension UISlider {
	var cgValue: CGFloat {
		CGFloat(value)
	}
}

extension CGFloat {
	var float: Float {
		Float(self)
	}
}
