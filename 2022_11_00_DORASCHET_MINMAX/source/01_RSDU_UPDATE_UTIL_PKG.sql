CREATE OR REPLACE package RSDUADMIN.RSDU_UPDATE_UTIL_PKG
/******************************************************************************
 Created by Elеna, 16.06.2019

 Пакет утилит для установки обновлений РСДУ

  Modified:
    18.11.2020 - Dina: возможность поиска записи как CaseSensitive, так и без
    11.05.2021 - Dina: добавлены функции проверки прав приложений.
*******************************************************************************
*/
  IS 
  
  cursor c_col (vOWN varchar2, vTAB varchar2, vCOL varchar2)
     is select count(1) from all_tab_columns where owner like vOWN and table_name like vTAB and column_name like vCOL;
  cursor c_obj (vOWN varchar2, vOBJ varchar2, vTYP varchar2)
     is select count(1) from all_objects where owner like vOWN  and object_name like vOBJ and object_type like vTYP;
  cursor c_obj_status (vOWN varchar2, vOBJ varchar2, vTYP varchar2)
     is select status from all_objects where owner like vOWN  and object_name like vOBJ and object_type like vTYP;
  cursor c_src_text (vOWN varchar2, vOBJ varchar2, vTEXT varchar2)
     is select count (1) from all_source where owner like vOWN and name like vOBJ and lower (text) like lower (vTEXT);
  cursor c_upd_state (vDefAlias varchar2)  
     is select id from RSDUADMIN.RSDU_UPDATE_DESC where upper(define_alias) like vDefAlias;
     
  function CHECK_COLUMN_EXISTS (pOwner VARCHAR2, pObjectName VARCHAR2, pColumnName VARCHAR2) return number;
  function CHECK_OBJECT_EXISTS (pOwner VARCHAR2, pObjectName VARCHAR2, pObjectType VARCHAR2) return number;
  function CHECK_OBJECT_STATUS (pOwner VARCHAR2, pObjectName VARCHAR2, pObjectType VARCHAR2) return varchar2;
  function CHECK_SOURCE_TEXT_EXISTS (pSchema VARCHAR2, pObjectName VARCHAR2, pTEXT VARCHAR2) return number;
  function CHECK_RECORD_EXISTS (pSchema VARCHAR2, pTableName VARCHAR2, pDefAlias VARCHAR2, pColName VARCHAR2 default 'DEFINE_ALIAS', pCaseSensitive BOOLEAN default TRUE) return number;
  function CHECK_RECORD_COUNT  (pSchema VARCHAR2, pTableName VARCHAR2, pDefAlias VARCHAR2, pColName VARCHAR2 default 'DEFINE_ALIAS', pCaseSensitive BOOLEAN default TRUE) return number;
  function CHECK_ID_FREE (pSchema VARCHAR2, pTableName VARCHAR2, pID VARCHAR2) return number;
  function CHECK_COLUMN_TYPE (pOwner VARCHAR2, pObjectName VARCHAR2, pColumnText VARCHAR2) return VARCHAR2;
  function CHECK_COLUMN_TYPE2 (pOwner VARCHAR2, pObjectName VARCHAR2, pColumnName VARCHAR2, pColumnTyp VARCHAR2, pColumnLen VARCHAR2, pColumnNullable VARCHAR2 default null) return varchar2;

  function GetUpdateStatus_CurVal (pStr VARCHAR2)  return number;
  function GetUpdateStatus_CurDesc (pStr VARCHAR2)  return varchar2;
  function GetUpdateStatus_ByDefAlias (pDefAlias VARCHAR2) return number;

  procedure TEMP_RSDU_UPDATE_PREPARE;
  procedure TEMP_RSDU_UPDATE_INIT ( 
    pUpdateName varchar2,   -- текстовое наименование обновления "DBUpdateName63" 
    pUpdateAlias varchar2,  -- уникальная символьная метка обновления "DBUpdateAlias"
    pUpdateSchema varchar2 default 'RSDUADMIN',  -- схема, в которой выполняются обновления "DBowner"
    pUpdateServer varchar2 default 'RSDU',       -- алиас подключения к БД "DBname"
    pApplName varchar2     default NULL          -- приложения, на которые влияет обновление "ApplName63"
  );
  function get_val (pStr VARCHAR2)  return varchar2;
  procedure put_val (pName VARCHAR2, pVal  VARCHAR2);
  procedure add_val (pName VARCHAR2, pVal  VARCHAR2);
  procedure set_val (pName VARCHAR2, pVal  VARCHAR2);

