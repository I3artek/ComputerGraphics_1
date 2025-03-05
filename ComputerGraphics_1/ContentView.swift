//
//  ContentView.swift
//  ComputerGraphics_1
//
//  Created by I3artek on 21/02/2025.
//
// Links to resources used:
// https://metalbyexample.com/fundamentals-of-image-processing/
// https://www.hackingwithswift.com/books/ios-swiftui/integrating-core-image-with-swiftui
// https://medium.com/@garejakirit/a-beginners-guide-to-metal-shaders-in-swiftui-5e98ef3cb222

// https://flexmonkey.blogspot.com/2014/10/metal-kernel-functions-compute-shaders.html

import SwiftUI

struct ContentView: View {
    @State private var image: Image?
    @State private var new_image: Image?
    
    var body: some View {
        HStack {
            TwoImages()
        }
    }
}

#Preview {
    ContentView()
}
