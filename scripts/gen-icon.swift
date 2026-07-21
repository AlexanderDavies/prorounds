// Generates the ProRounds app icon (1024×1024 PNG) from a SwiftUI view — the "Ring + PR" mark
// (DESIGN §10): a red timer ring around an off-white "PR" on a near-black field. Committed +
// reproducible. Run: xcrun swift scripts/gen-icon.swift <output.png>
import SwiftUI
import ImageIO
import UniformTypeIdentifiers
import CoreGraphics

struct IconView: View {
    var body: some View {
        ZStack {
            Rectangle().fill(Color(red: 0x0A/255, green: 0x0A/255, blue: 0x0B/255))
            Circle()
                .trim(from: 0, to: 0.84)
                .stroke(Color(red: 0xE5/255, green: 0x09/255, blue: 0x14/255),
                        style: StrokeStyle(lineWidth: 76, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 640, height: 640)
            Text("PR")
                .font(.system(size: 292, weight: .heavy))
                .tracking(-14)
                .foregroundStyle(Color(red: 0xF5/255, green: 0xF5/255, blue: 0xF7/255))
        }
        .frame(width: 1024, height: 1024)
    }
}

@MainActor
func render(to path: String) {
    let renderer = ImageRenderer(content: IconView())
    renderer.scale = 1 // 1024 points → 1024 px
    guard let cg = renderer.cgImage else { fputs("render failed\n", stderr); exit(1) }
    let url = URL(fileURLWithPath: path)
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        fputs("destination failed\n", stderr); exit(1)
    }
    CGImageDestinationAddImage(dest, cg, nil)
    if CGImageDestinationFinalize(dest) {
        print("wrote \(path) (\(cg.width)×\(cg.height))")
    } else {
        fputs("finalize failed\n", stderr); exit(1)
    }
}

let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"
MainActor.assumeIsolated { render(to: output) }
