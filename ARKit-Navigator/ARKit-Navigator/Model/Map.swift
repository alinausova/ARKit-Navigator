//
//  Map.swift
//  ARKit-Navigator
//
//  Created by Alina Usova on 01/05/2018.
//  Copyright © 2018 alinausova. All rights reserved.
//

import Foundation
import ARKit

class Map {

    var floorElements : [ARPlaneAnchor]
    var wallElements : [ARPlaneAnchor]

    var mapGrid : [MapElement]

    init(anchors: [ARAnchor]) {
        floorElements = []
        wallElements = []
        for anchor in anchors {
            if let plane = anchor as? ARPlaneAnchor {
                if plane.alignment == .horizontal {
                    floorElements.append(plane)
                }
                else if plane.alignment == .vertical {
                    wallElements.append(plane)
                }
            }
        }
        mapGrid = []
    }

    init() {
        floorElements = []
        wallElements = []
        mapGrid = []
    }

}

struct MapElement {
    let x : Int
    let y : Int
    let z : Int
    var confidence = 0.0
    var content = MapContent.notDefined


    init(x: Int, y: Int, z: Int) {
        self.x = x
        self.y = y
        self.z = z
    }

    mutating func changeContent(content type: MapContent) {
        self.content = type
    }
}

enum MapContent{
    case floor
    case wall
    case object
    case notDefined
}
