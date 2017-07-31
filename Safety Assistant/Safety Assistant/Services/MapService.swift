//
//  MapService.swift
//  Safety Assistant
//
//  Created by Csongor Barabasi on 31/07/2017.
//  Copyright © 2017 Csongor Barabasi. All rights reserved.
//

import Foundation
import Alamofire

struct MapService {
	
	let url: String
	
	init(url: String) {
		self.url = url
	}
	
	func makeRequest(completion: @escaping ((_ result: [Neighbourhood]) -> Void)) {
		
		Alamofire.request(self.url).responseJSON(completionHandler: { response in
			
			if let json = response.result.value {
				JSONParser().parseJSON(json as AnyObject, completion: {
					res in completion(res)
				})
			}
			
		})
		
	}
	
}
