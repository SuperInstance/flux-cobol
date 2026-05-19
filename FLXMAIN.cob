      *> ====================================================================
      *> FLXMAIN.cob — Full pipeline: FLXCHECK + FLXFRACT + FLXSEDIMNT
      *> Demonstrates the complete constraint system with adversarial tests.
      *> ====================================================================

       IDENTIFICATION DIVISION.
       PROGRAM-ID. FLXMAIN.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "copybooks/FLXCONST.cpy".
       COPY "copybooks/FLXRESULT.cpy".
       COPY "copybooks/FLXSEDIMNT.cpy".

      *    Dependency matrix for fracture
       01 DEPENDENCY-MATRIX.
          05 DEP-ROW OCCURS 8 TIMES.
             10 DEP-COL          PIC 9     VALUE 0
                OCCURS 8 TIMES.

       01 CONSTRAINT-BLOCK        PIC 9(4) COMP
          OCCURS 8 TIMES VALUE 0.
       01 BLOCK-COUNT             PIC 9(4) COMP VALUE 0.

      *    BFS work area (minimal)
       01 VISITED                 PIC 9     VALUE 0
          OCCURS 8 TIMES.
       01 BFS-QUEUE.
          05 BFS-Q               PIC 9(4) COMP VALUE 0
             OCCURS 8 TIMES.
       01 BFS-HEAD                PIC 9(4) COMP VALUE 0.
       01 BFS-TAIL                PIC 9(4) COMP VALUE 0.

      *    Input / work
       01 INPUT-RECORD.
          05 SENSOR-VALUE OCCURS 8 TIMES
             PIC S9(4) COMP VALUE 0.

       01 IDX                     PIC 9(4) COMP.
       01 S-IDX                   PIC 9(4) COMP.
       01 CURRENT                 PIC 9(4) COMP.
       01 NEIGHBOR                PIC 9(4) COMP.
       01 DIM-IDX                 PIC 9(4) COMP.
       01 WORK-VAL                PIC S9(4) COMP.
       01 WORK-LO                 PIC S9(4) COMP.
       01 WORK-HI                 PIC S9(4) COMP.
       01 BIT-VAL                 PIC 9(4) COMP.
       01 TEST-COUNT              PIC 9(4) COMP VALUE 0.
       01 PASS-COUNT              PIC 9(4) COMP VALUE 0.
       01 FAIL-COUNT              PIC 9(4) COMP VALUE 0.

       LINKAGE SECTION.

       PROCEDURE DIVISION.
       MAIN-SECTION.
           DISPLAY "============================================"
           DISPLAY " FLXMAIN — Full Pipeline Integration Test"
           DISPLAY " Constraint Theory Ecosystem — COBOL Port"
           DISPLAY "============================================"
           DISPLAY " "

           PERFORM INIT-CONSTRAINTS
           PERFORM INIT-DEPENDENCY
           PERFORM INIT-SEDIMENT

           DISPLAY "Phase 1: Basic bounds checking"
           DISPLAY "--------------------------------"
           PERFORM TEST-BASIC-CHECK

           DISPLAY " "
           DISPLAY "Phase 2: Fracture into independent blocks"
           DISPLAY "------------------------------------------"
           PERFORM TEST-FRACTURE

           DISPLAY " "
           DISPLAY "Phase 3: Sediment layer corrections"
           DISPLAY "------------------------------------"
           PERFORM TEST-SEDIMENT

           DISPLAY " "
           DISPLAY "Phase 4: Adversarial inputs"
           DISPLAY "----------------------------"
           PERFORM TEST-ADVERSARIAL

           DISPLAY " "
           DISPLAY "============================================"
           DISPLAY " RESULTS: " PASS-COUNT " passed, "
               FAIL-COUNT " failed out of "
               TEST-COUNT " tests"
           DISPLAY "============================================"

           STOP RUN.

      *> ------------------------------------------------------------------
      *> INIT-CONSTRAINTS: 6 sensor constraints
      *> ------------------------------------------------------------------
       INIT-CONSTRAINTS SECTION.
           MOVE 6 TO CONSTRAINT-COUNT

           MOVE -40 TO C-LO(1)  MOVE 85  TO C-HI(1)
           MOVE 1 TO C-SEVERITY(1)
           MOVE "temperature" TO C-NAME(1)

           MOVE 800 TO C-LO(2)  MOVE 1200 TO C-HI(2)
           MOVE 2 TO C-SEVERITY(2)
           MOVE "pressure" TO C-NAME(2)

           MOVE 0 TO C-LO(3)    MOVE 50 TO C-HI(3)
           MOVE 1 TO C-SEVERITY(3)
           MOVE "voltage" TO C-NAME(3)

           MOVE -20 TO C-LO(4)  MOVE 60 TO C-HI(4)
           MOVE 1 TO C-SEVERITY(4)
           MOVE "humidity" TO C-NAME(4)

           MOVE 0 TO C-LO(5)    MOVE 5000 TO C-HI(5)
           MOVE 3 TO C-SEVERITY(5)
           MOVE "rpm" TO C-NAME(5)

           MOVE -10 TO C-LO(6)  MOVE 10 TO C-HI(6)
           MOVE 2 TO C-SEVERITY(6)
           MOVE "drift" TO C-NAME(6)
           .

      *> ------------------------------------------------------------------
      *> INIT-DEPENDENCY: Which sensors share physical dimensions
      *> Rows 1-3 = thermal group (connected)
      *> Rows 4-6 = mechanical group (connected)
      *> Two independent blocks
      *> ------------------------------------------------------------------
       INIT-DEPENDENCY SECTION.
      *    Thermal group: temp, pressure, voltage share thermal dims
           MOVE 1 TO DEP-COL(1,1)  MOVE 1 TO DEP-COL(1,2)
           MOVE 1 TO DEP-COL(2,1)  MOVE 1 TO DEP-COL(2,3)
           MOVE 1 TO DEP-COL(3,2)  MOVE 1 TO DEP-COL(3,3)
      *    Mechanical group: humidity, rpm, drift share mechanical dims
           MOVE 1 TO DEP-COL(4,4)  MOVE 1 TO DEP-COL(4,5)
           MOVE 1 TO DEP-COL(5,4)  MOVE 1 TO DEP-COL(5,6)
           MOVE 1 TO DEP-COL(6,5)  MOVE 1 TO DEP-COL(6,6)
           .

      *> ------------------------------------------------------------------
      *> INIT-SEDIMENT: Edge-case corrections from field data
      *> ------------------------------------------------------------------
       INIT-SEDIMENT SECTION.
           MOVE 2 TO SEDIMENT-COUNT

      *    Layer 1: Extended temp range for desert deployment
           MOVE 1 TO S-CONSTRAINT-IDX(1)
           MOVE -40 TO S-OLD-LO(1)  MOVE 85 TO S-OLD-HI(1)
           MOVE -40 TO S-NEW-LO(1)  MOVE 110 TO S-NEW-HI(1)
           MOVE " " TO S-OVERRIDE-PASS(1)
           MOVE "desert_deployment" TO S-REASON(1)
           MOVE 20260515 TO S-TIMESTAMP(1)

      *    Layer 2: Wider drift tolerance during calibration
           MOVE 6 TO S-CONSTRAINT-IDX(2)
           MOVE -10 TO S-OLD-LO(2)  MOVE 10 TO S-OLD-HI(2)
           MOVE -15 TO S-NEW-LO(2)  MOVE 15 TO S-NEW-HI(2)
           MOVE " " TO S-OVERRIDE-PASS(2)
           MOVE "calibration_mode" TO S-REASON(2)
           MOVE 20260518 TO S-TIMESTAMP(2)
           .

      *> ------------------------------------------------------------------
      *> TEST-BASIC-CHECK: Simple bounds checking
      *> ------------------------------------------------------------------
       TEST-BASIC-CHECK SECTION.
      *    All pass
           MOVE 25  TO SENSOR-VALUE(1)
           MOVE 900 TO SENSOR-VALUE(2)
           MOVE 12  TO SENSOR-VALUE(3)
           MOVE 30  TO SENSOR-VALUE(4)
           MOVE 3000 TO SENSOR-VALUE(5)
           MOVE 0   TO SENSOR-VALUE(6)
           PERFORM VALIDATE-ALL
           ADD 1 TO TEST-COUNT
           IF RESULT-PASSED = "Y"
               ADD 1 TO PASS-COUNT
               DISPLAY "  [PASS] All sensors in bounds"
           ELSE
               ADD 1 TO FAIL-COUNT
               DISPLAY "  [FAIL] All sensors should pass"
           END-IF

      *    Temperature violation
           MOVE 100 TO SENSOR-VALUE(1)
           PERFORM VALIDATE-ALL
           ADD 1 TO TEST-COUNT
           IF RESULT-PASSED = "N"
               ADD 1 TO PASS-COUNT
               DISPLAY "  [PASS] Temperature violation detected"
           ELSE
               ADD 1 TO FAIL-COUNT
               DISPLAY "  [FAIL] Temp=100 should violate (HI=85)"
           END-IF
           .

      *> ------------------------------------------------------------------
      *> TEST-FRACTURE: Block decomposition
      *> ------------------------------------------------------------------
       TEST-FRACTURE SECTION.
           PERFORM FRACTURE
           ADD 1 TO TEST-COUNT
           IF BLOCK-COUNT = 2
               ADD 1 TO PASS-COUNT
               DISPLAY "  [PASS] Correctly identified 2 blocks"
           ELSE
               ADD 1 TO FAIL-COUNT
               DISPLAY "  [FAIL] Expected 2 blocks, got "
                   BLOCK-COUNT
           END-IF
           .

      *> ------------------------------------------------------------------
      *> TEST-SEDIMENT: Sediment corrections
      *> ------------------------------------------------------------------
       TEST-SEDIMENT SECTION.
      *    Temp=95 fails without sediment, passes with it
           PERFORM APPLY-SEDIMENT-TO-CONSTRAINTS
           MOVE 95 TO SENSOR-VALUE(1)
           PERFORM VALIDATE-ALL
           ADD 1 TO TEST-COUNT
           IF RESULT-PASSED = "Y"
               ADD 1 TO PASS-COUNT
               DISPLAY "  [PASS] Temp=95 passes with sediment (HI=110)"
           ELSE
               ADD 1 TO FAIL-COUNT
               DISPLAY "  [FAIL] Sediment should extend temp to 110"
           END-IF

      *    Drift=12 fails without sediment, passes with it
           MOVE 12 TO SENSOR-VALUE(6)
           PERFORM VALIDATE-ALL
           ADD 1 TO TEST-COUNT
           IF RESULT-PASSED = "Y"
               ADD 1 TO PASS-COUNT
               DISPLAY "  [PASS] Drift=12 passes with sediment (HI=15)"
           ELSE
               ADD 1 TO FAIL-COUNT
               DISPLAY "  [FAIL] Sediment should extend drift to 15"
           END-IF
           .

      *> ------------------------------------------------------------------
      *> TEST-ADVERSARIAL: Boundary and extreme values
      *> ------------------------------------------------------------------
       TEST-ADVERSARIAL SECTION.
      *    INT8 saturation: value way below range
           MOVE -999 TO SENSOR-VALUE(1)
           PERFORM SATURATE-SENSORS
           ADD 1 TO TEST-COUNT
           IF SENSOR-VALUE(1) = -127
               ADD 1 TO PASS-COUNT
               DISPLAY "  [PASS] INT8 saturate -999 -> -127"
           ELSE
               ADD 1 TO FAIL-COUNT
               DISPLAY "  [FAIL] INT8 saturation"
           END-IF

      *    INT8 saturation: value way above range
           MOVE 999 TO SENSOR-VALUE(1)
           PERFORM SATURATE-SENSORS
           ADD 1 TO TEST-COUNT
           IF SENSOR-VALUE(1) = 127
               ADD 1 TO PASS-COUNT
               DISPLAY "  [PASS] INT8 saturate 999 -> 127"
           ELSE
               ADD 1 TO FAIL-COUNT
               DISPLAY "  [FAIL] INT8 saturation"
           END-IF

      *    Exact boundary: LO boundary should pass
           PERFORM INIT-CONSTRAINTS
           PERFORM APPLY-SEDIMENT-TO-CONSTRAINTS
           MOVE -40 TO SENSOR-VALUE(1)
           PERFORM VALIDATE-ALL
           ADD 1 TO TEST-COUNT
           IF RESULT-PASSED = "Y"
               ADD 1 TO PASS-COUNT
               DISPLAY "  [PASS] Exact LO boundary (-40) passes"
           ELSE
               ADD 1 TO FAIL-COUNT
               DISPLAY "  [FAIL] LO boundary should pass"
           END-IF

      *    One-off boundary: LO-1 should fail
           MOVE -41 TO SENSOR-VALUE(1)
           PERFORM VALIDATE-ALL
           ADD 1 TO TEST-COUNT
           IF RESULT-PASSED = "N"
               ADD 1 TO PASS-COUNT
               DISPLAY "  [PASS] LO-1 (-41) correctly fails"
           ELSE
               ADD 1 TO FAIL-COUNT
               DISPLAY "  [FAIL] LO-1 should fail"
           END-IF
           .

      *> ==================================================================
      *> Internal procedures (duplicated from FLXCHECK/FLXFRACT/FLXSEDIMNT
      *> for standalone compilation)
      *> ==================================================================

       VALIDATE-ALL SECTION.
           MOVE 0 TO RESULT-ERROR-MASK
           MOVE 0 TO RESULT-VIOLATED
           MOVE 0 TO RESULT-SEVERITY
           MOVE "Y" TO RESULT-PASSED
           PERFORM SATURATE-SENSORS
           PERFORM CHECK-ALL-CONSTRAINTS
           .

       SATURATE-SENSORS SECTION.
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

       CHECK-ALL-CONSTRAINTS SECTION.
           PERFORM VARYING IDX FROM 1 BY 1
               UNTIL IDX > CONSTRAINT-COUNT
               IF SENSOR-VALUE(IDX) < C-LO(IDX) OR
                  SENSOR-VALUE(IDX) > C-HI(IDX)
                   ADD 1 TO RESULT-VIOLATED
                   COMPUTE BIT-VAL = 2 ** (IDX - 1)
                   ADD BIT-VAL TO RESULT-ERROR-MASK
                   ADD C-SEVERITY(IDX) TO RESULT-SEVERITY
                   MOVE "N" TO RESULT-PASSED
               END-IF
           END-PERFORM
           .

       APPLY-SEDIMENT-TO-CONSTRAINTS SECTION.
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

       FRACTURE SECTION.
           MOVE 0 TO BLOCK-COUNT
           INITIALIZE CONSTRAINT-BLOCK
           INITIALIZE VISITED
           PERFORM VARYING IDX FROM 1 BY 1
               UNTIL IDX > CONSTRAINT-COUNT
               IF VISITED(IDX) = 0
                   ADD 1 TO BLOCK-COUNT
                   PERFORM BFS-EXPAND
               END-IF
           END-PERFORM
           .

       BFS-EXPAND SECTION.
           MOVE 1 TO BFS-HEAD
           MOVE 1 TO BFS-TAIL
           MOVE IDX TO BFS-Q(1)
           MOVE 1 TO VISITED(IDX)
           MOVE BLOCK-COUNT TO CONSTRAINT-BLOCK(IDX)
           PERFORM UNTIL BFS-HEAD > BFS-TAIL
               MOVE BFS-Q(BFS-HEAD) TO CURRENT
               ADD 1 TO BFS-HEAD
               PERFORM VARYING NEIGHBOR FROM 1 BY 1
                   UNTIL NEIGHBOR > CONSTRAINT-COUNT
                   IF VISITED(NEIGHBOR) = 0
                       PERFORM CHECK-ADJ
                       IF VISITED(NEIGHBOR) = 1
                           ADD 1 TO BFS-TAIL
                           MOVE NEIGHBOR
                               TO BFS-Q(BFS-TAIL)
                       END-IF
                   END-IF
               END-PERFORM
           END-PERFORM
           .

       CHECK-ADJ SECTION.
           PERFORM VARYING DIM-IDX FROM 1 BY 1
               UNTIL DIM-IDX > 8
               IF DEP-COL(CURRENT, DIM-IDX) = 1
                 AND DEP-COL(NEIGHBOR, DIM-IDX) = 1
                   MOVE 1 TO VISITED(NEIGHBOR)
                   MOVE BLOCK-COUNT
                       TO CONSTRAINT-BLOCK(NEIGHBOR)
                   MOVE 8 TO DIM-IDX
               END-IF
           END-PERFORM
           .
