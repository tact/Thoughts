import Combine
import Foundation
import ThoughtsTypes
import os.log
import SwiftUI

enum OneThoughtViewAction {
  /// Save a thought.
  case save
  
  /// User was looking at an existing thought and tapped edit button
  case editExisting(Thought)
  
  case cancelEditExisting
}

@MainActor
class OneThoughtViewModel: ObservableObject {
  private let store: Store
  let kind: OneThoughtView.Kind
  @Published private(set) var state: OneThoughtView.State

  @Published private(set) var thought: Thought?
  @Published var title = ""
  @Published var body = ""

  private var thoughtCancellable: AnyCancellable?
  private let logger = Logger(subsystem: "Thoughts", category: "OneThoughtViewModel")
  
  init(store: Store, kind: OneThoughtView.Kind, state: OneThoughtView.State) {
    self.store = store
    self.kind = kind
    self.state = state
    
    switch kind {
    case .existing(let thought):
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
        title = thought.title
        body = thought.body
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
            // Immediately update the thought shown in the UI.
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
      default:
        logger.error("cancelEditExisting with kind \(self.kind). Should not get to this state.")
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
