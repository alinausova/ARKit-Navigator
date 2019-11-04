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
    let confidenceThreshold = 15.0
    let gridSize : Float = 0.05
    var path: [vector_float3] = []

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

    /// Set the floor level
    func setFloor(floorLevel: Float) {
        self.floorLevel = round(floorLevel / gridSize) * gridSize
    }

    /// Check if a level belongs to the floor range
    func isFloor(planeLevel: Float) -> Bool {
        if planeLevel - floorLevel < floorLevelMistake {
            return true
        } else {
            return false
        }
    }

    /// Process new ARPlaneAnchor data
    func addElement(newElement: ARPlaneAnchor) {
        if newElement.alignment == .horizontal {
            addHorisontalPlane(newElement: newElement)
        }
        else if newElement.alignment == .vertical {
            addVerticalPlane(newElement: newElement)
        }
    }

    /// Change current path
    func addPath(path: [vector_float3]){
        self.path = path
    }

    /// Process horisontal plane
    func addHorisontalPlane(newElement: ARPlaneAnchor) {
        if isFloor(planeLevel: newElement.transform.columns.3.y) {
        for element in translatePlane(planeAnchor: newElement) {
                let newMapElement = MapElement (x: round(element.x / gridSize) * gridSize,
                                                y: floorLevel,
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
    }

    /// Process vertical plane
    func addVerticalPlane(newElement: ARPlaneAnchor) {
        var newWallPoints : [MapElement] = []
        for element in translatePlane(planeAnchor: newElement) {
            let newMapElement = MapElement (x: round(element.x / gridSize) * gridSize,
                                            y: floorLevel,
                                            z: round(element.z / gridSize) * gridSize,
                                            content: .wall,
                                            confidence: 30)
            addMapElementToGrid(newMapElement: newMapElement)
            newWallPoints.append(newMapElement)
        }
    }

    /// Add object to the map grid
    func addObjectToGrid(newElement: ARAnchor, name: String) {
        let newMapElement = MapElement(x: round((newElement.transform.columns.3.x) / gridSize) * gridSize,
                                         y: floorLevel,
                                         z: round((newElement.transform.columns.3.z) / gridSize) * gridSize,
                                         content: .object,
                                         confidence: 1000,
                                         name: name)
        addMapElementToGrid(newMapElement: newMapElement)
    }

    /// Add a new element to grid
    func addMapElementToGrid(newMapElement: MapElement) {
        let newKey = createKey(mapElement: newMapElement)
        if let old = mapGrid[newKey]{
            if old.content == newMapElement.content && old.confidence < 999 {
                old.confidence += 1
            } else if old.confidence < newMapElement.confidence {
                mapGrid[newKey] = newMapElement
            }
        } else {
            mapGrid[newKey] = newMapElement
        }
    }

    /// Check if a point belongs to the polygon
    func isPointInPolygon(boundaries: [vector_float3], point: vector_float3) -> Bool {
        var result = false
        for i in 0...boundaries.count-1 {
            let p1: vector_float3
            let p2 = boundaries[i]
            if i == 0 {
                p1 = boundaries[boundaries.count-1]
            } else {
                p1 = boundaries[i-1]
            }
            if ((((p1.z <= point.z) && ( point.z < p2.z )) || ((p2.z <= point.z) && ( point.z < p1.z ))) && ( point.x > (p2.x - p1.x) * (point.z - p1.z) / (p2.z - p1.z) + p1.x)) {
                result = !result
            }
        }
        return result
    }

    /// Make rotation matrix for X axis, angle is in radians
    func makeXRotationMatrix(angle: Float) -> simd_float3x3 {
        let rows = [
            simd_float3( 1,     0,              0),
            simd_float3( 0,     cos(angle),     sin(angle)),
            simd_float3( 0,     -sin(angle),    cos(angle)),
        ]

        return float3x3(rows: rows)
    }

    /// Make rotation matrix for Y axis, angle is in radians
    func makeYRotationMatrix(angle: Float) -> simd_float3x3 {
        let rows = [
            simd_float3( cos(angle),  0,    sin(angle)),
            simd_float3( 0,           1,    0),
            simd_float3( -sin(angle), 0,    cos(angle)),
        ]

        return float3x3(rows: rows)
    }

    /// Rotate and translate all points belong to the plane
    func translatePlane(planeAnchor: ARPlaneAnchor) -> [simd_float3] {
        var result: [simd_float3] = []

        let string = planeAnchor.description
        let end = string.components(separatedBy: CharacterSet(charactersIn : "()"))[3].components(separatedBy: "°")

        let y = Float(end[1].trimmingCharacters(in: CharacterSet(charactersIn: " ")))!
        if planeAnchor.alignment == .vertical && y == 0 {
            print("Vertical plane orientation mistake")
            return  result
        }

        let center = simd_float3(x: planeAnchor.transform.columns.3.x,
                                 y: planeAnchor.transform.columns.3.y,
                                 z: planeAnchor.transform.columns.3.z)

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

    /// Create a key for mapGrid dictionary from a vector
    func createKey (mapElement: MapElement) -> String {
        return "\(mapElement.x):\(mapElement.y):\(mapElement.z)"
    }

    /// Get distance between two map elements
    func getDistance(a: MapElement, b: MapElement) -> Float {
        var distance : Float
        distance = sqrt(pow((a.x - b.x),2) + pow((a.y - b.y),2) + pow((a.z - b.z),2))
        return distance
    }

    /// Mock map elements for path finder demonstration
    func mockPlaneForTesting(loc: vector_float3) {
        let current = vector_float3( round(loc.x / gridSize) * gridSize,
                                     floorLevel,
                                     round(loc.z / gridSize) * gridSize)
        for i in -20...20 {
            for j in -20...20 {
                if i == 15 && i == j {
                    let newMapElement = MapElement (x: current.x + Float(i) * gridSize,
                                                    y: floorLevel,
                                                    z: current.z + Float(j) * gridSize,
                                                    content: .object,
                                                    confidence: 100,
                                                    name: "Granny Smith")
                    addMapElementToGrid(newMapElement: newMapElement)
                } else if (i == 8 && j < 10 && j > -15) || (j == 8 && i < 10 && i > -15) || (j == -8 && i < 10 && i > -15) || (i == -8 && j < 15 && j > -5) {
                    let newMapElement = MapElement (x: current.x + Float(i) * gridSize,
                                                    y: floorLevel,
                                                    z: current.z + Float(j) * gridSize,
                                                    content: .wall,
                                                    confidence: 100)
                    addMapElementToGrid(newMapElement: newMapElement)
                } else {
                    let newMapElement = MapElement (x: current.x + Float(i) * gridSize,
                                                    y: floorLevel,
                                                    z: current.z + Float(j) * gridSize,
                                                    content: .floor,
                                                    confidence: 100)
                    addMapElementToGrid(newMapElement: newMapElement)
                }
            }
        }
    }

    /// Get only new or all map elements
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

    /// Get an object from the map by its name
    func getObject(objectName: String) -> MapElement? {
        for mapEl in mapGrid.values {
            if mapEl.content == .object,
                mapEl.name == objectName {
                return mapEl
            }
        }
        return nil
    }

    /// Get only new or all floor map elements
    func getFloor(only new: Bool) -> [MapElement] {
        var result: [MapElement] = []
        if new {
            for mapEl in mapGrid.values {
                if mapEl.content == .floor && mapEl.isNew
                {
                    result.append(mapEl)
                }
            }
        } else {
            for mapEl in mapGrid.values {
                if mapEl.content == .floor
                {
                    result.append(mapEl)
                }
            }
        }
        return result
    }

    /// Change status of new map elements when enviroment research cycle step is complete
    func toOld() {
        for mapEl in mapGrid.values {
            if mapEl.isNew
            {
                mapEl.isNew = false
            }
        }
    }
}

class MapElement {
    let x : Float
    let y : Float
    let z : Float
    var confidence = 0.0
    var content = MapContent.notDefined
    var loadedInMap = false
    var isNew = true
    var name: String = ""

    init(x: Float, y: Float, z: Float, content: MapContent, confidence: Double) {
        self.x = x
        self.y = y
        self.z = z
        self.content = content
        self.confidence = confidence
    }

    init(x: Float, y: Float, z: Float, content: MapContent, confidence: Double, name: String) {
        self.x = x
        self.y = y
        self.z = z
        self.content = content
        self.confidence = confidence
        self.name = name
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
}

enum MapContent{
    case floor
    case plane
    case wall
    case object
    case center
    case notDefined
}


