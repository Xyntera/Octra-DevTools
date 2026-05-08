# Roadmap

## Phase 0: Repo Baseline

Status: started

- Flutter Android/iOS scaffold.
- Octra DevTools visual shell.
- Minimal AML editor.
- Minimal Octra RPC client.
- `octra_compileAml` compiler call.
- Architecture and research docs.

## Phase 1: Usable Mobile IDE

Goal: replicate the core Octra client DevTools loop.

- Project templates: blank, OCS-01 token, vault, escrow, multisig, PrivateML example-inspired template.
- Local project manager.
- File import and folder import.
- AML/OASM editor with syntax highlighting.
- Single-file AML compile.
- Multi-file AML compile.
- OASM compile.
- Output tabs: ABI, bytecode, disassembly, console, storage, diagnostics.
- Copy/export compiler output.

## Phase 2: Contract Interaction

Goal: compile, deploy, call, inspect.

- Compute/preview contract address.
- Dynamic fee fetcher using `octra_recommendedFee(op_type?)`.
- Deploy form with constructor JSON params.
- ABI-aware call form.
- Read-only `contract_call`.
- Signed state-changing contract-call transaction.
- Receipt viewer through `contract_receipt`.
- Contract metadata through `vm_contract`.
- ABI fetch through `octra_contractAbi`.
- Storage lookup through `octra_contractStorage`.

## Phase 3: Wallet-Signed Native Flow

Goal: no server, local signing only.

- Import Octra wallet.
- Watch-only address mode for read-only dev work.
- Secure key storage.
- Biometric/PIN confirmation before deploy/call.
- Nonce lookup and pending transaction tracking.
- Submit signed transaction with `octra_submit`.

## Phase 4: Source Verification

Goal: source-to-chain traceability.

- Verify deployed source using current project files.
- Save ABI after successful deployment.
- Fetch verified source.
- Compare local source hash with verified source where possible.

## Phase 5: FHE and Private Program Tools

Goal: make encrypted program testing practical.

- Encrypt integer to ciphertext.
- Decrypt ciphertext to integer.
- Fetch PVAC public key and encrypted cipher data where needed.
- Prepare encrypted call parameters.
- UI warnings that encrypted/private operations may require registered PVAC keys and higher fees.

## Phase 6: Groth16 BN254 Proof Lab

Goal: mobile proof-verifier tooling for Octra programs.

- Import snarkjs `verification_key.json`, `proof.json`, `public.json`.
- Validate BN254 curve/protocol and `nPublic`.
- Encode `OG16V1` verification key bundle.
- Encode `OG16P1` proof bundle.
- Encode public inputs.
- Call verifier contract method `verify` through `contract_call`.
- Save recent verifier contracts and caller addresses.

## Phase 7: Advanced Developer Experience

Goal: make it feel like a serious native IDE.

- Symbol outline for programs, structs, enums, events, state, and functions.
- Error-to-line navigation.
- Project-wide search.
- Contract templates marketplace/importer.
- Snippet library.
- Built-in Octra docs viewer.
- GitHub gist/import/export support.
- Optional local compile or LSP if Octra compiler/language server becomes available.
