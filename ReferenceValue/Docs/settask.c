/*
* RSDU2 electrical and other parameter server
* Alexandr V. Strelnikov
* 06.11.2000
* Start version 3.01
*/

/*
* Изменение работы с ручным вводом уставок
* Макаренко Е.А.
* 08.04.2003 
*/

/*
* Добавление временного гистерезиса для срабатывания уставки
* Коновалов П.В.
* 24.02.2011
*/
#include <sys/shm.h>
#include <signal.h>
#include <stddef.h>
#include <string.h>
#include <errno.h>
#include <stdio.h>
#include <strings.h>
#include <stdlib.h>
#include <math.h>

#include <rsdu2def.h>
#include <rmxtbox.h>
#include <utils.h>
#include <db2const.h>
#include <sys_sign.h>
#include <elreg30.h>
#include <rsdujrn.h>

#ifndef EPS_VAL
#define EPS_VAL 1.0e-5
#endif

void on_sig_stuff(int32_t index);

int32_t query_sets(ELRSRV_ENV *Env, LOG_HEADER* LogFile);
void SS_SendRegSet(COMM_PORT * port, uint32_t signal, uint32_t signal_type,
                       REG_BASE *ppRegBase, int32_t c_index, uint32_t level,
                       ELRSRV_ENV *env, LOG_HEADER* lfp)
{
    J_ELSET_STR       el_set;
    unsigned char    *trb = NULL;
    uint32_t          l;

    errno = 0;

    el_set.sh.signal = signal;
    el_set.sh.id_cause_user = (*env).UserID;
    el_set.sh.id_src_user = (*env).UserID;
    el_set.sh.lctime = RSDURTGUtils_Time70();
    el_set.dirt_id = (*env).MyDirTableID;
    el_set.dirr_id = (*ppRegBase).id_node;
    el_set.lstt_id = (*env).MyLstTableID;
    el_set.lstr_id = (*ppRegBase).id;
    el_set.state = (*ppRegBase).rv[c_index].ft;
    el_set.set_min = (*(*ppRegBase).set)[level].min_val_final;
    el_set.set_max = (*(*ppRegBase).set)[level].max_val_final;
    el_set.extr_val = (*(*ppRegBase).set)[level].extrem;

    l = sizeof(J_ELSET_STR);
    trb = (unsigned char *)RSDURTGUtils_SMalloc((uint32_t)l);
    if (trb == (unsigned char *)0)
    {
        RSDURTGUtils_ErrCheck( lfp, ERR_RMX, __LINE__, __FILE__, (int32_t)E_MEM, ERR_CONTINUE, "SS_SendRegSet: Out of memory ");
        /*if (port == NULL_TOKEN) rq_delete_port (CommPort, &status); */
        return;
    }
    memmove(trb, (char *)&el_set, l);
    if (RSDURTGUtils_SS_SendSignal((uint32_t) SS_CONTROLOBJECT, signal_type, (char *)trb, l, port, lfp, env->FullPathName) < 0)
    {
        RSDURTGUtils_ErrCheck( lfp, ERR_RMX, __LINE__, __FILE__, (int32_t)E_PARAM, ERR_CONTINUE, "SS_SendRegSet: RSDURTGUtils_SS_SendSignal() failed ");
    }
    RSDURTGUtils_SFree(trb);
}

