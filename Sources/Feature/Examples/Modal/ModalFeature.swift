import SwiftUI

struct ModalState: Equatable {
  var isPresented: Bool = false
  var text: String = ""
}

struct RootState: Equatable {
  var modal: ModalState?
}

struct RootDependencies: Dependencies {}

class RootFeature: Feature<RootState, RootDependencies> {
  var modalFeature: ModalFeature? {
    ifLet(\.modal, ModalFeature.self)
  }

  func showModal() {
    state.modal = ModalState()
  }
}

class ModalFeature: Feature<ModalState, RootDependencies> {
  func updateText(_ text: String) {
    state.text = text
  }
}
