//
//  MapViewController.swift
//  ARKit-Navigator
//
//  Created by Alina Usova on 02/05/2018.
//  Copyright © 2018 alinausova. All rights reserved.
//

import Foundation
import UIKit
import ARKit
import SpriteKit

protocol  MapViewDelegate {
    func getMapElements(onlyNew: Bool) -> [MapElement]
    func getGridSize() -> Float
    func getCameraLocation() -> SCNVector3?
    func getCurrentPositionOfCamera() -> CGFloat
    func isPathUpdateNeeded() -> Bool
    func getNewPath() -> [vector_float3] 
}

class MapViewController: UIViewController {

    @IBOutlet weak var mapSKView: SKView!

    var delegate: MapViewDelegate?
    let scene = SKScene(size: CGSize(width: 2048, height: 2048))

    var mapTimer: Timer?
    var mapRefreshRate = 0.07

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mapSKView.presentScene(scene)

        // Create node for the map base
        let backNode = SKShapeNode(circleOfRadius: scene.size.height)
        backNode.fillColor = .clear
        backNode.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        backNode.name = "backNode"

        // Load existing map elements

        if let mapElements = delegate?.getMapElements(onlyNew: false),
            let gridSize = delegate?.getGridSize() {
            let scaledGridSize = CGFloat(gridSize * 100)
            // Show existing elements
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

            backNode.addChild(roundNode)
            roundNode.zPosition = 15
            triangleNode.zPosition = -1
        }

        scene.addChild(backNode)
        mapSKView.presentScene(scene)
        // Set the timer for veiw update
        mapTimer = Timer.scheduledTimer(withTimeInterval: mapRefreshRate, repeats: true, block: {_ in
            self.updateMap()
        })
    }

    @IBAction func goBack(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    func updateMap() {
        if let currentOrientation = delegate?.getCurrentPositionOfCamera(),
            let currentPosition = delegate?.getCameraLocation() {
            self.scene.childNode(withName: "backNode")?.childNode(withName: "round")?.position =
            CGPoint (x: CGFloat(currentPosition.x * 100), y: -CGFloat(currentPosition.z * 100))
            self.scene.childNode(withName: "backNode")?.childNode(withName: "round")?.zRotation = CGFloat(currentOrientation)
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
                self.scene.childNode(withName: "backNode")?.addChild(newNode)
            }
        }
    }
}
