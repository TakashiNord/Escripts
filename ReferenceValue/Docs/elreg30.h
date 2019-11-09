/*  EMA Ltd. 2003 All right...
Заголовочный файл сервера параметров эл. режима / прочих параметров
РСДУ v.2.1.
Взамен ранее используемого фала "elreg30.h"
*/
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
03 февраля 2005 г., Жилеев И.В.: изменена структура ELRSRV_ENV
Добавлено поле:
ServicesLisе - Список имен сервиса основного архивного сервера БД и резервных
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
19 июля 2003 г., Стрельников А.В.: изменена структура ELRSRV_ENV
Для обеспечения возможности контроля целостности БДТИ и БДРВ (задача db_integrity_check):
Добавлено поле db_last_update_time - время последнего обновления БДТИ на момент инициализации задач
Добавлено поле db_last_relink_time - время последнего обновления БДТИ на момент инициализации задач, требующего сборки исполняемого модуля
Добавлено поле db_last_relink_status - статус контроля целостности, требующего сборки исполняемого модуля: 1 - вкл; 0 - откл
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
7 марта 2003 г., Макаренко Е.А.: добавлено объявление новой функции сравнения
структур CALC_STR по channel_id: calc_str_channel_comp.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
6 марта 2003 г., Макаренко Е.А.: модифицирована структура  CALC_STR.
Добавлено поле id srci для хранения ID канала источника "Дорасчет"
(для реализации множественной настройки на источник),
удалено поле  form_id, т.к. оно не использовалось.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
26 февраля 2003г., Макаренко Е.А.: изменены названия некоторых полей структур
(преимущественно списков) с целью придания смысловой нагрузки именам.
Определен новый тип данных PTR_REG_TUNE для создания индексных массивов для
списка структур REG_TUNE по различным полям.
Добавлена функция сравнения reg_tune_my_id_srci_comp для поиска    в массиве 
настроек по id парметра и канала.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
#ifndef __ELREG_21_H
#define __ELREG_21_H

//#pragma pack(1)
#include <sys/sem.h>
#include <pthread.h>

#include <oicdcpi.h>
#include <archdef.h>
#include <calclib.h>
#include <db2const.h>
// [26-08-2011] Morpheus. '#pragma pack' must be after all system includes!
#include "stnoalg.h"

#ifdef E
#define jname   "RSDU Electrical Options Server"
#define JobName "RSDU Electrical Options Server"
#else
#define jname   "RSDU Other Options Server"
#define JobName "RSDU Other Options Server"
#endif

#ifndef ASKD
#ifdef E
#define BASE_ARC                "EL_ARC"
#define BASE_LIST               "EL_REG"
#define BASE_VAL                "EL_VAL"
#define BASE_SOURCE             "EL_SOURCE"
#define BASE_SRC_CHANNEL        "EL_SRC_CHANNEL"
#define BASE_SRC_CHANNEL_TUNE   "EL_SRC_CHANNEL_TUNE"
#define BASE_SRC_CHAN_PAR_KOEF  "EL_SRC_CHAN_PAR_KOEF"
#define BASE_SRC_CHAN_PAR_IND   "EL_SRC_CHAN_PAR_IND"
#define BASE_SRC_CHANNEL_CALC   "EL_SRC_CHANNEL_CALC"
#define BASE_SRC_CHANNEL_MNL    "EL_SRC_CHANNEL_MNL"
#define BASE_SSRC_CHANNEL       "EL_SSRC_CHANNEL"
#define BASE_SSRC_CHANNEL_TUNE  "EL_SSRC_CHANNEL_TUNE"
#define BASE_SSRC_CHAN_PAR_KOEF "EL_SSRC_CHAN_PAR_KOEF"
#define BASE_SSRC_CHANNEL_MNL   "EL_SSRC_CHANNEL_MNL"
#define BASE_SVAL               "EL_SVAL"
#define BASE_EL_DEPENDENT_SVAL  "EL_DEPENDENT_SVAL"
#define BASE_LEV                "EL_LEV"
#else
#define BASE_ARC                "PH_ARC"
#define BASE_LIST               "PH_REG"
#define BASE_VAL                "PH_VAL"
#define BASE_SOURCE             "PH_SOURCE"
#define BASE_SRC_CHANNEL        "PH_SRC_CHANNEL"
#define BASE_SRC_CHANNEL_TUNE   "PH_SRC_CHANNEL_TUNE"
#define BASE_SRC_CHAN_PAR_KOEF  "PH_SRC_CHAN_PAR_KOEF"
#define BASE_SRC_CHAN_PAR_IND   "PH_SRC_CHAN_PAR_IND"
#define BASE_SRC_CHANNEL_CALC   "PH_SRC_CHANNEL_CALC"
#define BASE_SRC_CHANNEL_MNL    "PH_SRC_CHANNEL_MNL"
#define BASE_SSRC_CHANNEL       "PH_SSRC_CHANNEL"
#define BASE_SSRC_CHANNEL_TUNE  "PH_SSRC_CHANNEL_TUNE"
#define BASE_SSRC_CHAN_PAR_KOEF "PH_SSRC_CHAN_PAR_KOEF"
#define BASE_SSRC_CHANNEL_MNL   "PH_SSRC_CHANNEL_MNL"
#define BASE_SVAL               "PH_SVAL"
#define BASE_EL_DEPENDENT_SVAL  "PH_DEPENDENT_SVAL"
#define BASE_LEV                "PH_LEV"
#endif

