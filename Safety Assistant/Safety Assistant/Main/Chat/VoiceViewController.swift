//
//  VoiceViewController.swift
//  Safety Assistant
//
//  Created by Csongor Barabasi on 10/08/2017.
//  Copyright © 2017 Csongor Barabasi. All rights reserved.
//

import UIKit
import AWSLex
import AWSMobileHubHelper

class VoiceViewController: UIViewController {

	@IBOutlet weak var voiceButton: AWSLexVoiceButton!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		let configuration = AWSServiceConfiguration(region: SafetyAssistantBotBotRegion, credentialsProvider: AWSIdentityManager.default().credentialsProvider)
		let botConfig = AWSLexInteractionKitConfig.defaultInteractionKitConfig(withBotName: SafetyAssistantBotBotName, botAlias: SafetyAssistantBotBotAlias)
		
		// register the interaction kit client for the voice button using the AWSLexVoiceButtonKey constant defined in SDK
		AWSLexInteractionKit.register(with: configuration!, interactionKitConfiguration: botConfig, forKey: AWSLexVoiceButtonKey)
		super.viewDidLoad()
		(self.voiceButton as AWSLexVoiceButton).delegate = self
		
		configureNavbar()
		
    }
	
	func configureNavbar() {
		self.navigationItem.hidesBackButton = true
		self.navigationItem.title = "Voice"
		
		let btn = UIButton(type: .custom)
		btn.setImage(UIImage(named: "back_button"), for: .normal)
		btn.frame = CGRect(x: 0, y: 0, width: 35, height: 30)
		btn.addTarget(self, action: #selector(VoiceViewController.backButtonPress), for: .touchUpInside)
		let item = UIBarButtonItem(customView: btn)
		self.navigationItem.setLeftBarButton(item, animated: true)
		
	}
	
	func backButtonPress() {
		self.navigationController?.popViewController(animated: true)
	}

}

extension VoiceViewController: AWSLexVoiceButtonDelegate {
	
	func voiceButton(_ button: AWSLexVoiceButton, on response: AWSLexVoiceButtonResponse) {
		// handle response from the voice button here
	}
	
	func voiceButton(_ button: AWSLexVoiceButton, onError error: Error) {
		// handle error response from the voice button here
	}
	
}
