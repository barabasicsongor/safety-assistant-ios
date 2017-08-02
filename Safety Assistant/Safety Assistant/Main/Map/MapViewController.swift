//
//  MapViewController.swift
//  Safety Assistant
//
//  Created by Csongor Barabasi on 31/07/2017.
//  Copyright © 2017 Csongor Barabasi. All rights reserved.
//

import UIKit
import MapKit
import KRProgressHUD

class MapViewController: UIViewController {
	
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var textField: UITextField!
	@IBOutlet weak var tableView: UITableView!
	
	var nhoods: [Neighbourhood] = []
	var polygons: [MKPolygon] = []
	var sanFrancisco = CLLocationCoordinate2D(latitude: 37.760545, longitude: -122.443351)
	
	var searchCompleter = MKLocalSearchCompleter()
	var searchResults = [MKLocalSearchCompletion]()
	var isTextFieldHidden = true
	var isTableViewHidden = true
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		KRProgressHUD.show()
		
		self.searchCompleter.delegate = self
		
		self.tableView.delegate = self
		self.tableView.dataSource = self
		
		self.mapView.isHidden = true
		
		textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
		
		MapService(url: "http://barabasicsongor.com/heatmap.json").makeRequest(completion: { [weak self] result in
			self?.nhoods = result
			self?.loadMap()
		})
		
    }
	
	// ACTIONS
	
	@IBAction func chatButtonPress(_ sender: Any) {
		let chatViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
		
		self.navigationController?.pushViewController(chatViewController, animated: true)
	}
	
	func textFieldDidChange(_ textField: UITextField) {
		
		if textField.text?.characters.count == 0 {
			
			if isTableViewHidden == false {
				showTableView()
			}
			
			self.searchCompleter.queryFragment = ""
			self.searchResults = []
			self.tableView.reloadData()
		} else {
			if isTableViewHidden {
				showTableView()
			}
			
			self.searchCompleter.queryFragment = self.textField.text!
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
			UIView.animate(withDuration: 0.25, animations: { [weak self] in
				self?.textField.alpha = 0.0
			})
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
	
}

extension MapViewController: MKLocalSearchCompleterDelegate {
	
	func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
		searchResults = completer.results
		
		self.tableView.reloadData()
	}
	
	func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
		// Error
	}
}

extension MapViewController: UITableViewDelegate, UITableViewDataSource {
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.searchResults.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		
		cell.textLabel?.text = searchResults[indexPath.row].title + "," + searchResults[indexPath.row].subtitle
		cell.textLabel?.font = UIFont(name: (cell.textLabel?.font.fontName)!, size: 12.0)
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
	}
	
}
