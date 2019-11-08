WHENEVER SQLERROR EXIT 
SET SERVEROUTPUT on
SET feedback on
SET verify off

declare 
  nRetVal number := 0;
  nID_SYSGTOPT number := 0;
  nID_TBLLST number := 0;
  nID_ARCGINFO number := 0;
  nID_SPROFILE number := 0;
  nID_PRIORITY number := 0;
  pARC_PROFILE varchar2(64);
begin
  dbms_output.enable (100000);
  
  dbms_output.put_line ('===========================================================');
  -- определения id заданной таблицы-списка сбора
  select count(1) into nRetVal from RSDUADMIN.SYS_TBLLST where table_name = '&TblLstName';
  if (nRetVal = 0)
  then
    dbms_output.put_line ('!!! Ошибка определения ID таблицы-списка для '|| '&TblLstName');
	dbms_output.put_line ('!!! Проверьте имя таблицы. Выполнение скрипта прекращено.');
  else
	
	select id into nID_TBLLST from RSDUADMIN.SYS_TBLLST where table_name = '&TblLstName';

	select id into nID_ARCGINFO from RSDUADMIN.ARC_GINFO where id=28;
	select max(id)+1 into nID_SPROFILE from RSDUADMIN.ARC_SUBSYST_PROFILE;

	pARC_PROFILE := 'DA_ARC_' || nID_TBLLST || '_' || nId_ARCGINFO;
	dbms_output.put_line ('>>> Вставка в ARC_SUBSYST_PROFILE нового профиля архивов: '|| pARC_PROFILE);
	Insert into RSDUADMIN.ARC_SUBSYST_PROFILE (ID, ID_TBLLST, ID_GINFO, IS_WRITEON, STACK_NAME, LAST_UPDATE, IS_VIEWABLE)
		Values (nID_SPROFILE, nID_TBLLST, nID_ARCGINFO, 0, pARC_PROFILE, 0, 1);
	
	dbms_output.put_line ('>>> Вставка в ARC_SERVICES_TUNE настроек для записи нового профиля архивов:');
	for rec in (
      select id from ad_service where define_alias like 'ADV_SRVC_DPLOADADCP_ACCESPORT%' order by id asc
     )
     loop
	    nID_PRIORITY := nID_PRIORITY + 1;
		dbms_output.put_line ('>>>    ID_SPROFILE: ' || nID_SPROFILE || '   ID_SERVICE: '|| rec.id || '   PRIORITY: ' || nID_PRIORITY);
        Insert into RSDUADMIN.ARC_SERVICES_TUNE(ID_SPROFILE, ID_SERVICE, PRIORITY)
		       Values (nID_SPROFILE, rec.id, nID_PRIORITY);
     end loop;

	dbms_output.put_line ('>>> Вставка в ARC_SERVICES_ACCESS настроек для чтения нового профиля архивов:');
	for rec in (
      select id from ad_service where define_alias like 'ADV_SRVC_DCSOICTCP_ACCESSPORT1' order by id asc
     )
     loop
		dbms_output.put_line ('>>>    ID_SPROFILE: ' || nID_SPROFILE || '   ID_SERVICE: '|| rec.id || '   RETRO_DEPTH: ' || '86400');
        Insert into RSDUADMIN.ARC_SERVICES_ACCESS(ID_SPROFILE, ID_SERVICE, RETRO_DEPTH)
		       Values (nID_SPROFILE, rec.id, 1800);
     end loop;	 
	 
	 commit;
  end if;
  
  dbms_output.put_line ('===========================================================');
EXCEPTION 
  WHEN OTHERS THEN
	dbms_output.put_line (sqlerrm);
end;
/
