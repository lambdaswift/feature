# Feature

A Swift package for managing feature state with composable parent-child relationships and dependency injection.

## Overview

Feature provides a powerful way to manage state in your Swift applications using a Feature-based architecture. It supports:

- Observable state management
- Type-safe dependency injection
- Parent-child state composition
- Collection state management
- Optional state handling
- Effect management

## Requirements

- iOS 17.0+
- macOS 14.0+
- watchOS 10.0+
- tvOS 17.0+
- visionOS 1.0+

## Installation

Add Feature to your Swift package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/lambdaswift/feature", from: "0.0.1")
]
```

## Usage

### Basic Feature

Create a feature by defining its state and dependencies:

```swift
// Define your state
struct CounterState: Equatable {
    var count: Int = 0
}

// Define dependencies (if needed)
struct CounterDependencies: Dependencies {}

// Create your feature model
class CounterFeature: Feature<CounterState, CounterDependencies> {
    func increment() {
        state.count += 1
    }
}
```

### Child Features

Compose features using scope operators:

```swift
// Parent state
struct ParentState: Equatable {
    var counter: CounterState = .init()
}

class ParentFeature: Feature<ParentState, ParentDependencies> {
    lazy var counter = scope(\.counter, CounterFeature.self)
}
```

### Collection Features

Manage collections of child features:

```swift
struct TodoState: Equatable, Identifiable {
    let id: UUID
    var text: String
}

// Parent state with collection
struct TodoListState: Equatable {
    var todos: IdentifiedArray<TodoState> = []
}

class TodoListFeature: Feature<TodoListState, TodoDependencies> {
    var todoFeatures: [TodoFeature] {
        forEach(\.todos, TodoFeature.self)
    }
}
```

### Optional Features

Handle optional child states:

```swift
struct ParentState: Equatable {
    var modal: ModalState?
}

class ParentFeature: Feature<ParentState, ParentDependencies> {
    var modalFeature: ModalFeature? {
        ifLet(\.modal, ModalFeature.self)
    }
}
```

### Effects

Perform asynchronous operations:

```swift
func fetchData() {
    effect {
        // Async work here
        try await networkCall()
        self.state.data = result
    }
}
```

## Features

- **@Observable State**: Automatic state observation and updates
- **Dynamic Member Lookup**: Direct state property access
- **Dependency Injection**: Type-safe dependency management
- **State Composition**: Easy parent-child state relationships
- **Collection Management**: Efficient handling of arrays of child features
- **Optional State**: Clean handling of optional child features
- **Effect Management**: Simple async operation handling

## License

[Your License Here]
