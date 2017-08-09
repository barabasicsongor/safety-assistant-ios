//
//  HelpViewController.swift
//  Safety Assistant
//
//  Created by Csongor Barabasi on 09/08/2017.
//  Copyright © 2017 Csongor Barabasi. All rights reserved.
//

import UIKit

protocol HelpViewControllerDelegate: class {
	func doneButtonPress()
}

class HelpViewController: UIViewController {
	
	weak var delegate: HelpViewControllerDelegate?
	
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	@IBAction func doneButtonPress(_ sender: Any) {
		self.delegate?.doneButtonPress()
	}

}
