//
//  LocationManager.swift
//  Safety Assistant
//
//  Created by Csongor Barabasi on 15/08/2017.
//  Copyright © 2017 Csongor Barabasi. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationServiceDelegate {
	func tracingLocation(_ currentLocation: CLLocation)
	func tracingLocationDidFailWithError(_ error: NSError)
	func updateHeading(heading: CLHeading)
}

class LocationService: NSObject, CLLocationManagerDelegate {
	static let sharedInstance: LocationService = {
		let instance = LocationService()
		return instance
	}()
	
	var locationManager: CLLocationManager?
	var currentLocation: CLLocation?
	var heading: CLHeading?
	var delegate: LocationServiceDelegate?
	
	override init() {
		super.init()
		
		self.locationManager = CLLocationManager()
		guard let locationManager = self.locationManager else {
			return
		}
		
		if CLLocationManager.authorizationStatus() == .notDetermined {
			locationManager.requestWhenInUseAuthorization()
		}
		
		locationManager.desiredAccuracy = kCLLocationAccuracyBest // The accuracy of the location data
		locationManager.distanceFilter = 2 // The minimum distance (measured in meters) a device must move horizontally before an update event is generated.
		locationManager.delegate = self
	}
	
	func startUpdatingLocation() {
		print("Starting Location Updates")
		self.locationManager?.startUpdatingLocation()
	}
	
	func stopUpdatingLocation() {
		print("Stop Location Updates")
		self.locationManager?.stopUpdatingLocation()
	}
	
	func startUpdatingHeading() {
		self.locationManager?.startUpdatingHeading()
	}
	
	func stopUpdatingHeading() {
		self.locationManager?.stopUpdatingHeading()
	}
	
	// CLLocationManagerDelegate
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		
		guard let location = locations.last else {
			return
		}
		
		// singleton for get last(current) location
		currentLocation = location
		
		// use for real time update location
		updateLocation(location)
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
		print("Heading: \(newHeading.magneticHeading)")
		updateHeading(heading: newHeading)
	}
	
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		if status == .authorizedWhenInUse {
			locationManager?.requestLocation()
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		
		// do on error
		updateLocationDidFailWithError(error as NSError)
	}
	
	// Private function
	fileprivate func updateLocation(_ currentLocation: CLLocation){
		
		guard let delegate = self.delegate else {
			return
		}
		
		delegate.tracingLocation(currentLocation)
	}
	
	fileprivate func updateLocationDidFailWithError(_ error: NSError) {
		
		guard let delegate = self.delegate else {
			return
		}
		
		delegate.tracingLocationDidFailWithError(error)
	}
	
	fileprivate func updateHeading(heading: CLHeading) {
		guard let delegate = self.delegate else {
			return
		}
		
		delegate.updateHeading(heading: heading)
	}
}
