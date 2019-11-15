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
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		qrettyCodeView.data = "test".data(using: .utf8)
		DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
			self.imageView.image = self.qrettyCodeView.image
		}
	}


}

