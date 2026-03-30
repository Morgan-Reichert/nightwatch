import SwiftUI
import AVFoundation
import PhotosUI

// MARK: - Mistral API Models
struct MistralRequest: Codable {
    let model: String
    let messages: [MistralMessage]
    let maxTokens: Int

    enum CodingKeys: String, CodingKey {
        case model, messages
        case maxTokens = "max_tokens"
    }
}

struct MistralMessage: Codable {
    let role: String
    let content: [MistralContent]
}

struct MistralContent: Codable {
    let type: String
    let text: String?
    let imageUrl: MistralImageUrl?

    enum CodingKeys: String, CodingKey {
        case type, text
        case imageUrl = "image_url"
    }
}

struct MistralImageUrl: Codable {
    let url: String
}

struct MistralResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

// MARK: - Mistral Drink Detector
struct MistralDrinkDetector {
    static let apiKey = AppConfig.mistralApiKey
    static let endpoint = "https://api.mistral.ai/v1/chat/completions"

    static func analyze(base64Image: String) async throws -> DrinkAnalysisResult {
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let prompt = """
        Analyze this drink image and respond ONLY with JSON in exactly this format:
        {"name": "drink name", "volume_ml": 330, "abv": 0.05}

        Rules:
        - name: common drink name in French (e.g. "Bière", "Vin rouge", "Mojito", "Shot de vodka", "Eau")
        - volume_ml: estimated volume in milliliters as a number (integer)
        - abv: alcohol by volume as decimal 0 to 1 (e.g. 0.05 for 5%, 0.40 for 40%)
        - If not a drink, use {"name": "Inconnu", "volume_ml": 250, "abv": 0}
        - Respond with ONLY the JSON, no other text.
        """

        let mistralRequest = MistralRequest(
            model: "pixtral-12b-2409",
            messages: [
                MistralMessage(
                    role: "user",
                    content: [
                        MistralContent(type: "text", text: prompt, imageUrl: nil),
                        MistralContent(
                            type: "image_url",
                            text: nil,
                            imageUrl: MistralImageUrl(url: "data:image/jpeg;base64,\(base64Image)")
                        )
                    ]
                )
            ],
            maxTokens: 150
        )

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(mistralRequest)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        let mistralResponse = try decoder.decode(MistralResponse.self, from: data)

        guard let content = mistralResponse.choices.first?.message.content else {
            throw URLError(.cannotParseResponse)
        }

        // Extract JSON from the content (handle potential whitespace or markdown)
        let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonStart = cleanContent.firstIndex(of: "{") ?? cleanContent.startIndex
        let jsonEnd = cleanContent.lastIndex(of: "}").map { cleanContent.index(after: $0) } ?? cleanContent.endIndex
        let jsonString = String(cleanContent[jsonStart..<jsonEnd])

        guard let jsonData = jsonString.data(using: .utf8),
              let result = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        let name = result["name"] as? String ?? "Boisson inconnue"
        let volumeMl: Double
        if let v = result["volume_ml"] as? Double {
            volumeMl = v
        } else if let v = result["volume_ml"] as? Int {
            volumeMl = Double(v)
        } else {
            volumeMl = 250
        }
        let abv = result["abv"] as? Double ?? 0

        return DrinkAnalysisResult(name: name, volumeMl: volumeMl, abv: abv)
    }
}

// MARK: - Analysis Result
struct DrinkAnalysisResult {
    let name: String
    let volumeMl: Double
    let abv: Double
}

// MARK: - Camera Scanner View
struct CameraScannerView: View {
    let onDetected: (String, Double, Double) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var capturedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var analysisResult: DrinkAnalysisResult?
    @State private var errorMessage: String?
    @State private var showCamera = true
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showPhotoPicker = false

    // Editable fields after detection
    @State private var editedName = ""
    @State private var editedVolume = ""
    @State private var editedABV = ""

