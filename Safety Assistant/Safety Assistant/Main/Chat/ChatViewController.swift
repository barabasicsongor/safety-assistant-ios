//
//  ChatViewController.swift
//  Safety Assistant
//
//  Created by Csongor Barabasi on 01/08/2017.
//  Copyright © 2017 Csongor Barabasi. All rights reserved.
//

import Foundation
import JSQMessagesViewController
import AWSLex
import AWSMobileHubHelper
import KRProgressHUD

let ClientSenderId = UserDefaults.standard.string(forKey: "name")
let ServerSenderId = "Server"

/// Manages a text-to-text conversation with a bot
class ChatViewController: JSQMessagesViewController, JSQMessagesComposerTextViewPasteDelegate {
	
	var messages: [JSQMessage]?
	var interactionKit: AWSLexInteractionKit?
	var sessionAttributes: [AnyHashable: Any]?
	var outgoingBubbleImageData: JSQMessagesBubbleImage?
	var incomingBubbleImageData: JSQMessagesBubbleImage?
	var textModeSwitchingCompletion: AWSTaskCompletionSource<NSString>?
	var clientImage: JSQMessagesAvatarImage?
	var serverImage: JSQMessagesAvatarImage?
	var helpVC: HelpViewController?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		configureNavbar()
		
		// setup service configuration for bots
		let configuration = AWSServiceConfiguration(region: SafetyAssistantBotBotRegion, credentialsProvider: AWSIdentityManager.default().credentialsProvider)
		// setup interaction kit configuration
		let botConfig = AWSLexInteractionKitConfig.defaultInteractionKitConfig(withBotName: SafetyAssistantBotBotName, botAlias: SafetyAssistantBotBotAlias)
		
		// disable automatic voice playback for text demo
		botConfig.autoPlayback = false
		
		// register the interaction kit client
		AWSLexInteractionKit.register(with: configuration!, interactionKitConfiguration: botConfig, forKey: SafetyAssistantBotBotName)
		AWSLexInteractionKit.register(with: configuration!, interactionKitConfiguration: botConfig, forKey: AWSLexVoiceButtonKey)
		// fetch and set the interaction kit client
		self.interactionKit = AWSLexInteractionKit.init(forKey: SafetyAssistantBotBotName)
		// set the interaction kit delegate
		self.interactionKit?.interactionDelegate = self
		
		// setup JSQMessagesViewController configuration
		self.showLoadEarlierMessagesHeader = false
		
		
		// Initialize avatars for client and server
		
		clientImage = JSQMessagesAvatarImageFactory().avatarImage(with: getUserImage())
		serverImage = JSQMessagesAvatarImageFactory().avatarImage(with: UIImage(named: "robot_avatar")!)
		
		// set the keyboard type
		self.inputToolbar.contentView?.textView?.keyboardType = UIKeyboardType.default
		self.inputToolbar.contentView?.textView?.placeHolder = "How can I help?"
		
		// initialize the messages list
		self.messages = [JSQMessage]()
		
		// set the colors for message bubbles
		let bubbleFactory = JSQMessagesBubbleImageFactory()
		self.outgoingBubbleImageData = bubbleFactory.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
		self.incomingBubbleImageData = bubbleFactory.incomingMessagesBubbleImage(with: UIColor(hex: "#004474"))
		
		self.inputToolbar.contentView?.leftBarButtonItem = nil
		
