import SwiftUI
import SceneKit

struct MinimalRotatingLightSphere: UIViewRepresentable {
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.backgroundColor = .clear
        
        let scene = SCNScene()
        
        // Esfera amarela
        let sphere = SCNSphere(radius: 1.0)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white
        material.specular.contents = UIColor.white
        sphere.firstMaterial = material
        
        let sphereNode = SCNNode(geometry: sphere)
        scene.rootNode.addChildNode(sphereNode)
        
        // Luz
        let lightNode = SCNNode()
        let light = SCNLight()
        light.type = .omni
        light.color = UIColor.white
        light.intensity = 1000
        
        lightNode.light = light
        lightNode.position = SCNVector3(4, 3, 0)
        scene.rootNode.addChildNode(lightNode)
        
        // Câmera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 4)
        scene.rootNode.addChildNode(cameraNode)
        
        sceneView.scene = scene
        
        // Rotação horizontal da luz
        let orbitNode = SCNNode()
        orbitNode.addChildNode(lightNode)
        lightNode.position = SCNVector3(4, 2, 0)
        scene.rootNode.addChildNode(orbitNode)
        
        let rotateAction = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 10)
        let repeatRotation = SCNAction.repeatForever(rotateAction)
        orbitNode.runAction(repeatRotation)
        
        // Luz sempre olha para esfera
        let lookAt = SCNLookAtConstraint(target: sphereNode)
        lightNode.constraints = [lookAt]
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
}

// View final simplificada
struct SimpleYellowSphereView: View {
    var body: some View {
        MinimalRotatingLightSphere()
//            .frame(width: 250, height: 250)
    }
}

#Preview {
    ZStack {
//        LinearGradient(colors: [Color.black, Color.gray.opacity(0.1)], startPoint: .top, endPoint: .bottom)
//            .ignoresSafeArea()
        SimpleYellowSphereView()
            .ignoresSafeArea()
    }
}
