import Cocoa
import ApplicationServices

class MouseEventManager {

    static let shared = MouseEventManager()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private init() {}

    func startMonitoring() -> Bool {
        // Check for accessibility permissions
        guard AXIsProcessTrusted() else {
            print("⚠️ Accessibility permissions not granted for event tap")
            return false
        }

        // Define event mask for other mouse button events
        let eventMask = (1 << CGEventType.otherMouseDown.rawValue) | (1 << CGEventType.otherMouseUp.rawValue)

        // Create event tap callback
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            let manager = Unmanaged<MouseEventManager>.fromOpaque(refcon!).takeUnretainedValue()
            return manager.handleMouseEvent(proxy: proxy, type: type, event: event)
        }

        // Create event tap
        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            print("❌ Failed to create event tap")
            return false
        }

        eventTap = tap

        // Create run loop source and add to current run loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)

        // Enable the event tap
        CGEvent.tapEnable(tap: tap, enable: true)

        print("✅ Mouse event monitoring started")
        return true
    }

    func stopMonitoring() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil

        print("🛑 Mouse event monitoring stopped")
    }

    private func handleMouseEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Handle tap disabled events
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            print("⚠️ Event tap disabled, re-enabling...")
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        // Only handle mouse down events
        guard type == .otherMouseDown else {
            return Unmanaged.passUnretained(event)
        }

        // Get the mouse button number (0-indexed)
        let buttonNumber = event.getIntegerValueField(.mouseEventButtonNumber)

        print("🖱️ Mouse button \(buttonNumber) pressed")

        switch buttonNumber {
        case 3: // Button 4 (0-indexed: 3) = Forward
            print("➡️ Forward button pressed")
            sendKeyboardShortcut(keyCode: 0x1E, withCommand: true) // Command+]
            return nil // Consume the event

        case 4: // Button 5 (0-indexed: 4) = Back
            print("⬅️ Back button pressed")
            sendKeyboardShortcut(keyCode: 0x21, withCommand: true) // Command+[
            return nil // Consume the event

        default:
            // Pass through other mouse buttons
            return Unmanaged.passUnretained(event)
        }
    }

    private func sendKeyboardShortcut(keyCode: CGKeyCode, withCommand: Bool) {
        let source = CGEventSource(stateID: .hidSystemState)

        // Get the currently focused application
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            print("⚠️ Could not get frontmost application")
            return
        }

        let pid = frontApp.processIdentifier

        // Create key down event with Command modifier
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true) {
            if withCommand {
                keyDown.flags = .maskCommand
            }
            keyDown.postToPid(pid)
        }

        // Small delay to ensure key down is registered
        usleep(10000) // 10ms

        // Create key up event
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
            if withCommand {
                keyUp.flags = .maskCommand
            }
            keyUp.postToPid(pid)
        }

        print("⌨️ Sent keyboard shortcut: keyCode=\(keyCode), command=\(withCommand)")
    }

    deinit {
        stopMonitoring()
    }
}
