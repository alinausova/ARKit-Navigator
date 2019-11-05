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
    @IBOutlet weak var mapPreView: UIView!
    @IBOutlet weak var mapPreviewButton: UIButton!

    // Controller for tracking state and recognition result representation
    private lazy var statusViewController: StatusViewController = {
        return children.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()
    
    let configuration = ARWorldTrackingConfiguration()
    var isFloorInitialized = false
    var currentPositionOfCamera: CGFloat = 0
    var needPathUpdate = false
    let pathBuilder = AStarPathFinder()

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

    // Prepare for view transition
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nav = segue.destination as? MapViewController {
            nav.delegate = self
        }
        if let nav = segue.destination as? MapPreViewController {
            nav.delegate = self
        }
    }

    // MARK: - Plane Anchors processing

    // Add new planeAnchor to ARView and load it to the map
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

        if !isFloorInitialized && planeAnchor.alignment == .horizontal {
            map.setFloor(floorLevel: planeAnchor.transform.columns.3.y)
            isFloorInitialized = true
        }

        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode(geometry: plane)
        planeNode.simdPosition = SIMD3(planeAnchor.center.x, 0, planeAnchor.center.z)

        planeNode.eulerAngles.x = -.pi / 2
        planeNode.opacity = 0.1

        node.addChildNode(planeNode)
        map.addElement(newElement: planeAnchor)
    }

    // Update planeAnchor in ARView and load it to the map
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }

        planeNode.simdPosition = SIMD3(planeAnchor.center.x, 0, planeAnchor.center.z)

        plane.width = CGFloat(planeAnchor.extent.x)
        plane.height = CGFloat(planeAnchor.extent.z)

        map.addElement(newElement: planeAnchor)
    }

    // Remove planeAnchor from ARView
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let anchorPlane = anchor as? ARPlaneAnchor else { return }
        print("Plane Anchor was removed!", anchorPlane.extent)
    }

    // Update phone location and position of camera
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let pointOfView = sceneView.pointOfView else { return }
        self.currentLocation = SCNVector3(pointOfView.transform.m41, pointOfView.transform.m42, pointOfView.transform.m43)
        if let quat = self.sceneView.pointOfView?.presentation.worldOrientation {
            let roll = atan2(2*(quat.y*quat.w - quat.x*quat.z), 1 - 2*quat.y*quat.y - 2*quat.z*quat.z)
            self.currentPositionOfCamera = CGFloat(roll)

            // Camera's pitch and yaw calculating
            //let pitch = GLKMathRadiansToDegrees(atan2(2*(quat.x*quat.w + quat.y*quat.z), 1 - 2*quat.x*quat.x - 2*quat.z*quat.z))
            //let yaw = GLKMathRadiansToDegrees(asin(2*quat.x*quat.y + 2*quat.w*quat.z))
        }
    }

    // MARK: - ARSessionDelegate

    // Pass camera frames received from ARKit to Vision (when not already processing one)
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard currentBuffer == nil, case .normal = frame.camera.trackingState else {
            return
        }
        // Retain the image buffer for Vision processing.
        self.currentBuffer = frame.capturedImage
        classifyCurrentImage()
    }

    // MARK: - Vision classification

    // Vision classification request and model
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
    private func classifyCurrentImage() {
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
    func processClassifications(for request: VNRequest, error: Error?) {
        guard let results = request.results else {
            print("Unable to classify image.\n\(error!.localizedDescription)")
            return
        }
        let classifications = results as! [VNClassificationObservation]

        // Show a label for the highest-confidence result (but only above a minimum confidence threshold)
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

    // Show the classification results in the UI and adding detected object to the map
    private func displayClassifierResults() {
        guard !self.identifierString.isEmpty else {
            return // No object was classified.
        }
        let message = String(format: "Detected \(self.identifierString) with %.2f", self.confidence * 100) + "% confidence"
        statusViewController.showMessage(message)

        if self.identifierString == "Granny Smith" && self.confidence * 100 > 90 {
            let center = self.sceneView.hitTest(CGPoint(x: self.sceneView.accessibilityFrame.width/2, y: self.sceneView.accessibilityFrame.height/2), types: [.featurePoint, .estimatedHorizontalPlane])
            if let result = center.first {
                // Add a new anchor location.
                let anchor = ARAnchor(transform: result.worldTransform)
                // Add an object to the map
                map.addObjectToGrid(newElement: anchor, name: self.identifierString)
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
            setOverlaysHidden(false)
        }
        self.currentOrientation = camera.eulerAngles
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }

        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]

        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        DispatchQueue.main.async {
            self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
        }
    }

    func sessionWasInterrupted(_ session: ARSession) {
        setOverlaysHidden(true)
    }

    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
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

    // MARK: - Add virtual elements to the view

    /// Add line connecting two points
    func addLine(startPosition: SCNVector3, endPosition: SCNVector3) {
        let line = SCNGeometry.line(from: startPosition, to: endPosition)
        let lineNode = SCNNode(geometry: line)
        lineNode.position = SCNVector3Zero
        self.sceneView.scene.rootNode.addChildNode(lineNode)

    }

    /// Add an SCNNode for map element representation
    func add(x: Float, y: Float, z: Float, color: UIColor, size: CGFloat) {
        let node = SCNNode()
        node.geometry = SCNBox(width: size, height: size, length: size, chamferRadius: size)
        node.geometry?.firstMaterial?.diffuse.contents = color
        node.position = SCNVector3(x,y,z)
        node.name = "map"
        self.sceneView.scene.rootNode.addChildNode(node)
    }

    /// Add an SCNNode for path element representation
    func add(position: SCNVector3) {
        let node = SCNNode()
        let size: CGFloat = 0.02
        node.geometry = SCNBox(width: size, height: size, length: size, chamferRadius: size)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        node.position = position
        node.name = "path"
        self.sceneView.scene.rootNode.addChildNode(node)
    }

    /// Clear ARScene
    func clear() {
        for node in self.sceneView.scene.rootNode.childNodes {
            if node.name == "map" {
                node.removeFromParentNode()
            }
        }
    }

    /// Remove path elements
    func clearPath() {
        for node in self.sceneView.scene.rootNode.childNodes {
            if node.name == "path" {
                node.removeFromParentNode()
            }
        }
    }

    /// Refresh AR map elements visualization
    func refresh() {
        clear()
        clearPath()
        for element in map.mapGrid.values {
            if element.confidence > map.confidenceThreshold {
                add(x: element.x, y: element.y, z: element.z, color: element.color, size: 0.01)
            }
        }
    }

    // MARK: - IBActions

    @IBAction func showMapPreview(_ sender: Any) {
        if mapPreviewButton.isHidden {
            mapPreView.alpha = 1
        } else {
            mapPreView.alpha = 0
        }
        mapPreviewButton.isHidden.toggle()
    }

    @IBAction func showMap(_ sender: Any) {
        clear()
        refresh()
    }
    
    @IBAction func findPathToExplore(_ sender: Any) {
        clearPath()
        let path = getPathToFarPoint()
        for point in path {
            add(position: SCNVector3(point.x, 0, point.z))
        }
    }

    @IBAction func clearScene(_ sender: Any) {
        self.sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
    }

    @IBAction func findObject(_ sender: Any) {
       // clearScene(self)
        clearPath()
        let path = getPathToObject(objectName: "Granny Smith")
        for point in path {
            add(position: SCNVector3(point.x, 0, point.z))
        }
    }

    // MARK: - Path finding
    /// Get shortest path to the object by its name
    func getPathToObject (objectName: String) -> [vector_float3] {
        if let mapElement = map.getObject(objectName: objectName),
            let start = self.currentLocation {
            let path =  self.pathBuilder.findPath(from: vector_float3(round(start.x / map.gridSize) * map.gridSize,
                                                            map.floorLevel,
                                                            round(start.y / map.gridSize) * map.gridSize),
                                        to: vector_float3(mapElement.x, map.floorLevel, mapElement.z), map: map)
            map.addPath(path: path)
            needPathUpdate = true
            return path
        }
        return []
    }

    /// Get shortest path to the furthest point on the map
    func getPathToFarPoint () -> [vector_float3] {
        if let start = self.currentLocation {
            let end = pathBuilder.getFurthestPoint(start:  vector_float3(start), map: map)
            let path =  self.pathBuilder.findPath(from: vector_float3(round(start.x / map.gridSize) * map.gridSize,
                                                                      map.floorLevel,
                                                                      round(start.y / map.gridSize) * map.gridSize),
                                                  to: end, map: map)
            map.addPath(path: path)
            map.toOld()
            needPathUpdate = true
            return path
        }
        return []
    }

    // MARK: - Map View delegate functions

    func getGridSize() -> Float {
        return map.gridSize
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

    func isPathUpdateNeeded() -> Bool {
        if needPathUpdate {
            needPathUpdate = false
            return true
        } else {
            return false
        }
    }

    func getNewPath() -> [vector_float3] {
        return map.path
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
