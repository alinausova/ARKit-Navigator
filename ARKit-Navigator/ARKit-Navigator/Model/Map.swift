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
        let coorCenter = MapElement(x: 0, y: 0, z: 0, content: .center, confidence: 2000)
        addMapElementToGrid(newMapElement: coorCenter)
        let coorCenterX = MapElement(x: gridSize, y: 0,  z: 0, content: .center, confidence: 2000)
        let coorCenterZ = MapElement(x: 0, y: 0, z: gridSize, content: .center, confidence: 2000)
        let coorCenterZ2 = MapElement(x: 0, y: 0, z: gridSize + gridSize, content: .center, confidence: 2000)
        addMapElementToGrid(newMapElement: coorCenterX)
        addMapElementToGrid(newMapElement: coorCenterZ)
        addMapElementToGrid(newMapElement: coorCenterZ2)

    }

//    func addElement(newElement: ARPlaneAnchor) {
//        if newElement.alignment == .horizontal {
//            floorElements.append(newElement)
//            if floorLevel > round((newElement.transform.columns.3.y) / gridSize) * gridSize {
//                changeFloorLevel(newLevel: round((newElement.transform.columns.3.y) / gridSize) * gridSize)
//            }
//            addFloorToGrid(newElement: newElement)
//        }
//        else if newElement.alignment == .vertical {
//            wallElements.append(newElement)
//            addWallToGrid(newElement: newElement)
//
//        }
//    }

    func addElement(newElement: ARPlaneAnchor) {
        if newElement.alignment == .horizontal {
            floorElements.append(newElement)
            addFloorToGrid(newElement: newElement)
        }
        else if newElement.alignment == .vertical {
            wallElements.append(newElement)
            addWallToGrid(newElement: newElement)

        }
//        print ("\(String(describing: newElement.transform))")
//        print ("\(String(describing: newElement.alignment))")
//        print ("\(String(describing: newElement.geometry.triangleIndices.debugDescription))")

    }

    func addElement(newElement: ARAnchor) {
        addObjectToGrid(newElement: newElement)

    }

    func addElement(newElement: SCNNode) {
//        print ("\(String(describing: newElement.transform))")
//        print ("\(String(describing: newElement.rotation))")
//        print ("\(String(describing: newElement.orientation))")
//         print ("\(String(describing: newElement.eulerAngles))")
    }
    
