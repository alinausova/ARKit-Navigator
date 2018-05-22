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

    var floorLevel : Float = 100
    let floorLevelMistake : Float = 0.5
    let confidenceThreshold = 1.0
    let gridSize : Float = 0.05

    var mapGrid = [String : MapElement]()

    init() {
        // create elements for the absolute center
        let coorCenter = MapElement(x: 0, y: 0, z: 0, content: .center, confidence: 2000)
        let coorCenterX = MapElement(x: gridSize, y: 0,  z: 0, content: .center, confidence: 2000)
        let coorCenterZ = MapElement(x: 0, y: 0, z: gridSize, content: .center, confidence: 2000)
        let coorCenterZ2 = MapElement(x: 0, y: 0, z: gridSize + gridSize, content: .center, confidence: 2000)
        addMapElementToGrid(newMapElement: coorCenter)
        addMapElementToGrid(newMapElement: coorCenterX)
        addMapElementToGrid(newMapElement: coorCenterZ)
        addMapElementToGrid(newMapElement: coorCenterZ2)
    }

    func setFloor(floorLevel: Float) {
        self.floorLevel = round(floorLevel / gridSize) * gridSize
    }

    func isFloor(planeLevel: Float) -> Bool {
        if planeLevel - floorLevel < floorLevelMistake {
            return true
        } else {
            return false
        }
    }

    func addElement(newElement: ARPlaneAnchor) {
        if newElement.alignment == .horizontal {
            addHorisontalPlane(newElement: newElement)
        }
        else if newElement.alignment == .vertical {
            addVerticalPlane(newElement: newElement)
        }
    }

    func addElement(newElement: ARAnchor) {
        addObjectToGrid(newElement: newElement)
    }

    func addHorisontalPlane(newElement: ARPlaneAnchor) {
        if isFloor(planeLevel: newElement.transform.columns.3.y) {
        for element in translatePlane(planeAnchor: newElement) {
                let newMapElement = MapElement (x: round(element.x / gridSize) * gridSize,
                                                y: floorLevel, //round(element.y / gridSize) * gridSize,
                                                z: round(element.z / gridSize) * gridSize,
                                                content: .floor,
                                                confidence: 1)
                addMapElementToGrid(newMapElement: newMapElement)
            }
        } else {
            for element in translatePlane(planeAnchor: newElement) {
                let newMapElement = MapElement (x: round(element.x / gridSize) * gridSize,
                                                y: round(element.y / gridSize) * gridSize,
                                                z: round(element.z / gridSize) * gridSize,
                                                content: .plane,
                                                confidence: 1)
                addMapElementToGrid(newMapElement: newMapElement)
            }
        }
//        for point1 in newFloorPoints {
//            for point2 in newFloorPoints{
//                if point1.x == point2.x && point1.z < point2.z {
//                    var i = point1.z + gridSize
//                    while (i < point2.z) {
//                        let newPoint = MapElement(x: point1.x, y: point1.y, z: i)
//                        newPoint.content = .floor
//                        addMapElementToGrid(newMapElement: newPoint)
//                        i += gridSize
//                    }
//                } else if point1.x < point2.x && point1.z == point2.z {
//                    var i = point1.x + gridSize
//                    while (i < point2.x) {
//                        let newPoint = MapElement(x: i, y: point1.y, z: point1.z)
//                        newPoint.content = .floor
//                        addMapElementToGrid(newMapElement: newPoint)
//                        i += gridSize
//                    }
//                }
//            }
//        }
    }

    func addVerticalPlane(newElement: ARPlaneAnchor) {
        var newWallPoints : [MapElement] = []
        for element in translatePlane(planeAnchor: newElement) {
            let newMapElement = MapElement (x: round(element.x / gridSize) * gridSize,
                                            y: floorLevel, //round(element.y / gridSize) * gridSize,
                                            z: round(element.z / gridSize) * gridSize,
                                            content: .wall,
                                            confidence: 1)
            addMapElementToGrid(newMapElement: newMapElement)
            newWallPoints.append(newMapElement)
        }
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
        let newKey = createKey(mapElement: newMapElement)
        if let old = mapGrid[newKey]{
            if old.content == newMapElement.content {
                old.confidence += 1
            } else if old.confidence < newMapElement.confidence {
                mapGrid[newKey] = newMapElement
            }
        } else {
            mapGrid[newKey] = newMapElement
        }
    }

    func isPointInPolygon(boundaries: [vector_float3], point: vector_float3) -> Bool {
        var result = false
        for i in 1...boundaries.count-1 {
            let p1 = boundaries[i-1]
            let p2 = boundaries[i]
            if ((((p1.z <= point.z) && ( point.z < p2.z )) || ((p2.z <= point.z) && ( point.z < p1.z ))) && ( point.x > (p2.x - p1.x) * (point.z - p1.z) / (p2.z - p1.z) + p1.x)) {
                result = !result
            }
        }
        return result
    }

    func makeXRotationMatrix(angle: Float) -> simd_float3x3 {
        let rows = [
            simd_float3( 1,     0,              0),
            simd_float3( 0,     cos(angle),     sin(angle)),
            simd_float3( 0,     -sin(angle),    cos(angle)),
        ]

        return float3x3(rows: rows)
    }

    func makeYRotationMatrix(angle: Float) -> simd_float3x3 {
        let rows = [
            simd_float3( cos(angle),  0,    sin(angle)),
            simd_float3( 0,           1,    0),
            simd_float3( -sin(angle), 0,    cos(angle)),
        ]

        return float3x3(rows: rows)
    }

