import SwiftUI
import PhotosUI
import Foundation

struct ContentView: View {

    @State private var imageID = ""
    @State private var savedCount = 0
    @State private var resultsFile: URL?

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    @State private var result: PredictionResult?
    @State private var errorMessage = ""
    @State private var isAnalyzing = false

    private let analyzer = FaceAnalyzer()

    var body: some View {

        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 380)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 16)
                            )
                    } else {
                        Image(systemName: "person.crop.square")
                            .font(.system(size: 80))
                            .foregroundStyle(.secondary)

                        Text("Choose a photograph to begin")
                            .foregroundStyle(.secondary)
                    }

                    TextField(
                        "Image ID, for example IMG01",
                        text: $imageID
                    )
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)

                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images
                    ) {
                        Label(
                            "Choose Photo",
                            systemImage: "photo"
                        )
                    }
                    .buttonStyle(.borderedProminent)

                    if selectedImage != nil {
                        Button("Analyze Image") {
                            analyzeImage()
                        }
                        .buttonStyle(.bordered)
                        .disabled(isAnalyzing)
                    }

                    if isAnalyzing {
                        ProgressView("Analyzing...")
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    if let result {
                        GroupBox("Prediction") {
                            VStack(spacing: 12) {

                                resultRow(
                                    title: "Age",
                                    value: result.ageGroup
                                )

                                resultRow(
                                    title: "Age range",
                                    value: result.ageRange
                                )

                                resultRow(
                                    title: "Age confidence",
                                    value: percentage(
                                        result.ageConfidence
                                    )
                                )

                                resultRow(
                                    title: "Gender",
                                    value: result.gender
                                )

                                resultRow(
                                    title: "Gender confidence",
                                    value: percentage(
                                        result.genderConfidence
                                    )
                                )

                                resultRow(
                                    title: "Expression",
                                    value: result.expression
                                )

                                resultRow(
                                    title: "Expression confidence",
                                    value: percentage(
                                        result.expressionConfidence
                                    )
                                )

                                resultRow(
                                    title: "Dominant emotion",
                                    value: result.dominantEmotion
                                )

                                resultRow(
                                    title: "Inference time",
                                    value: String(
                                        format: "%.2f ms",
                                        result.inferenceTimeMs
                                    )
                                )
                            }
                        }

                        Button("Save Result") {
                            saveResult()
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Text("Saved \(savedCount) of 20")
                        .foregroundStyle(.secondary)

                    if let resultsFile {
                        ShareLink(item: resultsFile) {
                            Label(
                                "Export CSV",
                                systemImage: "square.and.arrow.up"
                            )
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            .navigationTitle("Edge Face AI")
            .onChange(of: selectedItem) { _, newItem in
                loadImage(from: newItem)
            }
            .onAppear {
                loadExistingResults()
            }
        }
    }

    private func loadImage(
        from item: PhotosPickerItem?
    ) {

        Task {
            guard
                let data = try? await item?.loadTransferable(
                    type: Data.self
                ),
                let image = UIImage(data: data)
            else {
                return
            }

            selectedImage = image
            result = nil
            errorMessage = ""
        }
    }

    private func analyzeImage() {

        guard let selectedImage else {
            return
        }

        let id = formattedImageID()

        guard isValidImageID(id) else {
            errorMessage = "Enter an image ID from IMG01 to IMG20."
            return
        }

        result = nil
        errorMessage = ""
        isAnalyzing = true

        Task {
            await Task.yield()

            do {
                result = try analyzer.analyze(selectedImage)
            } catch {
                errorMessage = error.localizedDescription
            }

            isAnalyzing = false
        }
    }

    private func resultRow(
        title: String,
        value: String
    ) -> some View {

        HStack {
            Text(title)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
        }
    }

    private func percentage(
        _ value: Float
    ) -> String {

        String(
            format: "%.2f%%",
            value * 100
        )
    }

    private var resultsURL: URL {

        FileManager.default
            .urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]
            .appendingPathComponent(
                "iphone_results.csv"
            )
    }

    private func formattedImageID() -> String {

        imageID
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .uppercased()
    }

    private func isValidImageID(
        _ id: String
    ) -> Bool {

        guard id.hasPrefix("IMG") else {
            return false
        }

        let numberText = String(id.dropFirst(3))

        guard let number = Int(numberText) else {
            return false
        }

        return id.count == 5 &&
            number >= 1 &&
            number <= 20
    }

    private func saveResult() {

        guard let currentResult = result else {
            return
        }

        let id = formattedImageID()

        guard isValidImageID(id) else {
            errorMessage = "Enter an image ID from IMG01 to IMG20."
            return
        }

        let url = resultsURL

        if resultAlreadyExists(id, at: url) {
            errorMessage = "\(id) has already been saved."
            return
        }

        let header =
            "image_id,predicted_age_group,age_range," +
            "predicted_gender,predicted_expression," +
            "dominant_emotion,age_confidence," +
            "gender_confidence,expression_confidence," +
            "inference_ms\n"

        let row =
            "\(id)," +
            "\(currentResult.ageGroup)," +
            "\(currentResult.ageRange)," +
            "\(currentResult.gender)," +
            "\(currentResult.expression)," +
            "\(currentResult.dominantEmotion)," +
            "\(currentResult.ageConfidence)," +
            "\(currentResult.genderConfidence)," +
            "\(currentResult.expressionConfidence)," +
            "\(currentResult.inferenceTimeMs)\n"

        do {
            if !FileManager.default.fileExists(
                atPath: url.path
            ) {
                try header.write(
                    to: url,
                    atomically: true,
                    encoding: .utf8
                )
            }

            let fileHandle = try FileHandle(
                forWritingTo: url
            )

            fileHandle.seekToEndOfFile()

            if let data = row.data(
                using: .utf8
            ) {
                fileHandle.write(data)
            }

            fileHandle.closeFile()

            resultsFile = url
            savedCount = numberOfSavedResults()
            errorMessage = ""

            imageID = ""
            selectedItem = nil
            selectedImage = nil
            result = nil

        } catch {
            errorMessage = "The result could not be saved."
        }
    }

    private func resultAlreadyExists(
        _ id: String,
        at url: URL
    ) -> Bool {

        guard
            let text = try? String(
                contentsOf: url,
                encoding: .utf8
            )
        else {
            return false
        }

        let rows = text.split(separator: "\n")

        return rows.dropFirst().contains {
            $0.hasPrefix("\(id),")
        }
    }

    private func numberOfSavedResults() -> Int {

        guard
            let text = try? String(
                contentsOf: resultsURL,
                encoding: .utf8
            )
        else {
            return 0
        }

        let rows = text.split(separator: "\n")

        return max(rows.count - 1, 0)
    }

    private func loadExistingResults() {

        guard FileManager.default.fileExists(
            atPath: resultsURL.path
        ) else {
            return
        }

        resultsFile = resultsURL
        savedCount = numberOfSavedResults()
    }
}

#Preview {
    ContentView()
}