		self.navigationController?.navigationBar.isTranslucent = false
		showGreeting()
	}
	
	// ACTIONS
	
	@objc func backButtonPress() {
		self.navigationController?.popViewController(animated: true)
	}
	
	@objc func micButtonPress() {
		let voiceVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VoiceViewController") as! VoiceViewController
		self.navigationController?.pushViewController(voiceVC, animated: true)
	}
	
	// HELPER FUNCTIONS
	func configureNavbar() {
		self.navigationItem.hidesBackButton = true
		self.navigationItem.title = "Chat"
		
		let btn = UIButton(type: .custom)
		btn.setImage(UIImage(named: "back_button"), for: .normal)
		btn.frame = CGRect(x: 0, y: 0, width: 35, height: 30)
		btn.addTarget(self, action: #selector(ChatViewController.backButtonPress), for: .touchUpInside)
		let item = UIBarButtonItem(customView: btn)
		self.navigationItem.setLeftBarButton(item, animated: true)
		
		let btn1 = UIButton(type: .custom)
		btn1.setImage(UIImage(named: "mic"), for: .normal)
		btn1.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
		btn1.addTarget(self, action: #selector(ChatViewController.micButtonPress), for: .touchUpInside)
//		let item1 = UIBarButtonItem(customView: btn1)
//		self.navigationItem.setRightBarButton(item1, animated: true)
		
	}
	
	func showGreeting() {
		self.showTypingIndicator = true
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [weak self] in
			self?.messages?.append(JSQMessage(senderId: ServerSenderId, senderDisplayName: (self?.senderDisplayName())!, date: Date(), text: "Hello " + (self?.senderDisplayName())! + "! How can I help you?"))
			self?.collectionView?.reloadData()
			
			DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: { [weak self] in
				self?.messages?.append(JSQMessage(senderId: ServerSenderId, senderDisplayName: (self?.senderDisplayName())!, date: Date(), text: "Type 'help' for usage instructions"))
				self?.collectionView?.reloadData()
				self?.showTypingIndicator = false
			})
			
		})
		
	}
	
	func getUserImage() -> UIImage {
		let filename = getDocumentsDirectory().appendingPathComponent("profile_pic.png")
		return UIImage(contentsOfFile: filename.path)!
	}
	
	func getDocumentsDirectory() -> URL {
		let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		let documentsDirectory = paths[0]
		return documentsDirectory
	}
	
	func showHelp() {
		
		if let _ = helpVC { } else {
			helpVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "HelpViewController") as? HelpViewController
			helpVC!.delegate = self
		}
		
		present(helpVC!, animated: true, completion: nil)
	}
	
	// MARK: - JSQMessagesViewController delegate methods
	
	override func didPressSend(_ button: UIButton, withMessageText text: String, senderId: String, senderDisplayName: String, date: Date) {
		let message = JSQMessage(senderId: senderId, senderDisplayName: senderDisplayName, date: date, text: text)
		self.messages?.append(message)
		
		if let textModeSwitchingCompletion = textModeSwitchingCompletion {
			textModeSwitchingCompletion.set(result: text as NSString)
			self.textModeSwitchingCompletion = nil
		}
		else {
			
			if text.lowercased() == "help" {
				showHelp()
			} else {
				self.interactionKit?.text(inTextOut: text)
				self.showTypingIndicator = true
			}
			
		}
		self.finishSendingMessage(animated: true)
	}
	
	override func senderDisplayName() -> String {
		return UserDefaults.standard.string(forKey: "name")!
	}
	
	override func senderId() -> String {
		return ClientSenderId!
	}
	
	override func collectionView(_ collectionView: JSQMessagesCollectionView, messageDataForItemAt indexPath: IndexPath) -> JSQMessageData {
		
		return self.messages![indexPath.item]
	}
	
	override func collectionView(_ collectionView: JSQMessagesCollectionView, didDeleteMessageAt indexPath: IndexPath) {
		//DO NOTHING
	}
	
	override func collectionView(_ collectionView: JSQMessagesCollectionView, messageBubbleImageDataForItemAt indexPath: IndexPath) -> JSQMessageBubbleImageDataSource {
		let message = self.messages![indexPath.item]
		if (message.senderId == self.senderId()) {
			return self.outgoingBubbleImageData!
		}
		return self.incomingBubbleImageData!
	}
	
	override func collectionView(_ collectionView: JSQMessagesCollectionView, avatarImageDataForItemAt indexPath: IndexPath) -> JSQMessageAvatarImageDataSource? {
		let message = messages![indexPath.item]
		if message.senderId == ClientSenderId {
			return self.clientImage
		}
		return self.serverImage
	}
	
	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		if let messages = messages {
			return messages.count
		}
		return 0
	}
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
		let cell = (super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell)
		let msg = self.messages?[indexPath.item]
		if !msg!.isMediaMessage {
			if (msg?.senderId == self.senderId()) {
				cell.textView?.textColor = UIColor.black
			}
			else {
				cell.textView?.textColor = UIColor.white
			}
		}
		return cell
	}
	
	override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForCellTopLabelAt indexPath: IndexPath) -> NSAttributedString? {
		if indexPath.item % 3 == 0 {
			let message = self.messages?[indexPath.item]
			return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message!.date)
		}
		return nil
	}
	
	override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath) -> NSAttributedString? {
		let message = self.messages?[indexPath.item]
		
		// iOS7-style sender name labels
		if (message?.senderId == self.senderId()) {
			return nil
		}
		if indexPath.item - 1 > 0 {
			let previousMessage = self.messages?[indexPath.item - 1]
			if (previousMessage?.senderId == message?.senderId) {
				return nil
			}
		}
		
		// Don't specify attributes to use the defaults.
		return NSAttributedString(string: message!.senderDisplayName)
	}
	
	override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForCellBottomLabelAt indexPath: IndexPath) -> NSAttributedString? {
		return nil
	}
	
	func composerTextView(_ textView: JSQMessagesComposerTextView, shouldPasteWithSender sender: Any) -> Bool {
		return true
	}
	
}

