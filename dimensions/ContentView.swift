//
//  ContentView.swift
//  dimensions
//
//  Created by Егор Каверин on 16.07.2025.
//

import SwiftUI

struct ContentView: View {
    init() {
        testRotation()
        testVectorOperations()
    }
    
    var body: some View {
        MetalViewWrapper()
            .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
