//
//  ViewController.swift
//  ARKit-Navigator
//
//  Created by Alina Usova on 01/05/2018.
//  Copyright © 2018 alinausova. All rights reserved.
//

import UIKit
import ARKit
import CoreML
import Vision

class ARViewController: UIViewController, ARSCNViewDelegate, MapViewDelegate, MapPreViewDelegate, ARSessionDelegate {

    // MARK: - IBOutlets

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var sceneLabel: UILabel!
    @IBOutlet weak var mapPreView: UIView!
    @IBOutlet weak var mapPreviewButton: UIButton!


    private lazy var statusViewController: StatusViewController = {
        return childViewControllers.lazy.flatMap({ $0 as? StatusViewController }).first!
    }()
    
    let configuration = ARWorldTrackingConfiguration()
    let confidenceThreshold = 15.0
    var mapElements : [ARAnchor] = []
    var floorLevel : Float = 100.0
    var appleIsNotFound = true
    var currentPositionOfCamera: CGFloat = 0

    var map = Map() //Map2D()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        mapPreView.layer.cornerRadius = 128
        mapPreView.layer.masksToBounds = true

        sceneView.delegate = self
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.delegate = self
        self.sceneView.session.run(configuration)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nav = segue.destination as? MapViewController {
               nav.delegate = self
        }
        if let nav = segue.destination as? MapPreViewController {
            nav.delegate = self
        }
    }


    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode(geometry: plane)
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)

        planeNode.eulerAngles.x = -.pi / 2
        planeNode.opacity = 0.1

//        add(x: planeAnchor.transform.columns.3.x,
//            y: planeAnchor.transform.columns.3.y,
//            z: planeAnchor.transform.columns.3.z,
//            color: .green, size: 0.05)

//        add(x: planeAnchor.transform.columns.3.x + planeAnchor.center.x,
//            y: planeAnchor.transform.columns.3.y + planeAnchor.center.y,
//            z: planeAnchor.transform.columns.3.z + planeAnchor.center.z,
//            color: .yellow, size: 0.05)
//        add(x: planeAnchor.transform.columns.3.x + planeAnchor.transform.columns.0.x,
//            y: planeAnchor.transform.columns.3.y + planeAnchor.transform.columns.0.y,
//            z: planeAnchor.transform.columns.3.z + planeAnchor.transform.columns.0.z,
//            color: .white, size: 0.05)
//        add(x: planeAnchor.transform.columns.3.x + planeAnchor.transform.columns.1.x,
//            y: planeAnchor.transform.columns.3.y + planeAnchor.transform.columns.1.y,
//            z: planeAnchor.transform.columns.3.z + planeAnchor.transform.columns.1.z,
//            color: .red, size: 0.05)
//
//        let center = SCNVector3(x: planeAnchor.transform.columns.3.x + planeAnchor.center.x,
//                                 y: planeAnchor.transform.columns.3.y + planeAnchor.center.y,
//                                 z: planeAnchor.transform.columns.3.z + planeAnchor.center.z)
//
//        let testPoint = rotate(point: simd_float3(x: 0.1, y: 0, z: 0.1), planeAnchor: planeAnchor)
//                    add(x: testPoint.x,
//                        y: testPoint.y,
//                        z: testPoint.z,
//                        color: .lightGray, size: 0.02)
//                    add(x: 0.1, y: 0, z: 0.1,
//                        color: .darkGray, size: 0.02)
//
//
//        let testPoint1 = rotate(point: simd_float3(x: 0.1, y: 0, z: 0), planeAnchor: planeAnchor)
//        let testPoint2 = rotate(point: simd_float3(x: 0, y: 0.1, z: 0), planeAnchor: planeAnchor)
//        let testPoint3 = rotate(point: simd_float3(x: 0, y: 0, z: 0.1), planeAnchor: planeAnchor)
//
//        add(x: testPoint1.x, y: testPoint1.y, z: testPoint1.z,
//            color: .red, size: 0.02)
//        add(x: testPoint2.x, y: testPoint2.y, z: testPoint2.z,
//            color: .green, size: 0.02)
//        add(x: testPoint3.x, y: testPoint3.y, z: testPoint3.z,
//            color: .blue, size: 0.02)
//
//        for element in planeAnchor.geometry.boundaryVertices {
//            let newPoint = rotate(point: simd_float3(x: element.x, y: element.y, z: element.z), planeAnchor: planeAnchor)
//            add(x: newPoint.x,
//                y: newPoint.y,
//                z: newPoint.z,
//                color: .lightGray, size: 0.01)
//            add(x: element.x + center.x,
//                y: element.y + center.y,
//                z: element.z + center.z,
//                color: .darkGray, size: 0.01)
//        }
//
//        let endPosition0 = SCNVector3(x: planeAnchor.transform.columns.3.x + planeAnchor.transform.columns.0.x,
//                                     y: planeAnchor.transform.columns.3.y + planeAnchor.transform.columns.0.y,
//                                     z: planeAnchor.transform.columns.3.z + planeAnchor.transform.columns.0.z)
//        let endPosition1 = SCNVector3(x: planeAnchor.transform.columns.3.x + planeAnchor.transform.columns.1.x,
//                                      y: planeAnchor.transform.columns.3.y + planeAnchor.transform.columns.1.y,
//                                      z: planeAnchor.transform.columns.3.z + planeAnchor.transform.columns.1.z)
//        let endPosition2 = SCNVector3(x: planeAnchor.transform.columns.3.x + planeAnchor.transform.columns.2.x,
//                                      y: planeAnchor.transform.columns.3.y + planeAnchor.transform.columns.2.y,
//                                      z: planeAnchor.transform.columns.3.z + planeAnchor.transform.columns.2.z)
//
//        addLine(startPosition: center, endPosition: endPosition0)
//        addLine(startPosition: center, endPosition: endPosition1)
//        addLine(startPosition: center, endPosition: endPosition2)
//        addLine(startPosition: SCNVector3(x: 0, y: 0, z: 0), endPosition:  SCNVector3(x: 1, y: 1, z: 1))

       // print("\(planeAnchor.description)")

        print("**********")


