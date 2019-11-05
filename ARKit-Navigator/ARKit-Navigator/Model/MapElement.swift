//
//  MapElement.swift
//  ARKit-Navigator
//
//  Created by Alina Usova on 04.11.19.
//  Copyright © 2019 alinausova. All rights reserved.
//

import Foundation
import ARKit

class MapElement {
    let x : Float
    let y : Float
    let z : Float
    var confidence = 0.0
    var content = MapContent.notDefined
    var loadedInMap = false
    var isNew = true
    var name: String

    init(x: Float, y: Float, z: Float, content: MapContent, confidence: Double, name: String = "") {
        self.x = x
        self.y = y
        self.z = z
        self.content = content
        self.confidence = confidence
        self.name = name
    }

    var color: UIColor {
        switch self.content {
        case .object: return UIColor(red:0.47, green:0.88, blue:0.56, alpha:1.0)
        case .floor: return UIColor(red:0.96, green:0.73, blue:0.23, alpha:1.0)
        case .plane: return UIColor(red:0.90, green:0.56, blue:0.15, alpha:1.0)
        case .wall: return UIColor(red:0.29, green:0.41, blue:0.74, alpha:1.0)
        case .center: return UIColor(red:0.90, green:0.31, blue:0.22, alpha:1.0)
        default: return .white
        }
    }
}

enum MapContent{
    case floor
    case plane
    case wall
    case object
    case center
    case notDefined
}


