//
//  ContentView.swift
//  CustomScrollView
//
//  Created by Huynh Tan Phu on 4/9/20.
//  Copyright © 2020 Filesoft. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        CustomScrollView {
            ForEach(0...100, id: \.self) { index in
                VStack {
                    Text("Item \(index)")
                        .padding()
                        .background(Color.yellow)
                    Divider()
                }
               
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

public struct CustomScrollView <Content: View> : View {
    @State var contentHeight: CGFloat = .zero
    @State var contentOffset: CGFloat = .zero
    @State var dragDistance: CGFloat = .zero
    let content: Content
    
    public init(@ViewBuilder content: ()-> Content) {
        self.content = content()
    }
    
    public var body: some View {
        GeometryReader { proxy in
            VStack {
                self.content
            }
            .modifier(ContentHeightGetter())
            .onPreferenceChange(ContentHeightKey.self) {
                self.updateContentHeight($0)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            .offset(y: self.contentOffset + self.dragDistance)
            .animation(.spring())
            .gesture(
                DragGesture()
                    .onChanged { self.onChanged($0) }
                    .onEnded { self.onEnded($0, scrollHeight: proxy.size.height) }
            )
                
        }
        .clipped()
    }
    
    func updateContentHeight(_ height: CGFloat) {
        self.contentHeight = height
    }
    
    func onChanged(_ value: DragGesture.Value) {
        self.dragDistance = value.location.y - value.startLocation.y
    }
    
    func onEnded(_ value: DragGesture.Value, scrollHeight: CGFloat) {
        self.dragDistance = .zero
        let predictedDragDistance = value.predictedEndLocation.y - value.startLocation.y
        self.updateContentOffset(dragDistance: predictedDragDistance, scrollHeight: scrollHeight)
    }
    
    func updateContentOffset(dragDistance: CGFloat, scrollHeight: CGFloat) {
        let difference = self.contentHeight - scrollHeight
        if difference <= .zero {
            self.contentOffset = .zero
        } else {
            var proposedOffset = self.contentOffset + dragDistance
            print(proposedOffset)
            if proposedOffset > .zero {
                proposedOffset = .zero
            } else if abs(proposedOffset) > difference {
                proposedOffset = -difference
            }
            self.contentOffset = proposedOffset
        }
    }
}

struct ContentHeightKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue: CGFloat {0}
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = value + nextValue()
    }
}

struct ContentHeightGetter: ViewModifier {
    func body(content: Content) -> some View {
        return content.background(
            GeometryReader { proxy in
                Color.clear.preference(key: ContentHeightKey.self, value: proxy.size.height)
            }
        )
    }
}