#else // ASKD

#ifdef E
#define BASE_LIST               "elreg_list_v"
#else
#define BASE_LIST               "phreg_list_v"
#endif

#define BASE_ARC                "meas_arc"
#define BASE_VAL                "meas_val"
#define BASE_SOURCE             "meas_source"
#define BASE_SRC_CHANNEL        "meas_src_channel"
#define BASE_SRC_CHANNEL_TUNE   "meas_src_channel_tune"
#define BASE_SRC_CHAN_PAR_KOEF  "meas_src_chan_par_koef"
#define BASE_SRC_CHAN_PAR_IND   "meas_src_chan_par_ind"
#define BASE_SRC_CHANNEL_CALC   "meas_src_channel_calc"
#define BASE_SRC_CHANNEL_MNL    "meas_src_channel_mnl"
#define BASE_SSRC_CHANNEL       "meas_ssrc_channel"
#define BASE_SSRC_CHANNEL_TUNE  "meas_ssrc_channel_tune"
#define BASE_SSRC_CHAN_PAR_KOEF "meas_ssrc_chan_par_koef"
#define BASE_SSRC_CHANNEL_MNL   "meas_ssrc_channel_mnl"
#define BASE_SVAL               "meas_el_sval"
#define BASE_EL_DEPENDENT_SVAL  "meas_el_dependent_sval"
#define BASE_LEV                "meas_el_lev"
#endif

/* Технологический цикл в комплексе, в секундах */
#ifdef OIC_TECHCYCLE_SEC1
#define TECH_CYCLE         1
#else
#define TECH_CYCLE         5
#endif

#define RETRO_WIDTH              120 /* retro of 120 values for delta=5 sec. */
#define RETRO_HWIDTH             RETRO_WIDTH/2

#define ELR_COMMON_WAIT          (uint16_t)3000
#define ELR_CYCLE_WAIT           (uint16_t)TECH_CYCLE*100 + 20
#define ELR_TI_WAIT              (uint16_t)TECH_CYCLE*100 - 50
#define ELR_DB_WAIT              (uint16_t)3000
#define ELR_UPDDB_WAIT           (uint16_t)6000
#define ELR_ARCWRITE_WAIT        (uint16_t)3000

#define ELRD_MAIN                0x0001
#define ELRD_CONTROL             0x0002
#define ELRD_SERVICE             0x0004
#define ELRD_TECH                0x0008
#define ELRD_NCSCLN              0x0010
#define ELRD_CHECKSRC            0x0040
#define ELRD_RETRO               0x0080
#define ELRD_MVL                 0x0100
#define ELRD_CHECKSET            0x0200
#define ELRD_SAVEINT             0x0400
#define ELRD_DCPSERVICE          0x0800
#define ELRD_UDPSERVICE          0x1000
#define ELRD_SNCSCLN             0x2000
#define ELRD_INTGR_CK            0x4000

#define ELRSRC_MAN               1
#define ELRSRC_CALC              2
#define ELRSRC_OWN               2
#define ELRSRC_GRAPH             3
#define ELRSRC_UTM               4
#define ELUPD_SRC                20
#define ELUPD_MAN                21
#define ELUPD_SET                22
#define ELUPD_PROP               23
#define ELUPD_SET_SRC            24
#define ELUPD_SET_MANUAL         25

