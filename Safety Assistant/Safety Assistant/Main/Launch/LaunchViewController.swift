//
//  LaunchViewController.swift
//  Safety Assistant
//
//  Created by Csongor Barabasi on 02/08/2017.
//  Copyright © 2017 Csongor Barabasi. All rights reserved.
//

import UIKit
import SimpleAnimation

class LaunchViewController: UIViewController {

	@IBOutlet weak var imageView: UIImageView!
	
	let kRotationAnimationKey = "com.safetyassistant.3drot"
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(true)
		
		imageView.fadeIn(duration: 1.0, delay: 0.2, completion: { [weak self] done in
			if UserDefaults.standard.bool(forKey: "registered") {
				self?.showMapPage()
			} else {
				self?.showRegistrationPage()
			}
		})
		
	}
	
	func showMapPage() {
		let navController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MapNavigationController") as! UINavigationController
		self.present(navController, animated: true, completion: nil)
	}
	
	func showRegistrationPage() {
		let registeVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RegisterViewController") as! RegisterViewController
		self.present(registeVC, animated: true, completion: nil)
	}

}
