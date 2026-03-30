//
//  AccessibilityHelpers.swift
//  BookBrowser
//
//  Created by Sanjay Kumar on 31/03/2026.
//

import SwiftUI

// MARK: - VoiceOver Announcements

/// Posts a VoiceOver announcement when a value changes.
struct AccessibilityAnnouncementModifier<Value: Equatable>: ViewModifier {
    
    let value: Value
    let message: (Value) -> String?
    
    func body(content: Content) -> some View {
        content
            .onChange(of: value) { _, newValue in
                if let announcement = message(newValue) {
                    // Short delay so VoiceOver finishes current speech first
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(500))
                        guard !Task.isCancelled else { return }
                        UIAccessibility.post(
                            notification: .announcement,
                            argument: announcement
                        )
                    }
                }
            }
    }
}

extension View {
    /// Return `nil` from the closure to skip announcement for that value.
    func announceChange<Value: Equatable>(
        for value: Value,
        message: @escaping (Value) -> String?
    ) -> some View {
        modifier(AccessibilityAnnouncementModifier(value: value, message: message))
    }
}

// MARK: - Scalable Cover Image

/// Scales cover images with Dynamic Type — larger text = larger covers.
struct ScaledCoverFrameModifier: ViewModifier {
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    private let baseWidth: CGFloat
    private let baseHeight: CGFloat
    
    init(baseWidth: CGFloat = 60, baseHeight: CGFloat = 90) {
        self.baseWidth = baseWidth
        self.baseHeight = baseHeight
    }
    
    func body(content: Content) -> some View {
        content
            .frame(width: baseWidth * scaleFactor, height: baseHeight * scaleFactor)
    }
    
    private var scaleFactor: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium, .large:       1.0
        case .xLarge:                                 1.15
        case .xxLarge:                                1.25
        case .xxxLarge:                               1.35
        case .accessibility1:                         1.5
        case .accessibility2:                         1.65
        case .accessibility3, .accessibility4, .accessibility5: 1.8
        @unknown default:                             1.0
        }
    }
}

extension View {
    func scaledCoverFrame(baseWidth: CGFloat = 60, baseHeight: CGFloat = 90) -> some View {
        modifier(ScaledCoverFrameModifier(baseWidth: baseWidth, baseHeight: baseHeight))
    }
}

// MARK: - Adaptive Layout

/// HStack at normal sizes, VStack at accessibility sizes.
struct AdaptiveBookRowLayout<Content: View>: View {
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
        } else {
            HStack(spacing: 14) {
                content()
            }
        }
    }
}

