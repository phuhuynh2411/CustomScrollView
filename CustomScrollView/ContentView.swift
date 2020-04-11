//
//  ContentView.swift
//  CustomScrollView
//
//  Created by Huynh Tan Phu on 4/9/20.
//  Copyright © 2020 Filesoft. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State var attribute = CustomScrollAttribute()
    
    var body: some View {
        VStack {
            VStack {
                Button(action: {
                    self.attribute.scrollToBottom()
                }) {
                    Text("Scroll to bottom")
                }
                Button(action: {
                    self.attribute.scrollToTop()
                }) {
                    Text("Scroll to top")
                }
                Button(action: {
                    self.attribute.scrollTo(y: 200)
                }) {
                    Text("Scroll to y: 200")
                }
            }
            .padding()
            
            CustomScrollView(attribute: self.$attribute, showIndicators: true) {
                ForEach(0...100, id: \.self) { index in
                    VStack {
                        Text("Item \(index)")
                            .padding()
                            .background(Color.yellow)
                            .onTapGesture {
                        }
                        Divider()
                    }
                    
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
    @State var scrollHeight: CGFloat = .zero
    var showIndicators: Bool = true
    let content: Content
    @Binding var attribute: CustomScrollAttribute
    
    @State var indicatorOpactiy: Double = 0.0
    @State var indicatorScale: CGFloat = 1.0
    
    @State var lastScroll: Date = Date()
    @State var dragIndicator: Bool = false
    @State var indicatorOffset: CGFloat = .zero
    @State var indicatorDragDistance: CGFloat = .zero
    
    public init(attribute: Binding<CustomScrollAttribute>, showIndicators: Bool = true, @ViewBuilder content: ()-> Content) {
        self.content = content()
        self._attribute = attribute
        self.showIndicators = showIndicators
    }
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                self.vertical(proxy)
                self.indicator(proxy)
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
        }
        .clipped()
    }
    
    func vertical(_ proxy: GeometryProxy) -> some View {
        VStack {
            self.content
        }
        .modifier(ContentHeightGetter())
        .onPreferenceChange(ContentHeightKey.self) {
            self.updateContentHeight($0,scrollHeight: proxy.size.height)
        }
        .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
        .offset(y: self.contentOffset + self.dragDistance)
        .animation(.spring())
        .onReceive(self.attribute.$isBottom) { value in
            if value {
                self.contentOffset =  self.scrollHeight - self.contentHeight
                self.attribute.isBottom = false
            }
        }
        .onReceive(self.attribute.$isTop) { value in
            if value {
                self.contentOffset =  .zero
                self.attribute.isTop = false
            }
        }
        .onReceive(self.attribute.$scrollToY) { value in
            if value > .zero {
                self.scrollTo(y: value)
            }
        }
        .gesture(
            DragGesture()
                .onChanged { self.onChanged($0) }
                .onEnded { self.onEnded($0, scrollHeight: proxy.size.height) }
        )
    }
    
    func indicator(_ proxy:GeometryProxy) -> some View {
        HStack(alignment: .top) {
            Spacer()
            RoundedRectangle(cornerRadius: 2)
                .frame(width: 3, height: self.indicatorHeight) //88% of the content height
                .foregroundColor(Color.black.opacity(0.35))
                .padding(.trailing, 5)
                .offset(y: self.indicatorOffsetY)
                .animation(.spring())
                .scaleEffect(x: self.indicatorScale, y: 1)
                .gesture(DragGesture()
                    .onChanged { self.onIndicatorChanged(value: $0)}
                    .onEnded { self.onIndicatorEnded(value: $0, scrollHeight: proxy.size.height) }
                )
                .opacity(self.allowIndicators ? indicatorOpactiy : 0.0)
                .animation(.easeInOut)
        }
    }
    
    var indicatorOffsetY: CGFloat {
        let distance = self.contentOffset + self.dragDistance
        guard self.scrollHeight > 0, self.contentHeight > 0 else { return 0.0 }
        let topLimit = self.contentHeight - self.scrollHeight
        
        let offset = (self.scrollHeight - self.indicatorHeight) * distance / topLimit
        return self.dragIndicator ? self.indicatorOffset + self.indicatorDragDistance : -offset
    }
    
    var indicatorHeight: CGFloat {
        guard self.scrollHeight > 0, self.contentHeight > 0 else { return 0.0 }
        let ratio = self.scrollHeight/self.contentHeight
        let height = self.scrollHeight*ratio
        let minHeight: CGFloat = 44.0
        
        return height > minHeight ? height : minHeight
    }
    
    private var allowIndicators: Bool {
        self.showIndicators && self.contentHeight - self.scrollHeight > 0
    }
    
    func updateContentHeight(_ height: CGFloat, scrollHeight: CGFloat) {
        self.contentHeight = height
        self.scrollHeight = scrollHeight
    }
    
    func onChanged(_ value: DragGesture.Value) {
        self.dragDistance = value.location.y - value.startLocation.y
        self.indicatorOpactiy = 1.0
        self.lastScroll = Date()
        self.indicatorOffset = self.indicatorOffsetY
    }
    
    func onEnded(_ value: DragGesture.Value, scrollHeight: CGFloat) {
        self.dragDistance = .zero
        let predictedDragDistance = value.predictedEndLocation.y - value.startLocation.y
        self.updateContentOffset(dragDistance: predictedDragDistance, scrollHeight: scrollHeight)
        
        self.indicatorOffset = self.indicatorOffsetY
        self.hideIndicator()
    }
    
    func updateContentOffset(dragDistance: CGFloat, scrollHeight: CGFloat) {
        let difference = self.contentHeight - scrollHeight
        if difference <= .zero {
            self.contentOffset = .zero
        } else {
            var proposedOffset = self.contentOffset + dragDistance
            if proposedOffset > .zero {
                proposedOffset = .zero
            } else if abs(proposedOffset) > difference {
                proposedOffset = -difference
            }
            self.contentOffset = proposedOffset
        }
    }
    
    func scrollTo(y: CGFloat) {
        let difference = self.contentHeight - self.scrollHeight
        if y < .zero {
            self.contentOffset = .zero
        } else if y > difference {
            self.contentOffset = -difference
        }
        self.contentOffset = -y
        
        self.attribute.scrollToY = .zero
    }
    
    func onIndicatorChanged(value: DragGesture.Value) {
        self.indicatorScale = 3.0
        self.lastScroll = Date()
        self.dragIndicator = true
        self.indicatorDragDistance = value.location.y - value.startLocation.y
        
        // Update content off set
        let proposedOffset = self.indicatorOffset + indicatorDragDistance
        let topLimit = self.contentHeight - self.scrollHeight
        let offset = topLimit * proposedOffset / self.scrollHeight
        self.contentOffset = -offset
    }
    
    func onIndicatorEnded(value: DragGesture.Value, scrollHeight: CGFloat) {
        self.indicatorScale = 1.0
        self.indicatorDragDistance = .zero
        let predictedDragDistance = value.predictedEndLocation.y - value.startLocation.y
        
        self.updateIndicatorOffset(dragDistance: predictedDragDistance, scrollHeight: scrollHeight)
        self.dragIndicator = false
        self.hideIndicator()
    }
    
    func hideIndicator() {
        // Hide the indicator after 3 seconds
        // if user stops dragging
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let a = self.lastScroll.distance(to: Date())
            self.indicatorOpactiy = a > 2.0 ? 0.0 : 1.0
        }
    }
    
    func updateIndicatorOffset(dragDistance: CGFloat, scrollHeight: CGFloat) {
        let proposedOffset = self.indicatorOffset + dragDistance
        let topLimit = self.contentHeight - self.scrollHeight
        print(proposedOffset)
        if proposedOffset < .zero {
            self.indicatorOffset = .zero
            self.contentOffset = .zero
        } else if abs(proposedOffset) > self.scrollHeight - self.indicatorHeight {
            self.indicatorOffset = self.scrollHeight - self.indicatorHeight
            self.contentOffset = -topLimit
        } else {
            self.indicatorOffset = proposedOffset
            let offset = topLimit * proposedOffset / self.scrollHeight
            self.contentOffset =  -offset
        }
    }
}

public class CustomScrollAttribute {
    @Published var isBottom: Bool = false
    @Published var isTop: Bool = false
    @Published var scrollToY: CGFloat = .zero
    
    public func scrollToBottom() {
        self.isBottom = true
    }
    
    public func scrollToTop() {
        self.isTop = true
    }
    
    public func scrollTo(y: CGFloat) {
        self.scrollToY = y
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
