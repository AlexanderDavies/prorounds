import Foundation

/// Locates this module's own resources.
///
/// The catalog, the scripts and the 115 clips all ship inside the package bundle — nothing here
/// assumes a filesystem path, and nothing reaches the network.
public enum CoachingBundle {
    public static var resources: Bundle { .module }
}
