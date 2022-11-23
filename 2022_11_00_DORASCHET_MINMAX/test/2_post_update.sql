set SERVEROUTPUT on
set termout ON
SET verify off

declare 
 nCnt  NUMBER := 0;
 nCnt2 NUMBER := 0;
 nPar  NUMBER := 0;
 nID   NUMBER := 0;
 nErr  NUMBER := 0;
 nWarn NUMBER := 0;
 vUpdateName   varchar2(255 char);
 vUpdateName2  varchar2(255 char);
 vUpdateSchema varchar2(63 char);
 vUpdateState  varchar2(63 char);
 vUpdateServer varchar2(63 char);
 vUpdateDesc   varchar2(2000 char);
 vUpdateWarn   varchar2(2000 char);
 vTableName    varchar2(63 char);
 vCheckName    varchar2(63 char);
 vCheckName2   varchar2(63 char);
 vSQL	       varchar2(2000 char);

  type tTestedDefAlias is table of varchar2(63 char) index by binary_integer;
  tTestName    tTestedDefAlias;

  small_buffer        EXCEPTION;
  PRAGMA EXCEPTION_INIT(small_buffer,  -6502);

  procedure AddUpdateDesc (pStr VARCHAR2) is
  begin
    vUpdateDesc := vUpdateDesc || pStr || chr(10);
  exception when small_buffer then 
    vUpdateDesc := vUpdateDesc || case when vUpdateDesc not like '%...' then '....' else '' end;
  end;  

begin

  dbms_output.enable (null);
  ----------------------------------------------------------------
  -- выполнение процедуры проверки
  test_rsdu_update_p;
  ----------------------------------------------------------------
  -- считывание результатов проверки
  vUpdateState  := RSDU_UPDATE_UTIL_PKG.get_val ('update_state');
  vUpdateDesc   := RSDU_UPDATE_UTIL_PKG.get_val ('update_desc');
  vUpdateWarn   := RSDU_UPDATE_UTIL_PKG.get_val ('update_warn');
   
  ---------------------------------------------------------------------------------------------------------

   if vUpdateState = 2 and vUpdateWarn is null then 
--   vUpdateState := 'UPD_OK'; 
     RSDU_UPDATE_UTIL_PKG.set_val ('update_state', '0');
   elsif vUpdateState = 2 and vUpdateWarn is not null then 
--   vUpdateState := 'UPD_WARN';
     RSDU_UPDATE_UTIL_PKG.set_val ('update_state', '1');
   else 
--   vUpdateState := 'UPD_ERROR';
     null;
   end if;
 
exception WHEN OTHERS THEN
  nErr := SQLCODE;
  dbms_output.put_line (SQLERRM);
  vUpdateDesc := DBMS_UTILITY.FORMAT_CALL_STACK;
  dbms_output.put_line (substr (replace (vUpdateDesc, '----- PL/SQL Call Stack -----'), 500));
end;
/
set termout on

------------------------------- РЕГИСТРАЦИЯ ОБНОВЛЕНИЯ -------------------------------

set feedback off
delete from rsdu_update 
  where define_alias like (select val||'%' update_alias from temp_rsdu_update where lower(name) like 'update_alias');

insert into rsdu_update 
 (id, id_parent, dt1970, state, name, define_alias, server_name, schema_name, applications, description)
select 
 rsdu_update_s.NEXTVAL
, NULL
, to_dt1970(SYSDATE)
, update_state 
, update_name  
, update_alias 
, server_name  
, schema_name  
, appl_name
, update_desc 
from 
(select val update_name  from temp_rsdu_update where lower(name) like 'update_name') t1,
(select val update_alias from temp_rsdu_update where lower(name) like 'update_alias') t2,
(select val server_name  from temp_rsdu_update where lower(name) like 'server_name') t3,
(select val schema_name  from temp_rsdu_update where lower(name) like 'schema_name') t4,
(select val update_state from temp_rsdu_update where lower(name) like 'update_state') t5,
(select val appl_name    from temp_rsdu_update where lower(name) like 'appl_name') t6,
(select val update_desc  from temp_rsdu_update where lower(name) like 'update_desc') t7
;
-----------------------
-- для схем архивных владельцев
BEGIN
 FOR rec IN (SELECT REPLACE (NAME, 'update_alias') num FROM temp_rsdu_update WHERE NAME LIKE 'update_alias_')
  LOOP
      
insert into rsdu_update 
 (id, id_parent, dt1970, state, name, define_alias, server_name, schema_name, applications, description)
select 
 rsdu_update_s.NEXTVAL
, parent_id
, to_dt1970(SYSDATE)
, update_state 
, update_name  
, update_alias 
, server_name  
, schema_name  
, appl_name
, update_desc 
from 
(select val update_name  from temp_rsdu_update where lower(name) like 'update_name'||rec.num) t1,
(select val update_alias from temp_rsdu_update where lower(name) like 'update_alias'||rec.num) t2,
(select val server_name  from temp_rsdu_update where lower(name) like 'server_name'||rec.num) t3,
(select val schema_name  from temp_rsdu_update where lower(name) like 'schema_name'||rec.num) t4,
(select val update_state from temp_rsdu_update where lower(name) like 'update_state'||rec.num) t5,
(select val appl_name    from temp_rsdu_update where lower(name) like 'appl_name'||rec.num) t6,
(select val update_desc  from temp_rsdu_update where lower(name) like 'update_desc'||rec.num) t7,
(select id  parent_id    from rsdu_update where define_alias like
   (select val  from temp_rsdu_update where lower(name) like 'update_alias')) t8
;

  END LOOP;
END;
/
commit;
----------------------------------------------------------------------------------------
-- Удаление процедуры проверки 
drop procedure test_rsdu_update_p;
-- Удаление временной таблицы
--drop table  temp_rsdu_update;
Prompt _________________________________________________________________________________
Prompt 
Prompt Сведения о результатах выполнения обновления:
Prompt 
col name format a30
col value format a70
set linesize 105
select '1.Статус выполнения' NAME ,  update_state VALUE from 
 (select d.name update_state from temp_rsdu_update t, rsdu_update_desc d 
                            where t.val = d.id and lower(t.name) like 'update_state') t5
UNION select '2.Наименование обновления', update_name  from 
 (select val update_name  from temp_rsdu_update where lower(name) like 'update_name') t1
UNION select '3.Код обновления', update_alias  FROM 
 (select val update_alias from temp_rsdu_update where lower(name) like 'update_alias') t2
UNION select '4.Соединение с БД', server_name   FROM 
 (select val server_name  from temp_rsdu_update where lower(name) like 'server_name') t3
UNION select '5.Обновляемая схема', schema_name FROM 
 (select val schema_name  from temp_rsdu_update where lower(name) like 'schema_name%') t4
UNION select '6.Приложения, на котор. влияет', appl_name FROM 
 (select val appl_name    from temp_rsdu_update where lower(name) like 'appl_name') t6
UNION select '7.Описание результатов', update_desc  FROM 
 (select val update_desc  from temp_rsdu_update where lower(name) like 'update_desc%') t7
UNION select case when cnt > 0 then 'ПРЕДУПРЕЖДЕНИE'||nn else 'End.' end name, val
  from (select replace (lower (name),'warn', ' ')nn, val from temp_rsdu_update where lower(name) like 'warn%' order by name),
    (select count (1) cnt  from temp_rsdu_update where lower(name) like 'warn%');
    
Prompt _________________________________________________________________________________
set feedback on

--------------------------------------------------------------------------------------