//    func changeFloorLevel(newLevel: Float) {
//        floorLevel = newLevel
//        for element in mapGrid.values {
//            if element.content == .floor && element.y - newLevel <= floorLevelMistake {
//                mapGrid["\(element.x):\(element.y):\(element.z)"] = nil
//                element.changeY(newY: newLevel)
//                addMapElementToGrid(newMapElement: element)
//            }
//        }
//    }

    func addFloorToGrid(newElement: ARPlaneAnchor) {
        var newFloorPoints : [MapElement] = []
            for element in transform(planeAnchor: newElement) {
                let newMapElement = MapElement (x: round(element.x / gridSize) * gridSize,
                                                y: round(element.y / gridSize) * gridSize,
                                                z: round(element.z / gridSize) * gridSize,
                                                content: .floor,
                                                confidence: 1)
                newFloorPoints.append(newMapElement)
                if newMapElement.y - floorLevel <= floorLevelMistake {
                    newMapElement.changeY(newY: floorLevel)
                }
                newFloorPoints.append(newMapElement)
                addMapElementToGrid(newMapElement: newMapElement)
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
        for element in transform(planeAnchor: newElement) {
            let newMapElement = MapElement (x: round(element.x / gridSize) * gridSize,
                                            y: round(element.y / gridSize) * gridSize,
                                            z: round(element.z / gridSize) * gridSize,
                                            content: .wall,
                                            confidence: 50)
            addMapElementToGrid(newMapElement: newMapElement)
            newWallPoints.append(newMapElement)
        }
        let centerMapElement = MapElement (x: round((newElement.transform.columns.3.x + newElement.center.x) / gridSize) * gridSize,
                                           y: round((newElement.transform.columns.3.y + newElement.center.y) / gridSize) * gridSize,
                                           z: round((newElement.transform.columns.3.z + newElement.center.z) / gridSize) * gridSize,
                                           content: .wall)
        addMapElementToGrid(newMapElement: centerMapElement)
        newWallPoints.append(centerMapElement)

//        repeat {
//            let newPointToAdd = MapElement (x: round((point.x + centerMapElement.x) / 2 / gridSize) * gridSize,
//                                       y: round((point.y + centerMapElement.y) / 2 / gridSize) * gridSize,
//                                       z: round((point.z + centerMapElement.z) / 2 / gridSize) * gridSize,
//                                       content: .wall)
//            addMapElementToGrid(newMapElement: newPointToAdd)
//            point = MapElement (x: (point.x + centerMapElement.x) / 2,
//                                y: (point.y + centerMapElement.y) / 2,
//                                z: (point.z + centerMapElement.z) / 2,
//                                content: .wall)
//        } while getDistance(a: point, b: centerMapElement) > gridSize * 2

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


    func addObjectToGrid(newElement: ARAnchor) {
        let newMapElement = MapElement(x: round((newElement.transform.columns.3.x) / gridSize) * gridSize,
                                         y: round((newElement.transform.columns.3.y) / gridSize) * gridSize,
                                         z: round((newElement.transform.columns.3.z) / gridSize) * gridSize,
                                         content: .object,
                                         confidence: 1000)
        addMapElementToGrid(newMapElement: newMapElement)
    }

    func addMapElementToGrid(newMapElement: MapElement) {
        if floorLevel == 100 {floorLevel = newMapElement.y}
        let newKey = createKey(mapElement: newMapElement)
        if let old = mapGrid[newKey]{
            if old.content == newMapElement.content {
                old.confidence += 1
            } else if old.confidence < newMapElement.confidence {
                old.changeContent(content: newMapElement.content)
                old.confidence = newMapElement.confidence
            }
        } else {
            mapGrid[newKey] = newMapElement
        }
    }

    func transform(planeAnchor: ARPlaneAnchor) -> [simd_float3] {
        var result: [simd_float3] = []
        let aVector = getCosSinVectors(planeAnchor: planeAnchor)
        let center = simd_float3(x: planeAnchor.transform.columns.3.x + planeAnchor.center.x,
                                 y: planeAnchor.transform.columns.3.y + planeAnchor.center.y,
                                 z: planeAnchor.transform.columns.3.z + planeAnchor.center.z)

        if planeAnchor.alignment == .vertical {
            for point in planeAnchor.geometry.boundaryVertices {
                let y2 = point.y * 0 - point.z * 1
                let z1 = point.y * 1 + point.z * 0
                let x2 = point.x * aVector[0].y - z1 * aVector[1].y
                let z2 = point.x * aVector[1].y + z1 * aVector[0].y
                result.append(simd_float3(x: x2 + center.x, y: y2 + center.y, z: z2 + center.z))
            }
        } else {
            for point in planeAnchor.geometry.boundaryVertices {
                let x2 = point.x * aVector[0].y - point.z * aVector[1].y
                let z2 = point.x * aVector[1].y + point.z * aVector[0].y
                let y2 = point.y
                result.append(simd_float3(x: x2 + center.x, y: y2 + center.y, z: z2 + center.z))
            }
        }
        return result
    }

    func getCos(from: Float) -> Float {
        return cos( (from) * .pi / 180)
    }

    func getSin(from: Float) -> Float {
        return sin( (from) * .pi / 180)
    }

    func getCosSinVectors(planeAnchor: ARPlaneAnchor) -> [simd_float3] {
        let string = planeAnchor.description
        let end = string.components(separatedBy: CharacterSet(charactersIn : "()"))[3].components(separatedBy: "°")

        print ("\(end)")
        let x = Float(end[0].trimmingCharacters(in: CharacterSet(charactersIn: " ")))!
        let y = Float(end[1].trimmingCharacters(in: CharacterSet(charactersIn: " ")))!
        let z = Float(end[2].trimmingCharacters(in: CharacterSet(charactersIn: " ")))!

        return [simd_float3(x: getCos(from: -x), y: getCos(from:  -y - z), z: getCos(from:  -z)),
                simd_float3(x: getSin(from:  -x), y: getSin(from:  -y - z), z: getSin(from:  -z))]
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

    func getMap() -> [MapElement] {
        var result : [MapElement] = []
        for mapEl in mapGrid.values {
            result.append(mapEl)
        }
        return result
    }

    func getObjects() -> [MapElement] {
        var result : [MapElement] = []
        for mapEl in mapGrid.values {
            if mapEl.content == .object {
                result.append(mapEl)
            }
        }
        return result
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

    init(x: Float, y: Float, z: Float, content: MapContent) {
        self.x = x
        self.y = y
        self.z = z
        self.content = content
    }

    init(x: Float, y: Float, z: Float, content: MapContent, confidence: Double) {
        self.x = x
        self.y = y
        self.z = z
        self.content = content
        self.confidence = confidence
    }

    func changeContent(content type: MapContent) {
        self.content = type
    }

    func getElementColor() -> UIColor {
        let color : UIColor
        switch self.content {
        case .object: color = .cyan
        case .floor: color = .blue
        case .wall: color = .red
        case .center: color = .purple
        default: color = .white
        }
        return color
    }

    func changeY (newY: Float) {
        self.y = newY
    }
}

enum MapContent{
    case floor
    case wall
    case object
    case center
    case notDefined
}
