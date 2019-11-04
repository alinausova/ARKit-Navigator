//
//  AStarPathFinder.swift
//  ARKit-Navigator
//
//  Created by Alina Usova on 20/05/2018.
//  Copyright © 2018 alinausova. All rights reserved.
//

import Foundation
import UIKit
import ARKit

class AStarPathFinder {

    // Find path to object on the map
    func findPath(from: simd_float3, to: simd_float3, map: Map) -> [vector_float3] {
        let start_node = Node(position: from, parent: nil)
        start_node.getHeuristic(to: to)

        var openList: [Node] = []
        var closedList: [Node] = []

        openList.append(start_node)

        while openList.count > 0 {
            var currentNode = openList[0]
            var currentInd = 0
            for i in 0...openList.count - 1 {
                if openList[i].f < currentNode.f {
                    currentNode = openList[i]
                    currentInd = i
                }
            }
            openList.remove(at: currentInd)
            closedList.append(currentNode)

            if currentNode.h < map.gridSize {
                var path: [vector_float3] = []
                var current: Node? = currentNode
                while current != nil {
                    print("\(String(describing: current?.f))")
                    path.append((current?.position)!)
                    current = current?.parent
                }
                print("**************\(path.count)***************")
                return path
            }

            for child in getChildren(parent: currentNode, map: map) {
                var isClosed = false
                for closedChild in closedList {
                    if closedChild == child {
                        isClosed = true
                    }
                }
                var isOpen = false
                for openChild in openList {
                    if openChild == child {
                        isOpen = true
                        if openChild.g > child.g {
                            openChild.parent = child.parent
                            openChild.g = child.g
                            openChild.f = openChild.g + openChild.h
                        }
                    }
                }

                if !isClosed && !isOpen {
                    child.getHeuristic(to: to)
                    child.f = child.g + child.h
                    openList.append(child)
                    print ("\(child.position.x) ---- \(child.position.z)")
                }

            }
        }
        return []
    }

    // Get array of free to move nodes
    func getChildren(parent: Node, map: Map) -> [Node] {
        var children: [Node] = []
        for key in createNeighborKeys(node: parent, gridSize: map.gridSize) {
            if let newChild = map.mapGrid[key],
                newChild.content == .floor || newChild.content == .object {
                let newChildNode = Node(position: vector_float3(x: newChild.x, y: newChild.y, z: newChild.z), parent: parent)
                newChildNode.g = parent.g + map.gridSize / 2 
                children.append(newChildNode)
            }
        }
        return children
    }

    // Get keys to dictionary for
    func createNeighborKeys (node: Node, gridSize: Float) -> [String] {
        var newKeys : [String] = []
        newKeys.append("\(node.position.x + gridSize):\(node.position.y):\(node.position.z)")
        newKeys.append("\(node.position.x + gridSize):\(node.position.y):\(node.position.z + gridSize)")
        newKeys.append("\(node.position.x + gridSize):\(node.position.y):\(node.position.z - gridSize)")
        newKeys.append("\(node.position.x):\(node.position.y):\(node.position.z + gridSize)")
        newKeys.append("\(node.position.x):\(node.position.y):\(node.position.z - gridSize)")
        newKeys.append("\(node.position.x - gridSize):\(node.position.y):\(node.position.z)")
        newKeys.append("\(node.position.x - gridSize):\(node.position.y):\(node.position.z + gridSize)")
        newKeys.append("\(node.position.x - gridSize):\(node.position.y):\(node.position.z - gridSize)")
        return newKeys
    }

    // Get the furthest point on the map from new ones
    func getFurthestPoint (start: vector_float3, map: Map) -> vector_float3 {
        let floorPoints = map.getFloor(only: true)
        var maxDistance: Float = 0
        var result = start
        for point in floorPoints {
            let newDistance = getDistance(v1: start, v2: vector_float3(point.x, point.y, point.z))
            if maxDistance < newDistance {
                maxDistance = newDistance
                result = vector_float3(point.x, point.y, point.z)
            }
        }
        return result
    }

    //Get distance between two points on the map
    func getDistance(v1: vector_float3, v2: vector_float3) -> Float {
        return Float(sqrt(pow((v1.x - v2.x),2) + pow((v1.y - v2.y),2) + pow((v1.z - v2.z),2)))
    }

}

class Node {
    let position: vector_float3
    var parent: Node?
    var g: Float = 0.0
    var h: Float = 0.0
    var f: Float = 0.0

    init(position: vector_float3, parent: Node?) {
        self.position = position
        self.parent = parent
    }

    //Heuristic function is the distance between points
    func getHeuristic(to: vector_float3) {
        self.h = Float(sqrt(pow((position.x - to.x),2) + pow((position.y - to.y),2) + pow((position.z - to.z),2)))
    }
}
extension Node {
    static func == (left: Node, right: Node) -> Bool {
        return left.position == right.position
    }
    static func != (left: Node, right: Node) -> Bool {
        return !(left.position == right.position)
    }
}
