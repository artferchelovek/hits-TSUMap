//
//  AStarNode 2.swift
//  TSUMap
//
//  Created by Сергей Лихачев on 17.04.2026.
//

import Foundation

struct AStarNode: Hashable, Equatable, Comparable {
    let point: GridPoint
    let funcH: Double
    let dist: Double
    var funcF: Double

    init(_ points: GridPoint, _ h: Double, _ distance: Double) {
        point = points
        funcH = h
        dist = distance
        funcF = distance + h
    }

    static func < (lhs: AStarNode, rhs: AStarNode) -> Bool {
        if lhs.funcF != rhs.funcF {
            return lhs.funcF < rhs.funcF
        }
        return lhs.funcH < rhs.funcH
    }
}
