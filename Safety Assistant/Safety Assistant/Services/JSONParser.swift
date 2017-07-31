//
//  JSONParser.swift
//  Safety Assistant
//
//  Created by Csongor Barabasi on 31/07/2017.
//  Copyright © 2017 Csongor Barabasi. All rights reserved.
//

import Foundation
import SwiftyJSON

struct JSONParser {
	
	func parseJSON(_ json: AnyObject, completion: ((_ result: [Neighbourhood]) -> Void)) {
		let js = JSON(json)
		let js_arr = js["items"].array
		var result: [Neighbourhood] = []
		
		for item in js_arr! {
			let name = item["hood_name"].stringValue
			let color = item["color"].stringValue
			let totalCrimes = item["total_crimes"].intValue
			let polygon = item["polygon"].arrayObject as! [Float64]
			
			let nh = Neighbourhood(name: name, color: color, totalCrimes: totalCrimes, polygon: polygon)
			result.append(nh)
		}
		
		completion(result)
	}
	
}
