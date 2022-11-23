WHENEVER SQLERROR EXIT 
SET SERVEROUTPUT on
SET feedback off
set verify off
SET linesize  120

ALTER SESSION SET CURSOR_SHARING=FORCE;

-- если нет пакета для обновленй или он очень старый - обновить сразу
@@source/01_RSDU_UPDATE_UTIL_PKG.sql

--Prompt  Проверяем/подготавливаем нужные структуры
begin 
  RSDU_UPDATE_UTIL_PKG.TEMP_RSDU_UPDATE_PREPARE;
  RSDU_UPDATE_UTIL_PKG.TEMP_RSDU_UPDATE_INIT (
    '&DBUpdateName63',
    '&DBUpdateAlias',
    '&DBowner',
    '&DBname',
    '&ApplName63'
    );
end;
/

--Prompt  Создаем тестовую процедуру 
@@test\test_rsdu_update_p.sql 

Prompt =================================================================================
--Prompt >>>    Start of PRE - test

declare 
 vUpdateName   varchar2(63 char);
 vUpdateSchema varchar2(63 char);
 vUpdateState  varchar2(63 char);
 vUpdateStatePrev varchar2(63 char);
 vUpdateDesc   varchar2(2000 char);
 vUpdateWarn   varchar2(2000 char);

  already_exists      EXCEPTION;
  PRAGMA EXCEPTION_INIT(already_exists,-20002);

begin 

  ----------------------------------------------------------------
  -- выполнение процедуры проверки
  test_rsdu_update_p;
  ----------------------------------------------------------------
  -- считывание результатов проверки
  vUpdateState  := RSDU_UPDATE_UTIL_PKG.get_val ('update_state');
  vUpdateDesc   := RSDU_UPDATE_UTIL_PKG.get_val ('update_desc');
  vUpdateWarn   := RSDU_UPDATE_UTIL_PKG.get_val ('update_warn');

   ---------------------------------------------------------------------------------------------------------
   -- печать собранных сведений о тестировании
  RSDU_UPDATE_UTIL_PKG.PrintBigBuffer  (vUpdateDesc); 
   
   if vUpdateState = 2 and vUpdateWarn is null then   
     -- UPD_NONEED - обновление не требуется
     null;
   else
     if vUpdateState = 2 and vUpdateWarn is not null then   
      vUpdateState := 1;
     end if;

      for rec in (select rownum num, name, val from temp_rsdu_update where lower(name) like 'warn%' order by name)
      loop  
        dbms_output.put_line (rpad('ПРЕДУПРЕЖДЕНИЕ '||rec.num||':', 57, '-')); 
        RSDU_UPDATE_UTIL_PKG.PrintBigBuffer2 (rec.name); 
      end loop;

   --  печать сигнальной строки 
     dbms_output.put_line ('--------------------------------------------------------'||chr(10));
     dbms_output.put_line (chr(10)||'  ТРЕБУЕТСЯ ОБНОВЛЕНИЕ!'); 
   end if;

     dbms_output.put_line ('--------------------------------------------------------'||chr(10));


    vUpdateName   := RSDU_UPDATE_UTIL_PKG.get_val ('update_alias');
    vUpdateStatePrev := RSDU_UPDATE_UTIL_PKG.GetUpdateStatus_CurVal (vUpdateName);

  if vUpdateStatePrev is not null then 
    dbms_output.put_line ('========================================================');
    dbms_output.put_line ('Обновление уже было выполнено со статусом '||vUpdateStatePrev);
    dbms_output.put_line ('========================================================');

    if vUpdateState = 2 and nvl(vUpdateStatePrev,' ') in ('0', '2') then 
      -- предыдущее обновление уже выполнялось и статус исполнения "Успешно" или "Не нужно"
      raise already_exists;
    end if;
  
  else -- vUpdateStatePrev is null - нет записей о выполнении обновления
    if vUpdateState = 2 then
      -- обновление не нужно, но нет регистрации обновления! Регистрируем как ненужное для данной БД!
      dbms_output.put_line ('Обновление не требуется. Регистрация со статусом 2 (Не нужно)');
	--insert into rsdu_update 
 	--(id, id_parent, dt1970, state, name, define_alias, server_name, schema_name, applications, description)
	--select 
 	--rsdu_update_s.NEXTVAL
	--, NULL
	--, to_dt1970(SYSDATE)
	--, update_state 
	--, update_name  
	--, update_alias 
	--, server_name  
	--, schema_name  
	--, appl_name
	--, update_desc 
	--from 
	--(select val update_name  from temp_rsdu_update where lower(name) like 'update_name') t1,
	--(select val update_alias from temp_rsdu_update where lower(name) like 'update_alias') t2,
	--(select val server_name  from temp_rsdu_update where lower(name) like 'server_name') t3,
	--(select val schema_name  from temp_rsdu_update where lower(name) like 'schema_name') t4,
	--(select val update_state from temp_rsdu_update where lower(name) like 'update_state') t5,
	--(select val appl_name    from temp_rsdu_update where lower(name) like 'appl_name') t6,
	--(select val update_desc  from temp_rsdu_update where lower(name) like 'update_desc') t7
	--;
    --   commit;
       raise already_exists;
      end if;
  end if;

  --------------------------------------------------------------------------------------
EXCEPTION 
  WHEN already_exists THEN
    raise_application_error (-20002, 'Обновление не требуется. Выполнение сценария остановлено');

  WHEN OTHERS THEN
    raise;
end;
/

--show error 
--show sqlcode

WHENEVER SQLERROR CONTINUE 
--pause Продолжить выполнение обновления? ENTER = да, CTRL-С = нет
