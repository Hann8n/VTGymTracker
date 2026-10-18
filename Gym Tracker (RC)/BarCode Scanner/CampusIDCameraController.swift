import AVFoundation
import AVKit
import UIKit

final class CampusIDCameraController: UIViewController {
    private let camera = CampusIDCameraSession()
    private let preview = AVCaptureVideoPreviewLayer()
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    private var rotationObservation: NSKeyValueObservation?
    private var directionCoordinator: AnyObject?
    var onCode: ((String) -> Void)?
    var onError: ((String) -> Void)?
    var onTorchAvailability: ((Bool) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        preview.session = camera.session
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        camera.onCode = { [weak self] in self?.onCode?($0) }
        camera.onError = { [weak self] in self?.onError?($0) }
        camera.onDeviceReady = { [weak self] device in self?.configureRotation(device: device) }
        if #available(iOS 27.1, *) {
            directionCoordinator = AVCaptureDeviceDirectionCoordinator(
                view: view,
                deviceTypes: [.builtInWideAngleCamera, .builtInOuterUltraWideCamera, .builtInInnerUltraWideCamera]
            ) { [weak self] directions in
                // Prefer the rear lens when it faces away from this display; otherwise use
                // the system's backward-facing camera for the current display/pose.
                let choices = directions.backwardFacingDeviceDescriptors
                if let descriptor = choices.first(where: { $0.position == .back }) ?? choices.first {
                    self?.camera.selectDevice(uniqueID: descriptor.uniqueID)
                }
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview.frame = view.bounds
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        camera.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        camera.stop()
    }

    func stop() { camera.stop() }
    func setTorch(_ enabled: Bool) { camera.setTorch(enabled) }

    private func configureRotation(device: AVCaptureDevice) {
        rotationObservation?.invalidate()
        let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: preview)
        rotationCoordinator = coordinator
        onTorchAvailability?(device.hasTorch && device.isTorchAvailable)
        rotationObservation = coordinator.observe(\.videoRotationAngleForHorizonLevelPreview, options: [.initial, .new]) { [weak self] coordinator, _ in
            DispatchQueue.main.async {
                let angle = coordinator.videoRotationAngleForHorizonLevelPreview
                if let connection = self?.preview.connection, connection.isVideoRotationAngleSupported(angle) {
                    connection.videoRotationAngle = angle
                }
            }
        }
    }
}
