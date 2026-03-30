import SwiftUI
import PhotosUI
import AVFoundation

// MARK: - Party Photos View

struct PartyPhotosView: View {
    let partyId: UUID
    let profile: Profile
    let photos: [PartyPhotoWithProfile]

    @State private var selectedItem: PhotosPickerItem?
    @State private var isUploading = false
    @State private var caption = ""
    @State private var showCaptionSheet = false
    @State private var pendingImageData: Data?
    @State private var selectedPhoto: PartyPhotoWithProfile?

    @State private var showSourcePicker = false
    @State private var showCamera = false
    @State private var showGalleryPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // ── Add Photo button ──────────────────────────────────────
                Button {
                    showSourcePicker = true
                } label: {
                    Label("Ajouter une photo", systemImage: "camera.badge.plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.appAccentPurple.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.appAccentPurple, lineWidth: 1)
                        )
                }
                .padding(.horizontal)

                if isUploading {
                    HStack(spacing: 10) {
                        ProgressView()
                            .tint(Color.appAccentPurple)
                        Text("Envoi en cours…")
                            .font(.subheadline)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    .padding(.vertical, 8)
                }

                // ── Photo grid ────────────────────────────────────────────
                if photos.isEmpty {
                    VStack(spacing: 12) {
                        Text("📷")
                            .font(.system(size: 48))
                        Text("Aucune photo pour l'instant")
                            .font(.subheadline)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 2),
                        GridItem(.flexible(), spacing: 2),
                        GridItem(.flexible(), spacing: 2)
                    ], spacing: 2) {
                        ForEach(photos) { photoWithProfile in
                            PhotoGridCell(photoWithProfile: photoWithProfile)
                                .onTapGesture { selectedPhoto = photoWithProfile }
                        }
                    }
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        // ── Source picker dialog ──────────────────────────────────────────
        .confirmationDialog("Ajouter une photo", isPresented: $showSourcePicker, titleVisibility: .visible) {
            Button("Galerie photos")  { showGalleryPicker = true }
            Button("Caméra")          { showCamera = true }
            Button("Annuler", role: .cancel) {}
        }
        // ── Gallery picker (programmatic trigger) ─────────────────────────
        .photosPicker(isPresented: $showGalleryPicker, selection: $selectedItem, matching: .images)
        // ── Camera sheet ──────────────────────────────────────────────────
        .fullScreenCover(isPresented: $showCamera) {
            PartyPhotoCameraView { capturedData in
                pendingImageData = capturedData
                showCaptionSheet = true
            }
        }
        // ── Gallery change ────────────────────────────────────────────────
        .onChange(of: selectedItem) { _, newItem in
            Task {
                guard let newItem,
                      let data = try? await newItem.loadTransferable(type: Data.self) else { return }
                pendingImageData = data
                showCaptionSheet = true
            }
        }
        // ── Caption sheet ─────────────────────────────────────────────────
        .sheet(isPresented: $showCaptionSheet) {
            CaptionSheet(caption: $caption) {
                Task { await uploadPhoto() }
            }
        }
        // ── Photo detail ──────────────────────────────────────────────────
        .sheet(item: $selectedPhoto) { photoWithProfile in
            PhotoDetailView(photoWithProfile: photoWithProfile)
        }
    }

    private func uploadPhoto() async {
        guard let data = pendingImageData else { return }
        isUploading = true
        defer { isUploading = false }
        do {
            let fileName = "\(UUID().uuidString).jpg"
            let path = "party-photos/\(partyId.uuidString)/\(fileName)"
            try await supabase.storage
                .from("party-photos")
                .upload(path, data: data)

            let url = try supabase.storage
                .from("party-photos")
                .getPublicURL(path: path)

            let photoInsert = PartyPhotoInsert(
                partyId: partyId,
                userId: profile.userId,
                imageUrl: url.absoluteString,
                caption: caption.isEmpty ? nil : caption
            )
            try await supabase
                .from("party_photos")
                .insert(photoInsert)
                .execute()

            caption = ""
            pendingImageData = nil
        } catch {}
    }
}

// MARK: - Party Photo Camera View

struct PartyPhotoCameraView: View {
    let onCapture: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var cameraPosition: AVCaptureDevice.Position = .back
    @State private var capturedImage: UIImage?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image = capturedImage {
                // ── Preview + confirm ──────────────────────────────────
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VStack {
                    Spacer()
                    HStack(spacing: 32) {
                        // Retake
                        Button {
                            capturedImage = nil
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 56, height: 56)
                                    .background(Color.black.opacity(0.55))
                                    .clipShape(Circle())
                                Text("Reprendre")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                        }

                        // Validate
                        Button {
                            if let data = image.jpegData(compressionQuality: 0.82) {
                                onCapture(data)
                                dismiss()
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 56, height: 56)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.appAccentPurple, Color.appAccentBlue],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(Circle())
                                Text("Utiliser")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .padding(.bottom, 60)
                }
            } else {
                // ── Live camera ────────────────────────────────────────
                PartyCameraPreviewView(position: cameraPosition) { image in
                    capturedImage = image
                }
                .ignoresSafeArea()

                // Controls overlay
                VStack {
                    // Top bar
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    Spacer()

                    // Bottom controls: flash | shutter | flip
                    HStack(alignment: .center) {
                        Spacer()

                        // Shutter
                        PartyCaptureButton()
                            .frame(width: 76, height: 76)

                        Spacer()

                        // Flip camera
                        Button {
                            cameraPosition = (cameraPosition == .back) ? .front : .back
                        } label: {
                            Image(systemName: "camera.rotate.fill")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(width: 52, height: 52)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 28)
                    }
                    .padding(.bottom, 48)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Capture button shape

private struct PartyCaptureButton: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.6), lineWidth: 4)
            Circle()
                .fill(.white)
                .padding(6)
        }
    }
}