#define ELDATA_SAVE              26
#define ELDATA_READ              27

#define ELRF_VALUENOCORRECT      OIC_DST_VALUENOCORRECT /* Данные не достоверны */
#define ELRF_SRCNOPRESENT        OIC_DST_NOPRESENT      /* Источник данных отсутствует */
#define ELRF_DERATING            OIC_DST_DERATING       /* Нарушены уставки */
#define ELRF_ADERATING           OIC_DST_ADERATING      /* Нарушение аварийных уставок */
#define ELRF_HYST_PERIOD         OIC_DST_HYST_PERIOD    /* Выход за уставки по диапазону но не по времени для уставок с заданным HYST_PERIOD */
#define ELRF_NOSCANNED           OIC_DST_NOSCANNED      /* Значение не было опрошено источником например по причине того что параметр выведен из работы */

#define ELRF_ALLCORRECT          (~(ELRF_VALUENOCORRECT | ELRF_SRCNOPRESENT | ELRF_DERATING | ELRF_ADERATING))
#define check_valid(ft)          (ft & (ELRF_VALUENOCORRECT | ELRF_SRCNOPRESENT))
#define ELRF_CALCINT_STATE       (ARC_FTR_CALC_ABS | ARC_FTR_CALC_SIGN | ARC_FTR_CALC_INPUT | ARC_FTR_CALC_OUTPUT)
#define RETRO_EXTREME_WIDTH      2                      /* Размер ретроспективы для экстремумов */
#define RETRO_EXTREME_CUR        0                      /* Индекс готового значения экстремумов за прошлую рестроспективу */
#define RETRO_EXTREME_RET        1                      /* Индекс текущего вычисляемого значения экстремумов в данной рестроспективу */

#define MVALUE_WIDTH             24
#define RVALUE_WIDTH             12

#define CALC_CORRECT             1
#define CALC_POOR                0
#define CALC_DETERM              1
#define CALC_NODETERM            0

#define REG_VAL                  RET_VAL
#define REG_TIME                 RET_TIME
#define MVL_TASK_PARAM           1000

#define MAX_PARAM_VALUE          99999999999999.0
#define MIN_PARAM_VALUE         -MAX_PARAM_VALUE

#define ELR_UPD_DATAMBX_TYPE     1

typedef struct START_PARAMS
{
    void *pEnv;
    void *pParam;
}START_PARAMS;

typedef struct REG_SET
{
    uint32_t    id;
    uint32_t    id_param;
    uint32_t    id_level;
    uint32_t    id_src;
    uint32_t    id_srci;
    uint32_t    notify_period;
    uint32_t    hyst_period;    /* Временной гистерезис для срабатывания уставки*/
    uint32_t    firstbegintime; /* Время первоначального обнаружения выхода за уставки */
    uint32_t    priority;
    uint32_t    start_signal_id;
    uint32_t    cont_signal_id;
    uint32_t    sets_type;
    /*    double              m_min_val;*/      /* Значение уставки по ручному вводу */
    /*    double              m_max_val;  */
    double      min_val;        /* Значение уставки, полученное от источника */
    double      max_val;
    double      min_val_final;  /* Окончательно вычисленное значение уставки, используемое для контроля (например, для косвенных уставок) */
    double      max_val_final;
    uint32_t    val_is_get;     /* Значение уставки было получено от источника (и)*/
    uint32_t    begintime;      /* Время обнаружения выхода за уставки  */
    double      extrem;         /* Экстремальное значение параметра при выходе его за уставки */
    uint32_t    user_id;
    uint32_t    time1970;
} REG_SET;

typedef struct REG_MVL
{
    REG_VAL     mv[MVALUE_WIDTH+1];
    uint32_t    user_id;
    uint32_t    time1970;       /* Метка времени последней 10-минутки (включая "часовую" 10-минутку) */
    uint32_t    time1970_hour;  /* Метка времени последнего часового архива */
    uint32_t    last_hour;      /* Последний записанный час (фактически индекс) */
} REG_MVL;

