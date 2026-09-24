from io import BytesIO

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from PIL import Image

app = FastAPI(title="AgroShield AI Service")

MAX_FILE_SIZE = 5 * 1024 * 1024
ALLOWED_TYPES = {"image/jpeg", "image/png"}


@app.get("/health")
def health():
    return {
        "service": "agroshield-ai",
        "status": "UP",
        "analysisMode": "MOCK",
        "modelVersion": "mock-v1"
    }


@app.post("/predict")
async def predict(
    image: UploadFile = File(...),
    cropId: str = Form(...)
):
    if image.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=415,
            detail="Only JPEG and PNG images are supported"
        )

    image_bytes = await image.read()

    if len(image_bytes) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=413,
            detail="Image size must not exceed 5 MiB"
        )

    try:
        with Image.open(BytesIO(image_bytes)) as img:
            img.verify()
    except Exception:
        raise HTTPException(
            status_code=400,
            detail="Invalid image file"
        )

    return {
        "cropId": cropId,
        "diseaseId": "tomato_early_blight",
        "diseaseName": "Tomato Early Blight",
        "confidence": None,
        "predictionStatus": "CLASSIFIED",
        "analysisMode": "MOCK",
        "modelVersion": "mock-v1"
    }
}
