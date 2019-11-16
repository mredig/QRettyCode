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
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var qrTextDataInput: UITextField!
	@IBOutlet weak var correctionSegment: UISegmentedControl!
	@IBOutlet weak var qrStyleToggle: UISwitch!
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

	let qrGen = QRettyCodeImageGenerator(data: "testing".data(using: .utf8), correctionLevel: .H, size: 212, style: .dots)
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		qrGen.renderEffects = true
		qrGen.gradientBackgroundVisible = true
		qrGen.size = imageView.frame.maxX
		imageView.image = qrGen.image
	}

	@IBAction func textFieldChanged(_ sender: UITextField) {
		updateQRCode()
	}

	private func updateQRCode() {
		qrGen.data = qrTextDataInput.text?.data(using: .utf8)
		qrGen.correctionLevel = QRCorrectionLevel(rawValue: correctionSegment.titleForSegment(at: correctionSegment.selectedSegmentIndex) ?? "") ?? .H
		qrGen.style = qrStyleToggle.isOn ? .dots : .blocks
		qrGen.renderEffects = renderEffectsSwitch.isOn
		qrGen.gradientStyle = gradStyleSwitch.isOn ? .linear : .radial
		qrGen.gradientBackgroundVisible = gradBackgroundToggle.isOn
		qrGen.gradientBackgroundStrength = CGFloat(gradBGStrength.value)
		qrGen.gradientStartColor = UIColor(hue: startHue.cgValue, saturation: startSat.cgValue, brightness: startBrightness.cgValue, alpha: 1.0)
		qrGen.gradientEndColor = UIColor(hue: endHue.cgValue, saturation: endSat.cgValue, brightness: endBrightness.cgValue, alpha: 1.0)

		let startPoint = CGPoint(x: startX.cgValue, y: startY.cgValue)
		let endPoint = CGPoint(x: endX.cgValue, y: endY.cgValue)
		qrGen.gradientStartPoint = startPoint
		qrGen.gradientEndPoint = endPoint

		let offset = CGPoint(x: offsetX.cgValue, y: offsetY.cgValue)
		qrGen.shadowOffset = offset

		qrGen.shadowSoftness = softnessSlider.cgValue

		imageView.image = qrGen.image
	}

	@IBAction func inputChanged(_ sender: Any) {
		updateQRCode()
	}


}

extension UISlider {
	var cgValue: CGFloat {
		CGFloat(value)
	}
}