/* Описание профиля архива интегральных значений */
typedef struct ARC_PROFILE
{
    uint32_t    profile_id;      /* Идентификатор профиля архива, ARC_GINFO */
    uint32_t    gtopt_id;        /* Тип архива, SYS_GTOPT                   */
    uint32_t    arctype;         /* Тип архива: периодический, по изменению */
    uint32_t    interval;        /* Интервал записи архивов                 */
    uint32_t    profile_ftr;     /* Признаки обработки профиля архива       */
    uint32_t    start_calc_integral; /* Признак старта расчета интегрального значения */
    uint32_t    last_arc_time;   /* Время предыдущей записи среза */
    ListType    ArcPoints;       /* Список параметров (REG_BASE или REG_INT), для которых этот тип архива пишется */
    sem_t      *StartArcSem;     /* Для синхронизации с задачей записи архивов */
    pthread_t   ArcTaskId;       /* Идентификатор задачи записи архивов  */
}ARC_PROFILE;

/*****************************************************************/
/* Калинкин С.Ю.
Добавлено 06.12.2002 для описания каналов источника "Оператор"
*/
typedef struct REG_MAN
{
    uint32_t    param_id;   /* ID параметра */
    uint32_t    id_srci;    /* ID канала настройки источника "Оператор" */
    double      m_val;      /* Manual input value */
    double      m_disper;   /* Manual input accuracy */
    uint32_t    m_state;    /* Manual input state */
} REG_MAN;

/* Макаренко Е.А.
Добавлено 04.04.2002 для описания каналов источника "Оператор" уставок
*/
typedef struct SET_MANUAL
{
    uint32_t    id_set;     /* ID уставки */
    uint32_t    id_srci;    /* ID канала настройки источника "Оператор" */
    uint32_t    id_src;     /* ID источника "Оператор" */
    double      m_max_val;  /* Manual max input value */
    double      m_min_val;  /* Manual min input value */
    double      m_disper;   /* Manual input accuracy */
    uint32_t    m_state;    /* Manual input state */
} SET_MANUAL;

typedef struct SET_OWN
{
    uint32_t    id_set;     /* ID уставки */
    uint32_t    id_srci;    /* ID канала настройки собственного источника */
    uint32_t    id_src;     /* ID источника = собственный (2) */
    uint32_t    src_id;     /* ID параметра, на который выполнена настройка */
    double      coeff;
} SET_OWN;

/*****************************************************************/
/* 24.02.2005 Яковлев А.В.
Структуры данных для косвенных уставок (зависимого контроля уставок)
*/
typedef struct SET_DEPEND_VALUE
{
    double      cr_value;       /* Значение критерия-уставки */
    double      value_max;      /* Значение верхней границы уставки при данном значении критерия */
    double      value_min;      /* Значение нижней границы уставки при данном значении критерия */
} SET_DEPEND_VALUE;

typedef struct SET_DEPEND
{
    uint32_t    id_set;         /* ID уставки */
    ListType    values;         /* Список соответствий значений уставки значениям критерия */
} SET_DEPEND;

/* Структура для выборки значений из БД с целью дальнейшего разбора */
typedef struct SET_DEPEND_VALUE_DB
{
    uint32_t    id;             /* ID */
    uint32_t    id_set;         /* ID уставки */
    double      cr_value;       /* Значение критерия-уставки */
    double      value_max;      /* Значение верхней границы уставки при данном значении критерия */
    double      value_min;      /* Значение нижней границы уставки при данном значении критерия */
} SET_DEPEND_VALUE_DB;
/*****************************************************************/

typedef struct EXTREME_VALUE
{
    double      min_value;      /* Минимальное значение */
    double      max_value;      /* Максимальное значение */
    uint32_t    min_value_time; /* Время минимального значения */
    uint32_t    max_value_time; /* Время максимального значения */
} EXTREME_VALUE;

typedef struct REG_BASE
{
    uint32_t    id;
    uint32_t    id_node;
    uint32_t    cur_src;        /* Текущий источник значений */
    uint32_t    cur_srci;       /* Текущий канал источника значений */
    uint32_t    c_ft;           /* Current parameter state and feature */
    uint32_t    c_state;        /* Calculate state */
    uint32_t    state;          /* Parameter main feature */
    uint32_t    novalid;        /* 0 - значение параметра корректно, 1 - некорректно (изменено на ноль в силу возникшего математического исключения) */
    uint32_t    set_level_number;   /* Number of set level */
    uint32_t    last_change_time;   /* Last value change time */
    uint32_t    last_valid_value_time;
    double      last_valid_value;   /* No comment */
    double      c_disper;       /* Calculate accuracy */
    double      disper;         /* Current parameter accuracy */

    EXTREME_VALUE   extreme_value[RETRO_EXTREME_WIDTH]; /* Экстремальные значения параметров */
    REG_VAL     rv[RETRO_WIDTH];
    ListType    ivl;   /* Список ListType рассчитываемых интегральных значений REG_INT, отсортировано по интервалу */
    ListType    avr;   /* Список ListType рассчитываемых средних значений REG_AVR, отсортировано по интервалу */
    REG_MVL     mvl;
    REG_SET   (*set)[];
    struct ELRSRV_ENV *pEnv;
}REG_BASE;

