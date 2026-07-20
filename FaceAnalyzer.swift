//
//  FaceAnalyzer.swift
//  EdgeFaceAI
//
//  Created by Vishesh Vaibhav on 7/18/26.
//

import Foundation
import UIKit
import Vision
import CoreML
import ImageIO

struct PredictionResult {
    let ageGroup: String
    let ageRange: String
    let ageConfidence: Float

    let gender: String
    let genderConfidence: Float

    let expression: String
    let dominantEmotion: String
    let expressionConfidence: Float

    let inferenceTimeMs: Double
}

enum FaceAnalysisError: LocalizedError {
    case invalidImage
    case noFace
    case noPrediction
    case emotionLabelsMissing

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The selected image could not be processed."
        case .noFace:
            return "No face was detected."
        case .noPrediction:
            return "The models did not return a prediction."
        case .emotionLabelsMissing:
            return "Happy and sad labels were not found in the emotion model."
        }
    }
}

final class FaceAnalyzer {

    private let ageModel: VNCoreMLModel
    private let genderModel: VNCoreMLModel
    private let emotionModel: VNCoreMLModel

    init() {
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .cpuOnly

        ageModel = try! VNCoreMLModel(
            for: AgeNet(configuration: configuration).model
        )

        genderModel = try! VNCoreMLModel(
            for: GenderNet(configuration: configuration).model
        )

        emotionModel = try! VNCoreMLModel(
            for: Emotions(configuration: configuration).model
        )
    }

    func analyze(_ image: UIImage) throws -> PredictionResult {

        let fixedImage = image.normalized()

        guard let cgImage = fixedImage.cgImage else {
            throw FaceAnalysisError.invalidImage
        }

        let startTime = CFAbsoluteTimeGetCurrent()

        let faceImage = try cropLargestFace(from: cgImage)

        let ageResults = try classify(faceImage, using: ageModel)
        let genderResults = try classify(faceImage, using: genderModel)
        let emotionResults = try classify(faceImage, using: emotionModel)

        guard
            let ageResult = ageResults.first,
            let genderResult = genderResults.first,
            let dominantEmotion = emotionResults.first
        else {
            throw FaceAnalysisError.noPrediction
        }

        let ageRange = ageResult.identifier
        let ageGroup = ageRange.contains("60") ? "Elderly" : "Adult"

        let genderText = genderResult.identifier.lowercased()
        let gender = genderText.contains("female") ? "Female" : "Male"

        let happyScore = score(
            in: emotionResults,
            matching: ["happy", "happiness"]
        )

        let sadScore = score(
            in: emotionResults,
            matching: ["sad", "sadness"]
        )

        guard happyScore > 0 || sadScore > 0 else {
            throw FaceAnalysisError.emotionLabelsMissing
        }

        let expression = happyScore >= sadScore ? "Happy" : "Sad"
        let expressionConfidence = max(happyScore, sadScore)

        let inferenceTime =
            (CFAbsoluteTimeGetCurrent() - startTime) * 1000

        return PredictionResult(
            ageGroup: ageGroup,
            ageRange: ageRange,
            ageConfidence: ageResult.confidence,
            gender: gender,
            genderConfidence: genderResult.confidence,
            expression: expression,
            dominantEmotion: dominantEmotion.identifier.capitalized,
            expressionConfidence: expressionConfidence,
            inferenceTimeMs: inferenceTime
        )
    }

    private func cropLargestFace(from image: CGImage) throws -> CGImage {

        let request = VNDetectFaceRectanglesRequest()
        request.usesCPUOnly = true
        let handler = VNImageRequestHandler(
            cgImage: image,
            orientation: .up
        )

        try handler.perform([request])

        guard let face = request.results?.max(by: {
            ($0.boundingBox.width * $0.boundingBox.height) <
            ($1.boundingBox.width * $1.boundingBox.height)
        }) else {
            throw FaceAnalysisError.noFace
        }

        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let box = face.boundingBox

        let cropRect = CGRect(
            x: box.minX * width,
            y: (1 - box.maxY) * height,
            width: box.width * width,
            height: box.height * height
        ).integral

        let imageRect = CGRect(
            x: 0,
            y: 0,
            width: width,
            height: height
        )

        let safeRect = cropRect.intersection(imageRect)

        guard let croppedImage = image.cropping(to: safeRect) else {
            throw FaceAnalysisError.invalidImage
        }

        return croppedImage
    }

    private func classify(
        _ image: CGImage,
        using model: VNCoreMLModel
    ) throws -> [VNClassificationObservation] {

        let request = VNCoreMLRequest(model: model)
        request.usesCPUOnly = true
        request.imageCropAndScaleOption = .centerCrop

        let handler = VNImageRequestHandler(
            cgImage: image,
            orientation: .up
        )

        try handler.perform([request])

        guard
            let results = request.results as? [VNClassificationObservation],
            !results.isEmpty
        else {
            throw FaceAnalysisError.noPrediction
        }

        return results
    }

    private func score(
        in results: [VNClassificationObservation],
        matching names: [String]
    ) -> Float {

        for result in results {
            let label = result.identifier.lowercased()

            if names.contains(where: { label.contains($0) }) {
                return result.confidence
            }
        }

        return 0
    }
}

extension UIImage {

    func normalized() -> UIImage {

        if imageOrientation == .up {
            return self
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale

        return UIGraphicsImageRenderer(
            size: size,
            format: format
        ).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
