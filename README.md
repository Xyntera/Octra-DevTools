# Octra DevTools

Native Flutter IDE for Octra developers on Android and iOS.

This repo is intentionally separate from Octra Wallet. The goal is a mobile-first developer workspace for AppliedML (`.aml`), Octra Assembly (`.oasm`), contract deployment, contract calls, source verification, FHE helpers, and Groth16 BN254 proof workflows.

## Current Baseline

- Flutter Android/iOS project scaffolded.
- Professional Octra DevTools shell UI added.
- Wallet import/login using seed phrase, 32-byte private key, or watch-only Octra address.
- Single-file AppliedML editor added.
- Multi-file project JSON compile surface added.
- Octra Assembly compile surface added.
- `octra_compileAml`, `octra_compileAmlMulti`, and `octra_compileAssembly` JSON-RPC calls wired.
- Dynamic fee fetcher wired through `octra_recommendedFee`.
- Deploy preview wired through `octra_computeContractAddress`.
- Program deploy transaction signing wired locally with Ed25519.
- Contract read-only call wired through `contract_call`.
- State-changing contract-call transaction signing wired locally with Ed25519.
- Contract metadata, ABI, and storage lookup wired.
- Source verification wired through `contract_verify`.
- Groth16 BN254 proof bundle encoder and verifier-call screen added.
- Real PVAC/FHE host bridge added from the Octra Wallet native C++ core.
- FHE key registration, encrypt, and decrypt are wired through Flutter FFI.
- Heavy native PVAC calls run off the Flutter UI isolate to avoid app freezes.
- Android CI builds and packages `liboctra_core.so`, `libcrypto.so`, and `libc++_shared.so`.
- Output inspector added for RPC results and signed payload debugging.
- Research docs added for official Octra IDE behavior, RPC methods, contract examples, and Groth16 BN254.

## Architecture Direction

The app should not run a server. It should be a native Flutter client that talks directly to Octra RPC and signs write operations locally.

Core layers:

- `Flutter UI`: project explorer, editor, output inspector, deploy/call screens, proof lab.
- `Workspace layer`: local projects, imported files, templates, recent projects.
- `Octra RPC layer`: JSON-RPC 2.0 calls to `/rpc`.
- `Wallet/signing layer`: reuse Octra Wallet key derivation/signing patterns for deploy and contract-call transactions.
- `Native PVAC layer`: C++ FFI bridge over the vendored webcli PVAC implementation; no local server.

## Feature Coverage

Implemented:

- Wallet login/import.
- Secure wallet persistence using platform secure storage.
- Biometric/PIN confirmation before signed deploy/call actions.
- Watch-only mode.
- File import for AML/OASM/JSON/TXT project files.
- Mobile project file tabs and local project persistence.
- Built-in webcli-matched templates: empty, OCS01 token, vault, escrow, multisig, AMM.
- AML compile.
- Multi-file AML compile.
- OASM compile.
- Syntax-highlighted AML preview.
- Recommended fees.
- Deploy address preview.
- Signed deploy transaction build and submit.
- Read-only contract call.
- Signed contract-call transaction build and submit.
- ABI method extraction and generated params form.
- Contract info, ABI, and storage lookup.
- Receipt lookup through contract receipt and raw transaction RPC calls.
- Source verification.
- Groth16 BN254 snarkjs JSON encoding and verifier call.
- Native PVAC health check.
- Native PVAC public-key registration payload generation.
- Native FHE encrypt/decrypt with `hfhe_v1|...` ciphertexts.
- Native host FHE smoke test in CI.
- Android native PVAC library build in CI.

Still requires native/product hardening:

- iOS static library packaging in the release workflow.
- Larger project-folder persistence beyond imported file sets.
- Full release-signing secrets in GitHub Actions.

## Native FHE

The app uses the same native path as the Flutter wallet direction:

- `native/vendor/webcli/pvac`: vendored PVAC C API and serialization code.
- `native/cpp/octra_core.cpp`: stable C ABI consumed by Dart FFI.
- `lib/octra_core_bridge.dart`: Flutter FFI loader for Android/iOS/Linux.
- `lib/main.dart`: runs PVAC operations in a background isolate.

Supported native operations in the DevTools UI:

- `register_pubkey`
- `fhe_encrypt`
- `fhe_decrypt`

The host smoke test validates register, encrypt, decrypt, view-key derivation, and stealth output scan:

```bash
native/cpp/build_host.sh
python3 native/cpp/smoke_test.py native/cpp/target/local/liboctra_core.so
```

## Template Coverage

The bundled templates mirror `webcli/static/templates`:

- `empty/main.aml`
- `token/main.aml`
- `token/interfaces/IOCS01.aml`
- `vault/main.aml`
- `escrow/main.aml`
- `multisig/main.aml`
- `amm/main.aml`

All six templates were tested against live Octra RPC using `octra_compileAmlMulti`.
Each returned bytecode and ABI with compiler version `1.0 Rehovot`. Dry deploy
address preview was also tested with `octra_computeContractAddress`.

## Release Signing

The workflow builds debug and release APK artifacts. `app-release.apk` now requires production signing. Add these GitHub repository secrets before running the release build:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`

Without those secrets, the release APK job fails. This prevents shipping a debug-signed file as a production release.

Generate a keystore locally:

```bash
keytool -genkeypair -v -keystore octra-devtools-release.jks -keyalg RSA -keysize 4096 -validity 10000 -alias octra-devtools
base64 -w0 octra-devtools-release.jks
```

## Run

```bash
flutter run
```

## Test

```bash
flutter test
```

## Research

- [Research summary](docs/research.md)
- [Architecture plan](docs/architecture.md)
- [Native FHE/PVAC integration](docs/native-fhe.md)
- [Roadmap](docs/roadmap.md)
- [Groth16 BN254 plan](docs/groth16-bn254.md)

## Source References

- Octra IDE docs: https://docs.octra.org/developer-docs/setting-up-ide
- AppliedML docs: https://docs.octra.org/developer-docs/introduction-to-applied
- Octra RPC docs: https://docs.octra.org/developer-docs/rpc-scheme
- Contract examples: https://github.com/octra-labs/contract-examples
- Groth16 BN254 toolkit: https://github.com/lambda0xE/octra-groth16-bn254