/* For calculation task */
typedef void (*CALC_PROC)(REG_BASE *** , uint32_t);

/* 6 марта 2003 г., Макаренко Е.А.: Добавлено поле id srci для хранения идентификатора канала */
typedef struct CALC_STR
{
    uint32_t    channel_id; /* идентификатор канала источника "Дорасчет" */
    uint32_t    param_id;   /* идетификатор параметра */
    CALC_PROC   proc;       /* указатель на функцию вычисления значения */
    REG_BASE  **rb;         /* массив указателей на аргументы функции */
    uint32_t    memb_num;   /* количество аргументов функции */
    int32_t     determ;
} CALC_STR;

typedef struct OI_ELFMT_STR
{
    uint32_t    id_channel;
    uint32_t    id_frmprm;
    uint32_t    arg_index;
    uint32_t    id_param;
} OI_ELFMT_STR;

#define QUERY_YES       1
#define QUERY_NO        0

typedef struct REG_TUNE
{
    uint32_t    my_id;
    uint32_t    src_tbl;    /* ID таблицы-списка источника, на параметр которой выполнена настройка */
    uint32_t    src_id;     /* ID параметра, на который выполнена настройка */
    uint32_t    id_srci;    /* ID канала настройки для выбранного источника */
    double      coeff;
    uint16_t    query;
    REG_BASE   *pRegBase;   /* 3.06.2005 Вагин А.А. ссылка на параметр канала */
    REG_SET    *pRegSet;    /* 28.06.2005 Вагин А.А. ссылка на параметр канала уставок */
} REG_TUNE;

typedef REG_TUNE*   PTR_REG_TUNE;

#define SRC_NONPRESENT  (uint32_t)0
#define SRC_START       (uint32_t)1
#define SRC_CONNECT     (uint32_t)2
#define SRC_READY       (uint32_t)3

#define SRC_MANUAL      (uint32_t)1
#define SRC_CALC        (uint32_t)2
#define SRC_LIST        (uint32_t)4

typedef struct REG_SRC
{
    pthread_t   task_id;
    uint32_t    id_src;
    uint32_t    id_tbllst;
    uint32_t    id_gtopt;
    uint32_t    id_gtype;
    uint32_t    src_state;
    uint32_t    id_proto_type;
    COMM_PORT   query_port;
    COMM_PORT   control_port;
    uint16_t    priority;
    uint32_t    query_fail;
    uint32_t    query_num;
    uint32_t    tune_num;
    REG_TUNE  (*pTuneList)[];       /* основной массив с данными о настройках на источник, отсортированный по id параметра*/
    ListType    SrcAddrList;
    REM_ADDR    CurAddr;            /* Текущий адрес для отправки пакетов */
    ListType    ParamAdd;
    ListType    OicRegList;
} REG_SRC;

/* Константы для поля state (статус клиентов) структуры USR_STRUCT */
#define USR_STATE_READY 0           /* Задача работает */
#define USR_STATE_QUIT  1           /* Задача должна завершиться */

typedef struct USR_STRUCT
{
    uint32_t    id;
    uint32_t    user_id;
    REM_ADDR    rsock;
    COMM_PORT  *pMsgPort;
    pthread_t   task_id;
    uint32_t    state;
    uint32_t    profile_id;         /* ID архивного профиля, в рамках которого работает сервис. ID = 0 - мгновенные значения. */
    time_t      dt_last_getch;      /* Время выдачи клиенту последнего актуального среза данных (в рамках архива с profile_id) */
    ListType    analog;             /* For USR_AN_DATA structure */
    ListType    booll;              /* For USR_BL_DATA structure */
} USR_STRUCT;

#define ACC_STATE_OK    0
#define ACC_STATE_START 0x1
#define ACC_STATE_READY 0x2
#define ACC_STATE_EXIT  0x3

