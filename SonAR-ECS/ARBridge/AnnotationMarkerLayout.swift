//
//  AnnotationMarker.swift
//  SonAR
//
//  Created by Tiffany Michelle on 13/08/26.
//
import RealityKit
import UIKit
import simd

enum AnnotationMarkerLayout {
    static let diameter: Float = 0.03
    static let tapZoneRadius: Float = 0.26

    // heightAboveSensor, bobHeight, bobDuration DIHAPUS dari sini —
    // sudah dipindah jadi konstanta di AnnotationDisplaySystem
    // (heightAboveSensor) dan langsung di-pass ke BobbingComponent
    // (bobHeight, bobDuration). Dua-duanya sudah tidak dipakai dari
    // tempat ini lagi, jadi dihapus supaya tidak ada 2 sumber kebenaran.
}

enum AnnotationMarker {
    static let entityName = "annotationMarker"
    static let tapZoneName = "annotationTapZone"

    static func makeEntity() -> ModelEntity? {
        guard let cgImage = render()?.cgImage else { return nil }
        do {
            let texture = try TextureResource.generate(
                from: cgImage,
                withName: nil,
                options: .init(semantic: .color)
            )
            var material = UnlitMaterial()
            material.color = .init(tint: .white, texture: .init(texture))
            material.blending = .transparent(opacity: 1.0)
            material.faceCulling = .none
            let mesh = MeshResource.generatePlane(
                width: AnnotationMarkerLayout.diameter,
                height: AnnotationMarkerLayout.diameter
            )
            let marker = ModelEntity(mesh: mesh, materials: [material])
            marker.name = entityName
            marker.generateCollisionShapes(recursive: false)
            return marker
        } catch {
            print("[AnnotationMarker] Gagal membuat tekstur: \(error.localizedDescription)")
            return nil
        }
    }

    static func makeTapZone() -> ModelEntity {
        let zone = ModelEntity(
            mesh: .generateSphere(radius: AnnotationMarkerLayout.tapZoneRadius),
            materials: [UnlitMaterial(color: .clear)]
        )
        zone.name = tapZoneName
        zone.generateCollisionShapes(recursive: false)
        zone.components.remove(ModelComponent.self)
        return zone
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
        let side: CGFloat = 240
        let size = CGSize(width: side, height: side)
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let inset: CGFloat = 12
            let circle = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)
            context.cgContext.setShadow(
                offset: .zero,
                blur: 18,
                color: UIColor.black.withAlphaComponent(0.35).cgColor
            )
            UIColor.white.setFill()
            UIBezierPath(ovalIn: circle).fill()
            context.cgContext.setShadow(offset: .zero, blur: 0, color: nil)
            let text = "?" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 128, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            let textSize = text.size(withAttributes: attributes)
            text.draw(
                at: CGPoint(
                    x: circle.midX - textSize.width / 2,
                    y: circle.midY - textSize.height / 2
                ),
                withAttributes: attributes
            )
        }
    }
}