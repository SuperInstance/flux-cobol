# Flux COBOL — What Fixed-Format Records Teach About Constraint Architecture

COBOL (Common Business-Oriented Language, 1959) runs the world's financial infrastructure — banking, insurance, payroll. This repo implements the Flux constraint engine in GnuCOBOL.

## How to Read COBOL

COBOL looks verbose, but that's the point — it's self-documenting by design.

```cobol
      *> This is a comment (note: column 7+ for indicators/comments)
      *> Columns 1-6: line numbers, column 7: indicator, columns 8-72: code

       IDENTIFICATION DIVISION.         *> Every program starts here
       PROGRAM-ID. FLXCHECK.

       DATA DIVISION.                    *> All data declared here — no mixing
       WORKING-STORAGE SECTION.
       01  CONSTRAINT-TABLE.            *> 01 = top-level record
          05  CONSTRAINTS OCCURS 8.     *> 05 = field level, OCCURS = array
             10  C-LO     PIC S9(4) COMP.   *> PIC = picture clause (type)
             10  C-HI     PIC S9(4) COMP.   *> S9(4) = signed 4-digit
             10  C-SEV    PIC 9(2).          *> 9(2) = unsigned 2-digit
             10  C-VIOLATED PIC 9.           *> 0 or 1

       PROCEDURE DIVISION.              *> All logic here
           PERFORM CHECK-CONSTRAINTS    *> Like a function call
           STOP RUN.

       CHECK-CONSTRAINTS SECTION.       *> Section = named block of logic
           PERFORM VARYING I FROM 1 BY 1
               UNTIL I > 8              *> Counted loop
               IF SENSOR-VAL(I) < C-LO(I)
                   MOVE 1 TO C-VIOLATED(I)
               END-IF
           END-PERFORM.
```

Key ideas:
- **Four divisions** — IDENTIFICATION, DATA, ENVIRONMENT, PROCEDURE. You literally cannot mix data and logic.
- **PIC clauses** — `PIC S9(4) COMP` is a 16-bit signed integer. `PIC 9(2)` is unsigned. No undefined behavior.
- **OCCURS** — `OCCURS 8 TIMES` is a fixed-size array. The compiler enforces the cardinality.
- **PERFORM** — function call. `PERFORM X THRU Y` calls a range of paragraphs.
- **Sections/Paragraphs** — the PROCEDURE DIVISION is a call graph. Each section is a named procedure.
- **COPY** — `COPY "copybooks/FLXCONST.cpy"` pulls in shared definitions. This is compile-time dependency injection.

## How the Constraint Engine Maps to COBOL

| Constraint Engine Concept | COBOL Mechanism |
|---------------------------|-----------------|
| Constraint table (8 constraints) | `OCCURS 8` array with PIC-typed fields |
| Error mask (8 bits) | `PIC 9(8)` — one digit per constraint, 0 or 1 |
| INT8 saturation | `PIC S9(4) COMP` clamping — structural boundedness |
| Fracture (BFS blocks) | `PERFORM` sections with queue in WORKING-STORAGE |
| Coalescence (bitwise OR) | `ADD BIT-VAL TO RESULT-MASK` — arithmetic OR |
| Sediment layers | Stack of correction records, applied bottom-to-top |
| Pipeline stages | Sections in the PROCEDURE DIVISION |

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

## What COBOL Teaches Us

**The hot path wants to be fixed-format.** Constraint checking is bounded arrays in, fixed-width comparisons, bit-vector accumulation. COBOL gives you this for free — no heap allocation, no dynamic dispatch, no garbage collection. Just records in, flags out.

Three specific lessons:

1. **OCCURS is a schema constraint, not a runtime check.** `OCCURS 8 TIMES` means the compiler won't let you access index 9. The constraint engine's 8-constraint table isn't enforced by a guard — it's enforced by the type system. This is safety by construction, not safety by testing.

2. **The DATA DIVISION forces you to design data before writing logic.** You must declare every record, every field, every type before you write a single line of procedure. This is exactly the discipline constraint systems need: the schema IS the architecture.

3. **Copybooks are compile-time dependency injection.** `COPY "FLXCONST.cpy"` guarantees every program sees the same constraint table layout. No runtime type mismatches. No version skew. The shared state is structurally impossible to get wrong.

## Files

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

## Where to Go Next

- **flux-rpg** — RPG IV's indicator variables are literal error mask bits. The cycle model maps to constraint processing naturally.
- **flux-pli** — PL/I has native `BIT(8)` type. The error mask isn't simulated — it's a first-class data type.
- **flux-docs** — Full documentation: error masks, fracture-coalesce, sediment, thermodynamic analogy.

## Author

Forgemaster ⚒️ — Constraint Theory Ecosystem, 2026-05-19
