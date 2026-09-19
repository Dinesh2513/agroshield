# AgroShield API Contract — Version 1

## First milestone

Flutter uploads a tomato leaf image to Spring Boot.
Spring Boot forwards it to the Python AI service.
Spring Boot saves a successful result and returns it to Flutter.

Initial predictions are explicitly labelled as mock results.
A trained model will replace the mock implementation later.

## Ownership

- Dinesh: Flutter application.
- Jayanth: Spring Boot APIs, database and AI-service connection.
- Lalsingh: Python AI service and disease model.
- Sudhakar: farm analytics specifications and integration testing.

## Development ports

- Spring Boot: 8080
- Python AI service: 8000

Flutter communicates with Spring Boot.
Spring Boot communicates with the Python AI service.

On an Android emulator, the host computer is usually reachable
through 10.0.2.2 instead of localhost.

On a physical Android phone, use the backend computer's LAN IP.
The phone and computer must have network access to each other.

## Shared conventions

- JSON field names use camelCase.
- Initial supported cropId: "tomato".
- Identifiers use lowercase snake_case.
- confidence is a number from 0 to 1, or null when unavailable.
- Missing measurements are null, never zero.
- Timestamps use UTC ISO 8601, such as 2026-09-19T10:30:00Z.
- analysisMode is "MOCK" or "MODEL".
- predictionStatus is "CLASSIFIED" or "UNCERTAIN".
- MOCK results must visibly say "Demo result — not an AI diagnosis".
- MODEL identifies real inference; it does not guarantee accuracy.

## 1. Java backend health

GET /api/v1/health

Successful response: HTTP 200

```json
{
  "service": "agroshield-backend",
  "status": "UP"
}
```

This endpoint confirms the Java application is running.
It does not verify the AI service or database.

## 2. Python AI health

GET /health

Successful response: HTTP 200

```json
{
  "service": "agroshield-ai",
  "status": "UP",
  "analysisMode": "MOCK",
  "modelVersion": "mock-v1"
}
```

## 3. Flutter uploads an image to Java

POST /api/v1/scans

Content-Type: multipart/form-data

Required fields:

| Field | Type | Description |
|---|---|---|
| image | File | JPEG or PNG image, maximum 5 MiB |
| cropId | Text | "tomato" for the first milestone |

Both services must validate the file size and decode the image.
A filename extension alone is insufficient.

Flutter must let its HTTP library generate the multipart boundary.

Successful response after saving: HTTP 201

```json
{
  "scanId": "8f2e7b10-4321-4bcd-9876-123456789abc",
  "cropId": "tomato",
  "diseaseId": "tomato_early_blight",
  "diseaseName": "Tomato Early Blight",
  "confidence": null,
  "predictionStatus": "CLASSIFIED",
  "analysisMode": "MOCK",
  "modelVersion": "mock-v1",
  "createdAt": "2026-09-19T10:30:00Z"
}
```

The disease above is a fixed integration-test example.
It is not inferred from the uploaded image.
Mock confidence stays null because no model ran.

Spring Boot generates scanId and createdAt.
Flutter displays a message instead of a percentage when confidence is null.

## 4. Java calls Python

POST /predict

Content-Type: multipart/form-data

Use the same image and cropId fields as the Flutter upload.

Successful response: HTTP 200

```json
{
  "cropId": "tomato",
  "diseaseId": "tomato_early_blight",
  "diseaseName": "Tomato Early Blight",
  "confidence": null,
  "predictionStatus": "CLASSIFIED",
  "analysisMode": "MOCK",
  "modelVersion": "mock-v1"
}
```

Python returns prediction information.
Spring Boot owns scan storage and scan identifiers.

When a real model cannot give a reliable classification:
- predictionStatus must be "UNCERTAIN".
- diseaseId and diseaseName must be null.
- Flutter must show "Unable to identify reliably".
- Confidence thresholds will be chosen using validation results.

## Errors returned by Spring Boot to Flutter

Use this response structure:

```json
{
  "error": {
    "code": "INVALID_IMAGE",
    "message": "Please upload a valid JPEG or PNG image."
  }
}
```

| HTTP status | Error code | Meaning |
|---|---|---|
| 400 | INVALID_REQUEST | Missing field or unsupported cropId |
| 400 | INVALID_IMAGE | File cannot be decoded as an image |
| 413 | IMAGE_TOO_LARGE | File exceeds 5 MiB |
| 415 | UNSUPPORTED_IMAGE_TYPE | Image is not JPEG or PNG |
| 502 | AI_INVALID_RESPONSE | Python returns an invalid response |
| 503 | AI_UNAVAILABLE | Python is unavailable or times out |
| 503 | STORAGE_UNAVAILABLE | Scan cannot be saved |

Spring Boot translates internal service errors into this format.
Never silently replace a failed real prediction with a mock result.

## Deferred features

Weather, soil-report analysis, severity and growth tracking
will receive separate contracts after this milestone works.

Do not invent values for features that are not implemented.

## Contract changes

Propose changes through a pull request.
Notify affected teammates before merging a change.
Update this document alongside the implementation.