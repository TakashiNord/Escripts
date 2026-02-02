set serveroutput on
set trimout on
set linesize 160
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

define DBUpdateName63='Проверка записи в БД'
define ApplName63='test'

set serveroutput on size 80000
set linesize 120
spool &DBUpdateAlias..&DBname..log

conn &DBowner/&DBpswd@&DBname


Prompt _____ TEST for update ___________________________________________________________
Prompt
@@test/1_pre_update.sql  &1 &2 &3 &4

spool off
--pause  НАЖМИТЕ ЛЮБУЮ КЛАВИШУ. То же самое читайте в лог-файле &DBUpdateAlias..log
exit;
