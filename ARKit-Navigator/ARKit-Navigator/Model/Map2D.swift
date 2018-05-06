//
//  Map2D.swift
//  ARKit-Navigator
//
//  Created by Alina Usova on 03/05/2018.
//  Copyright © 2018 alinausova. All rights reserved.
//

import Foundation
import ARKit

class Map2D {

    var floorElements : [ARPlaneAnchor]
    var wallElements : [ARPlaneAnchor]
    var floorLevel : Float = 100
    let floorLevelMistake : Float = 0.15
    let gridSize : Float = 0.05

    var mapGrid = [String : MapElement2d]()

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
            addFloorToGrid(newElement: newElement)
        }
        else if newElement.alignment == .vertical {
            wallElements.append(newElement)
            addWallToGrid(newElement: newElement)

        }
    }

    func addFloorToGrid(newElement: ARPlaneAnchor) {
        var newFloorPoints : [MapElement2d] = []
        for boundaryPoint in newElement.geometry.boundaryVertices {
            let newMapElement = MapElement2d(x: round((boundaryPoint.x + newElement.transform.columns.3.x) / gridSize) * gridSize,
                                           z: round((boundaryPoint.z + newElement.transform.columns.3.z) / gridSize) * gridSize)
            newMapElement.changeContent(content: .floor)
            addMapElement2dToGrid(newMapElement: newMapElement)
        }
        for verticle in newElement.geometry.vertices {
            let newMapElement = MapElement2d(x: round((verticle.x + newElement.transform.columns.3.x) / gridSize) * gridSize,
                                           z: round((verticle.z + newElement.transform.columns.3.z) / gridSize) * gridSize)
            newMapElement.changeContent(content: .floor)
            addMapElement2dToGrid(newMapElement: newMapElement)
            newFloorPoints.append(newMapElement)
        }
        let centerMapElement2d = MapElement2d (x: round((newElement.transform.columns.3.x) / gridSize) * gridSize,
                                           z: round((newElement.transform.columns.3.z) / gridSize) * gridSize)
        centerMapElement2d.content = .floor
        addMapElement2dToGrid(newMapElement: centerMapElement2d)
        newFloorPoints.append(centerMapElement2d)

        for point1 in newFloorPoints {
            for point2 in newFloorPoints{
                if point1.x == point2.x && point1.z < point2.z {
                    var i = point1.z + gridSize
                    while (i < point2.z) {
                        let newPoint = MapElement2d(x: point1.x, z: i)
                        newPoint.content = .floor
                        addMapElement2dToGrid(newMapElement: newPoint)
                        i += gridSize
                    }
                } else if point1.x < point2.x && point1.z == point2.z {
                    var i = point1.x + gridSize
                    while (i < point2.x) {
                        let newPoint = MapElement2d(x: i, z: point1.z)
                        newPoint.content = .floor
                        addMapElement2dToGrid(newMapElement: newPoint)
                        i += gridSize
                    }
                }
            }
        }
    }

    func addWallToGrid(newElement: ARPlaneAnchor) {
        var newWallPoints : [MapElement2d] = []
        for boundaryPoint in newElement.geometry.boundaryVertices {
            let newMapElement = MapElement2d(x: round((boundaryPoint.x + newElement.transform.columns.3.x) / gridSize) * gridSize,
                                           z: round((boundaryPoint.z + newElement.transform.columns.3.z) / gridSize) * gridSize)
            newMapElement.changeContent(content: .wall)
            addMapElement2dToGrid(newMapElement: newMapElement)
            newWallPoints.append(newMapElement)
        }
        for verticle in newElement.geometry.vertices {
            let newMapElement = MapElement2d(x: round((verticle.x + newElement.transform.columns.3.x) / gridSize) * gridSize,
                                           z: round((verticle.z + newElement.transform.columns.3.z) / gridSize) * gridSize)
            newMapElement.changeContent(content: .wall)
            addMapElement2dToGrid(newMapElement: newMapElement)
            newWallPoints.append(newMapElement)
        }
        let centerMapElement2d = MapElement2d (x: round((newElement.transform.columns.3.x) / gridSize) * gridSize,
                                           z: round((newElement.transform.columns.3.z) / gridSize) * gridSize)
        centerMapElement2d.content = .wall
        addMapElement2dToGrid(newMapElement: centerMapElement2d)
    }

    func createKey (MapElement2d: MapElement2d) -> String {
        return "\(MapElement2d.x):\(MapElement2d.z)"
    }

    func createCenterKey (MapElement2d: MapElement2d) -> String {
        return "\(MapElement2d.x + gridSize):\(MapElement2d.z + gridSize)"
    }

    func createNeighborKeys (MapElement2d: MapElement2d) -> [String] {
        var newKeys : [String] = []
        newKeys.append("\(MapElement2d.x + gridSize):\(MapElement2d.z)")
        newKeys.append("\(MapElement2d.x + gridSize):\(MapElement2d.z + gridSize)")
        newKeys.append("\(MapElement2d.x + gridSize):\(MapElement2d.z - gridSize)")
        newKeys.append("\(MapElement2d.x):\(MapElement2d.z + gridSize)")
        newKeys.append("\(MapElement2d.x):\(MapElement2d.z - gridSize)")
        newKeys.append("\(MapElement2d.x - gridSize):\(MapElement2d.z)")
        newKeys.append("\(MapElement2d.x - gridSize):\(MapElement2d.z + gridSize)")
        newKeys.append("\(MapElement2d.x - gridSize):\(MapElement2d.z - gridSize)")
        return newKeys
    }


    func addMapElement2dToGrid(newMapElement: MapElement2d) {
        let newKey = createKey(MapElement2d: newMapElement)
        if let oldValue = mapGrid[newKey] {
            if newMapElement.content == .wall && oldValue.content == .floor {
                oldValue.content = .floor
            }
            oldValue.confidence += 1
        } else {
            newMapElement.confidence = 1
            mapGrid[newKey] = newMapElement
        }
    }

    func getFloor() -> [MapElement2d] {
        var result : [MapElement2d] = []
        for mapEl in mapGrid.values {
            if mapEl.content == .floor {
                result.append(mapEl)
            }
        }
        return result
    }

    func getWall() -> [MapElement2d] {
        var result : [MapElement2d] = []
        for mapEl in mapGrid.values {
            if mapEl.content == .wall {
                result.append(mapEl)
            }
        }
        return result
    }

    func getObjects() -> [MapElement2d] {
        var result : [MapElement2d] = []
        for mapEl in mapGrid.values {
            if mapEl.content == .object {
                result.append(mapEl)
            }
        }
        return result
    }

    func getDistance(a: MapElement2d, b: MapElement2d) -> Float {
        var distance : Float
        distance = sqrt(pow((a.x - b.x),2) + pow((a.z - b.z),2))
        return distance
    }

    func fillFloor() {
        var loopCNT : Int = 0
        repeat {

            for element in mapGrid.values {
                let centersKeys : [String] = createNeighborKeys(MapElement2d: element)
                for centerKey in centersKeys {
                    if mapGrid[centerKey] == nil {
                        let newMapElement = MapElement2d(x: element.x + gridSize,
                                                       z: element.z + gridSize)
                        let filledNeighbours = countFilledNeighbours(center: newMapElement)
                        if filledNeighbours > 3 {
                            newMapElement.content = .floor
                            addMapElement2dToGrid(newMapElement: newMapElement)
                        }
                    }
                }
            }
            loopCNT += 1
        } while loopCNT < 5
    }

    func countFilledNeighbours(center: MapElement2d) -> Int {
        var cnt = 0
        let keys = createNeighborKeys(MapElement2d: center)
        for key in keys {
            if let oldPoint = mapGrid[key],
                oldPoint.content == .floor {
                cnt += 1
            }
        }
        return cnt
    }
}

class MapElement2d {
    let x : Float
    var z : Float
    var confidence = 0.0
    var content = MapContent.notDefined


    init(x: Float, z: Float) {
        self.x = x
        self.z = z
    }


    func changeContent(content type: MapContent) {
        self.content = type
    }
}

