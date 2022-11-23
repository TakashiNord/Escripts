--
declare 
  nerr number;
  nRetVal number;
  nId_TYPE number;

  -- вспомогательная функция - обновление существующей ф-ции дорасчета
  function MEAS_FUNCTION_TEMPLATE_update (pID number, /*pID_TYPE,*/ pNAME VARCHAR2, pALIAS VARCHAR2, /*pN_USE,*/
					 pTEMPLATE_ARGNUM number, pTEMPLATE_HEADER CLOB, pTEMPLATE_CODE CLOB)
    return number 
  is
    nCnt NUMBER;
    nRetval number := 0;
    nOld_ARGNUMS NUMBER;
    cOld_HEADER CLOB;
    cOld_CODE CLOB;
    nOldArgId NUMBER;
    vOldArmName VARCHAR2(255);
    vOldArgAlias VARCHAR2(255);
  begin

  select TEMPLATE_ARGNUM, TEMPLATE_HEADER, TEMPLATE_CODE   
   INTO  nOld_ARGNUMS, cOld_HEADER, cOld_CODE 
   from  MEAS_FUNCTION_TEMPLATE where  ID = pID;
------------------------------------------------------------------------------------------
  update MEAS_FUNCTION_TEMPLATE
  set    TEMPLATE_ARGNUM = pTEMPLATE_ARGNUM, TEMPLATE_HEADER = pTEMPLATE_HEADER, TEMPLATE_CODE = pTEMPLATE_CODE 
  where  ID = pID
  and (TEMPLATE_HEADER not like pTEMPLATE_HEADER or TEMPLATE_CODE not like pTEMPLATE_CODE);
/*  RETURNING  TEMPLATE_ARGNUM, TEMPLATE_HEADER, TEMPLATE_CODE 
  INTO  nTEMPLATE_ARGNUMS, cTEMPLATE_HEADERS, cTEMPLATE_CODES;*/
  nCnt := SQL%ROWCOUNT;
