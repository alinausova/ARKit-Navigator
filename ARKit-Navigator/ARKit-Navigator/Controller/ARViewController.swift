//
//  ViewController.swift
//  ARKit-Navigator
//
//  Created by Alina Usova on 01/05/2018.
//  Copyright © 2018 alinausova. All rights reserved.
//

import UIKit
import ARKit

class ARViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var sceneLabel: UILabel!
   
    
    let configuration = ARWorldTrackingConfiguration()
    var mapElements : [ARAnchor] = []
    var floorLevel : Float = 100.0
    let map = Map()

    override func viewDidLoad() {
        super.viewDidLoad()

        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
        }

        sceneView.delegate = self
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        configuration.planeDetection = [.horizontal, .vertical]
        //configuration.isAutoFocusEnabled = true
        self.sceneView.session.run(configuration)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Place content only for anchors found by plane detection.
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

        // Create a SceneKit plane to visualize the plane anchor using its position and extent.
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode(geometry: plane)
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)

        // `SCNPlane` is vertically oriented in its local coordinate space, so
        // rotate the plane to match the horizontal orientation of `ARPlaneAnchor`.
        planeNode.eulerAngles.x = -.pi / 2

        // Make the plane visualization semitransparent to clearly show real-world placement.
        planeNode.opacity = 0.25

        // Add the plane visualization to the ARKit-managed node so that it tracks
        // changes in the plane anchor as plane estimation continues.
        //mapElements.append(planeAnchor)


        add(x: planeAnchor.transform.columns.3.x,
            y: planeAnchor.transform.columns.3.y,
            z: planeAnchor.transform.columns.3.z,
            color: .green)
//        for ver in planeAnchor.geometry.vertices {
//            add(x: planeAnchor.transform.columns.3.x + ver.x,
//                y: planeAnchor.transform.columns.3.y + ver.y,
//                z: planeAnchor.transform.columns.3.z + ver.z,
//            color: .green)
//        }
//        for ver in planeAnchor.geometry.boundaryVertices {
//            add(x: planeAnchor.transform.columns.3.x + ver.x,
//                y: planeAnchor.transform.columns.3.y + ver.y,
//                z: planeAnchor.transform.columns.3.z + ver.z,
//                color: .blue)
//        }
//        for ver in planeAnchor.geometry.textureCoordinates {
//            add(x: planeAnchor.transform.columns.3.x + ver.x,
//                y: planeAnchor.transform.columns.3.y,
//                z: planeAnchor.transform.columns.3.z + ver.y,
//                color: .red)
//        }

        node.addChildNode(planeNode)

        map.addElement(newElement: planeAnchor)

        if planeAnchor.center.z < self.floorLevel {
            floorLevel = planeAnchor.center.z
            updateStateLabel()
        }

    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Update content only for plane anchors and nodes matching the setup created in `renderer(_:didAdd:for:)`.
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }

        // Plane estimation may shift the center of a plane relative to its anchor's transform.
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)

        // Plane estimation may also extend planes, or remove one plane to merge its extent into another.
        plane.width = CGFloat(planeAnchor.extent.x)
        plane.height = CGFloat(planeAnchor.extent.z)
        //mapElements.append(planeAnchor)
         if planeAnchor.center.z < self.floorLevel {
            floorLevel = planeAnchor.center.z
            updateStateLabel()
        }
        map.addElement(newElement: planeAnchor)
    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let anchorPlane = anchor as? ARPlaneAnchor else { return }
        print("Plane Anchor was removed!", anchorPlane.extent)
    }

    func updateStateLabel() {
        DispatchQueue.main.async{
            self.sceneLabel.text = "Floor level: \(self.floorLevel)"
        }
    }

    func add(x: Float, y: Float, z: Float, color: UIColor) {
        let node = SCNNode()
        node.geometry = SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0.01)
        node.geometry?.firstMaterial?.diffuse.contents = color
        node.position = SCNVector3(x,y,z)
        self.sceneView.scene.rootNode.addChildNode(node)
    }

    func refreshFloor() {
        let floor = map.getFloor()
        for floorEl in floor {
            if floorEl.confidence>5 {
                add(x: floorEl.x, y: floorEl.y, z: floorEl.z, color: .blue)
            }
        }
    }

    @IBAction func showFloor(_ sender: Any) {
        refreshFloor()
    }

    @IBAction func describeMap(_ sender: Any) {
        for element in mapElements {
            guard let planeAnchor = element as? ARPlaneAnchor else { return }
            print("\n Center: \(planeAnchor.center),  Extent \(planeAnchor.extent),\n \(planeAnchor.alignment), \n Description \(planeAnchor.description),\n Transform \(planeAnchor.transform)")
        }
    }
}

