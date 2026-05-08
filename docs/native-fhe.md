# Native FHE / PVAC Integration

## Goal

Run Octra privacy cryptography inside the mobile app, not through a local server.
Flutter owns the UI and wallet flow; the native C++ bridge owns the PVAC/FHE
operations.

## Source Layout

- `native/vendor/webcli/pvac`: vendored PVAC implementation and C API.
- `native/vendor/webcli/lib`: TweetNaCl, randombytes, stealth helpers, and JSON support.
- `native/cpp/octra_core.cpp`: stable C ABI exported to Flutter.
- `native/cpp/build_host.sh`: Linux host build for smoke tests.
- `native/cpp/build_android_openssl.sh`: Android OpenSSL build for AES-GCM support.
- `native/cpp/build_android.sh`: Android `liboctra_core.so` build.
- `native/cpp/smoke_test.py`: FHE and stealth primitive smoke test.
- `lib/octra_core_bridge.dart`: Dart FFI loader and JSON bridge.

## Flutter Operation Contract

Flutter sends JSON to `octra_core_execute_privacy_operation`.

Register PVAC public key:

```json
{
  "op": "register_pubkey",
  "private_key_b64": "<32 byte seed key>"
}
```

FHE encrypt:

```json
{
  "op": "fhe_encrypt",
  "private_key_b64": "<32 byte seed key>",
  "amount_raw": "777",
  "seed_b64": "<random 32 bytes>"
}
```

FHE decrypt:

```json
{
  "op": "fhe_decrypt",
  "private_key_b64": "<32 byte seed key>",
  "cipher": "hfhe_v1|..."
}
```

## Current Working Operations

- Native health check.
- PVAC public-key registration payload generation.
- FHE amount encryption.
- FHE ciphertext decryption.
- View-key derivation in native smoke tests.
- Empty stealth-output scanning in native smoke tests.

## UI Freeze Fix

PVAC operations can be CPU-heavy. The app runs native PVAC calls through
`Isolate.run`, creating the FFI bridge inside the worker isolate. This prevents
long encryption/proof work from blocking Flutter frame rendering.

## Android Packaging

GitHub Actions builds and packages:

- `android/app/src/main/jniLibs/arm64-v8a/liboctra_core.so`
- `android/app/src/main/jniLibs/arm64-v8a/libcrypto.so`
- `android/app/src/main/jniLibs/arm64-v8a/libc++_shared.so`
- matching `x86_64` libraries for emulator builds

The APK jobs download those libraries before `flutter build apk`.

## Validation

Local host validation:

```bash
native/cpp/build_host.sh
python3 native/cpp/smoke_test.py native/cpp/target/local/liboctra_core.so
flutter analyze
flutter test
```

CI validation:

- Flutter analyze/test.
- Native host PVAC build.
- Native host FHE smoke test.
- Android OpenSSL build.
- Android native core build.
- Android runtime dependency verification with `readelf`.
- Debug APK build.
- Release APK build.

## Open Work

- iOS static library packaging in CI.
- Full stealth send/claim UI in DevTools.
- Encrypted-balance transaction builders beyond raw FHE encrypt/decrypt tools.
