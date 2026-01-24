import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "AccentColor" asset catalog color resource.
    static let accent = DeveloperToolsSupport.ColorResource(name: "AccentColor", bundle: resourceBundle)

    /// The "BorderColor" asset catalog color resource.
    static let border = DeveloperToolsSupport.ColorResource(name: "BorderColor", bundle: resourceBundle)

    /// The "CardBackground" asset catalog color resource.
    static let cardBackground = DeveloperToolsSupport.ColorResource(name: "CardBackground", bundle: resourceBundle)

    /// The "CustomGreen" asset catalog color resource.
    static let customGreen = DeveloperToolsSupport.ColorResource(name: "CustomGreen", bundle: resourceBundle)

    /// The "CustomMaroon" asset catalog color resource.
    static let customMaroon = DeveloperToolsSupport.ColorResource(name: "CustomMaroon", bundle: resourceBundle)

    /// The "CustomOrange" asset catalog color resource.
    static let customOrange = DeveloperToolsSupport.ColorResource(name: "CustomOrange", bundle: resourceBundle)

    /// The "SecondaryBackground" asset catalog color resource.
    static let secondaryBackground = DeveloperToolsSupport.ColorResource(name: "SecondaryBackground", bundle: resourceBundle)

    /// The "WidgetBorderColor" asset catalog color resource.
    static let widgetBorder = DeveloperToolsSupport.ColorResource(name: "WidgetBorderColor", bundle: resourceBundle)

    /// The "WidgetCardBackground" asset catalog color resource.
    static let widgetCardBackground = DeveloperToolsSupport.ColorResource(name: "WidgetCardBackground", bundle: resourceBundle)

    /// The "WidgetCustomGreen" asset catalog color resource.
    static let widgetCustomGreen = DeveloperToolsSupport.ColorResource(name: "WidgetCustomGreen", bundle: resourceBundle)

    /// The "WidgetCustomMaroon" asset catalog color resource.
    static let widgetCustomMaroon = DeveloperToolsSupport.ColorResource(name: "WidgetCustomMaroon", bundle: resourceBundle)

    /// The "WidgetCustomOrange" asset catalog color resource.
    static let widgetCustomOrange = DeveloperToolsSupport.ColorResource(name: "WidgetCustomOrange", bundle: resourceBundle)

    /// The "WidgetSecondaryBackground" asset catalog color resource.
    static let widgetSecondaryBackground = DeveloperToolsSupport.ColorResource(name: "WidgetSecondaryBackground", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "Bluesky_Logo" asset catalog image resource.
    static let blueskyLogo = DeveloperToolsSupport.ImageResource(name: "Bluesky_Logo", bundle: resourceBundle)

    /// The "Close" asset catalog image resource.
    static let close = DeveloperToolsSupport.ImageResource(name: "Close", bundle: resourceBundle)

    /// The "Gear" asset catalog image resource.
    static let gear = DeveloperToolsSupport.ImageResource(name: "Gear", bundle: resourceBundle)

    /// The "GitHub_Logo" asset catalog image resource.
    static let gitHubLogo = DeveloperToolsSupport.ImageResource(name: "GitHub_Logo", bundle: resourceBundle)

    /// The "LinkedIn_Logo" asset catalog image resource.
    static let linkedInLogo = DeveloperToolsSupport.ImageResource(name: "LinkedIn_Logo", bundle: resourceBundle)

    /// The "VTGymApp_Logo" asset catalog image resource.
    static let vtGymAppLogo = DeveloperToolsSupport.ImageResource(name: "VTGymApp_Logo", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "AccentColor" asset catalog color.
    static var accent: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accent)
#else
        .init()
#endif
    }

    /// The "BorderColor" asset catalog color.
    static var border: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .border)
#else
        .init()
#endif
    }

    /// The "CardBackground" asset catalog color.
    static var cardBackground: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cardBackground)
#else
        .init()
#endif
    }

    /// The "CustomGreen" asset catalog color.
    static var customGreen: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .customGreen)
#else
        .init()
