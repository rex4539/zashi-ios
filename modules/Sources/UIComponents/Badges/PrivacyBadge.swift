//
//  PrivacyBadge.swift
//  Zashi
//
//  Created by Lukáš Korba on 09-19-2024.
//

import SwiftUI

import Generated

public struct PrivacyBadge: View {
    public enum Privacy {
        case low
        case max
    }
    
    let privacy: Privacy
    
    public init(_ privacy: Privacy) {
        self.privacy = privacy
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            if privacy == .max {
                Asset.Assets.Icons.shieldTickFilled.image
                    .zImage(size: 14, style: Design.Utility.Purple._700)
                    .padding(.trailing, 4)
            } else {
                Asset.Assets.Icons.alertCircle.image
                    .zImage(size: 14, style: Design.Utility.WarningYellow._700)
                    .padding(.trailing, 4)
            }
            
            Text(privacy == .max
                 ? L10n.Component.maxPrivacy
                 : L10n.Component.lowPrivacy
            )
            .zFont(
                .medium,
                size: 14,
                style: privacy == .max
                ? Design.Utility.Purple._700
                : Design.Utility.WarningYellow._700
            )
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 10)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(privacy == .max
                      ? Design.Utility.Purple._50.color
                      : Design.Utility.WarningYellow._50.color
                )
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(privacy == .max
                                ? Design.Utility.Purple._200.color
                                : Design.Utility.WarningYellow._200.color
                        )
                }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        PrivacyBadge(.max)
        PrivacyBadge(.low)
    }
}