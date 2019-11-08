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
  -- ����������� id �������� �������-������ �����
  select count(1) into nRetVal from RSDUADMIN.SYS_TBLLST where table_name = '&TblLstName';
  if (nRetVal = 0)
  then
    dbms_output.put_line ('!!! ������ ����������� ID �������-������ ��� '|| '&TblLstName');
	dbms_output.put_line ('!!! ��������� ��� �������. ���������� ������� ����������.');
  else
	
	select max(id)+1 into nID_SYSGTOPT from RSDUADMIN.SYS_GTOPT;
	dbms_output.put_line ('>>> ������� � SYS_GTOPT ������ ���� # '|| nID_SYSGTOPT);
	Insert into RSDUADMIN.SYS_GTOPT (ID, NAME, ALIAS, ID_GTYPE, DEFINE_ALIAS, INTERVAL, ID_ATYPE)
	       Values (nID_SYSGTOPT, '����������� �� ������� 1 ������', '���. 1 ���',1, 'GLT_ANALOG_OPT_AVGMIN1', 60,2);
		   
	select id into nID_TBLLST from RSDUADMIN.SYS_TBLLST where table_name = '&TblLstName';

	select max(id)+1 into nID_ARCGINFO from RSDUADMIN.ARC_GINFO;
	select max(id)+1 into nID_SPROFILE from RSDUADMIN.ARC_SUBSYST_PROFILE;

	dbms_output.put_line ('>>> ������� � ARC_GINFO ������ ���� ������ # '|| nID_ARCGINFO);
	Insert into RSDUADMIN.ARC_GINFO (ID, ID_GTOPT, ID_TYPE, DEPTH, DEPTH_LOCAL, CACHE_SIZE, CACHE_TIMEOUT, FLUSH_INTERVAL, RESTORE_INTERVAL, STACK_INTERVAL, WRITE_MINMAX, RESTORE_TIME, NAME, STATE, DEPTH_PARTITION, RESTORE_TIME_LOCAL)
	       Values (nId_ARCGINFO, nID_SYSGTOPT, 1, 0, 720, 200000, 5, 0, 3600, 300, 1, 720, '&DBArcName', 2, 180, 0);
	
	pARC_PROFILE := 'MEAS_ARC_' || nID_TBLLST || '_' || nId_ARCGINFO;
	dbms_output.put_line ('>>> ������� � ARC_SUBSYST_PROFILE ������ ������� �������: '|| pARC_PROFILE);
	Insert into RSDUADMIN.ARC_SUBSYST_PROFILE (ID, ID_TBLLST, ID_GINFO, IS_WRITEON, STACK_NAME, LAST_UPDATE, IS_VIEWABLE)
		Values (nID_SPROFILE, nID_TBLLST, nID_ARCGINFO, 0, pARC_PROFILE, 0, 1);
	
	dbms_output.put_line ('>>> ������� � ARC_SERVICES_TUNE �������� ��� ������ ������ ������� �������:');
	for rec in (
      select id from ad_service where define_alias like 'ADV_SRVC_DPLOADADCP_ACCESPORT%' order by id asc
     )
     loop
	    nID_PRIORITY := nID_PRIORITY + 1;
		dbms_output.put_line ('>>>    ID_SPROFILE: ' || nID_SPROFILE || '   ID_SERVICE: '|| rec.id || '   PRIORITY: ' || nID_PRIORITY);
        Insert into RSDUADMIN.ARC_SERVICES_TUNE(ID_SPROFILE, ID_SERVICE, PRIORITY)
		       Values (nID_SPROFILE, rec.id, nID_PRIORITY);
     end loop;

	dbms_output.put_line ('>>> ������� � ARC_SERVICES_ACCESS �������� ��� ������ ������ ������� �������:');
	for rec in (
      select id from ad_service where define_alias like 'ADV_SRVC_PHROIC_ACCESPORT%' order by id asc
     )
     loop
		dbms_output.put_line ('>>>    ID_SPROFILE: ' || nID_SPROFILE || '   ID_SERVICE: '|| rec.id || '   RETRO_DEPTH: ' || '86400');
        Insert into RSDUADMIN.ARC_SERVICES_ACCESS(ID_SPROFILE, ID_SERVICE, RETRO_DEPTH)
		       Values (nID_SPROFILE, rec.id, 86400);
     end loop;	 
	 
	 commit;
  end if;
  
  dbms_output.put_line ('===========================================================');
EXCEPTION 
  WHEN OTHERS THEN
	dbms_output.put_line (sqlerrm);
end;
/
