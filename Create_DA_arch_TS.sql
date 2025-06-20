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
  idginfo number ;
  idgtopt number ;
  err_code      VARCHAR2 (4000);
  err_msg       VARCHAR2 (4000);  

BEGIN  
  dbms_output.ENABLE (400000) ;
  
  idginfo := 5 ;
  idgtopt := 8 ;

  FOR rec IN (     
   SELECT da.ID, da.id_node, da.NAME, dd.cvalif, gt.NAME gtopt
   FROM da_param da , da_v_cat_1 da_cat, -- !!! смена раздела
        da_dev_desc dd, sys_gtopt gt
   where  dd.ID = da.id_point
        and gt.ID = dd.id_gtopt 
        and gt.define_alias like '%BOOL%'
        AND da.id_node = da_cat.ID
        AND da.is_deleted = 0
		-- and da.id_node in  ( ) -- !! отбор по приборам
  ) 
  LOOP
 
    sss:='';
  
    --dbms_output.put_line ('id =' || rec.id);
    
    cnt1:=0;
    SELECT count(*) INTO cnt1 FROM da_param WHERE EXISTS (SELECT 1 FROM da_arc WHERE id_param = rec.id AND id_ginfo = idginfo and ID_GTOPT=idgtopt );

    IF cnt1 = 0 THEN
      --dbms_output.put_line ('id =' || rec.id || ' - archive not exists');

        aaa := 0;
        aaa := rsdu2daarh.arc_arh_pkg.create_arh (rec.id, idginfo, vTname, sss); 

      IF aaa = 0 THEN 
        -- dbms_output.put_line (vTname || ' created');
        INSERT INTO da_arc (id_param, id_ginfo, retfname, ID_GTOPT) 
          SELECT rec.id, idginfo, vTname, idgtopt FROM dual
          WHERE NOT EXISTS (SELECT 1 FROM da_arc WHERE id_param = rec.id AND  id_ginfo = idginfo and ID_GTOPT=idgtopt );
        cnt:= SQL%ROWCOUNT;
        IF cnt > 0 THEN 
           COMMIT;
           dbms_output.put_line (vTname || ' inserted to DA_ARC');
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