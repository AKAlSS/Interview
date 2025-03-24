import SwiftUI
import AppKit

// MARK: - View Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    @ViewBuilder
    func foreground<V: View>(_ view: V) -> some View {
        self.overlay(view.mask(self))
    }
    
    func hideKeyboard() {
        NSApp.keyWindow?.makeFirstResponder(nil)
    }
}

// Custom shape for specific corner rounding
struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - String Extensions

extension String {
    func trimmingWhitespace() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var isBlank: Bool {
        self.trimmingWhitespace().isEmpty
    }
    
    func truncated(limit: Int, trailing: String = "...") -> String {
        if self.count <= limit {
            return self
        } else {
            return String(self.prefix(limit)) + trailing
        }
    }
    
    func containsAny(of keywords: [String], caseSensitive: Bool = false) -> Bool {
        for keyword in keywords {
            let options: NSString.CompareOptions = caseSensitive ? [] : [.caseInsensitive]
            if self.range(of: keyword, options: options) != nil {
                return true
            }
        }
        return false
    }
    
    func highlightCode() -> AttributedString {
        // A very simple syntax highlighter for code
        var attributedString = AttributedString(self)
        
        let keywords = ["func", "var", "let", "if", "else", "for", "while", "guard", "return", "class", "struct", "enum", "import", "switch", "case", "default"]
        let types = ["String", "Int", "Double", "Float", "Bool", "Array", "Dictionary", "Set"]
        
        // Function to apply attributes to matches
        func applyAttributes(to matches: [String], with color: Color) {
            for match in matches {
                if let range = self.range(of: "\\b\(match)\\b", options: .regularExpression) {
                    let nsRange = NSRange(range, in: self)
                    let attrRange = AttributeScopes.SwiftUIAttributes.Range(location: nsRange.location, length: nsRange.length)
                    attributedString[attrRange].foregroundColor = color
                }
            }
        }
        
        // Apply syntax highlighting
        applyAttributes(to: keywords, with: .purple)
        applyAttributes(to: types, with: .blue)
        
        // Highlight strings
        if let regex = try? NSRegularExpression(pattern: "\"[^\"]*\"", options: []) {
            let results = regex.matches(in: self, options: [], range: NSRange(location: 0, length: self.count))
            for result in results {
                let attrRange = AttributeScopes.SwiftUIAttributes.Range(location: result.range.location, length: result.range.length)
                attributedString[attrRange].foregroundColor = .green
            }
        }
        
        // Highlight comments
        if let regex = try? NSRegularExpression(pattern: "//.*$", options: .anchorsMatchLines) {
            let results = regex.matches(in: self, options: [], range: NSRange(location: 0, length: self.count))
            for result in results {
                let attrRange = AttributeScopes.SwiftUIAttributes.Range(location: result.range.location, length: result.range.length)
                attributedString[attrRange].foregroundColor = .gray
            }
        }
        
        return attributedString
    }
}

// MARK: - NSBezierPath for UIBezierPath compatibility

extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        
        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)
            
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath:
                path.closeSubpath()
            @unknown default:
                break
            }
        }
        
        return path
    }
}

// For UIKit compatibility in SwiftUI macOS
typealias UIRectCorner = NSRectCorner
typealias UIBezierPath = NSBezierPath

extension NSRectCorner {
    static let allCorners: NSRectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
    static let topLeft = NSRectCorner(rawValue: 1 << 0)
    static let topRight = NSRectCorner(rawValue: 1 << 1)
    static let bottomLeft = NSRectCorner(rawValue: 1 << 2)
    static let bottomRight = NSRectCorner(rawValue: 1 << 3)
}

extension NSBezierPath {
    convenience init(roundedRect rect: CGRect, byRoundingCorners corners: NSRectCorner, cornerRadii: CGSize) {
        self.init()
        
        let topLeft = rect.origin
        let topRight = CGPoint(x: rect.maxX, y: rect.minY)
        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
        
        let radius = min(cornerRadii.width, cornerRadii.height)
        
        self.move(to: CGPoint(x: topLeft.x + (corners.contains(.topLeft) ? radius : 0), y: topLeft.y))
        
        // Top edge and top-right corner
        self.line(to: CGPoint(x: topRight.x - (corners.contains(.topRight) ? radius : 0), y: topRight.y))
        if corners.contains(.topRight) {
            self.curve(to: CGPoint(x: topRight.x, y: topRight.y + radius), controlPoint1: CGPoint(x: topRight.x, y: topRight.y), controlPoint2: CGPoint(x: topRight.x, y: topRight.y + radius))
        }
        
        // Right edge and bottom-right corner
        self.line(to: CGPoint(x: bottomRight.x, y: bottomRight.y - (corners.contains(.bottomRight) ? radius : 0)))
        if corners.contains(.bottomRight) {
            self.curve(to: CGPoint(x: bottomRight.x - radius, y: bottomRight.y), controlPoint1: CGPoint(x: bottomRight.x, y: bottomRight.y), controlPoint2: CGPoint(x: bottomRight.x - radius, y: bottomRight.y))
        }
        
        // Bottom edge and bottom-left corner
        self.line(to: CGPoint(x: bottomLeft.x + (corners.contains(.bottomLeft) ? radius : 0), y: bottomLeft.y))
        if corners.contains(.bottomLeft) {
            self.curve(to: CGPoint(x: bottomLeft.x, y: bottomLeft.y - radius), controlPoint1: CGPoint(x: bottomLeft.x, y: bottomLeft.y), controlPoint2: CGPoint(x: bottomLeft.x, y: bottomLeft.y - radius))
        }
        
        // Left edge and top-left corner
        self.line(to: CGPoint(x: topLeft.x, y: topLeft.y + (corners.contains(.topLeft) ? radius : 0)))
        if corners.contains(.topLeft) {
            self.curve(to: CGPoint(x: topLeft.x + radius, y: topLeft.y), controlPoint1: CGPoint(x: topLeft.x, y: topLeft.y), controlPoint2: CGPoint(x: topLeft.x + radius, y: topLeft.y))
        }
        
        self.close()
    }
} 