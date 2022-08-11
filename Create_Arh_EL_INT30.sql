set SERVEROUTPUT on 
/*

 --------

*/
DECLARE  
  cnt NUMBER; 
  cnt1 NUMBER;
  aaa NUMBER; 
  sss VARCHAR2(1000); 
  vTname VARCHAR2(30);
  nCnt number;
  default_id_ginfo number := 4;
  idginfo number ;
  idgtopt number ;
  err_code      VARCHAR2 (4000);
  err_msg       VARCHAR2 (4000);  

BEGIN  
  dbms_output.ENABLE (100000) ;
  
  idginfo := default_id_ginfo ;
  idgtopt := default_id_ginfo ;
  select sp.id_ginfo , ag.ID_GTOPT INTO idginfo, idgtopt from arc_subsyst_profile sp, arc_ginfo ag 
  where sp.id_tbllst in (select id from sys_tbllst where table_name like 'ELREG_LIST_V') 
     AND ag.id = sp.id_ginfo
     AND ag.id_gtopt in ( select  id from SYS_GTOPT where DEFINE_ALIAS like 'GLT_ANALOG_OPT_INT30' ) ;

  FOR rec IN (     
    SELECT ID 
    FROM meas_list
    WHERE id_meas_type IN ( select id from SYS_MEAS_TYPES where DEFINE_ALIAS like 'MEAS_P_CROSSFLOW' or DEFINE_ALIAS like 'MEAS_Q_CROSSFLOW' ) AND is_exdata = 0
  ) 
  LOOP
  
    sss:='';
  
    dbms_output.put_line ('id =' || rec.id);
    
    cnt1:=0;
    SELECT count(*) INTO cnt1 FROM meas_list WHERE EXISTS (SELECT 1 FROM meas_arc WHERE id_param = rec.id AND id_ginfo = idginfo );

    IF cnt1 = 0 THEN
      dbms_output.put_line ('id =' || rec.id || ' - archive not exists');

      select  'el'||lpad(to_char(4), 3, '0')||'_'||lpad(to_char(rec.id), 7, '0') INTO vTname FROM dual ;

      SELECT COUNT (1) INTO cnt FROM All_objects 
        WHERE owner LIKE 'RSDU2ELARH' 
          AND object_name LIKE vTname 
          AND object_type IN ('TABLE','VIEW');
        
      IF cnt = 0 THEN
        aaa := 0;
        aaa := rsdu2elarh.arc_arh_pkg.create_arh (rec.id, default_id_ginfo, vTname, sss); 
      ELSE 
        aaa := 0;
        dbms_output.put_line (vTname || ' exists');
      END IF;

      IF aaa = 0 THEN 
        dbms_output.put_line (vTname || ' created');
        INSERT INTO meas_arc (id_param, id_ginfo, retfname, ID_GTOPT) 
         SELECT rec.id, idginfo, vTname, idgtopt FROM dual
          WHERE NOT EXISTS (SELECT 1 FROM meas_arc WHERE id_param = rec.id AND  id_ginfo = idginfo );
        cnt:= SQL%ROWCOUNT;
        IF cnt > 0 THEN 
           COMMIT;
           dbms_output.put_line (vTname || ' inserted to MEAS_ARC');
        END IF; 
      ELSE 
        dbms_output.put_line (rec.id || ' err = ' || aaa || ' ' ||  sss); 
      END IF;
      
    END IF;

    
  END LOOP;
  
  
EXCEPTION
  WHEN OTHERS THEN
    err_code := SQLCODE;
    err_msg := SUBSTR(SQLERRM, 1, 200);
    DBMS_OUTPUT.PUT_LINE  (err_code || err_msg);  

  
END; 
/ 



