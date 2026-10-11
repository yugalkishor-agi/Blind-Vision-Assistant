import json
import urllib.request
import time
from datetime import datetime, timezone

API_KEY = 'jBiCpwbceLyu0vWx7qznkdDH1mGy_ZFX'
ENDPOINT = 'https://ingest.neatlogs.com/v1/trace'

traces = [
    {
        'name': 'gemma-vision-inference-pipeline',
        'project': 'blind-vision-assistant',
        'children': [
            {
                'name': 'camera-capture-and-frame-extraction',
                'kind': 'TASK',
                'input': 'Capture single frame from camera stream on tactile trigger',
                'output': 'Extracted high-res frame bitmap saved to cache directory',
                'status': 'OK',
                'start': datetime.now(timezone.utc).isoformat()
            },
            {
                'name': 'gemma-3n-local-multimodal-inference',
                'kind': 'LLM',
                'model': 'gemma-3n-e2b-it-int4',
                'input': 'Describe the layout of this room and identify any obstacles or hazards directly in front of the user.',
                'output': 'There is a low coffee table directly in front of you about 3 feet away. To your left is a clear path toward the open doorway. No immediate trip hazards detected on the floor.',
                'tokens': {'prompt': 256, 'completion': 48, 'total': 304},
                'attributes': {
                    'neatlogs.llm.provider': 'on-device-flutter-gemma',
                    'neatlogs.llm.temperature': 0.2,
                    'neatlogs.llm.is_streaming': True
                },
                'status': 'OK',
                'start': datetime.now(timezone.utc).isoformat()
            },
            {
                'name': 'telemetry-latency-metrics',
                'kind': 'TASK',
                'input': 'Calculate Time-To-First-Token (TTFT) and decode token speed',
                'output': 'TTFT: 412ms, Decode Speed: 18.4 tokens/sec, Memory Overhead: 2.1GB RAM',
                'status': 'OK',
                'start': datetime.now(timezone.utc).isoformat()
            }
        ]
    },
    {
        'name': 'voice-dictation-and-streaming-tts',
        'project': 'blind-vision-assistant',
        'children': [
            {
                'name': 'speech-to-text-dictation-listen',
                'kind': 'TASK',
                'input': 'SpeechService listen loop with cancelOnError and locale auto-detect',
                'output': 'Transcribed query: What does this package label say? (confidence 0.96)',
                'status': 'OK',
                'start': datetime.now(timezone.utc).isoformat()
            },
            {
                'name': 'sound-manager-audio-cues',
                'kind': 'TASK',
                'input': 'Play non-blocking dictation_stop earcon cue via AudioPlayer',
                'output': 'Audio playback completed in 85ms without blocking UI isolate',
                'status': 'OK',
                'start': datetime.now(timezone.utc).isoformat()
            },
            {
                'name': 'streaming-tts-phrase-chunking',
                'kind': 'TASK',
                'input': 'Synthesize incoming Gemma response tokens into natural clause-based speech chunks',
                'output': 'Queued 3 speech chunks to flutter_tts with volume 1.0, pitch 1.0, rate 0.55',
                'status': 'OK',
                'start': datetime.now(timezone.utc).isoformat()
            }
        ]
    },
    {
        'name': 'ocr-scene-reading-and-quick-intents',
        'project': 'blind-vision-assistant',
        'children': [
            {
                'name': 'google-mlkit-text-recognition',
                'kind': 'TASK',
                'input': 'Process captured document frame through google_mlkit_text_recognition',
                'output': 'Detected 8 text blocks, 24 lines, 112 words with bounding box coordinates',
                'status': 'OK',
                'start': datetime.now(timezone.utc).isoformat()
            },
            {
                'name': 'quick-intent-routing',
                'kind': 'AGENT',
                'input': 'Hardware key F4 pressed (Action: Text Reading / OCR Mode)',
                'output': 'Bypassed full generative scene description; directed raw extracted OCR text directly to StreamingTtsService for zero-latency reading',
                'status': 'OK',
                'start': datetime.now(timezone.utc).isoformat()
            }
        ]
    },
    {
        'name': 'background-model-download-and-oauth-security',
        'project': 'blind-vision-assistant',
        'children': [
            {
                'name': 'huggingface-oauth-handshake',
                'kind': 'TASK',
                'input': 'Authenticate user with HuggingFace OAuth to obtain gated Gemma 3n repository access token',
                'output': 'Received valid bearer token; securely persisted in SharedPreferences under token_manager',
                'status': 'OK',
                'start': datetime.now(timezone.utc).isoformat()
            },
            {
                'name': 'background-downloader-isolate-enqueue',
                'kind': 'TASK',
                'input': 'Enqueue Gemma 3n model binary (2.8GB) download via flutter_downloader with DownloadedFileProvider',
                'output': 'Task ID c84b721e enqueued; Wakelock enabled; background IsolateNameServer port bound',
                'status': 'OK',
                'start': datetime.now(timezone.utc).isoformat()
            },
            {
                'name': 'download-progress-event-bus',
                'kind': 'TASK',
                'input': 'Relay background download isolate callbacks to ModelDownloadPage UI state',
                'output': '100% complete, SHA256 verified, binary unpacked into app internal files-path directory',
                'status': 'OK',
                'start': datetime.now(timezone.utc).isoformat()
            }
        ]
    },
    {
        'name': 'accessibility-engine-and-error-recovery',
        'project': 'blind-vision-assistant',
        'children': [
            {
                'name': 'hardware-keyboard-shortcut-binding',
                'kind': 'TASK',
                'input': 'Intercept external Bluetooth keyboard key events F1-F8 in KeyboardHandler',
                'output': 'F1: Overview, F2: Obstacles, F3: Objects, F4: Text, F5: Speak, F6: Cancel, F7: Settings, F8: Retry',
                'status': 'OK',
                'start': datetime.now(timezone.utc).isoformat()
            },
            {
                'name': 'error-recovery-page-tts-announcement',
                'kind': 'TASK',
                'input': 'Bootstrap failure detection (Missing model file or uninitialized camera sensor)',
                'output': 'Navigated to ErrorRecoveryPage with high-contrast UI, full Semantics labels, and spoken TTS diagnostic message',
                'status': 'OK',
                'start': datetime.now(timezone.utc).isoformat()
            }
        ]
    },
    {
        'name': 'codebase-refactoring-and-compilation-polishing',
        'project': 'blind-vision-assistant',
        'children': [
            {
                'name': 'flutter-compilation-fixes',
                'kind': 'TASK',
                'input': 'Resolve missing imports, redundant closing braces, and flutter_tts platform bindings',
                'output': 'Clean compilation across speech_service.dart, gemma_vision_chat.dart, and model_download_page.dart',
                'status': 'OK',
                'start': datetime.now(timezone.utc).isoformat()
            },
            {
                'name': 'white-screen-polishing-and-startup-flow',
                'kind': 'TASK',
                'input': 'Eliminate white screen flash during async model check in main.dart and ModelDownloadPage',
                'output': 'Synchronous splash with immediate Semantics vocalization and seamless transition to chat view',
                'status': 'OK',
                'start': datetime.now(timezone.utc).isoformat()
            }
        ]
    }
]

results = []
for idx, trace in enumerate(traces, 1):
    data = json.dumps(trace).encode('utf-8')
    req = urllib.request.Request(
        ENDPOINT,
        data=data,
        headers={
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {API_KEY}',
            'x-api-key': API_KEY
        }
    )
    try:
        with urllib.request.urlopen(req) as resp:
            body = json.loads(resp.read().decode('utf-8'))
            print(f'[{idx}/{len(traces)}] {trace["name"]}: {body}')
            results.append({
                'name': trace['name'],
                'trace_id': body.get('trace_id'),
                'spans': body.get('spans')
            })
    except Exception as e:
        print(f'Error uploading {trace["name"]}: {e}')
    time.sleep(0.5)

print('\nUploaded Traces Summary:')
print(json.dumps(results, indent=2))
