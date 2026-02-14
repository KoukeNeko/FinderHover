//
//  GraphicsExtractor.swift
//  FinderHover
//
//  Graphics-related metadata extraction (Vector, PSD, Model3D)
//

import Foundation

// MARK: - Graphics Metadata Extractor

enum GraphicsExtractor {

    // MARK: - Vector Graphics Metadata Extraction

    static func extractVectorGraphicsMetadata(
        from url: URL,
        policy: FileInfo.MetadataExtractionPolicy = .default,
        noticeRecorder: ((FileInfo.AnalysisNotice) -> Void)? = nil
    ) -> VectorGraphicsMetadata? {
        let ext = url.pathExtension.lowercased()
        let vectorExtensions = ["svg", "eps", "ai", "pdf"]

        guard vectorExtensions.contains(ext) else {
            return nil
        }

        var format: String? = nil
        var dimensions: String? = nil
        var viewBox: String? = nil
        var elementCount: Int? = nil
        var colorMode: String? = nil
        var creator: String? = nil
        var version: String? = nil

        switch ext {
        case "svg":
            format = "SVG"
            if policy.enableLargeFileProtection,
               let size = fileSize(of: url),
               size > policy.largeFileThresholds.vectorTextBytes {
                noticeRecorder?(.largeFileProtection)
                break
            }
            if let content = try? String(contentsOf: url, encoding: .utf8) {
                // Extract viewBox
                if let viewBoxRange = content.range(of: #"viewBox="([^"]+)""#, options: .regularExpression) {
                    viewBox = String(content[viewBoxRange])
                        .replacingOccurrences(of: "viewBox=\"", with: "")
                        .replacingOccurrences(of: "\"", with: "")
                }

                // Extract dimensions
                var width: String? = nil
                var height: String? = nil
                if let widthRange = content.range(of: #"width="([^"]+)""#, options: .regularExpression) {
                    width = String(content[widthRange])
                        .replacingOccurrences(of: "width=\"", with: "")
                        .replacingOccurrences(of: "\"", with: "")
                }
                if let heightRange = content.range(of: #"height="([^"]+)""#, options: .regularExpression) {
                    height = String(content[heightRange])
                        .replacingOccurrences(of: "height=\"", with: "")
                        .replacingOccurrences(of: "\"", with: "")
                }
                if let w = width, let h = height {
                    dimensions = "\(w) × \(h)"
                }

                // Count elements
                let pathCount = content.components(separatedBy: "<path").count - 1
                let rectCount = content.components(separatedBy: "<rect").count - 1
                let circleCount = content.components(separatedBy: "<circle").count - 1
                let ellipseCount = content.components(separatedBy: "<ellipse").count - 1
                let polygonCount = content.components(separatedBy: "<polygon").count - 1
                let lineCount = content.components(separatedBy: "<line").count - 1
                elementCount = pathCount + rectCount + circleCount + ellipseCount + polygonCount + lineCount

                // Check for version
                if content.contains("svg version=\"1.1\"") {
                    version = "SVG 1.1"
                } else if content.contains("svg version=\"1.0\"") {
                    version = "SVG 1.0"
                } else if content.contains("svg version=\"2.0\"") {
                    version = "SVG 2.0"
                }
            }
        case "eps":
            format = "EPS"
        case "ai":
            format = "Adobe Illustrator"
        default:
            format = ext.uppercased()
        }

        let metadata = VectorGraphicsMetadata(
            format: format,
            dimensions: dimensions,
            viewBox: viewBox,
            elementCount: elementCount,
            colorMode: colorMode,
            creator: creator,
            version: version
        )

        return metadata.hasData ? metadata : nil
    }

    // MARK: - PSD Metadata Extraction

    static func extractPSDMetadata(from url: URL) -> PSDMetadata? {
        guard url.pathExtension.lowercased() == "psd" else { return nil }

        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe),
              data.count >= 30 else {
            return nil
        }

        // Check PSD magic number "8BPS"
        let magic = String(data: data.prefix(4), encoding: .ascii)
        guard magic == "8BPS" else {
            return nil
        }

        var layerCount: Int? = nil
        var colorMode: String? = nil
        var bitDepth: Int? = nil
        var dimensions: String?
        var hasTransparency: Bool?

        // Version (2 bytes at offset 4)
        _ = data.subdata(in: 4..<6).withUnsafeBytes { $0.load(as: UInt16.self).bigEndian }

        // Channels (2 bytes at offset 12)
        let channels = data.subdata(in: 12..<14).withUnsafeBytes { $0.load(as: UInt16.self).bigEndian }
        hasTransparency = channels > 3