#endif
    }

    /// The "CustomMaroon" asset catalog color.
    static var customMaroon: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .customMaroon)
#else
        .init()
#endif
    }

    /// The "CustomOrange" asset catalog color.
    static var customOrange: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .customOrange)
#else
        .init()
#endif
    }

    /// The "SecondaryBackground" asset catalog color.
    static var secondaryBackground: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .secondaryBackground)
#else
        .init()
#endif
    }

    /// The "WidgetBorderColor" asset catalog color.
    static var widgetBorder: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .widgetBorder)
#else
        .init()
#endif
    }

    /// The "WidgetCardBackground" asset catalog color.
    static var widgetCardBackground: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .widgetCardBackground)
#else
        .init()
#endif
    }

    /// The "WidgetCustomGreen" asset catalog color.
    static var widgetCustomGreen: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .widgetCustomGreen)
#else
        .init()
#endif
    }

    /// The "WidgetCustomMaroon" asset catalog color.
    static var widgetCustomMaroon: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .widgetCustomMaroon)
#else
        .init()
#endif
    }

    /// The "WidgetCustomOrange" asset catalog color.
    static var widgetCustomOrange: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .widgetCustomOrange)
#else
        .init()
#endif
    }

    /// The "WidgetSecondaryBackground" asset catalog color.
    static var widgetSecondaryBackground: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .widgetSecondaryBackground)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "AccentColor" asset catalog color.
    static var accent: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .accent)
#else
        .init()
#endif
    }

    /// The "BorderColor" asset catalog color.
    static var border: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .border)
#else
        .init()
#endif
    }

    /// The "CardBackground" asset catalog color.
    static var cardBackground: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .cardBackground)
#else
        .init()
#endif
    }

    /// The "CustomGreen" asset catalog color.
    static var customGreen: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .customGreen)
#else
        .init()
#endif
    }

    /// The "CustomMaroon" asset catalog color.
    static var customMaroon: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .customMaroon)
#else
        .init()
#endif
    }

    /// The "CustomOrange" asset catalog color.
    static var customOrange: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .customOrange)
#else
        .init()
#endif
    }

    /// The "SecondaryBackground" asset catalog color.
    static var secondaryBackground: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .secondaryBackground)
#else
        .init()
#endif
    }

    /// The "WidgetBorderColor" asset catalog color.
    static var widgetBorder: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .widgetBorder)
#else
        .init()
#endif
    }

    /// The "WidgetCardBackground" asset catalog color.
    static var widgetCardBackground: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .widgetCardBackground)
#else
        .init()
#endif
    }

    /// The "WidgetCustomGreen" asset catalog color.
    static var widgetCustomGreen: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .widgetCustomGreen)
#else
        .init()
#endif
    }

    /// The "WidgetCustomMaroon" asset catalog color.
    static var widgetCustomMaroon: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .widgetCustomMaroon)
#else
        .init()
#endif
    }

    /// The "WidgetCustomOrange" asset catalog color.
    static var widgetCustomOrange: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .widgetCustomOrange)
#else
        .init()
