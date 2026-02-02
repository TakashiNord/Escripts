WHENEVER SQLERROR EXIT 
SET SERVEROUTPUT on
SET feedback off

ALTER SESSION SET CURSOR_SHARING=FORCE;

Prompt  Создадим временную таблицу для контроля выполнени€ обновлени€
begin 
  execute immediate 'CREATE TABLE TEMP_RSDU_UPDATE (NAME VARCHAR2(63),VAL VARCHAR2(2000))';
--dbms_output.put_line ('Создана вспомогательная таблица дл€ обновления TEMP_RSDU_UPDATE');
exception when OTHERS then
  execute immediate 'TRUNCATE TABLE TEMP_RSDU_UPDATE';
--dbms_output.put_line ('Очищена вспомогательна€ таблица дл€ обновления TEMP_RSDU_UPDATE');
end;
/

insert into 
  &DBowner..TEMP_RSDU_UPDATE
  (name, val) select
  'update_name', '&DBUpdateName63' 
  from dual union select
  'test','тест'
  from dual ;
commit;

Prompt =================================================================================
Prompt >>>    Start of PRE - test

declare 
 nCnt  NUMBER := 0;
 nRet  NUMBER := 0;
 nErr  NUMBER := 0;
 vTest   varchar2(63);

begin

 select val into vTest from temp_rsdu_update where lower(name) like 'test';
 
 dbms_output.put_line ('vTest='||vTest);
 
 --select decode('тест',vTest,0,1) into nRet from dual ;
 --dbms_output.put_line ('1) nRet='||nRet);
 
-- select decode(cast('тест'as CHAR(4)),vTest,0,1) into nRet from dual ;
-- dbms_output.put_line ('2) nRet='||nRet); 
 
 select INSTR(vTest, '?') into nRet from dual ;
 dbms_output.put_line ('3) nRet='||nRet); 
 
 if nRet=1 then
    nErr := nErr + 1;
 end if;

 if nErr <> 0 then 
    -- обновления нельзя выполнять
      dbms_output.put_line ('Обновления выполнять НЕЛЬЗЯ. Не совпадение кодовых страниц...');
      --raise_application_error (-20002, chr(10)||'Обновления выполнять НЕЛЬЗЯ. Не совпадение кодовых страниц... Выполнение сценария остановлено');
 end if; 
 
 
  --------------------------------------------------------------------------------------
EXCEPTION 
  WHEN OTHERS THEN
    nErr := SQLCODE;
    if nErr = -20001 or nErr = -20002 then 
      raise;
    elsif nErr = -942 or nErr = -1775 then 
      dbms_output.put_line ('Отсутствует обновление 2008_03_13_RSDU_UPDATE, выполните сначала его!');
      raise;
    else
      dbms_output.put_line (sqlerrm);
    end if;
end;
/
Prompt <<<    End of PRE - test
Prompt =================================================================================

WHENEVER SQLERROR CONTINUE 
--pause ѕродолжить выполнение обновлени€? ENTER = да, CTRL-— = нет
