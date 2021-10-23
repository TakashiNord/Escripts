DROP TABLE RSDUADMIN.T CASCADE CONSTRAINTS;

CREATE TABLE RSDUADMIN.T
(
  DT   NUMBER,
  VAL  NUMBER
)

SET DEFINE OFF;
Insert into T
   (DT, VAL)
 Values
   (0, NULL);
Insert into T
   (DT, VAL)
 Values
   (1, 1);
Insert into T
   (DT, VAL)
 Values
   (2, 0);
Insert into T
   (DT, VAL)
 Values
   (9, 0);
Insert into T
   (DT, VAL)
 Values
   (11, 1);
Insert into T
   (DT, VAL)
 Values
   (15, 0);
Insert into T
   (DT, VAL)
 Values
   (16, NULL);
Insert into T
   (DT, VAL)
 Values
   (1, NULL);
Insert into T
   (DT, VAL)
 Values
   (17, 1);
Insert into T
   (DT, VAL)
 Values
   (18, 0);
Insert into T
   (DT, VAL)
 Values
   (19, 1);
Insert into T
   (DT, VAL)
 Values
   (20, 0);
Insert into T
   (DT, VAL)
 Values
   (22, 1);
Insert into T
   (DT, VAL)
 Values
   (23, 1);
Insert into T
   (DT, VAL)
 Values
   (25, 1);
Insert into T
   (DT, VAL)
 Values
   (26, 0);
Insert into T
   (DT, VAL)
 Values
   (27, 0);
Insert into T
   (DT, VAL)
 Values
   (28, 1);
Insert into T
   (DT, VAL)
 Values
   (30, 0);
COMMIT;
