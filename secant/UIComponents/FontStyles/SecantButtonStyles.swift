//
//  SecantButtonStyles.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 22.02.2022.
//

import SwiftUI

extension Button {
    func titleText() -> some View {
        self.modifier(TitleTextStyle())
    }

    private struct TitleTextStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .foregroundColor(Asset.Colors.Text.heading.color)
                .font(.custom(FontFamily.Rubik.regular.name, size: 15))
                .shadow(color: Asset.Colors.Text.captionTextShadow.color, radius: 1, x: 0, y: 1)
        }
    }
}
