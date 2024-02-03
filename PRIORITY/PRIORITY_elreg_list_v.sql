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