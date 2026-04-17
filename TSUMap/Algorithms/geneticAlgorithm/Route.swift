//
//  ga.swift
//  TSUMap
//
//  Created by Екатерина Кондрашова on 16.04.2026.
//
struct Route {
    var cafesToVisit: [Cafe]
    var fitness: Double
}

extension WeekDay {
    init(calendarIndex: Int) {
        switch calendarIndex {
        case 1: self = .Sunday
        case 2: self = .Monday
        case 3: self = .Tuesday
        case 4: self = .Wednesday
        case 5: self = .Thursday
        case 6: self = .Friday
        case 7: self = .Saturday
        default: self = .Monday
        }
    }
}


