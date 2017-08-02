//
//  RegisterViewController.swift
//  Safety Assistant
//
//  Created by Csongor Barabasi on 02/08/2017.
//  Copyright © 2017 Csongor Barabasi. All rights reserved.
//

import UIKit
import MapKit

class RegisterViewController: UIViewController {
	
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var textField: UITextField!
	
	let picker = UIImagePickerController()
	var selectedImg = false
	
    override func viewDidLoad() {
        super.viewDidLoad()

		imageView.layer.cornerRadius = 75.0
		imageView.layer.masksToBounds = true
		
        picker.delegate = self
		
		textField.delegate = self
		
		self.hideKeyboardWhenTappedAround()
    }
	
	// ACTIONS
	
	@IBAction func cameraButtonPress(_ sender: Any) {
		let alertVC = UIAlertController(
			title: "Select profile picture",
			message: "",
			preferredStyle: .actionSheet)
		let cameraAction = UIAlertAction(
			title: "Camera",
			style:.default,
			handler: { [weak self] action in self?.photoFromCamera()})
		let libraryAction = UIAlertAction(
			title: "Library",
			style:.default,
			handler: { [weak self] action in self?.photoFromLibrary()})
		let cancelAction = UIAlertAction(
			title: "Cancel",
			style: .cancel,
			handler: nil)
		alertVC.addAction(cameraAction)
		alertVC.addAction(libraryAction)
		alertVC.addAction(cancelAction)
		present(
			alertVC,
			animated: true,
			completion: nil)
	}
	
	@IBAction func continueButtonPress(_ sender: Any) {
		
		if selectedImg == false {
			alert(title: "No image", message: "Please set a profile picture for a friendlier environment")
		} else if textField.text!.characters.count == 0 {
			alert(title: "No name", message: "Please set a name for a friendlier environment")
		} else {
			save(name: textField.text!, image: imageView.image!)
			UserDefaults.standard.set(true, forKey: "registered")
			
			let navController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MapNavigationController") as! UINavigationController
			present(navController, animated: true, completion: nil)
		}
	}
	
	// PHOTO ACTION
	
	func photoFromLibrary() {
		picker.allowsEditing = false
		picker.sourceType = .photoLibrary
		picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
		picker.modalPresentationStyle = .popover
		present(picker, animated: true, completion: nil)
	}
	
	func photoFromCamera() {
		if UIImagePickerController.isSourceTypeAvailable(.camera) {
			picker.allowsEditing = false
			picker.sourceType = UIImagePickerControllerSourceType.camera
			picker.cameraCaptureMode = .photo
			picker.modalPresentationStyle = .fullScreen
			present(picker, animated: true, completion: nil)
		} else {
			alert(title: "No Camera", message: "Sorry, this device has no camera")
		}
	}
	
	// ALERT
	
	func alert(title: String, message: String) {
		let alertVC = UIAlertController(
			title: title,
			message: message,
			preferredStyle: .alert)
		let okAction = UIAlertAction(
			title: "OK",
			style:.default,
			handler: nil)
		alertVC.addAction(okAction)
		present(
			alertVC,
			animated: true,
			completion: nil)
	}
	
	// FILE HANDLING
	
	func save(name: String, image: UIImage) {
		UserDefaults.standard.set(name, forKey: "name")
		
		if let data = UIImageJPEGRepresentation(image, 0.8) {
			let filename = getDocumentsDirectory().appendingPathComponent("profile_pic.png")
			try? data.write(to: filename)
		}
	}
	
	func getDocumentsDirectory() -> URL {
		let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		let documentsDirectory = paths[0]
		return documentsDirectory
	}

}

extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
		imageView.contentMode = .scaleAspectFill
		imageView.image = chosenImage
		selectedImg = true
		dismiss(animated: true, completion: nil)
	}
	
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		dismiss(animated: true, completion: nil)
	}
	
}

extension RegisterViewController: UITextFieldDelegate {
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		self.view.endEditing(true)
		return false
	}
}
