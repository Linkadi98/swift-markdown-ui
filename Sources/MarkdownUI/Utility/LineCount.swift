import SwiftUI

// Publishes the measured line count for a view, dynamically adapting to the
// actual font used by that view. It works by measuring:
// - the total rendered height of the content
// - the single-line height for the same style (via a hidden one-line probe)
// Then derives the line count using these values, which respects per-block
// font sizes such as headings vs paragraphs.

struct LineCountKey: PreferenceKey {
    static let defaultValue: Int = 0
    static func reduce(value: inout Int, nextValue: () -> Int) { value = nextValue() }
}

private struct LineHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

@available(iOS 15, *)
extension View {
    func onLineCountChange(perform action: @escaping (Int) -> Void) -> some View {
        modifier(LineCountUpdateModifier(action: action))
    }
}

@available(iOS 15, *)
struct LineCountUpdateModifier: ViewModifier {
    let action: (Int) -> Void
    @State private var currentLineCount: CGFloat = 0
    @State private var measuredHeight: CGFloat = 0
    @State private var singleLineHeight: CGFloat = 0
    
    func body(content: Content) -> some View {
        ZStack(alignment: .topLeading) {
            // Actual content tree measured with unlimited lines to capture natural height
            content
                .lineLimit(nil)
                .background(
                    GeometryReader { g in
                        Color.clear
                            .preference(key: LineCountKey.self, value: Int(max(0, g.size.height)))
                    }
                )
            
            // One-line probe using the same content and style to capture true line height
            content
                .lineLimit(1)
                .opacity(0.001)
                .accessibilityHidden(true)
                .background(
                    GeometryReader { g in
                        Color.clear.preference(key: LineHeightKey.self, value: g.size.height)
                    }
                )
        }
        .onPreferenceChange(LineHeightKey.self) { lh in
            if lh > 0 { singleLineHeight = lh }
            computeIfReady()
        }
        .onPreferenceChange(LineCountKey.self) { rawHeight in
            measuredHeight = CGFloat(rawHeight)
            computeIfReady()
        }
    }

    private func computeIfReady() {
        // Compute after the view has rendered both heights
        #if canImport(UIKit)
        let fallback = UIFont.preferredFont(forTextStyle: .body).lineHeight
        #else
        let fallback: CGFloat = 20
        #endif
        let lh = singleLineHeight > 0 ? singleLineHeight : fallback
        guard lh > 0, measuredHeight > 0 else { return }
        let lines = max(1, ceil(measuredHeight / lh))
        if lines != currentLineCount {
            currentLineCount = lines
            DispatchQueue.main.async { action(Int(lines)) }
        }
    }
}
