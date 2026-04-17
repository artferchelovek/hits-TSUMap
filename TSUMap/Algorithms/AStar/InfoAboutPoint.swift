//
//  InfoAboutPoint.swift
//  TSUMap
//
//  Created by Сергей Лихачев on 16.04.2026.
//

struct InfoAboutPoint {
    var point: GridPoint
    var openPoints: [GridPoint]
    var pathToPoint: Set<GridPoint>
    var isEnd: Bool
    var path: [GridPoint]
}
