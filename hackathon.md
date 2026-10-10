# Blind Vision Assistant — Hackathon Submission & Build Log

## 1. Project
- **Name**: Blind Vision Assistant
- **Purpose**: An offline AI vision assistant that helps blind users describe scenes, read text, and identify objects using voice, with complete on-device privacy.
- **Problem**: Blind users have no private, offline tool to describe scenes, read text, or identify objects via voice without relying on cloud services that compromise privacy or require constant internet connectivity.

## 2. Team
<!-- Builder names/handles to be added by the user -->

## 3. Stack
- **Framework**: Flutter
- **On-Device Vision Model**: flutter_gemma (`Gemma 3n E2B IT Int4`)
- **Text Recognition**: google_mlkit_text_recognition
- **Voice / Accessibility**: flutter_tts, speech_to_text, audioplayers
- **Device & Storage**: camera, flutter_downloader, shared_preferences
- **Auth / Assets**: HuggingFace OAuth

## 4. Build Log
### 2026-10-10
- **Status**: Completed (Kickoff)
- **Summary**: Project kickoff. hackathon.md created. Flutter project setup pending. neatlogs and Entire integrations pending.
- **Completed Work**: Initialized project repository documentation and hackathon tracking.
- **Planned Work**: Set up Flutter project foundation, configure on-device AI pipelines, instrument neatlogs, and link Entire graph.
- **Tests Run**: N/A (Documentation phase).
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 2 — Flutter Project Setup)
- **Status**: Completed
- **Summary**: Initialized Flutter project with Android platform support (`blind_vision_assistant`, `com.hackathon`). 34 project files generated.
- **Completed Work**: Executed `flutter create . --project-name blind_vision_assistant --org com.hackathon --platforms android`. Generated Android Gradle structure, Kotlin MainActivity, analysis options, `pubspec.yaml`, and entrypoint `lib/main.dart`.
- **Planned Work**: Add app dependencies to `pubspec.yaml`, connect on-device AI pipeline, instrument neatlogs logging, leverage Entire graph.
- **Tests Run**: Verified Flutter project initialization build script (Exit code: 0).
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 3 — NeatLogs Integration & Verification)
- **Status**: Completed
- **Summary**: Implemented telemetry trace pipeline for NeatLogs and verified live trace delivery.
- **Completed Work**: Configured HTTP trace injection to `https://ingest.neatlogs.com/v1/trace`. Dispatched live verification trace (Trace ID: `d722535861ccbe1337802212a4d044c8`).
- **Planned Work**: Add app dependencies to `pubspec.yaml` and implement offline AI pipelines.
- **Tests Run**: API Ingestion verification (HTTP 200 OK, 3 spans ingested).
- **Known Issues / Failures**: None.

## 5. Demo
- **URL**: Pending
- **Instructions**: Reproduction and run instructions will be documented upon initial build.

## 6. Known Limitations and Next Steps
- **Limitations**:
  - Requires ~3GB model download for local on-device inference.
  - Android only for AI features.
  - No real-time video stream (operates on captured frames/snapshots).
- **Next Steps**:
  - Add Flutter dependencies (`flutter_gemma`, `google_mlkit_text_recognition`, etc.).
  - Leverage Entire code graph for agent context and navigation.

## 7. Submission
- **neatlogs**: Connected & Verified (Trace ID: `d722535861ccbe1337802212a4d044c8`)
- **Entire**: Pending
- **cfo.ai**: N/A

