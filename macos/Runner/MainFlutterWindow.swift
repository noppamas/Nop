import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // The Flutter toolbar shares the title-bar row with the window controls:
    // hide the native title, let content run under the title bar, and use an
    // empty unified toolbar so the row is tall enough and the window controls
    // sit vertically centered in it.
    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    self.styleMask.insert(.fullSizeContentView)
    let toolbar = NSToolbar(identifier: "MainToolbar")
    toolbar.showsBaselineSeparator = false
    self.toolbar = toolbar
    self.toolbarStyle = .unified

    RegisterGeneratedPlugins(registry: flutterViewController)

    let windowChannel = FlutterMethodChannel(
      name: "json_better_editor/window",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    windowChannel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(nil)
        return
      }
      switch call.method {
      case "setTitle":
        if let title = call.arguments as? String {
          self.title = title
        }
        result(nil)
      case "getTitle":
        result(self.title)
      case "startDrag":
        if let event = NSApp.currentEvent {
          self.performDrag(with: event)
        }
        result(nil)
      case "zoom":
        self.zoom(nil)
        result(nil)
      case "windowControlsFrame":
        result(self.windowControlsFrame())
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }

  /// Union of the close/minimize/zoom buttons, in Flutter (top-left origin)
  /// coordinates of the content view.
  private func windowControlsFrame() -> [String: Double]? {
    guard let contentView = self.contentView else { return nil }
    var union = NSRect.null
    for type in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
      guard let button = self.standardWindowButton(type),
        let superview = button.superview
      else { continue }
      let inWindow = superview.convert(button.frame, to: nil)
      let inContent = contentView.convert(inWindow, from: nil)
      union = union.union(inContent)
    }
    if union.isNull { return nil }
    let height = contentView.bounds.height
    let top = contentView.isFlipped ? union.minY : height - union.maxY
    return [
      "left": Double(union.minX),
      "top": Double(top),
      "right": Double(union.maxX),
      "bottom": Double(top + union.height),
    ]
  }
}
