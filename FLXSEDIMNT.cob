      *> ====================================================================
      *> FLXSEDIMNT.cob — SEDIMENT: Accumulated correctness layers
      *> Geological model: each layer is an immutable edge-case correction.
      *> New layers supersede older ones. Monotonic convergence to coverage.
      *> ====================================================================

       IDENTIFICATION DIVISION.
       PROGRAM-ID. FLXSEDIMNT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "copybooks/FLXCONST.cpy".
       COPY "copybooks/FLXRESULT.cpy".
       COPY "copybooks/FLXSEDIMNT.cpy".

       01 IDX                      PIC 9(4) COMP.
       01 S-IDX                    PIC 9(4) COMP.
       01 LAYER-IDX                PIC 9(4) COMP.
       01 CORRECTNESS              PIC 9V999 COMP VALUE 1.000.
       01 TOTAL-CORRECTIONS        PIC 9(4) COMP VALUE 0.
       01 ACTIVE-CORRECTIONS       PIC 9(4) COMP VALUE 0.
       01 WORK-VAL                 PIC S9(4) COMP.
       01 WORK-LO                  PIC S9(4) COMP.
       01 WORK-HI                  PIC S9(4) COMP.
       01 TEMP-PASSED              PIC X     VALUE "Y".
       01 BIT-VAL                  PIC 9(4) COMP.

       01 INPUT-RECORD.
          05 SENSOR-VALUE OCCURS 8 TIMES
             PIC S9(4) COMP VALUE 0.

       LINKAGE SECTION.

       PROCEDURE DIVISION.
       MAIN-SECTION.
           DISPLAY "FLXSEDIMNT — Sediment Layer Engine v1.0"
           DISPLAY "======================================="
           PERFORM SELF-TEST
           STOP RUN.

      *> ------------------------------------------------------------------
      *> SELF-TEST
      *> ------------------------------------------------------------------
       SELF-TEST.
           DISPLAY "Running self-test..."

      *    Setup 2 constraints
           MOVE 2 TO CONSTRAINT-COUNT
           MOVE 0 TO C-LO(1)   MOVE 100 TO C-HI(1)
           MOVE 1 TO C-SEVERITY(1)  MOVE "temp" TO C-NAME(1)
           MOVE 0 TO C-LO(2)   MOVE 50  TO C-HI(2)
           MOVE 2 TO C-SEVERITY(2)  MOVE "voltage" TO C-NAME(2)

      *    TEST 1: Add a sediment layer that extends bounds
           PERFORM ADD-TEST-LAYERS
           IF SEDIMENT-COUNT NOT = 3
               DISPLAY "  FAIL: Test 1 (layer count)"
           ELSE
               DISPLAY "  PASS: Test 1 (3 layers added)"
           END-IF

      *    TEST 2: Apply layers and check bounds
           PERFORM APPLY-LAYERS
           IF C-HI(1) NOT = 120
               DISPLAY "  FAIL: Test 2 (sediment HI)"
           ELSE
               DISPLAY "  PASS: Test 2 (bounds extended to 120)"
           END-IF

      *    TEST 3: Compute correctness score
           PERFORM COMPUTE-CORRECTNESS
           DISPLAY "  INFO: Correctness score = " CORRECTNESS

      *    TEST 4: Value that passes with sediment but not without
           MOVE 110 TO SENSOR-VALUE(1)
           PERFORM CHECK-WITH-SEDIMENT
           IF TEMP-PASSED NOT = "Y"
               DISPLAY "  FAIL: Test 4 (sediment should pass 110)"
           ELSE
               DISPLAY "  PASS: Test 4 (110 passes with sediment)"
           END-IF

      *    TEST 5: Value still out of extended bounds
           MOVE 130 TO SENSOR-VALUE(1)
           PERFORM CHECK-WITH-SEDIMENT
           IF TEMP-PASSED = "Y"
               DISPLAY "  FAIL: Test 5 (130 should still fail)"
           ELSE
               DISPLAY "  PASS: Test 5 (130 correctly fails)"
           END-IF

      *    TEST 6: Override-pass layer
           MOVE 130 TO SENSOR-VALUE(1)
      *    Add override layer
           ADD 1 TO SEDIMENT-COUNT
           MOVE 3 TO SEDIMENT-COUNT
           MOVE 1 TO S-CONSTRAINT-IDX(3)
           MOVE 0 TO S-NEW-LO(3)
           MOVE 0 TO S-NEW-HI(3)
           MOVE "Y" TO S-OVERRIDE-PASS(3)
           MOVE "safety_override" TO S-REASON(3)
           MOVE 20260519 TO S-TIMESTAMP(3)

           PERFORM CHECK-WITH-SEDIMENT
           IF TEMP-PASSED NOT = "Y"
               DISPLAY "  FAIL: Test 6 (override should force pass)"
           ELSE
               DISPLAY "  PASS: Test 6 (override-pass works)"
           END-IF

           DISPLAY "Self-test complete."
           .

      *> ------------------------------------------------------------------
      *> ADD-TEST-LAYERS: Populate sediment for testing
      *> ------------------------------------------------------------------
       ADD-TEST-LAYERS SECTION.
      *    Layer 1: Extend temp upper bound
           MOVE 1 TO SEDIMENT-COUNT
           MOVE 1 TO S-CONSTRAINT-IDX(1)
           MOVE 0 TO S-OLD-LO(1)
           MOVE 100 TO S-OLD-HI(1)
           MOVE 0 TO S-NEW-LO(1)
           MOVE 120 TO S-NEW-HI(1)
           MOVE " " TO S-OVERRIDE-PASS(1)
           MOVE "high_temp_field_data" TO S-REASON(1)
           MOVE 20260518 TO S-TIMESTAMP(1)

      *    Layer 2: Extend voltage upper bound
           ADD 1 TO SEDIMENT-COUNT
           MOVE 2 TO S-CONSTRAINT-IDX(2)
           MOVE 0 TO S-OLD-LO(2)
           MOVE 50 TO S-OLD-HI(2)
           MOVE 0 TO S-NEW-LO(2)
           MOVE 60 TO S-NEW-HI(2)
           MOVE " " TO S-OVERRIDE-PASS(2)
           MOVE "voltage_tolerance" TO S-REASON(2)
           MOVE 20260519 TO S-TIMESTAMP(2)
           .

      *> ------------------------------------------------------------------
      *> ADD-LAYER: Add a sediment layer to the stack
      *> ------------------------------------------------------------------
       ADD-LAYER SECTION.
      *    Expects caller to fill SEDIMENT-LAYER(SEDIMENT-COUNT+1)
      *    then CALL this to increment count with bounds check
           IF SEDIMENT-COUNT < SEDIMENT-MAX
               ADD 1 TO SEDIMENT-COUNT
               MOVE "Y" TO TEMP-PASSED
           ELSE
               DISPLAY "WARNING: Sediment stack full"
               MOVE "N" TO TEMP-PASSED
           END-IF
           .

      *> ------------------------------------------------------------------
      *> APPLY-LAYERS: Walk sediment stack, apply corrections to constraints
      *> Layers are applied in order — later layers supersede earlier ones
      *> ------------------------------------------------------------------
       APPLY-LAYERS SECTION.
           MOVE 0 TO ACTIVE-CORRECTIONS
           PERFORM VARYING S-IDX FROM 1 BY 1
               UNTIL S-IDX > SEDIMENT-COUNT
               MOVE S-CONSTRAINT-IDX(S-IDX) TO IDX
               IF IDX > 0 AND IDX <= CONSTRAINT-COUNT
      *>            Apply new LO if non-zero
                   IF S-NEW-LO(S-IDX) NOT = 0
                       MOVE S-NEW-LO(S-IDX) TO C-LO(IDX)
                   END-IF
      *>            Apply new HI if non-zero
                   IF S-NEW-HI(S-IDX) NOT = 0
                       MOVE S-NEW-HI(S-IDX) TO C-HI(IDX)
                   END-IF
                   ADD 1 TO ACTIVE-CORRECTIONS
               END-IF
           END-PERFORM
           DISPLAY "  Applied " ACTIVE-CORRECTIONS
               " sediment corrections"
           .

      *> ------------------------------------------------------------------
      *> COMPUTE-CORRECTNESS: Monotonic coverage score
      *> Each layer adds coverage. Score = active / (active + untested)
      *> ------------------------------------------------------------------
       COMPUTE-CORRECTNESS SECTION.
           MOVE 0 TO TOTAL-CORRECTIONS
           MOVE 0 TO ACTIVE-CORRECTIONS
           PERFORM VARYING S-IDX FROM 1 BY 1
               UNTIL S-IDX > SEDIMENT-COUNT
               ADD 1 TO TOTAL-CORRECTIONS
               IF S-CONSTRAINT-IDX(S-IDX) > 0
                   ADD 1 TO ACTIVE-CORRECTIONS
               END-IF
           END-PERFORM
      *    Correctness: fraction of layers that are active corrections
           IF TOTAL-CORRECTIONS > 0
               COMPUTE CORRECTNESS =
                   ACTIVE-CORRECTIONS / TOTAL-CORRECTIONS
           ELSE
               MOVE 1.000 TO CORRECTNESS
           END-IF
           .

      *> ------------------------------------------------------------------
      *> CHECK-WITH-SEDIMENT: Apply layers then check single constraint
      *> ------------------------------------------------------------------
       CHECK-WITH-SEDIMENT SECTION.
      *    Re-apply sediment to restore any corrections
           PERFORM APPLY-LAYERS-SILENT

           MOVE "Y" TO TEMP-PASSED
           MOVE SENSOR-VALUE(1) TO WORK-VAL
           MOVE C-LO(1) TO WORK-LO
           MOVE C-HI(1) TO WORK-HI

      *    Check override-pass layers (last one wins)
           PERFORM VARYING S-IDX FROM 1 BY 1
               UNTIL S-IDX > SEDIMENT-COUNT
               IF S-CONSTRAINT-IDX(S-IDX) = 1
                 AND S-OVERRIDE-PASS(S-IDX) = "Y"
                   MOVE "Y" TO TEMP-PASSED
               END-IF
           END-PERFORM

      *    If no override, check bounds normally
           IF TEMP-PASSED NOT = "Y"
               IF WORK-VAL < WORK-LO OR WORK-VAL > WORK-HI
                   MOVE "N" TO TEMP-PASSED
               END-IF
           END-IF
           .

      *> ------------------------------------------------------------------
      *> APPLY-LAYERS-SILENT: Same as APPLY-LAYERS but no DISPLAY
      *> ------------------------------------------------------------------
       APPLY-LAYERS-SILENT SECTION.
           PERFORM VARYING S-IDX FROM 1 BY 1
               UNTIL S-IDX > SEDIMENT-COUNT
               MOVE S-CONSTRAINT-IDX(S-IDX) TO IDX
               IF IDX > 0 AND IDX <= CONSTRAINT-COUNT
                   IF S-NEW-LO(S-IDX) NOT = 0
                       MOVE S-NEW-LO(S-IDX) TO C-LO(IDX)
                   END-IF
                   IF S-NEW-HI(S-IDX) NOT = 0
                       MOVE S-NEW-HI(S-IDX) TO C-HI(IDX)
                   END-IF
               END-IF
           END-PERFORM
           .
