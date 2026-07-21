# EdgeFaceAI

## On-Device Age, Gender and Expression Recognition

EdgeFaceAI is an academic Edge AI project developed for **DLBAIPEAI - Project: Edge AI** at IU International University of Applied Sciences.

The project compares two facial-analysis implementations:

1. A **Google Colab baseline** using DeepFace.
2. A native **iOS application** using SwiftUI, Vision and Core ML on a physical iPhone.

Both implementations were evaluated using the same set of 20 facial images. The experiment measured classification performance and inference time for:

- Age group: Adult or Elderly
- Gender model label: Male or Female
- Facial expression: Happy or Sad

> This is an educational prototype. Its outputs are model predictions and must not be treated as factual determinations about a person.

## Academic Information

- **Course:** DLBAIPEAI - Project: Edge AI
- **Selected task:** Task 2 - Age, gender and expression recognition application
- **Student:** Vishesh Vaibhav
- **Matriculation number:** 92129377
- **Institution:** IU International University of Applied Sciences

## Research Question

> How effectively can pretrained facial-analysis models classify age group, binary gender label and facial expression when deployed on an iPhone, compared with a Google Colab implementation?

## Project Overview

### Google Colab baseline

The computer-based baseline uses:

- Python 3.12.13
- DeepFace 0.0.100
- TensorFlow 2.20.0
- scikit-learn 1.6.1
- OpenCV face detection
- CPU runtime with no GPU detected

DeepFace returns numerical age, gender and emotion scores. The results are mapped to the binary categories required for the experiment:

- Age below 60: Adult
- Age 60 or above: Elderly
- Man or Male: Male
- Woman or Female: Female
- Higher Happy score than Sad score: Happy
- Higher Sad score than Happy score: Sad

### iOS Edge AI application

The mobile implementation uses:

- SwiftUI
- Apple Vision
- Core ML
- Xcode 26.6
- Physical iPhone 17
- iOS 27 Beta 3 during testing
- CPU-only model execution

The application allows the user to:

1. Enter an image ID from `IMG01` to `IMG20`.
2. Select an image from the photo library.
3. Detect and crop the largest face.
4. Run the age, gender and emotion models locally.
5. View predictions, confidence values and inference time.
6. Save the result to a CSV file.
7. Export the saved results from the device.

The Core ML models included in the project are:

- `AgeNet.mlmodel`
- `GenderNet.mlmodel`
- `Emotions.mlmodel`, used as the CNN-based emotion model

The model files are tracked using Git LFS.

## Evaluation Dataset

The evaluation contains 20 images:

- 10 Adult and 10 Elderly labels
- 10 Male and 10 Female labels overall
- 10 Happy and 10 Sad expressions overall
- 18 images selected from the FACES database
- 2 supplementary synthetic portraits

The set was balanced overall for each target variable. It did not achieve a strict 5/5 gender split inside both age groups:

- Adult subset: 6 Male and 4 Female
- Elderly subset: 4 Male and 6 Female

This deviation is reported as a limitation of the experimental design.

The evaluation images are not included in this public repository because of privacy, copyright and dataset-distribution considerations. The exported predictions, metrics and figures are included.

## Results

### Classification performance

| Task | Platform | Accuracy | Macro Precision | Macro Recall | Macro F1 |
|---|---|---:|---:|---:|---:|
| Age | Google Colab | 50.00% | 25.00% | 50.00% | 33.33% |
| Age | iPhone | 50.00% | 25.00% | 50.00% | 33.33% |
| Gender | Google Colab | 75.00% | 83.33% | 75.00% | 73.33% |
| Gender | iPhone | 60.00% | 65.63% | 60.00% | 56.04% |
| Expression | Google Colab | 70.00% | 81.25% | 70.00% | 67.03% |
| Expression | iPhone | 85.00% | 88.46% | 85.00% | 84.65% |

### Inference time

| Measurement | Google Colab CPU | iPhone 17 |
|---|---:|---:|
| Mean for all 20 images | 6700.66 ms | 353.27 ms |
| Median | 7144.21 ms | 220.46 ms |
| Minimum | 1920.42 ms | 136.78 ms |
| Maximum | 8230.98 ms | 2678.74 ms |
| Warm mean | 6708.14 ms | 230.87 ms |

The first iPhone prediction included a cold-start time of 2678.74 ms. The remaining 19 predictions averaged 230.87 ms.

### Main findings

- Both systems predicted every Elderly image as Adult.
- DeepFace performed better for gender classification.
- The iPhone application performed better for Happy/Sad expression classification.
- The iPhone produced substantially faster end-to-end predictions than the Colab CPU workflow.
- The two implementations use different pretrained models and preprocessing pipelines, so the timing and accuracy comparison is an implementation-level comparison rather than a controlled comparison of identical model weights.

## Repository Contents

```text
EdgeFaceAI/
├── AgeNet.mlmodel
├── GenderNet.mlmodel
├── Emotions.mlmodel
├── ContentView.swift
├── FaceAnalyzer.swift
├── EdgeFaceAIApp.swift
├── Assets.xcassets/
├── EdgeFaceAI.xcodeproj.zip
├── DLBAIPEAI_DeepFace.ipynb
├── deepface_metrics.csv
├── deepface_predictions.csv
├── deepface_misclassified.csv
├── iphone_results_with_ground_truth.csv
├── age_confusion_matrix.png
├── gender_confusion_matrix.png
├── expression_confusion_matrix.png
├── iphone_age_confusion_matrix.png
├── iphone_expression_confusion_matrix.png
├── colab_vs_iphone_metrics.png
├── .gitattributes
├── .gitignore
└── README.md
```

