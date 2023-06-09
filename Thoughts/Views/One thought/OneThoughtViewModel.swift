import Combine
import Foundation
import os.log
import SwiftUI
import ThoughtsTypes

enum OneThoughtViewAction {
  /// Done editing a thought.
  ///
  /// Save if there were any changes to the content.
  case done
  
  /// User was looking at an existing thought and tapped edit button
  case editExisting(Thought)
}

@MainActor
class OneThoughtViewModel: ObservableObject {
  enum Field: Hashable, Equatable {
    case title
    case body
  }
  
  private let store: Store
  let kind: OneThoughtView.Kind
  @Published private(set) var state: OneThoughtView.State

  @Published private(set) var thought: Thought?
  @Published var title = ""
  @Published var body = ""
  @Published var focusedField: Field?
  
  private var thoughtCancellable: AnyCancellable?
  private let logger = Logger(subsystem: "Thoughts", category: "OneThoughtViewModel")
  
  init(store: Store, kind: OneThoughtView.Kind, state: OneThoughtView.State) {
    self.store = store
    self.kind = kind
    self.state = state
    
    switch kind {
    case let .existing(thought):
      self.thought = thought
      Task {
        // Watch for changes in the source of truth, and update the local UI with the updated thought.
        self.thoughtCancellable = await store.$thoughts
          .receive(on: DispatchQueue.main)
          .sink(receiveValue: { [weak self] updatedThoughts in
            // [weak self] is important here. Otherwise there’s a retain cycle
            // and OneThoughtViewModel is never released.
            if let updatedThought = updatedThoughts[id: thought.id] {
              self?.thought = updatedThought
            }
          })
      }
    case .new:
      self.state = .editing
    }
    
    switch state {
    case .editing:
      if let thought {
        self.title = thought.title
        self.body = thought.body
      }
    default: break
    }
  }
    
  deinit {
    // Visually inspect in the console that the view model
    // is correctly released when you navigate away from it.
    // Try removing [weak self] in the above cancellable sink
    // and see that OneThoughtViewModel then never gets released.
    logger.debug("deinit")
  }
  
  func send(_ action: OneThoughtViewAction) async {
    switch action {
    case let .editExisting(thought):
      title = thought.title
      body = thought.body
      state = .editing
      focusedField = .body
    case .done:
      switch kind {
      case .new:
        await store.send(.saveNewThought(title: title, body: body))
      case let .existing(thought):
        await MainActor.run {
          self.state = .viewing
        }
        if title != thought.title || body != thought.body {
          logger.debug("Saving changes to the thought.")
          await store.send(.modifyExistingThought(thought: thought, title: title, body: body))
          
          // We did not update the local UI after saving. There will be two store updates:
          // 1) immediately on modification, Store saves the modified thought to local store,
          // and this gets reflected back to this view model with the thoughtCancellable.
          // 2) after a successful CloudKit save, there will be another update where the
          // modifiedAt is updated, and this gets reflected back through the same cancellable.
          
        } else {
          logger.debug("No edits. Just reverting back to view state.")
        }
      }
    }
  }
  
  var navigationTitle: String {
    switch kind {
    case .new: return "Add thought"
    case .existing:
      return state == .editing ? "" : thought!.title
    }
  }
  
  var shouldDismissOnDone: Bool {
    kind == .new
  }
  
  var shouldEnableSave: Bool {
    guard state == .editing else { return false }
    return !title.isEmpty || !body.isEmpty
  }
  
  #if os(iOS)
    var navigationBarTitleDisplayMode: NavigationBarItem.TitleDisplayMode {
      state == .editing ? .inline : .automatic
    }
  #endif
}