        // Height (4 bytes at offset 14)
        let height = data.subdata(in: 14..<18).withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }

        // Width (4 bytes at offset 18)
        let width = data.subdata(in: 18..<22).withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }

        dimensions = "\(width) × \(height)"

        // Bit depth (2 bytes at offset 22)
        let depth = data.subdata(in: 22..<24).withUnsafeBytes { $0.load(as: UInt16.self).bigEndian }
        bitDepth = Int(depth)

        // Color mode (2 bytes at offset 24)
        let mode = data.subdata(in: 24..<26).withUnsafeBytes { $0.load(as: UInt16.self).bigEndian }
        switch mode {
        case 0: colorMode = "Bitmap"
        case 1: colorMode = "Grayscale"
        case 2: colorMode = "Indexed"
        case 3: colorMode = "RGB"
        case 4: colorMode = "CMYK"
        case 7: colorMode = "Multichannel"
        case 8: colorMode = "Duotone"
        case 9: colorMode = "Lab"
        default: colorMode = "Unknown"
        }

        let metadata = PSDMetadata(
            layerCount: layerCount,
            colorMode: colorMode,
            bitDepth: bitDepth,
            resolution: nil,
            hasTransparency: hasTransparency,
            dimensions: dimensions
        )

        return metadata.hasData ? metadata : nil
    }

    // MARK: - 3D Model Metadata Extraction

    static func extractModel3DMetadata(
        from url: URL,
        policy: FileInfo.MetadataExtractionPolicy = .default,
        noticeRecorder: ((FileInfo.AnalysisNotice) -> Void)? = nil
    ) -> Model3DMetadata? {
        let ext = url.pathExtension.lowercased()
        let model3DExtensions = ["usdz", "usda", "usdc", "usd", "obj", "gltf", "glb", "fbx", "dae", "stl", "ply", "3ds"]

        guard model3DExtensions.contains(ext) else {
            return nil
        }

        var format: String? = nil
        var vertexCount: Int? = nil
        var faceCount: Int? = nil
        var meshCount: Int? = nil
        var materialCount: Int? = nil
        var animationCount: Int? = nil
        var hasSkeleton: Bool? = nil
        var boundingBox: String? = nil

        // Determine format name
        switch ext {
        case "usdz", "usda", "usdc", "usd":
            format = "USD (\(ext.uppercased()))"
        case "obj":
            format = "Wavefront OBJ"
        case "gltf", "glb":
            format = "glTF \(ext == "glb" ? "(Binary)" : "(JSON)")"
        case "fbx":
            format = "Autodesk FBX"
        case "dae":
            format = "COLLADA"
        case "stl":
            format = "STL"
        case "ply":
            format = "PLY"
        case "3ds":
            format = "3DS"
        default:
            format = ext.uppercased()
        }

        // Parse text-based formats
        if ["obj", "gltf", "dae", "stl", "ply"].contains(ext) {
            if policy.enableLargeFileProtection,
               let size = fileSize(of: url),
               size > policy.largeFileThresholds.modelTextBytes {
                noticeRecorder?(.largeFileProtection)
            } else {
                do {
                    let content = try String(contentsOf: url, encoding: .utf8)
                    let lines = content.components(separatedBy: .newlines)

                    switch ext {
                    case "obj":
                        var vCount = 0
                        var fCount = 0
                        var mtlSet = Set<String>()

                        for line in lines.prefix(50000) {
                            let trimmed = line.trimmingCharacters(in: .whitespaces)
                            if trimmed.hasPrefix("v ") {
                                vCount += 1
                            } else if trimmed.hasPrefix("f ") {
                                fCount += 1
                            } else if trimmed.hasPrefix("usemtl ") {
                                let material = String(trimmed.dropFirst(7)).trimmingCharacters(in: .whitespaces)
                                mtlSet.insert(material)
                            }
                        }

                        if vCount > 0 { vertexCount = vCount }
                        if fCount > 0 { faceCount = fCount }
                        if !mtlSet.isEmpty { materialCount = mtlSet.count }

                    case "stl":
                        var facetCount = 0
                        for line in lines {
                            if line.trimmingCharacters(in: .whitespaces).lowercased().hasPrefix("facet normal") {
                                facetCount += 1
                            }
                        }
                        if facetCount > 0 {
                            faceCount = facetCount
                            vertexCount = facetCount * 3
                        }

                    case "gltf":
                        if let data = content.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            if let meshes = json["meshes"] as? [[String: Any]] {
                                meshCount = meshes.count
                            }
                            if let materials = json["materials"] as? [[String: Any]] {
                                materialCount = materials.count
                            }
                            if let animations = json["animations"] as? [[String: Any]] {
                                animationCount = animations.count
                            }
                            if let skins = json["skins"] as? [[String: Any]], !skins.isEmpty {
                                hasSkeleton = true
                            }
                        }

                    default:
                        break
                    }
                } catch {
                    Logger.debug("Failed to parse 3D model: \(error.localizedDescription)", subsystem: .fileSystem)
                }
            }
        }

        // Parse binary GLB
        if ext == "glb" {
            do {
                let data = try Data(contentsOf: url)
                if data.count >= 12 {
                    let magic = data.subdata(in: 0..<4)
                    if magic == Data([0x67, 0x6C, 0x54, 0x46]) {
                        format = "glTF (Binary)"
                    }
                }
            } catch {
                Logger.debug("Failed to read GLB header: \(error.localizedDescription)", subsystem: .fileSystem)
            }
        }

        let metadata = Model3DMetadata(
            format: format,
            vertexCount: vertexCount,
            faceCount: faceCount,
            meshCount: meshCount,
            materialCount: materialCount,
            animationCount: animationCount,
            hasSkeleton: hasSkeleton,
            boundingBox: boundingBox
        )

        return metadata.hasData ? metadata : nil
    }

    private static func fileSize(of url: URL) -> Int64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) else {
            return nil
        }
        return attributes[.size] as? Int64
    }
}
