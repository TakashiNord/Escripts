SET SERVEROUTPUT ON
declare
    ret1 number ;
    ret2 number ;
    cntSum number :=0 ;
 -- 
  function GetList (pID number)
    return number
  is
    nCnt    number;
    vStr VARCHAR2(1024);
    rid number ;
    nRetval number := 0;
  begin

      --
      rid:=0;
      EXECUTE IMMEDIATE 'Select count(*) from MEAS_LIST ml , MEAS_SRC_CHANNEL msc where msc.ID_OWNLST=ml.ID and ml.id_meas_type IN (SELECT ID FROM elreg_tlist_v) AND is_exdata = 0 and ml.ID_OBJ='||pID INTO rid;
      if rid <=0 then
        return nRetval;
      end if ;

      FOR recdp in (
            Select ml.ID,ml.Name,ml.ALIAS, msc.ID as ID_CANAL, msc.ID_SOURCE,msc.ALIAS as ALIAS_CANAL,msc.PRIORITY
            from MEAS_LIST ml , MEAS_SRC_CHANNEL msc 
            where msc.ID_OWNLST=ml.ID and ml.id_meas_type IN (SELECT ID FROM elreg_tlist_v) AND is_exdata = 0 and ml.ID_OBJ=pID 
      )
      LOOP

       vStr := ' ; none' ;
       dbms_output.put_line( ';' || recdp.id || ';' || recdp.alias || ';' || recdp.ID_CANAL || ';' ||  recdp.ID_SOURCE || ';' ||  recdp.ALIAS_CANAL || ';'||  recdp.PRIORITY || ';');

-- MEAS_SOURCE
--
--Сбор с филиала ЭС ИЭСК (СЭС, ЗЭС, ЦЭС, ЮЭС, ВЭС)
-- 
-- 9	Сбор с СЭС (ТИ)	1	2205	255
--20	Сбор с СЭС (ТС)	8	2206	255
--23	Сбор с ЦЭС (ТИ)	1	2216	255
--24	Сбор с ЦЭС (ТС)	8	2213	255
--25	Сбор с ЮЭС (ТИ)	1	2220	255
--26	Сбор с ЮЭС (ТС)	8	2217	255
--27	Сбор с ВЭС (ТИ)	1	2228	255
--28	Сбор с ВЭС (ТС)	8	2221	255
--32	Сбор с ЦППС ЗЭС (ТИ)	1	2202	255
--33	Сбор с ЦППС ЗЭС (ТС)	8	2191	255
--
--29\30 Сбор с ИРДУ
--1 Оператор

-- Назначим приоритеты 
-- 9	Сбор с СЭС (ТИ)	   255
--20	Сбор с СЭС (ТС)	   255
--23	Сбор с ЦЭС (ТИ)	   255
--24	Сбор с ЦЭС (ТС)	   255
--25	Сбор с ЮЭС (ТИ)	   255
--26	Сбор с ЮЭС (ТС)	   255
--27	Сбор с ВЭС (ТИ)	   255
--28	Сбор с ВЭС (ТС)	   255
--32	Сбор с ЦППС ЗЭС (ТИ)  255
--33	Сбор с ЦППС ЗЭС (ТС)  255
--
--29	Сбор с ИРДУ (ТИ)   270
--30	Сбор с ИРДУ (ТС)   270
-- 
--1 Оператор      280


      if recdp.ID_SOURCE=1  then
	     UPDATE MEAS_SRC_CHANNEL SET PRIORITY = 280 WHERE ID=recdp.ID_CANAL ;
		 commit;
	  end if ;
      
	  if recdp.ID_SOURCE=29  then
	     UPDATE MEAS_SRC_CHANNEL SET PRIORITY = 270 WHERE ID=recdp.ID_CANAL ;
		 commit;
	  end if ;	  
      if recdp.ID_SOURCE=30  then
	     UPDATE MEAS_SRC_CHANNEL SET PRIORITY = 270 WHERE ID=recdp.ID_CANAL ;
		 commit;
	  end if ;
	  
      if recdp.ID_SOURCE=9  then
	     UPDATE MEAS_SRC_CHANNEL SET PRIORITY = 255 WHERE ID=recdp.ID_CANAL ;
		 commit;
	  end if ;
      if recdp.ID_SOURCE=20  then
	     UPDATE MEAS_SRC_CHANNEL SET PRIORITY = 255 WHERE ID=recdp.ID_CANAL ;
		 commit;
	  end if ;
      if recdp.ID_SOURCE=23  then
	     UPDATE MEAS_SRC_CHANNEL SET PRIORITY = 255 WHERE ID=recdp.ID_CANAL ;
		 commit;
	  end if ;	  
      if recdp.ID_SOURCE=24  then
	     UPDATE MEAS_SRC_CHANNEL SET PRIORITY = 255 WHERE ID=recdp.ID_CANAL ;
		 commit;
	  end if ;	  
      if recdp.ID_SOURCE=25  then
	     UPDATE MEAS_SRC_CHANNEL SET PRIORITY = 255 WHERE ID=recdp.ID_CANAL ;
		 commit;
	  end if ;	  
      if recdp.ID_SOURCE=26  then
	     UPDATE MEAS_SRC_CHANNEL SET PRIORITY = 255 WHERE ID=recdp.ID_CANAL ;
		 commit;
	  end if ;
      if recdp.ID_SOURCE=27  then
	     UPDATE MEAS_SRC_CHANNEL SET PRIORITY = 255 WHERE ID=recdp.ID_CANAL ;
		 commit;
	  end if ;
      if recdp.ID_SOURCE=28  then
	     UPDATE MEAS_SRC_CHANNEL SET PRIORITY = 255 WHERE ID=recdp.ID_CANAL ;
		 commit;
	  end if ;
      if recdp.ID_SOURCE=32  then
	     UPDATE MEAS_SRC_CHANNEL SET PRIORITY = 255 WHERE ID=recdp.ID_CANAL ;
		 commit;
	  end if ;
      if recdp.ID_SOURCE=33  then
	     UPDATE MEAS_SRC_CHANNEL SET PRIORITY = 255 WHERE ID=recdp.ID_CANAL ;
		 commit;
	  end if ;

      END LOOP;

    return nRetval;
  exception when others then
    nRetval := SQLCODE;
end;

 -- 
  function GetElem (pID number)
    return number
  is
    cid number ;
    ret1 number ;
    ret2 number ;
    nRetval number := 0;
  begin

    cid:=0;
    EXECUTE IMMEDIATE 'Select count(ID) from OBJ_TREE where ID_PARENT='||pID INTO cid;
    if cid>0 then
      FOR recdp in ( Select ID, ID_PARENT ,ID_TYPE, NAME , ALIAS from  OBJ_TREE where ID_PARENT=pID
                     ORDER BY 1 )
      LOOP
        ret1:=GetList (recdp.id) ;
        ret2:=GetElem (recdp.id) ;
      END LOOP;
    end if ;

    return nRetval;
  exception when others then
    nRetval := SQLCODE;
end;


begin
    dbms_output.ENABLE (400000);
    --
    FOR rec in ( Select ID, ID_PARENT ,ID_TYPE, NAME, ALIAS FROM OBJ_TREE where ID=335 )
    LOOP
        ret1:=GetList (rec.id) ;
        ret2:=GetElem (rec.id) ;
    END LOOP;

end;