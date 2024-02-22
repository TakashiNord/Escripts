--SET SERVEROUTPUT on
DECLARE

--  TYPE cur_typ  IS REF CURSOR;
--  cur           cur_typ;
--  TYPE tab_rec_type IS RECORD (id_param NUMBER(11), param_name VARCHAR(255 char), id_table NUMBER(11), table_name VARCHAR(255 char));
--  TYPE tab_type IS TABLE OF tab_rec_type INDEX BY PLS_INTEGER;
--  tabSource tab_type;
--  out_rec PARAM_ROW_TYPE := PARAM_ROW_TYPE (0,'', 0, '');

-- CURSOR Tune_tab is
--    select * from elreg_list_v ;

--  CURSOR src_tab (pLST number) is
--    select msc.ID,msc.ID_SOURCE,ms.ALIAS as AL,msc.ALIAS,msc.PRIORITY
--    from MEAS_SRC_CHANNEL msc, MEAS_SOURCE ms
--    where msc.ID_OWNLST=pLST  and ms.ID=msc.ID_SOURCE
--    order by msc.PRIORITY asc

    ret1 number ;
    ret2 number ;
    vStrM VARCHAR2(256);
 --

 -- список источников\каналов у параметра
function GetSource (pID number , s VARCHAR2)
    return number
  is
    rid number ;
    ret3 number := 0;
    vStrS VARCHAR2(4024);
    nRetval number := 0;

    valias VARCHAR2(40);
    vportn number := 0;
    vid number := 0;
    vids number := 0;
    isrct number := 0;
    isrcl number := 0;

    vStrT VARCHAR2(1024);
    vStrT2 VARCHAR2(1024);
    vStrA VARCHAR2(1024);
    TABLE_NAME VARCHAR2(40);
    TABLE_NAME_DEF VARCHAR2(256);

 begin
    --
    rid:=0;
    EXECUTE IMMEDIATE 'Select count(*) FROM MEAS_SRC_CHANNEL where ID_OWNLST='||pID INTO rid;
    if rid <=0 then
      return nRetval;
    end if ;

    FOR recmsc in ( Select ID, ID_SOURCE FROM MEAS_SRC_CHANNEL where ID_OWNLST=pID )
    LOOP
      vid:=recmsc.ID;
      vids:=recmsc.ID_SOURCE;
      vStrS:='';
      vStrT:='';
      vStrA:='';
      valias:='';

      rid:=0;
      EXECUTE IMMEDIATE 'Select count(*) FROM MEAS_SOURCE where ID='||vids INTO rid;
      if rid>0 then
        FOR recms in ( Select ID, ALIAS, PORT_NUM FROM MEAS_SOURCE where ID=vids )
        LOOP
          vportn:=recms.PORT_NUM;
          valias:=recms.ALIAS;

          -- Оператор | Дорасчет
          if vportn=1 then
            rid:=0;
            vStrT:='';
            EXECUTE IMMEDIATE 'Select count(*) FROM MEAS_SRC_CHANNEL_CALC where ID_CHANNEL='||vid INTO rid;
            if rid>0 then
              FOR recmscc in ( Select ID_CHANNEL, FORMULE FROM MEAS_SRC_CHANNEL_CALC where ID_CHANNEL=vid )
              LOOP
                vStrT:=recmscc.FORMULE ;
              END LOOP;
              vStrS:= valias||';"'||vStrT||'";'||pID ; -- формула дорасчета
            else
              vStrS:= valias||';'||'0'||';'||pID ;
            end if ;
          end if ;

          --
          if vportn<>1 then

            vStrT:='';
            isrct:=0;
            isrcl:=0;
            TABLE_NAME:='';
            TABLE_NAME_DEF:='';

            rid:=0;
            EXECUTE IMMEDIATE 'Select count(*) FROM MEAS_SRC_CHANNEL_TUNE where ID_CHANNEL='||vid INTO rid;
            if rid>0 then
              FOR recmsct in ( Select ID, ID_SRCTBL, ID_SRCLST FROM MEAS_SRC_CHANNEL_TUNE where ID_CHANNEL=vid )
              LOOP
                isrct:=recmsct.ID_SRCTBL ;
                isrcl:=recmsct.ID_SRCLST ;
              END LOOP;
            end if ;

            -- получаем таблицу раздела
            rid:=0;
            EXECUTE IMMEDIATE 'SELECT count(*) FROM sys_tbllst WHERE ID='||isrct  INTO rid;
            if rid>0 then
              FOR rectbl in ( SELECT UPPER(TABLE_NAME) as TABLE_NAME, NAME FROM sys_tbllst WHERE ID=isrct  )
              LOOP
                TABLE_NAME:=rectbl.TABLE_NAME ;
                TABLE_NAME_DEF:=rectbl.NAME ;
              END LOOP;
              vStrT:= TABLE_NAME_DEF||'('||isrct||');;'||isrcl ;

              if INSTR( TABLE_NAME , 'PHREG_LIST_V')>0 then
                vStrT2:=';';
                rid:=0;
                EXECUTE IMMEDIATE 'Select count(*) FROM phreg_list_v where ID='||isrcl INTO rid;
                if rid>0 then
                  FOR recmsct in ( Select ID,ID_NODE, id_type, NAME,ALIAS FROM phreg_list_v where ID=isrcl )
                  LOOP
                    vStrT2:=recmsct.NAME||';'||recmsct.ALIAS;
                  END LOOP;
                end if ;
                vStrS:=vStrT||';;'||vStrT2||';';
              end if ;

              if INSTR( TABLE_NAME , 'ELREG_LIST_V')>0 then
                vStrT2:=';';
                rid:=0;
                EXECUTE IMMEDIATE 'Select count(*) FROM elreg_list_v where ID='||isrcl INTO rid;
                if rid>0 then
                  FOR recmsct in ( Select ID,ID_NODE, id_type, NAME,ALIAS FROM elreg_list_v where ID=isrcl )
                  LOOP
                    vStrT2:=recmsct.NAME||';'||recmsct.ALIAS;
                  END LOOP;
                end if ;
                vStrS:=vStrT||';;'||vStrT2||';';
               end if ;

              if INSTR( TABLE_NAME , 'DA_V_LST')>0 then
                vStrT2:=';';
                rid:=0;
                EXECUTE IMMEDIATE 'Select count(*) FROM DA_PARAM dp, DA_DEV_DESC dd, DA_CAT dc where dd.ID=dp.ID_POINT and dp.ID_NODE=dc.id and dp.ID='||isrcl INTO rid;
                if rid>0 then
                  FOR recmsct in ( Select dp.ID,dp.ID_NODE,dc.NAME as N1,dp.NAME as N2,dp.ALIAS,dd.CVALIF FROM DA_PARAM dp, DA_DEV_DESC dd, DA_CAT dc
                          where dd.ID=dp.ID_POINT and dp.ID_NODE=dc.id and dp.ID=isrcl )
                  LOOP
                    vStrT2:=recmsct.N1||';'||recmsct.N2||';'||recmsct.ALIAS||';'||recmsct.CVALIF;
                  END LOOP;
                end if ;
                vStrS:=vStrT||';'||vStrT2||'';
              end if ;

            end if ; -- if rid>0
          end if ; -- vportn<>1

        END LOOP;
      end if ;

      --"${header};${ALIAS1};${str}"
      dbms_output.put_line ( s||';'||valias||';'||vStrS );

    END LOOP;

    return nRetval;
  exception when others then
    nRetval := SQLCODE;
