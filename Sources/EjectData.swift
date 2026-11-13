import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let defaults = UserDefaults.standard

    private var volume: String {
        get { defaults.string(forKey: "volume") ?? "/Volumes/Data" }
        set { defaults.set(newValue, forKey: "volume") }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "eject.fill", accessibilityDescription: "Eject Data")
            button.toolTip = "退出占用外接盘的应用并安全弹出"
        }

        let menu = NSMenu()
        let eject = NSMenuItem(title: "退出应用并弹出", action: #selector(ejectNow), keyEquivalent: "e")
        let dry = NSMenuItem(title: "仅预览占用 (dry-run)", action: #selector(dryRun), keyEquivalent: "d")
        let choose = NSMenuItem(title: "选择要弹出的卷…", action: #selector(chooseVolume), keyEquivalent: "o")
        let quit = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        for item in [eject, dry, choose, quit] { item.target = self }
        menu.addItem(eject)
        menu.addItem(dry)
        menu.addItem(choose)
        menu.addItem(.separator())
        menu.addItem(quit)
        statusItem.menu = menu
    }

    @objc private func ejectNow() { run([volume]) }
    @objc private func dryRun() { run(["--dry-run", volume]) }

    @objc private func chooseVolume() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/Volumes")
        panel.message = "选择要弹出的外接卷"
        panel.prompt = "选择"
        if panel.runModal() == .OK, let url = panel.url {
            volume = url.path
        }
    }

    @objc private func quitApp() { NSApp.terminate(nil) }

    private func scriptPath() -> String {
        if let path = Bundle.main.path(forResource: "eject-data", ofType: "sh") {
            return path
        }
        return "\(NSHomeDirectory())/bin/eject-data.sh"
    }

    private func run(_ args: [String]) {
        DispatchQueue.global().async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = [self.scriptPath()] + args
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            var output = ""
            do {
                try process.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                output = String(data: data, encoding: .utf8) ?? "(no output)"
            } catch {
                output = "Failed to run: \(error)"
            }
            DispatchQueue.main.async { self.show(output) }
        }
    }

    private func show(_ text: String) {
        let alert = NSAlert()
        alert.messageText = "Eject Data"
        alert.informativeText = text.isEmpty ? "(done)" : text
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
