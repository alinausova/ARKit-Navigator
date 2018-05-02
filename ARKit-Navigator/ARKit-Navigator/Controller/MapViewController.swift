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

class MapViewController: UIViewController {

    @IBOutlet weak var mapSKView: SKView!

    let scene = SKScene(size: CGSize(width: 327, height: 537))

    override func viewDidLoad() {
        super.viewDidLoad()
        mapSKView.presentScene(scene)

        let label = SKLabelNode(text: "SpriteKit")
        label.position = CGPoint(x: scene.size.width / 2,
                                 y: scene.size.height / 2)
        scene.addChild(label)
        mapSKView.presentScene(scene)
        let backNode = SKShapeNode(rectOf: scene.size)
        backNode.fillColor = .white
        


    }

    @IBAction func goBack(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }


}