-- вывод подготовленной строки
  procedure PrintBigBuffer (pStr VARCHAR2, pStdLen number default 120);
-- вывод подготовленного поля из таблицы temp_rsdu_update
  procedure PrintBigBuffer2 (pName VARCHAR2, pStdLen number default 120, 
          pStr1 VARCHAR2 default null, pWith1 VARCHAR2 default null, 
          pStr2 VARCHAR2 default null, pWith2 VARCHAR2 default null, 
          pStr3 VARCHAR2 default null, pWith3 VARCHAR2 default null, 
          pStr4 VARCHAR2 default null, pWith4 VARCHAR2 default null 
       );

  procedure Create_Table (pTable VARCHAR2, pScript VARCHAR2, pType VARCHAR2 default 'TABLE');
  procedure Create_Index (pINDEX VARCHAR2, pCond VARCHAR2, pTabSpace VARCHAR2 default 'RSDU_IND');
  procedure Create_Сonstraint (pTable varchar2, pConstr varchar2, pCond varchar2);

-- функция для вычисления максимально возможных прав для подсистемы
  function get_subsyst_max_mask (pID_SUBSYST NUMBER, pID_NABOR number) return NUMBER;
-- функция получения текущей маски приложения
  function get_cur_appl_mask (pID_APPL NUMBER, pID_SUBSYST NUMBER, pID_NABOR number ) return NUMBER;
-- функция для проверки прав приложения
  function check_appl_rights (pId_Appl NUMBER, pID_SUBSYST NUMBER, pMask VARCHAR2, pId_Nabor NUMBER) return NUMBER;