//        add(x: planeAnchor.transform.columns.3.x,
//            y: planeAnchor.transform.columns.3.y + 0.1,
//            z: planeAnchor.transform.columns.3.z,
//            color: .green, size: 0.05)
//        add(x: planeAnchor.transform.columns.3.x,
//            y: planeAnchor.transform.columns.3.y + 0.2,
//            z: planeAnchor.transform.columns.3.z,
//            color: .green, size: 0.05)
//        add(x: planeAnchor.transform.columns.3.x,
//            y: planeAnchor.transform.columns.3.y,
//            z: planeAnchor.transform.columns.3.z + 0.1,
//            color: .yellow, size: 0.05)
//        add(x: planeAnchor.transform.columns.3.x,
//            y: planeAnchor.transform.columns.3.y,
//            z: planeAnchor.transform.columns.3.z + 0.2,
//            color: .yellow, size: 0.05)
//        add(x: planeAnchor.transform.columns.3.x + 0.1,
//            y: planeAnchor.transform.columns.3.y,
//            z: planeAnchor.transform.columns.3.z,
//            color: .purple, size: 0.05)
//        add(x: planeAnchor.transform.columns.3.x + 0.2,
//            y: planeAnchor.transform.columns.3.y,
//            z: planeAnchor.transform.columns.3.z,
//            color: .purple, size: 0.05)



        node.addChildNode(planeNode)
        map.addElement(newElement: planeAnchor)
        map.addElement(newElement: planeNode)
        if floorLevel == 100.0 { floorLevel = anchor.transform.columns.3.y }
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }

        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)

        plane.width = CGFloat(planeAnchor.extent.x)
        plane.height = CGFloat(planeAnchor.extent.z)

        map.addElement(newElement: planeAnchor)
        if map.floorLevel < self.floorLevel { self.floorLevel = map.floorLevel }
        updateStateLabel()
    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let anchorPlane = anchor as? ARPlaneAnchor else { return }
        print("Plane Anchor was removed!", anchorPlane.extent)
    }

    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        guard let pointOfView = sceneView.pointOfView else { return }
        let transform = pointOfView.transform
        self.currentLocation = SCNVector3(transform.m41, transform.m42, transform.m43)
        if let quat = self.sceneView.pointOfView?.presentation.worldOrientation {
            let roll = atan2(2*(quat.y*quat.w - quat.x*quat.z), 1 - 2*quat.y*quat.y - 2*quat.z*quat.z)
//            let myPitch = GLKMathRadiansToDegrees(atan2(2*(quat.x*quat.w + quat.y*quat.z), 1 - 2*quat.x*quat.x - 2*quat.z*quat.z))
//            let myYaw = GLKMathRadiansToDegrees(asin(2*quat.x*quat.y + 2*quat.w*quat.z))
            self.currentPositionOfCamera = CGFloat(roll)
        }
    }

    // MARK: - ARSessionDelegate

    // Pass camera frames received from ARKit to Vision (when not already processing one)
    /// - Tag: ConsumeARFrames
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Do not enqueue other buffers for processing while another Vision task is still running.
        // The camera stream has only a finite amount of buffers available; holding too many buffers for analysis would starve the camera.
        guard currentBuffer == nil, case .normal = frame.camera.trackingState else {
            return
        }

        // Retain the image buffer for Vision processing.
        self.currentBuffer = frame.capturedImage
        classifyCurrentImage()
    }

    // MARK: - Vision classification

    // Vision classification request and model
    /// - Tag: ClassificationRequest
    private lazy var classificationRequest: VNCoreMLRequest = {
        do {
            // Instantiate the model from its generated Swift class.
            let model = try VNCoreMLModel(for: Inceptionv3().model)
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })

            // Crop input images to square area at center, matching the way the ML model was trained.
            request.imageCropAndScaleOption = .centerCrop

            // Use CPU for Vision processing to ensure that there are adequate GPU resources for rendering.
            request.usesCPUOnly = true

            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()

    // The pixel buffer being held for analysis; used to serialize Vision requests.
    private var currentBuffer: CVPixelBuffer?
    private var currentOrientation: vector_float3?
    private var currentLocation: SCNVector3?

    // Queue for dispatching vision classification requests
    private let visionQueue = DispatchQueue(label: "com.example.apple-samplecode.ARKitVision.serialVisionQueue")

    // Run the Vision+ML classifier on the current image buffer.
    /// - Tag: ClassifyCurrentImage
    private func classifyCurrentImage() {
        // Most computer vision tasks are not rotation agnostic so it is important to pass in the orientation of the image with respect to device.
        let orientation = CGImagePropertyOrientation(UIDevice.current.orientation)

        let requestHandler = VNImageRequestHandler(cvPixelBuffer: currentBuffer!, orientation: orientation)
        visionQueue.async {
            do {
                // Release the pixel buffer when done, allowing the next buffer to be processed.
                defer { self.currentBuffer = nil }
                try requestHandler.perform([self.classificationRequest])
            } catch {
                print("Error: Vision request failed with error \"\(error)\"")
            }
        }
    }

    // Classification results
    private var identifierString = ""
    private var confidence: VNConfidence = 0.0

    // Handle completion of the Vision request and choose results to display.
    /// - Tag: ProcessClassifications
    func processClassifications(for request: VNRequest, error: Error?) {
        guard let results = request.results else {
            print("Unable to classify image.\n\(error!.localizedDescription)")
            return
        }
        // The `results` will always be `VNClassificationObservation`s, as specified by the Core ML model in this project.
        let classifications = results as! [VNClassificationObservation]

        // Show a label for the highest-confidence result (but only above a minimum confidence threshold).
        if let bestResult = classifications.first(where: { result in result.confidence > 0.5 }),
            let label = bestResult.identifier.split(separator: ",").first {
            identifierString = String(label)
            confidence = bestResult.confidence
        } else {
            identifierString = ""
            confidence = 0
        }

        DispatchQueue.main.async { [weak self] in
            self?.displayClassifierResults()
        }
    }

    // Show the classification results in the UI.
    private func displayClassifierResults() {
        guard !self.identifierString.isEmpty else {
            return // No object was classified.
        }
        let message = String(format: "Detected \(self.identifierString) with %.2f", self.confidence * 100) + "% confidence"
        statusViewController.showMessage(message)

        if self.identifierString == "Granny Smith" && self.confidence * 100 > 90 && appleIsNotFound {
            let center = self.sceneView.hitTest(CGPoint(x: self.sceneView.accessibilityFrame.width/2, y: self.sceneView.accessibilityFrame.height/2), types: [.featurePoint, .estimatedHorizontalPlane])
            if let result = center.first {

                // Add a new anchor at the tap location.
                let anchor = ARAnchor(transform: result.worldTransform)
                //sceneView.session.add(anchor: anchor)

                // Track anchor ID to associate text with the anchor after ARKit creates a corresponding SKNode.
                map.addElement(newElement: anchor)
                //appleIsNotFound = false
            }
        }
    }

    // MARK: - AR Session Handling

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        statusViewController.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)

        switch camera.trackingState {
        case .notAvailable, .limited:
            statusViewController.escalateFeedback(for: camera.trackingState, inSeconds: 3.0)
        case .normal:
            statusViewController.cancelScheduledMessage(for: .trackingStateEscalation)
            // Unhide content after successful relocalization.
            setOverlaysHidden(false)
        }
        self.currentOrientation = camera.eulerAngles
        //self.currentLocation = camera.transform
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }

        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]

        // Filter out optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        DispatchQueue.main.async {
            self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
        }
    }

    func sessionWasInterrupted(_ session: ARSession) {
        setOverlaysHidden(true)
    }

    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        /*
         Allow the session to attempt to resume after an interruption.
         This process may not succeed, so the app must be prepared
         to reset the session if the relocalizing status continues
         for a long time -- see `escalateFeedback` in `StatusViewController`.
         */
        return true
    }

    private func setOverlaysHidden(_ shouldHide: Bool) {
        sceneView.scene.rootNode.childNodes.forEach { node in
            if shouldHide {
                // Hide overlay content immediately during relocalization.
                node.runAction(.fadeOut(duration: 0.1))
            } else {
                // Fade overlay content in after relocalization succeeds.
                node.runAction(.fadeIn(duration: 0.5))
            }
        }
    }

    private func restartSession() {
        statusViewController.cancelAllScheduledMessages()
        statusViewController.showMessage("RESTARTING SESSION")

        //map = Map2D()
        map = Map()

        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    // MARK: - Error handling

    private func displayErrorMessage(title: String, message: String) {
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.restartSession()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }

    func updateStateLabel() {
        DispatchQueue.main.async{
            self.sceneLabel.text = " Floor level: \(self.floorLevel)"
        }
    }

    func addLine(startPosition: SCNVector3, endPosition: SCNVector3) {
        let line = SCNGeometry.line(from: startPosition, to: endPosition)
        let lineNode = SCNNode(geometry: line)
        lineNode.position = SCNVector3Zero
        self.sceneView.scene.rootNode.addChildNode(lineNode)

    }

    func add(x: Float, y: Float, z: Float, color: UIColor, size: CGFloat) {
        let node = SCNNode()
        node.geometry = SCNBox(width: size, height: size, length: size, chamferRadius: size)
        node.geometry?.firstMaterial?.diffuse.contents = color
        node.position = SCNVector3(x,y,z)
        node.name = "map"
        self.sceneView.scene.rootNode.addChildNode(node)
    }

    func clear() {
        for node in self.sceneView.scene.rootNode.childNodes {
            if node.name == "map" {
                node.removeFromParentNode()
            }
        }
    }

    func refresh() {
        for element in map.mapGrid.values {
            if element.confidence > confidenceThreshold {
                add(x: element.x, y: element.y, z: element.z, color: element.getElementColor(), size: 0.01)
            }
        }
    }

    // MARK: - IBActions

    @IBAction func showMapPreview(_ sender: Any) {
        if mapPreviewButton.isHidden {
            mapPreviewButton.isHidden = false
            mapPreView.alpha = 1
        } else {
            mapPreviewButton.isHidden = true
            mapPreView.alpha = 0
        }
    }

    @IBAction func showMap(_ sender: Any) {
        clear()
        map.fillFloor()
        refresh()
    }

    // MARK: - Delegate functions

    func getGridSize() -> Float {
        return map.gridSize
    }

    func getFloorPoints() -> [MapElement] {
        return map.getFloor()
    }

    func getWallPoints() -> [MapElement] {
        return map.getWall()
    }

    func getObjectPoints() -> [MapElement] {
        return map.getObjects()
    }

    func getMapElements(onlyNew: Bool = false) -> [MapElement] {
        return map.getMap(onlyNew: onlyNew)
    }

    func getCameraLocation() -> SCNVector3? {
        return self.currentLocation
    }

    func getCurrentPositionOfCamera() -> CGFloat {
        return self.currentPositionOfCamera
    }


}

extension SCNGeometry {
    class func line(from vector1: SCNVector3, to vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        return SCNGeometry(sources: [source], elements: [element])
    }
}