/* Функция рассчета значений для косвенных уставок */
int32_t get_depend_sets_value(ELRSRV_ENV *Env, LOG_HEADER*  lfp, uint32_t id_set, double cr_value, double *value_max, double *value_min)
{
    SET_DEPEND        *pSetDepend = NULL, **ppSetDepend = NULL;
    int32_t            i = 0, isFind = 0;
    SET_DEPEND_VALUE   SetDependValueX1, SetDependValueX2;
    int32_t            ret = 0;
    uint16_t           status = E_OK;

    if(Env->SetsDependenceList == NULL || ListNumItems(Env->SetsDependenceList) == 0)
        ret = -4;
    else
    {
        /* Ждем семафора на доступ к таблице соответствия для косвенных уставок */
        RSDURTGUtils_ReceiveUnits((void*)&Env->sets_depend_sem, (uint16_t)1, ELR_COMMON_WAIT, &status);
        RSDURTGUtils_ErrCheck(lfp, ERR_RMX, __LINE__, __FILE__, (int32_t)status, ERR_CONTINUE, "get_depend_sets_value(): rq_receive_units on sets_depend_sem ");

        ppSetDepend = (SET_DEPEND**)bsearch(&id_set,
            ListGetDataPtr((*Env).SetsDependenceList),
            (size_t)ListNumItems((*Env).SetsDependenceList),
            sizeof(SET_DEPEND *),
            set_id_depend_comp);
        /*
        RSDURTGUtils_UnilogMessage(LOG_DEBUG, lfp, "-----ppSetDepend=%p ",
        ppSetDepend);

        */

        if (ppSetDepend != NULL)
        {
            pSetDepend = *ppSetDepend;
            /*
            RSDURTGUtils_UnilogMessage(LOG_DEBUG, lfp, "Num(pSetDepend->values) =%d  id_set=%d cr_value=%d ",ListNumItems(pSetDepend->values),id_set,cr_value);

            */
            if (pSetDepend->values == NULL)
                ret = -2;
            else
                if (ListNumItems(pSetDepend->values) == 0)
                    ret = -3;
                else
                    if (ListNumItems(pSetDepend->values) == 1)
                    {
                        SetDependValueX1 = *(SET_DEPEND_VALUE *)ListGetPtrToItem(pSetDepend->values, (int32_t)1);
                        *value_max = SetDependValueX1.value_max;
                        *value_min = SetDependValueX1.value_min;
                    }
                    else
                    {
                        i = 0;
                        while (i < ListNumItems(pSetDepend->values)-1 && isFind == 0)
                        {
                            SetDependValueX1 = *(SET_DEPEND_VALUE *)ListGetPtrToItem(pSetDepend->values, (int32_t)(i+1));
                            SetDependValueX2 = *(SET_DEPEND_VALUE *)ListGetPtrToItem(pSetDepend->values, (int32_t)(i+2));
                            /*
                            RSDURTGUtils_UnilogMessage(LOG_DEBUG, lfp, "-----SetDependValueX1.value_max=%lf, min=%lf SetDependValueX2.value_max=%lf min=%lf ",
                            SetDependValueX1.value_max,SetDependValueX1.value_min, SetDependValueX2.value_max,SetDependValueX2.value_min);

                            */
                            if (cr_value <= SetDependValueX1.cr_value && i == 0)
                            {
                                *value_max = SetDependValueX1.value_max;
                                *value_min = SetDependValueX1.value_min;
                                isFind = 1;
                            }
                            else
                                if (cr_value >= SetDependValueX2.cr_value && i == ListNumItems(pSetDepend->values)-2)
                                {
                                    *value_max = SetDependValueX2.value_max;
                                    *value_min = SetDependValueX2.value_min;
                                    isFind = 1;
                                }
                                else
                                    if (cr_value >= SetDependValueX1.cr_value && cr_value <= SetDependValueX2.cr_value)
                                    {
                                        if (fabs(SetDependValueX1.cr_value - SetDependValueX2.cr_value) < EPS_VAL)
                                        {
                                            *value_max = SetDependValueX1.value_max;
                                            *value_min = SetDependValueX1.value_min;
                                        }
                                        else
                                        {
                                            /* y=(x-x1)(y2-y1)/(x2-x1)+y1 - линейная интерполяция */
                                            *value_max = (cr_value-SetDependValueX1.cr_value)*(SetDependValueX2.value_max-SetDependValueX1.value_max)/
                                                (SetDependValueX2.cr_value-SetDependValueX1.cr_value)+SetDependValueX1.value_max;
                                            *value_min = (cr_value-SetDependValueX1.cr_value)*(SetDependValueX2.value_min-SetDependValueX1.value_min)/
                                                (SetDependValueX2.cr_value-SetDependValueX1.cr_value)+SetDependValueX1.value_min;
                                        }
                                        isFind = 1;
                                    }
                                    i++;
                        }/* while (i < ListNumItems(pSetDepend->values)-1 && isFind == 0) */
                    }/* else */
        }/* if (pSetDepend != NULL) */
        else
            ret = -1;

        /* Освобождаем семафор на доступ к таблице соответствия для косвенных уставок */
        RSDURTGUtils_SendUnits((void*)&Env->sets_depend_sem, (uint16_t)1, &status);
        RSDURTGUtils_ErrCheck(lfp, ERR_RMX, __LINE__, __FILE__, (int32_t)status, ERR_CONTINUE, "get_depend_sets_value(): rq_send_units on sets_depend_sem ");
    }/* else */

    return ret;
}

