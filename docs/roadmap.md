# Roadmap

## Phase 0: Repo Baseline

Status: complete

- Flutter Android/iOS scaffold.
- Octra DevTools visual shell.
- Minimal AML editor.
- Minimal Octra RPC client.
- `octra_compileAml` compiler call.
- Architecture and research docs.

## Phase 1: Usable Mobile IDE

Status: partially implemented

Goal: replicate the core Octra client DevTools loop.

- Done: single-file AML compile.
- Done: multi-file AML compile through JSON project input.
- Done: OASM compile.
- Done: output inspector for compiler/RPC data.
- Done: project templates: blank, token, vault, escrow.
- Done: local project persistence.
- Done: file import for AML/OASM/JSON/TXT files.
- Done: syntax-highlighted AML preview.
- Open: OCS-01 token, multisig, PrivateML example-inspired templates.
- Open: folder-tree import/presentation.
- Open: copy/export compiler output.

## Phase 2: Contract Interaction

Status: partially implemented

Goal: compile, deploy, call, inspect.

- Done: compute/preview contract address.
- Done: dynamic fee fetcher using `octra_recommendedFee(op_type?)`.
- Done: deploy form with constructor JSON params.
- Done: read-only `contract_call`.
- Done: signed state-changing contract-call transaction.
- Done: contract metadata through `vm_contract`.
- Done: ABI fetch through `octra_contractAbi`.
- Done: storage lookup through `octra_contractStorage`.
- Done: ABI-aware call form generator.
- Done: receipt viewer through `contract_receipt`.

## Phase 3: Wallet-Signed Native Flow

Status: partially implemented

Goal: no server, local signing only.

- Done: import Octra wallet using seed phrase or private key.
- Done: watch-only address mode for read-only dev work.
- Done: nonce lookup with staging fallback.
- Done: submit signed transaction with `octra_submit`.
- Done: secure key storage.
- Done: biometric/PIN confirmation before deploy/call.
- Open: full pending transaction tracker.

## Phase 4: Source Verification

Status: partially implemented

Goal: source-to-chain traceability.

- Done: verify deployed source using current main AML source.
- Open: multi-file source verification from project manager.
- Open: save ABI after successful deployment.
- Open: fetch verified source.
- Open: compare local source hash with verified source where possible.

## Phase 5: FHE and Private Program Tools

Goal: make encrypted program testing practical.

- Encrypt integer to ciphertext.
- Decrypt ciphertext to integer.
- Fetch PVAC public key and encrypted cipher data where needed.
- Prepare encrypted call parameters.
- UI warnings that encrypted/private operations may require registered PVAC keys and higher fees.

## Phase 6: Groth16 BN254 Proof Lab

Status: partially implemented

Goal: mobile proof-verifier tooling for Octra programs.

- Done: paste/import snarkjs `verification_key.json`, `proof.json`, `public.json`.
- Done: validate BN254 curve/protocol and `nPublic`.
- Done: encode `OG16V1` verification key bundle.
- Done: encode `OG16P1` proof bundle.
- Done: encode public inputs.
- Done: call verifier contract method `verify` through `contract_call`.
- Open: file picker import.
- Open: save recent verifier contracts and caller addresses.

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
