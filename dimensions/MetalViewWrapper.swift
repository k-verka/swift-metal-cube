//
//  MetalViewWrapper.swift
//  dimensions
//
//  Created by Егор Каверин on 16.07.2025.
//

import Foundation
import SwiftUI

struct MetalViewWrapper: NSViewRepresentable {
    func makeNSView(context: Context) -> MetalView {
        return MetalView(frame: .zero)
    }

    func updateNSView(_ nsView: MetalView, context: Context) {
        // Обновление, если нужно
    }
}
