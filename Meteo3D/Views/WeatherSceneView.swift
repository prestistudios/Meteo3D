import SceneKit
import SwiftUI

struct WeatherSceneView: UIViewRepresentable {
    let kind: WeatherKind
    let isDay: Bool

    private let popPalette: [UIColor] = [
        UIColor(red: 0.98, green: 0.43, blue: 0.08, alpha: 1),
        UIColor(red: 1.00, green: 0.80, blue: 0.08, alpha: 1),
        UIColor(red: 0.98, green: 0.67, blue: 0.73, alpha: 1),
        UIColor(red: 0.25, green: 0.83, blue: 0.70, alpha: 1),
        UIColor(red: 0.18, green: 0.34, blue: 0.94, alpha: 1),
        UIColor(red: 0.48, green: 0.25, blue: 0.86, alpha: 1)
    ]

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
        ambient.light?.intensity = isDay ? 720 : 430
        ambient.light?.color = isDay
            ? UIColor(red: 1, green: 0.86, blue: 0.74, alpha: 1)
            : UIColor(red: 0.35, green: 0.42, blue: 1, alpha: 1)
        scene.rootNode.addChildNode(ambient)

        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .omni
        key.light?.intensity = 1_250
        key.light?.color = UIColor(red: 1, green: 0.72, blue: 0.42, alpha: 1)
        key.position = SCNVector3(-3, 4, 5)
        scene.rootNode.addChildNode(key)

        let rim = SCNNode()
        rim.light = SCNLight()
        rim.light?.type = .omni
        rim.light?.intensity = 850
        rim.light?.color = UIColor(red: 0.28, green: 0.86, blue: 0.92, alpha: 1)
        rim.position = SCNVector3(3, 1.5, 2)
        scene.rootNode.addChildNode(rim)

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
        sphere.firstMaterial = material(
            color: UIColor(red: 0.12, green: 0.20, blue: 0.72, alpha: 1),
            roughness: 0.58
        )
        let node = SCNNode(geometry: sphere)
        node.position = SCNVector3(0, -5.5, 0)
        scene.rootNode.addChildNode(node)

