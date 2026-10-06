# AgroShield Scan API Test Cases

## Purpose

This document defines manual integration test cases for the AgroShield scan flow.

The scan flow is:

Flutter → Spring Boot → Python AI

The main endpoint under test is:

POST /api/v1/scans

Initial supported crop:

tomato

## Test Result Status

- PASS — Actual result matches the expected result.
- FAIL — Actual result does not match the expected result.
- NOT RUN — Test has not been executed yet.
- BLOCKED — Test cannot be executed because a required service, endpoint, test data, or dependency is unavailable.

A test must never be marked PASS if the required endpoint or functionality does not exist.

## Important File Size Rule

The 5 MiB limit applies to the uploaded image file itself.

5 MiB = 5,242,880 bytes.

Multipart/form-data overhead is not part of the image file size limit.

## Test Cases

| ID | Test case | Preconditions | Input | Expected status / fields | Actual result | Evidence | Result |
|---|---|---|---|---|---|---|---|
| SCAN-001 | Java health check | Spring Boot is running | GET `/api/v1/health` | HTTP 200; `service` = `agroshield-backend`; `status` = `UP` | Not run | Not available | NOT RUN |
| SCAN-002 | Python AI health check | Python AI service is running | GET `/health` | HTTP 200; `service` = `agroshield-ai`; `status` = `UP`; `analysisMode` = `MOCK`; `modelVersion` = `mock-v1` | Not run | Not available | NOT RUN |
| SCAN-003 | Valid JPEG tomato scan | Spring Boot and Python AI services are running; valid JPEG test image available | POST `/api/v1/scans`; `image` = valid JPEG; `cropId` = `tomato` | HTTP 201; response contains `scanId`, `cropId`, disease fields, `confidence`, `predictionStatus`, `analysisMode`, `modelVersion`, and `createdAt`; successful scan is saved | Not run | Not available | NOT RUN |
| SCAN-004 | Valid PNG tomato scan | Spring Boot and Python AI services are running; valid PNG test image available | POST `/api/v1/scans`; `image` = valid PNG; `cropId` = `tomato` | HTTP 201; successful scan is saved and response contains the required fields | Not run | Not available | NOT RUN |
| SCAN-005 | Missing image field | Spring Boot is running | POST `/api/v1/scans`; `cropId` = `tomato`; no `image` field | HTTP 400; error code = `INVALID_REQUEST` | Not run | Not available | NOT RUN |
| SCAN-006 | Missing cropId field | Spring Boot is running; valid image available | POST `/api/v1/scans`; valid image; no `cropId` | HTTP 400; error code = `INVALID_REQUEST` | Not run | Not available | NOT RUN |
| SCAN-007 | Unsupported cropId | Spring Boot is running; valid image available | POST `/api/v1/scans`; valid image; unsupported cropId | HTTP 400; error code = `INVALID_REQUEST` | Not run | Not available | NOT RUN |
| SCAN-008 | Invalid image bytes | Spring Boot is running | POST `/api/v1/scans`; `image` contains invalid/non-image bytes; `cropId` = `tomato` | HTTP 400; error code = `INVALID_IMAGE` | Not run | Not available | NOT RUN |
| SCAN-009 | Unsupported image type | Spring Boot is running | POST `/api/v1/scans`; image is not JPEG or PNG; `cropId` = `tomato` | HTTP 415; error code = `UNSUPPORTED_IMAGE_TYPE` | Not run | Not available | NOT RUN |
| SCAN-010 | Image exactly at 5 MiB | Spring Boot and Python AI services are running; valid JPEG/PNG test image exactly 5,242,880 bytes | POST `/api/v1/scans`; image file size = exactly 5,242,880 bytes; `cropId` = `tomato` | File is not rejected because it is exactly at the maximum allowed file size; if otherwise valid, request proceeds normally | Not run | Not available | NOT RUN |
| SCAN-011 | Image just over 5 MiB | Spring Boot is running; test image is larger than 5,242,880 bytes | POST `/api/v1/scans`; image file size > 5,242,880 bytes; `cropId` = `tomato` | HTTP 413; error code = `IMAGE_TOO_LARGE` | Not run | Not available | NOT RUN |
| SCAN-012 | AI service unavailable | Spring Boot is running; Python AI service is offline or unreachable | POST `/api/v1/scans`; valid JPEG/PNG; `cropId` = `tomato` | HTTP 503; error code = `AI_UNAVAILABLE` | Not run | Not available | NOT RUN |
| SCAN-013 | AI service timeout | Spring Boot is running; Python AI service does not respond within configured timeout | POST `/api/v1/scans`; valid JPEG/PNG; `cropId` = `tomato` | HTTP 503; error code = `AI_UNAVAILABLE` | Not run | Not available | NOT RUN |
| SCAN-014 | Malformed AI response | Spring Boot and test AI service are available; AI returns an invalid response | POST `/api/v1/scans`; valid JPEG/PNG; `cropId` = `tomato` | HTTP 502; error code = `AI_INVALID_RESPONSE` | Not run | Not available | NOT RUN |
| SCAN-015 | Storage failure | Spring Boot and Python AI services are running; storage is unavailable or saving fails | POST `/api/v1/scans`; valid JPEG/PNG; `cropId` = `tomato` | HTTP 503; error code = `STORAGE_UNAVAILABLE`; must not return successful scan response | Not run | Not available | NOT RUN |

## Successful Mock Response Checks

For a successful mock scan, verify:

- HTTP status is `201`.
- `scanId` is present.
- `cropId` is `tomato`.
- `diseaseId` is `tomato_early_blight`.
- `diseaseName` is `Tomato Early Blight`.
- `confidence` is `null`.
- `predictionStatus` is `CLASSIFIED`.
- `analysisMode` is `MOCK`.
- `modelVersion` is `mock-v1`.
- `createdAt` is present as a UTC ISO 8601 timestamp.
- The scan was actually saved before HTTP 201 is returned.

The mock disease result is a fixed integration-test fixture and is not inferred from the uploaded image.

## Additional Checks

- JPEG and PNG files must be validated by their actual image content, not only by filename extension.
- The HTTP client must generate the multipart boundary.
- Missing information must be represented as `null`, not a fabricated zero.
- A failed real model must not silently fall back to a mock result.
- Do not mark a test PASS when the required endpoint or functionality is unavailable.

## Test Execution Record

| Test execution date | Tester | Environment | Commit / version | Notes |
|---|---|---|---|---|
| Not executed | Sudhakar | Not available | Not available | Initial test cases prepared; execution pending |