typedef struct ACC_POINT_INFO
{
    uint16_t        type_id;        /* тип интерфейса (DCP,OIC,ADCP)*/
    uint16_t        port_id;        /* порт */
    uint16_t        proto_id;       /* протокол (UDP,TCP,ETH,...)*/
    uint16_t        state;          /* состояние */
    COMM_PORT      *pServicePort;   /* Порт сервиса */
    sem_t          *SyncSem;        /* Синхронизирующий семафор для запуска клиентских задач */
    sem_t          *UserSem;        /* Семафор доступа к списку UserInfo */
    ListType        UserInfo;       /* Список информации о задачах, работающих с клиентами */
    pthread_t       TaskToken;
}ACC_POINT_INFO;

/*Описание сервисов БД*/
typedef struct SERVICE_INFO
{
    char    TNS_NAME[MAX_DOMAIN_NAME_LEN + 1];
    char    SCHEMA_NAME[MAX_DOMAIN_NAME_LEN + 1];
} SERVICE_INFO;

/* в структуру добавлены поля DCP_CurUser, DCP_CurPass 30.01.2004 Кранчев Д.Ф. */
typedef struct ELRSRV_ENV
{
    uint32_t        UserID;         /* My uid*/
    uint32_t        GroupID;        /* My gid*/
    uint32_t        MyServerID;     /* My server ID from table ac_serv */
    uint32_t        MySignalServiceUserID;      /* My signal subsystem uid*/
    uint32_t        MyLstTableID;               /* My list table id on sys_tbl*/
    uint32_t        MyDirTableID;               /* My directory table id on sys_tbl*/
    unsigned char   UserAlias[MAX_LOGIN_LEN];   /* My login name */
    unsigned char   password[MAX_PASSWD_LEN];   /* My password */
    char            LogFilePath[MAX_PATH_LEN];  /* Full path for .log file */
    char            LogFileName[MAX_PATH_LEN];  /* Full path for .log file */
    unsigned char   MyLstTableName[MAX_ALIAS_FIELD_LEN];      /* Имя таблицы-списка, которую обслуживает сервер */
    unsigned char   MyDirTableName[MAX_ALIAS_FIELD_LEN];      /* Имя таблицы-каталога, которую обслуживает сервер */
    ListType        ServicesList;               /* List of database services */
    uint32_t        DCP_UserID;                 /* Current user */
    unsigned char   DCP_CurUser[MAX_LOGIN_LEN]; /* логин текущего пользователя - человека */
    unsigned char   DCP_CurPass[MAX_PASSWD_LEN];/* пароль для доступа к базе данных*/
    uint32_t        WaitTime;       /* The wait time in min */
    uint32_t        DebugMode;      /* Debug mask for task */
    uint32_t        CheckTime;      /* The boxes check time in sek */
    unsigned char   M_TaskPriority; /* server main task priority */
    unsigned char   C_TaskPriority; /* server control task priority */
    unsigned char   T_TaskPriority; /* technologi task's priority */
    unsigned char   A_TaskPriority; /* accses task's priority */
    REM_ADDR        RetServicePort; /*  */
    ACC_POINT_INFO *AccessPoints;   /* Точки доступа сервера */
    uint16_t        AccessPointsNum;/* Число точек доступа сервера */
    ACC_POINT_INFO *pCurrentPoint;  /* Точка доступа стартующая */
    int             UpdateMBox;     /* For DB update */
    int             TechMBox;       /* For tech task */
    sem_t          *TechSem;        /* For cient task synchronization */
    sem_t          *par_reg;        /* For data acces synchronization */
    sem_t          *src_sets_sem;   /* For sets control task */
    sem_t          *sets_sem;       /* For sets control task */
    sem_t          *sets_depend_sem;/* For sets control task - to share access to SetsDependenceList*/
    sem_t          *mv_sem;         /* For mvl task */
    sem_t          *mv_ready;       /* For mvl task */
    sem_t          *ret_sem;        /* For retro task */
    sem_t          *dbint_sem;      /**/
    sem_t          *SyncSem;
    sem_t          *TaskSem;
    sem_t          *ClnSyncSem;
    int32_t         DataMBox;       /* Для чтения и записи часовых значений параметров в БДТИ */
    uint32_t        db_last_update_time;    /* Время последнего обновления БДТИ на момент инициализации задач*/
    uint32_t        db_last_relink_time;    /* Время последнего обновления БДТИ на момент инициализации задач, требующего сборки исполняемого модуля*/
    uint32_t        db_last_relink_status;  /* Статус контроля целостности, требующего сборки исполняемого модуля: 1 - вкл; 0 - откл */
    uint32_t        db_sets_depend_last_update_time;/* Время последнего обновления таблицы соответвствия косвенных уставок БДТИ */
    uint32_t        system_node;        /* Идентификатор узла системы - либо кластера, либо отдельной машины, к которой принадлежит данный сервер */
    uint32_t        set_src_query_num;  /**/
    uint32_t        index_plus;         /**/
    uint32_t        cur_index;          /**/
    uint32_t        ret_index;          /**/
    uint32_t        mvl_index;          /**/
    uint32_t        mvl_task_num;       /* Номер задачи записи архивов */
    uint32_t        p_number;           /**/
    REG_TIME        (*c_time)[RETRO_WIDTH]; /**/
    struct timeval  (*c_timetick)[RETRO_WIDTH]; /**/
    ListType        RegBaseList;        /* base */
    ListType        DataSrcList;        /* список зарегистрированных источников данных */
    ListType        SetsSrcList;        /**/
    ListType        ManualSrcList;      /* Список структур REG_MAN, отсортированный по id_srci */
    ListType        SetsList;           /**/
    ListType        Sets_ManualSrcList; /* Список структур SET_MANUAL, отсортированный по id_set, id_srci */
    ListType        Sets_OwnList;       /* Список структур SET_OWN, отсортированный по id_set, id_srci */
    uint32_t        Sets_OnwSrcId;      /* Идентификатор собственного источника (id_source) */
    REG_SET       **ppReg_Set;
    sem_t          *usr_reg;            /* Region for user info access */
    ListType        UsersList;          /**/
    ListType        SetsDependenceList; /* Таблица соответствий значений уставок значениям критерия */
    uint32_t        CalcCorrect;
    int32_t         FormuleNumber;
    int32_t         ArgumentNumber;
    CALC_STR        (*all_fn)[];
    REG_BASE        (*ppRegBase)[];
    REG_BASE      **ppRegBaseFormule;
    uint32_t        CurFormuleNumber;
    CALC_STR      **cur_fn;
    char            FullPathName[MAX_PATH_LEN];
    int             ExitMbx;
    pthread_t       pthrd[13];
    long            ExitMsgType;
    int32_t         AbortFlag;
    int32_t         mode;
    uint32_t        id_ginfo_march;
    uint32_t        id_ginfo_mmarch;
    uint32_t        id_ginfo_hmarch;
    uint32_t        id_ginfo_imarch;
    uint32_t        arch_port;
    char            arch_ip[64];
    uint32_t        arch_host_node;
    ListType        IntProfiles;        /* Список профилей архивов интегральных значений */
    ListType        AvrProfiles;        /* Список профилей архивов усредненных значений */
    ARC_PROFILE     InstantProfile;     /* Профиль мгновенных архивов  */
    RSDU_INFO      *regRsduInfo;
} ELRSRV_ENV;

