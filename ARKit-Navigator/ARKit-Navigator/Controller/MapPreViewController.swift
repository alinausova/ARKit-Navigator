//
//  MapPreViewController.swift
//  ARKit-Navigator
//
//  Created by Alina Usova on 19/05/2018.
//  Copyright © 2018 alinausova. All rights reserved.
//

import Foundation
import UIKit
import ARKit
import SpriteKit

protocol  MapPreViewDelegate : MapViewDelegate {
}

class MapPreViewController : UIViewController {
    
    @IBOutlet weak var mapSKView: SKView!

    var delegate: MapPreViewDelegate?

    let scene = SKScene(size: CGSize(width: 512, height: 512))

    var mapTimer: Timer?
    var mapRefreshRate = 0.07

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mapSKView.presentScene(scene)

        // Create root view node
        let rootNode = SKShapeNode(circleOfRadius: scene.size.height / 2)
        rootNode.name = "root"
        rootNode.fillColor = .clear
        rootNode.lineWidth = 0
        rootNode.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)

        // Create node for the map base
        let backNode = SKShapeNode(circleOfRadius: scene.size.height)
        backNode.name = "backNode"
        backNode.fillColor = .clear
        backNode.position = CGPoint(x: 0, y: 0)

        // Load existing map elements

        if let mapElements = delegate?.getMapElements(onlyNew: false),
            let gridSize = delegate?.getGridSize() {
            let scaledGridSize = CGFloat(gridSize * 100)
            for element in mapElements {
                let newNode = SKShapeNode(rectOf: CGSize(width: CGFloat(scaledGridSize), height: CGFloat(scaledGridSize)))
                newNode.position = CGPoint(x: Double(element.x) * 100 , y: -Double(element.z) * 100)
                newNode.fillColor = element.getElementColor()
                newNode.glowWidth = 0
                newNode.lineWidth = 0
                backNode.addChild(newNode)
            }

            // Create round node for current device position
            let roundNode = SKShapeNode(circleOfRadius: scaledGridSize * 3)
            roundNode.fillColor = UIColor(red:0.72, green:0.08, blue:0.25, alpha:1.0)
            roundNode.name = "round"

            if let cameraLocation = delegate?.getCameraLocation() {
                roundNode.position = CGPoint(x: Double(cameraLocation.x * 100), y: Double(cameraLocation.z * 100))
            } else {
                roundNode.position = CGPoint(x: 0, y: 0)
            }

            // Create triangle node for orientation representation
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0.0, y: 50.0))
            path.addLine(to: CGPoint(x: 50.0, y: -36.6))
            path.addLine(to: CGPoint(x: -50.0, y: -36.6))
            path.addLine(to: CGPoint(x: 0.0, y: 50.0))

            let triangleNode = SKShapeNode(path: path.cgPath)
            triangleNode.fillColor = UIColor(red:0.72, green:0.08, blue:0.25, alpha:0.5)
            triangleNode.name = "triangle"
            triangleNode.lineWidth = 0
            triangleNode.zRotation = CGFloat(GLKMathDegreesToRadians(180))
            triangleNode.yScale = 0.5
            triangleNode.position = CGPoint(x: 0, y: 20)
            roundNode.addChild(triangleNode)

            // Create  node for path representation
            let pathLayer = SKShapeNode(circleOfRadius: scene.size.height)
            pathLayer.name = "pathLayer"
            pathLayer.fillColor = .clear
            pathLayer.position = CGPoint(x: 0, y: 0)

            backNode.addChild(roundNode)
            backNode.addChild(pathLayer)
            pathLayer.zPosition = 14
            roundNode.zPosition = 15
            triangleNode.zPosition = -1
        }

        rootNode.addChild(backNode)
        scene.addChild(rootNode)
        mapSKView.presentScene(scene)

        // Set the timer for veiw update
        mapTimer = Timer.scheduledTimer(withTimeInterval: mapRefreshRate, repeats: true, block: {_ in
            self.updateMap()
            if let pathUpdate = self.delegate?.isPathUpdateNeeded(),
                pathUpdate,
                let path = self.delegate?.getNewPath(){
                self.drawPath(path: path)
            }
        })
    }

    func updateMap() {
        if let currentOrientation = delegate?.getCurrentPositionOfCamera(),
            let currentPosition = delegate?.getCameraLocation() {

            self.scene.childNode(withName: "root")?.zRotation = CGFloat(-currentOrientation)
            self.scene.childNode(withName: "root")?.childNode(withName: "backNode")?.childNode(withName: "round")?.zRotation = CGFloat(currentOrientation)

            self.scene.childNode(withName: "root")?.childNode(withName: "backNode")?.childNode(withName: "round")?.position =
                CGPoint (x: CGFloat(currentPosition.x * 100), y: -CGFloat(currentPosition.z * 100))
            self.scene.childNode(withName: "root")?.childNode(withName: "backNode")?.position =
                            CGPoint (x: -CGFloat(currentPosition.x * 100),
                                     y: CGFloat(currentPosition.z * 100))

        }
        if let mapElements = delegate?.getMapElements(onlyNew: true),
            let gridSize = delegate?.getGridSize() {
            let scaledGridSize = CGFloat(gridSize * 100)
            for element in mapElements {
                let newNode = SKShapeNode(rectOf: CGSize(width: CGFloat(scaledGridSize), height: CGFloat(scaledGridSize)))
                newNode.position = CGPoint(x: Double(element.x) * 100 , y: -Double(element.z) * 100)
                newNode.fillColor = element.getElementColor()
                newNode.glowWidth = 0
                newNode.lineWidth = 0
                self.scene.childNode(withName: "root")?.childNode(withName: "backNode")?.addChild(newNode)
            }
        }
    }

    // Draw new path to the point
    func drawPath(path: [vector_float3]) {
        self.scene.childNode(withName: "root")?.childNode(withName: "backNode")?.childNode(withName: "pathLayer")?.removeAllChildren()
        if let gridSize = delegate?.getGridSize() {
            let scaledGridSize = CGFloat(gridSize * 100)
            for element in path {
                let newNode = SKShapeNode(rectOf: CGSize(width: CGFloat(scaledGridSize), height: CGFloat(scaledGridSize)))
                newNode.position = CGPoint(x: Double(element.x) * 100 , y: -Double(element.z) * 100)
                newNode.fillColor = .red
                newNode.glowWidth = 0
                newNode.lineWidth = 0
                self.scene.childNode(withName: "root")?.childNode(withName: "backNode")?.childNode(withName: "pathLayer")?.addChild(newNode)
            }
        }
    }
}
