//
//  Date+WeekDay.swift
//  Safety Assistant
//
//  Created by Csongor Barabasi on 03/08/2017.
//  Copyright © 2017 Csongor Barabasi. All rights reserved.
//

import Foundation

extension Date {
	func weekDay() -> String? {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "EEEE"
		return dateFormatter.string(from: self).capitalized
	}
}
