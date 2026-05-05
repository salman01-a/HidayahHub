# Voice Search (Surah and Doa)

This document explains the voice recognition feature for searching surah and doa.

## Summary

- Voice input uses the `speech_to_text` plugin.
- Speech results are placed into the search field and filtered locally.
- Locale is set to `id_ID` for Indonesian recognition.

## Files updated

- lib/screen/home/search_surah_view.dart
- lib/screen/home/doa_view.dart
- pubspec.yaml
- android/app/src/main/AndroidManifest.xml
- ios/Runner/Info.plist

## How it works

1. The view initializes `SpeechToText` when the screen loads.
2. Tap the mic icon to start listening.
3. Recognized words are written into the search field.
4. The existing filter logic runs with the new query.
5. Tap the mic icon again to stop.

## Permissions

Android:

- Add microphone permission in AndroidManifest:
  - android.permission.RECORD_AUDIO

iOS:

- Add these keys to Info.plist:
  - NSMicrophoneUsageDescription
  - NSSpeechRecognitionUsageDescription

## Notes

- If speech recognition is not available on the device, the mic button is disabled.
- Partial results are enabled to update the search as you speak.

## Optional tweaks

- Change the locale if you want another language (e.g., `en_US`).
- Use `ListenMode.confirmation` if you only want final results.
