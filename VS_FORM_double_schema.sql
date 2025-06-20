--SET SERVEROUTPUT on
DECLARE
  nCNT NUMBER ;
  vSQL VARCHAR2(32700);
  idp NUMBER;
  iNew NUMBER;
  nInserted INTEGER := 0;
  id_old NUMBER := 10; -- id старой схемы из таблицы VS_FORM
  id_new NUMBER := 57; -- id новой схемы из таблицы VS_FORM
BEGIN
   -- TAG_POSITION      ID_SCHEME    ID_TAG -> TAG_LIST
   -- VS_COMP           ID_FORM  ,  ID_OWNLST  -> VS_REGIM_TUNE

   dbms_output.ENABLE (200000);
   dbms_output.put_line ( '-----------DELETE--------------' );
   
   DELETE FROM TAG_POSITION tp where tp.ID_SCHEME = id_new ;
   DELETE FROM VS_COMP where ID_FORM = id_new ;
   
   dbms_output.put_line ( '------------COPY----------------' );

   select count(*) into nCNT from TAG_POSITION tp where tp.ID_SCHEME = id_old ;
   if (nCNT>0) THEN
     --
	 nInserted:=0;
     FOR rec1 IN (
        select tp.ID_TAG, tp.ID_SCHEME, tp.POS_X, tp.POS_Y, tp.ID_COMP
         from TAG_POSITION tp
        where tp.ID_SCHEME = id_old
     )
     LOOP

	  idp:=rec1.ID_TAG;
      FOR rec2 IN (
        select ID,ID_NODE,ID_TYPE,VISIBLE,ID_USER_CREATE, DT1970_CREATE, ID_USER_MODIFY, DT1970_MODIFY, DESCRIPTION, DT1970_STARTEVENT, DT1970_ENDEVENT,ID_DIR
          from TAG_LIST
         where ID = idp
      )
      LOOP
        select max(ID)+1 INTO iNew from TAG_LIST ;
        INSERT INTO TAG_LIST (ID,ID_NODE,ID_TYPE,VISIBLE,ID_USER_CREATE, DT1970_CREATE, ID_USER_MODIFY, DT1970_MODIFY, DESCRIPTION, DT1970_STARTEVENT, DT1970_ENDEVENT,ID_DIR) VALUES (iNew, rec2.ID_NODE,rec2.ID_TYPE,rec2.VISIBLE,rec2.ID_USER_CREATE,rec2.DT1970_CREATE,rec2.ID_USER_MODIFY,rec2.DT1970_MODIFY,rec2.DESCRIPTION,rec2.DT1970_STARTEVENT,rec2.DT1970_ENDEVENT,rec2.ID_DIR) ;
        Insert into TAG_POSITION (ID_TAG,ID_SCHEME,POS_X,POS_Y,ID_COMP) VALUES (iNew,id_new,rec1.POS_X, rec1.POS_Y, rec1.ID_COMP) ;
        COMMIT;
	    nInserted := nInserted + 1;
	    END LOOP;

     END LOOP;
	 dbms_output.put_line('Inserted TAG_LIST and TAG_POSITION = ' || nInserted || ' equipment tunes');
	 --
   END IF;


   select count(*) into nCNT from VS_COMP where ID_FORM = id_old ;
   if (nCNT>0) THEN
     --
	 nInserted:=0;
     FOR rec3 IN (
       select ID,ID_FORM,NAME,ID_TCTRL,FEATURE,PRECISION,TAG
         from VS_COMP
        where ID_FORM = id_old
     )
     LOOP

      idp:=rec3.ID;
      FOR rec4 IN (
        select ID_OWNLST,ID_REGIM,ID_TABLE,ID_PARAM,ID_GTOPT,SCALE
          from VS_REGIM_TUNE
         where ID_OWNLST = idp
      )
      LOOP
        select max(ID)+1 INTO iNew from VS_COMP ;
        Insert into VS_COMP (ID,ID_FORM,NAME,ID_TCTRL,FEATURE,PRECISION,TAG) VALUES (iNew,id_new,rec3.NAME,rec3.ID_TCTRL,rec3.FEATURE,rec3.PRECISION,rec3.TAG) ;
		INSERT INTO VS_REGIM_TUNE (ID_OWNLST,ID_REGIM,ID_TABLE,ID_PARAM,ID_GTOPT,SCALE) VALUES (iNew, rec4.ID_REGIM,rec4.ID_TABLE,rec4.ID_PARAM,rec4.ID_GTOPT,rec4.SCALE) ;
        COMMIT;
		nInserted := nInserted + 1;
	  END LOOP;

    END LOOP;
	dbms_output.put_line('Inserted VS_COMP and VS_REGIM_TUNE = ' || nInserted || ' equipment tunes');
	--
   END IF;


EXCEPTION WHEN OTHERS THEN
  nCnt := SQLCODE;
  vSQL := SQLERRM;
  dbms_output.put_line ('ORA-'||nCnt);
  dbms_output.put_line (vSQL);
END;
/