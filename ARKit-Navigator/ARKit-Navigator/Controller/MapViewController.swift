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
//    func getFloorPoints() -> [MapElement2d]
//    func getWallPoints() -> [MapElement2d]
//    func getObjectPoints() -> [MapElement2d]
//    func getMapElements() -> [MapElement2d]
    func getFloorPoints() -> [MapElement]
    func getWallPoints() -> [MapElement]
    func getObjectPoints() -> [MapElement]
    func getMapElements() -> [MapElement]
    func getGridSize() -> Float
    func getCameraOrientation() -> vector_float3?
    func getCameraLocation() -> SCNVector3?
    func getCurrentPositionOfCamera() -> SCNVector3
}

class MapViewController: UIViewController {

    @IBOutlet weak var mapSKView: SKView!

    var delegate: MapViewDelegate?

    let scene = SKScene(size: CGSize(width: 327, height: 537))

    var mapTimer: Timer?
    var mapRefreshRate = 0.07

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidLoad()
        mapSKView.presentScene(scene)

        let backNode = SKShapeNode(circleOfRadius: scene.size.height)
        backNode.fillColor = .lightGray
        backNode.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        backNode.name = "backNode"

        if let mapElements = delegate?.getMapElements(),
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
            if let cameraLocation = delegate?.getCameraLocation() {
                let newNode = SKShapeNode(circleOfRadius: scaledGridSize * 3)
                newNode.position = CGPoint(x: Double(cameraLocation.x * 100), y: Double(cameraLocation.z * 100))
                newNode.fillColor = UIColor(red:0.97, green:0.56, blue:0.70, alpha:1.0)
                newNode.name = "camera"

                let rectSize = scaledGridSize * 8
                let newRectNode = SKShapeNode(rectOf: CGSize(width: rectSize, height: rectSize))
                newRectNode.zRotation = CGFloat(GLKMathDegreesToRadians(45.0))
                newRectNode.position = CGPoint(x: 0, y: 3 * sqrt(rectSize))
                newRectNode.name = "rect"
                newRectNode.lineWidth = 0
                newRectNode.fillColor = UIColor(red:0.97, green:0.65, blue:0.76, alpha:0.5)
                newNode.addChild(newRectNode)
                //newNode.childNode(withName: "rect")?.zPosition = -1

                backNode.addChild(newNode)
                newNode.zPosition = 5
                newRectNode.zPosition = -1
            }
            updateMap()
        }

        scene.addChild(backNode)
        mapSKView.presentScene(scene)
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
            self.scene.childNode(withName: "backNode")?.zRotation = CGFloat(currentOrientation.x)
            self.scene.childNode(withName: "backNode")?.childNode(withName: "camera")?.position =
            CGPoint (x: CGFloat(currentPosition.x * 100), y: -CGFloat(currentPosition.z * 100))
            self.scene.childNode(withName: "backNode")?.childNode(withName: "camera")?.zRotation = CGFloat(-currentOrientation.x)
        }
        if let mapElements = delegate?.getMapElements(),
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
