import SwiftUI
import AVFoundation
import Vision

struct BarcodeScannerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var scannedBarcode: String
    @Binding var showAlert: Bool

    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var parent: BarcodeScannerView
        var captureSession: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?
        var isScanned = false
        weak var scannerViewController: ScannerViewController? // Use a weak reference

        // Vision request
        lazy var barcodeRequest: VNDetectBarcodesRequest = {
            let request = VNDetectBarcodesRequest(completionHandler: self.handleDetectedBarcodes)
            request.symbologies = [.codabar] // Restrict to Codabar
            return request
        }()

        init(parent: BarcodeScannerView) {
            self.parent = parent
            super.init()
            startSession()
        }

        deinit {
            stopSession()
        }

        func startSession() {
            guard captureSession == nil else {
                print("Capture session already running")
                return
            }

            captureSession = AVCaptureSession()
            guard let captureSession = captureSession else { return }

            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
                print("No video device found")
                return
            }

            do {
                let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
                if captureSession.canAddInput(videoInput) {
                    captureSession.addInput(videoInput)
                } else {
                    print("Could not add video input")
                    return
                }
            } catch {
                print("Error setting up video input: \(error)")
                return
            }

            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            } else {
                print("Could not add video output")
                return
            }

            captureSession.startRunning()
            print("Capture session started")
        }

        func stopSession() {
            guard let captureSession = captureSession else {
                print("Capture session is not running")
                return
            }
            captureSession.stopRunning()
            self.captureSession = nil
            print("Capture session stopped")
        }

        // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard !isScanned else { return }

            let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .right, options: [:])
            do {
                try handler.perform([barcodeRequest])
            } catch {
                print("Failed to perform barcode request: \(error)")
            }
        }

        // MARK: - VNRequestCompletion
        func handleDetectedBarcodes(request: VNRequest, error: Error?) {
            if let error = error {
                print("Barcode detection error: \(error)")
                return
            }

            guard let results = request.results as? [VNBarcodeObservation] else { return }

            for barcode in results {
                if let payload = barcode.payloadStringValue {
                    DispatchQueue.main.async {
                        self.isScanned = true
                        var code = payload.uppercased()
                        let validStartStopChars: Set<Character> = ["A", "B", "C", "D"]

                        // Ensure valid start and stop characters for Codabar
                        if code.first == nil || !validStartStopChars.contains(code.first!) {
                            code = "A" + code
                        }
                        if code.last == nil || !validStartStopChars.contains(code.last!) {
                            code = code + "B"
                        }

                        self.parent.scannedBarcode = code
                        UserDefaults.standard.set(code, forKey: "gymBarcode")
                        self.parent.showAlert = true
                        self.parent.isPresented = false

                        // Notify the ScannerViewController to update the border color
                        self.scannerViewController?.updateScannerFrame(isScanned: true)

                        self.stopSession()
                    }
                    break
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> ScannerViewController {
        let scannerViewController = ScannerViewController()
        scannerViewController.coordinator = context.coordinator
        context.coordinator.scannerViewController = scannerViewController // Assign reference
        return scannerViewController
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        // No update needed
    }
}

class ScannerViewController: UIViewController {
    var coordinator: BarcodeScannerView.Coordinator?
    private var scanBorderLayer: CAShapeLayer?
    private var flashlightButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black // Ensure the background is not transparent

        // Setup camera preview
        if let coordinator = coordinator, let captureSession = coordinator.captureSession {
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            coordinator.previewLayer = previewLayer

            setupScannerOverlay()
        }

        setupFlashlightButton() // Add flashlight button
    }

    private func setupScannerOverlay() {
        // Overlay container
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.clear

        // Calculate scanner frame (15% larger than default)
        let baseWidth: CGFloat = 300
        let baseHeight: CGFloat = 200
        let frameWidth = baseWidth * 1.15
        let frameHeight = baseHeight * 1.15
        let frameX = view.bounds.midX - frameWidth / 2
        let frameY = view.bounds.midY - frameHeight / 1 - 50 // Positioned higher
        let scanRect = CGRect(x: frameX, y: frameY, width: frameWidth, height: frameHeight)

        // Transparent mask
        let path = UIBezierPath(rect: overlay.bounds)
        let innerPath = UIBezierPath(roundedRect: scanRect, cornerRadius: 15)
        path.append(innerPath)
        path.usesEvenOddFillRule = true

        let fillLayer = CAShapeLayer()
        fillLayer.path = path.cgPath
        fillLayer.fillRule = .evenOdd
        fillLayer.fillColor = UIColor.black.withAlphaComponent(0.5).cgColor
        overlay.layer.addSublayer(fillLayer)

        // Scanner border layer
        let borderLayer = CAShapeLayer()
        borderLayer.path = UIBezierPath(roundedRect: scanRect, cornerRadius: 15).cgPath
        borderLayer.strokeColor = UIColor.white.cgColor
        borderLayer.lineWidth = 2.0
        borderLayer.fillColor = UIColor.clear.cgColor
        overlay.layer.addSublayer(borderLayer)
        scanBorderLayer = borderLayer

        // Add title text below the scanner frame
        let titleLabel = UILabel()
        titleLabel.text = "Scan Hokie Passport"
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(titleLabel)

        // Add informational text below the title
        let infoLabel = UILabel()
        infoLabel.text = "All data is stored locally on this device."
        infoLabel.textColor = UIColor.white
        infoLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        infoLabel.textAlignment = .center
        infoLabel.numberOfLines = 0
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(infoLabel)

        // Constraints for the title label
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: overlay.topAnchor, constant: frameY + frameHeight + 10),
            titleLabel.centerXAnchor.constraint(equalTo: overlay.centerXAnchor)
        ])

        // Constraints for the informational label
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            infoLabel.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -20)
        ])

        view.addSubview(overlay)
    }

    private func setupFlashlightButton() {
        flashlightButton = UIButton(type: .system)

        // Set flashlight icon (use SF Symbols)
        let flashlightImage = UIImage(systemName: "flashlight.off.fill")
        flashlightButton.setImage(flashlightImage, for: .normal)
        flashlightButton.tintColor = .white

        // Button styling
        flashlightButton.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        flashlightButton.layer.cornerRadius = 30 // Circle button
        flashlightButton.translatesAutoresizingMaskIntoConstraints = false

        // Add toggle action
        flashlightButton.addTarget(self, action: #selector(toggleFlashlight), for: .touchUpInside)

        view.addSubview(flashlightButton)

        // Constraints for positioning the button at the bottom
        NSLayoutConstraint.activate([
            flashlightButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            flashlightButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            flashlightButton.widthAnchor.constraint(equalToConstant: 60), // Circle size
            flashlightButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    @objc private func toggleFlashlight() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            print("Torch is not available on this device.")
            return
        }

        do {
            try device.lockForConfiguration()
            let isFlashlightOn = (device.torchMode == .on)
            device.torchMode = isFlashlightOn ? .off : .on
            device.unlockForConfiguration()

            // Update button icon
            let iconName = isFlashlightOn ? "flashlight.off.fill" : "flashlight.on.fill"
            let newIcon = UIImage(systemName: iconName)
            flashlightButton.setImage(newIcon, for: .normal)
        } catch {
            print("Failed to toggle flashlight: \(error)")
        }
    }

    func updateScannerFrame(isScanned: Bool) {
        // Change border color based on scanning status
        DispatchQueue.main.async {
            self.scanBorderLayer?.strokeColor = isScanned ? UIColor.green.cgColor : UIColor.white.cgColor
        }
    }
}
