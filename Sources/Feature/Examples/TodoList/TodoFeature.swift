import SwiftUI

struct TodoState: Equatable, Identifiable {
  let id: UUID
  var text: String
  var isCompleted: Bool

  init(id: UUID = UUID(), text: String, isCompleted: Bool = false) {
    self.id = id
    self.text = text
    self.isCompleted = isCompleted
  }
}

struct TodoListState: Equatable {
  var todos: IdentifiedArray<TodoState> = []
  var newTodoText: String = ""
}

struct TodoListDependencies: Dependencies {}

class TodoListFeature: Feature<TodoListState, TodoListDependencies> {
  var todoFeatures: [TodoFeature] {
    forEach(\.todos, TodoFeature.self)
  }

  func addTodo() {
    guard !state.newTodoText.isEmpty else { return }
    state.todos.append(TodoState(text: state.newTodoText))
    state.newTodoText = ""
  }

  func removeTodo(at indexSet: IndexSet) {
    state.todos.remove(atOffsets: indexSet)
  }
}

class TodoFeature: Feature<TodoState, TodoListDependencies>, Identifiable {
  func toggleCompleted() {
    state.isCompleted.toggle()
  }
}
