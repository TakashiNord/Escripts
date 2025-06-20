# Escripts (Garbage\Мусор)
methods: tcl\tk, bash, python, p-sql, php, lua,  

### **BASH**

+ Oracle-bash\
  + esztab.sh - размер табличного пространства БД Oracle (FROM dba_free_space)
  + eups.sh - получение информации snmpget -Oqv -c public -v 2c и кладем в БД Oracle
  + edfcheck.sh - проверка размера диска и выдача информации о превышении
  + emview.sh \ emview.sql - обновление MVIEWS посредством скрипта 
  + sp.sh - получение process+session из БД Oracle
+ ema (ema.service, ema.timer) - модернизация скрипта ema добавлением serv_list
+ emahlpdsk.sh - service php-fpm , mysqld , nginx , elasticsearch , supervisord restart

### **CMD**

+ apc2.cmd  - plink -pw
+ apc92.cmd \ apc92.txt - выполнение команды через putty.exe -m apc92.txt -ssh

### **Python**

+ pr38-cid2profile\ - конвертация .iid.profile (xml-формат) в json (проект не завершен)
+ pr00-ema_time\ - Script to check time
  + ema_time.sh - Script to check time offset between local system and remote NTP servers
  + ema_time4.sh - fix version
  + ema_time_p.sh - ver 1
  + ema_time_v1.sh - fix error bash-script (ver 1)
  + ema_time_v2.sh - fix error bash-script (ver 2)
+ ema_autoload_rename.py (ema_autoload_rename.png) - выравнивание автозагрузки в glob /etc/init.d/rc*/*
+ emasmget.py - получение статуса сервера от sysmon udp:2003 или acrsvd udp:2005
+ pr43-weather\ - погода
  + eweather.py ( eweat1.json, eweat2.json, eweather.txt ) - получение погоды для обьектов
+ scada_info.py - получение состояния сервиса

### **Tcl\Tk**

+ zvkdgk\ - экспорт из БД MS Sql 'zvkdgk' в SQLite
+ serverApi\ - получение посредством rest api информации от server
+ daDevTcl\ - проект для редактирования DA_DEV_DESC (не завершен)
+ Scada Data GateWay\ - В полуавтоматическом режиме формирует таблицу для файла данных программы "SCADA Data Gateway"
+ pr14-Virtualport\ - создание виртуального прибора(не завершен)
+ pr39-Trim\ - операция trim(name) для колонок в таблице
  + table_trim.cmd \ table_trim.tcl - операция trim(name) для таблиц obj_tree,meas_list,da_dev_desc,da_param,RPT_LST,sys_otyp
  + ema_trim_da_dev.tcl - операция trim(name) для таблицы da_dev_desc
  + ema_trim_da_param.tcl - операция trim(name) для таблицы da_param
  + table_trim_obj_tree_fix.tcl
+ ema_autoload_rename.tcl - выравнивание автозагрузки в glob /etc/init.d/rc*/*
+ Export_dg_from_xls_to_bd\ - экспорт из XLS в таблицу DG
  + dg_export1.tcl , dg_export2.tcl
