//
//  Neighbourhood.swift
//  Safety Assistant
//
//  Created by Csongor Barabasi on 31/07/2017.
//  Copyright © 2017 Csongor Barabasi. All rights reserved.
//

import Foundation
import SwiftyJSON

struct Neighbourhood {
	
	let name: String
	let color: String
	let totalCrimes: Int
	let polygon: [Float64]
	
	init(name: String, color: String, totalCrimes: Int, polygon: [Float64]) {
		self.name = name
		self.color = color
		self.totalCrimes = totalCrimes
		self.polygon = polygon
	}
	
}