// MARK: Bot Interaction Kit
extension ChatViewController: AWSLexInteractionDelegate {
	
	func interactionKit(_ interactionKit: AWSLexInteractionKit, onError error: Error) {
		print("Error occurred: \(error)")
	}
	
	func interactionKit(_ interactionKit: AWSLexInteractionKit, switchModeInput: AWSLexSwitchModeInput, completionSource: AWSTaskCompletionSource<AWSLexSwitchModeResponse>?) {
		self.sessionAttributes = switchModeInput.sessionAttributes
		var length: Double = 0.0
		if let str = switchModeInput.outputText {
			length = length + Double(str.characters.count) * 0.15
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(Int(length)), execute: {
			let message: JSQMessage
			// Handle a successful fulfillment
			if (switchModeInput.dialogState == AWSLexDialogState.readyForFulfillment) {
				// Currently just displaying the slots returned on ready for fulfillment
				if let slots = switchModeInput.slots {
					message = JSQMessage(senderId: ServerSenderId, senderDisplayName: "", date: Date(), text: "Slots:\n\(slots)")
					self.messages?.append(message)
					self.finishSendingMessage(animated: true)
				}
			} else {
				message = JSQMessage(senderId: ServerSenderId, senderDisplayName: "", date: Date(), text: switchModeInput.outputText!)
				self.messages?.append(message)
				self.finishSendingMessage(animated: true)
			}
			
			self.showTypingIndicator = false
			
		})
		//this can expand to take input from user.
		let switchModeResponse = AWSLexSwitchModeResponse()
		switchModeResponse.interactionMode = AWSLexInteractionMode.text
		switchModeResponse.sessionAttributes = switchModeInput.sessionAttributes
		completionSource?.set(result: switchModeResponse)
	}
	
	/*
	* Sent to delegate when the Switch mode requires a user to input a text. You should set the completion source result to the string that you get from the user. This ensures that the session attribute information is carried over from the previous request to the next one.
	*/
	func interactionKitContinue(withText interactionKit: AWSLexInteractionKit, completionSource: AWSTaskCompletionSource<NSString>) {
		textModeSwitchingCompletion = completionSource
	}
	
}

extension ChatViewController: HelpViewControllerDelegate {
	func doneButtonPress() {
		helpVC!.dismiss(animated: true, completion: nil)
	}
}
