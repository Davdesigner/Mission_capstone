# 🌾 AminoRice – Mobile AI Rice Quality Assessment

## 📌 Description
AminoRice is a mobile-integrated AI computer vision system that evaluates rice grain quality from images.  
The model analyzes a captured rice sample and predicts quality indicators such as:

- Total grains
- Broken grains
- Chalky grains
- Grain dimensions

The goal is to provide farmers, millers, and inspectors with a portable quality-inspection tool using a smartphone camera instead of laboratory equipment.

The project combines:
- Deep learning image regression
- Data preprocessing & augmentation
- Model inference API
- Mobile application integration

This solution supports faster and more accessible rice quality grading in real-world environments.

---

## 🔗 GitHub Repository

https://github.com/Davdesigner/Mission_capstone.git

## Video demo

https://drive.google.com/file/d/1w-XUjHkWJbogdZeI79E8lTJgOZxZYFOE/view?usp=sharing

---

# ⚙️ Environment Setup

## 1️⃣ Clone the Repository
```bash
git clone [https://github.com/your-username/ricevision.git](https://github.com/Davdesigner/Mission_capstone.git)
cd Mission capstone
```
## 2️⃣ Create Virtual Environment
```bash
python -m venv venv
```
### Activate:

Windows:
```bash
venv\Scripts\activate
```
Mac/Linux:
```bash
source venv/bin/activate
```
## Install all dependencies
```bash
pip install -r requirements.txt
```
## 4️⃣ Dataset Setup

Place the dataset inside:
```
project-root/
│
├── data/
│   ├── train.csv
│   └── images/
```
Update paths inside the notebook or script:
```
DATASET_PATH = "data/train.csv"
IMG_DIR = "data/images"
```
## 5️⃣ Run Model Notebook
Open in VS Code or Jupyter:
```
jupyter notebook
```
Run: 
```
David_Mission_Capstone.ipynb
```
# 🖼 Designs Deployment
## Figma 
Figma Design Link: https://www.figma.com/design/jeT4IBYbf2ajMnx0zNKLIo/AminoRice?node-id=0-1&t=sO9ItIcCcm1ehnLM-1 
<img width="450" height="913" alt="Screenshot 2026-02-13 135541" src="https://github.com/user-attachments/assets/826aa459-b235-4f60-b0fd-bd314072217a" />
<img width="442" height="908" alt="image" src="https://github.com/user-attachments/assets/cd8061ab-e615-4a92-a30a-aa89a5ededc0" />

## 🧩 System Architecture Diagram
Includes:
- Mobile App
- Preprocessing Engine
- CNN Model
- Prediction Layer
- API Gateway
- Results Visualization
