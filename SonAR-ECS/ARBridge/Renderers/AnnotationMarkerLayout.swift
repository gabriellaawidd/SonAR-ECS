//
//  AnnotationMarkerLayout.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 17/08/26.
//

import RealityKit
import UIKit
import simd

enum AnnotationMarkerLayout {
    static let width: Float = 0.052
    static let tapZoneRadius: Float = 0.13

    static let canvasWidth: CGFloat = 402
    static let bodyHeight: CGFloat = 100
    static let tailHeight: CGFloat = 37
    static let tailHalfWidth: CGFloat = 26
    static let cornerRadius: CGFloat = 26

    static var aspect: Float {
        Float((bodyHeight + tailHeight) / canvasWidth)
    }
}

enum AnnotationMarker {
    static let entityName = "annotationMarker"
    static let tapZoneName = "annotationTapZone"

    static func makeEntity() -> ModelEntity? {
        guard let image = render(), let cgImage = image.cgImage else { return nil }

        let texture = try? TextureResource(
            image: cgImage,
            withName: nil,
            options: .init(semantic: .color)
        )

        var material = UnlitMaterial()
        if let texture {
            material.color = .init(tint: .white, texture: .init(texture))
        } else {
            material.color = .init(tint: .white)
        }
        material.blending = .transparent(opacity: 1.0)
        material.faceCulling = .none

        let aspect = Float(image.size.height / image.size.width)
        let mesh = MeshResource.generatePlane(
            width: AnnotationMarkerLayout.width,
            height: AnnotationMarkerLayout.width * aspect
        )
        let marker = ModelEntity(mesh: mesh, materials: [material])
        marker.name = entityName
        marker.generateCollisionShapes(recursive: false)

        let tapZone = Entity()
        tapZone.name = tapZoneName
        tapZone.components.set(CollisionComponent(
            shapes: [.generateSphere(radius: AnnotationMarkerLayout.tapZoneRadius)]
        ))
        marker.addChild(tapZone)

        return marker
    }

    static func isTappable(_ entity: Entity) -> Bool {
        var current: Entity? = entity
        while let node = current {
            if node.name == entityName || node.name == tapZoneName {
                return true
            }
            current = node.parent
        }
        return false
    }

    private static func render() -> UIImage? {
        let w = AnnotationMarkerLayout.canvasWidth
        let h = AnnotationMarkerLayout.bodyHeight
        let tailHeight = AnnotationMarkerLayout.tailHeight
        let tailHalfWidth = AnnotationMarkerLayout.tailHalfWidth
        let r = min(AnnotationMarkerLayout.cornerRadius, min(w, h) / 2)

        let size = CGSize(width: w, height: h + tailHeight)
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = 1

        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let tipX = w / 2
            let tipY = h + tailHeight
            let baseLeft = tipX - tailHalfWidth
            let baseRight = tipX + tailHalfWidth

            let bubble = UIBezierPath()
            bubble.move(to: CGPoint(x: r, y: 0))
            bubble.addLine(to: CGPoint(x: w - r, y: 0))
            bubble.addArc(
                withCenter: CGPoint(x: w - r, y: r), radius: r,
                startAngle: -.pi / 2, endAngle: 0, clockwise: true
            )
            bubble.addLine(to: CGPoint(x: w, y: h - r))
            bubble.addArc(
                withCenter: CGPoint(x: w - r, y: h - r), radius: r,
                startAngle: 0, endAngle: .pi / 2, clockwise: true
            )
            bubble.addLine(to: CGPoint(x: baseRight, y: h))
            bubble.addLine(to: CGPoint(x: tipX, y: tipY))
            bubble.addLine(to: CGPoint(x: baseLeft, y: h))
            bubble.addLine(to: CGPoint(x: r, y: h))
            bubble.addArc(
                withCenter: CGPoint(x: r, y: h - r), radius: r,
                startAngle: .pi / 2, endAngle: .pi, clockwise: true
            )
            bubble.addLine(to: CGPoint(x: 0, y: r))
            bubble.addArc(
                withCenter: CGPoint(x: r, y: r), radius: r,
                startAngle: .pi, endAngle: 3 * .pi / 2, clockwise: true
            )
            bubble.close()

            context.cgContext.setShadow(
                offset: CGSize(width: 0, height: 4),
                blur: 14,
                color: UIColor.black.withAlphaComponent(0.25).cgColor
            )
            UIColor(red: 0xF7 / 255, green: 0xF4 / 255, blue: 0xEE / 255, alpha: 1).setFill()
            bubble.fill()
            context.cgContext.setShadow(offset: .zero, blur: 0, color: nil)

            let text = "?" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 58, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            let textSize = text.size(withAttributes: attributes)
            text.draw(
                at: CGPoint(
                    x: w / 2 - textSize.width / 2,
                    y: h / 2 - textSize.height / 2
                ),
                withAttributes: attributes
            )
        }
    }
}
