# Research Summary

Date: 2026-05-08

## Official Octra IDE

Source: https://docs.octra.org/developer-docs/setting-up-ide

The existing Octra client exposes a built-in `dev tools` IDE surface. It is not a separate desktop IDE. It lives inside the client and supports:

- Creating a project from templates such as blank, OCS-01 token, and vault.
- Importing single files or folder-based multi-file projects.
- Editing AppliedML (`.aml`) and Octra Assembly (`.oasm`).
- Compiling source.
- Inspecting ABI, assembly, console output, and storage-oriented output.
- Deploying programs with bytecode, constructor params, fee, and preview address.
- Calling methods and running read-only views.
- Using basic FHE tools for encrypting and decrypting integer ciphertexts.
- Looking up deployed program info and last receipts.
- Verifying source from the current project file set.

The mobile IDE should mirror this workflow in native Flutter.

## AppliedML

Source: https://docs.octra.org/developer-docs/introduction-to-applied

AppliedML is Octra's high-level program language. AML compiles to OCTB bytecode for the Octra VM and can expose ABI and disassembly. The design goal is readable source without hiding execution behavior.

Important concepts for tooling:

- AML supports program state, maps, lists, structs, enums, tuples, imports, and interfaces.
- State lowers into explicit string-addressed storage keys.
- Functions can be read-only views or state-changing entrypoints.
- Built-ins include caller, origin, self address, attached value, and epoch.
- Events, require checks, asserts, and revert behavior are first-class and should be surfaced in diagnostics.
- Multi-file project support matters because interfaces and imports are part of normal program structure.

## Octra RPC Surface

Source: https://docs.octra.org/developer-docs/rpc-scheme

Octra exposes JSON-RPC 2.0 over `POST /rpc`. Requests use positional arrays for params.

Developer-tooling methods we should build around:

- `octra_compileAml(source)`
- `octra_compileAmlMulti(files, main)`
- `octra_compileAssembly(source)`
- `octra_computeContractAddress(bytecode_b64, deployer, nonce?)`
- `vm_contract(address)`
- `octra_contractAbi(address)`
- `octra_contractStorage(address, key)`
- `contract_receipt(hash)`
- `contract_call(address, method, params?, caller?)`
- `contract_verify(address, source, files?)`
- `contract_saveAbi(address, abi)`
- `contract_source(address)`
- `octra_recommendedFee(op_type?)`

Wallet and encrypted-operation support can reuse:

- `octra_balance(address)`
- `octra_nonce(address)`
- `octra_submit(tx_json)`
- `octra_submitBatch(transactions)`
- `octra_registerPublicKey(address, public_key, signature)`
- `octra_registerPvacPubkey(address, pubkey_blob, aes_kat)`
- `octra_pvacPubkey(address)`
- `octra_encryptedCipher(address)`
- `octra_encryptedBalance(address, signature, pubkey)`
- `octra_privateTransfer(tx)`
- `octra_viewPubkey(address)`
- `octra_stealthOutputs(from_epoch?)`

## Contract Examples

Source: https://github.com/octra-labs/contract-examples

Local research commit: `b583d14 Create example_1.aml`

The example repository is MIT licensed and currently contains `example_1.aml`, a large `PrivateML` AppliedML program.

Useful IDE implications:

- The editor must handle real files larger than toy examples.
- The outline view should parse enums, structs, events, state fields, view functions, and state-changing functions.
- Templates should include ML-style contracts, governance, owner controls, maps, and encrypted/private fields.
- Diagnostics should show owner checks, fee checks, status checks, and event declarations clearly.
- Search and symbol navigation will be important once multi-file projects are added.

## Groth16 BN254 Toolkit

Source: https://github.com/lambda0xE/octra-groth16-bn254

Local research commit: `d5c9a7a octra groth16`

The toolkit is an Elixir project for using Circom Groth16 BN254 proofs with Octra.

Observed design:

- Reads `verification_key.json`, `proof.json`, and `public.json` from a circuit folder.
- Encodes a verification key bundle with magic header `OG16V1`.
- Encodes a proof bundle with magic header `OG16P1`.
- Encodes public inputs as 32-byte big-endian BN254 scalar field elements.
- Calls Octra RPC method `contract_call` against a verifier contract method named `verify`.
- Reference verifier contract: `oct3rzJZucw9BsS7LRWBNoKRoaBsXAhhSK4LmfRvg45ppSs`.
- Supports BN254 only.
- `nPublic` must be between `0` and `1024`.

For Flutter, we can port the encoder to Dart first. Rust/FFI is only needed if we later add local proving or heavier cryptographic checks.
