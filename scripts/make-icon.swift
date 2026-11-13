#!/usr/bin/env swift
//
// make-icon.swift — renders the MDView app icon with Core Graphics.
//
// Design: a full-bleed blue → indigo gradient (macOS masks it to its
// squircle), a white sheet of paper with a folded corner, and the Markdown
// mark "M↓" stroked in the same gradient.
//
// Usage:  scripts/make-icon.swift <output-dir>
// Writes <output-dir>/AppIcon-1024.png and <output-dir>/AppIcon.iconset/*.png
// (turn the iconset into .icns with `iconutil -c icns`).
//

import AppKit
import CoreGraphics

let canvas: CGFloat = 1024

// MARK: - Palette

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

let backgroundTop = rgb(0x3D9BFF)     // bright system blue
let backgroundBottom = rgb(0x4B3FD8)  // deep indigo
let markTop = rgb(0x1E88FF)
let markBottom = rgb(0x5A3FE0)
let paper = rgb(0xFFFFFF)
let paperShade = rgb(0xEEF0F6)
let foldLight = rgb(0xE3E6EF)
let foldDark = rgb(0xC9CEDC)

// MARK: - Shapes

/// Sheet of paper with the top-right corner folded down.
func pagePath(_ r: CGRect, radius: CGFloat, fold: CGFloat) -> CGPath {
    let p = CGMutablePath()
    p.move(to: CGPoint(x: r.minX + radius, y: r.minY))
    p.addLine(to: CGPoint(x: r.maxX - radius, y: r.minY))
    p.addArc(tangent1End: CGPoint(x: r.maxX, y: r.minY), tangent2End: CGPoint(x: r.maxX, y: r.minY + radius), radius: radius)
    p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - fold))
    p.addLine(to: CGPoint(x: r.maxX - fold, y: r.maxY))
    p.addLine(to: CGPoint(x: r.minX + radius, y: r.maxY))
    p.addArc(tangent1End: CGPoint(x: r.minX, y: r.maxY), tangent2End: CGPoint(x: r.minX, y: r.maxY - radius), radius: radius)
    p.addLine(to: CGPoint(x: r.minX, y: r.minY + radius))
    p.addArc(tangent1End: CGPoint(x: r.minX, y: r.minY), tangent2End: CGPoint(x: r.minX + radius, y: r.minY), radius: radius)
    p.closeSubpath()
    return p
}

func foldPath(_ r: CGRect, fold: CGFloat, radius: CGFloat) -> CGPath {
    let p = CGMutablePath()
    p.move(to: CGPoint(x: r.maxX - fold, y: r.maxY))
    p.addLine(to: CGPoint(x: r.maxX - fold, y: r.maxY - fold + radius))
    p.addArc(tangent1End: CGPoint(x: r.maxX - fold, y: r.maxY - fold),
             tangent2End: CGPoint(x: r.maxX - fold + radius, y: r.maxY - fold), radius: radius)
    p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - fold))
    p.closeSubpath()
    return p
}

/// The Markdown mark: "M" and a down arrow, as centre-line strokes.
func markdownMarkPath(center: CGPoint, height h: CGFloat) -> CGPath {
    let p = CGMutablePath()
    let w = h * 0.92          // width of the M
    let gap = h * 0.30        // space between M and arrow
    let arrowW = h * 0.56     // arrow head width
    let total = w + gap + arrowW
    let left = center.x - total / 2
    let bottom = center.y - h / 2
    let top = center.y + h / 2

    // M
    p.move(to: CGPoint(x: left, y: bottom))
    p.addLine(to: CGPoint(x: left, y: top))
    p.addLine(to: CGPoint(x: left + w / 2, y: top - h * 0.46))
    p.addLine(to: CGPoint(x: left + w, y: top))
    p.addLine(to: CGPoint(x: left + w, y: bottom))

    // ↓
    let ax = left + w + gap + arrowW / 2
    p.move(to: CGPoint(x: ax, y: top))
    p.addLine(to: CGPoint(x: ax, y: bottom + h * 0.04))
    p.move(to: CGPoint(x: ax - arrowW / 2, y: bottom + arrowW / 2))
    p.addLine(to: CGPoint(x: ax, y: bottom))
    p.addLine(to: CGPoint(x: ax + arrowW / 2, y: bottom + arrowW / 2))
    return p
}