------------------------------------------------------------------------------------------
     if nCnt > 0 then
        dbms_output.put_line ('Updated #'|| pID || ' '||pALIAS|| ' ('||pName||')'); 
        dbms_output.put_line (chr(9)||'Num_Args: old  ='|| nOld_ARGNUMS||',  new  ='|| pTEMPLATE_ARGNUM); 
        dbms_output.put_line (chr(9)||'Headers : old  ='''|| cOld_HEADER||''',  new ='''|| pTEMPLATE_HEADER||''''); 
        dbms_output.put_line (chr(9)||'Code  old  :   '); 
        dbms_output.put_line ('--------------------------------------------------------------------------------'); 
        dbms_output.put_line (cOld_CODE); 
        dbms_output.put_line ('--------------------------------------------------------------------------------'); 
        --если менялось тело функции - удалим старые аргументы 
        -----------------------------------------------------------------------------------
        dbms_output.put_line ('deleting old args:');
        FOR rec in (select id FROM MEAS_FUNCTION_ARGUMENT WHERE id_template = pID) LOOP
               --DELETE FROM MEAS_FUNCTION_ARGUMENT WHERE id_template = pID
               DELETE FROM MEAS_FUNCTION_ARGUMENT WHERE id = rec.id
                    RETURNING ID, NAME, ALIAS INTO nOldArgId, vOldArmName, vOldArgAlias;
                dbms_output.put_line ('#'||nOldArgId||' '||vOldArmName||' ('||vOldArgAlias||')');
        END LOOP;         
        -----------------------------------------------------------------------------------
      end if;
    return pID;
  exception when others then 
    nRetval := SQLCODE;
    dbms_output.put_line ('Error #'|| pId || ' '||pName||chr(10)|| SQLERRM);
  end;
      

  -- вспомогательная функция - вставка с проверкой что такого нет еще 
  function MEAS_FUNCTION_TEMPLATE_insert (pID number, pID_TYPE number, pNAME varchar2, pALIAS varchar2, 
                                          pN_USE number, pTEMPLATE_ARGNUM number, 
                                          pTEMPLATE_HEADER CLOB, pTEMPLATE_CODE CLOB)
    return number 
  is
    nCnt    number;
    nNewId  number;
    nRetval number := 0;
  begin
    select count(1) into nCnt from MEAS_FUNCTION_TEMPLATE where upper(name) like upper(pNAME) and upper(alias) like upper(pALIAS);
    if nCnt = 0 then 
      select count (1) into nCnt from MEAS_FUNCTION_TEMPLATE where id = pID;
      nNewID := pId;
      if nCnt = 0 then 
------------------------------------------------------------------------------------------
Insert into MEAS_FUNCTION_TEMPLATE
   (ID, ID_TYPE, NAME, ALIAS, N_USE, TEMPLATE_ARGNUM, TEMPLATE_HEADER, TEMPLATE_CODE) 
 Values
   (nNewID, pID_TYPE, pNAME, pALIAS, pN_USE, pTEMPLATE_ARGNUM, pTEMPLATE_HEADER, pTEMPLATE_CODE);

------------------------------------------------------------------------------------------
        dbms_output.put_line ('');
        dbms_output.put_line ('Added #'|| nNewId || ' '||pName); 
        dbms_output.put_line ('  Num_Args ='|| pTEMPLATE_ARGNUM); 
        nRetval := nNewId;
      else --id is busy
        select MEAS_FUNCTION_TEMPLATE_S.nextval into nNewId from dual;
        nRetval := MEAS_FUNCTION_TEMPLATE_insert (nNewID, pID_TYPE, pNAME, pALIAS, pN_USE, pTEMPLATE_ARGNUM, pTEMPLATE_HEADER, pTEMPLATE_CODE);
      end if;
    else --name and alias already exists
      dbms_output.put_line ('Exists '|| pALIAS || ' ('||pName||')');
      select id into nNewID from MEAS_FUNCTION_TEMPLATE where upper(name) like upper(pNAME) and upper(alias) like upper(pALIAS);
      nRetVal := MEAS_FUNCTION_TEMPLATE_update (nNewID, /*pID_TYPE,*/ pNAME, pALIAS,/* pN_USE,*/ pTEMPLATE_ARGNUM, pTEMPLATE_HEADER, pTEMPLATE_CODE);
    end if;

    return nRetval;
  exception when others then 
    nRetval := SQLCODE;
    dbms_output.put_line ('Error #'|| pId || ' '||pName);
    dbms_output.put_line (' '|| SQLERRM);
  end;
       
  -- вспомогательная функуция - вставка АРГУМЕНТА с проверкой что такого нет еще 
  function MEAS_FUNCTION_ARGUMENT_insert (pID number, pID_TEMPLATE number, pNAME varchar2,
                                          pALIAS varchar2, pARG_POSITION number, pIS_STATIC number)
    return number 
  is
    nCnt    number;
    nNewId  number;
    nRetval number := 0;
  begin
    select count(1) into nCnt from MEAS_FUNCTION_ARGUMENT 
     where id_template = pID_TEMPLATE and arg_position= pARG_POSITION;
    if nCnt = 0 then 
      select count (1) into nCnt from MEAS_FUNCTION_ARGUMENT where id = pID;
      nNewID := pId;
      if nCnt = 0 then 
------------------------------------------------------------------------------------------
Insert into MEAS_FUNCTION_ARGUMENT
   (ID, ID_TEMPLATE, NAME, ALIAS, ARG_POSITION, IS_STATIC)
 Values
   (nNewID, pID_TEMPLATE, pNAME, pALIAS, pARG_POSITION, pIS_STATIC);
------------------------------------------------------------------------------------------
        dbms_output.put_line ('Added Arg'||pARG_POSITION||' #'|| nNewId || ' '||pName); 
        nRetval := nNewId;
      else 
        select MEAS_FUNCTION_ARGUMENT_S.nextval into nNewId from dual;
        nRetval := MEAS_FUNCTION_ARGUMENT_insert (nNewID, pID_TEMPLATE, pNAME, pALIAS, pARG_POSITION, pIS_STATIC);
      end if;
    else 
      dbms_output.put_line ('Exists Arg'||pARG_POSITION||' #'|| nNewId || ' '||pName); 
    end if;

    return nRetval;
  exception when others then 
    nRetval := SQLCODE;
    dbms_output.put_line ('Error Arg'||pARG_POSITION||' #'|| pId || ' '||pName);
    dbms_output.put_line (' '|| SQLERRM);
  end;
       
begin
   dbms_output.enable (100000);

  -- тип формулы - "Пользовательская формула" (id = 2224)
  select id into nId_TYPE from sys_otyp where define_alias like 'OTYP_MEAS_FUNC_USER';


----------------------------------------------------------------------------------------------------------------
  nRetVal := MEAS_FUNCTION_TEMPLATE_insert 
   (151, /*2224*/ nId_TYPE, 'Расчет MIN из двух параметров', 'Min2', 0, 2, 'REG_VAL Min2(REG_BASE *pVal1, REG_BASE *pVal2);', 
'REG_VAL Min2(REG_BASE *pVal1, REG_BASE *pVal2)
{
    ELRSRV_ENV    *pEnv = NULL;
    REG_VAL        RetVal;
    int            current_index;

    pEnv = pVal1->pEnv;
    RetVal.ft = 0;
    current_index = (*pEnv).ret_index; 

    // x=min(1,2)
	if ((*pVal1).rv[current_index].vl < (*pVal2).rv[current_index].vl) {
        RetVal.vl = (*pVal1).rv[current_index].vl ;
	    RetVal.ft = (*pVal1).rv[current_index].ft ;
    } else { 
	    RetVal.vl = (*pVal2).rv[current_index].vl ;
		// status = (a==b)?(a|b):b
	    if (ISZERO((*pVal1).rv[current_index].vl-(*pVal2).rv[current_index].vl))
	       RetVal.ft |= (*pVal1).rv[current_index].ft | (*pVal2).rv[current_index].ft;
		else 
		   RetVal.ft = (*pVal2).rv[current_index].ft ;
	}
	   
    return RetVal;
}'
);

  if nRetval > 0 Then -- это новый ид добавленной записи
---------------- Аргументы функции
    nerr := MEAS_FUNCTION_ARGUMENT_insert (301, /*126*/ nRetval, 'Первый параметр', 'pVal1', 1, 0);
    nerr := MEAS_FUNCTION_ARGUMENT_insert (302, /*126*/ nRetval, 'Второй параметр', 'pVal2', 2, 0);
----------------------------------
  end if;

  dbms_output.put_line (chr(10)); 
  
  
----------------------------------------------------------------------------------------------------------------
  nRetVal := MEAS_FUNCTION_TEMPLATE_insert 
   (152, /*2224*/ nId_TYPE, 'Расчет MAX из двух параметров', 'Max2', 0, 2, 'REG_VAL Max2(REG_BASE *pVal1, REG_BASE *pVal2);', 
'REG_VAL Max2(REG_BASE *pVal1, REG_BASE *pVal2)
{
    ELRSRV_ENV    *pEnv = NULL;
    REG_VAL        RetVal;
    int            current_index;

    pEnv = pVal1->pEnv;
    RetVal.ft = 0;
    current_index = (*pEnv).ret_index; 

    // x=max(1,2)
	if ((*pVal1).rv[current_index].vl > (*pVal2).rv[current_index].vl) {
        RetVal.vl = (*pVal1).rv[current_index].vl ;
	    RetVal.ft = (*pVal1).rv[current_index].ft ;
    } else { 
	    RetVal.vl = (*pVal2).rv[current_index].vl ;
	    // status = (a==b)?(a|b):b
	    if (ISZERO((*pVal1).rv[current_index].vl-(*pVal2).rv[current_index].vl))
	        RetVal.ft |= (*pVal1).rv[current_index].ft | (*pVal2).rv[current_index].ft;	
        else 
	        RetVal.ft = (*pVal2).rv[current_index].ft ;
	}
	   
    return RetVal;
}'
);

  if nRetval > 0 Then -- это новый ид добавленной записи
---------------- Аргументы функции
    nerr := MEAS_FUNCTION_ARGUMENT_insert (303, /*126*/ nRetval, 'Первый параметр', 'pVal1', 1, 0);
    nerr := MEAS_FUNCTION_ARGUMENT_insert (304, /*126*/ nRetval, 'Второй параметр', 'pVal2', 2, 0);
----------------------------------
  end if;

  dbms_output.put_line (chr(10)); 
  
  
----------------------------------------------------------------------------------------------------------------
  nRetVal := MEAS_FUNCTION_TEMPLATE_insert 
--Insert into MEAS_FUNCTION_TEMPLATE (ID, ID_TYPE, NAME, ALIAS, N_USE, TEMPLATE_ARGNUM, TEMPLATE_HEADER, TEMPLATE_CODE) Values
   (153, /*2224*/ nId_TYPE, 'Расчет MIN значения из трех параметров', 'Min3', 0, 3, 'REG_VAL Min3(REG_BASE *pVal1, REG_BASE *pVal2, REG_BASE *pVal3);',
'REG_VAL Min3(REG_BASE *pVal1, REG_BASE *pVal2, REG_BASE *pVal3)
{
    ELRSRV_ENV    *pEnv = NULL;
    REG_VAL        RetVal;
    int            current_index;

    pEnv = pVal1->pEnv;
	RetVal.ft = 0;
    current_index = (*pEnv).ret_index; 

    // x=min(1,2)
	if ((*pVal1).rv[current_index].vl < (*pVal2).rv[current_index].vl) {
        RetVal.vl = (*pVal1).rv[current_index].vl ;
	    RetVal.ft = (*pVal1).rv[current_index].ft ;
    } else { 
	    // status = (a==b)?(a|b):b
	    if (ISZERO((*pVal1).rv[current_index].vl-(*pVal2).rv[current_index].vl))
	       RetVal.ft |= (*pVal1).rv[current_index].ft | (*pVal2).rv[current_index].ft;
		else 
		   RetVal.ft = (*pVal2).rv[current_index].ft ;
	    RetVal.vl = (*pVal2).rv[current_index].vl ;
	}
	
	// =min(x,3)
    if (RetVal.vl >= (*pVal3).rv[current_index].vl) {
	    if (ISZERO(RetVal.vl-(*pVal3).rv[current_index].vl))
	       RetVal.ft |= (*pVal3).rv[current_index].ft;
		else 
           RetVal.ft = (*pVal3).rv[current_index].ft ;		
	    RetVal.vl = (*pVal3).rv[current_index].vl ;
	}	
  
    return RetVal;
}'
);

  if nRetval > 0 Then -- это новый ид добавленной записи
---------------- Аргументы функции
    nerr := MEAS_FUNCTION_ARGUMENT_insert (305, /*127*/ nRetval, 'Первый параметр', 'pVal1', 1, 0);
    nerr := MEAS_FUNCTION_ARGUMENT_insert (306, /*127*/ nRetval, 'Второй параметр', 'pVal2', 2, 0);
    nerr := MEAS_FUNCTION_ARGUMENT_insert (307, /*127*/ nRetval, 'Третий параметр', 'pVal3', 3, 0);
----------------------------------
  end if;


  dbms_output.put_line (chr(10)); 
  
  
----------------------------------------------------------------------------------------------------------------
  nRetVal := MEAS_FUNCTION_TEMPLATE_insert 
--Insert into MEAS_FUNCTION_TEMPLATE (ID, ID_TYPE, NAME, ALIAS, N_USE, TEMPLATE_ARGNUM, TEMPLATE_HEADER, TEMPLATE_CODE) Values
   (154, /*2224*/ nId_TYPE, 'Расчет MAX значения из трех параметров', 'Max3', 0, 3, 'REG_VAL Max3(REG_BASE *pVal1, REG_BASE *pVal2, REG_BASE *pVal3);',
'REG_VAL Max3(REG_BASE *pVal1, REG_BASE *pVal2, REG_BASE *pVal3)
{
    ELRSRV_ENV    *pEnv = NULL;
    REG_VAL        RetVal;
    int            current_index;

    pEnv = pVal1->pEnv;
	RetVal.ft = 0;
    current_index = (*pEnv).ret_index; 

    // x=max(1,2)
	if ((*pVal1).rv[current_index].vl > (*pVal2).rv[current_index].vl) {
        RetVal.vl = (*pVal1).rv[current_index].vl ;
	    RetVal.ft = (*pVal1).rv[current_index].ft ;
    } else { 
	    // status = (a==b)?(a|b):b
	    if (ISZERO((*pVal1).rv[current_index].vl-(*pVal2).rv[current_index].vl))
	       RetVal.ft |= (*pVal1).rv[current_index].ft | (*pVal2).rv[current_index].ft;
		else 
		   RetVal.ft = (*pVal2).rv[current_index].ft ;
	    RetVal.vl = (*pVal2).rv[current_index].vl ;
	}
	
	// =max(x,3)
    if (RetVal.vl <= (*pVal3).rv[current_index].vl) {
	    if (ISZERO(RetVal.vl-(*pVal3).rv[current_index].vl))
	       RetVal.ft |= (*pVal3).rv[current_index].ft;
		else 
           RetVal.ft = (*pVal3).rv[current_index].ft ;
	    RetVal.vl = (*pVal3).rv[current_index].vl ;		   
	}	
  
    return RetVal;
}'
);

  if nRetval > 0 Then -- это новый ид добавленной записи
---------------- Аргументы функции
    nerr := MEAS_FUNCTION_ARGUMENT_insert (308, /*127*/ nRetval, 'Первый параметр', 'pVal1', 1, 0);
    nerr := MEAS_FUNCTION_ARGUMENT_insert (309, /*127*/ nRetval, 'Второй параметр', 'pVal2', 2, 0);
    nerr := MEAS_FUNCTION_ARGUMENT_insert (310, /*127*/ nRetval, 'Третий параметр', 'pVal3', 3, 0);
----------------------------------
  end if;



----------------------------------------------------------------------------------------------------------------

end;
/


COMMIT;