end;


 -- список параметров
 function GetList (pID number , s VARCHAR2)
    return number
  is
    nCnt    number;
    vStrL VARCHAR2(1024);
    rid number ;
    nRetval number := 0;
    ret3 number ;
 begin
    --
    rid:=0;
    EXECUTE IMMEDIATE 'Select count(*) from MEAS_LIST ml, MEAS_VAL mv , elreg_tlist_v e, SYS_PUNIT sp
 where mv.ID_PARAM=ml.ID and ml.id_meas_type=e.ID and sp.ID=mv.ID_UNIT
 and ml.id_meas_type IN (SELECT ID FROM elreg_tlist_v) AND is_exdata = 0 and ml.ID_OBJ='||pID INTO rid;
    if rid <=0 then
      return nRetval;
    end if ;

    FOR recdp in ( Select ml.ID, ml.ID_OBJ ,ml.ID_MEAS_TYPE, ml.NAME , ml.ALIAS, ml.IS_EXDATA ,e.NAME as NAME1,e.alias as alias1,e.define_alias
 ,mv.ID_PARAM, mv.PRECISION ,mv.FEATURE, mv.ID_UNIT ,sp.ID_TYPE , sp.NAME as NAME2, sp.COEF_TO_BASE
from MEAS_LIST ml, MEAS_VAL mv , elreg_tlist_v e, SYS_PUNIT sp
where mv.ID_PARAM=ml.ID and ml.id_meas_type=e.ID and sp.ID=mv.ID_UNIT
    and ml.id_meas_type IN (SELECT ID FROM elreg_tlist_v) AND is_exdata = 0 and  ml.ID_OBJ=pID
 )
    LOOP
      vStrL:=s||';'||recdp.id||';'||recdp.name||';'||recdp.alias||';'||recdp.NAME1||';'||recdp.alias1||';'||recdp.define_alias||';PRECISION='||recdp.PRECISION||';UNIT='||recdp.NAME2||';COEF='||recdp.COEF_TO_BASE ;
      -- dbms_output.put_line ( vStrL );

      ret3:=GetSource (recdp.id , vStrL ) ;
    END LOOP;

    return nRetval;
  exception when others then
    nRetval := SQLCODE;
end;


 -- узлы
function GetElem (pID number, s VARCHAR2 )
    return number
  is
    cid number ;
    vStrE VARCHAR2(1024);
    ret1 number ;
    ret2 number ;
    nRetval number := 0;
begin

    cid:=0;
    EXECUTE IMMEDIATE 'Select count(ID) from OBJ_TREE where ID_PARENT='||pID INTO cid;
    if cid>0 then
      FOR recdp in ( Select ID,ID_PARENT,ID_TYPE,NAME,ALIAS from OBJ_TREE where ID_PARENT=pID
                     ORDER BY 1 )
      LOOP
        -- "${header};${name}|${alias}"
        --vStrE:= s||';'||recdp.id||';'||recdp.name||'|'||recdp.alias;
        vStrE:= s||'\'||recdp.name;
        --dbms_output.put_line ( vStrE );

        ret1:=GetList (recdp.id, vStrE) ;
        ret2:=GetElem (recdp.id, vStrE) ;
      END LOOP;
    end if ;

    return nRetval;
  exception when others then
    nRetval := SQLCODE;
end;


begin
    dbms_output.ENABLE (400000);
    --  -- and ID_TYPE in (select ID from SYS_OTYP where like '%OTYP_BUS_NETWORK%' )
    FOR rec in ( Select ID,ID_PARENT,ID_TYPE,NAME,ALIAS FROM OBJ_TREE where ID=3 )
    LOOP
        -- header = ";$name"
        vStrM:=''||rec.name;
        --dbms_output.put_line ( vStrM );

        ret1:=GetList (rec.id, vStrM) ;
        ret2:=GetElem (rec.id, vStrM) ;
    END LOOP;
end;
/