import SwiftUI

struct CounterState: Equatable {
  var count: Int = 0
}

struct CounterDependencies: Dependencies {}

class CounterFeature: Feature<CounterState, CounterDependencies> {
  func increment() {
    state.count += 1
  }

  func decrement() {
    state.count -= 1
  }
}
