import Foundation

final class LatencyMetrics {
    private var readiness: [Double] = []
    private var keystrokes: [Double] = []

    func recordReadiness(ms: Double) {
        readiness.append(ms)
        Diag.log(String(format: "readiness (hotkey->editor focused): %.1f ms  |  %@", ms, summary(readiness)))
    }

    func recordKeystroke(ms: Double, first: Bool) {
        keystrokes.append(ms)
        if first || keystrokes.count % 5 == 0 {
            Diag.log(String(format: "keystroke input->paint: %.1f ms  |  %@", ms, summary(keystrokes)))
        }
    }

    func printMemory(context: String) {
        let megabytes = Double(physFootprint()) / 1_048_576.0
        Diag.log(String(format: "memory (phys_footprint): %.1f MB  (%@)", megabytes, context))
    }

    private func summary(_ values: [Double]) -> String {
        guard !values.isEmpty else { return "" }
        let sorted = values.sorted()
        return String(
            format: "n=%d p50=%.1f p95=%.1f ms",
            values.count, percentile(sorted, 0.50), percentile(sorted, 0.95)
        )
    }

    private func percentile(_ sorted: [Double], _ fraction: Double) -> Double {
        guard !sorted.isEmpty else { return 0 }
        let index = Int((Double(sorted.count - 1) * fraction).rounded())
        return sorted[index]
    }

    private func physFootprint() -> UInt64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size
        )
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? info.phys_footprint : 0
    }
}
