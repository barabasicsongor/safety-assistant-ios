//
//  APIService.swift
//  Safety Assistant
//
//  Created by Csongor Barabasi on 03/08/2017.
//  Copyright © 2017 Csongor Barabasi. All rights reserved.
//

import Foundation
import Alamofire

struct APIService {
	
	func getDangerLevel(place: String, completion: @escaping ((_ response: String) -> Void)) {
		let weekday = Date().weekDay()!
		
		
		let headers = ["Content-Type": "application/json"]
		let parameters = ["place": place, "day": weekday]
		let url = "http://safetyassistant.us-east-1.elasticbeanstalk.com/api"
		Alamofire.request(url, method:.post, parameters:parameters,encoding: JSONEncoding.default, headers:headers).responseJSON { response in
			switch response.result {
			case .success:
				if let result = response.result.value {
					let JSON = result as! Dictionary<String, Float>
					print(JSON)
					let value = JSON["results"]
					completion(self.getStringFromResult(result: value!))
				}
			case .failure(let error):
				print("Error \(error)")
				completion("Sorry. Something went wrong.")
			}
		}
	}
	
	func getStringFromResult(result: Float) -> String {
		var result_str = ""
		
		if result == -1 {
			result_str = "I could not find any relevant data about the location."
		} else if result >= 0 && result < 0.15 {
			result_str = "It is safe."
		} else if result >= 0.15 && result < 0.4 {
			result_str = "It is relatively OK, but be careful!"
		} else {
			result_str = "It is NOT safe!"
		}
		
		return result_str
	}
	
}