    // Scan line animation
    @State private var scanLineProgress: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if showCamera && capturedImage == nil {
                    cameraView
                } else if capturedImage != nil {
                    resultView
                }
            }
            .navigationTitle("Scanner une boisson")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                        .foregroundStyle(Color.appTextSecondary)
                }
                if showCamera && capturedImage == nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        PhotosPicker(selection: $photoPickerItem, matching: .images) {
                            Image(systemName: "photo.fill")
                                .foregroundStyle(Color.appAccentPurple)
                        }
                        .onChange(of: photoPickerItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    capturedImage = image
                                    showCamera = false
                                    await analyzeImage(image)
                                }
                            }
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Camera View
    @ViewBuilder
    private var cameraView: some View {
        ZStack {
            CameraPreviewView(onCapture: { image in
                capturedImage = image
                showCamera = false
                Task { await analyzeImage(image) }
            })
            .ignoresSafeArea()

            // Overlay with scan frame
            VStack {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.appAccentPurple)

                    Text("Pointez vers votre boisson")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("L'IA Mistral Pixtral analysera la boisson et estimera son contenu en alcool")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
        }
    }

    // MARK: Result View
    @ViewBuilder
    private var resultView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: 280)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal)
                        .overlay {
                            if isAnalyzing {
                                // Scan line animation overlay
                                GeometryReader { geo in
                                    ZStack(alignment: .top) {
                                        // Dark vignette during scan
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.black.opacity(0.35))

                                        // Moving scan line
                                        VStack(spacing: 0) {
                                            // Glow above the line
                                            LinearGradient(
                                                colors: [
                                                    Color.appAccentPurple.opacity(0),
                                                    Color.appAccentPurple.opacity(0.25)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                            .frame(height: 48)

                                            // The scan line itself
                                            LinearGradient(
                                                colors: [
                                                    Color.appAccentBlue.opacity(0.6),
                                                    Color.appAccentPurple,
                                                    Color.appAccentBlue.opacity(0.6)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                            .frame(height: 2.5)
                                            .shadow(color: Color.appAccentPurple, radius: 6, x: 0, y: 0)

                                            // Glow below the line
                                            LinearGradient(
                                                colors: [
                                                    Color.appAccentPurple.opacity(0.1),
                                                    Color.appAccentPurple.opacity(0)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                            .frame(height: 48)
                                        }
                                        .offset(y: scanLineProgress * geo.size.height - 50)
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                }

                                // Corner brackets
                                ZStack {
                                    // Top-left
                                    ScanCorner().padding(.leading, 16).padding(.top, 16)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                    // Top-right
                                    ScanCorner().rotationEffect(.degrees(90)).padding(.trailing, 16).padding(.top, 16)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                    // Bottom-left
                                    ScanCorner().rotationEffect(.degrees(-90)).padding(.leading, 16).padding(.bottom, 16)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                                    // Bottom-right
                                    ScanCorner().rotationEffect(.degrees(180)).padding(.trailing, 16).padding(.bottom, 16)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .overlay(alignment: .topTrailing) {
                            if !isAnalyzing {
                                Button {
                                    resetState()
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(8)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .padding(.top, 8)
                                .padding(.trailing, 24)
                            }
                        }
                        .onChange(of: isAnalyzing) { _, analyzing in
                            if analyzing {
                                scanLineProgress = 0
                                withAnimation(
                                    .linear(duration: 1.6).repeatForever(autoreverses: false)
                                ) {
                                    scanLineProgress = 1
                                }
                            } else {
                                scanLineProgress = 0
                            }
                        }
                }

                if isAnalyzing {
                    analysingView
                } else if let result = analysisResult {
                    detectedDrinkView(result: result)
                } else if let error = errorMessage {
                    errorView(message: error)
                }

                Spacer(minLength: 60)
            }
            .padding(.top, 16)
        }
    }

    @ViewBuilder
    private var analysingView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.appAccentPurple.opacity(0.2), lineWidth: 3)
                    .frame(width: 70, height: 70)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(colors: [Color.appAccentPurple, Color.appAccentBlue], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnalyzing)

                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(Color.appAccentPurple)
            }

            VStack(spacing: 6) {
                Text("Analyse en cours...")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Mistral Pixtral détecte votre boisson")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCard.opacity(0.8))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
        .padding(.horizontal)
    }

    @ViewBuilder
    private func detectedDrinkView(result: DrinkAnalysisResult) -> some View {
        VStack(spacing: 16) {
            // Detected header
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.appSuccess)
                Text("Boisson détectée")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal)

            // Editable fields
            VStack(spacing: 12) {
                ScannerTextField(
                    icon: "drop.fill",
                    label: "Nom",
                    placeholder: result.name,
                    text: $editedName
                )

                HStack(spacing: 10) {
                    ScannerTextField(
                        icon: "cylinder.fill",
                        label: "Volume (ml)",
                        placeholder: "\(Int(result.volumeMl))",
                        text: $editedVolume
                    )
                    .keyboardType(.numberPad)

                    ScannerTextField(
                        icon: "percent",
                        label: "ABV (%)",
                        placeholder: "\(Int(result.abv * 100))",
                        text: $editedABV
                    )
                    .keyboardType(.decimalPad)
                }
            }
            .padding(.horizontal)

            // Alcohol info
            let finalVolume = Double(editedVolume) ?? result.volumeMl
            let finalABVInput = Double(editedABV.replacingOccurrences(of: ",", with: ".")) ?? (result.abv * 100)
            let finalABV = finalABVInput > 1 ? finalABVInput / 100.0 : finalABVInput
            let alcoholGrams = finalVolume * finalABV * 0.8

            if alcoholGrams > 0 {
                HStack(spacing: 20) {
                    AlcoholInfoBadge(icon: "cylinder.fill", value: "\(Int(finalVolume))ml", label: "Volume", color: Color.appAccentBlue)
                    AlcoholInfoBadge(icon: "percent", value: String(format: "%.1f%%", finalABV * 100), label: "ABV", color: Color.appAccentPurple)
                    AlcoholInfoBadge(icon: "exclamationmark.triangle.fill", value: String(format: "%.1fg", alcoholGrams), label: "Alcool", color: Color.appWarning)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.appCard.opacity(0.7))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
                )
                .padding(.horizontal)
            }

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    resetState()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reprendre")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.appTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appCard)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1), lineWidth: 1))
                }

                Button {
                    let finalName = editedName.isEmpty ? result.name : editedName
                    let vol = Double(editedVolume) ?? result.volumeMl
                    let abvInput = Double(editedABV.replacingOccurrences(of: ",", with: ".")) ?? (result.abv * 100)
                    let abv = abvInput > 1 ? abvInput / 100.0 : abvInput
                    onDetected(finalName, vol, abv)
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Ajouter")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [Color.appAccentPurple, Color.appAccentBlue], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            editedName = result.name
            editedVolume = "\(Int(result.volumeMl))"
            editedABV = "\(Int(result.abv * 100))"
        }
    }

    @ViewBuilder
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "xmark.octagon.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.appDanger)

            VStack(spacing: 6) {
                Text("Détection échouée")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                resetState()
            } label: {
                Text("Réessayer")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [Color.appAccentPurple, Color.appAccentBlue], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCard.opacity(0.8))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
        .padding(.horizontal)
    }

    // MARK: - Helpers
    private func resetState() {
        capturedImage = nil
        analysisResult = nil
        errorMessage = nil
        editedName = ""
        editedVolume = ""
        editedABV = ""
        showCamera = true
    }

    private func analyzeImage(_ image: UIImage) async {
        await MainActor.run { isAnalyzing = true; errorMessage = nil }

        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            await MainActor.run {
                errorMessage = "Impossible de traiter l'image"
                isAnalyzing = false
            }
            return
        }

        let base64 = imageData.base64EncodedString()

        do {
            let result = try await MistralDrinkDetector.analyze(base64Image: base64)
            await MainActor.run {
                analysisResult = result
                editedName = result.name
                editedVolume = "\(Int(result.volumeMl))"
                editedABV = "\(Int(result.abv * 100))"
                isAnalyzing = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Détection IA échouée: \(error.localizedDescription)"
                isAnalyzing = false
            }
        }
    }
}

