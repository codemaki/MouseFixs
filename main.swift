import Cocoa

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Make it a regular app that can show UI
app.setActivationPolicy(.accessory)

app.run()
