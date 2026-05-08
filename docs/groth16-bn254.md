# Groth16 BN254 Mobile Plan

## What The Existing Toolkit Does

Source: https://github.com/lambda0xE/octra-groth16-bn254

The current toolkit is an Elixir implementation that loads Circom/snarkjs output and verifies it through an Octra verifier contract.

Inputs:

- `verification_key.json`
- `proof.json`
- `public.json`

Encoding:

- Verification key starts with ASCII magic `OG16V1`.
- Proof starts with ASCII magic `OG16P1`.
- BN254 field elements are encoded as 32-byte big-endian values.
- G1 points are encoded as `x || y`.
- G2 points are encoded as `x.c0 || x.c1 || y.c0 || y.c1`.
- Public inputs are encoded as scalar field elements using BN254 scalar modulus.

RPC:

- Calls `contract_call`.
- Contract method is `verify`.
- Params are `[proof_b64, inputs_b64]`.
- Reference contract from the toolkit: `oct3rzJZucw9BsS7LRWBNoKRoaBsXAhhSK4LmfRvg45ppSs`.

Constraints:

- BN254 only.
- `nPublic` must be `0..1024`.
- Verification key `IC` length must equal `nPublic + 1`.
- Public input count must equal `nPublic`.

## Flutter Implementation

First version should be pure Dart:

- Use `dart:convert` for JSON/base64.
- Use `BigInt.parse` for decimal field values.
- Validate modulus ranges before encoding.
- Use `Uint8List` builders for byte output.
- Use Octra RPC client to call verifier contract.

Rust/FFI is not required for this first proof-lab feature because no proof generation is happening on-device.

## Later Native Extensions

Use Rust/FFI only if adding:

- Local proof generation.
- Faster proof normalization for large input sets.
- Shared proof codecs with a Rust CLI.
- Native cryptographic pre-checks beyond byte encoding.

## UI Flow

1. Select circuit folder or three JSON files.
2. Parse and validate files.
3. Show `nPublic`, proof size, verification key size, and input count.
4. Let the user set verifier contract and caller address.
5. Run read-only verification through `contract_call`.
6. Show boolean result and returned storage data.
