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
- FHE tool product surface added with explicit native PVAC FFI requirement.
- Output inspector added for RPC results and signed payload debugging.
- Research docs added for official Octra IDE behavior, RPC methods, contract examples, and Groth16 BN254.

## Architecture Direction

The app should not run a server. It should be a native Flutter client that talks directly to Octra RPC and signs write operations locally.

Core layers:

- `Flutter UI`: project explorer, editor, output inspector, deploy/call screens, proof lab.
- `Workspace layer`: local projects, imported files, templates, recent projects.
- `Octra RPC layer`: JSON-RPC 2.0 calls to `/rpc`.
- `Wallet/signing layer`: reuse Octra Wallet key derivation/signing patterns for deploy and contract-call transactions.
- `Native helpers`: optional Rust/FFI for heavy proof/FHE utilities if Dart implementation is not enough.

## Feature Coverage

Implemented:

- Wallet login/import.
- Watch-only mode.
- AML compile.
- Multi-file AML compile.
- OASM compile.
- Recommended fees.
- Deploy address preview.
- Signed deploy transaction build and submit.
- Read-only contract call.
- Signed contract-call transaction build and submit.
- Contract info, ABI, and storage lookup.
- Source verification.
- Groth16 BN254 snarkjs JSON encoding and verifier call.

Still requires native/product hardening:

- Secure persistent key storage.
- Biometric confirmation.
- Native PVAC FHE encrypt/decrypt through Flutter FFI.
- File/folder picker project manager.
- ABI-driven forms and syntax highlighting.
- Release signing configuration.

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
- [Roadmap](docs/roadmap.md)
- [Groth16 BN254 plan](docs/groth16-bn254.md)

## Source References

- Octra IDE docs: https://docs.octra.org/developer-docs/setting-up-ide
- AppliedML docs: https://docs.octra.org/developer-docs/introduction-to-applied
- Octra RPC docs: https://docs.octra.org/developer-docs/rpc-scheme
- Contract examples: https://github.com/octra-labs/contract-examples
- Groth16 BN254 toolkit: https://github.com/lambda0xE/octra-groth16-bn254
