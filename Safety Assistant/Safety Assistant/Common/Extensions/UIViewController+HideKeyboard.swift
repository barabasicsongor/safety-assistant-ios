//
//  UIViewController+HideKeyboard.swift
//  Safety Assistant
//
//  Created by Csongor Barabasi on 02/08/2017.
//  Copyright © 2017 Csongor Barabasi. All rights reserved.
//

import UIKit

extension UIViewController {
	func hideKeyboardWhenTappedAround() {
		let tap: UITapGestureRecognizer =  UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
		tap.cancelsTouchesInView = false
		view.addGestureRecognizer(tap)
	}
	
	func dismissKeyboard() {
		view.endEditing(true)
	}
}
