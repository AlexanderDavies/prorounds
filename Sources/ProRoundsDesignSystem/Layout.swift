import CoreGraphics

/// Spacing on the 8-pt grid (`DESIGN.md` §2.1).
public enum Spacing {
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let xxl: CGFloat = 48
    public static let xxxl: CGFloat = 64
}

/// Corner radii (`DESIGN.md` §2.2). `pill` is an effectively-infinite radius for capsule shapes.
public enum Radius {
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 24
    public static let pill: CGFloat = 999
}
