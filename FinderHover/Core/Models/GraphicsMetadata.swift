//
//  GraphicsMetadata.swift
//  FinderHover
//
//  Graphics-related metadata structures (Vector, PSD, 3D Model)
//

import Foundation

// MARK: - Vector Graphics Metadata Structure
struct VectorGraphicsMetadata {
    let format: String?           // Format type (SVG, EPS, AI, etc.)
    let dimensions: String?       // Width x Height
    let viewBox: String?          // ViewBox for SVG
    let elementCount: Int?        // Number of paths/shapes
    let colorMode: String?        // Color mode (RGB, CMYK, etc.)
    let creator: String?          // Creator application
    let version: String?          // Format version (e.g., SVG 1.1)

    var hasData: Bool {
        return format != nil || dimensions != nil || viewBox != nil ||
               elementCount != nil || colorMode != nil || creator != nil || version != nil
    }
}

// MARK: - PSD Metadata Structure
struct PSDMetadata {
    let layerCount: Int?
    let colorMode: String?         // RGB, CMYK, Grayscale, etc.
    let bitDepth: Int?
    let resolution: String?        // e.g., "300 DPI"
    let hasTransparency: Bool?
    let dimensions: String?

    var hasData: Bool {
        return layerCount != nil || colorMode != nil || bitDepth != nil ||
               resolution != nil || hasTransparency != nil || dimensions != nil
    }
}

// MARK: - 3D Model Metadata Structure
struct Model3DMetadata {
    let format: String?               // USDZ, OBJ, FBX, GLTF
    let vertexCount: Int?             // Number of vertices
    let faceCount: Int?               // Number of faces
    let meshCount: Int?               // Number of meshes
    let materialCount: Int?           // Number of materials
    let animationCount: Int?          // Number of animations
    let hasSkeleton: Bool?            // Has skeleton/armature
    let boundingBox: String?          // Bounding box dimensions

    var hasData: Bool {
        return format != nil ||
               vertexCount != nil ||
               faceCount != nil ||
               meshCount != nil ||
               materialCount != nil ||
               animationCount != nil ||
               hasSkeleton != nil ||
               boundingBox != nil
    }
}