// MARK: - Camera preview (UIViewControllerRepresentable)

struct PartyCameraPreviewView: UIViewControllerRepresentable {
    let position: AVCaptureDevice.Position
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> PartyCameraViewController {
        let vc = PartyCameraViewController()
        vc.position = position
        vc.onCapture = onCapture
        return vc
    }

    func updateUIViewController(_ vc: PartyCameraViewController, context: Context) {
        // Switch camera if position changed
        if vc.position != position {
            vc.position = position
            vc.switchCamera(to: position)
        }
    }
}

// MARK: - PartyCameraViewController

class PartyCameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    var position: AVCaptureDevice.Position = .back
    var onCapture: ((UIImage) -> Void)?

    private var captureSession: AVCaptureSession?
    private var photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var captureButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera(position: position)
        setupUI()
    }

    // MARK: Camera setup

    private func setupCamera(position: AVCaptureDevice.Position) {
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        captureSession = session

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        if session.canAddInput(input)  { session.addInput(input) }
        if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.insertSublayer(preview, at: 0)
        previewLayer = preview

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    // MARK: Switch camera

    func switchCamera(to newPosition: AVCaptureDevice.Position) {
        guard let session = captureSession else { return }
        session.beginConfiguration()

        // Remove existing inputs
        session.inputs.forEach { session.removeInput($0) }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        session.commitConfiguration()

        // Fix preview orientation after switch
        if let connection = previewLayer?.connection, connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
    }

    // MARK: UI

    private func setupUI() {
        captureButton = UIButton(type: .custom)
        captureButton.backgroundColor = .clear
        captureButton.layer.cornerRadius = 38
        captureButton.layer.borderWidth = 4
        captureButton.layer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        view.addSubview(captureButton)

        let innerCircle = UIView()
        innerCircle.backgroundColor = .white
        innerCircle.layer.cornerRadius = 28
        innerCircle.isUserInteractionEnabled = false
        innerCircle.translatesAutoresizingMaskIntoConstraints = false
        captureButton.addSubview(innerCircle)

        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -48),
            captureButton.widthAnchor.constraint(equalToConstant: 76),
            captureButton.heightAnchor.constraint(equalToConstant: 76),
            innerCircle.centerXAnchor.constraint(equalTo: captureButton.centerXAnchor),
            innerCircle.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            innerCircle.widthAnchor.constraint(equalToConstant: 56),
            innerCircle.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    // MARK: Capture

    @objc private func capturePhoto() {
        // Shutter animation
        UIView.animate(withDuration: 0.07, animations: {
            self.captureButton.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
        }) { _ in
            UIView.animate(withDuration: 0.15, delay: 0,
                           usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5) {
                self.captureButton.transform = .identity
            }
        }

        // White flash blink
        let flash = UIView(frame: view.bounds)
        flash.backgroundColor = .white
        flash.alpha = 0
        view.addSubview(flash)
        UIView.animate(withDuration: 0.1, animations: { flash.alpha = 0.9 }) { _ in
            UIView.animate(withDuration: 0.2) { flash.alpha = 0 } completion: { _ in flash.removeFromSuperview() }
        }

        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              var image = UIImage(data: data) else { return }

        // Mirror selfie if front camera
        if position == .front, let cgImage = image.cgImage {
            image = UIImage(cgImage: cgImage, scale: image.scale, orientation: .leftMirrored)
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
        DispatchQueue.main.async { [weak self] in
            self?.onCapture?(image)
        }
    }
}

// MARK: - Photo Grid Cell

struct PhotoGridCell: View {
    let photoWithProfile: PartyPhotoWithProfile

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: photoWithProfile.photo.imageUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(Color.appCard)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundStyle(Color.appTextSecondary)
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fill)
            .clipped()

            if let caption = photoWithProfile.photo.caption {
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(Color.black.opacity(0.5))
            }
        }
        .frame(height: 120)
        .clipped()
    }
}

// MARK: - Photo Detail View

struct PhotoDetailView: View {
    let photoWithProfile: PartyPhotoWithProfile
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                HStack {
                    AvatarView(
                        avatarUrl: photoWithProfile.profile.avatarUrl,
                        pseudo: photoWithProfile.profile.pseudo,
                        size: 36
                    )
                    Text(photoWithProfile.profile.pseudo)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding()

                Spacer()

                AsyncImage(url: URL(string: photoWithProfile.photo.imageUrl ?? "")) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    ProgressView().tint(.white)
                }

                Spacer()

                if let caption = photoWithProfile.photo.caption {
                    Text(caption)
                        .font(.body)
                        .foregroundStyle(.white)
                        .padding()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Caption Sheet

struct CaptionSheet: View {
    @Binding var caption: String
    let onUpload: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground()

                VStack(spacing: 20) {
                    Text("Ajouter une légende")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.top, 20)

                    TextField("Légende (optionnel)", text: $caption)
                        .padding()
                        .background(Color.appCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                        .padding(.horizontal)

                    HStack(spacing: 12) {
                        Button("Ignorer") {
                            caption = ""
                            onUpload()
                            dismiss()
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .secondaryButton()

                        Button("Envoyer") {
                            onUpload()
                            dismiss()
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .primaryButton()
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium])
    }
}

// MARK: - Insert model

private struct PartyPhotoInsert: Codable {
    let partyId: UUID
    let userId: UUID
    let imageUrl: String?
    let caption: String?

    enum CodingKeys: String, CodingKey {
        case partyId  = "party_id"
        case userId   = "user_id"
        case imageUrl = "image_url"
        case caption
    }
}