//  doesnt work
//    func getPlaneRoll(transform: SCNMatrix4) -> Float{
//         let yaw: Float
//         if (transform.m11 == 1.0)
//         {
//             yaw = atan2f(transform.m13, transform.m34);
//         } else if (transform.m11 == -1.0) {
//             yaw = atan2f(transform.m13, transform.m34);
//         } else {
//             yaw = atan2(-transform.m31, transform.m11);
//         }
//        return yaw
//    }

    func translatePlane(planeAnchor: ARPlaneAnchor) -> [simd_float3] {
        var result: [simd_float3] = []

        let string = planeAnchor.description
        let end = string.components(separatedBy: CharacterSet(charactersIn : "()"))[3].components(separatedBy: "°")

        let y = Float(end[1].trimmingCharacters(in: CharacterSet(charactersIn: " ")))!

        let center = simd_float3(x: planeAnchor.transform.columns.3.x, //+ planeAnchor.center.x,
                                 y: planeAnchor.transform.columns.3.y, //+ planeAnchor.center.y,
                                 z: planeAnchor.transform.columns.3.z) //+ planeAnchor.center.z)

        let xRotationMatrix = makeXRotationMatrix(angle: GLKMathDegreesToRadians(90))
        let yRotationMatrix = makeYRotationMatrix(angle: GLKMathDegreesToRadians(-y))

        //create a plane of extent size
        var plane : [vector_float3] = []

        let w: Int = Int(round (planeAnchor.extent.x / 2 / gridSize))
        let h: Int = Int(round (planeAnchor.extent.z / 2 / gridSize))

        for i in -w...w {
            for j in -h...h {
                let point = vector_float3(gridSize * Float(i),
                                          0,
                                          gridSize * Float(j))
                if isPointInPolygon(boundaries: planeAnchor.geometry.boundaryVertices, point: point) {
                    plane.append(point)
                }
            }
        }

        // transform plane
        for point in plane {
            // rotation with fixed x
            var transformedPoint = point
            if planeAnchor.alignment == .vertical {
                transformedPoint = transformedPoint * xRotationMatrix
            }
            //rotation with fixed y
            transformedPoint = transformedPoint * yRotationMatrix
            //translation
            transformedPoint = simd_float3(transformedPoint.x  + center.x,
                                           transformedPoint.y  + center.y,
                                           transformedPoint.z + center.z)
            result.append(transformedPoint)
        }
        return result
    }

    //another transform method

