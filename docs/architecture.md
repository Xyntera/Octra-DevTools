# Architecture Plan

## Goal

Build Octra DevTools as a native Flutter Android/iOS app, not a server. The app should provide a mobile IDE for AppliedML and Octra Assembly while using Octra RPC for compiler, deployment, chain inspection, and source verification.

## High-Level Modules

## 1. App Shell

Responsibilities:

- Responsive Android/iOS UI.
- Left navigation on tablets/foldables, bottom navigation or compact header on phones.
- Project, editor, inspector, deploy/call, verify, proof lab, and settings areas.

Current status:

- Initial shell exists in `lib/main.dart`.

## 2. Workspace Manager

Responsibilities:

- Create project from template.
- Import files.
- Import folder-like project structure through Android document picker and iOS files integration.
- Store recent projects.
- Track active file, dirty state, and compile target.

Suggested local storage:

- `path_provider` for app documents directory.
- `file_picker` for project import.
- `shared_preferences` for recent project metadata.
- Optional encrypted storage for wallet-linked settings.

## 3. Editor

Responsibilities:

- AML and OASM text editing.
- Syntax highlighting.
- Search.
- Basic outline.
- Error line display when compiler diagnostics are available.

Suggested libraries:

- `flutter_code_editor` for code editing.
- `highlight` for language grammar support.
- Custom AML grammar if no existing grammar is available.

## 4. Octra RPC Client

Responsibilities:

- JSON-RPC 2.0 transport to `/rpc`.
- Request IDs.
- Structured error mapping.
- Timeout and retry policy for read-only calls.
- No retry for signed transaction submissions unless idempotency is proven.

Current status:

- Minimal `OctraRpcClient` exists and can call `octra_compileAml`.

Primary methods:

- `octra_compileAml`
- `octra_compileAmlMulti`
- `octra_compileAssembly`
- `octra_computeContractAddress`
- `contract_call`
- `contract_verify`
- `contract_source`
- `contract_receipt`
- `vm_contract`
- `octra_recommendedFee`

## 5. Compiler Service

Responsibilities:

- Compile current file.
- Compile multi-file project.
- Compile assembly.
- Normalize output into ABI, bytecode, disassembly, console, and storage panels.

First implementation:

- RPC compiler only.

Advanced implementation:

- Local compiler only if Octra compiler source becomes available and portable to mobile.

## 6. Deployment and Contract Call Service

Responsibilities:

- Preview deployment address.
- Build deploy transaction.
- Build contract call transaction.
- Estimate fee by operation type.
- Sign locally.
- Submit through `octra_submit`.
- Track pending tx and fetch receipts.

Dependency:

- Reuse signing and wallet-account logic from Octra Wallet.

## 7. FHE Tools

Responsibilities:

- Encrypt integer to ciphertext.
- Decrypt ciphertext to integer when wallet/private key is available.
- Prepare encrypted params for AML programs expecting FHE inputs.

Implementation choices:

- If existing PVAC native library can be reused cleanly, expose it through Flutter FFI.
- If the operation is supported by Octra RPC and does not expose secrets, call RPC.
- Heavy private operations should stay local and never require a server.

## 8. Groth16 BN254 Proof Lab

Responsibilities:

- Import `verification_key.json`, `proof.json`, and `public.json`.
- Validate `nPublic`, curve, protocol, field ranges, and proof shape.
- Encode bundles matching the Octra Groth16 toolkit format.
- Call verifier contract through `contract_call`.

First implementation:

- Dart port of the current Elixir encoder.

Advanced implementation:

- Rust/FFI helper only if Dart big integer and byte encoding performance becomes a problem.

## 9. Source Verification

Responsibilities:

- Use current project files to call `contract_verify`.
- Save ABI through `contract_saveAbi` where needed.
- Show verified source retrieved from `contract_source`.

## 10. Wallet Integration

Responsibilities:

- Import or connect Octra Wallet account.
- Sign deploy/call transactions locally.
- Biometric confirmation for write actions.
- Keep private key and mnemonic out of logs, compiler output, and crash reports.

Security baseline:

- Use platform keystore/keychain through Flutter secure storage.
- Require biometric or PIN before signing.
- Never send private keys to RPC.

## Advanced Ceiling

We can go very advanced on mobile:

- Full AML/OASM project manager.
- Syntax highlighting and symbol outline.
- Multi-file compile.
- ABI-aware method-call form generator.
- Contract storage browser.
- Receipt viewer and pending transaction tracker.
- Source verification workflow.
- Groth16 proof bundle import and verifier-call UI.
- FHE encrypt/decrypt helpers.
- Wallet-signed deploy/call flow.

Hard limits:

- Offline AML compiler depends on compiler availability. If the compiler is only exposed through Octra RPC, the app must compile through RPC.
- Local Circom proving on phones is possible but heavy and not a first version. Proof verification-call tooling is realistic first.
- A full LSP-grade IDE is possible later, but the first app should ship compiler-backed diagnostics and outline before deep language intelligence.
