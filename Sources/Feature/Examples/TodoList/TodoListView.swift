import SwiftUI

struct TodoListView: View {
  @State private var feature = TodoListFeature(
    initialState: TodoListState(),
    dependencies: TodoListDependencies()
  )

  var body: some View {
    NavigationStack {
      List {
        HStack {
          TextField("New todo", text: $feature.newTodoText)
            .textFieldStyle(.roundedBorder)

          Button("Add") { feature.addTodo() }
        }
        ForEach(feature.todoFeatures) { todoFeature in
          TodoRowView(feature: todoFeature)
        }
        .onDelete { feature.removeTodo(at: $0) }
      }
      .navigationTitle("Todos")
    }
  }
}

struct TodoRowView: View {
  let feature: TodoFeature

  var body: some View {
    HStack {
      Text(feature.text)
      Spacer()
      Toggle(
        "",
        isOn: Binding(
          get: { feature.isCompleted },
          set: { _ in feature.toggleCompleted() }
        ))
    }
  }
}

#Preview {
  TodoListView()
}
