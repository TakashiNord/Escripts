set serveroutput on
set trimout on
set linesize 180
set pagesize 1000
/*
**  запускаем сценарий с параметрами:
**  sqlplusw /nolog @main.sql %DBowner% %DBpswd% %DBname% %DBUpdateAlias% 
**  sqlplusw /nolog @main.sql     &1       &2        &3        &4         
*/
define DBowner=&1
define DBpswd=&2
define DBname=&3
define DBUpdateAlias=&4

define DBUpdateName63='Добавление формул дорасчета'
define ApplName63=''

spool &DBUpdateAlias..&DBname..log

conn &DBowner/&DBpswd@&DBname
SET TERMOUT ON

Prompt _____ TEST for update ___________________________________________________________
Prompt
@@test/1_pre_update.sql  &1 &2 &3 &4

-->>> Собственно выполнение обновлений -------------------------------------------------


Prompt
Prompt ___1. Дополнение справочников ____________________________________________________
Prompt
@@data\insert_MEAS_FUNCTION_TEMPLATE.sql



-- Конец выполнения обновлений <<<------------------------------------------------------
Prompt
Prompt _____ Тест и регистрация обновления  ____________________________________________
rem ------------------ @@test/2_post_update.sql

spool off
--pause  НАЖМИТЕ ЛЮБУЮ КЛАВИШУ. То же самое читайте в лог-файле &DBUpdateAlias..log
exit;
