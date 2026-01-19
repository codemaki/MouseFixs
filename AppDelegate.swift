import Cocoa
import ApplicationServices
import Carbon
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?
    private let mouseEventManager = MouseEventManager.shared
    private var permissionCheckTimer: Timer?
    private var hasAccessibilityPermission = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check for accessibility permissions
        hasAccessibilityPermission = checkAccessibilityPermissions()
        if !hasAccessibilityPermission {
            showAccessibilityAlert()
        }

        setupMenuBar()
        startMouseMonitoring()

        // Start monitoring permission status
        startPermissionMonitoring()

        print("MouseFix app started")
    }

    private func startPermissionMonitoring() {
        // Check permission status every 5 seconds
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            let currentPermission = AXIsProcessTrusted()

            // If permission was just granted
            if !self.hasAccessibilityPermission && currentPermission {
                self.hasAccessibilityPermission = true
                self.showPermissionGrantedNotification()
            }
            // If permission was revoked
            else if self.hasAccessibilityPermission && !currentPermission {
                self.hasAccessibilityPermission = false
                print("⚠️ Accessibility permission was revoked")
            }
        }
    }

    private func showPermissionGrantedNotification() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "접근성 권한이 부여되었습니다"
            alert.informativeText = "Baker가 정상적으로 작동하려면 앱을 재시작해야 합니다."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "지금 재시작")
            alert.addButton(withTitle: "나중에")

            if alert.runModal() == .alertFirstButtonReturn {
                // Restart the app
                let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
                let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
                let task = Process()
                task.launchPath = "/usr/bin/open"
                task.arguments = [path]
                task.launch()
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private func checkAccessibilityPermissions() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "접근성 권한 필요"
        alert.informativeText = "이 앱이 마우스 이벤트를 감지하려면 접근성 권한이 필요합니다.\n\n시스템 설정 > 개인정보 보호 및 보안 > 접근성에서 이 앱을 허용해주세요."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "시스템 설정 열기")
        alert.addButton(withTitle: "나중에")

        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "🥊"
            button.toolTip = "MouseFix"
        }

        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "마우스 사이드 버튼 활성화됨", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "  버튼 4 : 앞으로가기", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "  버튼 5 : 뒤로가기", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        // Auto-launch toggle
        let autoLaunchItem = NSMenuItem(title: "로그인 시 자동 실행", action: #selector(toggleAutoLaunch), keyEquivalent: "")
        autoLaunchItem.state = isAutoLaunchEnabled() ? .on : .off
        menu.addItem(autoLaunchItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "종료", action: #selector(quit), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    private func startMouseMonitoring() {
        if hasAccessibilityPermission {
            let success = mouseEventManager.startMonitoring()
            if success {
                print("✅ Mouse monitoring started successfully")
            } else {
                print("❌ Failed to start mouse monitoring")
            }
        } else {
            print("⚠️ Cannot start mouse monitoring without accessibility permission")
        }
    }

    // MARK: - Auto Launch Management

    private func isAutoLaunchEnabled() -> Bool {
        // Check if app is in login items using AppleScript
        let script = """
        tell application "System Events"
            get the name of every login item
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let output = scriptObject.executeAndReturnError(&error)
            if error == nil {
                let items = output.stringValue ?? ""
                return items.contains("MouseFix")
            }
        }
        return false
    }

    @objc private func toggleAutoLaunch(_ sender: NSMenuItem) {
        if sender.state == .on {
            // Disable auto-launch
            if disableAutoLaunch() {
                sender.state = .off
                print("Auto-launch disabled")
            } else {
                showError("자동 실행을 해제하는데 실패했습니다.")
            }
        } else {
            // Enable auto-launch
            if enableAutoLaunch() {
                sender.state = .on
                print("Auto-launch enabled")
            } else {
                showError("자동 실행을 설정하는데 실패했습니다.")
            }
        }
    }

    private func enableAutoLaunch() -> Bool {
        let appPath = Bundle.main.bundlePath
        let script = """
        tell application "System Events"
            make login item at end with properties {path:"\(appPath)", hidden:false}
        end tell
        """

        return executeAppleScript(script)
    }

    private func disableAutoLaunch() -> Bool {
        let script = """
        tell application "System Events"
            delete login item "MouseFix"
        end tell
        """

        return executeAppleScript(script)
    }

    private func executeAppleScript(_ script: String) -> Bool {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript error: \(error)")
                return false
            }
            return true
        }
        return false
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "오류"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "확인")
        alert.runModal()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = nil
    }
}