//    func getCos(from: Float) -> Float {
//        return cos( (from) * .pi / 180)
//    }
//
//    func getSin(from: Float) -> Float {
//        return sin( (from) * .pi / 180)
//    }
//
//    func getCosSinVectors(planeAnchor: ARPlaneAnchor) -> [simd_float3] {
//        let string = planeAnchor.description
//        let end = string.components(separatedBy: CharacterSet(charactersIn : "()"))[3].components(separatedBy: "°")
//
//        print ("\(end)")
//        let x = Float(end[0].trimmingCharacters(in: CharacterSet(charactersIn: " ")))!
//        let y = Float(end[1].trimmingCharacters(in: CharacterSet(charactersIn: " ")))!
//        let z = Float(end[2].trimmingCharacters(in: CharacterSet(charactersIn: " ")))!
//
//        return [simd_float3(x: getCos(from: -x), y: getCos(from:  -y - z), z: getCos(from:  -z)),
//                simd_float3(x: getSin(from:  -x), y: getSin(from:  -y - z), z: getSin(from:  -z))]
//    }
    //    func transform(planeAnchor: ARPlaneAnchor) -> [simd_float3] {
    //        var result: [simd_float3] = []
    //        let aVector = getCosSinVectors(planeAnchor: planeAnchor)
    //        let center = simd_float3(x: planeAnchor.transform.columns.3.x + planeAnchor.center.x,
    //                                 y: planeAnchor.transform.columns.3.y + planeAnchor.center.y,
    //                                 z: planeAnchor.transform.columns.3.z + planeAnchor.center.z)
    //
    //        if planeAnchor.alignment == .vertical {
    //            for point in planeAnchor.geometry.boundaryVertices {
    //                let y2 = point.y * 0 - point.z * 1
    //                let z1 = point.y * 1 + point.z * 0
    //                let x2 = point.x * aVector[0].y - z1 * aVector[1].y
    //                let z2 = point.x * aVector[1].y + z1 * aVector[0].y
    //                result.append(simd_float3(x: x2 + center.x, y: y2 + center.y, z: z2 + center.z))
    //            }
    //        } else {
    //            for point in planeAnchor.geometry.boundaryVertices {
    //                let x2 = point.x * aVector[0].y - point.z * aVector[1].y
    //                let z2 = point.x * aVector[1].y + point.z * aVector[0].y
    //                let y2 = point.y
    //                result.append(simd_float3(x: x2 + center.x, y: y2 + center.y, z: z2 + center.z))
    //            }
    //        }
    //        return result
    //    }

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

    func getMap(onlyNew: Bool) -> [MapElement] {
        var result : [MapElement] = []
        if onlyNew {
            for mapEl in mapGrid.values {
                if !mapEl.loadedInMap && mapEl.confidence > confidenceThreshold {
                    result.append(mapEl)
                    mapEl.loadedInMap = true
                }
           }
        } else {
            for mapEl in mapGrid.values {
                if mapEl.confidence > confidenceThreshold {
                    result.append(mapEl)
                    mapEl.loadedInMap = true
                }
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
    var loadedInMap = false
    var name: String = ""

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
        case .object: color = UIColor(red:0.47, green:0.88, blue:0.56, alpha:1.0)
        case .floor: color = UIColor(red:0.96, green:0.73, blue:0.23, alpha:1.0)
        case .plane: color =  UIColor(red:0.90, green:0.56, blue:0.15, alpha:1.0)
        case .wall: color = UIColor(red:0.29, green:0.41, blue:0.74, alpha:1.0)
        case .center: color = UIColor(red:0.90, green:0.31, blue:0.22, alpha:1.0)
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
    case plane
    case wall
    case object
    case center
    case notDefined
}
