//
//  MapViewController.swift
//  Safety Assistant
//
//  Created by Csongor Barabasi on 31/07/2017.
//  Copyright © 2017 Csongor Barabasi. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import KRProgressHUD

class MapViewController: UIViewController {
	
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var textField: UITextField!
	@IBOutlet weak var tableView: UITableView!
	
	var nhoods: [Neighbourhood] = []
	var polygons: [MKPolygon] = []
	var sanFrancisco = CLLocationCoordinate2D(latitude: 37.760545, longitude: -122.443351)
	
	let locationManager = CLLocationManager()
	var matchingItems: [MKMapItem] = []
	var selectedPin: MKPlacemark? = nil
	
	var isTextFieldHidden = true
	var isTableViewHidden = true
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		KRProgressHUD.show()
		
		self.tableView.delegate = self
		self.tableView.dataSource = self
		self.tableView.tableFooterView = UIView(frame: CGRect.zero)
		
		self.mapView.isHidden = true
		
		self.locationManager.delegate = self
		self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
		self.locationManager.requestWhenInUseAuthorization()
		self.locationManager.requestLocation()
		
		textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
		self.textField.delegate = self
		
		MapService(url: "http://barabasicsongor.com/heatmap.json").makeRequest(completion: { [weak self] result in
			self?.nhoods = result
			self?.loadMap()
		})
		
    }
	
	// ACTIONS
	
	@IBAction func chatButtonPress(_ sender: Any) {
		KRProgressHUD.show()
		let chatViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
		
		self.navigationController?.pushViewController(chatViewController, animated: true)
		KRProgressHUD.dismiss()
	}
	
	@IBAction func profileButtonPress(_ sender: Any) {
		KRProgressHUD.show()
		let registeVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RegisterViewController") as! RegisterViewController
		registeVC.type = .Update
		self.navigationController?.pushViewController(registeVC, animated: true)
		KRProgressHUD.dismiss()
	}

	
	func textFieldDidChange(_ textField: UITextField) {
		
		if textField.text?.characters.count == 0 {
			
			if isTableViewHidden == false {
				showTableView()
			}
			
			matchingItems = []
			self.tableView.reloadData()
		} else {
			if isTableViewHidden {
				showTableView()
			}
			
			let request = MKLocalSearchRequest()
			request.naturalLanguageQuery = self.textField.text
			request.region = self.mapView.region
			let search = MKLocalSearch(request: request)
			search.start(completionHandler: { [weak self] response, _ in
				guard let response = response else {
					return
				}
				
				self?.matchingItems = response.mapItems
				self?.tableView.reloadData()
			})
			
		}
	}
	
	// MAP FUNCTIONS
	
	func loadMap() {
		self.mapView.delegate = self
		let span = MKCoordinateSpanMake(0.15, 0.15)
		let region = MKCoordinateRegion(center: sanFrancisco, span: span)
		self.mapView.setRegion(region, animated: true)
		
		self.addPolygons()
		
		let tap = UITapGestureRecognizer(target: self, action: #selector(MapViewController.showTextField))
		self.mapView.addGestureRecognizer(tap)
		
		self.mapView.isHidden = false
		KRProgressHUD.dismiss()
	}
	
	func addPolygons() {
		
		for hood in nhoods {
			
			var points: [CLLocationCoordinate2D] = []
			
			for var i in stride(from: 0, to: hood.polygon.count-1, by: 2) {
				points.append(CLLocationCoordinate2DMake(hood.polygon[i], hood.polygon[i+1]))
			}
			
			let poly = MKPolygon(coordinates: &points, count: points.count)
			poly.title = hood.name
			self.polygons.append(poly)
			
		}
		
		self.mapView.addOverlays(polygons)
	}
	
	// HELPER FUNCTIONS
	
	func showTextField() {
		if isTextFieldHidden {
			isTextFieldHidden = false
			UIView.animate(withDuration: 0.25, animations: { [weak self] in
				self?.textField.alpha = 1.0
			})
		} else {
			isTextFieldHidden = true
			self.view.endEditing(true)
			
			if isTableViewHidden == false {
				showTableView()
			}
			
			UIView.animate(withDuration: 0.25, animations: { [weak self] in
				self?.textField.alpha = 0.0
			})
			
			self.textField.text = ""
			self.matchingItems = []
			self.tableView.reloadData()
		}
	}
	
	func showTableView() {
		if isTableViewHidden {
			isTableViewHidden = false
			UIView.animate(withDuration: 0.1, animations: { [weak self] in
				self?.tableView.alpha = 1.0
			})
		} else {
			isTableViewHidden = true
			UIView.animate(withDuration: 0.1, animations: { [weak self] in
				self?.tableView.alpha = 0.0
			})
		}
	}
	
	func parseAddress(selectedItem:MKPlacemark) -> String {
		// put a space between "4" and "Melrose Place"
		let firstSpace = (selectedItem.subThoroughfare != nil && selectedItem.thoroughfare != nil) ? " " : ""
		// put a comma between street and city/state
		let comma = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) && (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", " : ""
		// put a space between "Washington" and "DC"
		let secondSpace = (selectedItem.subAdministrativeArea != nil && selectedItem.administrativeArea != nil) ? " " : ""
		let addressLine = String(
			format:"%@%@%@%@%@%@%@",
			// street number
			selectedItem.subThoroughfare ?? "",
			firstSpace,
			// street name
			selectedItem.thoroughfare ?? "",
			comma,
			// city
			selectedItem.locality ?? "",
			secondSpace,
			// state
			selectedItem.administrativeArea ?? ""
		)
		return addressLine
	}
	
	func getDangerLevel() {
		KRProgressHUD.show()
		
		self.mapView.removeAnnotations(self.mapView.annotations)
		
		APIService().getDangerLevel(place: parseAddress(selectedItem: self.selectedPin!), completion: { [weak self] resp in
			KRProgressHUD.dismiss()
			self?.alert(title: "Result", message: resp)
			self?.selectedPin = nil
		})
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

}

extension MapViewController: MKMapViewDelegate {
	
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		if overlay is MKPolygon {
			let renderer = MKPolygonRenderer(polygon: overlay as! MKPolygon)
			let title = renderer.polygon.title!
			
			var ind = -1
			for hood in nhoods {
				ind = ind + 1
				
				if hood.name.compare(title).rawValue == 0 {
					break
				}
			}
			
			renderer.fillColor = UIColor(hex: nhoods[ind].color).withAlphaComponent(0.5)
			renderer.strokeColor = UIColor.black.withAlphaComponent(0.7)
			renderer.lineWidth = 0.5
			return renderer
		}
		
		return MKOverlayRenderer()
	}
	
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?{
		if annotation is MKUserLocation {
			//return nil so map view draws "blue dot" for standard user location
			return nil
		}
		let reuseId = "pin"
		var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
		pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
		pinView?.pinTintColor = UIColor.orange
		pinView?.canShowCallout = true
		let smallSquare = CGSize(width: 30, height: 30)
		let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
		button.setBackgroundImage(UIImage(named: "robot_avatar"), for: .normal)
		button.addTarget(self, action: #selector(MapViewController.getDangerLevel), for: .touchUpInside)
		pinView?.leftCalloutAccessoryView = button
		return pinView
	}
	
}

extension MapViewController: CLLocationManagerDelegate {
	
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		if status == .authorizedWhenInUse {
			locationManager.requestLocation()
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		// Updated location

//		Zoom to users current location
//		if let location = locations.first {
//			let span = MKCoordinateSpanMake(0.05, 0.05)
//			let region = MKCoordinateRegion(center: location.coordinate, span: span)
//			mapView.setRegion(region, animated: true)
//		}
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("Error with location manager")
	}
	
}

extension MapViewController: UITableViewDelegate, UITableViewDataSource {
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.matchingItems.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		let selectedItem = self.matchingItems[indexPath.row].placemark
		
		cell.textLabel?.text = parseAddress(selectedItem: selectedItem)
		cell.textLabel?.font = UIFont(name: (cell.textLabel?.font.fontName)!, size: 12.0)
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let selectedItem = self.matchingItems[indexPath.row].placemark
		
		self.selectedPin = selectedItem
		
		self.mapView.removeAnnotations(self.mapView.annotations)
		let annotation = MKPointAnnotation()
		annotation.coordinate = selectedItem.coordinate
		annotation.title = selectedItem.title
		if let city = selectedItem.locality,
			let state = selectedItem.administrativeArea {
			annotation.subtitle = String(format: "%@ %@", city, state)
		}
		self.mapView.addAnnotation(annotation)
		let span = MKCoordinateSpanMake(0.05, 0.05)
		let region = MKCoordinateRegionMake(selectedItem.coordinate, span)
		self.mapView.setRegion(region, animated: true)
		
		showTableView()
		showTextField()
		
	}
	
}

extension MapViewController: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		self.view.endEditing(true)
		return false
	}
	
}
