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

// TODO:
// [x] editing in the table itself - not possible due to weird Swift limitations
// [ ] automatic computation of divisor
// [ ] what is filter offset? is it different from anchor?
// [x] literal edge cases - by default the pixels outside have value 0.0 (black), so I leave this as it is an acceptable solution (as mentioned on lectures)
// [ ] saving image to a file
// [ ] contrast enhancement

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
