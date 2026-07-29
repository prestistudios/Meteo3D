import SceneKit
import SwiftUI

struct WeatherSceneView: UIViewRepresentable {
    let kind: WeatherKind
    let isDay: Bool

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling4X
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = false
        view.scene = makeScene()
        view.isPlaying = true
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        view.scene = makeScene()
        view.isPlaying = true
    }

    private func makeScene() -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.clear

        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.fieldOfView = 48
        camera.position = SCNVector3(0, 0.3, 8)
        scene.rootNode.addChildNode(camera)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = isDay ? 650 : 300
        ambient.light?.color = isDay ? UIColor.white : UIColor.systemIndigo
        scene.rootNode.addChildNode(ambient)

        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .omni
        key.light?.intensity = 1_100
        key.position = SCNVector3(-3, 4, 5)
        scene.rootNode.addChildNode(key)

        addGround(to: scene)
        switch kind {
        case .clear:
            addSun(to: scene, moon: !isDay)
        case .partlyCloudy:
            addSun(to: scene, moon: !isDay)
            addClouds(to: scene, count: 2)
        case .cloudy:
            addClouds(to: scene, count: 4)
        case .fog:
            addClouds(to: scene, count: 5, low: true)
        case .rain:
            addClouds(to: scene, count: 3)
            addPrecipitation(to: scene, snow: false)
        case .snow:
            addClouds(to: scene, count: 3)
            addPrecipitation(to: scene, snow: true)
        case .storm:
            addClouds(to: scene, count: 4)
            addPrecipitation(to: scene, snow: false)
            addLightning(to: scene)
        }
        return scene
    }

    private func addGround(to scene: SCNScene) {
        let sphere = SCNSphere(radius: 5)
        sphere.segmentCount = 96
        sphere.firstMaterial?.diffuse.contents = UIColor(red: 0.12, green: 0.27, blue: 0.32, alpha: 1)
        sphere.firstMaterial?.roughness.contents = 0.82
        let node = SCNNode(geometry: sphere)
        node.position = SCNVector3(0, -5.5, 0)
        scene.rootNode.addChildNode(node)
    }

    private func addSun(to scene: SCNScene, moon: Bool) {
        let geometry = SCNSphere(radius: moon ? 0.75 : 0.9)
        geometry.segmentCount = 64
        geometry.firstMaterial?.diffuse.contents = moon ? UIColor.systemGray6 : UIColor.systemYellow
        geometry.firstMaterial?.emission.contents = moon ? UIColor.systemGray3 : UIColor.systemOrange
        let node = SCNNode(geometry: geometry)
        node.position = SCNVector3(0.5, 0.8, 0)
        node.runAction(.repeatForever(.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 18)))
        scene.rootNode.addChildNode(node)
    }

    private func addClouds(to scene: SCNScene, count: Int, low: Bool = false) {
        for index in 0..<count {
            let cloud = SCNNode()
            let positions: [SCNVector3] = [
                SCNVector3(-0.65, 0, 0), SCNVector3(0, 0.18, 0),
                SCNVector3(0.65, 0, 0), SCNVector3(-0.15, -0.15, 0.25)
            ]
            for (part, position) in positions.enumerated() {
                let sphere = SCNSphere(radius: part == 1 ? 0.66 : 0.52)
                sphere.segmentCount = 32
                sphere.firstMaterial?.diffuse.contents = UIColor(
                    white: low ? 0.72 : 0.9 - CGFloat(index) * 0.05,
                    alpha: low ? 0.6 : 0.96
                )
                sphere.firstMaterial?.roughness.contents = 0.95
                let puff = SCNNode(geometry: sphere)
                puff.position = position
                cloud.addChildNode(puff)
            }
            cloud.position = SCNVector3(
                Float(index - count / 2) * 1.25,
                low ? Float(index % 2) * 0.25 - 0.4 : Float(index % 2) * 0.5 + 0.35,
                Float(index % 3) * -0.6
            )
            cloud.scale = SCNVector3(0.85, 0.85, 0.85)
            let drift = SCNAction.sequence([
                .moveBy(x: 0.25, y: 0.03, z: 0, duration: 2.5 + Double(index) * 0.25),
                .moveBy(x: -0.25, y: -0.03, z: 0, duration: 2.5 + Double(index) * 0.25)
            ])
            cloud.runAction(.repeatForever(drift))
            scene.rootNode.addChildNode(cloud)
        }
    }

    private func addPrecipitation(to scene: SCNScene, snow: Bool) {
        for index in 0..<38 {
            let geometry: SCNGeometry = snow
                ? SCNSphere(radius: 0.035)
                : SCNCapsule(capRadius: 0.015, height: 0.32)
            geometry.firstMaterial?.diffuse.contents = snow ? UIColor.white : UIColor.systemCyan
            geometry.firstMaterial?.emission.contents = snow ? UIColor.white : UIColor.systemBlue
            let drop = SCNNode(geometry: geometry)
            let x = Float((index * 37) % 100) / 22 - 2.25
            let y = Float((index * 53) % 100) / 30 - 1
            let z = Float((index * 29) % 100) / 50 - 1
            drop.position = SCNVector3(x, y, z)
            let distance: CGFloat = snow ? -3.5 : -5
            let duration = snow ? 3.2 + Double(index % 5) * 0.2 : 1.15 + Double(index % 4) * 0.08
            drop.runAction(.repeatForever(.sequence([
                .moveBy(x: snow ? 0.35 : 0, y: distance, z: 0, duration: duration),
                .moveBy(x: snow ? -0.35 : 0, y: -distance, z: 0, duration: 0)
            ])))
            scene.rootNode.addChildNode(drop)
        }
    }

    private func addLightning(to scene: SCNScene) {
        let bolt = SCNBox(width: 0.09, height: 1.6, length: 0.05, chamferRadius: 0.03)
        bolt.firstMaterial?.diffuse.contents = UIColor.systemYellow
        bolt.firstMaterial?.emission.contents = UIColor.white
        let node = SCNNode(geometry: bolt)
        node.eulerAngles.z = 0.28
        node.position = SCNVector3(0.2, -0.5, 0.3)
        node.opacity = 0
        node.runAction(.repeatForever(.sequence([
            .fadeIn(duration: 0.05), .fadeOut(duration: 0.12),
            .wait(duration: 2.4), .fadeIn(duration: 0.04),
            .fadeOut(duration: 0.08), .wait(duration: 4)
        ])))
        scene.rootNode.addChildNode(node)
    }
}
