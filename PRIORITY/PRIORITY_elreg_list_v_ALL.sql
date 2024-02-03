--SET SERVEROUTPUT on
DECLARE 
  nCNT NUMBER ;
  vSQL VARCHAR2(32700);
  i NUMBER := 0;
  
BEGIN
   dbms_output.ENABLE (200000);
   dbms_output.put_line ( '-----------------------------------------------------' ); 
   -- parameter
   FOR rec IN ( 
      select * from elreg_list_v 
   )
   LOOP
    i := i+1;  
    --dbms_output.put_line ( rpad (rec.id, 7) ||';' || rec.id_node || ';' || rec.name ||'; ; ;' );   
    FOR lst IN ( 
        select msc.ID,msc.ID_SOURCE,ms.ALIAS as AL,msc.ALIAS,msc.PRIORITY 
          from MEAS_SRC_CHANNEL msc, MEAS_SOURCE ms
         where msc.ID_OWNLST=rec.id  and ms.ID=msc.ID_SOURCE
         order by msc.PRIORITY asc
    )
    LOOP
        dbms_output.put_line ( rpad (rec.id, 7) ||';' || rec.id_node || ';' || rec.name ||'; '||lst.ALIAS ||';'||lst.PRIORITY ||';' );
        --dbms_output.put_line ( '' ||';' ||''||';'||''||';'||lst.ALIAS ||';'||lst.PRIORITY ||';' );
    END LOOP;
    --dbms_output.put_line ('' );

   END LOOP;

 
EXCEPTION WHEN OTHERS THEN 
  nCnt := SQLCODE;
  vSQL := SQLERRM;
    dbms_output.put_line ('ORA-'||nCnt);
    dbms_output.put_line (vSQL);
END;
/