func fillGradient(_ ctx: CGContext, clip path: CGPath, colors: [CGColor], from: CGPoint, to: CGPoint) {
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors as CFArray, locations: nil)!
    ctx.drawLinearGradient(gradient, start: from, end: to, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    ctx.restoreGState()
}

// MARK: - Drawing

func drawIcon(in ctx: CGContext) {
    // Full-bleed artwork: macOS 26+ applies its own squircle mask (and puts
    // icons with transparent margins on a grey platter), so the background
    // fills the whole canvas and the system rounds it.
    let tile = CGRect(x: 0, y: 0, width: canvas, height: canvas)
    let tilePath = CGPath(rect: tile, transform: nil)

    // Background gradient (top-left light → bottom-right deep)
    fillGradient(ctx, clip: tilePath, colors: [backgroundTop, backgroundBottom],
                 from: CGPoint(x: tile.minX, y: tile.maxY), to: CGPoint(x: tile.maxX, y: tile.minY))

    // Subtle top highlight for depth
    let glow = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                          colors: [rgb(0xFFFFFF, 0.22), rgb(0xFFFFFF, 0)] as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(glow, startCenter: CGPoint(x: tile.midX, y: tile.maxY + 40), startRadius: 0,
                           endCenter: CGPoint(x: tile.midX, y: tile.maxY + 40), endRadius: tile.width * 0.75, options: [])

    // The glyph was designed on Apple's 824 pt grid; scale it to the full canvas.
    let glyphScale = canvas / 824
    ctx.translateBy(x: canvas / 2, y: canvas / 2)
    ctx.scaleBy(x: glyphScale, y: glyphScale)
    ctx.translateBy(x: -canvas / 2, y: -canvas / 2)

    // Paper
    let pageW: CGFloat = 500, pageH: CGFloat = 620
    let page = CGRect(x: canvas / 2 - pageW / 2, y: canvas / 2 - pageH / 2 - 6, width: pageW, height: pageH)
    let fold: CGFloat = 120
    let corner: CGFloat = 44
    let sheet = pagePath(page, radius: corner, fold: fold)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 40, color: rgb(0x1A1060, 0.40))
    ctx.addPath(sheet)
    ctx.setFillColor(paper)
    ctx.fillPath()
    ctx.restoreGState()

    // Very light vertical shading on the paper
    fillGradient(ctx, clip: sheet, colors: [paper, paperShade],
                 from: CGPoint(x: page.midX, y: page.maxY), to: CGPoint(x: page.midX, y: page.minY))

    // Folded corner
    let flap = foldPath(page, fold: fold, radius: 18)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: -6, height: -6), blur: 14, color: rgb(0x1A1060, 0.22))
    ctx.addPath(flap)
    ctx.setFillColor(foldLight)
    ctx.fillPath()
    ctx.restoreGState()
    fillGradient(ctx, clip: flap, colors: [paper, foldDark],
                 from: CGPoint(x: page.maxX - fold, y: page.maxY - fold), to: CGPoint(x: page.maxX - fold / 2, y: page.maxY - fold / 2))

    // Markdown mark, stroked then filled with the brand gradient
    let mark = markdownMarkPath(center: CGPoint(x: page.midX, y: page.midY - 30), height: 196)
    let stroked = mark.copy(strokingWithWidth: 48, lineCap: .round, lineJoin: .round, miterLimit: 10)
    fillGradient(ctx, clip: stroked, colors: [markTop, markBottom],
                 from: CGPoint(x: page.minX, y: page.maxY), to: CGPoint(x: page.maxX, y: page.minY))
}

// MARK: - Output

func renderPNG(size: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!.cgContext
    ctx.interpolationQuality = .high
    ctx.setShouldAntialias(true)
    let scale = CGFloat(size) / canvas
    ctx.scaleBy(x: scale, y: scale)
    drawIcon(in: ctx)
    return rep.representation(using: .png, properties: [:])!
}

let outDir = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? ".", isDirectory: true)
let iconset = outDir.appendingPathComponent("AppIcon.iconset", isDirectory: true)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

try renderPNG(size: 1024).write(to: outDir.appendingPathComponent("AppIcon-1024.png"))

for base in [16, 32, 128, 256, 512] {
    try renderPNG(size: base).write(to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    try renderPNG(size: base * 2).write(to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
print("Wrote \(outDir.path)/AppIcon-1024.png and \(iconset.path)")
