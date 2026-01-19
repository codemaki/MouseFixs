#!/usr/bin/env swift
import Cocoa
import Foundation

// Create icon from emoji
func createEmojiIcon(emoji: String, size: CGSize) -> NSImage {
    let image = NSImage(size: size)
    image.lockFocus()

    // Clear background
    NSColor.clear.set()
    NSRect(origin: .zero, size: size).fill()

    // Draw emoji
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size.width * 0.8),
        .foregroundColor: NSColor.black
    ]

    let attributedString = NSAttributedString(string: emoji, attributes: attributes)
    let stringSize = attributedString.size()
    let point = CGPoint(
        x: (size.width - stringSize.width) / 2,
        y: (size.height - stringSize.height) / 2
    )

    attributedString.draw(at: point)
    image.unlockFocus()

    return image
}

// Save PNG
func savePNG(image: NSImage, path: String) -> Bool {
    guard let tiffData = image.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
        return false
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: path))
        return true
    } catch {
        print("Error saving PNG: \(error)")
        return false
    }
}

// Create iconset directory
let iconsetPath = "icon.iconset"
try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

// Icon sizes
let sizes: [(Int, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

print("Creating icon images...")
for (size, filename) in sizes {
    let image = createEmojiIcon(emoji: "🥊", size: CGSize(width: size, height: size))
    let path = "\(iconsetPath)/\(filename)"
    if savePNG(image: image, path: path) {
        print("✓ Created \(filename)")
    } else {
        print("✗ Failed to create \(filename)")
    }
}

print("\nConverting to icns...")
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconsetPath, "-o", "AppIcon.icns"]

do {
    try task.run()
    task.waitUntilExit()

    if task.terminationStatus == 0 {
        print("✅ Successfully created AppIcon.icns")
        // Clean up iconset
        try? FileManager.default.removeItem(atPath: iconsetPath)
    } else {
        print("❌ iconutil failed with status \(task.terminationStatus)")
    }
} catch {
    print("❌ Error running iconutil: \(error)")
}
