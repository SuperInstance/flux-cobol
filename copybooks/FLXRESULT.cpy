      * >>COPY FLXRESULT.cpy<<
      * Result record — shared by all FLX programs

       01 RESULT-RECORD.
          05 RESULT-ERROR-MASK    PIC 9(4) COMP VALUE 0.
          05 RESULT-VIOLATED      PIC 9(4) COMP VALUE 0.
          05 RESULT-SEVERITY      PIC 9(4) COMP VALUE 0.
          05 RESULT-PASSED        PIC X     VALUE "Y".

       01 INT8-MIN                PIC S9(4) COMP VALUE -127.
       01 INT8-MAX                PIC S9(4) COMP VALUE  127.