END;
/
CREATE OR REPLACE package body RSDUADMIN.RSDU_UPDATE_UTIL_PKG
 as 

  function CHECK_COLUMN_EXISTS (pOwner VARCHAR2, pObjectName VARCHAR2, pColumnName VARCHAR2) return number is
   nRetVal  number;
  begin
    open c_col (pOwner, pObjectName, pColumnName);
    fetch c_col into nRetVal;
    close c_col;      
    return nRetVal;  
  END;

  function CHECK_OBJECT_EXISTS (pOwner VARCHAR2, pObjectName VARCHAR2, pObjectType VARCHAR2) return number is
   nRetVal  number;
  begin
    open c_obj (pOwner, pObjectName, pObjectType);
    fetch c_obj into nRetVal;
    close c_obj;      
    return nRetVal;  
  END;

  function CHECK_OBJECT_STATUS (pOwner VARCHAR2, pObjectName VARCHAR2, pObjectType VARCHAR2) return varchar2 is 
   vRetVal  varchar2 (255);
  begin
    open c_obj_status (pOwner, pObjectName, pObjectType);
    fetch c_obj_status into vRetVal;
    close c_obj_status;      
    return nvl(vRetVal, 'НЕ СУЩЕСТВУЕТ');  
  END;

  function CHECK_SOURCE_TEXT_EXISTS (pSchema VARCHAR2, pObjectName VARCHAR2, pTEXT VARCHAR2) return number is
   nRetVal  number;
  begin
    open c_src_text (pSchema, pObjectName, pTEXT);
    fetch c_src_text into nRetVal;
    close c_src_text;      
    return nRetVal;  
  END;

 
  function CHECK_RECORD_EXISTS (pSchema VARCHAR2, pTableName VARCHAR2, pDefAlias VARCHAR2, pColName VARCHAR2 default 'DEFINE_ALIAS', pCaseSensitive BOOLEAN default TRUE) return number is
   nRetVal  number;
   nCur     number;
   nErr     number;
   vSql     varchar2(255);
  begin  
    vSql := 'select id from '||pSchema||'.'||pTableName||' where '||
        case when pCaseSensitive then pColName||' like :v'
        else 'upper ('||pColName||') like upper (:v)' end;
    nCur := dbms_sql.open_cursor;
    dbms_sql.parse( nCur, vSql, dbms_sql.NATIVE);
    dbms_sql.bind_variable( nCur, 'v', pDefAlias);
    dbms_sql.define_column( nCur, 1, nRetVal);
    nErr := dbms_sql.execute_and_fetch(nCur);
    dbms_sql.column_value (nCur,  1, nRetVal);
    dbms_sql.close_cursor(nCur);
    return nvl (nRetVal, 0); 
  END;

  function CHECK_RECORD_COUNT (pSchema VARCHAR2, pTableName VARCHAR2, pDefAlias VARCHAR2, pColName VARCHAR2 default 'DEFINE_ALIAS', pCaseSensitive BOOLEAN default TRUE) return number is
   nRetVal  number;
   nCur     number;
   nErr     number;
   vSql     varchar2(255);
  begin  
    vSql := 'select id from '||pSchema||'.'||pTableName||' where '||
        case when pCaseSensitive then pColName||' like :v'
        else 'upper ('||pColName||') like upper (:v)' end;
    nCur := dbms_sql.open_cursor;
    dbms_sql.parse( nCur, vSql, dbms_sql.NATIVE);
    dbms_sql.bind_variable( nCur, 'v', pDefAlias);
    dbms_sql.define_column( nCur, 1, nRetVal);
    nErr := dbms_sql.execute_and_fetch(nCur);
    dbms_sql.column_value (nCur,  1, nRetVal);
    dbms_sql.close_cursor(nCur);
    return nvl (nRetVal, 0); 
  END;

  function CHECK_ID_FREE (pSchema VARCHAR2, pTableName VARCHAR2, pID VARCHAR2) return number is
   nRetVal  number;
   nCur     number;
   nErr     number;
   vSql     varchar2(255);
   cur      cursor_pkg.cursor_type;
  begin  
  -- проверка, что ID свободен (возвращает проверяемый pID, либо новое значение из последовательности, либо max+1 из таблицы)
    if pID is null then 
      vSql := 'select '||pSchema||'.'||pTableName||'_S.nextval from dual where nvl (:v,0) = 0';
    else
      vSql := 'select '||pSchema||'.'||pTableName||'_S.nextval from '||pSchema||'.'||pTableName||' where id = :v';
    end if;
      nCur := dbms_sql.open_cursor;
      dbms_sql.parse( nCur, vSql, dbms_sql.NATIVE);
      dbms_sql.bind_variable( nCur, 'v', nvl(pID,0));
      dbms_sql.define_column( nCur, 1, nRetVal);
      nErr := dbms_sql.execute_and_fetch(nCur);
      dbms_sql.column_value (nCur,  1, nRetVal);
      dbms_sql.close_cursor(nCur);

    if nRetVal is not null then
      nRetVal := CHECK_ID_FREE (pSchema, pTableName, nRetval);
    end if;
    return nvl (nRetVal, pID); 
  EXCEPTION WHEN OTHERS THEN 
     if CHECK_OBJECT_EXISTS (pSchema, pTableName||'_S', 'SEQUENCE') = 0 then
      -- нет сиквенса
        vSql := 'select count (id) from '||pSchema||'.'||pTableName||' where id=:v union select nvl (max(ID),0)+1 from '||pSchema||'.'||pTableName;
       nCur := dbms_sql.open_cursor;
       dbms_sql.parse( nCur, vSql, dbms_sql.NATIVE);
       dbms_sql.bind_variable( nCur, 'v', nvl(pID,0));
       dbms_sql.define_column( nCur, 1, nRetVal);
       nErr := dbms_sql.execute_and_fetch(nCur);
       dbms_sql.column_value (nCur,  1, nRetVal);
         if nRetVal = 0  and  not nvl(pID,0) = 0 then 
          nRetVal := pID;
         else
          nErr := dbms_sql.FETCH_ROWS(nCur);
          dbms_sql.column_value (nCur,  1, nRetVal);
         end if;
       dbms_sql.close_cursor(nCur);
       return nRetVal; 
     elsif CHECK_OBJECT_EXISTS (pSchema, pTableName, 'TABLE') = 0 then
      -- нет самой таблицы
      dbms_output.put_line ('ОШИБКА! '||pSchema||'.'||pTableName||' не существует!');
     elsif CHECK_COLUMN_EXISTS (pSchema, pTableName, 'ID') = 0 then
      -- нет самой таблицы
      dbms_output.put_line ('ОШИБКА! '||pSchema||'.'||pTableName||': поле "ID" не существует!');
     else raise;
    end if;
  end;

  function CHECK_COLUMN_TYPE (pOwner VARCHAR2, pObjectName VARCHAR2, pColumnText VARCHAR2) return VARCHAR2 is
   vName varchar2(255);
   vType    varchar2(255);
   vLength  varchar2(255);
   vNotNULL varchar2(255);
   vStr     varchar2(1024);
   vRetval  varchar2(1024);
  begin
   if upper (pColumnText) like 'NOT NULL' then
     vNotNULL := 'NOT NULL';
     vStr  := ltrim (rtrim (substr (pColumnText, 1, instr (upper(pColumnText),vNotNULL, 1,1) -1)));
   else    
     vStr  := ltrim (rtrim (pColumnText));
   end if;
   if vStr like '%(%' then
     vLength := ltrim (rtrim (substr (vStr, instr (vStr,'(', 1,1))));
     vStr := ltrim (rtrim (substr (vStr, 1, instr (vStr,'(', 1,1) -1)));
   end if;
   vTYPE := ltrim (rtrim (substr (vStr, instr (vStr,' ', 1,1)+1)));
   vNAME := ltrim (rtrim (substr (vStr, 1, instr (vStr,' ', 1,1) -1)));
   vRetval := RSDU_UPDATE_UTIL_PKG.CHECK_COLUMN_TYPE2 (pOwner, pObjectName, vName, vType, vLength, vNotNull);
 
   return vRetval;
  end;
  
  
  function CHECK_COLUMN_TYPE2 (pOwner VARCHAR2, pObjectName VARCHAR2, pColumnName VARCHAR2, pColumnTyp VARCHAR2, pColumnLen VARCHAR2, pColumnNullable VARCHAR2 default null) return VARCHAR2 is
    cursor c_col_type (pOWN varchar2, pTAB varchar2, pCOL varchar2)
     is select  
      column_name col, data_type as typ,
      replace ('('|| 
       case   
       when char_used is not null then to_char (char_length) || decode (char_used,'C',' CHAR', '')
       when char_col_decl_length = 4000 then ''
       when data_precision > 0  then replace (data_precision||','||data_scale, ',0')
       when DATA_TYPE like 'RAW' then to_char (data_length)
       else ''
       end 
     ||')', '()') as  len,
     decode (nullable, 'N', 'NOT NULL','') nullable
    from all_tab_columns t where owner like pOwn 
    and table_name like pTab
    and column_name like pCol;
    rec  c_col_type%ROWTYPE;
    vRetval varchar2 (255);
  begin
  
    open c_col_type (pOwner, pObjectNAme, pColumnName);
    fetch c_col_type into rec;
    close c_col_type; 
    vRetval := rtrim (rec.col||' '|| rec.typ||' '||rec.len||' '||rec.nullable);
    return vRetVal;  
  
  end;

  function GetUpdateStatus_CurVal (pStr VARCHAR2) return number is
    cursor c1 is  select state from rsdu_update where define_alias like pStr;
    retval number;
  begin
    open c1;
    fetch c1 into retval;
    close c1;
    return retval;
  end;  

  function GetUpdateStatus_CurDesc (pStr VARCHAR2) return varchar2 is
    cursor c1 is  select description from rsdu_update where define_alias like pStr;
    retval varchar2 (2000 char);
  begin
    open c1;
    fetch c1 into retval;
    close c1;
    return retval;
  end;  

  function GetUpdateStatus_ByDefAlias (pDefAlias VARCHAR2) return number is
   nRetVal  number;
   cursor c1 is select id from RSDU_UPDATE_DESC where upper(define_alias) like pDefAlias;
  begin  
    open c1;
    fetch c1 into nRetVal;
    close c1;
    return nvl (nRetVal, -999); 
  END;

  procedure TEMP_RSDU_UPDATE_PREPARE 
  IS
  -- Проверка, что есть таблица регистрации обновлений: если нет - выдаем ошибку. 
  -- Чистим вспомогательную таблицу обновлений, если ее нет - создаем.
  nCnt number;
  begin 
    nCnt := RSDU_UPDATE_UTIL_PKG.CHECK_OBJECT_EXISTS ('RSDUADMIN', 'RSDU_UPDATE', 'TABLE');
    if nCnt = 0 then 
      raise_application_error (-20003, 'Отсутствует обновление 2008_03_13_RSDU_UPDATE, выполните сначала его!');
    end if;
   
    nCnt := RSDU_UPDATE_UTIL_PKG.CHECK_OBJECT_EXISTS ('RSDUADMIN', 'TEMP_RSDU_UPDATE', 'TABLE');
    if nCnt = 0 then 
      execute immediate 'CREATE TABLE TEMP_RSDU_UPDATE (NAME VARCHAR2(255 CHAR),VAL VARCHAR2(2000 CHAR))';
    else 
      execute immediate 'TRUNCATE TABLE TEMP_RSDU_UPDATE';
    end if;  
  end;

  procedure TEMP_RSDU_UPDATE_INIT ( 
    pUpdateName   varchar2,  -- текстовое наименование обновления "DBUpdateName63" 
    pUpdateAlias  varchar2,  -- уникальная символьная метка обновления "DBUpdateAlias"
    pUpdateSchema varchar2 default 'RSDUADMIN',  -- схема, в которой выполняются обновления "DBowner"
    pUpdateServer varchar2 default 'RSDU',       -- алиас подключения к БД "DBname"
    pApplName varchar2     default NULL          -- приложения, на которые влияет обновление "ApplName63"
  )
  IS
   nRetVal  number;
   nCur     number;
   nErr     number;
   vSql     varchar2(255);
  begin  
    vSql := 'insert into TEMP_RSDU_UPDATE (name, val) values (:v1, :v2)';
    nCur := dbms_sql.open_cursor;
    dbms_sql.parse( nCur, vSql, dbms_sql.NATIVE);
    dbms_sql.bind_variable( nCur, 'v1', 'update_name');
    dbms_sql.bind_variable( nCur, 'v2', pUpdateName);
    nErr := dbms_sql.execute(nCur);
    dbms_sql.bind_variable( nCur, 'v1', 'update_alias');
    dbms_sql.bind_variable( nCur, 'v2', pUpdateAlias);
    nErr := dbms_sql.execute(nCur);
    dbms_sql.bind_variable( nCur, 'v1', 'schema_name');
    dbms_sql.bind_variable( nCur, 'v2', pUpdateSchema);
    nErr := dbms_sql.execute(nCur);
    dbms_sql.bind_variable( nCur, 'v1', 'server_name');
    dbms_sql.bind_variable( nCur, 'v2', pUpdateServer);
    nErr := dbms_sql.execute(nCur);
    dbms_sql.bind_variable( nCur, 'v1', 'appl_name');
    dbms_sql.bind_variable( nCur, 'v2', pApplName);
    nErr := dbms_sql.execute(nCur);
    dbms_sql.bind_variable( nCur, 'v1', 'update_desc');
    dbms_sql.bind_variable( nCur, 'v2', '');
    nErr := dbms_sql.execute(nCur);
    dbms_sql.bind_variable( nCur, 'v1', 'update_state');
    dbms_sql.bind_variable( nCur, 'v2', '');
    nErr := dbms_sql.execute(nCur);
    dbms_sql.close_cursor(nCur);
    commit;
  exception when others then
    if dbms_sql.is_open (nCur) then 
      dbms_sql.close_cursor(nCur);
    end if;
    raise;
  end;

  function get_val (pStr VARCHAR2)  return varchar2 is
    cursor c1 is  select val from temp_rsdu_update where name like pStr;
    retval varchar2 (2000);
  begin
    open c1;
    fetch c1 into retval;
    close c1;
    return retval;
  end;  

  procedure put_val ( 
    pName varchar2,  -- наименование записи
    pVal varchar2    -- текст записи
  )
  IS
   nRetVal  number;
   nCur     number;
   nErr     number;
   vSql     varchar2(255);
  begin  
    vSql := 'insert into TEMP_RSDU_UPDATE (name, val) values (:v1, :v2)';
    nCur := dbms_sql.open_cursor;
    dbms_sql.parse( nCur, vSql, dbms_sql.NATIVE);
    dbms_sql.bind_variable( nCur, 'v1', pName);
    dbms_sql.bind_variable( nCur, 'v2', pVal);
    nErr := dbms_sql.execute(nCur);
    dbms_sql.close_cursor(nCur);
