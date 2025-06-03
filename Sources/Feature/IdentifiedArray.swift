import Foundation

/// A lightweight implementation of an identified collection.
/// A collection that maintains a sorted array of `Identifiable` elements while providing O(1) access by ID
/// and ensuring unique IDs.
public struct IdentifiedArray<Element: Identifiable> where Element.ID: Hashable & Sendable {
  private var elements: [Element]
  private var idToIndex: [Element.ID: Int]

  /// Creates an empty `IdentifiedArray`.
  public init() {
    self.elements = []
    self.idToIndex = [:]
  }

  /// Creates an `IdentifiedArray` from a sequence of elements.
  /// - Parameter elements: The elements to include in the array.
  public init<S: Sequence>(_ elements: S) where S.Element == Element {
    self.elements = Array(elements)
    self.idToIndex = [:]

    // Build the index map and check for duplicates
    for (index, element) in self.elements.enumerated() {
      if idToIndex[element.id] != nil {
        fatalError("Duplicate ID found: \(element.id)")
      }
      idToIndex[element.id] = index
    }
  }

  /// The number of elements in the array.
  public var count: Int {
    elements.count
  }

  /// A Boolean value indicating whether the array is empty.
  public var isEmpty: Bool {
    elements.isEmpty
  }

  /// Returns the element with the specified ID.
  /// - Parameter id: The ID of the element to retrieve.
  /// - Returns: The element with the specified ID, or `nil` if no such element exists.
  public subscript(id id: Element.ID) -> Element? {
    get {
      guard let index = idToIndex[id] else { return nil }
      return elements[index]
    }
    set {
      if let newValue {
        if let index = idToIndex[id] {
          elements[index] = newValue
        } else {
          self.append(newValue)
        }
      } else {
        remove(id: id)
      }
    }
  }

  /// Returns the element at the specified position.
  /// - Parameter index: The position of the element to access.
  /// - Returns: The element at the specified position.
  public subscript(index: Int) -> Element {
    elements[index]
  }

  /// Inserts a new element into the array at the specified position.
  /// - Parameters:
  ///   - element: The element to insert.
  ///   - index: The position at which to insert the element.
  public mutating func insert(_ element: Element, at index: Int) {
    if idToIndex[element.id] != nil {
      fatalError("Duplicate ID found: \(element.id)")
    }

    // Insert the element at the specified index
    elements.insert(element, at: index)

    // Update the index map
    for i in index..<elements.count {
      idToIndex[elements[i].id] = i
    }
  }

  /// Removes the element with the specified ID.
  /// - Parameter id: The ID of the element to remove.
  /// - Returns: The removed element, or `nil` if no element with the specified ID exists.
  @discardableResult
  public mutating func remove(id: Element.ID) -> Element? {
    guard let index = idToIndex[id] else { return nil }
    let element = elements.remove(at: index)
    idToIndex.removeValue(forKey: id)

    // Update the index map for elements after the removed one
    for i in index..<elements.count {
      idToIndex[elements[i].id] = i
    }

    return element
  }

  /// Removes elements by an index set
  public mutating func remove(atOffsets offsets: IndexSet) {
    // Remove elements at specified indices
    for index in offsets.reversed() {
      let removedElement = elements.remove(at: index)
      idToIndex.removeValue(forKey: removedElement.id)
    }

    // Rebuild index map
    for (index, element) in elements.enumerated() {
      idToIndex[element.id] = index
    }
  }

  /// Removes all elements from the array.
  public mutating func removeAll() {
    elements.removeAll()
    idToIndex.removeAll()
  }

  /// Appends a new element to the end of the array.
  /// - Parameter element: The element to append.
  public mutating func append(_ element: Element) {
    if idToIndex[element.id] != nil {
      fatalError("Duplicate ID found: \(element.id)")
    }

    let index = elements.count
    elements.append(element)
    idToIndex[element.id] = index
  }
}

// MARK: - Sequence Conformance
extension IdentifiedArray: Sequence {
  public func makeIterator() -> IndexingIterator<[Element]> {
    elements.makeIterator()
  }
}

// MARK: - Collection Conformance
extension IdentifiedArray: Collection {
  public var startIndex: Int { elements.startIndex }
  public var endIndex: Int { elements.endIndex }

  public func index(after i: Int) -> Int {
    elements.index(after: i)
  }
}

// MARK: - Equatable Conformance
extension IdentifiedArray: Equatable where Element: Equatable {
  public static func == (lhs: IdentifiedArray<Element>, rhs: IdentifiedArray<Element>) -> Bool {
    lhs.elements == rhs.elements
  }
}

// MARK: - Hashable Conformance
extension IdentifiedArray: Hashable where Element: Hashable {}

// MARK: - ExpressibleByArrayLiteral Conformance
extension IdentifiedArray: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: Element...) {
    self.init(elements)
  }
}

extension IdentifiedArray: Sendable where Element: Sendable {}
