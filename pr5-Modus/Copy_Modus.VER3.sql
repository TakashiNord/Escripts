SET SERVEROUTPUT ON 
DECLARE 
-- 
--  Created by Elena   
--
  id1 NUMBER :=-1; -- Исходный id файла 
  id2 NUMBER :=-2; -- копируемый id файла
  vs_id NUMBER;
  vs_id_new NUMBER;
  sql_stmt          VARCHAR2(200);
  CURSOR c1 (id_form1 NUMBER) IS
    select id , NAME, ID_TCTRL, FEATURE, PRECISION, TAG  from vs_comp where id_form=id_form1 ;
  CURSOR c2 (OWNLST NUMBER) IS
    select ID_OWNLST , ID_REGIM, ID_TABLE, ID_PARAM, ID_GTOPT  from VS_REGIM_TUNE where ID_OWNLST=OWNLST ;
  CURSOR c3 (id_form1 NUMBER) IS
    select ID_TABLE, ID_PARAM from VS_OBJ_TUNE where id_form=id_form1 ;
BEGIN 
  dbms_output.ENABLE (100000);
  vs_id_new :=1;
  select nvl(max(id),0) into vs_id from VS_COMP;
  while vs_id_new < vs_id loop
   select VS_COMP_S.nextval into vs_id_new from dual;
  end loop;

  FOR rec IN c1(id1) LOOP
    vs_id := rec.id ;
    EXECUTE IMMEDIATE 'SELECT vs_comp_s.nextval from vs_comp' INTO vs_id_new;
    --vs_id_new:=vs_id_new+1;
    sql_stmt := 'INSERT INTO vs_comp VALUES (:1, :2, :3, :4, :5, :6, :7)';
    EXECUTE IMMEDIATE sql_stmt USING vs_id_new,id2,rec.NAME,rec.ID_TCTRL,rec.FEATURE,rec.PRECISION,rec.TAG;    
    dbms_output.put_line('id new ='||vs_id_new);
    FOR rec2 IN c2(vs_id) LOOP          
      sql_stmt := 'insert into VS_REGIM_TUNE (ID_OWNLST,ID_REGIM,ID_TABLE,ID_PARAM,ID_GTOPT) values (:1, :2, :3, :4, :5)';
      EXECUTE IMMEDIATE sql_stmt USING vs_id_new,rec2.ID_REGIM,rec2.ID_TABLE,rec2.ID_PARAM,rec2.ID_GTOPT; 
    END LOOP ;    
  END LOOP;
  commit;

  FOR rec IN c3(id1) LOOP
    sql_stmt := 'INSERT INTO vs_obj_tune VALUES (:1, :2, :3)';
    EXECUTE IMMEDIATE sql_stmt USING id2,rec.ID_TABLE,rec.ID_PARAM;    
  END LOOP;
  commit;
  dbms_output.put_line('done');
END;
/
