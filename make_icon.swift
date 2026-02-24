#!/usr/bin/swift
// make_icon.swift — generates the MacPad++ app icon (1024×1024 PNG)
// Usage: swift make_icon.swift <output.png>
import AppKit

// Initialize AppKit (required for font/color APIs, no event loop needed)
let _ = NSApplication.shared

func buildDocumentPath(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat,
                        corner: CGFloat, fold: CGFloat) -> CGPath {
    let p = CGMutablePath()
    // Bottom-left corner
    p.move(to: CGPoint(x: x + corner, y: y))
    // Bottom edge
    p.addLine(to: CGPoint(x: x + w - corner, y: y))
    p.addArc(center: CGPoint(x: x + w - corner, y: y + corner),
             radius: corner, startAngle: -.pi / 2, endAngle: 0, clockwise: false)
    // Right edge up to fold
    p.addLine(to: CGPoint(x: x + w, y: y + h - fold))
    // Fold diagonal
    p.addLine(to: CGPoint(x: x + w - fold, y: y + h))
    // Top edge
    p.addLine(to: CGPoint(x: x + corner, y: y + h))
    p.addArc(center: CGPoint(x: x + corner, y: y + h - corner),
             radius: corner, startAngle: .pi / 2, endAngle: .pi, clockwise: false)
    // Left edge
    p.addLine(to: CGPoint(x: x, y: y + corner))
    p.addArc(center: CGPoint(x: x + corner, y: y + corner),
             radius: corner, startAngle: .pi, endAngle: -.pi / 2, clockwise: false)
    p.closeSubpath()
    return p
}

let image = NSImage(size: NSSize(width: 1024, height: 1024), flipped: false) { _ in
    guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

    let s: CGFloat = 1024
    let cs = CGColorSpaceCreateDeviceRGB()

    // ── 1. Background: dark blue gradient rounded rect ──────────────────────
    let bgGradient = CGGradient(
        colorsSpace: cs,
        colors: [
            CGColor(red: 0.12, green: 0.31, blue: 0.60, alpha: 1.0),
            CGColor(red: 0.04, green: 0.12, blue: 0.32, alpha: 1.0)
        ] as CFArray,
        locations: [0.0, 1.0]
    )!
    let bgCorner = s * 0.19
    let bgPath = CGPath(roundedRect: CGRect(x: 0, y: 0, width: s, height: s),
                        cornerWidth: bgCorner, cornerHeight: bgCorner, transform: nil)
    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()
    ctx.drawLinearGradient(bgGradient,
        start: CGPoint(x: s / 2, y: s),
        end:   CGPoint(x: s / 2, y: 0),
        options: [])
    ctx.restoreGState()

    // ── 2. Paper / document ──────────────────────────────────────────────────
    let pad: CGFloat = s * 0.115
    let fold: CGFloat = s * 0.125
    let docX = pad, docY = pad
    let docW = s - pad * 2, docH = s - pad * 2
    let corner: CGFloat = s * 0.026

    let paperPath = buildDocumentPath(x: docX, y: docY, w: docW, h: docH,
                                      corner: corner, fold: fold)

    // Drop shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -(s * 0.025)),
                  blur: s * 0.055,
                  color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.45))
    ctx.addPath(paperPath)
    ctx.setFillColor(CGColor(red: 0.96, green: 0.975, blue: 1.0, alpha: 1.0))
    ctx.fillPath()
    ctx.restoreGState()

    // Paper fill (no shadow)
    ctx.addPath(paperPath)
    ctx.setFillColor(CGColor(red: 0.96, green: 0.975, blue: 1.0, alpha: 1.0))
    ctx.fillPath()

    // Fold triangle (top-right corner)
    let foldPath = CGMutablePath()
    foldPath.move(to: CGPoint(x: docX + docW - fold, y: docY + docH))
    foldPath.addLine(to: CGPoint(x: docX + docW, y: docY + docH - fold))
    foldPath.addLine(to: CGPoint(x: docX + docW - fold, y: docY + docH - fold))
    foldPath.closeSubpath()
    ctx.addPath(foldPath)
    ctx.setFillColor(CGColor(red: 0.70, green: 0.78, blue: 0.90, alpha: 1.0))
    ctx.fillPath()

    // ── 3. Horizontal text lines (suggesting code) ───────────────────────────
    let lineColor = CGColor(red: 0.68, green: 0.77, blue: 0.90, alpha: 0.80)
    ctx.setFillColor(lineColor)
    let lineH:   CGFloat = s * 0.026
    let lineXL:  CGFloat = docX + s * 0.07
    let lineSpacing: CGFloat = s * 0.073
    let lineTopY: CGFloat = docY + docH * 0.47   // start in upper-middle area
    let lineFractions: [CGFloat] = [0.72, 0.85, 0.60, 0.76]
    for (i, frac) in lineFractions.enumerated() {
        let ly = lineTopY + CGFloat(i) * lineSpacing
        ctx.fill(CGRect(x: lineXL, y: ly, width: docW * frac * 0.85, height: lineH))
    }

    // ── 4. "++" symbol in green ──────────────────────────────────────────────
    let ppFont = CTFontCreateWithName("Helvetica-Bold" as CFString, s * 0.265, nil)
    let ppColor = CGColor(red: 0.15, green: 0.78, blue: 0.38, alpha: 1.0)
    let attrs: [CFString: Any] = [
        kCTFontAttributeName: ppFont,
        kCTForegroundColorAttributeName: ppColor
    ]
    let cfStr = "++" as CFString
    let attrStr = CFAttributedStringCreate(nil, cfStr, attrs as CFDictionary)!
    let line = CTLineCreateWithAttributedString(attrStr)
    let lineWidth = CTLineGetTypographicBounds(line, nil, nil, nil)
    let ppX = docX + (docW - lineWidth) / 2
    let ppY = docY + docH * 0.095      // lower third of paper

    ctx.saveGState()
    ctx.textPosition = CGPoint(x: ppX, y: ppY)
    CTLineDraw(line, ctx)
    ctx.restoreGState()

    return true
}

// ── Save PNG ──────────────────────────────────────────────────────────────────
let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "/tmp/macpad_icon.png"

guard
    let cgImg = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
    let data  = NSBitmapImageRep(cgImage: cgImg).representation(using: .png, properties: [:])
else {
    fputs("Error: could not render icon image\n", stderr)
    exit(1)
}

do {
    try data.write(to: URL(fileURLWithPath: outputPath))
    print("✓ Icon written to \(outputPath)")
} catch {
    fputs("Error writing file: \(error)\n", stderr)
    exit(1)
}
