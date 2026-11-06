//
//  BrightDICOMFile.swift
//  Widgets
//

import CoreGraphics
import CoreImage
import Foundation

// Decodes uncompressed little-endian DICOM (the common X-ray export) into a displayable image.
// Compressed transfer syntaxes (JPEG, JPEG 2000, RLE) and big-endian files return nil.
nonisolated struct BrightDICOMFile {
    struct Window: Equatable {
        var center: Double
        var width: Double
    }

    let image: CGImage
    // Nil for colour scans, which have no brightness/contrast window.
    let defaultWindow: Window?
    let valueRange: ClosedRange<Double>
    // MONOCHROME1 stores bright as low values, so brightening moves the window the other way.
    let isInverted: Bool
    // Millimetres per pixel across (width) and down (height); nil when the file doesn't say.
    let pixelSpacing: CGSize?
    let modality: String?
    let bodyPart: String?
    let studyDescription: String?
    let viewPosition: String?
    let institution: String?
    let studyDate: Date?
    let width: Int
    let height: Int
    let bitsStored: Int
    let fileSize: Int
    let transferSyntax: String

    private let source: CIImage?

    var modalityName: String? {
        switch modality {
        case "CR": "Computed radiography"
        case "DX": "Digital X-ray"
        case "MG": "Mammogram"
        case "CT": "CT scan"
        case "MR": "MRI"
        case "US": "Ultrasound"
        default: modality
        }
    }

    var encodingName: String {
        transferSyntax == DICOMReader.explicitLittleEndian ? "Uncompressed, explicit" : "Uncompressed, implicit"
    }

    init?(data: Data) {
        var reader = DICOMReader(bytes: [UInt8](data))
        guard let elements = reader.readDataset(),
              let pixels = elements[Tag.pixelData],
              let rows = elements.uint16(Tag.rows),
              let columns = elements.uint16(Tag.columns)
        else { return nil }

        let samples = elements.uint16(Tag.samplesPerPixel) ?? 1
        let bitsAllocated = elements.uint16(Tag.bitsAllocated) ?? 16
        let bitsStored = elements.uint16(Tag.bitsStored) ?? bitsAllocated
        let photometric = elements.string(Tag.photometric) ?? "MONOCHROME2"
        let count = rows * columns

        var values: [Float]?
        var colourImage: CGImage?
        if samples == 1 {
            values = Self.greyscaleValues(
                pixels,
                count: count,
                bitsAllocated: bitsAllocated,
                bitsStored: bitsStored,
                isSigned: elements.uint16(Tag.pixelRepresentation) == 1,
                slope: elements.double(Tag.rescaleSlope) ?? 1,
                intercept: elements.double(Tag.rescaleIntercept) ?? 0
            )
        } else if samples == 3, bitsAllocated == 8 {
            let rgb = Self.interleavedRGB(pixels, count: count, planar: elements.uint16(Tag.planarConfiguration) == 1)
            // Plenty of X-ray exports are saved as RGB with identical channels; read those as greyscale so they can be windowed.
            if let rgb, Self.isGrey(rgb) {
                values = stride(from: 0, to: rgb.count, by: 3).map { Float(rgb[$0]) }
            } else if let rgb {
                colourImage = Self.makeImage(Data(rgb), width: columns, height: rows, components: 3)
            }
        }

        let lowest = Double(values?.min() ?? 0)
        let highest = Double(values?.max() ?? 255)
        let range = lowest ... max(highest, lowest + 1)
        let inverted = photometric == "MONOCHROME1"

        var normalised: CIImage?
        var window: Window?
        if let values {
            normalised = Self.normalisedImage(values, width: columns, height: rows, range: range)
            if let center = elements.double(Tag.windowCenter), let width = elements.double(Tag.windowWidth), width > 1 {
                window = Window(center: center, width: width)
            } else {
                window = Window(center: (lowest + highest) / 2, width: max(highest - lowest, 1))
            }
        }

        let greyscaleImage = window.flatMap { Self.render(normalised, window: $0, range: range, isInverted: inverted) }
        guard let image = colourImage ?? greyscaleImage else { return nil }

        self.image = image
        source = normalised
        defaultWindow = window
        valueRange = range
        isInverted = inverted
        pixelSpacing = Self.spacing(elements.string(Tag.pixelSpacing, keepingAllValues: true))
            ?? Self.spacing(elements.string(Tag.imagerPixelSpacing, keepingAllValues: true))
        modality = elements.string(Tag.modality)
        bodyPart = elements.string(Tag.bodyPart)?.capitalized
        studyDescription = elements.string(Tag.studyDescription)?.capitalized
        viewPosition = elements.string(Tag.viewPosition)
        institution = elements.string(Tag.institution)
        studyDate = elements.string(Tag.studyDate).flatMap(Self.date)
        width = columns
        height = rows
        self.bitsStored = bitsStored
        fileSize = data.count
        transferSyntax = elements.string(Tag.transferSyntax) ?? DICOMReader.implicitLittleEndian
    }

    func image(window: Window) -> CGImage? {
        Self.render(source, window: window, range: valueRange, isInverted: isInverted)
    }

    // Colour management is off throughout so the stored values reach the window maths untouched.
    private static let context = CIContext(options: [
        .workingColorSpace: NSNull(),
        .outputColorSpace: NSNull(),
        .workingFormat: CIFormat.RGBAf,
    ])

    private static func render(_ source: CIImage?, window: Window, range: ClosedRange<Double>, isInverted: Bool) -> CGImage? {
        guard let source else { return nil }
        let span = range.upperBound - range.lowerBound
        let lower = (window.center - window.width / 2 - range.lowerBound) / span
        var scale = 1 / max(window.width / span, .leastNonzeroMagnitude)
        var bias = -lower * scale
        if isInverted {
            scale = -scale
            bias = 1 - bias
        }
        let s = CGFloat(scale)
        let b = CGFloat(bias)
        let output = source
            .applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: s, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: s, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: s, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
                "inputBiasVector": CIVector(x: b, y: b, z: b, w: 0),
            ])
            .applyingFilter("CIColorClamp")
        return context.createCGImage(output, from: source.extent, format: .L8, colorSpace: CGColorSpaceCreateDeviceGray())
    }

    private static func greyscaleValues(
        _ pixels: ArraySlice<UInt8>,
        count: Int,
        bitsAllocated: Int,
        bitsStored: Int,
        isSigned: Bool,
        slope: Double,
        intercept: Double
    ) -> [Float]? {
        let bytesPerSample = bitsAllocated / 8
        guard bytesPerSample == 1 || bytesPerSample == 2, pixels.count >= count * bytesPerSample else { return nil }
        var values = [Float](repeating: 0, count: count)
        pixels.withUnsafeBufferPointer { raw in
            let mask = (1 << bitsStored) - 1
            let signBit = 1 << (bitsStored - 1)
            for index in 0 ..< count {
                var value = bytesPerSample == 1
                    ? Int(raw[index])
                    : Int(raw[index * 2]) | Int(raw[index * 2 + 1]) << 8
                value &= mask
                if isSigned, value & signBit != 0 { value -= 1 << bitsStored }
                values[index] = Float(Double(value) * slope + intercept)
            }
        }
        return values
    }

    // Spreads the values across the full 16-bit range so the window maths keeps every level.
    private static func normalisedImage(_ values: [Float], width: Int, height: Int, range: ClosedRange<Double>) -> CIImage? {
        let lower = Float(range.lowerBound)
        let span = Float(range.upperBound - range.lowerBound)
        let levels = values.map { UInt16(min(max(($0 - lower) / span, 0), 1) * 65535) }
        let data = levels.withUnsafeBufferPointer { Data(buffer: $0) }
        guard let provider = CGDataProvider(data: data as CFData),
              let image = CGImage(
                  width: width,
                  height: height,
                  bitsPerComponent: 16,
                  bitsPerPixel: 16,
                  bytesPerRow: width * 2,
                  space: CGColorSpaceCreateDeviceGray(),
                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue | CGBitmapInfo.byteOrder16Little.rawValue),
                  provider: provider,
                  decode: nil,
                  shouldInterpolate: true,
                  intent: .defaultIntent
              )
        else { return nil }
        return CIImage(cgImage: image, options: [.colorSpace: NSNull()])
    }

    private static func interleavedRGB(_ pixels: ArraySlice<UInt8>, count: Int, planar: Bool) -> [UInt8]? {
        guard pixels.count >= count * 3 else { return nil }
        let start = pixels.startIndex
        guard planar else { return Array(pixels[start ..< start + count * 3]) }
        var interleaved = [UInt8](repeating: 0, count: count * 3)
        for index in 0 ..< count {
            for channel in 0 ..< 3 {
                interleaved[index * 3 + channel] = pixels[start + channel * count + index]
            }
        }
        return interleaved
    }

    private static func isGrey(_ rgb: [UInt8]) -> Bool {
        let step = max(rgb.count / 3 / 5000, 1) * 3
        return stride(from: 0, to: rgb.count - 2, by: step).allSatisfy { rgb[$0] == rgb[$0 + 1] && rgb[$0 + 1] == rgb[$0 + 2] }
    }

    private static func makeImage(_ data: Data, width: Int, height: Int, components: Int) -> CGImage? {
        guard let provider = CGDataProvider(data: data as CFData) else { return nil }
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 8 * components,
            bytesPerRow: width * components,
            space: components == 1 ? CGColorSpaceCreateDeviceGray() : CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }

    // Pixel spacing is "row\column" in mm, i.e. the vertical step first.
    private static func spacing(_ value: String?) -> CGSize? {
        guard let parts = value?.split(separator: "\\").compactMap({ Double($0.trimmingCharacters(in: .whitespaces)) }),
              parts.count == 2, parts[0] > 0, parts[1] > 0
        else { return nil }
        return CGSize(width: parts[1], height: parts[0])
    }

    // DICOM dates are YYYYMMDD; older files write YYYY.MM.DD, so the dots are dropped first.
    private static func date(_ value: String) -> Date? {
        let digits = value.filter(\.isNumber).prefix(8)
        guard digits.count == 8, let number = Int(digits) else { return nil }
        let components = DateComponents(year: number / 10000, month: number / 100 % 100, day: number % 100)
        return Calendar.current.date(from: components)
    }
}

