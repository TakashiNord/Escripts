
CREATE OR REPLACE PROCEDURE RSDUADMIN.RSDUARC_REFRESH_MVIEWS_IF 
As
tmpVar NUMBER;
/******************************************************************************

******************************************************************************/
 n1      number;
 n2      number;
BEGIN
   tmpVar := 0;
   n1:=0;
   n2:=0;
   select count(*) into n1 from MEAS_SNAPSHOT30_TUNE ;
   select count (*) into n2 from MEAS_SNAPSHOT30_TUNE@RSDU1.RSDU.IESK.IRKUTSKENERGO.RU ;
   IF n1 <> n2 THEN
     EXECUTE immediate 'RSDUADMIN.RSDUARC_REFRESH_MVIEWS' ;
   END IF;

   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END RSDUARC_REFRESH_MVIEWS_IF;
/

GRANT EXECUTE ON RSDUARC_REFRESH_MVIEWS_IF TO PUBLIC



