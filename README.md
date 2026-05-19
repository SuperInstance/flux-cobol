# Flux COBOL — Constraint Engine with Fracture-Coalesce and Sediment

> "COBOL's fixed-format, record-based, division-structured organization FORCES
> a particular architecture. That forced architecture IS the optimal shape for
> the frozen hot path." — Forgemaster ⚒️

## What's Here

| File | Purpose |
|------|---------|
| `FLXCHECK.cob` | Core engine: INT8 bounds checking + sediment application |
| `FLXFRACT.cob` | Fracture-coalesce: BFS connected components, bitwise OR coalescence |
| `FLXSEDIMNT.cob` | Sediment layers: immutable edge-case corrections, monotonic coverage |
| `FLXMAIN.cob` | Full pipeline integration test with adversarial inputs |
| `copybooks/` | Shared COBOL copybooks (FLXCONST, FLXRESULT, FLXSEDIMNT) |
| `Makefile` | Build with GnuCOBOL |

## Build & Run

```bash
make all      # Compile all programs
make test     # Run FLXMAIN integration tests
make clean    # Remove compiled modules
```

Requires: [GnuCOBOL](https://gnucobol.sourceforge.io/) (`cobc`)

## Architecture

```
FLXMAIN (orchestrator)
  ├── FLXCHECK (core validation)
  │     ├── SATURATE-SENSORS — INT8 clamping
  │     ├── APPLY-SEDIMENT — layer corrections onto bounds
  │     ├── CHECK-CONSTRAINTS — exact bounds comparison
  │     └── COMPUTE-SEVERITY — sum violated severities
  ├── FLXFRACT (fracture-coalesce)
  │     ├── FRACTURE — BFS connected components
  │     ├── CHECK-ADJACENT — shared dimension detection
  │     └── COALESCE-RESULTS — bitwise OR of block masks
  └── FLXSEDIMNT (sediment layers)
        ├── ADD-LAYER — push correction to stack
        ├── APPLY-LAYERS — walk stack, mutate bounds
        └── COMPUTE-CORRECTNESS — coverage score
```

## What COBOL's Structure Teaches Us

### 1. The DIVISION Forces Separation of Concerns
COBOL's four divisions (IDENTIFICATION, DATA, ENVIRONMENT, PROCEDURE) enforce
a clean split that modern languages leave to convention. You literally cannot
mix data declarations with logic. The DATA DIVISION's hierarchical records
(01/05/10 levels) make the constraint table's structure self-documenting.

### 2. OCCURS Is a Schema Constraint
`OCCURS 8 TIMES` is a hard cardinality constraint — not a suggestion, not a
hint. The compiler enforces it. This is exactly what we want for safety-critical
constraint systems: the bounds are structural, not runtime checks.

### 3. Fixed-Format Forces Boundedness
Every record has a fixed PIC clause. `PIC S9(4) COMP` is exactly a 16-bit
signed integer — no undefined behavior, no overflow surprise. The constraint
system inherits this boundedness. INT8 saturation is structural, not a runtime
guard bolted on afterward.

### 4. The PROCEDURE DIVISION Is a Call Graph
Sections in the PROCEDURE DIVISION map directly to function calls. `PERFORM
CHECK-CONSTRAINTS` is the COBOL equivalent of a function call with zero
surprise — no closures, no captures, no hidden state. The call graph is
explicit and auditable.

### 5. Copybooks Are Dependency Injection
`COPY "copybooks/FLXCONST.cpy"` pulls in the shared constraint table definition.
This is compile-time dependency injection — the same record layout is guaranteed
across all programs. No runtime type mismatches possible.

### 6. The Hot Path Wants This Shape
Constraint checking is: bounded arrays → fixed-width comparisons → bit-vector
accumulation. This is exactly what COBOL's record model gives you for free.
No heap allocation, no dynamic dispatch, no garbage collection. Just records
in, flags out.

## Theorems Implemented

**Fracture-Coalesce Correctness:** If fracture correctly identifies connected
components of the constraint-dimension dependency graph, coalescence via
bitwise OR preserves zero false negatives. Each constraint violation is a
Boolean event. For independent blocks, event spaces are disjoint. Union = OR.

**Sediment Monotonicity:** A constraint system with N sediment layers has
strictly higher correctness than the same system with fewer layers. Each
layer adds coverage without removing prior corrections.

## Author

Forgemaster ⚒️ — Constraint Theory Ecosystem, 2026-05-19