nonisolated private enum Tag {
    static let transferSyntax: UInt32 = 0x0002_0010
    static let studyDate: UInt32 = 0x0008_0020
    static let modality: UInt32 = 0x0008_0060
    static let institution: UInt32 = 0x0008_0080
    static let studyDescription: UInt32 = 0x0008_1030
    static let bodyPart: UInt32 = 0x0018_0015
    static let imagerPixelSpacing: UInt32 = 0x0018_1164
    static let viewPosition: UInt32 = 0x0018_5101
    static let samplesPerPixel: UInt32 = 0x0028_0002
    static let photometric: UInt32 = 0x0028_0004
    static let planarConfiguration: UInt32 = 0x0028_0006
    static let rows: UInt32 = 0x0028_0010
    static let columns: UInt32 = 0x0028_0011
    static let pixelSpacing: UInt32 = 0x0028_0030
    static let bitsAllocated: UInt32 = 0x0028_0100
    static let bitsStored: UInt32 = 0x0028_0101
    static let pixelRepresentation: UInt32 = 0x0028_0103
    static let windowCenter: UInt32 = 0x0028_1050
    static let windowWidth: UInt32 = 0x0028_1051
    static let rescaleIntercept: UInt32 = 0x0028_1052
    static let rescaleSlope: UInt32 = 0x0028_1053
    static let pixelData: UInt32 = 0x7FE0_0010

    static let item: UInt32 = 0xFFFE_E000
    static let itemEnd: UInt32 = 0xFFFE_E00D
    static let sequenceEnd: UInt32 = 0xFFFE_E0DD
}

