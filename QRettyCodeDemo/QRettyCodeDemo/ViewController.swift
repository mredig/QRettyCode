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
	@IBOutlet weak var qrettyCodeView: QRettyCodeView!
	@IBOutlet weak var imageView: UIImageView!

	let qrGen = QRettyCodeImageGenerator(data: "testing".data(using: .utf8), correctionLevel: .H, size: 212, style: .dots)
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		qrettyCodeView.data = "testing".data(using: .utf8)
		imageView.image = qrGen.image
	}

	@IBAction func textFieldChanged(_ sender: UITextField) {
		qrettyCodeView.data = sender.text?.data(using: .utf8)
		qrGen.data = sender.text?.data(using: .utf8)
		imageView.image = qrGen.image

	}

}

