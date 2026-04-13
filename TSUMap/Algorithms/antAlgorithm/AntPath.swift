//
//  AntPath.swift
//  TSUMap
//
//  Created by Сергей Лихачев on 09.04.2026.
//
import Foundation

struct AntPath {
    var places: [Int]
    var dist: Int
    
    init(dist: Int = 0) {
        places = []
        self.dist = dist
    }
}
