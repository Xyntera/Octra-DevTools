# Octra DevTools

Native Flutter IDE for Octra developers on Android and iOS.

This repo is intentionally separate from Octra Wallet. The goal is a mobile-first developer workspace for AppliedML (`.aml`), Octra Assembly (`.oasm`), contract deployment, contract calls, source verification, FHE helpers, and Groth16 BN254 proof workflows.

## Current Baseline

- Flutter Android/iOS project scaffolded.
- Professional Octra DevTools shell UI added.
- Single-file AppliedML editor added.
- `octra_compileAml` JSON-RPC compiler call wired through Dart `HttpClient`.
- Output inspector layout added for ABI, assembly, compiler output, storage, and errors.
- Research docs added for official Octra IDE behavior, RPC methods, contract examples, and Groth16 BN254.

## Architecture Direction

The app should not run a server. It should be a native Flutter client that talks directly to Octra RPC and signs write operations locally.

Core layers:

- `Flutter UI`: project explorer, editor, output inspector, deploy/call screens, proof lab.
- `Workspace layer`: local projects, imported files, templates, recent projects.
- `Octra RPC layer`: JSON-RPC 2.0 calls to `/rpc`.
- `Wallet/signing layer`: reuse Octra Wallet key derivation/signing patterns for deploy and contract-call transactions.
- `Native helpers`: optional Rust/FFI for heavy proof/FHE utilities if Dart implementation is not enough.

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
