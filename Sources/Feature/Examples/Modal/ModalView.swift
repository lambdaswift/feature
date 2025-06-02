import SwiftUI

struct RootView: View {
    @State private var feature = RootFeature(
        initialState: RootState(),
        dependencies: RootDependencies()
    )
    
    var body: some View {
        Button("Show Modal") {
            feature.showModal()
        }
        .sheet(
            isPresented: feature.ifLet(\.modal)
        ) {
            if let modalFeature = feature.modalFeature {
                ModalView(feature: modalFeature)
            }
        }
    }
}

struct ModalView: View {
    let feature: ModalFeature
    
    var body: some View {
        NavigationStack {
            VStack {
                Text(feature.text)
                TextField("Enter text", text: Binding(
                    get: { feature.text },
                    set: { feature.updateText($0) }
                ))
                .textFieldStyle(.roundedBorder)
                .padding()
            }
            .navigationTitle("Modal")
        }
    }
}

#Preview {
    RootView()
}