nonisolated private extension [UInt32: ArraySlice<UInt8>] {
    // Multi-valued strings are backslash-separated; most callers only want the first value.
    func string(_ tag: UInt32, keepingAllValues: Bool = false) -> String? {
        guard let bytes = self[tag] else { return nil }
        var text = String(decoding: bytes, as: UTF8.self)
        if !keepingAllValues { text = text.split(separator: "\\").first.map(String.init) ?? "" }
        text = text.trimmingCharacters(in: .whitespaces.union(CharacterSet(charactersIn: "\0")))
        return text.isEmpty ? nil : text
    }

    func uint16(_ tag: UInt32) -> Int? {
        guard let bytes = self[tag], bytes.count >= 2 else { return nil }
        return Int(bytes[bytes.startIndex]) | Int(bytes[bytes.startIndex + 1]) << 8
    }

    func double(_ tag: UInt32) -> Double? {
        string(tag).flatMap(Double.init)
    }
}

nonisolated private struct DICOMReader {
    let bytes: [UInt8]
    var offset = 0

    static let implicitLittleEndian = "1.2.840.10008.1.2"
    static let explicitLittleEndian = "1.2.840.10008.1.2.1"
    private static let undefinedLength: UInt32 = 0xFFFF_FFFF
    private static let longLengthVRs: Set<String> = ["OB", "OD", "OF", "OL", "OV", "OW", "SQ", "SV", "UC", "UN", "UR", "UT", "UV"]

    init(bytes: [UInt8]) {
        self.bytes = bytes
        let hasPreamble = bytes.count > 132 && bytes[128 ..< 132].elementsEqual("DICM".utf8)
        offset = hasPreamble ? 132 : 0
    }

    // Reads every top-level element up to and including the pixel data.
    mutating func readDataset() -> [UInt32: ArraySlice<UInt8>]? {
        var elements: [UInt32: ArraySlice<UInt8>] = [:]

        while peekGroup() == 0x0002 {
            guard let element = readElement(explicit: true), element.length != Self.undefinedLength,
                  let value = take(Int(element.length)) else { return nil }
            elements[element.tag] = value
        }

        let syntax = elements.string(Tag.transferSyntax) ?? Self.implicitLittleEndian
        guard syntax == Self.implicitLittleEndian || syntax == Self.explicitLittleEndian else { return nil }
        let explicit = syntax == Self.explicitLittleEndian

        while offset < bytes.count {
            guard let element = readElement(explicit: explicit) else { return nil }
            if element.length == Self.undefinedLength {
                // Undefined-length pixel data is encapsulated (compressed), which this reader doesn't decode.
                guard element.tag != Tag.pixelData, skipSequence(explicit: explicit && element.vr != "UN") else { return nil }
                continue
            }
            guard let value = take(Int(element.length)) else { return nil }
            elements[element.tag] = value
            if element.tag == Tag.pixelData { break }
        }
        return elements
    }

    private func peekGroup() -> UInt16? {
        guard offset + 2 <= bytes.count else { return nil }
        return UInt16(bytes[offset]) | UInt16(bytes[offset + 1]) << 8
    }

    private mutating func readElement(explicit: Bool) -> (tag: UInt32, vr: String?, length: UInt32)? {
        guard let group = readUInt16(), let number = readUInt16() else { return nil }
        let tag = UInt32(group) << 16 | UInt32(number)
        // Item and delimiter tags never carry a VR, even in explicit files.
        guard explicit, group != 0xFFFE else {
            return readUInt32().map { (tag, nil, $0) }
        }
        guard let vrBytes = take(2) else { return nil }
        let vr = String(decoding: vrBytes, as: UTF8.self)
        if Self.longLengthVRs.contains(vr) {
            guard take(2) != nil, let length = readUInt32() else { return nil }
            return (tag, vr, length)
        }
        return readUInt16().map { (tag, vr, UInt32($0)) }
    }

    private mutating func skipSequence(explicit: Bool) -> Bool {
        while let element = readElement(explicit: false) {
            switch element.tag {
            case Tag.sequenceEnd:
                return true
            case Tag.item where element.length == Self.undefinedLength:
                guard skipItem(explicit: explicit) else { return false }
            case Tag.item:
                guard take(Int(element.length)) != nil else { return false }
            default:
                return false
            }
        }
        return false
    }

    private mutating func skipItem(explicit: Bool) -> Bool {
        while let element = readElement(explicit: explicit) {
            if element.tag == Tag.itemEnd { return true }
            if element.length == Self.undefinedLength {
                guard skipSequence(explicit: explicit && element.vr != "UN") else { return false }
            } else {
                guard take(Int(element.length)) != nil else { return false }
            }
        }
        return false
    }

    private mutating func take(_ count: Int) -> ArraySlice<UInt8>? {
        guard count >= 0, offset + count <= bytes.count else { return nil }
        defer { offset += count }
        return bytes[offset ..< offset + count]
    }

    private mutating func readUInt16() -> UInt16? {
        take(2).map { UInt16($0[$0.startIndex]) | UInt16($0[$0.startIndex + 1]) << 8 }
    }

    private mutating func readUInt32() -> UInt32? {
        take(4).map { slice in
            (0 ..< 4).reduce(UInt32(0)) { $0 | UInt32(slice[slice.startIndex + $1]) << (8 * $1) }
        }
    }
}
