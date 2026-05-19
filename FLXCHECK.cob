      *> ====================================================================
      *> FLXCHECK.cob — THE CORE: Exact INT8 bounds checking with sediment
      *> Constraint engine: validate sensor inputs against bounds,
      *> apply sediment corrections, compute severity.
      *> GnuCOBOL free-format compatible.
      *> ====================================================================

       IDENTIFICATION DIVISION.
       PROGRAM-ID. FLXCHECK.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *    Copy shared definitions
       COPY "copybooks/FLXCONST.cpy".
       COPY "copybooks/FLXRESULT.cpy".
       COPY "copybooks/FLXSEDIMNT.cpy".

      *    Input: 8 sensor values (INT8 saturated)
       01 INPUT-RECORD.
          05 SENSOR-VALUE OCCURS 8 TIMES
             PIC S9(4) COMP VALUE 0.

      *    Work variables
       01 IDX                      PIC 9(4) COMP.
       01 S-IDX                    PIC 9(4) COMP.
       01 WORK-VAL                 PIC S9(4) COMP.
       01 WORK-LO                  PIC S9(4) COMP.
       01 WORK-HI                  PIC S9(4) COMP.
       01 BIT-VAL                  PIC 9(4) COMP.
       01 SEV-SUM                  PIC 9(4) COMP VALUE 0.
       01 LAYER-APPLIED            PIC 9(4) COMP VALUE 0.

       LINKAGE SECTION.

       PROCEDURE DIVISION.
       MAIN-SECTION.
           DISPLAY "FLXCHECK — Flux Constraint Engine v1.0"
           DISPLAY "====================================="
           PERFORM SELF-TEST
           STOP RUN.

      *> ------------------------------------------------------------------
      *> SELF-TEST: adversarial and boundary inputs
      *> ------------------------------------------------------------------
       SELF-TEST.
           DISPLAY "Running self-test..."

      *    Setup 3 constraints: temp, pressure, voltage
           MOVE 1 TO CONSTRAINT-COUNT

           MOVE -40 TO C-LO(1)
           MOVE  85 TO C-HI(1)
           MOVE  1  TO C-SEVERITY(1)
           MOVE "temperature" TO C-NAME(1)

           ADD 1 TO CONSTRAINT-COUNT
           MOVE 800 TO C-LO(2)
           MOVE 1200 TO C-HI(2)
           MOVE 2 TO C-SEVERITY(2)
           MOVE "pressure" TO C-NAME(2)

           ADD 1 TO CONSTRAINT-COUNT
           MOVE 0 TO C-LO(3)
           MOVE 50 TO C-HI(3)
           MOVE 1 TO C-SEVERITY(3)
           MOVE "voltage" TO C-NAME(3)

      *    TEST 1: All values in bounds
           MOVE 25  TO SENSOR-VALUE(1)
           MOVE 900 TO SENSOR-VALUE(2)
           MOVE 12  TO SENSOR-VALUE(3)
           PERFORM VALIDATE-ALL
           IF RESULT-PASSED NOT = "Y"
               DISPLAY "  FAIL: Test 1 (all pass)"
           ELSE
               DISPLAY "  PASS: Test 1 (all in bounds)"
           END-IF

      *    TEST 2: Temperature violation
           MOVE 100 TO SENSOR-VALUE(1)
           PERFORM VALIDATE-ALL
           IF RESULT-PASSED = "Y"
               DISPLAY "  FAIL: Test 2 (temp violation missed)"
           ELSE
               DISPLAY "  PASS: Test 2 (temp caught)"
           END-IF

      *    TEST 3: Boundary — exactly at LO
           MOVE -40 TO SENSOR-VALUE(1)
           PERFORM VALIDATE-ALL
           IF RESULT-PASSED NOT = "Y"
               DISPLAY "  FAIL: Test 3 (boundary LO)"
           ELSE
               DISPLAY "  PASS: Test 3 (boundary LO pass)"
           END-IF

      *    TEST 4: INT8 saturation
           MOVE -200 TO SENSOR-VALUE(1)
           PERFORM SATURATE-SENSOR
           IF SENSOR-VALUE(1) NOT = -127
               DISPLAY "  FAIL: Test 4 (saturate negative)"
           ELSE
               DISPLAY "  PASS: Test 4 (INT8 saturate)"
           END-IF

      *    TEST 5: Sediment correction
           MOVE 1 TO SEDIMENT-COUNT
           MOVE 1 TO S-CONSTRAINT-IDX(1)
           MOVE -40 TO S-OLD-LO(1)
           MOVE  85 TO S-OLD-HI(1)
           MOVE -40 TO S-NEW-LO(1)
           MOVE 105 TO S-NEW-HI(1)
           MOVE " " TO S-OVERRIDE-PASS(1)
           MOVE "extended_temp_range" TO S-REASON(1)
           MOVE 20260519 TO S-TIMESTAMP(1)

           MOVE 95 TO SENSOR-VALUE(1)
           PERFORM VALIDATE-ALL
           IF RESULT-PASSED NOT = "Y"
               DISPLAY "  FAIL: Test 5 (sediment correction)"
           ELSE
               DISPLAY "  PASS: Test 5 (sediment extended bounds)"
           END-IF

           DISPLAY "Self-test complete."
           .

      *> ------------------------------------------------------------------
      *> VALIDATE-ALL: Full pipeline — saturate, apply sediment, check
      *> ------------------------------------------------------------------
       VALIDATE-ALL.
           MOVE 0 TO RESULT-ERROR-MASK
           MOVE 0 TO RESULT-VIOLATED
           MOVE 0 TO RESULT-SEVERITY
           MOVE "Y" TO RESULT-PASSED

           PERFORM SATURATE-SENSOR
           PERFORM APPLY-SEDIMENT
           PERFORM CHECK-CONSTRAINTS
           PERFORM COMPUTE-SEVERITY
           .

      *> ------------------------------------------------------------------
      *> SATURATE-SENSOR: Clamp all inputs to INT8 range
      *> ------------------------------------------------------------------
       SATURATE-SENSOR SECTION.
           PERFORM VARYING IDX FROM 1 BY 1
               UNTIL IDX > CONSTRAINT-COUNT
               IF SENSOR-VALUE(IDX) < INT8-MIN
                   MOVE INT8-MIN TO SENSOR-VALUE(IDX)
               END-IF
               IF SENSOR-VALUE(IDX) > INT8-MAX
                   MOVE INT8-MAX TO SENSOR-VALUE(IDX)
               END-IF
           END-PERFORM
           .

      *> ------------------------------------------------------------------
      *> APPLY-SEDIMENT: Layer corrections onto constraint bounds
      *> ------------------------------------------------------------------
       APPLY-SEDIMENT SECTION.
           MOVE 0 TO LAYER-APPLIED
           PERFORM VARYING S-IDX FROM 1 BY 1
               UNTIL S-IDX > SEDIMENT-COUNT
               MOVE S-CONSTRAINT-IDX(S-IDX) TO IDX
               IF IDX > 0 AND IDX <= CONSTRAINT-COUNT
      *>            Apply new LO if specified
                   IF S-NEW-LO(S-IDX) NOT = 0
                       MOVE S-NEW-LO(S-IDX) TO C-LO(IDX)
                   END-IF
      *>            Apply new HI if specified
                   IF S-NEW-HI(S-IDX) NOT = 0
                       MOVE S-NEW-HI(S-IDX) TO C-HI(IDX)
                   END-IF
                   ADD 1 TO LAYER-APPLIED
               END-IF
           END-PERFORM
           .

      *> ------------------------------------------------------------------
      *> CHECK-CONSTRAINTS: Compare each sensor value to its bounds
      *> ------------------------------------------------------------------
       CHECK-CONSTRAINTS SECTION.
           PERFORM VARYING IDX FROM 1 BY 1
               UNTIL IDX > CONSTRAINT-COUNT
               MOVE SENSOR-VALUE(IDX) TO WORK-VAL
               MOVE C-LO(IDX) TO WORK-LO
               MOVE C-HI(IDX) TO WORK-HI

               IF WORK-VAL < WORK-LO OR WORK-VAL > WORK-HI
                   ADD 1 TO RESULT-VIOLATED
                   COMPUTE BIT-VAL = 2 ** (IDX - 1)
                   ADD BIT-VAL TO RESULT-ERROR-MASK
                   MOVE "N" TO RESULT-PASSED
               END-IF
           END-PERFORM
           .

      *> ------------------------------------------------------------------
      *> COMPUTE-SEVERITY: Sum severities of violated constraints
      *> ------------------------------------------------------------------
       COMPUTE-SEVERITY SECTION.
           MOVE 0 TO SEV-SUM
           PERFORM VARYING IDX FROM 1 BY 1
               UNTIL IDX > CONSTRAINT-COUNT
               COMPUTE BIT-VAL = 2 ** (IDX - 1)
               COMPUTE RESULT-ERROR-MASK = RESULT-ERROR-MASK
      *    Test if this bit is set in error mask
               IF RESULT-ERROR-MASK >= BIT-VAL
                   ADD C-SEVERITY(IDX) TO SEV-SUM
               END-IF
           END-PERFORM
           MOVE SEV-SUM TO RESULT-SEVERITY
           .
