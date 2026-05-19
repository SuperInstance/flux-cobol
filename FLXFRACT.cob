      *> ====================================================================
      *> FLXFRACT.cob — FRACTURE-COALESCE: Split constraints into blocks
      *> Identifies independent blocks via BFS on dependency matrix.
      *> Coalesces results via bitwise OR — provably zero false negatives.
      *> ====================================================================

       IDENTIFICATION DIVISION.
       PROGRAM-ID. FLXFRACT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "copybooks/FLXCONST.cpy".
       COPY "copybooks/FLXRESULT.cpy".

      *    Dependency matrix: which constraint touches which dimension
       01 DEPENDENCY-MATRIX.
          05 DEP-ROW OCCURS 8 TIMES.
             10 DEP-COL          PIC 9     VALUE 0
                OCCURS 8 TIMES.

      *    Block assignment: which constraint belongs to which block
       01 CONSTRAINT-BLOCK        PIC 9(4) COMP
          OCCURS 8 TIMES VALUE 0.

      *    Block results
       01 BLOCK-RESULT.
          05 BLOCK-ENTRY OCCURS 8 TIMES.
             10 BLK-ERROR-MASK   PIC 9(4) COMP VALUE 0.
             10 BLK-VIOLATED     PIC 9(4) COMP VALUE 0.
             10 BLK-PASSED       PIC X     VALUE "Y".

       01 BLOCK-COUNT             PIC 9(4) COMP VALUE 0.

      *    BFS work area
       01 BFS-QUEUE.
          05 BFS-Q               PIC 9(4) COMP VALUE 0
             OCCURS 8 TIMES.
       01 BFS-HEAD                PIC 9(4) COMP VALUE 0.
       01 BFS-TAIL                PIC 9(4) COMP VALUE 0.
       01 VISITED                 PIC 9     VALUE 0
          OCCURS 8 TIMES.
       01 CURRENT                 PIC 9(4) COMP.
       01 NEIGHBOR                PIC 9(4) COMP.
       01 DIM-IDX                 PIC 9(4) COMP.
       01 CON-IDX                 PIC 9(4) COMP.
       01 IDX                     PIC 9(4) COMP.
       01 WORK-VAL                PIC S9(4) COMP.
       01 WORK-LO                 PIC S9(4) COMP.
       01 WORK-HI                 PIC S9(4) COMP.
       01 BIT-VAL                 PIC 9(4) COMP.

      *    Sensor inputs (shared with FLXCHECK)
       01 INPUT-RECORD.
          05 SENSOR-VALUE OCCURS 8 TIMES
             PIC S9(4) COMP VALUE 0.

       LINKAGE SECTION.

       PROCEDURE DIVISION.
       MAIN-SECTION.
           DISPLAY "FLXFRACT — Fracture-Coalesce Engine v1.0"
           DISPLAY "========================================"
           PERFORM SELF-TEST
           STOP RUN.

      *> ------------------------------------------------------------------
      *> SELF-TEST
      *> ------------------------------------------------------------------
       SELF-TEST.
           DISPLAY "Running self-test..."

      *    Setup: 4 constraints over 4 dimensions
           MOVE 4 TO CONSTRAINT-COUNT

      *    C1: dims 1,2   C2: dims 3,4   C3: dims 1,3   C4: dims 2,4
      *    Dependency: C1-C3 (share dim1), C1-C4 (share dim2)
      *                C2-C3 (share dim3), C2-C4 (share dim4)
      *    All connected => 1 block

           MOVE 0 TO DEP-COL(1,1)  MOVE 1 TO DEP-COL(1,2)
           MOVE 0 TO DEP-COL(1,3)  MOVE 0 TO DEP-COL(1,4)
           MOVE 0 TO DEP-COL(2,1)  MOVE 0 TO DEP-COL(2,2)
           MOVE 1 TO DEP-COL(2,3)  MOVE 1 TO DEP-COL(2,4)
           MOVE 1 TO DEP-COL(3,1)  MOVE 0 TO DEP-COL(3,2)
           MOVE 1 TO DEP-COL(3,3)  MOVE 0 TO DEP-COL(3,4)
           MOVE 0 TO DEP-COL(4,1)  MOVE 1 TO DEP-COL(4,2)
           MOVE 0 TO DEP-COL(4,3)  MOVE 1 TO DEP-COL(4,4)

           PERFORM BUILD-DEPENDENCY
           PERFORM FRACTURE

           IF BLOCK-COUNT NOT = 1
               DISPLAY "  FAIL: Test 1 (should be 1 block)"
           ELSE
               DISPLAY "  PASS: Test 1 (fully connected = 1 block)"
           END-IF

      *    Now test independent: C1: dim1  C2: dim2  C3: dim3  C4: dim4
           INITIALIZE DEPENDENCY-MATRIX
           MOVE 1 TO DEP-COL(1,1)
           MOVE 1 TO DEP-COL(2,2)
           MOVE 1 TO DEP-COL(3,3)
           MOVE 1 TO DEP-COL(4,4)

           PERFORM FRACTURE

           IF BLOCK-COUNT NOT = 4
               DISPLAY "  FAIL: Test 2 (should be 4 blocks)"
           ELSE
               DISPLAY "  PASS: Test 2 (independent = 4 blocks)"
           END-IF

      *    Test coalesce
           MOVE 0 TO C-LO(1) MOVE 100 TO C-HI(1) MOVE 1 TO C-SEVERITY(1)
           MOVE 0 TO C-LO(2) MOVE 100 TO C-HI(2) MOVE 2 TO C-SEVERITY(2)
           MOVE 0 TO C-LO(3) MOVE 100 TO C-HI(3) MOVE 1 TO C-SEVERITY(3)
           MOVE 0 TO C-LO(4) MOVE 100 TO C-HI(4) MOVE 3 TO C-SEVERITY(4)

           MOVE 50  TO SENSOR-VALUE(1)
           MOVE 200 TO SENSOR-VALUE(2)
           MOVE 50  TO SENSOR-VALUE(3)
           MOVE -10 TO SENSOR-VALUE(4)

           PERFORM COALESCE-RESULTS

           IF RESULT-PASSED = "Y"
               DISPLAY "  FAIL: Test 3 (coalesce should catch violations)"
           ELSE
               DISPLAY "  PASS: Test 3 (coalesce caught "
                   RESULT-VIOLATED " violations)"
           END-IF

           DISPLAY "Self-test complete."
           .

      *> ------------------------------------------------------------------
      *> BUILD-DEPENDENCY: Compute which constraints share dimensions
      *> Two constraints are adjacent if any DEP-COL row has overlap
      *> ------------------------------------------------------------------
       BUILD-DEPENDENCY SECTION.
      *    Already populated in self-test or by caller.
      *    In production, this would load from config.
           .

      *> ------------------------------------------------------------------
      *> FRACTURE: BFS to find connected components (independent blocks)
      *> ------------------------------------------------------------------
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

      *> ------------------------------------------------------------------
      *> BFS-EXPAND: Expand one connected component from IDX
      *> Uses BFS queue to find all constraints reachable from IDX
      *> ------------------------------------------------------------------
       BFS-EXPAND SECTION.
           MOVE 1 TO BFS-HEAD
           MOVE 1 TO BFS-TAIL
           MOVE IDX TO BFS-Q(1)
           MOVE 1 TO VISITED(IDX)
           MOVE BLOCK-COUNT TO CONSTRAINT-BLOCK(IDX)

           PERFORM UNTIL BFS-HEAD > BFS-TAIL
               MOVE BFS-Q(BFS-HEAD) TO CURRENT
               ADD 1 TO BFS-HEAD

      *        Find all unvisited neighbors of CURRENT
               PERFORM VARYING NEIGHBOR FROM 1 BY 1
                   UNTIL NEIGHBOR > CONSTRAINT-COUNT
                   IF VISITED(NEIGHBOR) = 0
                       PERFORM CHECK-ADJACENT
                       IF VISITED(NEIGHBOR) = 1
                           ADD 1 TO BFS-TAIL
                           MOVE NEIGHBOR TO BFS-Q(BFS-TAIL)
                       END-IF
                   END-IF
               END-PERFORM
           END-PERFORM
           .

      *> ------------------------------------------------------------------
      *> CHECK-ADJACENT: Are CURRENT and NEIGHBOR connected?
      *> Connected if they share any dimension (DEP-COL overlap)
      *> ------------------------------------------------------------------
       CHECK-ADJACENT SECTION.
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

      *> ------------------------------------------------------------------
      *> COALESCE-RESULTS: Check each block independently, OR results
      *> THEOREM: Bitwise OR of independent block masks = exact result
      *> ------------------------------------------------------------------
       COALESCE-RESULTS SECTION.
           MOVE 0 TO RESULT-ERROR-MASK
           MOVE 0 TO RESULT-VIOLATED
           MOVE 0 TO RESULT-SEVERITY
           MOVE "Y" TO RESULT-PASSED

           PERFORM VARYING IDX FROM 1 BY 1
               UNTIL IDX > BLOCK-COUNT
               MOVE 0 TO BLK-ERROR-MASK(IDX)
               MOVE 0 TO BLK-VIOLATED(IDX)
               MOVE "Y" TO BLK-PASSED(IDX)
           END-PERFORM

      *    Check each constraint against its block
           PERFORM VARYING IDX FROM 1 BY 1
               UNTIL IDX > CONSTRAINT-COUNT
               MOVE CONSTRAINT-BLOCK(IDX) TO CON-IDX
               MOVE SENSOR-VALUE(IDX) TO WORK-VAL
               MOVE C-LO(IDX) TO WORK-LO
               MOVE C-HI(IDX) TO WORK-HI

               IF WORK-VAL < WORK-LO OR WORK-VAL > WORK-HI
                   ADD 1 TO BLK-VIOLATED(CON-IDX)
                   COMPUTE BIT-VAL = 2 ** (IDX - 1)
                   ADD BIT-VAL TO BLK-ERROR-MASK(CON-IDX)
                   MOVE "N" TO BLK-PASSED(CON-IDX)
               END-IF
           END-PERFORM

      *    Coalesce: OR all block masks together
           PERFORM VARYING IDX FROM 1 BY 1
               UNTIL IDX > BLOCK-COUNT
               ADD BLK-ERROR-MASK(IDX) TO RESULT-ERROR-MASK
               ADD BLK-VIOLATED(IDX) TO RESULT-VIOLATED
               IF BLK-PASSED(IDX) = "N"
                   MOVE "N" TO RESULT-PASSED
               END-IF
           END-PERFORM
           .
