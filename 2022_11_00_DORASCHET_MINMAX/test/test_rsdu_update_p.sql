--Prompt  ѕровер€ем/подготавливаем нужные структуры
/*
begin 
  RSDU_UPDATE_UTIL_PKG.TEMP_RSDU_UPDATE_PREPARE;
  RSDU_UPDATE_UTIL_PKG.TEMP_RSDU_UPDATE_INIT ('2021_08_27_JOB_MAIN_ID_SFORM','2021_08_27_JOB_MAIN_ID_SFORM');
end;
/
*/
set serveroutput on
create or replace procedure test_rsdu_update_p (print_result number default 0) as 
 nCnt  NUMBER := 0;
 nCnt2 NUMBER := 0;
 nPar  NUMBER := 0;
 nID   NUMBER := 0;
 nErr  NUMBER := 0;
 nWarn NUMBER := 0;
 vUpdateName   varchar2(63 char);
 vUpdateSchema varchar2(63 char);
 vUpdateState  varchar2(63 char);
 vUpdateDesc   varchar2(2000 char);
 vCheckName    varchar2(255 char);
 vCheckName2   varchar2(255 char);
 vTableName    varchar2(63 char);
 vUpdateNameREQUIRED varchar2(63 char) := '';
 vTxt           varchar2(2000 char);

  type tTestedDefAlias is table of varchar2(255 char) index by binary_integer;
  tTestName    tTestedDefAlias;

  no_preREQUIRED      EXCEPTION;
  small_buffer        EXCEPTION;
  no_dbpart           EXCEPTION;
  PRAGMA EXCEPTION_INIT(no_preREQUIRED,-20001);
  PRAGMA EXCEPTION_INIT(small_buffer,  -6502);
  PRAGMA EXCEPTION_INIT(no_dbpart,     -20003);

  procedure AddUpdateDesc (pStr VARCHAR2) is
  begin
    vUpdateDesc := vUpdateDesc || pStr || chr(10);
  exception when small_buffer then 
    vUpdateDesc := vUpdateDesc || case when vUpdateDesc not like '%...' then '....' else '' end;
  end;  

begin 

  vUpdateSchema := RSDU_UPDATE_UTIL_PKG.get_val ('schema_name');
  vUpdateName   := RSDU_UPDATE_UTIL_PKG.get_val ('update_alias');
 
  ----------------------------------
  -- ѕровер€ем наличие шаблонов
  vTableName := 'MEAS_FUNCTION_TEMPLATE';
  tTestName(1) := 'Min2';	  	tTestName(11) := '2';	
  tTestName(2) := 'Max2';       tTestName(12) := '2';	
  tTestName(3) := 'Min3';	  	tTestName(11) := '3';	
  tTestName(4) := 'Max3';       tTestName(12) := '3';	

  for i in 1..4 loop
    nCnt := rsdu_update_util_pkg.CHECK_RECORD_EXISTS ('RSDUADMIN', vTableName, tTestName(i),'ALIAS');

    if nCnt = 0 then 
       nErr := nErr + 1;
    else
       vTxt :='';
       select count(1) into nCnt2 from MEAS_FUNCTION_ARGUMENT 
	  where id_template in (select id from MEAS_FUNCTION_TEMPLATE where alias like tTestName(i));
	if nCnt2 != to_number(tTestName(i+10)) then 
           nErr := nErr + 1;
        end if;
        vTxt := chr(10)||'аргументы: количество'|| (case when nCnt2 != to_number(tTestName(i+10))  then ' не' end || ' соответствует.');
    end if;
    AddUpdateDesc ('шаблон '||tTestName(i)|| case when nCnt = 0 then ' отcутствует.' else ' приcутствует'||vTxt end );
   end loop;

   ---------------------------------------------------------------------------------------------------------
   -- сохранить собранные сведени€ тестировани€:
   update temp_rsdu_update set val = rtrim(ltrim(vUpdateDesc, chr(10)), chr(10)) where name like 'update_desc';
   if nvl (print_result,0) > 0  then 
     RSDU_UPDATE_UTIL_PKG.PrintBigBuffer  (vUpdateDesc); 
     dbms_output.put_line ('updatestate = '|| vUpdateState); 
   end if;

   if nErr = 0 then   
     -- UPD_NONEED - обновление не требуетс€
     update temp_rsdu_update set val = 2 where name like 'update_state';
   else
     update temp_rsdu_update set val = -1 where name like 'update_state';
   end if;
   commit;

   dbms_output.put_line ('--------------------------------------------------------'||chr(10));
  --------------------------------------------------------------------------------------
EXCEPTION 
  WHEN no_preREQUIRED THEN
    raise_application_error (-20001, 'PreREQUIRED обновление '||vUpdateNameREQUIRED||
                                     ' отсутствует, выполните сначала его! ¬ыполнение сценари€ остановлено');
  WHEN no_dbpart THEN
    raise_application_error (-20003, '–аздел отсутствует. ¬ыполнение сценари€ остановлено');

  WHEN OTHERS THEN
    dbms_output.put_line (sqlerrm); 
    raise;
end;
/

show error 

--exec test_rsdu_update_p; 
--select val from temp_rsdu_update;

