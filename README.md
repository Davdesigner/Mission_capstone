# AminoRice: AI-Powered Rice Quality Assessment

## Project Overview

**AminoRice** is an AI-powered computer vision system designed to evaluate rice grain quality using image analysis. The system analyzes rice grain images and predicts scientifically relevant quality indicators using a deep learning model.

The goal of this project is to assist farmers, rice processors, suppliers, and regulators in evaluating rice quality quickly and objectively using accessible digital tools.

The system predicts key rice grain characteristics and interprets them to classify rice quality levels such as:

- Premium Quality
- Standard Quality
- Substandard Quality/Poor Quality

This solution contributes to improving transparency and quality control in rice value chains.

## Video Demo

https://drive.google.com/file/d/19OiV5hV0iF7xf0K2W2BuOtHr3dAvxDNI/view?usp=sharing


## Project Objectives

1. Develop a deep learning computer vision model capable of predicting key rice quality indicators from grain images.

2. Evaluate the performance of the model using standard machine learning evaluation metrics.

3. Design a mobile-ready deployment architecture that enables users to assess rice quality through a mobile application interface.



## Repository Structure

```
AminoRice/
│
├── notebook/
│   └── Mission_Capstone.ipynb
│
├── model/
│   ├── best_rice_model.keras
│   └── target_scaler.pkl
│
├── dataset/
│   ├── Train.csv
│   ├── Test.csv
│   └── images/
│
├── api/
│   ├── main.py
│   ├── predictor.py
│   └── requirements.txt
│
├── design/
│   └── AminoRice_Figma_UI.png
│
└── README.md
```



## Dataset Description

The dataset contains images of rice samples captured under controlled conditions. Each image corresponds to laboratory-measured quality indicators used as ground truth labels for model training and evaluation.

### Target Variables

The machine learning model predicts the following rice quality indicators:

```
Count
Broken_Count
Long_Count
Medium_Count
Black_Count
Chalky_Count
Red_Count
Yellow_Count
Green_Count
WK_Length_Average
WK_Width_Average
WK_LW_Ratio_Average
Average_L
Average_a
Average_b
```

These variables represent grain size, structure, color characteristics, and defect counts.



## Machine Learning Model

The system uses a **deep learning architecture based on EfficientNetB0**, a convolutional neural network known for strong performance in image classification and feature extraction.

The architecture includes:

- EfficientNetB0 convolutional backbone
- Global Average Pooling layer
- Fully connected regression layers
- Output layer predicting 15 rice quality indicators



## Model Architecture

```
Input Image (224x224x3)
        │
        ▼
EfficientNetB0 (Pretrained CNN Backbone)
        │
        ▼
Global Average Pooling
        │
        ▼
Dense Layer (512 neurons)
        │
        ▼
Dropout Layer
        │
        ▼
Dense Output Layer (15 units)
        │
        ▼
Predicted Rice Quality Indicators
```

## Performance Evaluation

Model performance is evaluated using standard regression metrics:

- Mean Absolute Error (MAE)
- Mean Squared Error (MSE)
- Root Mean Squared Error (RMSE)

Example evaluation code:

```python
from sklearn.metrics import mean_absolute_error, mean_squared_error
import numpy as np

mae = mean_absolute_error(y_true, y_pred)
mse = mean_squared_error(y_true, y_pred)
rmse = np.sqrt(mse)

print("MAE:", mae)
print("RMSE:", rmse)
```

## Environment Setup

### 1. Clone the Repository

```bash
git clone [https://github.com/your-username/ricevision.git](https://github.com/Davdesigner/Mission_capstone.git)
cd Mission capstone

```

### 2. Create a Virtual Environment

```bash
python -m venv venv
```

Activate the environment.

Windows:

```bash
venv\Scripts\activate
```

Mac/Linux:

```bash
source venv/bin/activate
```

### 3. Install Dependencies

```bash
pip install -r api/requirements.txt
```

Example dependencies:

```
tensorflow
fastapi
uvicorn
numpy
pandas
opencv-python
scikit-learn
pillow
python-multipart
joblib
```

## Model Loading

```python
import tensorflow as tf
import joblib

model = tf.keras.models.load_model("model/best_rice_model.keras", compile=False)
target_scaler = joblib.load("model/target_scaler.pkl")
```

## Image Preprocessing

```python
import cv2
import numpy as np

def preprocess_image(image_path):

    img = cv2.imread(image_path)
    img = cv2.resize(img, (224,224))
    img = img / 255.0

    img = np.expand_dims(img, axis=0)

    return img
```

## Prediction Function

```python
def amino_rice_predict(image_path):

    img = preprocess_image(image_path)

    pred_scaled = model.predict(img)

    pred = target_scaler.inverse_transform(pred_scaled)

    return pred
```

## Quality Interpretation Logic

```python
def classify_rice_quality(long_count, chalky_count):

    if long_count > 70 and chalky_count < 5:
        return "Premium Quality"

    elif long_count > 40:
        return "Standard Quality"

    else:
        return "Substandard Quality"
```

## API Deployment (FastAPI)

Run the backend server:

```bash
uvicorn main:app --reload
```

Example API endpoint:

```
POST /predict
```

Example JSON response:

```json
{
  "Long_Count": 72,
  "Broken_Count": 6,
  "Chalky_Count": 2,
  "Quality_Class": "Premium Quality"
}
```

## Mobile Application Integration

The AminoRice system is designed to integrate with a **Flutter-based mobile application**. The mobile application allows users to:

- Capture rice grain images
- Upload images to the AI backend
- Receive instant rice quality predictions

## Interface Design

![AminoRice UI](design/AminoRice_Figma_UI.png)

## Deployment Architecture

```
Mobile App (Flutter)
        │
        ▼
Image Upload
        │
        ▼
FastAPI Backend
        │
        ▼
Deep Learning Model
        │
        ▼
Prediction Results
        │
        ▼
Rice Quality Interpretation
        │
        ▼
Results returned to the mobile application
```

## Future Improvements

Possible extensions of the project include:

- Real-time grain segmentation using object detection
- On-device inference using TensorFlow Lite
- Integration with agricultural supply chain monitoring systems
- Cloud deployment for large-scale agricultural analytics

## Author

David Ubushakebwimana  
Mission Capstone 
