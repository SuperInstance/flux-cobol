      * >>COPY FLXSEDIMNT.cpy<<
      * Sediment layer definition — accumulated correctness corrections

       01 SEDIMENT-TABLE.
          05 SEDIMENT-LAYER OCCURS 50 TIMES.
             10 S-CONSTRAINT-IDX  PIC 9(4) COMP VALUE 0.
             10 S-OLD-LO          PIC S9(4) COMP VALUE 0.
             10 S-OLD-HI          PIC S9(4) COMP VALUE 0.
             10 S-NEW-LO          PIC S9(4) COMP VALUE 0.
             10 S-NEW-HI          PIC S9(4) COMP VALUE 0.
             10 S-OVERRIDE-PASS   PIC X     VALUE " ".
             10 S-REASON          PIC X(32) VALUE SPACES.
             10 S-TIMESTAMP       PIC 9(8)  COMP VALUE 0.

       01 SEDIMENT-COUNT          PIC 9(4) COMP VALUE 0.
       01 SEDIMENT-MAX            PIC 9(4) COMP VALUE 50.
