import Combine
import Foundation
import Observation
import SwiftUI

public protocol Dependencies {}
extension Never: Dependencies {}

@MainActor
@Observable
@dynamicMemberLookup
open class Feature<State, D: Dependencies> {
  /// The current state, backed by an internal CurrentValueSubject for observation.
  private let _debugID: UUID
  fileprivate let internalState: CurrentValueSubject<State, Never>
  @ObservationIgnored private var children = [AnyHashable: Any]()  // hold child models for lists
  @ObservationIgnored private var cancellables = Set<AnyCancellable>()
  public private(set) var dependencies: D

  public var state: State {
    didSet {
      // Publish state changes to internal publisher
      internalState.send(state)
    }
  }

  public required init(initialState: State, dependencies: D) {
    self.state = initialState
    self.internalState = CurrentValueSubject(initialState)
    self.dependencies = dependencies
    self._debugID = UUID()
    // print("::: init \(self._debugID)")
  }

  // Dynamic member lookup to read/write state sub-properties directly.
  public subscript<Value>(dynamicMember keyPath: KeyPath<State, Value>) -> Value {
    state[keyPath: keyPath]
  }
  public subscript<Value>(dynamicMember keyPath: WritableKeyPath<State, Value>) -> Value {
    get { state[keyPath: keyPath] }
    set { state[keyPath: keyPath] = newValue }
  }

  deinit {
    // print("::: deinit \(self._debugID)")
  }
}

extension Feature {
  /// Scope a child model from this model's state.
  public func scope<
    ChildState: Equatable,
    ChildDependencies: Dependencies,
    ChildFeature: Feature<ChildState, ChildDependencies>
  >(
    _ stateKeyPath: WritableKeyPath<State, ChildState>,
    _ modelType: ChildFeature.Type = ChildFeature.self,
    dependencies depsKeyPath: KeyPath<D, ChildDependencies>? = nil
  ) -> ChildFeature {
    let dependencies: Dependencies = {
      guard let depsKeyPath = depsKeyPath else {
        return self.dependencies
      }
      return self.dependencies[keyPath: depsKeyPath]
    }()
    // Initialize the child with the current sub-state
    let child = ChildFeature(
      initialState: state[keyPath: stateKeyPath],
      dependencies: dependencies as! ChildDependencies)
    // CHILD → PARENT: Subscribe to child's state changes
    child.internalState
      .removeDuplicates()  // only act on true changes
      .sink { [weak self] newChildState in  // weakly capture parent
        guard let self = self else { return }
        // If parent's current sub-state differs, propagate the change up
        if self.state[keyPath: stateKeyPath] != newChildState {
          self.state[keyPath: stateKeyPath] = newChildState
        }
      }
      .store(in: &child.cancellables)

    // PARENT → CHILD: Subscribe to parent state changes for this key path
    internalState
      .map { $0[keyPath: stateKeyPath] }
      .removeDuplicates()  // only act on true changes
      .sink { [weak child] newValue in  // weakly capture child
        guard let child = child else { return }
        // If child's state differs, update it to match the parent
        if child.state != newValue {
          child.state = newValue
        }
      }
      .store(in: &child.cancellables)

    return child
  }