--    commit;  -- это делает вызывающая программа
  exception when others then
    if dbms_sql.is_open (nCur) then 
      dbms_sql.close_cursor(nCur);
    end if;
    raise;
  end;

  procedure add_val ( 
    pName varchar2,  -- наименование записи
    pVal varchar2    -- текст записи
  )
  IS
   nRetVal  number;
   nCur     number;
   nErr     number;
   vSql     varchar2(255);
  begin  
    vSql := 'update TEMP_RSDU_UPDATE set val = val || :v1 where name like :v2';
    nCur := dbms_sql.open_cursor;
    dbms_sql.parse( nCur, vSql, dbms_sql.NATIVE);
    dbms_sql.bind_variable( nCur, 'v1', pVal);
    dbms_sql.bind_variable( nCur, 'v2', pName);
    nErr := dbms_sql.execute(nCur);
    dbms_sql.close_cursor(nCur);
--    commit;  -- это делает вызывающая программа
  exception when others then
    if dbms_sql.is_open (nCur) then 
      dbms_sql.close_cursor(nCur);
    end if;
    raise;
  end;

  procedure set_val ( 
    pName varchar2,  -- наименование записи
    pVal varchar2    -- текст записи
  )
  IS
   nRetVal  number;
   nCur     number;
   nErr     number;
   vSql     varchar2(255);
  begin  
    vSql := 'update TEMP_RSDU_UPDATE set val = :v1 where name like :v2';
    nCur := dbms_sql.open_cursor;
    dbms_sql.parse( nCur, vSql, dbms_sql.NATIVE);
    dbms_sql.bind_variable( nCur, 'v1', pVal);
    dbms_sql.bind_variable( nCur, 'v2', pName);
    nErr := dbms_sql.execute(nCur);
    dbms_sql.close_cursor(nCur);
