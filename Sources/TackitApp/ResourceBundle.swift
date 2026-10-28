import Foundation

extension Bundle {
    static let resources: Bundle = {
        if let url = Bundle.main.resourceURL?.appendingPathComponent("Tackit_TackitApp.bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }
        return .module
    }()
}