  /// Create or update child models for each element in an IdentifiedArray in state.
  public func forEach<
    ChildState: Equatable & Identifiable,
    ChildDependencies: Dependencies,
    ChildFeature: Feature<ChildState, ChildDependencies>
  >(
    _ stateKeyPath: WritableKeyPath<State, IdentifiedArray<ChildState>>,
    _ modelType: ChildFeature.Type,
    dependencies depsKeyPath: KeyPath<D, ChildDependencies>? = nil
  ) -> [ChildFeature] where ChildState.ID: Hashable {
    let currentIDs = Set(state[keyPath: stateKeyPath].map { $0.id })
    // Remove any children that no longer exist in the state array
    for (id, _) in children {
      if let childID = id as? ChildState.ID, !currentIDs.contains(childID) {
        // Remove the child model from the dictionary
        children.removeValue(forKey: id)
      }
    }
    // Ensure every state element has an associated ChildFeature
    for element in state[keyPath: stateKeyPath] {
      if children[element.id] == nil {
        // Create a new child model for this element
        let dependencies: Dependencies = {
          guard let depsKeyPath else { return self.dependencies }
          return self.dependencies[keyPath: depsKeyPath]
        }()
        let child = ChildFeature(
          initialState: element,
          dependencies: dependencies as! ChildDependencies)
        // CHILD → PARENT subscription
        child.internalState
          .removeDuplicates()
          .sink { [weak self] updatedChildState in
            guard let self = self else { return }
            // Write the new child state back into the parent array (if different)
            if self.state[keyPath: stateKeyPath][id: element.id] != updatedChildState {
              self.state[keyPath: stateKeyPath][id: element.id] = updatedChildState
            }

          }
          .store(in: &child.cancellables)
        // PARENT → CHILD subscription
        internalState
          .compactMap { parentState -> ChildState? in
            // Extract this element's state from parent (if still exists)
            parentState[keyPath: stateKeyPath].first { $0.id == element.id }
          }
          .removeDuplicates()
          .sink { [weak child] newValue in
            guard let child = child else { return }
            // Update child's state if parent's version changed
            if child.state != newValue {
              child.state = newValue
            }
          }
          .store(in: &child.cancellables)
        children[element.id] = child
      }
    }
    // Return the array of child models in the same order as the state array
    return state[keyPath: stateKeyPath].compactMap { element in
      children[element.id] as? ChildFeature
    }
  }

  /// Create a child model from an optional state property.
  public func ifLet<
    ChildState: Equatable,
    ChildDependencies: Dependencies,
    ChildFeature: Feature<ChildState, ChildDependencies>
  >(
    _ stateKeyPath: WritableKeyPath<State, ChildState?>,
    _ modelType: ChildFeature.Type = ChildFeature.self,
    dependencies depsKeyPath: KeyPath<D, ChildDependencies>? = nil
  ) -> ChildFeature? {
    guard let childState = state[keyPath: stateKeyPath] else {
      return nil
    }

    let dependencies: Dependencies = {
      guard let depsKeyPath = depsKeyPath else {
        return self.dependencies
      }
      return self.dependencies[keyPath: depsKeyPath]
    }()

    // Initialize the child with the current sub-state
    let child = ChildFeature(
      initialState: childState,
      dependencies: dependencies as! ChildDependencies)

    // CHILD → PARENT: Subscribe to child's state changes
    child.internalState
      .removeDuplicates()  // only act on true changes
      .sink { [weak self] newChildState in  // weakly capture parent
        guard let self = self else { return }
        // If parent's current sub-state differs, propagate the change up
        if self.state[keyPath: stateKeyPath] != newChildState {
          self.state[keyPath: stateKeyPath] = newChildState
        }
      }
      .store(in: &child.cancellables)

    // PARENT → CHILD: Subscribe to parent state changes for this key path
    internalState
      .map { $0[keyPath: stateKeyPath] }
      .compactMap { $0 }  // Filter out nil values
      .removeDuplicates()  // only act on true changes
      .sink { [weak child] newValue in  // weakly capture child
        guard let child = child else { return }
        // If child's state differs, update it to match the parent
        if child.state != newValue {
          child.state = newValue
        }
      }
      .store(in: &child.cancellables)

    return child
  }
}

extension Feature {
  public func effect(_ work: @escaping () async throws -> Void) {
    Task {
      try await work()
    }
  }

  public func ifLet<T>(_ keyPath: WritableKeyPath<State, T?>) -> Binding<Bool> {
    Binding(
      get: { self.state[keyPath: keyPath] != nil },
      set: { _ in self.state[keyPath: keyPath] = nil }
    )
  }
}
