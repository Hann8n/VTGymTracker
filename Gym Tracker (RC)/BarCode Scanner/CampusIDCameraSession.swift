import AVFoundation

/// All session, input, and torch mutations run on one serial queue.
final class CampusIDCameraSession: NSObject, AVCaptureMetadataOutputObjectsDelegate, @unchecked Sendable {
    let session = AVCaptureSession()
    var onCode: ((String) -> Void)?
    var onError: ((String) -> Void)?
    var onDeviceReady: ((AVCaptureDevice) -> Void)?

    private let queue = DispatchQueue(label: "net.jackhannon.gymtracker.campus-id-camera")
    private let output = AVCaptureMetadataOutput()
    private var input: AVCaptureDeviceInput?
    private var configured = false
    private var wantsRunning = false
    private var wantsTorch = false
    private var completed = false // Metadata callbacks use the main queue.

    func start() {
        queue.async {
            self.wantsRunning = true
            if self.input == nil { self.configureDevice(uniqueID: nil) }
            if self.configured && !self.session.isRunning { self.session.startRunning() }
        }
    }

    func stop() {
        queue.async {
            self.wantsRunning = false
            self.wantsTorch = false
            self.applyTorch()
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    func selectDevice(uniqueID: String) {
        queue.async { self.configureDevice(uniqueID: uniqueID) }
    }

    func setTorch(_ enabled: Bool) {
        queue.async {
            self.wantsTorch = enabled
            self.applyTorch()
        }
    }

    private func configureDevice(uniqueID: String?) {
        let device = uniqueID.flatMap { AVCaptureDevice(uniqueID: $0) }
            ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        guard let device else {
            reportError("This device has no camera available for scanning.")
            return
        }
        guard input?.device.uniqueID != device.uniqueID else { return }
        do {
            let replacement = try AVCaptureDeviceInput(device: device)
            session.beginConfiguration()
            configured = false
            var ready = false
            defer {
                session.commitConfiguration()
                if ready {
                    applyTorch()
                    if wantsRunning && !session.isRunning { session.startRunning() }
                    DispatchQueue.main.async { [weak self] in self?.onDeviceReady?(device) }
                }
            }
            if let input { session.removeInput(input) }
            guard session.canAddInput(replacement) else {
                if let input, session.canAddInput(input) { session.addInput(input) }
                reportError("The camera could not be started.")
                return
            }
            session.addInput(replacement)
            input = replacement
            if !session.outputs.contains(output) {
                guard session.canAddOutput(output) else {
                    reportError("Barcode scanning is unavailable on this camera.")
                    return
                }
                session.addOutput(output)
                output.setMetadataObjectsDelegate(self, queue: .main)
            }
            guard output.availableMetadataObjectTypes.contains(.codabar) else {
                reportError("Barcode scanning is unavailable on this camera.")
                return
            }
            output.metadataObjectTypes = [.codabar]
            configured = true
            ready = true
        } catch {
            reportError("The camera could not be started. Close this screen and try again.")
        }
    }

    private func applyTorch() {
        guard let device = input?.device, device.hasTorch, device.isTorchAvailable else { return }
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            device.torchMode = wantsTorch ? .on : .off
        } catch { /* Scanning can continue without the torch. */ }
    }

    private func reportError(_ message: String) {
        DispatchQueue.main.async { [weak self] in self?.onError?(message) }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !completed,
              let value = metadataObjects.compactMap({ $0 as? AVMetadataMachineReadableCodeObject })
                .first(where: { $0.type == .codabar })?.stringValue,
              !value.isEmpty else { return }
        completed = true
        stop()
        onCode?(value)
    }
}
