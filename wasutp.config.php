<?php
return array(

    //Конфиг подключения к субд ORACLE
'driver' => 'oci',
    'user' => 'rsduadmin',
    'password' => 'passme',
    'tns' => "(DESCRIPTION =
        (CONNECT_TIMEOUT = 20)(TRANSPORT_CONNECT_TIMEOUT = 20)
        (ADDRESS = (PROTOCOL = TCP)(HOST = rsdudb01vip.rsdu.ses.kolenergo.ru)(PORT = 1521))
        (ADDRESS = (PROTOCOL = TCP)(HOST = rsdudb02vip.rsdu.ses.kolenergo.ru)(PORT = 1521))
        (LOAD_BALANCE = yes)
        (CONNECT_DATA = (SERVER = DEDICATED)
        (SERVICE_NAME = rsdu.rsdu.ses.kolenergo.ru)(FAILOVER_MODE =(TYPE = SESSION)
        (METHOD = BASIC)(RETRIES = 3)(DELAY = 5))))",


    //путь к утилите rtquery - {path}rtquery -c ......
    'path_to_rtquery' => '/usr/bin/',

    //Период обновления схем в миллисекундах
    'schemeUpdatePeriod' => 5000,
//    'schemesTestMode' => true,

    //Период обновления информационных панелей в миллисекундах
    'infoPanelUpdatePeriod' => 5000,
//    'infoPanelTestMode' => true,

    //Период обновления виджетов в миллисекундах
    'widgetUpdatePeriod' => 5000,

    //Период обновления оперативного режима подсистемы сбора в миллисекундах
    'dcsUpdatePeriod' => 5000,

    //подмена ip-адреса, используемого rtquery
    //'replaceIp' => "replace(i.host_addr, i.host_addr,'127.0.0.1')",
    'replaceIp' => "replace(replace(i.host_addr,'10.51.5.','10.51.1.'),'10.51.1.50','10.51.1.55')",
// 'replaceIp' => "10.51.1.55",
    //Тайтл в окне браузера
    'desktopTitle' => "iSMS",

    //Параметры работы логгера (null | serialize | unserialize)
//    'logger' => "serialize",

    //Путь к логам EMA для скачивания
    'pathToEmaLog' => '/var/log/ema/',

    //Путь к логам NTP для скачивания
    'pathToNtpLog' => '/var/log/ema/ntp.log',

    //Путь к логам PHP для скачивания
    'pathToPhpLog' => '/var/log/apache2/error.log',

    //Режим отладки
    'debugMode' => false,

    //Типы параметров для подсистемы сбора
    'paramTypes' => require 'wasutp/wasutp.param-types.php',

    //Допустимые протоколы профилей устройств
    'profileProtos' => require 'wasutp/wasutp.profile-protos.php',

    //Допустимые протоколы профилей устройств настроенных на передачу
    'transferDeviceProtos' => require 'wasutp/wasutp.profile-transfer-protos.php',

    //Допустимые протоколы профилей общих функций
    'functionDeviceProtos' => require 'wasutp/wasutp.profile-function-protos.php',

    //Показывать всплывающие подсказки элементов информационной панели
    'showPanelTips' => true,

    //перечень файлов конфигурации
    'documentation' => require 'wasutp/wasutp.documentation.php',

    //путь к утилите ismsgetstatus    
    'path_to_ismsgetstatus' => '/usr/bin/',

    //Формат времени сервера в трее в правом нижнем углу
    'trayClockFormat' => 'H:i',

    //Ограничение LIMIT для SQL-запросов в SQL-Консоли
    'SQLConsoleLimit' => 1000,

    //Конфиг для GIS
    'gis' => require 'wasutp/wasutp.gis.php',

    //Глобальная надстройка над Ajax
    //Использовать метод GET для всех Ajax-запросов
//    'ajaxMethod' => 'GET',
//    //Дополнительный параметры для всех Ajax-запросов
//    'ajaxAddParams' => array(
//        'XDEBUG_SESSION_START' => 123456,
//    ),

    //Главное меню ISMS
    'menu' => require 'wasutp/wasutp.menu.oracle.php',

    // Логгер
    'logger2' => require 'wasutp/wasutp.logger2.php',

    //Буфферезированный режим таблицы подсистемы сбора
    //Повышает производительность больших таблиц,
    //но отключает сортировку столбцов
//    'bufferedDcsGrid' => true,

    //Режим отладки для отчетов
    //Выводит sql-запрос в окно системных сообщений
//    'reportsDebugMode' => false,

    //Шаблон даты для отображения в таблице отчетов
    'reportDatePattern' => 'd.m.Y H:i:s',

    //Путь к файлу, содержащему информацию о программе (ReleasNotes)
    'aboutProPath' => '/usr/share/doc/webrsdu/ReleaseNotesWebRSDU.txt',

    //Идентификатор пользователя (s_users.id), используемый для работы c предпочтениями
    'preferUserId' => \WASUTP\User\User::getInstance()->getId(),

    //Значение true будет выводить каждый sql-запрос в окно сообщений системы
    'sqlDebugMode' => false,

    //Роль пользователя по умолчанию
    'defaultAclRole' => 'operator-oracle',
    
    // Значение true установит запрет редактирования источников данных
    'disableChangeDatasources' => false,

    //Путь к конфигурационному файлу дорасчета
    'pathToCalcConfig' => '/home/ema/dcs.lua',

    'loginTitlePrefix' => 'Web',

    'enableSldiagramIndex' => true,
);
