import Foundation
import ThoughtsTypes

enum OneThoughtViewAction {
  /// Save a thought.
  case save
  
  /// User was looking at an existing thought and tapped edit button
  case editExisting(Thought)
  
  case cancelEditExisting
}

@MainActor
class OneThoughtViewModel: ObservableObject {
  @Published var title = ""
  @Published var body = ""

  /// Thought represented by the current state.
  var thought: Thought?
  
  let kind: OneThoughtView.Kind
  @Published private(set) var state: OneThoughtView.State
  private let store: Store
  
  // Initializer for live use.
  // Maybe add another initializer for previews with view state, when we get view state
  init(store: Store, kind: OneThoughtView.Kind, state: OneThoughtView.State) {
    self.store = store
    self.kind = kind
    self.state = state
    
    switch kind {
    case .existing(let thought):
      self.thought = thought
    default: break
    }
    
    switch state {
    case .editing:
      if let thought {
        title = thought.title
        body = thought.body
      }
    default: break
    }
  }
  
  deinit {
    print("OneThoughtViewModel deinit")
  }
  
  func send(_ action: OneThoughtViewAction) {
    switch action {
    case .save:
      Task {
        switch kind {
        case .new:
          await store.send(.saveNewThought(title: title, body: body))
        case .existing(let thought):
          let updatedLocalThought = Thought(
            id: thought.id,
            title: title,
            body: body,
            createdAt: thought.createdAt,
            modifiedAt: thought.modifiedAt
          )
          await MainActor.run {
            // Update the thought shown in the UI.
            // This will likely be updated from the server side after the thought is saved.
            self.thought = updatedLocalThought
            self.state = .viewing
          }
          // Optimistically updated the UI before the save is completed.
          await store.send(.modifyExistingThought(thought: thought, title: title, body: body))
        }
      }
    case .cancelEditExisting:
      switch kind {
      case .existing:
        state = .viewing
      default: break // should not get to this case.
      }
    case .editExisting(let thought):
      title = thought.title
      body = thought.body
      state = .editing
    }
  }
  
  var shouldShowCancelEditButton: Bool {
    switch kind {
    case .existing: return true
    default: return false
    }
  }
}
