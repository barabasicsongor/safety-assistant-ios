//
//  MapViewController.swift
//  Safety Assistant
//
//  Created by Csongor Barabasi on 31/07/2017.
//  Copyright © 2017 Csongor Barabasi. All rights reserved.
//

import UIKit
import SpriteKit
import ARKit
import CoreLocation
import GameplayKit
import KRProgressHUD
import SwiftyJSON

class ARMapViewController: UIViewController {
	
	var data = [Dictionary<String, Any>]()
	
    var userLocation = CLLocation()
    var userHeading = 0.0
    var headingCount = 0
    var anchors = [UUID: Int]()
    
    @IBOutlet var sceneView: ARSKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		LocationService.sharedInstance.startUpdatingLocation()
		LocationService.sharedInstance.delegate = self
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and node count
        sceneView.showsFPS = true
        sceneView.showsNodeCount = true
        
        // Load the SKScene from 'Scene.sks'
        if let scene = SKScene(fileNamed: "Scene") {
            sceneView.presentScene(scene)
        }
		
		configureNavbar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
		let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
		
		APIService().getARMap { json in
			if let js = json {
				self.data = js
			}
			LocationService.sharedInstance.startUpdatingHeading()
		}
		
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
	func configureNavbar() {
		self.navigationItem.hidesBackButton = true
		
		let btn = UIButton(type: .custom)
		btn.setImage(UIImage(named: "back_button"), for: .normal)
		btn.frame = CGRect(x: 0, y: 0, width: 35, height: 30)
		btn.addTarget(self, action: #selector(ARMapViewController.backButtonPress), for: .touchUpInside)
		let item = UIBarButtonItem(customView: btn)
		self.navigationItem.setLeftBarButton(item, animated: true)
		
	}
	
	@objc func backButtonPress() {
		self.navigationController?.popViewController(animated: true)
	}
    
    func createSights() {
		
        var index = -1
        for p in data {
			index += 1
			
            let locationLat = p["lat"] as! Double
            let locationLon = p["lng"] as! Double
            let location = CLLocation(latitude: locationLat, longitude: locationLon)
            
            // calculate the distance from the user to this point, then calculate its azimuth
            let distance = Float(userLocation.distance(from: location))
            let azimuthFromUser = direction(from: userLocation, to: location)
            
            // calculate the angle from the user to that direction
            let angle = azimuthFromUser - userHeading
            let angleRadians = deg2rad(angle)
            
            // create a horizontal rotation matrix
            let rotationHorizontal = matrix_float4x4(SCNMatrix4MakeRotation(Float(angleRadians), 1, 0, 0))
            
            // create a vertical rotation matrix
            let rotationVertical = matrix_float4x4(SCNMatrix4MakeRotation(-0.2 + Float(distance / 600), 0, 1, 0))
            
            // combine the horizontal and vertical matrices, then combine that ith the camera transform
            let rotation = simd_mul(rotationHorizontal, rotationVertical)
            guard let sceneView = self.view as? ARSKView else { return }
            guard let frame = sceneView.session.currentFrame else { return }
            let rotation2 = simd_mul(frame.camera.transform, rotation)
            
            // create a matrix that lets us position the anchor into the screen, then combine that with our combined matrix so far
            var translation = matrix_identity_float4x4
            translation.columns.3.z = -(distance / 50)
            
            let transform = simd_mul(rotation2, translation)
            
            // create a new anchor using the final matrix, then add it to our pages dictionary
            let anchor = ARAnchor(transform: transform)
            sceneView.session.add(anchor: anchor)
			anchors[anchor.identifier] = index
        }
    }
    
    func deg2rad(_ degrees: Double) -> Double {
        return degrees * Double.pi / 180
    }
    
    func rad2Deg(_ radians: Double)-> Double {
        return radians * 180 / Double.pi
    }
    
    func direction(from pl: CLLocation, to p2: CLLocation) -> Double {
        
        let lon_delta = p2.coordinate.longitude - pl.coordinate.longitude
        let y = sin(lon_delta) * cos(p2.coordinate.longitude)
        let x = cos(pl.coordinate.latitude) * sin(p2.coordinate.latitude) - sin(pl.coordinate.latitude) * cos(p2.coordinate.latitude)  * cos(lon_delta)
        let radians = atan2(y,x)
        
        return rad2Deg(radians)
    }
    
}

extension ARMapViewController: ARSKViewDelegate {
	
	func view(_ view: ARSKView, nodeFor anchor: ARAnchor) -> SKNode? {
		
		let index = anchors[anchor.identifier]!
		
		//create a label node showing the title for this anchor
		let labelNode = SKLabelNode(text: data[index]["title"] as? String)
		labelNode.fontSize = 15.0
		labelNode.horizontalAlignmentMode = .center
		labelNode.verticalAlignmentMode = .center
		
		//scale up the label's size so we have some margin
		let size = labelNode.frame.size//.applying(CGAffineTransform(scaleX: 1.1, y: 1.4))
		
		//create a background node using the new size, rounding its corners gently
		let backgroundNode = SKShapeNode(circleOfRadius: size.width)
		
		//fill it in with a random color
		backgroundNode.fillColor = UIColor(hex: data[index]["color"] as! String).withAlphaComponent(0.7)
		
		//draw a border around it using a more opaque version of its fill color
		backgroundNode.strokeColor = UIColor(hex: data[index]["color"] as! String).withAlphaComponent(1)
		backgroundNode.lineWidth = 2
		
		//add the label to the background then send back the backgorund
		backgroundNode.addChild(labelNode)
		
		return backgroundNode
	}
	
	func session(_ session: ARSession, didFailWithError error: Error) {
		// Present an error message to the user
	}
	
	func sessionWasInterrupted(_ session: ARSession) {
		// Inform the user that the session has been interrupted, for example, by presenting an overlay
	}
	
	func sessionInterruptionEnded(_ session: ARSession) {
		// Reset tracking and/or remove existing anchors if consistent tracking is required
	}
	
}

extension ARMapViewController: LocationServiceDelegate {
	
	func tracingLocationDidFailWithError(_ error: NSError) {
		print("Location error")
	}
	
	func tracingLocation(_ currentLocation: CLLocation) {
		print("Location update: \(currentLocation)")
		userLocation = currentLocation
	}
	
	func updateHeading(heading: CLHeading) {
		DispatchQueue.main.async {
			
			self.headingCount += 1
			if self.headingCount != 2 { return }
			
			self.userHeading = heading.magneticHeading
			LocationService.sharedInstance.stopUpdatingHeading()
			
			DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
				self.createSights()
			})
			
		}
	}
	
}