        for index in 0..<4 {
            let ring = SCNTorus(
                ringRadius: CGFloat(1.35 + Double(index) * 0.68),
                pipeRadius: CGFloat(0.10 + Double(index) * 0.012)
            )
            ring.firstMaterial = material(
                color: popPalette[(index + 2) % popPalette.count],
                roughness: 0.45,
                emission: 0.12
            )
            let ringNode = SCNNode(geometry: ring)
            ringNode.eulerAngles.x = .pi / 2
            ringNode.position = SCNVector3(0, -0.82 - Float(index) * 0.11, 0.15)
            ringNode.scale = SCNVector3(1, 0.28, 1)
            ringNode.runAction(.repeatForever(.rotateBy(
                x: 0,
                y: 0,
                z: index.isMultiple(of: 2) ? .pi * 2 : -.pi * 2,
                duration: 14 + Double(index) * 3
            )))
            scene.rootNode.addChildNode(ringNode)
        }
    }

    private func addSun(to scene: SCNScene, moon: Bool) {
        let sun = SCNNode()
        let geometry = SCNSphere(radius: moon ? 0.68 : 0.78)
        geometry.segmentCount = 64
        geometry.firstMaterial = material(
            color: moon ? popPalette[2] : popPalette[1],
            roughness: 0.34,
            emission: 0.28
        )
        sun.addChildNode(SCNNode(geometry: geometry))

        for index in 0..<12 {
            let ray = SCNCapsule(capRadius: 0.11, height: 0.52)
            ray.firstMaterial = material(
                color: popPalette[index.isMultiple(of: 3) ? 0 : 1],
                roughness: 0.42,
                emission: 0.12
            )
            let rayNode = SCNNode(geometry: ray)
            let angle = Float(index) / 12 * .pi * 2
            rayNode.position = SCNVector3(sin(angle) * 1.04, cos(angle) * 1.04, 0)
            rayNode.eulerAngles.z = -angle
            sun.addChildNode(rayNode)
        }
        sun.position = SCNVector3(0.65, 0.9, -0.25)
        sun.runAction(.repeatForever(.group([
            .rotateBy(x: 0, y: 0, z: .pi * 2, duration: 24),
            .sequence([
                .scale(to: 1.06, duration: 1.8),
                .scale(to: 0.96, duration: 1.8)
            ])
        ])))
        scene.rootNode.addChildNode(sun)
    }

    private func addClouds(to scene: SCNScene, count: Int, low: Bool = false) {
        for index in 0..<count {
            let cloud = SCNNode()
            let modules: [(SCNVector3, SCNVector3)] = [
                (SCNVector3(-0.78, -0.18, 0.05), SCNVector3(1.55, 0.72, 0.72)),
                (SCNVector3(0, -0.22, 0.18), SCNVector3(1.8, 0.82, 0.78)),
                (SCNVector3(0.82, -0.16, 0.02), SCNVector3(1.4, 0.68, 0.68)),
                (SCNVector3(-0.42, 0.36, -0.04), SCNVector3(1.12, 0.94, 0.88)),
                (SCNVector3(0.32, 0.45, 0.08), SCNVector3(1.34, 1.05, 0.92)),
                (SCNVector3(0.72, 0.25, 0.20), SCNVector3(0.88, 0.76, 0.72))
            ]
            for (part, module) in modules.enumerated() {
                let capsule = SCNCapsule(capRadius: 0.34, height: 0.84)
                let baseColor = part == 1 || part == 4
                    ? UIColor(red: 1, green: 0.90, blue: 0.78, alpha: low ? 0.72 : 1)
                    : popPalette[(part + index * 2) % popPalette.count].withAlphaComponent(low ? 0.68 : 1)
                capsule.firstMaterial = material(
                    color: baseColor,
                    roughness: 0.52,
                    emission: low ? 0.03 : 0.08
                )
                let pebble = SCNNode(geometry: capsule)
                pebble.position = module.0
                pebble.eulerAngles.z = .pi / 2
                pebble.scale = module.1
                let pulse = 1.025 + CGFloat(part % 3) * 0.012
                pebble.runAction(.repeatForever(.sequence([
                    .scale(by: pulse, duration: 1.3 + Double(part) * 0.1),
                    .scale(by: 1 / pulse, duration: 1.3 + Double(part) * 0.1)
                ])))
                cloud.addChildNode(pebble)
            }
            cloud.position = SCNVector3(
                Float(index - count / 2) * 1.48,
                low ? Float(index % 2) * 0.24 - 0.28 : Float(index % 2) * 0.46 + 0.38,
                Float(index % 3) * -0.72
            )
            let scale = 0.74 - Float(index % 3) * 0.06
            cloud.scale = SCNVector3(scale, scale, scale)
            cloud.runAction(.repeatForever(.group([
                .sequence([
                    .moveBy(x: 0.28, y: 0.08, z: 0, duration: 2.6 + Double(index) * 0.22),
                    .moveBy(x: -0.28, y: -0.08, z: 0, duration: 2.6 + Double(index) * 0.22)
                ]),
                .sequence([
                    .rotateBy(x: 0.025, y: 0.08, z: -0.018, duration: 2.2),
                    .rotateBy(x: -0.025, y: -0.08, z: 0.018, duration: 2.2)
                ])
            ])))
            scene.rootNode.addChildNode(cloud)
        }
    }

    private func addPrecipitation(to scene: SCNScene, snow: Bool) {
        for index in 0..<34 {
            let geometry = SCNSphere(radius: snow ? 0.07 : 0.055 + CGFloat(index % 3) * 0.012)
            geometry.segmentCount = 20
            geometry.firstMaterial = material(
                color: snow
                    ? popPalette[(index + 2) % popPalette.count]
                    : popPalette[(index + 3) % popPalette.count],
                roughness: 0.26,
                emission: 0.24
            )
            let drop = SCNNode(geometry: geometry)
            let x = Float((index * 37) % 100) / 22 - 2.25
            let y = Float((index * 53) % 100) / 30 - 1
            let z = Float((index * 29) % 100) / 50 - 1
            drop.position = SCNVector3(x, y, z)
            let distance: CGFloat = snow ? -3.5 : -5
            let duration = snow ? 3.2 + Double(index % 5) * 0.2 : 1.0 + Double(index % 4) * 0.1
            drop.runAction(.repeatForever(.sequence([
                .group([
                    .moveBy(x: snow ? 0.35 : 0.08, y: distance, z: 0, duration: duration),
                    .scale(to: 0.6, duration: duration)
                ]),
                .group([
                    .moveBy(x: snow ? -0.35 : -0.08, y: -distance, z: 0, duration: 0),
                    .scale(to: 1, duration: 0)
                ])
            ])))
            scene.rootNode.addChildNode(drop)
        }
    }

    private func addLightning(to scene: SCNScene) {
        let bolt = SCNBox(width: 0.09, height: 1.6, length: 0.05, chamferRadius: 0.03)
        bolt.firstMaterial = material(color: popPalette[1], roughness: 0.18, emission: 0.75)
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

    private func material(
        color: UIColor,
        roughness: CGFloat,
        emission: CGFloat = 0
    ) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = color
        material.metalness.contents = 0.04
        material.roughness.contents = roughness
        if emission > 0 {
            material.emission.contents = color.withAlphaComponent(emission)
            material.emission.intensity = emission
        }
        return material
    }
}