#endif
    }

    /// The "WidgetSecondaryBackground" asset catalog color.
    static var widgetSecondaryBackground: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .widgetSecondaryBackground)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

    /// The "BorderColor" asset catalog color.
    static var border: SwiftUI.Color { .init(.border) }

    /// The "CardBackground" asset catalog color.
    static var cardBackground: SwiftUI.Color { .init(.cardBackground) }

    /// The "CustomGreen" asset catalog color.
    static var customGreen: SwiftUI.Color { .init(.customGreen) }

    /// The "CustomMaroon" asset catalog color.
    static var customMaroon: SwiftUI.Color { .init(.customMaroon) }

    /// The "CustomOrange" asset catalog color.
    static var customOrange: SwiftUI.Color { .init(.customOrange) }

    /// The "SecondaryBackground" asset catalog color.
    static var secondaryBackground: SwiftUI.Color { .init(.secondaryBackground) }

    /// The "WidgetBorderColor" asset catalog color.
    static var widgetBorder: SwiftUI.Color { .init(.widgetBorder) }

    /// The "WidgetCardBackground" asset catalog color.
    static var widgetCardBackground: SwiftUI.Color { .init(.widgetCardBackground) }

    /// The "WidgetCustomGreen" asset catalog color.
    static var widgetCustomGreen: SwiftUI.Color { .init(.widgetCustomGreen) }

    /// The "WidgetCustomMaroon" asset catalog color.
    static var widgetCustomMaroon: SwiftUI.Color { .init(.widgetCustomMaroon) }

    /// The "WidgetCustomOrange" asset catalog color.
    static var widgetCustomOrange: SwiftUI.Color { .init(.widgetCustomOrange) }

    /// The "WidgetSecondaryBackground" asset catalog color.
    static var widgetSecondaryBackground: SwiftUI.Color { .init(.widgetSecondaryBackground) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

    /// The "BorderColor" asset catalog color.
    static var border: SwiftUI.Color { .init(.border) }

    /// The "CardBackground" asset catalog color.
    static var cardBackground: SwiftUI.Color { .init(.cardBackground) }

    /// The "CustomGreen" asset catalog color.
    static var customGreen: SwiftUI.Color { .init(.customGreen) }

    /// The "CustomMaroon" asset catalog color.
    static var customMaroon: SwiftUI.Color { .init(.customMaroon) }

    /// The "CustomOrange" asset catalog color.
    static var customOrange: SwiftUI.Color { .init(.customOrange) }

    /// The "SecondaryBackground" asset catalog color.
    static var secondaryBackground: SwiftUI.Color { .init(.secondaryBackground) }

    /// The "WidgetBorderColor" asset catalog color.
    static var widgetBorder: SwiftUI.Color { .init(.widgetBorder) }

    /// The "WidgetCardBackground" asset catalog color.
    static var widgetCardBackground: SwiftUI.Color { .init(.widgetCardBackground) }

    /// The "WidgetCustomGreen" asset catalog color.
    static var widgetCustomGreen: SwiftUI.Color { .init(.widgetCustomGreen) }

    /// The "WidgetCustomMaroon" asset catalog color.
    static var widgetCustomMaroon: SwiftUI.Color { .init(.widgetCustomMaroon) }

    /// The "WidgetCustomOrange" asset catalog color.
    static var widgetCustomOrange: SwiftUI.Color { .init(.widgetCustomOrange) }

    /// The "WidgetSecondaryBackground" asset catalog color.
    static var widgetSecondaryBackground: SwiftUI.Color { .init(.widgetSecondaryBackground) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "Bluesky_Logo" asset catalog image.
    static var blueskyLogo: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .blueskyLogo)
#else
        .init()
#endif
    }

    /// The "Close" asset catalog image.
    static var close: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .close)
#else
        .init()
#endif
    }

    /// The "Gear" asset catalog image.
    static var gear: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .gear)
#else
        .init()
#endif
    }

    /// The "GitHub_Logo" asset catalog image.
    static var gitHubLogo: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .gitHubLogo)
#else
        .init()
#endif
    }

    /// The "LinkedIn_Logo" asset catalog image.
    static var linkedInLogo: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .linkedInLogo)
#else
        .init()
#endif
    }

    /// The "VTGymApp_Logo" asset catalog image.
    static var vtGymAppLogo: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .vtGymAppLogo)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "Bluesky_Logo" asset catalog image.
    static var blueskyLogo: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .blueskyLogo)
#else
        .init()
#endif
    }

    /// The "Close" asset catalog image.
    static var close: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .close)
#else
        .init()
#endif
    }

    /// The "Gear" asset catalog image.
    static var gear: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .gear)
#else
        .init()
#endif
    }

    /// The "GitHub_Logo" asset catalog image.
    static var gitHubLogo: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .gitHubLogo)
#else
        .init()
#endif
    }

    /// The "LinkedIn_Logo" asset catalog image.
    static var linkedInLogo: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .linkedInLogo)
#else
        .init()
#endif
    }

    /// The "VTGymApp_Logo" asset catalog image.
    static var vtGymAppLogo: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .vtGymAppLogo)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

