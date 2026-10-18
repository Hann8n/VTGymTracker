import SwiftUI

struct CampusIDCameraView: UIViewControllerRepresentable {
    let torchOn: Bool
    let onCode: (String) -> Void
    let onError: (String) -> Void
    let onTorchAvailability: (Bool) -> Void

    func makeUIViewController(context: Context) -> CampusIDCameraController { CampusIDCameraController() }

    func updateUIViewController(_ controller: CampusIDCameraController, context: Context) {
        controller.onCode = onCode
        controller.onError = onError
        controller.onTorchAvailability = onTorchAvailability
        controller.setTorch(torchOn)
    }

    static func dismantleUIViewController(_ controller: CampusIDCameraController, coordinator: ()) {
        controller.onCode = nil
        controller.onError = nil
        controller.onTorchAvailability = nil
        controller.stop()
    }
}
