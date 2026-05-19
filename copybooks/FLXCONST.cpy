      * >>COPY FLXCONST.cpy<<
      * Constraint table definition — shared by all FLX programs
      * 8 constraints, each with LO/HI bounds, severity, and name

       01 CONSTRAINT-TABLE.
          05 CONSTRAINT-ENTRY OCCURS 8 TIMES.
             10 C-LO              PIC S9(4) COMP.
             10 C-HI              PIC S9(4) COMP.
             10 C-SEVERITY        PIC 9     VALUE 0.
             10 C-NAME            PIC X(16) VALUE SPACES.

       01 CONSTRAINT-COUNT        PIC 9(4) COMP VALUE 0.