// MARK: - Scanner Text Field
struct ScannerTextField: View {
    let icon: String
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.appAccentPurple)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.appTextSecondary)
            }

            TextField(placeholder, text: $text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
    }
}

// MARK: - Alcohol Info Badge
struct AlcoholInfoBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Scan Corner Bracket
private struct ScanCorner: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Horizontal arm
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.appAccentPurple)
                .frame(width: 22, height: 3)
            // Vertical arm
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.appAccentPurple)
                .frame(width: 3, height: 22)
        }
        .shadow(color: Color.appAccentPurple.opacity(0.8), radius: 4, x: 0, y: 0)
    }
}

// MARK: - Camera Preview
struct CameraPreviewView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> CameraViewController {
        let vc = CameraViewController()
        vc.onCapture = onCapture
        return vc
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    var onCapture: ((UIImage) -> Void)?
    private var captureSession: AVCaptureSession?
    private var captureDevice: AVCaptureDevice?
    private var photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var captureButton: UIButton!
    private var flashButton: UIButton!
    private var isFlashOn = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupUI()
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        captureSession = session

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        captureDevice = device

        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        previewLayer = preview

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    private func setupUI() {
        // Capture button
        captureButton = UIButton(type: .custom)
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 36
        captureButton.layer.borderWidth = 5
        captureButton.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        view.addSubview(captureButton)

        // Inner circle on button
        let innerCircle = UIView()
        innerCircle.backgroundColor = UIColor(red: 0.49, green: 0.23, blue: 0.93, alpha: 1)
        innerCircle.layer.cornerRadius = 26
        innerCircle.isUserInteractionEnabled = false
        innerCircle.translatesAutoresizingMaskIntoConstraints = false
        captureButton.addSubview(innerCircle)

        // Flash button
        flashButton = UIButton(type: .system)
        flashButton.tintColor = .white
        let flashImage = UIImage(systemName: "bolt.slash.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium))
        flashButton.setImage(flashImage, for: .normal)
        flashButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        flashButton.layer.cornerRadius = 22
        flashButton.translatesAutoresizingMaskIntoConstraints = false
        flashButton.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
        view.addSubview(flashButton)

        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            captureButton.widthAnchor.constraint(equalToConstant: 72),
            captureButton.heightAnchor.constraint(equalToConstant: 72),
            innerCircle.centerXAnchor.constraint(equalTo: captureButton.centerXAnchor),
            innerCircle.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            innerCircle.widthAnchor.constraint(equalToConstant: 52),
            innerCircle.heightAnchor.constraint(equalToConstant: 52),
            flashButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            flashButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            flashButton.widthAnchor.constraint(equalToConstant: 44),
            flashButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func toggleFlash() {
        guard let device = captureDevice, device.hasTorch else { return }
        isFlashOn.toggle()
        do {
            try device.lockForConfiguration()
            device.torchMode = isFlashOn ? .on : .off
            device.unlockForConfiguration()
        } catch {}
        let iconName = isFlashOn ? "bolt.fill" : "bolt.slash.fill"
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        flashButton.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)
        flashButton.tintColor = isFlashOn ? .systemYellow : .white
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    @objc private func capturePhoto() {
        UIView.animate(withDuration: 0.08, animations: {
            self.captureButton.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
        }) { _ in
            UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5) {
                self.captureButton.transform = .identity
            }
        }
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        // Turn off torch before stopping session
        if let device = captureDevice, device.hasTorch, isFlashOn {
            try? device.lockForConfiguration()
            device.torchMode = .off
            device.unlockForConfiguration()
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
        DispatchQueue.main.async { [weak self] in
            self?.onCapture?(image)
        }
    }
}
