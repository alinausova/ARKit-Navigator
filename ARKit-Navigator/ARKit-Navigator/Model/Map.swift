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
    var floorLevel : Float = 100
    let gridSize : Float = 0.05

    var mapGrid = [String : MapElement]()

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
    }

    init() {
        floorElements = []
        wallElements = []
    }

    func addElement(newElement: ARPlaneAnchor) {
        if newElement.alignment == .horizontal {
            floorElements.append(newElement)
            if floorLevel > newElement.center.z {
                changeFloorLevel(newLevel: newElement.center.z)
            }
            addFloorToGrid(newElement: newElement)
        }
        else if newElement.alignment == .vertical {
            wallElements.append(newElement)
        }
    }

    func changeFloorLevel(newLevel: Float) {
        floorLevel = newLevel
        for element in mapGrid.values {
            if element.content == .floor {
                element.changeZ(newZ: newLevel)
            }
        }
    }

    func addFloorToGrid(newElement: ARPlaneAnchor) {
        let newFloorPoints : [MapElement] = []
        for boundaryPoint in newElement.geometry.boundaryVertices {
            let newMapElement = MapElement(x: round((boundaryPoint.x + newElement.transform.columns.3.x) / gridSize) * gridSize,
                                           y: round((boundaryPoint.y + newElement.transform.columns.3.y) / gridSize) * gridSize,
                                           z: round((boundaryPoint.z + newElement.transform.columns.3.z) / gridSize) * gridSize)
            newMapElement.changeContent(content: .floor)
            addMapElementToGrid(newMapElement: newMapElement)
        }
        let centerMapElement = MapElement (x: round((newElement.transform.columns.3.x) / gridSize) * gridSize,
                                           y: round((newElement.transform.columns.3.y) / gridSize) * gridSize,
                                           z: round((newElement.transform.columns.3.z) / gridSize) * gridSize)
        addMapElementToGrid(newMapElement: centerMapElement)


    }

    func addMapElementToGrid(newMapElement: MapElement) {
        let newKey = "\(newMapElement.x):\(newMapElement.y):\(newMapElement.z)"
        if let oldValue = mapGrid[newKey] {
            oldValue.confidence += 1
        } else {
            newMapElement.confidence = 1
            mapGrid[newKey] = newMapElement
        }
    }

    func getFloor() -> [MapElement] {
        var result : [MapElement] = []
        for mapEl in mapGrid.values {
            if mapEl.content == .floor {
                result.append(mapEl)
            }
        }
        return result
    }
}

class MapElement {
    let x : Float
    let y : Float
    var z : Float
    var confidence = 0.0
    var content = MapContent.notDefined


    init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }


    func changeContent(content type: MapContent) {
        self.content = type
    }

    func changeZ (newZ: Float) {
        self.z = newZ
    }
}

enum MapContent{
    case floor
    case wall
    case object
    case notDefined
}
