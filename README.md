# CustomScrollView
A CustomScrollView that supports scrolling to top, scroll to bottom and scroll to an content offset.

![Custom scroll view](custom_scrollview.gif)

## Support Platforms
- iOS
- macOS

## Axis
- Vertical (supported)
- Horizontal (not available yet)

## Key features
- Scroll to top
- Scroll to bottom
- Scroll to an y offset
- Show/hide vertical indicator

## Usage
```swift
struct ContentView: View {
    @State var attribute = CustomScrollAttribute()
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
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
