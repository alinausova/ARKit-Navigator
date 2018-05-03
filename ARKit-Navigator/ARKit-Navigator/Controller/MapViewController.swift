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
    func getFloorPoints() -> [MapElement2d]
    func getWallPoints() -> [MapElement2d]
    func getObjectPoints() -> [MapElement2d]
    func getGridSize() -> Float
}

class MapViewController: UIViewController {

    @IBOutlet weak var mapSKView: SKView!

    var delegate: MapViewDelegate?

    let scene = SKScene(size: CGSize(width: 327, height: 537))

    override func viewDidLoad() {
        super.viewDidLoad()
        mapSKView.presentScene(scene)

        let backNode = SKShapeNode(rectOf: scene.size)
        backNode.fillColor = .lightGray
        backNode.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)

        if let floor = delegate?.getFloorPoints(),
            let gridSize = delegate?.getGridSize() {
            let scaledGridSize = gridSize * 100
            for point in floor {
                let newNode = SKShapeNode(rectOf: CGSize(width: CGFloat(scaledGridSize), height: CGFloat(scaledGridSize)))
                newNode.position = CGPoint(x: Double(point.x) * 100 , y: Double(point.z) * 100)
                //newNode.position = CGPoint (x: 0, y: 0)
                newNode.fillColor = .blue
                backNode.addChild(newNode)
            }
        }

        if let wall = delegate?.getWallPoints(),
            let gridSize = delegate?.getGridSize() {
            let scaledGridSize = gridSize * 100
            for point in wall {
                let newNode = SKShapeNode(rectOf: CGSize(width: CGFloat(scaledGridSize), height: CGFloat(scaledGridSize)))
                newNode.position = CGPoint(x: Double(point.x) * 100 , y: Double(point.z) * 100)
                //newNode.position = CGPoint (x: 0, y: 0)
                newNode.fillColor = .red
                backNode.addChild(newNode)
            }
        }

//        let frontNode = SKShapeNode(circleOfRadius: 100)
//        frontNode.fillColor = .green
//        frontNode.position = CGPoint(x: 0, y: 0)
//        backNode.addChild(frontNode)

            scene.addChild(backNode)

        mapSKView.presentScene(scene)


    }

    @IBAction func goBack(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