/************************************************************************/
void *check_set_task(void *Env1)
{
    uint16_t    status = E_OK;
    uint16_t    actual;
    LOG_HEADER  LogStruct;
    LOG_HEADER  *LogFile = &LogStruct;
    COMM_PORT   *set_port;
    uint16_t    port_id = 0;
    ELRSRV_ENV  *Env;
    time_t      ct;    /* Метка времени начала цикла перебора всех параметров */
    int32_t     p_ind, c_ind;
    double      cset_max, cset_min, cset_disp;
    double      tmp_val;
    RET_VAL     cval;
    REG_BASE    (*ppRegBase)[];
    REG_BASE     *pRegBase;
    uint32_t    i, cur_set, SrcErr = 0;
    uint32_t    SetOwnListNum = 0;
    char        msg[256];
    SET_MANUAL  *_pSetManual = NULL;
    SET_OWN     *pSetOwn = NULL, *_pSetOwn = NULL, *pSetOwnList = NULL;
    TUNE_STRUCT _tuneStruct;
    REG_INT     *pRegInt = NULL;
    uint32_t    idx;
    uint32_t    profile_id = 0;

    signal(SIGINT, &on_sig_stuff);

    Env = (ELRSRV_ENV *)Env1;
    errno = 0;

    RSDURTGUtils_LogInit(LogFile, ELRD_CHECKSET, Env->LogFileName, NULL, __FUNCTION__);

    RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile,"Start check_set_task");

    /* Create service command port  */
    port_id = (uint16_t)0;
    set_port = RSDURTGUtils_GetCommPort((uint16_t)ADV_PROTO_COMMON, &port_id, &status, LogFile);
    if(set_port == (COMM_PORT*)0)
    {
        RSDURTGUtils_ErrCheck(LogFile, ERR_RMX, __LINE__, __FILE__, (int32_t)status,ERR_DELETE, "check_set_task: create_s_port() failed ");
    }

    /* Signal main task that the shared data has been read.*/
    RSDURTGUtils_SendUnits((void*)&Env->SyncSem, (uint16_t)1, &status);
    RSDURTGUtils_ErrCheck(LogFile, ERR_RMX, __LINE__, __FILE__, (int32_t)status, ERR_CONTINUE, (const char *) 0);

    /*(*Env).sets_sem = rq_create_semaphore ((uint16_t) 0, (uint16_t) 24, FIFO_QUEUING , &status);*/
    RSDURTGUtils_CreateSemaphore((uint16_t) 0, (void*)&(*Env).sets_sem, (uint16_t) 24, FIFO_QUEUING , &status);
    RSDURTGUtils_ErrCheck(LogFile, ERR_RMX, __LINE__, __FILE__, (int32_t)status, ERR_DELETE,  "check_set_task: rq_create_semaphore() ");

    /*(*Env).src_sets_sem = rq_create_semaphore ((uint16_t) 0, (uint16_t) 24, FIFO_QUEUING , &status);*/
    RSDURTGUtils_CreateSemaphore((uint16_t) 0, (void*)&(*Env).src_sets_sem, (uint16_t) 24, FIFO_QUEUING , &status);
    RSDURTGUtils_ErrCheck(LogFile, ERR_RMX, __LINE__, __FILE__, (int32_t)status, ERR_DELETE,  "check_set_task: rq_create_semaphore() ");

    while ( 1 )
    {
        /* Ждем семафора на начало работы цикла проверки уставок */
        actual = RSDURTGUtils_ReceiveUnits((void*)&(*Env).sets_sem, (uint16_t)1, WAIT_FOREVER, &status);
        if(Env->AbortFlag)
            break;
        if ((status == E_OK) && ((*Env).p_number  > 0))
        {
            ct = RSDURTGUtils_Time70();
            c_ind = (*Env).cur_index;
            p_ind = c_ind - 1;
            if (p_ind < 0)
                p_ind = RETRO_WIDTH - 1;
            RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "check_set_task: Start check sets cycle");

            if ((*Env).set_src_query_num > 0)
            {
                actual = RSDURTGUtils_ReceiveUnits((void*)&(*Env).src_sets_sem, (uint16_t)(*Env).set_src_query_num, (uint16_t)(ELR_TI_WAIT), &status);
                if(Env->AbortFlag)
                    break;
                if ((status != E_OK) && (SrcErr == 0))
                {
                    SrcErr = 1;
                    sprintf(msg, "User ID %u check_set_task: Source no answer, query number is %d status %04hx ",
                        (*Env).UserID, (*Env).set_src_query_num, status);
                    RSDURTGUtils_UnilogMessage(LOG_WARNING, LogFile, msg);
                }
                else
                    SrcErr = 0;
            }
            (*Env).set_src_query_num = 0;

            ppRegBase = (REG_BASE (*)[])(*Env).ppRegBase;

            /* Цикл по всем параметрам */
            for (i = 0; i < (*Env).p_number; i++)
            {
                /* Формируем проверяемое значение параметра */
                if (((*ppRegBase)[i].c_ft & OIC_DST_AVERAGEMON) == OIC_DST_AVERAGEMON) /* Если включен контроль средних значений (за 30 минут) */
                {
                    /* Для контроля по среднему значению, находим среднее за 30 минут */
                    profile_id = (*Env).id_ginfo_imarch;
                    pRegInt = (REG_INT*)bsearch(&profile_id,
                        ListGetDataPtr((*ppRegBase)[i].ivl),
                        (size_t)ListNumItems((*ppRegBase)[i].ivl),
                        sizeof(REG_INT),
                        regint_profile_id_comp);
                    if (pRegInt!=0)
                    {
                        cval.vl = pRegInt->c_mop.vl;
                        cval.ft = pRegInt->c_mop.ft;
                    }
                    else
                    {
                        cval.vl = 0;
                        cval.ft = ELRF_SRCNOPRESENT;
                    }
                }
                else                                                                   /* иначе контролируем мнгновенные значения */
                {
                    cval.vl = (*ppRegBase)[i].rv[c_ind].vl;
                    cval.ft = (*ppRegBase)[i].rv[c_ind].ft;
                }
                /* Если параметр недостоверный, то уставки не проверяем */
                if (check_valid(cval.ft) != 0)
                {
                    RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "check_set_task: param %u value not valid <%u> ", (*ppRegBase)[i].id, cval.ft);

                    (*ppRegBase)[i].rv[c_ind].ft &= ~ELRF_DERATING;
                    (*ppRegBase)[i].rv[c_ind].ft &= ~ELRF_ADERATING;
                    continue;
                }

                /* Цикл по всем уровням уставок cur_set для текущего параметра (*ppRegBase)[i] */
                for (cur_set = 0; cur_set < (*ppRegBase)[i].set_level_number; cur_set++)
                {
                    /* Вычисляем текущую дисперсию параметра */
                    if (((*ppRegBase)[i].c_ft & OIC_DST_PERCENT) == OIC_DST_PERCENT)
                        cset_disp = fabs(cval.vl*((*ppRegBase)[i].disper/100.0));
                    else
                        cset_disp = (*ppRegBase)[i].disper;
                    RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "check_set_task: check sets for param  %u, val %lf    base disp %lf, cdisp %lf ",
                            (*ppRegBase)[i].id, cval.vl, (*ppRegBase)[i].disper, cset_disp);

                    /* Присваиваем значения уставок в зависимости от источника */
                    /* Если источник - ручной ввод */
                    if ((*(*ppRegBase)[i].set)[cur_set].id_src == ELRSRC_MAN)
                    {
                        /* 8 апреля 2003 г., Макаренко Е.А.*/
                        /* ищем значения ручного ввода для уставки */
                        _tuneStruct.channel_id = (*(*ppRegBase)[i].set)[cur_set].id_srci;
                        _tuneStruct.param_id = (*(*ppRegBase)[i].set)[cur_set].id;

                        _pSetManual = (SET_MANUAL*) bsearch(&_tuneStruct,
                            ListGetDataPtr((*Env).Sets_ManualSrcList),
                            (size_t)ListNumItems((*Env).Sets_ManualSrcList),
                            sizeof(SET_MANUAL),
                            set_manual_comp);

                        if (_pSetManual != (SET_MANUAL*)0)
                        {
                            (*(*ppRegBase)[i].set)[cur_set].max_val = _pSetManual->m_max_val;
                            (*(*ppRegBase)[i].set)[cur_set].min_val = _pSetManual->m_min_val;
                            (*(*ppRegBase)[i].set)[cur_set].val_is_get = 1;
                        }
                        else
                        {
                            RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "check_set_task: Can't find SET_MANUAL for param %u, set level %u (channel %u) ",
                                    (*ppRegBase)[i].id,
                                    (*(*ppRegBase)[i].set)[cur_set].id_level,
                                    (*(*ppRegBase)[i].set)[cur_set].id_srci);

                            (*(*ppRegBase)[i].set)[cur_set].max_val = MAX_PARAM_VALUE;
                            (*(*ppRegBase)[i].set)[cur_set].min_val = MIN_PARAM_VALUE;
                        }
                    }/* if ((*(*ppRegBase)[i].set)[cur_set].id_src == ELRSRC_MAN) */
                    else if((*(*ppRegBase)[i].set)[cur_set].id_src == (*Env).Sets_OnwSrcId) /* Если источник - собственный (параметр электрического режима) */
                    {
                        _tuneStruct.channel_id = (*(*ppRegBase)[i].set)[cur_set].id_srci;
                        _tuneStruct.param_id = (*(*ppRegBase)[i].set)[cur_set].id;
                        pSetOwnList = (SET_OWN*)ListGetDataPtr((*Env).Sets_OwnList);
                        SetOwnListNum = ListNumItems((*Env).Sets_OwnList);

                        pSetOwn = (SET_OWN*) bsearch(&_tuneStruct,
                            pSetOwnList,
                            (size_t)SetOwnListNum,
                            sizeof(SET_OWN),
                            set_own_comp);
                        if (pSetOwn == (SET_OWN*)0)
                        {
                            RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "check_set_task: Can't find SET_OWN for param %u, set level %u (channel %u) ",
                                    (*ppRegBase)[i].id,
                                    (*(*ppRegBase)[i].set)[cur_set].id_level,
                                    (*(*ppRegBase)[i].set)[cur_set].id_srci);

                            (*(*ppRegBase)[i].set)[cur_set].max_val = MAX_PARAM_VALUE;
                            (*(*ppRegBase)[i].set)[cur_set].min_val = MIN_PARAM_VALUE;
                        }
                        else
                        {
                            idx = pSetOwn - pSetOwnList; /* определяем индекс найденной записи */
                            RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "dcp_set_setssource: Find record idx %u for own set ", idx);

                            while (idx > 0)
                            {
                                idx--;
                                if (pSetOwnList[idx].id_srci == pSetOwn->id_srci)
                                    pSetOwn = &(pSetOwnList[idx]);
                                else break;
                            }
                            RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "dcp_set_setssource: First record idx %u for own set ", idx + 1);

                            /* теперь pSetOwn - указатель на первую настройку канала */
                            _pSetOwn = pSetOwn;
                            idx = pSetOwn - pSetOwnList; /* определяем индекс первой записи */

                            (*(*ppRegBase)[i].set)[cur_set].max_val = 0.0;
                            (*(*ppRegBase)[i].set)[cur_set].min_val = 0.0;

                            while (idx < SetOwnListNum)
                            {
                                pSetOwn = &(pSetOwnList[idx]);
                                if ((*pSetOwn).id_srci != (*_pSetOwn).id_srci)
                                    break;
                                pRegBase = (REG_BASE *)bsearch (&(*pSetOwn).src_id,
                                    (*Env).ppRegBase,
                                    (size_t)(*Env).p_number,
                                    (size_t)ListGetItemSize((*Env).RegBaseList),
                                    base_id_comp);
                                if (pRegBase != NULL)
                                {
                                    switch((*(*ppRegBase)[i].set)[cur_set].sets_type)
                                    {
                                    case EOR_SETS_MON_NOT_RANGE:
                                    case EOR_SETS_MON_DEPENDED_NOT_RANGE:
                                        (*(*ppRegBase)[i].set)[cur_set].max_val += (*pRegBase).rv[c_ind].vl * (*pSetOwn).coeff + (cset_disp*1.5);
                                        (*(*ppRegBase)[i].set)[cur_set].min_val += (*pRegBase).rv[c_ind].vl * (*pSetOwn).coeff - (cset_disp*1.5);
                                        break;
                                    default:
                                        (*(*ppRegBase)[i].set)[cur_set].max_val += (*pRegBase).rv[c_ind].vl * (*pSetOwn).coeff;
                                        (*(*ppRegBase)[i].set)[cur_set].min_val += (*pRegBase).rv[c_ind].vl * (*pSetOwn).coeff;
                                    }
                                    (*(*ppRegBase)[i].set)[cur_set].val_is_get = 1;
                                }
                                else
                                {
                                    (*(*ppRegBase)[i].set)[cur_set].max_val = MAX_PARAM_VALUE;
                                    (*(*ppRegBase)[i].set)[cur_set].min_val = MIN_PARAM_VALUE;
                                }
                                idx++;
                            }
                        }
                    }
                    /* if((*(*ppRegBase)[i].set)[cur_set].id_src == ELRSRC_OWN) */
                    /* Обработка значений уставок в зависимости от их типа */
                    switch((*(*ppRegBase)[i].set)[cur_set].sets_type)
                    {
                    case EOR_SETS_MON_NOT_RANGE:
                        if ((*(*ppRegBase)[i].set)[cur_set].val_is_get == 1)
                        {
                            (*(*ppRegBase)[i].set)[cur_set].max_val_final = (*(*ppRegBase)[i].set)[cur_set].max_val;
                            (*(*ppRegBase)[i].set)[cur_set].min_val_final = (*(*ppRegBase)[i].set)[cur_set].min_val;
                        }
                        else
                        {
                            (*(*ppRegBase)[i].set)[cur_set].max_val_final = (*(*ppRegBase)[i].set)[cur_set].max_val = MAX_PARAM_VALUE;
                            (*(*ppRegBase)[i].set)[cur_set].min_val_final = (*(*ppRegBase)[i].set)[cur_set].min_val = MIN_PARAM_VALUE;
                        }
                        break;
                    case EOR_SETS_MON_NOT_HIGH:
                        if ((*(*ppRegBase)[i].set)[cur_set].val_is_get == 1)
                            (*(*ppRegBase)[i].set)[cur_set].max_val_final = (*(*ppRegBase)[i].set)[cur_set].max_val;
                        else
                            (*(*ppRegBase)[i].set)[cur_set].max_val_final = (*(*ppRegBase)[i].set)[cur_set].max_val = MAX_PARAM_VALUE;
                        (*(*ppRegBase)[i].set)[cur_set].min_val_final = (*(*ppRegBase)[i].set)[cur_set].min_val = MIN_PARAM_VALUE;
                        break;
                    case EOR_SETS_MON_NOT_LOWER:
                        (*(*ppRegBase)[i].set)[cur_set].max_val_final = (*(*ppRegBase)[i].set)[cur_set].max_val = MAX_PARAM_VALUE;
                        if ((*(*ppRegBase)[i].set)[cur_set].val_is_get == 1)
                            (*(*ppRegBase)[i].set)[cur_set].min_val_final = (*(*ppRegBase)[i].set)[cur_set].min_val;
                        else
                            (*(*ppRegBase)[i].set)[cur_set].min_val_final = (*(*ppRegBase)[i].set)[cur_set].min_val = MIN_PARAM_VALUE;
                        break;
                    case EOR_SETS_MON_DEPENDED_NOT_RANGE:
                        if ((*(*ppRegBase)[i].set)[cur_set].val_is_get == 1 &&
                            get_depend_sets_value(Env, LogFile, (*(*ppRegBase)[i].set)[cur_set].id, (*(*ppRegBase)[i].set)[cur_set].max_val, &cset_max, &cset_min) == 0)
                        {
                            if ((*(*ppRegBase)[i].set)[cur_set].id_src == (*Env).Sets_OnwSrcId)
                                (*(*ppRegBase)[i].set)[cur_set].max_val_final = cset_max + (cset_disp*1.5);
                            else
                                (*(*ppRegBase)[i].set)[cur_set].max_val_final = cset_max;
                        }
                        else
                            (*(*ppRegBase)[i].set)[cur_set].max_val_final = MAX_PARAM_VALUE;
                        if ((*(*ppRegBase)[i].set)[cur_set].val_is_get == 1 &&
                            get_depend_sets_value(Env, LogFile, (*(*ppRegBase)[i].set)[cur_set].id, (*(*ppRegBase)[i].set)[cur_set].min_val, &cset_max, &cset_min) == 0)
                        {
                            if ((*(*ppRegBase)[i].set)[cur_set].id_src == (*Env).Sets_OnwSrcId)
                                (*(*ppRegBase)[i].set)[cur_set].min_val_final = cset_min - (cset_disp*1.5);
                            else
                                (*(*ppRegBase)[i].set)[cur_set].min_val_final = cset_min;
                        }
                        else
                            (*(*ppRegBase)[i].set)[cur_set].min_val_final = MIN_PARAM_VALUE;
                        break;
                    case EOR_SETS_MON_DEPENDED_NOT_HIGH:
                        if ((*(*ppRegBase)[i].set)[cur_set].val_is_get == 1 &&
                            get_depend_sets_value(Env, LogFile, (*(*ppRegBase)[i].set)[cur_set].id, (*(*ppRegBase)[i].set)[cur_set].max_val, &cset_max, &cset_min) == 0)
                            (*(*ppRegBase)[i].set)[cur_set].max_val_final = cset_max;
                        else
                            (*(*ppRegBase)[i].set)[cur_set].max_val_final = MAX_PARAM_VALUE;
                        (*(*ppRegBase)[i].set)[cur_set].min_val_final = (*(*ppRegBase)[i].set)[cur_set].min_val = MIN_PARAM_VALUE;
                        break;
                    case EOR_SETS_MON_DEPENDED_NOT_LOWER:
                        (*(*ppRegBase)[i].set)[cur_set].max_val_final = (*(*ppRegBase)[i].set)[cur_set].max_val = MAX_PARAM_VALUE;
                        if ((*(*ppRegBase)[i].set)[cur_set].val_is_get == 1 &&
                            get_depend_sets_value(Env, LogFile, (*(*ppRegBase)[i].set)[cur_set].id, (*(*ppRegBase)[i].set)[cur_set].min_val, &cset_max, &cset_min) == 0)
                            (*(*ppRegBase)[i].set)[cur_set].min_val_final = cset_min;
                        else
                            (*(*ppRegBase)[i].set)[cur_set].min_val_final = MIN_PARAM_VALUE;
                        break;
                    }/* switch((*(*ppRegBase)[i].set)[cur_set].sets_type) */

                    /*************************************************************************************/
                    /*    23.07.03 Калинкин С.Ю
                    Блок перенесен из начала цикла выше по тексту.
                    Для инициализации текущих значений уставок в случае notify_period=0
                    */
                    if ((*(*ppRegBase)[i].set)[cur_set].notify_period == 0)
                    {
                        (*ppRegBase)[i].rv[c_ind].ft &= ~ELRF_DERATING;
                        if (0 == cur_set) /* Аварийные уставки */
                            (*ppRegBase)[i].rv[c_ind].ft &= ~ELRF_ADERATING;
                        (*(*ppRegBase)[i].set)[cur_set].begintime = 0;
                        (*(*ppRegBase)[i].set)[cur_set].extrem = 0.0;
                        RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "check_set_task: param id %u, level %u, notify_period is 0 ",
                                (*ppRegBase)[i].id, (*(*ppRegBase)[i].set)[cur_set].id_level);

                        continue;
                    }

                    /*************************************************************************************/

                    /* Если значения минимума и максимума равны, то диапазон задаем дисперсией */
                    if ((*(*ppRegBase)[i].set)[cur_set].max_val_final == (*(*ppRegBase)[i].set)[cur_set].min_val_final)
                    {
                        tmp_val = (*(*ppRegBase)[i].set)[cur_set].max_val_final;
                        switch((*(*ppRegBase)[i].set)[cur_set].sets_type)
                        {
                        case EOR_SETS_MON_NOT_RANGE:
                        case EOR_SETS_MON_DEPENDED_NOT_RANGE:
                            (*(*ppRegBase)[i].set)[cur_set].max_val_final = tmp_val + (cset_disp*1.5);
                            (*(*ppRegBase)[i].set)[cur_set].min_val_final = tmp_val - (cset_disp*1.5);
                            break;
                        case EOR_SETS_MON_NOT_HIGH:
                        case EOR_SETS_MON_DEPENDED_NOT_HIGH:
                            (*(*ppRegBase)[i].set)[cur_set].max_val_final = tmp_val;
                            (*(*ppRegBase)[i].set)[cur_set].min_val_final = MIN_PARAM_VALUE;
                            break;
                        case EOR_SETS_MON_NOT_LOWER:
                        case EOR_SETS_MON_DEPENDED_NOT_LOWER:
                            (*(*ppRegBase)[i].set)[cur_set].max_val_final = MAX_PARAM_VALUE;
                            (*(*ppRegBase)[i].set)[cur_set].min_val_final = tmp_val;
                            break;
                        }
                    }

                    /* Вычисляем значения уставок для проверки с учетом дисперсии */
                    if  (((*ppRegBase)[i].rv[p_ind].ft & ELRF_DERATING) != ELRF_DERATING)
                    {
                        cset_max = (*(*ppRegBase)[i].set)[cur_set].max_val_final + cset_disp;
                        cset_min = (*(*ppRegBase)[i].set)[cur_set].min_val_final - cset_disp;
                    }
                    else
                    {
                        cset_max = (*(*ppRegBase)[i].set)[cur_set].max_val_final - cset_disp;
                        cset_min = (*(*ppRegBase)[i].set)[cur_set].min_val_final + cset_disp;
                    }

                    /* Непосредственно проверка значений */
                    if (cval.vl > cset_max)
                    {
                        (*ppRegBase)[i].rv[c_ind].ft |= ELRF_DERATING;
                        if (0 == cur_set) /* Аварийные уставки */
                            (*ppRegBase)[i].rv[c_ind].ft |= ELRF_ADERATING;
                        if  (((*ppRegBase)[i].rv[p_ind].ft & ELRF_DERATING) != ELRF_DERATING)
                            (*(*ppRegBase)[i].set)[cur_set].extrem = cval.vl;
                        else
                        {
                            if ((*(*ppRegBase)[i].set)[cur_set].extrem < cval.vl)
                                (*(*ppRegBase)[i].set)[cur_set].extrem = cval.vl;
                        }
                    }
                    else if (cval.vl < cset_min)
                    {
                        (*ppRegBase)[i].rv[c_ind].ft |= ELRF_DERATING;
                        if (0 == cur_set) /* Аварийные уставки */
                            (*ppRegBase)[i].rv[c_ind].ft |= ELRF_ADERATING;
                        if  (((*ppRegBase)[i].rv[p_ind].ft & ELRF_DERATING) != ELRF_DERATING)
                            (*(*ppRegBase)[i].set)[cur_set].extrem = cval.vl;
                        else
                        {
                            if ((*(*ppRegBase)[i].set)[cur_set].extrem > cval.vl)
                                (*(*ppRegBase)[i].set)[cur_set].extrem = cval.vl;
                        }
                    }
                    /* Завершение нарушения уставок */
                    else
                    {
                        /* Проверяем, не участвует ли в расчете уставок гестерезис. 
                        Если да, то не всегда необходимо посылать сигнал о завершении фактического нарушения,
                        а только если было нарушение по гистерезису */
                        if((*(*ppRegBase)[i].set)[cur_set].hyst_period > 0)
                        {
                            if  ((((*ppRegBase)[i].rv[p_ind].ft & ELRF_HYST_PERIOD) == ELRF_HYST_PERIOD)
                                && ((*(*ppRegBase)[i].set)[cur_set].firstbegintime > 0))
                            {
#ifdef  E
                                SS_SendRegSet(set_port, (uint32_t)SS_ENDSET, SS_MESSAGE, &(*ppRegBase)[i], p_ind, (uint32_t)cur_set, Env, LogFile);
#else
                                SS_SendRegSet(set_port, (uint32_t)SS_PHENDFAIL, SS_MESSAGE, &(*ppRegBase)[i], p_ind,(uint32_t) cur_set, Env, LogFile);
#endif
                            }
                        }
                        else
                            if ((((*ppRegBase)[i].rv[p_ind].ft & ELRF_DERATING) == ELRF_DERATING)
                                && ((*(*ppRegBase)[i].set)[cur_set].begintime > 0))
                            {
#ifdef  E
                                SS_SendRegSet(set_port, (uint32_t)SS_ENDSET, SS_MESSAGE, &(*ppRegBase)[i], p_ind, (uint32_t)cur_set, Env, LogFile);
#else
                                SS_SendRegSet(set_port, (uint32_t)SS_PHENDFAIL, SS_MESSAGE, &(*ppRegBase)[i], p_ind,(uint32_t) cur_set, Env, LogFile);
#endif
                            }
                            RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "check_set_task: all OK! ");

                            (*ppRegBase)[i].rv[c_ind].ft &= ~ELRF_DERATING;
                            if (0 == cur_set) /* Аварийные уставки */
                                (*ppRegBase)[i].rv[c_ind].ft &= ~ELRF_ADERATING;
                            (*(*ppRegBase)[i].set)[cur_set].begintime = 0;
                            (*(*ppRegBase)[i].set)[cur_set].extrem = 0.0;
                            (*ppRegBase)[i].rv[c_ind].ft &= ~ELRF_HYST_PERIOD;
                            (*(*ppRegBase)[i].set)[cur_set].firstbegintime = 0;
                    }

                    /* Уставки нарушены */
                    if (((*ppRegBase)[i].rv[c_ind].ft & ELRF_DERATING) == ELRF_DERATING)
                    {
                        if  (((*ppRegBase)[i].rv[p_ind].ft & ELRF_DERATING) != ELRF_DERATING)
                        {
                            (*(*ppRegBase)[i].set)[cur_set].begintime        = ct;
                            (*(*ppRegBase)[i].set)[cur_set].firstbegintime    = ct;

                            if((*(*ppRegBase)[i].set)[cur_set].hyst_period == 0)
                                SS_SendRegSet(set_port, (*(*ppRegBase)[i].set)[cur_set].start_signal_id, SS_ALARM, &(*ppRegBase)[i], c_ind, (uint32_t)cur_set, Env, LogFile);
                        }
                        else if ((ct - (*(*ppRegBase)[i].set)[cur_set].begintime) >= (*(*ppRegBase)[i].set)[cur_set].notify_period)
                        {
                            if((*(*ppRegBase)[i].set)[cur_set].hyst_period == 0)
                            {
                                SS_SendRegSet(set_port, (*(*ppRegBase)[i].set)[cur_set].cont_signal_id, SS_ALARM,&(*ppRegBase)[i], c_ind, (uint32_t)cur_set, Env, LogFile);
                                (*(*ppRegBase)[i].set)[cur_set].begintime = ct;
                            }
                        }

                        /* Проверяем временнОй гистерезис */

                        if((*(*ppRegBase)[i].set)[cur_set].hyst_period > 0)
                        {
                            if((ct - (*(*ppRegBase)[i].set)[cur_set].firstbegintime) >= (*(*ppRegBase)[i].set)[cur_set].hyst_period)
                            {
                                (*ppRegBase)[i].rv[c_ind].ft |= ELRF_HYST_PERIOD;
                                if  (((*ppRegBase)[i].rv[p_ind].ft & ELRF_HYST_PERIOD) != ELRF_HYST_PERIOD)
                                {
                                    SS_SendRegSet(set_port, (*(*ppRegBase)[i].set)[cur_set].start_signal_id, SS_ALARM, &(*ppRegBase)[i], c_ind, (uint32_t)cur_set, Env, LogFile);
                                    (*(*ppRegBase)[i].set)[cur_set].begintime = ct;
                                }
                                else if ((ct - (*(*ppRegBase)[i].set)[cur_set].begintime) >= (*(*ppRegBase)[i].set)[cur_set].notify_period)
                                {
                                    SS_SendRegSet(set_port, (*(*ppRegBase)[i].set)[cur_set].cont_signal_id, SS_ALARM,&(*ppRegBase)[i], c_ind, (uint32_t)cur_set, Env, LogFile);
                                    (*(*ppRegBase)[i].set)[cur_set].begintime = ct;
                                }
                            }
                        }

                        RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "check_set_task: DERATING level(cur_set) %u, c_min %lf, c_max %lf, min %lf, max %lf, min_final %lf, max_final %lf, sets_type %u, param_ft=%u, hyst_period=%u, firstbegintime=%u, begintime=%u",
                                (*(*ppRegBase)[i].set)[cur_set].id_level, cset_min, cset_max,
                                (*(*ppRegBase)[i].set)[cur_set].min_val,
                                (*(*ppRegBase)[i].set)[cur_set].max_val,
                                (*(*ppRegBase)[i].set)[cur_set].min_val_final,
                                (*(*ppRegBase)[i].set)[cur_set].max_val_final,
                                (*(*ppRegBase)[i].set)[cur_set].sets_type,
                                (*ppRegBase)[i].rv[c_ind].ft,
                                (*(*ppRegBase)[i].set)[cur_set].hyst_period,
                                (*(*ppRegBase)[i].set)[cur_set].firstbegintime,
                                (*(*ppRegBase)[i].set)[cur_set].begintime);

                        break;
                    }/* if (((*ppRegBase)[i].rv[c_ind].ft & ELRF_DERATING) == ELRF_DERATING) */
                }/* for (cur_set = 0; cur_set < (*ppRegBase)[i].set_level_number; cur_set++) */
            }/* for (i = 0; i < (*Env).p_number; i++) */
            /* Посылаем запрос на значение уставок */

            /* 29.06.2005 Вагин А.А. обнуляем чтобы работало суммирование */
            for (i = 0; i < (*Env).p_number; i++)
            {
                for (cur_set = 0; cur_set < (*ppRegBase)[i].set_level_number; cur_set++)
                {
                    if ((*(*ppRegBase)[i].set)[cur_set].id_src == ELRSRC_MAN)
                        continue;
                    if((*(*ppRegBase)[i].set)[cur_set].id_src == (*Env).Sets_OnwSrcId)
                        continue;
                    (*(*ppRegBase)[i].set)[cur_set].min_val = 0.0;
                    (*(*ppRegBase)[i].set)[cur_set].max_val = 0.0;
                    (*(*ppRegBase)[i].set)[cur_set].val_is_get = 0;
                }
            }

            query_sets(Env, LogFile);
            RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "check_set_task: End check sets  cycle");
        }/* if ((status == E_OK) && ((*Env).p_number  > 0)) */
        else
            RSDURTGUtils_ErrCheck(LogFile, ERR_RMX, __LINE__, __FILE__, (int32_t)status, ERR_CONTINUE, "set_task: rq_receive_units() failed ");
    }/* while */
    RSDURTGUtils_DelCommPort(set_port,LogFile);
    Env->pthrd[4] = 0;
    RSDURTGUtils_LogClose(LogFile);
    return 0;
}