/* Для хранения рассчитываемого значения интеграла */
typedef struct REG_INT
{
    uint32_t        interval;           /* Период интегрирования */
    uint32_t        calc_regim;         /* Режим интегрирования, константа ARC_FTR_CALC_XXX */
    uint32_t        profile_id;         /* Номер профиля архива */
    uint32_t        start_int_time;     /* Начало периода интегрирования */
    uint32_t        end_int_time;       /* Конец периода интегрирования */
    uint32_t        previous_time;      /* Время последнего расчета интеграла */
    uint32_t        notvalid_period;    /* Время некорректного значения параметра */
    REG_VAL         c_mop;              /* Текущее среднее значение */
    REG_VAL         last_mop;           /* Рассчитанное среднее значение */
    REG_VAL         c_int;              /* Текущее значение рассчитываемого интеграла */
    REG_VAL         last_int;           /* Рассчитанное значение интеграла */
    REG_BASE       *pRegBase;           /* Ссылка на обрабатываемый параметр */
} REG_INT;

/* Для хранения рассчитываемого значения усредненного архива */
typedef struct REG_AVR
{
    uint32_t        interval;           /* Период записи архива */
    uint32_t        profile_id;         /* Номер профиля архива */
    REG_VAL         last_avr;
    uint32_t        last_avr_time;
    EXTREME_VALUE   extr_value;
    EXTREME_VALUE   extr_value_ret;
    REG_BASE       *pRegBase;        /* Ссылка на обрабатываемый параметр */
} REG_AVR;

