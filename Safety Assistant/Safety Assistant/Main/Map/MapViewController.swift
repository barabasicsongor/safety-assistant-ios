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

class MapViewController: UIViewController, MKMapViewDelegate {
	
	@IBOutlet weak var mapView: MKMapView!

	var nhoods: [Neighbourhood] = []
	var polygons: [MKPolygon] = []
	var sanFrancisco = CLLocationCoordinate2D(latitude: 37.760545, longitude: -122.443351)
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		KRProgressHUD.show()
		
		self.mapView.isHidden = true
		
		MapService(url: "http://barabasicsongor.com/heatmap.json").makeRequest(completion: { [weak self] result in
			self?.nhoods = result
			self?.loadMap()
		})
		
    }
	
	// MAP FUNCTIONS
	
	func loadMap() {
		self.mapView.delegate = self
		let span = MKCoordinateSpanMake(0.15, 0.15)
		let region = MKCoordinateRegion(center: sanFrancisco, span: span)
		self.mapView.setRegion(region, animated: true)
		
		addPolygons()
		
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
			polygons.append(poly)
			
		}
		
		self.mapView.addOverlays(polygons)
	}
	
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
			renderer.strokeColor = UIColor.black
			renderer.lineWidth = 1
			return renderer
		}
		
		return MKOverlayRenderer()
	}
	
	// ACTIVITY INDICATOR
	func startActivityIndicator() {
		
	}

}
