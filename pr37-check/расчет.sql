SET SERVEROUTPUT ON 
DECLARE 
-- 
  t1 NUMBER;
  fl NUMBER;
  ds NUMBER;
  tstart NUMBER;
  tend NUMBER;
  tu NUMBER;
  str VARCHAR2(255);
BEGIN 
  dbms_output.ENABLE (100000);
  dbms_output.put_line ('  ');
  fl:=0;
  tstart:=16;
  tend:=37;
  tu:=tend;
  ds:=0;
FOR rec IN (
select dt, val  
from  rsduadmin.t 
where dt between tstart and tend 
order by dt desc
      ) LOOP
      BEGIN 
        IF rec.val=1 THEN 
          fl:=fl+1;
          t1:=rec.dt;
          ds:=ds+ (tu-t1);
          dbms_output.put_line('1='||ds||' ' ||tu||'  ' ||t1);
          tu:=t1;
        END IF;
        IF rec.val=0 THEN 
          tu:=rec.dt;
          fl:=0;
          dbms_output.put_line('0='||ds);
        END IF;
      EXCEPTION WHEN OTHERS THEN NULL;
      END;
   END LOOP;
    str := ' ds = ' || ds;
   dbms_output.put_line(' ' ||str);
END;
/
