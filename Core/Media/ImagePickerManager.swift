import SwiftUI
import PhotosUI
import AVFoundation

@MainActor @Observable
class ImagePickerManager {
    var selectedImage: UIImage?
    var showPhotoPicker = false
    var showCameraSheet = false
    var showPermissionAlert = false
    var permissionAlertMessage = ""

    // Built by Christos Ferlachidis & Daniel Hedenberg

    func requestCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showCameraSheet = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    if granted {
                        self.showCameraSheet = true
                    } else {
                        self.showPermissionDenied(for: "camera")
                    }
                }
            }
        case .denied, .restricted:
            showPermissionDenied(for: "camera")
        @unknown default:
            break
        }
    }

    func requestPhotoLibrary() {
        showPhotoPicker = true
    }

    func compressImage(_ image: UIImage, maxSizeKB: Int = 500) -> Data? {
        var compression: CGFloat = 0.8
        var data = image.jpegData(compressionQuality: compression)

        while let d = data, d.count > maxSizeKB * 1024, compression > 0.1 {
            compression -= 0.1
            data = image.jpegData(compressionQuality: compression)
        }
        return data
    }

    private func showPermissionDenied(for feature: String) {
        let isSv = UserDefaults.standard.string(forKey: Config.languageKey) == "sv"
        if feature == "camera" {
            permissionAlertMessage = isSv
                ? "Bokvia behöver tillgång till kameran för att ta profilbilder. Gå till Inställningar för att aktivera."
                : "Bokvia needs camera access to take profile photos. Go to Settings to enable."
        }
        showPermissionAlert = true
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    // Built by Christos Ferlachidis & Daniel Hedenberg

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        init(_ parent: CameraView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