--    commit;  -- это делает вызывающая программа
  exception when others then
    if dbms_sql.is_open (nCur) then 
      dbms_sql.close_cursor(nCur);
    end if;
    raise;
  end;

-- вывод подготовленной строки 
  procedure PrintBigBuffer (pStr VARCHAR2, pStdLen number default 120) is
    vStr1  VARCHAR2 (255);
    cur cursor_pkg.cursor_type;
    Cursor c1 (pLEN number) is 
-- есть длинная строка - которую нужно разбить на строчки по N символов, не разбивая слова.
    select trim(regexp_substr(s,'(.{0,99}(\s|$))|[^[:space:]]{'||pLEN||'}',1,level))
    from (select pStr s from dual) t
    CONNECT BY
     regexp_substr(s,'(.{0,99}(\s|$))|[^[:space:]]{'||pLEN||'}',1,level) is not null;
  begin

    open c1 (pStdLen);
     loop
     fetch c1 into vStr1;
     exit when c1%notfound;
      if vStr1 = chr(10) then 
        dbms_output.put (vStr1);
      else
        dbms_output.put_line (substr (vStr1, 1, length (vStr1) -1));
      end if;
     end loop; 

  end;  

-- вывод подготовленного поля из таблицы temp_rsdu_update
  procedure PrintBigBuffer2 (pName VARCHAR2, pStdLen number default 120, 
          pStr1 VARCHAR2 default null, pWith1 VARCHAR2 default null,  -- паттерны, что на что заменить
          pStr2 VARCHAR2 default null, pWith2 VARCHAR2 default null, 
          pStr3 VARCHAR2 default null, pWith3 VARCHAR2 default null, 
          pStr4 VARCHAR2 default null, pWith4 VARCHAR2 default null 
       ) is
    vStr1  VARCHAR2 (255);
    cur cursor_pkg.cursor_type;
    Cursor c1 (pLEN number) is 
