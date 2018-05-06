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
    let floorLevelMistake : Float = 0.15
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
            if floorLevel > round((newElement.transform.columns.3.y) / gridSize) * gridSize {
                changeFloorLevel(newLevel: round((newElement.transform.columns.3.y) / gridSize) * gridSize)
            }
            addFloorToGrid(newElement: newElement)
        }
        else if newElement.alignment == .vertical {
            wallElements.append(newElement)
            addWallToGrid(newElement: newElement)

        }
    }

    func changeFloorLevel(newLevel: Float) {
        floorLevel = newLevel
        for element in mapGrid.values {
            if element.content == .floor && element.y - newLevel <= floorLevelMistake {
                mapGrid["\(element.x):\(element.y):\(element.z)"] = nil
                element.changeY(newY: newLevel)
                addMapElementToGrid(newMapElement: element)
            }
        }
    }

    func addFloorToGrid(newElement: ARPlaneAnchor) {
        var newFloorPoints : [MapElement] = []
        for boundaryPoint in newElement.geometry.boundaryVertices {
            let newMapElement = MapElement(x: round((boundaryPoint.x + newElement.transform.columns.3.x) / gridSize) * gridSize,
                                           y: round((boundaryPoint.y + newElement.transform.columns.3.y) / gridSize) * gridSize,
                                           z: round((boundaryPoint.z + newElement.transform.columns.3.z) / gridSize) * gridSize)
            newMapElement.changeContent(content: .floor)
            if newMapElement.y - floorLevel <= floorLevelMistake {
                newMapElement.changeY(newY: floorLevel)
            }
            addMapElementToGrid(newMapElement: newMapElement)
        }
        for verticle in newElement.geometry.vertices {
            let newMapElement = MapElement(x: round((verticle.x + newElement.transform.columns.3.x) / gridSize) * gridSize,
                                           y: round((verticle.y + newElement.transform.columns.3.y) / gridSize) * gridSize,
                                           z: round((verticle.z + newElement.transform.columns.3.z) / gridSize) * gridSize)
            newMapElement.changeContent(content: .floor)
            addMapElementToGrid(newMapElement: newMapElement)
            newFloorPoints.append(newMapElement)
        }
        let centerMapElement = MapElement (x: round((newElement.transform.columns.3.x) / gridSize) * gridSize,
                                           y: round((newElement.transform.columns.3.y) / gridSize) * gridSize,
                                           z: round((newElement.transform.columns.3.z) / gridSize) * gridSize)
        centerMapElement.content = .floor
        addMapElementToGrid(newMapElement: centerMapElement)
        newFloorPoints.append(centerMapElement)

        for point1 in newFloorPoints {
            for point2 in newFloorPoints{
                if point1.x == point2.x && point1.z < point2.z {
                    var i = point1.z + gridSize
                    while (i < point2.z) {
                        let newPoint = MapElement(x: point1.x, y: point1.y, z: i)
                        newPoint.content = .floor
                        addMapElementToGrid(newMapElement: newPoint)
                        i += gridSize
                    }
                } else if point1.x < point2.x && point1.z == point2.z {
                    var i = point1.x + gridSize
                    while (i < point2.x) {
                        let newPoint = MapElement(x: i, y: point1.y, z: point1.z)
                        newPoint.content = .floor
                        addMapElementToGrid(newMapElement: newPoint)
                        i += gridSize
                    }
                }
            }
        }
    }

    func addWallToGrid(newElement: ARPlaneAnchor) {
        var newWallPoints : [MapElement] = []
        for boundaryPoint in newElement.geometry.boundaryVertices {
            let newMapElement = MapElement(x: round((boundaryPoint.x + newElement.transform.columns.3.x) / gridSize) * gridSize,
                                           y: floorLevel,
                                           z: round((boundaryPoint.z + newElement.transform.columns.3.z) / gridSize) * gridSize)
            newMapElement.changeContent(content: .wall)
            addMapElementToGrid(newMapElement: newMapElement)
            newWallPoints.append(newMapElement)
        }
        for verticle in newElement.geometry.vertices {
            let newMapElement = MapElement(x: round((verticle.x + newElement.transform.columns.3.x) / gridSize) * gridSize,
                                           y: floorLevel,
                                           z: round((verticle.z + newElement.transform.columns.3.z) / gridSize) * gridSize)
            newMapElement.changeContent(content: .wall)
            addMapElementToGrid(newMapElement: newMapElement)
            newWallPoints.append(newMapElement)
        }
        let centerMapElement = MapElement (x: round((newElement.transform.columns.3.x) / gridSize) * gridSize,
                                           y: floorLevel,
                                           z: round((newElement.transform.columns.3.z) / gridSize) * gridSize)
        centerMapElement.content = .wall
        addMapElementToGrid(newMapElement: centerMapElement)

//        for point1 in newWallPoints {
//            for point2 in newWallPoints{
//                if point1.x == point2.x && point1.z < point2.z {
//                    var i = point1.z + gridSize
//                    while (i < point2.z) {
//                        let newPoint = MapElement(x: point1.x, y: point1.y, z: i)
//                        newPoint.content = .wall
//                        addMapElementToGrid(newMapElement: newPoint)
//                        i += gridSize
//                    }
//                } else if point1.x < point2.x && point1.z == point2.z {
//                    var i = point1.x + gridSize
//                    while (i < point2.x) {
//                        let newPoint = MapElement(x: i, y: point1.y, z: point1.z)
//                        newPoint.content = .wall
//                        addMapElementToGrid(newMapElement: newPoint)
//                        i += gridSize
//                    }
//                }
//            }
//        }
    }

    func createKey (mapElement: MapElement) -> String {
        return "\(mapElement.x):\(mapElement.y):\(mapElement.z)"
    }

    func createCenterKey (mapElement: MapElement) -> String {
        return "\(mapElement.x + gridSize):\(mapElement.y):\(mapElement.z + gridSize)"
    }

    func createNeighborKeys (mapElement: MapElement) -> [String] {
        var newKeys : [String] = []
        newKeys.append("\(mapElement.x + gridSize):\(mapElement.y):\(mapElement.z)")
        newKeys.append("\(mapElement.x + gridSize):\(mapElement.y):\(mapElement.z + gridSize)")
        newKeys.append("\(mapElement.x + gridSize):\(mapElement.y):\(mapElement.z - gridSize)")
        newKeys.append("\(mapElement.x):\(mapElement.y):\(mapElement.z + gridSize)")
        newKeys.append("\(mapElement.x):\(mapElement.y):\(mapElement.z - gridSize)")
        newKeys.append("\(mapElement.x - gridSize):\(mapElement.y):\(mapElement.z)")
        newKeys.append("\(mapElement.x - gridSize):\(mapElement.y):\(mapElement.z + gridSize)")
        newKeys.append("\(mapElement.x - gridSize):\(mapElement.y):\(mapElement.z - gridSize)")
        return newKeys

    }


    func addMapElementToGrid(newMapElement: MapElement) {
        let newKey = createKey(mapElement: newMapElement)
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

    func getWall() -> [MapElement] {
        var result : [MapElement] = []
        for mapEl in mapGrid.values {
            if mapEl.content == .wall {
                result.append(mapEl)
            }
        }
        return result
    }

    func getDistance(a: MapElement, b: MapElement) -> Float {
        var distance : Float
        distance = sqrt(pow((a.x - b.x),2) + pow((a.y - b.y),2) + pow((a.z - b.z),2))
        return distance
    }

    func fillFloor() {
        var loopCNT : Int = 0
        repeat {

            for element in mapGrid.values {
                let centersKeys : [String] = createNeighborKeys(mapElement: element)
                for centerKey in centersKeys {
                    if mapGrid[centerKey] == nil {
                        let newMapElement = MapElement(x: element.x + gridSize,
                                                       y: element.y,
                                                       z: element.z + gridSize)
                        let filledNeighbours = countFilledNeighbours(center: newMapElement)
                        if filledNeighbours > 3 {
                            newMapElement.content = .floor
                            addMapElementToGrid(newMapElement: newMapElement)

                        }
                    }
                }
            }
            loopCNT += 1
        } while loopCNT < 5
    }

    func countFilledNeighbours(center: MapElement) -> Int {
        var cnt = 0
        let keys = createNeighborKeys(mapElement: center)
        for key in keys {
            if let oldPoint = mapGrid[key],
                oldPoint.content == .floor {
                cnt += 1
            }
        }
        return cnt
    }
}

class MapElement {
    let x : Float
    var y : Float
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

    func changeY (newY: Float) {
        self.y = newY
    }
}

enum MapContent{
    case floor
    case wall
    case object
    case notDefined
}
