import Foundation

final class EditorSurfacePool {
    private var warm: [WebEditorSurface] = []
    private let size: Int
    private let editorDirectory: URL?
    private let indexURL: URL?
    private let navigationDelegate: EditorNavigationDelegate

    var warmCount: Int { warm.count }

    init(size: Int) {
        self.size = size
        let directory = Bundle.module.resourceURL?.appendingPathComponent("editor")
        self.editorDirectory = directory
        self.indexURL = Bundle.module.url(forResource: "index", withExtension: "html", subdirectory: "editor")
        self.navigationDelegate = EditorNavigationDelegate(baseDirectory: directory ?? Bundle.module.bundleURL)
    }

    func warmUp() {
        scheduleWarm()
    }

    private func scheduleWarm() {
        guard warm.count < size else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, self.warm.count < self.size else { return }
            let start = CFAbsoluteTimeGetCurrent()
            let surface = self.makeSurface()
            self.warm.append(surface)
            let ms = (CFAbsoluteTimeGetCurrent() - start) * 1000
            Diag.log(String(format: "pool warmed %d/%d (create %.0f ms)", self.warm.count, self.size, ms))
            self.scheduleWarm()
        }
    }

    private func makeSurface() -> WebEditorSurface {
        let surface = WebEditorSurface(
            indexURL: indexURL,
            readAccessURL: editorDirectory,
            navigationDelegate: navigationDelegate
        )
        surface.onReady = { Diag.log("surface ready (bridge round-trip ok)") }
        return surface
    }

    func acquire() -> WebEditorSurface {
        let surface: WebEditorSurface
        if warm.isEmpty {
            Diag.log("pool empty on acquire; creating on demand")
            surface = makeSurface()
        } else {
            surface = warm.removeFirst()
        }
        scheduleWarm()
        return surface
    }

    func release(_ surface: WebEditorSurface) {
        surface.onDocChanged = nil
        surface.onReady = nil
        surface.onMetric = nil
        surface.reset()
        if warm.count < size {
            warm.append(surface)
        }
    }
}
