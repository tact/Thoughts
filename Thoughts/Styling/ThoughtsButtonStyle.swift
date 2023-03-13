import SwiftUI

struct ThoughtsButton: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.title)
      .padding()
      .background(.background)
      .foregroundColor(.accentColor)
      .border(Color.accentColor)
      .opacity(configuration.isPressed ? 0.4 : 1)
  }
}

#if DEBUG
struct ThoughtsButtonStyle_Previews: PreviewProvider {
  static var previews: some View {
    Button(
      action: {},
      label: {
        Text("What")
      }
    )
    .buttonStyle(ThoughtsButton())
  }
}
#endif