## Running the iOS Application

### Requirements

- A Mac with Xcode
- A physical iPhone
- An Apple ID for free development signing
- Git LFS

### Setup

Clone the repository:

```bash
git clone https://github.com/cranzoid/EdgeFaceAI.git
cd EdgeFaceAI
```

Install and download the Git LFS objects:

```bash
git lfs install
git lfs pull
```

Extract the Xcode project:

```bash
unzip EdgeFaceAI.xcodeproj.zip
```

Open the project:

```bash
open EdgeFaceAI.xcodeproj
```

In Xcode:

1. Select the project target.
2. Open **Signing & Capabilities**.
3. Select your Personal Team.
4. Connect the iPhone.
5. Select the connected iPhone as the run destination.
6. Build and run the application.
7. Grant photo-library access when requested.

The application was tested using CPU-only inference because this configuration provided stable execution for the selected converted models and beta device environment.

## Running the Google Colab Notebook

1. Open `DLBAIPEAI_DeepFace.ipynb` in Google Colab.
2. Run the installation and import cells.
3. Provide the evaluation images using the paths expected by the notebook.
4. Use filenames `IMG01.jpg` to `IMG20.jpg`.
5. Run the DeepFace analysis cells.
6. Run the metric and visualization cells.
7. Export the generated CSV and PNG files.

The exact evaluation photographs are not redistributed in this repository. Reproducing the exact reported predictions requires access to the same authorised image set. The included result files allow the reported calculations and comparisons to be inspected.

## Output Files

- `deepface_metrics.csv` contains the aggregate DeepFace metrics.
- `deepface_predictions.csv` contains the full per-image DeepFace predictions.
- `deepface_misclassified.csv` contains DeepFace error cases.
- `iphone_results_with_ground_truth.csv` contains the iPhone predictions, ground-truth labels, confidence values and inference times.
- The PNG files contain performance comparisons and confusion matrices.
- `colab_vs_iphone_metrics.png` compares the primary Colab and iPhone metrics.

## Technical Notes

### Age mapping

DeepFace produces a numerical age estimate. Predictions of 60 or above are mapped to Elderly.

AgeNet produces an age range. Only the model's `60-100` range is mapped to Elderly. Other ranges are mapped to Adult.

### Expression mapping

Both workflows reduce emotion output to the binary task by comparing only the Happy and Sad scores. The original dominant emotion is retained where available for error analysis.

### Face handling

The iOS application uses Apple Vision to detect faces. When more than one face is detected, the largest face is selected and cropped before classification.

## Limitations

- The experiment contains only 20 images.
- Some identities appear more than once with different expressions.
- Most source photographs are frontal and controlled.
- Two test images are synthetic and may differ from the real-image distribution.
- Gender was balanced overall but not strictly balanced within each age group.
- The Colab and iPhone implementations use different pretrained models.
- CPU-only execution does not measure the potential performance of the Apple GPU or Neural Engine.
- The age models failed to recognise the Elderly class in this experiment.
- Binary model labels do not represent a person's self-identified gender.
- A visible facial expression does not prove a person's internal emotional state.

## Responsible Use

This project is intended only for academic demonstration and evaluation. It should not be used for:

- Medical decisions
- Security or surveillance decisions
- Employment decisions
- Customer profiling
- Identity determination
- Any other high-stakes decision

On-device inference reduces the need to send photographs to a remote prediction service. Exported CSV files may still contain sensitive experimental information and should be stored and deleted responsibly.

## Model and Dataset Attribution

The project uses or builds upon the following resources:

- Serengil, S. I., and Ozpinar, A. (2021). HyperExtended LightFace: A facial attribute analysis framework.
- Levi, G., and Hassner, T. (2015). Age and gender classification using convolutional neural networks.
- Levi, G., and Hassner, T. (2015). Emotion recognition in the wild via convolutional neural networks and mapped binary patterns.
- Ebner, N. C., Riediger, M., and Lindenberger, U. (2010). FACES - A database of facial expressions in young, middle-aged, and older women and men.
- [DeepFace](https://github.com/serengil/deepface)
- [FacesVisionDemo](https://github.com/cocoa-ai/FacesVisionDemo)
- [Apple Core ML](https://developer.apple.com/documentation/coreml)
- [Apple Vision](https://developer.apple.com/documentation/vision)

Third-party models, libraries and datasets remain subject to their original licences and terms. Their inclusion in this academic repository does not relicense them.

## AI-Tool Disclosure

OpenAI ChatGPT was used to support experimental planning, troubleshooting of Xcode and Core ML errors, revision of Swift and Python code, organisation of results, chart preparation and language editing.

Two supplementary synthetic portraits were generated using ChatGPT to complete the overall target counts after the selected FACES subset did not contain enough eligible Elderly Happy or Sad images.

The final methods were selected by the author. The Colab and iPhone experiments were executed by the author, the exported results were checked against the recorded files, and the author remains responsible for the submitted work.

## Author

**Vishesh Vaibhav**  
Matriculation number: 92129377  
Bachelor of Science in Applied Artificial Intelligence  
IU International University of Applied Sciences

## Academic Use Notice

This repository was prepared as supporting material for a university project report. It is provided for review and reproducibility of the academic work. Examination materials and the original evaluation images are not redistributed.
