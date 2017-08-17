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

protocol HandleMapSearch {
	func dropPinZoom(placemark: MKPlacemark)
}

class MapViewController: UIViewController {
	
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var searchButton: UIButton!
	@IBOutlet weak var zoomButton: UIButton!
	
	var rightBarButton: UIBarButtonItem!
	var leftBarButton: UIBarButtonItem!
	
	var nhoods: [Neighbourhood] = []
	var polygons: [MKPolygon] = []
	var sanFrancisco = CLLocationCoordinate2D(latitude: 37.760545, longitude: -122.443351)
	var sanFranciscoRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.760545, longitude: -122.443351), span: MKCoordinateSpanMake(0.15, 0.15))
	
	let locationManager = CLLocationManager()
	var selectedPin: MKPlacemark? = nil
	var isCustomPin = true
	
	var resultSearchController: UISearchController? = nil
	var searchBar: UISearchBar!
	
	var isSearchFieldHidden = true
	var polygonCounter = 0
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
		LocationService.sharedInstance.startUpdatingLocation()
		
		self.zoomButton.isHidden = true
		
		setupNavBar()
		loadMap()
		
		let locationSearchTable = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LocationSearchTableViewController") as? LocationSearchTableViewController
		locationSearchTable?.mapView = self.mapView
		locationSearchTable?.handleMapSearchDelegate = self
		resultSearchController = UISearchController(searchResultsController: locationSearchTable)
		resultSearchController?.searchResultsUpdater = locationSearchTable
		resultSearchController?.hidesNavigationBarDuringPresentation = false
		resultSearchController?.dimsBackgroundDuringPresentation = true
		definesPresentationContext = true
		
		searchBar = resultSearchController?.searchBar
		searchBar.delegate = self
		searchBar.sizeToFit()
		searchBar.placeholder = "Search for places"
		
		KRProgressHUD.show()
		
		DispatchQueue.global().async {
			
			MapService(url: "http://safetyassistant.us-east-1.elasticbeanstalk.com/heatmap").makeRequest(completion: { [weak self] result in
				self?.nhoods = result
				self?.addPolygons()
			})
		}
		
    }
	
	// VIEW SETUP
	
	func setupNavBar() {
		
		let btn1 = UIButton(type: .custom)
		btn1.setImage(UIImage(named: "info_icon"), for: .normal)
		btn1.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
		btn1.addTarget(self, action: #selector(MapViewController.mapInfoButtonPress), for: .touchUpInside)
		self.leftBarButton = UIBarButtonItem(customView: btn1)
		self.navigationItem.setLeftBarButton(self.leftBarButton, animated: true)

		let btn2 = UIButton(type: .custom)
		btn2.setImage(UIImage(named: "robot_1"), for: .normal)
		btn2.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
		btn2.addTarget(self, action: #selector(MapViewController.chatButtonPress), for: .touchUpInside)
		self.rightBarButton = UIBarButtonItem(customView: btn2)
		self.navigationItem.setRightBarButton(self.rightBarButton, animated: true)

	}
	
	// ACTIONS
	
	@objc func chatButtonPress() {
		KRProgressHUD.show()
		let chatViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
		
		self.navigationController?.pushViewController(chatViewController, animated: true)
		KRProgressHUD.dismiss()
	}
	
	@objc func mapInfoButtonPress() {
		let alert = UIAlertController(title: "Map", message: "Choose a map type", preferredStyle: .actionSheet)
		alert.addAction(UIAlertAction(title: "Hybrid", style: .default, handler: { [weak self] alrt in
			self?.mapView.mapType = .hybrid
		}))
		alert.addAction(UIAlertAction(title: "Satellite", style: .default, handler: { [weak self] alrt in
			self?.mapView.mapType = .satellite
		}))
		alert.addAction(UIAlertAction(title: "Standard", style: .default, handler: { [weak self] alrt in
			self?.mapView.mapType = .standard
		}))
		alert.addAction(UIAlertAction(title: "ARMap", style: .default, handler: { [weak self] _ in
			let arVC = self?.storyboard?.instantiateViewController(withIdentifier: "ARMapViewController") as! ARMapViewController
			self?.navigationController?.pushViewController(arVC, animated: true)
		}))
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		present(alert, animated: true, completion: nil)
	}
	
	@IBAction func userLocationZoomButtonPress(_ sender: Any) {
		
		let mapPoint: MKMapPoint = MKMapPointForCoordinate(self.mapView.userLocation.coordinate)
		
		let found = isPointInPolygons(point: mapPoint)
		
		if found {
			self.mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: self.mapView.userLocation.coordinate.latitude, longitude: self.mapView.userLocation.coordinate.longitude), span: MKCoordinateSpanMake(0.05, 0.05)), animated: true)
		} else {
			alert(title: "Sorry", message: "We don't support your current location.")
		}
		
	}
	
	@IBAction func searchButtonPress(_ sender: Any) {
		changeSearchFieldState()
	}
	
	@objc func mapViewTapGestureRecognizerTap(_ gesture: UITapGestureRecognizer) {
		if isSearchFieldHidden == false {
			changeSearchFieldState()
		} else {
			let point = gesture.location(in: self.mapView)
			let coordinate = self.mapView.convert(point, toCoordinateFrom: nil)
			let mappoint = MKMapPointForCoordinate(coordinate)
			let ind = pointInPolygonIndex(point: mappoint)
			
			if ind >= 0 {
				mapView.removeAnnotations(mapView.annotations)
				isCustomPin = false
				
				let annotation = MKPointAnnotation()
				annotation.coordinate = polygons[ind].coordinate
			
				annotation.title = "Total number of crimes in \(nhoods[ind].name): \(nhoods[ind].totalCrimes)"
				
				mapView.addAnnotation(annotation)
				let span = MKCoordinateSpanMake(0.05, 0.05)
				let region = MKCoordinateRegionMake(polygons[ind].coordinate, span)
				mapView.setRegion(region, animated: true)
			}
		}
	}
	
	// MAP FUNCTIONS
	
	func loadMap() {
		self.mapView.delegate = self
		self.mapView.setRegion(sanFranciscoRegion, animated: true)
		
		let tap = UITapGestureRecognizer(target: self, action: #selector(MapViewController.mapViewTapGestureRecognizerTap))
		self.mapView.addGestureRecognizer(tap)
	}
	
	func addPolygons() {
		
		for hood in nhoods {
			
			var points: [CLLocationCoordinate2D] = []
			
			for i in stride(from: 0, to: hood.polygon.count-1, by: 2) {
				points.append(CLLocationCoordinate2DMake(hood.polygon[i], hood.polygon[i+1]))
			}
			
			let poly = MKPolygon(coordinates: &points, count: points.count)
			poly.title = hood.name
			self.polygons.append(poly)
			
		}
		
		self.mapView.addOverlays(polygons)
	}
	
	func isPointInPolygons(point: MKMapPoint) -> Bool {
		for polygon in polygons {
			let polygonRenderer = MKPolygonRenderer(polygon: polygon)
			let polygonViewPoint: CGPoint = polygonRenderer.point(for: point)
			
			if polygonRenderer.path.contains(polygonViewPoint) {
				return true
			}
		}
		return false
	}
	
	func pointInPolygonIndex(point: MKMapPoint) -> Int {
		for i in 0..<polygons.count {
			let polygonRenderer = MKPolygonRenderer(polygon: polygons[i])
			let polygonViewPoint: CGPoint = polygonRenderer.point(for: point)
			
			if polygonRenderer.path.contains(polygonViewPoint) {
				return i
			}
		}
		return -1
	}
	
	// HELPER FUNCTIONS
	
	func changeSearchFieldState() {
		let fadeAnimation = CATransition()
		fadeAnimation.duration = 0.25
		fadeAnimation.type = kCATransitionFade
		self.navigationController?.navigationBar.layer.add(fadeAnimation, forKey: "fadeTitleView")
		
		if isSearchFieldHidden {
			isSearchFieldHidden = false
			self.navigationItem.rightBarButtonItem = nil
			self.navigationItem.leftBarButtonItem = nil
			self.searchButton.isHidden = true
//			self.zoomButton.isHidden = true
			self.navigationItem.titleView = self.searchBar
			self.searchBar.becomeFirstResponder()
		} else {
			isSearchFieldHidden = true
			self.navigationItem.rightBarButtonItem = self.rightBarButton
			self.navigationItem.leftBarButtonItem = self.leftBarButton
			self.searchButton.isHidden = false
//			self.zoomButton.isHidden = false
			self.navigationItem.titleView = nil
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
	
	@objc func getDangerLevel() {
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
			
			renderer.fillColor = UIColor(hex: nhoods[ind].color).withAlphaComponent(0.6)
			renderer.strokeColor = UIColor(hex: nhoods[ind].color).withAlphaComponent(0.1)
			renderer.lineWidth = 8.0
			renderer.lineJoin = .round
			renderer.lineCap = .round
			
			polygonCounter += 1
			if polygonCounter == polygons.count {
				KRProgressHUD.dismiss()
			}
			
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
		
		
		if isCustomPin {
			let smallSquare = CGSize(width: 30, height: 30)
			let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
			button.setBackgroundImage(UIImage(named: "robot_avatar"), for: .normal)
			button.addTarget(self, action: #selector(MapViewController.getDangerLevel), for: .touchUpInside)
			pinView?.leftCalloutAccessoryView = button
		}
		
		return pinView
	}
	
	func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
		
		let mapPoint: MKMapPoint = MKMapPointForCoordinate(self.mapView.centerCoordinate)
		var found = isPointInPolygons(point: mapPoint)
		
		if found {
			found = (mapView.region.span.latitudeDelta < (sanFranciscoRegion.span.latitudeDelta + 0.8) || mapView.region.span.longitudeDelta < (sanFranciscoRegion.span.longitudeDelta + 0.8))
		}
		
		if !found {
			mapView.setRegion(sanFranciscoRegion, animated: true)
		}
		
	}
	
}

extension MapViewController: HandleMapSearch {
	func dropPinZoom(placemark: MKPlacemark) {
		self.selectedPin = placemark
		isCustomPin = true
		mapView.removeAnnotations(mapView.annotations)
		
		let annotation = MKPointAnnotation()
		annotation.coordinate = placemark.coordinate
		annotation.title = placemark.name
		
		if let city = placemark.locality,
			let state = placemark.administrativeArea {
			annotation.subtitle = String(format: "%@ %@", city, state)
		}
		mapView.addAnnotation(annotation)
		let span = MKCoordinateSpanMake(0.05, 0.05)
		let region = MKCoordinateRegionMake(placemark.coordinate, span)
		mapView.setRegion(region, animated: true)
	}
}

extension MapViewController: UISearchBarDelegate {
	
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		changeSearchFieldState()
	}
	
}