+ Export_from_Oracle_to_xxxxx\ - различные формы экспорта из Oracle
  + rsduadmin_to_xml.tcl - вывод схемы Oracle rsduadmin в XML-файл.
  + rsduadmin_to_sqlite-simple.tcl - вывод схемы Oracle rsduadmin в SQLite
  + rsduadmin_dg_guid.tcl - получение информации FROM DG_LIST, DG_GROUPS
  + rsduadmin_ast_org_cnt_guid.tcl - получение информации FROM AST_CNT, AST_ORG
  + rsdu2_to_sqlite.tcl - вывод схем Oracle в SQLite
  + rsduadmin_OBJ_EL_PIN.tcl - OBJ_EL_PIN
  + arc_dg_el_(file)_export.tcl - экспорт таблиц схемы DG\EL
  + arc_dg_export.tcl - merge таблиц схемы DG из 2-х БД
  + arc_elphpsau_export.tcl - экспорт таблиц схемы EL\PH\PS\AU
  + auto1.tcl - вывод в файл ?непонятно чего?
  + e_rsdu2-output_dir-1.tcl - вывод в папку out файлов таблиц из вьюшки elreg_list_v
  + e_rsdu2-output_sqlite-1.tcl - вывод в БД SQLite таблиц из вьюшки elreg_list_v
  + ersdu2-output-1.tcl \ ersdu2-output-1.log - вывод содержимого from da_cat da_param
  + e_file_to_csv.tcl \ e_file_to_csv.log - ???обход всех папок,и обьединение в 1.???
  + ELREG_LIST_SOURCE.sql - ....
  + ELREG_LIST_V_EXPORT - экспорт источников из БД 
    ( вывод : имя распределительного устройства - имя секции шин - Краткое имя присоединения - Тип параметра - Полное имя типа параметра - Краткое имя типа параметра - Единица измерения - Точность представления - Источник значений - Параметр источника значений. )
  + ELREG_LIST_V_EXPORT_Excel.tcl - (ELREG_LIST_V_29.xlsx) - экспорт источников из БД на основе excel-файла
  + sql_da_202304.txt - вывод из сборных таблиц в формате = ;Прибор;id;Наименование;Квалификатор;ТИП;НазваниеИсточника;idИсточника;НаименованиеИсточника;
  + sql_el_202304.txt - вывод из сборных таблиц в формате = ;id;АЛИАС/Наименование;Канал;idИсточника;НаименованиеИсточника;
  + obj_tree1.tcl \ obj_tree1.sql - цикличный обход Дерева в таблице. 
+ pr41-rsduadmin_renid\ - замена ID в таблицах Oracle
  + rsduadmin_renid.tcl 
+ pr01-emalogs\ - аккумуляция логов и настроек
  + emalogs1.tcl - аккумуляция логов и настроек
  + emalogsOracle1.tcl- аккумуляция логов и настроек
  + emalogs.sh - аккумуляция логов и настроек
+ Export_PQ.tcl - экспорт значений PQ из одной таблицы в другую (для 1ого Листа, создание INSERT для вставки в OBJ_GENERATOR_PQ)
+ Export_PQ_from_Excel.tcl - чтение 1-го xlsx - файла. получение списка Листов, создание файлов с их именами, в режиме w+

### **Lua**

+ LUA-сборник\
  + ereadfile_to_rsdu.lua \ ereadfile_to_rsdu_out_u_g.txt - чтение файлов посредством Lua (pcall)
  + lua cgk-3.txt   - ДорасчетТС, количество переключений

### **Php**

+ pr42-wasutp.config\
  + wasutp.config.php ( emasm1.py, ewasutp.sh )  - установка сервера в Web-iSMS (конфиг файл, скрипт для cron) 

### **SQL**

+ 2x_positonTC.sql - получение параметров обьединенных через Или,И (ver 1)
+ 2x_positonTC2.sql - получение параметров обьединенных через Или,И (ver 2)
+ Create_Arh_EL_INT30.sql - включение архива интегральный30 на разделе EL
+ Create_DA_arch_TS.sql - включение архива для ТС на всем разделе DA
+ MEASARC_ADD1-Интегральные 1 мин\  - создание архивного профиля
+ MEASARC_ADD1-Усредненные на границе 10 секунд\  - создание архивного профиля
+ MEASARC_ADD2-Усредненные на границе 1 минуты\  - создание архивного профиля
+ MEASARC_ADD-Мгн. на границе 5 секунд - 2 мес\  - создание архивного профиля
+ DA_ARC_ADD\  - создание архивного профиля
+ pr37-check\ - диапазон открытия форсунки
+ RsduSql\ - загрузка данных в MS SQL через bat
+ DBE-сборник\ - скрипты и запросы DBE
+ VS_FORM_double_schema.sql - копирование настроек схемы


--------------------------


--------------------------