-- есть длинная строка - которую нужно разбить на строчки по N символов, не разбивая слова.
    select trim(regexp_substr(s,'(.{0,99}(\s|$))|[^[:space:]]{'||pLEN||'}',1,level))
    from (select replace (replace (replace (replace (val, nvl (pStr1, '?'),nvl (pStr1, '?')),
                nvl (pStr2, '?'),nvl (pStr2, '?')), nvl (pStr3, '?'),nvl (pStr3, '?')), nvl (pStr4, '?'),nvl (pStr4, '?')) s 
              from temp_rsdu_update where name like pName) t  -- вывод поля 
    CONNECT BY
     regexp_substr(s,'(.{0,99}(\s|$))|[^[:space:]]{'||pLEN||'}',1,level) is not null;
  begin

    open c1 (pStdLen);
     loop
     fetch c1 into vStr1;
     exit when c1%notfound;
      if vStr1 = chr(10) then 
        dbms_output.put (vStr1);
      else
        dbms_output.put_line (substr (vStr1, 1, length (vStr1) -1));
      end if;
     end loop; 

  end;  

  procedure Create_Table (pTable VARCHAR2, pScript VARCHAR2, pType VARCHAR2 default 'TABLE') is
    pText  VARCHAR2 (255);
    pText2 VARCHAR2 (255);
  begin 
    
    pText := case when upper (pType) like 'TABLE' then 'Таблица '   
                  when upper (pType) like 'VIEW'  then 'Представление '
                  else  pType||' '
                  end; 

    execute immediate pScript;
    pText2:= case when upper (pType) like 'TABLE' then ' создана.'   
                  when upper (pType) like 'VIEW'  then ' создано.'
                  else ' создан(а).'
                  end; 
    dbms_output.put_line (pText||pTABLE||pText2);
  exception when others then
    if sqlcode = -955 then 
      dbms_output.put_line (pText||pTABLE||' уже существует.');
    else 
      dbms_output.put_line (pText||pTABLE||': ошибка при создании '||sqlerrm);
    end if;
  end; 

  procedure Create_Index (pINDEX VARCHAR2, pCond VARCHAR2, pTabSpace VARCHAR2 default 'RSDU_IND') is
  begin 
    execute immediate 'create index '||pINDEX||' '||pCond||' TABLESPACE '||pTabSpace;
    dbms_output.put_line ('Индекс '||pINDEX||' добавлен.');
  exception when others then 
    if sqlcode = -955 then 
      dbms_output.put_line ('Индекс '||pIndex||' уже существует.');
    else 
      dbms_output.put_line ('Индекс '||pIndex||': ошибка при создании '||sqlerrm);
    end if;
  end; 

  procedure Create_Сonstraint (pTable varchar2, pConstr varchar2, pCond varchar2)
   is 
  begin 
    execute immediate 'alter table '||pTable||' ADD CONSTRAINT '||pConstr||' '||pCond;
    dbms_output.put_line ('Ограничение '||pConstr||' добавлено.');
  exception when others then 
    if sqlcode in (-2260, -2261, -2264, -2275) then 
      dbms_output.put_line ('Ограничение '||pConstr||' уже существует.');
    else 
      dbms_output.put_line ('Ограничение '||pConstr||': ошибка при создании '||sqlerrm);
    end if;
  end; 

  -- функция для вычисления максимально возможных прав для подсистемы
  function get_subsyst_max_mask (pID_SUBSYST NUMBER, pID_NABOR number) return NUMBER
   is
    nMaxMask NUMBER;
    nCur     number;
    nErr     number;
    vSql     varchar2(255);

  begin

    vSql := 'select sum(VALUE) from s_rights where ID_SUBSYST = :p1 and ID_NABOR = :p2';
    nCur := dbms_sql.open_cursor;
    dbms_sql.parse( nCur, vSql, dbms_sql.NATIVE);
    dbms_sql.bind_variable( nCur, 'p1', pID_SUBSYST);
    dbms_sql.bind_variable( nCur, 'p2', pID_NABOR);
    dbms_sql.define_column( nCur, 1, nMaxMask);
    nErr := dbms_sql.execute_and_fetch(nCur);
    dbms_sql.column_value (nCur,  1, nMaxMask);
    dbms_sql.close_cursor(nCur);
    return nvl (nMaxMask, 0); 

   exception when others then return 0;
  end;
  
  -- функция получения текущей маски приложения
  function get_cur_appl_mask (pID_APPL NUMBER, pID_SUBSYST NUMBER, pID_NABOR number ) return NUMBER
   is
    nCurMask NUMBER;
    nCur     number;
    nErr     number;
    vSql     varchar2(255);
  begin
  
    vSql := 'select stand_mask from sys_app_ssyst where ID_APPL = :p1 and ID_SUBSYST = :p2';
    vSql := replace (vSql, 'stand_mask', case when pID_NABOR=2 then 'ext_mask' when pID_NABOR=3 then 'user_mask' else 'ERROR' end);
    if not vSql like '%ERROR%' then 
      nCur := dbms_sql.open_cursor;
      dbms_sql.parse( nCur, vSql, dbms_sql.NATIVE);
      dbms_sql.bind_variable( nCur, 'p1', pID_APPL);
      dbms_sql.bind_variable( nCur, 'p2', pID_SUBSYST);
      dbms_sql.define_column( nCur, 1, nCurMask);
      nErr := dbms_sql.execute_and_fetch(nCur);
      dbms_sql.column_value (nCur,  1, nCurMask);
      dbms_sql.close_cursor(nCur);
    end if;
    return nvl (nCurMask, 0); 
  
   exception when others /*NO_DATA_FOUND*/ then return 0;
  end;

  -- функция для проверки прав приложения.
