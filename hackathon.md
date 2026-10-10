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

### 2026-10-10 (Session 4 — Incremental Commits & GitHub Synchronization)
- **Status**: Completed
- **Summary**: Staged and synchronized initial codebase to GitHub across 5 focused, incremental commits.
- **Completed Work**: Pushed project configs, hackathon log, Flutter manifests, Android shell, and Dart entrypoint to `origin/main` with Entire code-graph checkpoint sync. Live telemetry trace recorded in NeatLogs (Trace ID: `e819222c3b4c0364993eebf83d0bad01`).
- **Planned Work**: Install accessibility and on-device AI packages in `pubspec.yaml` and build core screen layout.
- **Tests Run**: Git status verification & remote ref updates.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 5 — Dependency Manifest & Assets Configuration)
- **Status**: Completed
- **Summary**: Configured full offline AI, OCR, TTS, voice, and audio package suite in `pubspec.yaml`.
- **Completed Work**: Added 19 dependencies (`flutter_gemma`, `camera`, `speech_to_text`, `flutter_tts`, `google_mlkit_text_recognition`, etc.) and configured `assets/` folder. Successfully executed `flutter pub get` (89 dependencies resolved and downloaded).
- **Planned Work**: Setup application architecture, camera service, and local inference pipeline.
- **Tests Run**: `flutter pub get` executed cleanly with exit code 0.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 6 — Android Native Hardware & Permission Configuration)
- **Status**: Completed
- **Summary**: Configured Android SDK levels and runtime permissions for offline vision assistant.
- **Completed Work**: Set `compileSdk = 35`, `targetSdk = 35`, and `minSdk = 26` in `android/app/build.gradle.kts`. Configured permissions for camera, audio recording, internet, external storage, wake lock, foreground service, and legacy storage in `AndroidManifest.xml`. Confirmed AndroidX and Jetifier in `gradle.properties`.
- **Planned Work**: Implement Flutter service layers (camera, TTS, speech, Gemma vision engine).
- **Tests Run**: Gradle manifest and properties syntax verification.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 7 — Scaffolding Modular Architecture & Audio Assets)
- **Status**: Completed
- **Summary**: Created clean feature-based modular directory architecture and placeholder sound assets.
- **Completed Work**: Created `chat_page/` (config, handlers, models, services, widgets) and `download_page/` (config, logic, models, services, ui) subdirectories. Added audio assets (`woosh.mp3`, `dictation_start.mp3`, `dictation_stop.mp3`) under `assets/`. Pushed to GitHub with Entire checkpoint sync.
- **Planned Work**: Implement core data models, service abstractions, and UI widgets under 100-line modular design.
- **Tests Run**: Filesystem tree verification.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 8 — Core Chat & Performance Models Implementation)
- **Status**: Completed
- **Summary**: Implemented foundational multimodal message and latency telemetry models.
- **Completed Work**: Created `lib/chat_page/models/message_models.dart` (44 lines) defining `ChatMessage` (with factory constructors for text & image messages) and `MessageStats` (tracking time-to-first-token, latency, token count, prefill & decode speeds). Pushed to GitHub with Entire checkpoint sync.
- **Planned Work**: Implement camera handler, TTS/STT services, and UI widgets.
- **Tests Run**: Dart syntax and null-safety verification.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 9 — System Prompts & Accessibility Actions Configuration)
- **Status**: Completed
- **Summary**: Defined core system prompts and high-utility blind user visual accessibility quick actions.
- **Completed Work**: Created `lib/chat_page/config/system_prompts.dart` (15 lines) defining zero-allocation static const prompt instructions and four dedicated accessibility intents (room layout/hazards, general scene overview, object identification, and exact OCR text reading). Pushed to GitHub with Entire sync.
- **Planned Work**: Implement camera handler, TTS/STT services, and UI widgets.
- **Tests Run**: Dart compile-time constant analysis.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 10 — Gemma 3n On-Device Inference Engine Service)
- **Status**: Completed
- **Summary**: Implemented GemmaService singleton managing on-device Gemma 3n E2B model lifecycle and streaming response telemetry.
- **Completed Work**: Created `lib/chat_page/services/gemma_service.dart` (98 lines). Configured idempotent initialization, local .task binary loading, multimodal image queries, asynchronous stream listener, latency tracking, session reset, and native resource disposal. Pushed to GitHub with Entire sync.
- **Planned Work**: Implement speech/audio service and camera frame processing handlers.
- **Tests Run**: Dart static analysis and async Completer lifecycle verification.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 11 — Non-Blocking Audio Cue Feedback Service)
- **Status**: Completed
- **Summary**: Implemented SoundManager service providing acoustic feedback for blind accessibility navigation.
- **Completed Work**: Created `lib/chat_page/services/sound_manager.dart` (27 lines) wrapping `AudioPlayer` for `woosh.mp3`, `dictation_start.mp3`, and `dictation_stop.mp3` with non-crashing silent exception handling. Pushed to GitHub with Entire sync.
- **Planned Work**: Implement OCR recognition service and streaming TTS service.
- **Tests Run**: Audio asset source path verification.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 12 — On-Device Text Recognition Engine)
- **Status**: Completed
- **Summary**: Implemented TextRecognitionService singleton leveraging Google ML Kit for on-device OCR extraction.
- **Completed Work**: Created `lib/chat_page/services/text_recognition_service.dart` (35 lines) utilizing Latin script text recognizer with lazy initialization, defensive image validation, and resource cleanup. Pushed to GitHub with Entire sync.
- **Planned Work**: Implement StreamingTtsService for real-time speech synthesis.
- **Tests Run**: ML Kit Latin script recognizer initialization verification.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 13 — Sentence-Boundary Streaming Text-To-Speech)
- **Status**: Completed
- **Summary**: Implemented StreamingTtsService providing low-latency speech synthesis for blind users.
- **Completed Work**: Created `lib/chat_page/services/streaming_tts_service.dart` (49 lines). Implemented sentence-boundary buffering (`[.!?]`), reactive speaking state notification (`ValueNotifier<bool>`), clean buffer flush on completion, and interrupt/reset methods. Pushed to GitHub with Entire sync.
- **Planned Work**: Implement camera handler and chat UI components.
- **Tests Run**: Regex sentence-boundary trigger verification.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 14 — Acoustic Dictation & Voice Speech Service)
- **Status**: Completed
- **Summary**: Implemented SpeechService coordinating speech recognition, TTS feedback, and earcon sound cues.
- **Completed Work**: Created `lib/chat_page/services/speech_service.dart` (88 lines) integrating `SpeechToText`, `FlutterTts`, `SoundManager`, and prompt bar text binding with F2 shortcut listener. Pushed to GitHub with Entire sync.
- **Planned Work**: Implement tactile KeyboardHandler for hardware accessibility shortcuts.
- **Tests Run**: Speech recognition state machine & dictation sound synchronization verification.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 15 — Tactile Hardware Keyboard Accessibility Shortcuts)
- **Status**: Completed
- **Summary**: Implemented KeyboardHandler translating physical F1–F8 function keys into immediate vision, voice, and navigation intents.
- **Completed Work**: Created `lib/chat_page/handlers/keyboard_handler.dart` (64 lines) integrating Flutter `Shortcuts` and `Actions` architecture for tactile navigation (F1: messages, F2: voice, F3: new chat, F4: settings, F5-F8: visual quick actions). Pushed to GitHub with Entire sync.
- **Planned Work**: Implement camera handler and core UI widgets.
- **Tests Run**: Key activator and callback binding validation.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 16 — Chat Operations & Camera-OCR-TTS Orchestration)
- **Status**: Completed
- **Summary**: Implemented ChatHelpers service coordinating camera snapshot capture, on-device OCR enhancement, streaming AI inference, and real-time TTS audio feedback.
- **Completed Work**: Created `lib/chat_page/services/chat_helpers.dart` (98 lines). Features ephemeral camera lifecycle (instant initialization and disposal to prevent thermal throttling and battery drain for blind users), 3-token UI update throttling for smooth framerates, Latin OCR text injection into multimodal prompt contexts, and quick action routines. Pushed to GitHub with Entire sync.
- **Planned Work**: Implement BootstrapManager for robust dependency injection and startup orchestration.
- **Tests Run**: Camera capture lifecycle, OCR prompt augmentation, and streaming token throttle verification.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 17 — Service Dependency Injection & Bootstrap Manager)
- **Status**: Completed
- **Summary**: Implemented BootstrapManager orchestrating safe initialization order across TTS, OCR, speech dictation, chat helpers, keyboard shortcuts, and Gemma 3n inference.
- **Completed Work**: Created `lib/chat_page/services/bootstrap_manager.dart` (98 lines). Implemented asynchronous startup dependency ordering (TTS -> OCR -> Speech -> ChatHelpers -> KeyboardHandler -> GemmaService), 30-second timeout watchdog with Completer deadlock protection, and clean lifecycle teardown. Pushed to GitHub with Entire sync.
- **Planned Work**: Implement download page configuration constants and HuggingFace OAuth authentication flow.
- **Tests Run**: Bootstrap sequencing and Completer timeout handling verification.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 18 — HuggingFace OAuth & Model Download Configuration)
- **Status**: Completed
- **Summary**: Configured constants for HuggingFace OAuth authentication, Gemma 3n LiteRT model endpoints, and download persistence keys.
- **Completed Work**: Created `lib/download_page/config/constants.dart` (16 lines). Defined client credentials, authorization/token endpoints, custom redirect URI scheme (`com.hackathon.blind_vision_assistant://oauthredirect`), model asset URLs for Gemma 3n E2B IT Int4, and SharedPreferences persistent state keys. Pushed to GitHub with Entire sync.
- **Planned Work**: Implement HuggingFace OAuth service, PKCE challenge generator, and background model downloader.
- **Tests Run**: OAuth URI and HuggingFace endpoint URI validation.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 19 — Semantic Button Registry)
- **Status**: Completed
- **Summary**: Implemented SemanticButtonRegistry providing centralized accessibility key mapping for assistive technologies.
- **Completed Work**: Created `lib/chat_page/widgets/semantic_button_registry.dart` (14 lines). Implemented static registry linking accessible button labels to GlobalKeys for programmatic focus management and screen reader routing. Pushed to GitHub with Entire sync.
- **Planned Work**: Implement SemanticMaterialButton accessible UI component.
- **Tests Run**: Registry registration, lookup, and clear method verification.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 20 — Accessible Semantic Material Button)
- **Status**: Completed
- **Summary**: Implemented SemanticMaterialButton wrapping Semantics, Tooltip, and Material ink responses for high-contrast accessibility.
- **Completed Work**: Created `lib/chat_page/widgets/semantic_material_button.dart` (58 lines). Auto-registers with SemanticButtonRegistry on initialization, guarantees TalkBack/VoiceOver button semantics and enabled state announcements, and provides tactile ink splash feedback. Pushed to GitHub with Entire sync.
- **Planned Work**: Implement ChatBubble widget for multimodal streaming display.
- **Tests Run**: Semantics node binding and registry registration verification.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 21 — Accessible Chat Bubble with Streaming Indicator)
- **Status**: Completed
- **Summary**: Implemented ChatBubble widget rendering multimodal chat messages, markdown formatting, and animated streaming dots.
- **Completed Work**: Created `lib/chat_page/widgets/chat_bubble.dart` (82 lines). Integrated `GptMarkdown` with accessibility `Semantics` label wrapper, animated pulsing dots during active generation, thumbnail rendering for captured camera snapshots, and inference latency telemetry display. Pushed to GitHub with Entire sync.
- **Planned Work**: Implement PromptBar input widget and ChatPageView screen.
- **Tests Run**: User vs AI styling, streaming dots animation, and markdown semantics validation.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 22 — Accessible Prompt Bar Input Controller)
- **Status**: Completed
- **Summary**: Implemented PromptBar widget with public controller methods for programmatic voice-to-text population and accessible multimodal send controls.
- **Completed Work**: Created `lib/chat_page/widgets/prompt_bar.dart` (99 lines). Features public `setText` and `clear` API on `PromptBarState` for external `SpeechService` dictation binding, explicit Semantics labels for photo/text send buttons and speech toggles, and reactive TTS stop control. Pushed to GitHub with Entire sync.
- **Planned Work**: Implement ChatUIBuilder pure static builder.
- **Tests Run**: Controller text mutation, cursor positioning, and action callback bindings verification.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 23 — Chat UI Builder Presentation Layer)
- **Status**: Completed
- **Summary**: Implemented ChatUIBuilder isolating stateless UI rendering logic from page state management.
- **Completed Work**: Created `lib/chat_page/widgets/chat_ui_builder.dart` (97 lines). Provides pure static builders for accessible app bar, view toggle controls, scrollable messages container, model loading screens, and prompt bar assembly, adhering to Rule 2 (One File, One Job). Pushed to GitHub with Entire sync.
- **Planned Work**: Implement main ChatPageView screen.
- **Tests Run**: Static builder widget hierarchy and semantics structure validation.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 24 — Accessible Prompt Bar Voice & State Semantics)
- **Status**: Completed
- **Summary**: Refined PromptBar widget integrating dynamic voice listening hint text and explicit screen reader semantics across multimodal action buttons.
- **Completed Work**: Updated `lib/chat_page/widgets/prompt_bar.dart` (99 lines). Features public `setText` and `clear` API on `PromptBarState` for external `SpeechService` dictation binding, reactive `Listening...` vs `Ask something...` placeholder text, and explicit Semantics button wrappers for photo send, text send, dictation toggle, and TTS speech cancellation. Pushed to GitHub with Entire sync.
- **Planned Work**: Implement main ChatPageView and settings dialog.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 25 — App Bootstrap Entry Point & Background Downloader Config)
- **Status**: Completed
- **Summary**: Implemented application entry point in `lib/main.dart` initializing background downloader isolate messaging, WakelockPlus screen retention, and initial routing.
- **Completed Work**: Replaced default demo app in `lib/main.dart` (35 lines). Configured `FlutterDownloader` with top-level `@pragma('vm:entry-point')` callback dispatching progress via `IsolateNameServer`, enabled `WakelockPlus` to keep device awake during 3GB model transfers, and set `ModelDownloadPage` as root home. Pushed to GitHub with Entire sync.
- **Planned Work**: Implement `ModelDownloadPage` and download logic services.
- **Tests Run**: Isolate entry point annotation and bootstrap sequence validation.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 26 — Download Status Lifecycle State Enum)
- **Status**: Completed
- **Summary**: Defined `DownloadStatus` enum representing mutually exclusive lifecycle phases of the background model download pipeline.
- **Completed Work**: Created `lib/download_page/models/enums.dart` (9 lines). Enumerates `notStarted`, `downloading`, `paused`, `completed`, `failed`, and `cancelled` states, preventing invalid concurrent boolean flags. Pushed to GitHub with Entire sync.
- **Planned Work**: Implement `DownloadState` and `HuggingFaceToken` models.
- **Tests Run**: Enum values and exhaustiveness switch structure verification.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 27 — Immutable Download State and HuggingFace Token Models)
- **Status**: Completed
- **Summary**: Implemented immutable data models `DownloadState` and `HuggingFaceToken` for predictable state transitions and auth deserialization.
- **Completed Work**: Created `lib/download_page/models/models.dart` (44 lines). Implements `DownloadState` with immutable `copyWith` semantics to avoid race conditions during async isolate progress updates, and `HuggingFaceToken` with JSON factory parser for OAuth credentials. Pushed to GitHub with Entire sync.
- **Planned Work**: Implement `AppLogger` service.
- **Tests Run**: Immutable copyWith updates and JSON factory deserialization verification.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 28 — Debug-Only Privacy-Preserving Logger Service)
- **Status**: Completed
- **Summary**: Implemented `AppLogger` utility enforcing debug-only telemetry output via `kDebugMode` guards.
- **Completed Work**: Created `lib/download_page/services/logger.dart` (12 lines). Provides standardized console and error logging that compiles to no-ops in release builds, protecting user privacy and preventing sensitive tokens or paths from leaking into production system logs. Pushed to GitHub with Entire sync.
- **Planned Work**: Implement download state management and UI widgets.
- **Tests Run**: kDebugMode gating and error formatting validation.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 29 — HuggingFace OAuth Token Persistence Service)
- **Status**: Completed
- **Summary**: Implemented `TokenManager` managing HuggingFace OAuth bearer token persistence via `SharedPreferences`.
- **Completed Work**: Created `lib/download_page/services/token_manager.dart` (42 lines). Provides asynchronous static helpers for saving, retrieving, clearing, and probing authentication credentials, isolating auth storage from download state. Pushed to GitHub with Entire sync.
- **Planned Work**: Implement `DownloadStateManager` service.
- **Tests Run**: Token persistence and null check validation.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 30 — Download Task State and Lifecycle Persistence Service)
- **Status**: Completed
- **Summary**: Implemented `DownloadStateManager` caching active task IDs and download progress status across application restarts.
- **Completed Work**: Created `lib/download_page/services/download_state_manager.dart` (45 lines). Persists `DownloadStatus` name strings and background task IDs via `SharedPreferences`, enabling the app to resume tracking downloads when relaunched. Pushed to GitHub with Entire sync.
- **Planned Work**: Implement `HuggingFaceOAuth` service.
- **Tests Run**: State serialization and deserialization fallback verification.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 31 — HuggingFace OAuth PKCE Authentication Flow)
- **Status**: Completed
- **Summary**: Implemented `HuggingFaceOAuth` executing RFC 7636 PKCE (Proof Key for Code Exchange) auth without hardcoding client secrets.
- **Completed Work**: Created `lib/download_page/services/huggingface_oauth.dart` (65 lines). Generates high-entropy code verifier and SHA-256 challenge, opens custom tab authentication using `FlutterWebAuth2`, and exchanges auth codes for bearer tokens. Pushed to GitHub with Entire sync.
- **Planned Work**: Implement download manager business logic and UI view.
- **Tests Run**: PKCE verifier generation and token response parsing validation.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 32 — Download Manager Background Progress and Task Controller)
- **Status**: Completed
- **Summary**: Implemented `DownloadManager` orchestrating FlutterDownloader isolate message handling, reactive state broadcast, and task controls.
- **Completed Work**: Created `lib/download_page/services/download_manager.dart` (95 lines). Listens to native background download updates via `ReceivePort` / `IsolateNameServer`, maps task status into `DownloadStatus`, persists changes through `DownloadStateManager`, and exposes start/pause/resume/cancel controls. Pushed to GitHub with Entire sync.
- **Planned Work**: Implement `DownloadLogic` coordinator.
- **Tests Run**: Isolate port registration and lifecycle state transition verification.
- **Known Issues / Failures**: None.

### 2026-10-10 (Session 33 — Download Logic Coordinator and Model Integrity Validator)
- **Status**: Completed
- **Summary**: Implemented `DownloadLogic` binding download services, authentication, model size validation, and screen navigation.
- **Completed Work**: Created `lib/download_page/logic/download_logic.dart` (66 lines). Validates installed model presence and integrity (>100MB threshold), coordinates OAuth login with token caching, and manages transition to the main chat route upon download completion. Pushed to GitHub with Entire sync.
- **Planned Work**: Implement download UI widgets and views.
- **Tests Run**: Model installation heuristic and navigation guards verification.
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
  - Implement modular clean architecture in `lib/` (services, state, screens, widgets).
  - Leverage Entire code graph for agent context and navigation.

## 7. Submission
- **neatlogs**: Connected & Verified (Trace ID: `1e212922bc2a5ea35da9978c79c05228`)
- **Entire**: Pending
- **cfo.ai**: N/A

