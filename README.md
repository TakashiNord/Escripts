# Escripts (Garbage\Мусор)
methods: tcl\tk, bash, python, sql, c, php, lua,  

### **BASH**

+ esztab.sh - размер табличного пространства БД Oracle (FROM dba_free_space)
+ eups.sh - получение информации snmpget -Oqv -c public -v 2c и кладем в БД Oracle
+ edfcheck.sh - проверка размера диска и выдача информации о превышении
+ ema \ ema.service \ ema.timer - модернизация скрипта ema добавлением serv_list
+ emahlpdsk.sh - service php-fpm , mysqld , nginx , elasticsearch , supervisord restart
+ emalogs.sh - аккамуляция логов и настроек
+ emview.sh \ emview.sql - обновление MVIEWS посредством скрипта 
+ sp.sh - получение process+session из БД Oracle

### **CMD**

+ apc2.cmd  - plink -pw
+ apc92.cmd \ apc92.txt - выполнение команды через putty.exe -m apc92.txt -ssh

### **Python**

+ pr38-cid2profile\
+ ema_time.sh
  + ema_time4.sh
  + ema_time_p.sh
  + ema_time_v1.sh
  + ema_time_v2.sh
+ ema_autoload_rename.png \ ema_autoload_rename.py
+ emasm1.py
+ emasmget.py
+ eweat1.json \ eweat2.json \ eweather.py \ eweather.txt

### **Tcl\Tk**

+ zvkdgk\ - экспорт из БД MS Sql 'zvkdgk' в SQLite
+ serverApi\ - получение посредством rest api информации от server
+ output_ELREG_LIST_V\ - вывод : имя распределительного устройства - имя секции шин - Краткое имя присоединения - Тип параметра - Полное имя типа параметра - Краткое имя типа параметра - Единица измерения - Точность представления - Источник значений - Параметр источника значений.
+ dgexp2\ - экспорт их XLS в таблицу DG
+ daDevTcl\ - проект для редактирования DA_DEV_DESC (не завершен)
+ Scada Data GateWay\ - В полуавтоматическом режиме формирует таблицу для файла данных программы "SCADA Data Gateway"
+ pr14-Virtualport\ - операция trim(name) для таблицы da_dev_desc
+ table_trim.cmd \ table_trim.tcl - операция trim(name) для таблиц obj_tree,meas_list,da_dev_desc,da_param,RPT_LST,sys_otyp
+ ema_trim_da_dev.tcl - операция trim(name) для таблицы da_dev_desc
+ ema_trim_da_param.tcl - операция trim(name) для таблицы da_param
+ ema_autoload_rename.tcl - выравнивание автозагрузки в glob /etc/init.d/rc*/*
+ e_file_to_csv.tcl \ e_file_to_csv.log - 
+ arc_dg_el_(file)_export.tcl - экспорт таблиц схемы DG\EL
+ arc_dg_export.tcl - merge таблиц схемы DG из 2-х БД
+ arc_elphpsau_export.tcl - экспорт таблиц схемы EL\PH\PS\AU
+ auto1.tcl - вывод в файл ?непонятно чего?
+ rsduadmin_to_xml.tcl - вывод схемы Oracle rsduadmin в XML-файл.
+ rsduadmin_to_sqlite-simple.tcl - вывод схемы Oracle rsduadmin в SQLite
+ rsduadmin_dg_guid.tcl - получение информации FROM DG_LIST, DG_GROUPS
+ rsduadmin_ast_org_cnt_guid.tcl - получение информации FROM AST_CNT, AST_ORG
+ rsdu2_to_sqlite.tcl - вывод схем Oracle в SQLite
+ ersdu2-output-1.tcl \ ersdu2-output-1.log - вывод содержимого from da_cat da_param
+ rsduadmin_renid.tcl - замена ID в таблицах Oracle
+ tclExcelPQ.tcl - чтение 1-го xlsx - файла. для 1ого Листа, создание INSERT для вставки в OBJ_GENERATOR_PQ
+ tclExcel.tcl - чтение 1-го xlsx - файла. получение списка Листов, создание файлов с их именами, в режиме w+
+ e_rsdu2-output_dir-1.tcl - вывод в папку out файлов таблиц из вьюшки elreg_list_v
+ e_rsdu2-output_sqlite-1.tcl - вывод в БД SQLite таблиц из вьюшки elreg_list_v
+ emalogs1.tcl - аккамуляция логов и настроек
+ emalogsOracle1.tcl- аккамуляция логов и настроек

### **Lua**

+ ereadfile_to_rsdu.lua \ ereadfile_to_rsdu_out_u_g.txt - чтение файлов посредством Lua (pcall)
+ lua cgk-3.txt   - ДорасчетТС, количество переключений

### **Php**

+ wasutp.config.php \ ewasutp.sh  - установка сервера в Web-iSMS (конфиг файл, скрипт для cron) 

### **SQL**

+ VirtPribor1.sql - создание Виртуального прибора.
+ 2x_positonTC.sql - получение параметров обьединенных через Или,И (ver 1)
+ 2x_positonTC2.sql - получение параметров обьединенных через Или,И (ver 2)
+ Create_Arh_EL_INT30.sql - включение архива интегральный30 на разделе EL
+ Create_DA_arch_TS.sql - включение архива для ТС на всем разделе DA
+ MEASARC_ADD1-Интегральные 1 мин\  - создание архивного профиля
+ MEASARC_ADD1-Усредненные на границе 10 секунд\  - создание архивного профиля
+ MEASARC_ADD2-Усредненные на границе 1 минуты\  - создание архивного профиля
+ MEASARC_ADD-Мгн. на границе 5 секунд - 2 мес\  - создание архивного профиля
+ DA_ARC_ADD\  - создание архивного профиля
+ 2022_11_00_DORASCHET_MINMAX\ - добавление функций Min2, Max2, Min3, Max3 
+ pr37-check\ - диапазон открытия форсунки
+ RsduSql\ - загрузка данных в MS SQL через bat
+ Dorachet\  - добавление функций Mod, Trunc, Max3, GetTime, AccidentTimeDate, AccidentFrequency0, min10, max10
 
### **С** 

+ ReferenceValue\ - добавление функций AccidentTimeDate и AccidentTime (2016)
 


--------------------------
  eОсновной комплекс ENMAC(324).csv

--------------------------