/* Если маска полностью совпадает с текущей - возвращает 3 
   если все указанные биты установлены, но маски отличаются - 2
   не все биты из указанных установлены - 1
   ни один из указанных - 0
   если указанная маска превышает максимально возможную для данной подсистемы - возвращает -1
*/
  function check_appl_rights (pId_Appl NUMBER, pID_SUBSYST NUMBER, pMask VARCHAR2, pId_Nabor NUMBER) return NUMBER
  is
     nMask NUMBER;
     nCurMask NUMBER;
     nMaxMask NUMBER;
     res number :=0;
  
  begin
    
     nMask := to_number(pMask);
      
    --проверка на превышение макс.маски
     nMaxMask := get_subsyst_max_mask(pID_SUBSYST, pId_Nabor);
        if nMaxMask > 0 and nMask > nMaxMask then
            return  -1; --проверяемая маска больше максимальной для данной подсистемы и i-го набора 
        end if; 
    
    --получаем текущую маску приложения 
    nCurMask :=  get_cur_appl_mask (pID_APPL , pID_SUBSYST, pId_Nabor );
    
    --сравниваем указанную и текущую маски
        if nMask = nCurMask then
           return 3; --exact match 
        else       
         res := bitand (nMask, nCurMask);
         if res = nMask then return 2;-- такие права уже есть
         elsif res=0    then return 0; -- таких прав у приложения нет
         else return 1; --права есть частично
         end if; 
       end if; 
    
  exception when others then return SQLCODE;
  end;

END;
/
--SHOW ERROR

CREATE OR REPLACE PUBLIC SYNONYM RSDU_UPDATE_UTIL_PKG FOR RSDUADMIN.RSDU_UPDATE_UTIL_PKG;
GRANT EXECUTE ON RSDU_UPDATE_UTIL_PKG TO BASE_STAND_ADMIN;
