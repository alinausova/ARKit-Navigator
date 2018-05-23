//
//  AStarPathFinder.swift
//  ARKit-Navigator
//
//  Created by Alina Usova on 23/05/2018.
//  Copyright © 2018 alinausova. All rights reserved.
//

import Foundation
import UIKit
import ARKit

class AStarPathFinder {

    func findPath(from: simd_float3, to: simd_float3, map: Map) -> [vector_float3] {
        let start_node = Node(position: from, parent: nil)
        start_node.getHeuristic(to: to)
        let end_node = Node(position: to, parent: nil)

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
                    print(current?.f)
                    path.append((current?.position)!)
                    current = current?.parent
                }
                print("**************\(path.count)***************")
                return path
            }

            //print (getChildren(parent: currentNode, map: map).count)
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
