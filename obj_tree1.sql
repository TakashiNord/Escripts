--SET SERVEROUTPUT on
DECLARE

    ret1 number ;
    ret2 number ;
    vStrM VARCHAR2(256);
 --


 -- список параметров
 function GetList (pID number , s VARCHAR2)
    return number
  is
    nCnt    number;
    vStrL VARCHAR2(4024);
    rid number ;
    nRetval number := 0;
    ret3 number ;
 begin
    --
    rid:=0;


    return nRetval;
  exception when others then
    nRetval := -1;
    return nRetval;
end;


 -- узлы
function GetElem (pID number, s VARCHAR2 )
    return number
  is
    cid number ;
    vStrE VARCHAR2(4024);
    ret1 number ;
    ret2 number ;
    nRetval number := 0;
begin

    cid:=0;
    EXECUTE IMMEDIATE 'Select count(ID) from table_name where ID_PARENT='||pID INTO cid;

    --vStrE:= s||';cid='||cid;
    --dbms_output.put_line ( vStrE );

    if cid>0 then
      FOR recdp in ( Select ID,ID_PARENT,NAME from table_name where ID_PARENT=pID
                     ORDER BY 1 )
      LOOP
        vStrE:= s||';'||recdp.id||';'||recdp.name;

        dbms_output.put_line ( vStrE );

        ret1:=GetList (recdp.id, vStrE) ;
        ret2:=GetElem (recdp.id, vStrE) ;
      END LOOP;
    end if ;

    return nRetval;
  exception when others then
    raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
    nRetval := -1;
    return nRetval;
end;


begin
    --dbms_output.ENABLE (10000000);
    DBMS_OUTPUT.ENABLE (buffer_size => NULL);

    -- ID_PARENT is null
    FOR rec in ( Select ID,ID_PARENT,NAME FROM table_name where ID_PARENT is null )
    LOOP

        vStrM:=''||rec.id||';'||rec.name;
        dbms_output.put_line ( vStrM );

        ret1:=GetList (rec.id, vStrM) ;
        ret2:=GetElem (rec.id, vStrM) ;
    END LOOP;
end;
/