#if defined(WITH_DB_ORACLE)
#define GET_SQL_GINFO "select distinct arc_ginfo.id \
    from meas_arc, \
        %s list_v, \
        sys_gtopt, \
        arc_ginfo \
    where list_v.id = meas_arc.id_param \
        and sys_gtopt.id = arc_ginfo.id_gtopt \
        and arc_ginfo.id = meas_arc.id_ginfo \
        and sys_gtopt.define_alias like '%s' and rownum=1"
#elif defined(WITH_DB_MYSQL)
#define GET_SQL_GINFO "select distinct arc_ginfo.id \
    from meas_arc, \
        %s list_v, \
        sys_gtopt, \
        arc_ginfo \
    where list_v.id = meas_arc.id_param \
        and sys_gtopt.id = arc_ginfo.id_gtopt \
        and arc_ginfo.id = meas_arc.id_ginfo \
        and sys_gtopt.define_alias like '%s' \
    limit 1"
#else
#error "DB not defined."
#endif // defined(WITH_DB_ORACLE)

int32_t base_id_comp(const void *key, const void *d);
int32_t profile_id_comp(const void *key, const void *d);
int32_t regint_period_comp(const void *key, const void *d);
int32_t regint_profile_id_comp(const void *key, const void *d);
int32_t regavr_profile_id_comp(const void *key, const void *d);
int32_t oic_an_comp(const void *e1, const void *e2);
int32_t oic_dan_comp(const void *e1, const void *e2);
int32_t oic_an_id_comp(const void *key, const void *d);
int32_t oic_reg_comp(void *e1, void *e2);
int32_t oic_reg_comp(const void *e1, const void *e2);
int32_t oic_reg_id_comp(const void *key, const void *d);
int32_t man_id_comp(const void *key, const void *d);
int32_t man_id_srci_comp(const void *key, const void *d);
int32_t reg_source_id_comp(const void *e1, const void *e2);

int32_t reg_tune_my_id_srci_comp(const void *key, const void *d);
int32_t calc_str_channel_comp(const void *key, const void *d);

int32_t set_manual_comp(const void *key, const void *d);
int32_t set_id_depend_comp(const void *key, const void *d);
int32_t set_own_comp(const void *key, const void *d);
int32_t id_set_comp(const void *key, const void *d);
int32_t man_id_set_comp(const void *key, const void *d);
int32_t man_set_id_srci_comp(const void *key, const void *d);
int32_t pid_set_comp(const void *key, const void *d);
int32_t p_set_comp(const void *e1, const void *e2);

int32_t calc_init(ELRSRV_ENV *Env);
int32_t calc_regim(ELRSRV_ENV *Env);
int32_t form_sort(ELRSRV_ENV *Env,LOG_HEADER *LogFile, int32_t my_debug_mode);
int32_t db_read(ELRSRV_ENV *env, DB_ACCES_INFO *ui, LOG_HEADER *lfp);
int32_t ac_db_read(ELRSRV_ENV *env, LOG_HEADER *lfp);
int32_t fm_db_read(ELRSRV_ENV *env, LOG_HEADER *lfp);
void    oic_send_all(ELRSRV_ENV *Env, uint32_t oic_command, uint32_t global_type, LOG_HEADER *LogFile);
int32_t send_close_srvc(ELRSRV_ENV *Env, LOG_HEADER *lfp);
int32_t RemoveInfo(USR_STRUCT *user_info, ACC_POINT_INFO *pAccessInfo, ELRSRV_ENV *Env);
int32_t GetIndexByName(USR_STRUCT *user_info, ACC_POINT_INFO *pAccessInfo);
int32_t integral_tech_cycle(ELRSRV_ENV *Env, ARC_PROFILE *ArcProfile, LOG_HEADER *LogFile);
//int32_t integral_tech_cycle2(ELRSRV_ENV *Env, ARC_PROFILE *ArcProfile, LOG_HEADER *LogFile);
int32_t average_tech_cycle(ELRSRV_ENV *Env, ARC_PROFILE *ArcProfile, LOG_HEADER *LogFile);
int32_t mvl_tech_cycle(ELRSRV_ENV *Env, LOG_HEADER *LogFile);
void   *average_write_task(void *pStartParams);
double integral_sum(uint32_t calc_regime, double val, double dt);

#include "stalgrst.h"

#endif  /* __ELREG_21_H */
