//
//  QRScannerView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI
import AVFoundation

public struct QRScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    var onScanned: (String) -> Void
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                #if targetEnvironment(simulator)
                VStack(spacing: 16) {
                    Image(systemName: "camera.badge.ellipsis")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                    Text("Camera Not Available in Simulator")
                        .foregroundColor(.white)
                        .font(.headline)
                    Text("Use 'Add by URL' to manually input repository links.")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                #else
                CameraPreview(onFound: { code in
                    HapticManager.shared.notification(.success)
                    onScanned(code)
                    dismiss()
                })
                .ignoresSafeArea()
                #endif
                
                // Viewfinder Reticle Overlay
                VStack {
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(appState.currentAccentColor, lineWidth: 3)
                            .frame(width: 250, height: 250)
                            .background(Color.black.opacity(0.2))
                    }
                    Text("Point your camera at a repository QR code")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.top, 24)
                    Spacer()
                }
            }
            .navigationTitle("Scan QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

#if !targetEnvironment(simulator)
struct CameraPreview: UIViewControllerRepresentable {
    var onFound: (String) -> Void
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.onCodeFound = onFound
        return vc
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var onCodeFound: ((String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let session = AVCaptureSession()
        self.captureSession = session
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              session.canAddInput(videoInput) else { return }
        
        session.addInput(videoInput)
        
        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        }
        
        let layer = AVCaptureVideoPreviewLayer(session: session)
        self.previewLayer = layer
        layer.frame = view.layer.bounds
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {
            captureSession?.stopRunning()
            onCodeFound?(stringValue)
        }
    }
}
#endif
