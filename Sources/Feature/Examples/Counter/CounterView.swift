import SwiftUI

struct CounterView: View {
    @State private var feature = CounterFeature(
        initialState: CounterState(),
        dependencies: CounterDependencies()
    )
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Count: \(feature.count)")
                .font(.title)
            
            HStack(spacing: 20) {
                Button("-") { feature.decrement() }
                Button("+") { feature.increment() }
            }
        }
        .buttonStyle(.bordered)
    }
}

#Preview {
    CounterView()
}
