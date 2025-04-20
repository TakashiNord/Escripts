SET SERVEROUTPUT ON 
DECLARE 
-- 
--
  IDNODE NUMBER ;
  IDGINFO NUMBER;
  seq_currval NUMBER;
  done VARCHAR2(80);
BEGIN 
  dbms_output.ENABLE (100000);
  dbms_output.put_line ('');
  
  IDNODE := 2000475 ;
  IDGINFO := 28 ;  -- ТИ = 28  -- ТС = 5
  
  FOR rec IN (
        select id from DA_PARAM where ID_NODE = IDNODE
      ) LOOP
      done := '';

      BEGIN 
	    -- Вызов процедуры arc_arh_pkg.drop_arh (parnum,sname)
        seq_currval:=0;
		EXECUTE IMMEDIATE 'DELETE FROM DA_ARC WHERE ID_PARAM=' || rec.ID || ' AND ' || ' ID_GINFO= ' || IDGINFO INTO seq_currval; 
        IF seq_currval > 0  THEN 
            done := ' del reg id='|| rec.ID;
		    dbms_output.put_line(''||done);
        END IF;

      EXCEPTION WHEN OTHERS THEN NULL;
      END;
      
   END LOOP;
   dbms_output.put_line('done');
END;
/

