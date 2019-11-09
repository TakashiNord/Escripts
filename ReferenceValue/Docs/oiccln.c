/************************************************************************/
/*  Name:  oiccln.c
Author: A.Vaguine
Desc:  OIC client task                                             */
/************************************************************************/
/************************************************************************/
/*  28.09.2010 Korshunov A.A. - Code review
1) Удалены все блоки кода для RMX                  */
/************************************************************************/

#include <pthread.h>
#include <stddef.h>
#include <string.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <rsdu2def.h>
#include <sys/socket.h>
#include <netdb.h>
#include <netinet/in.h>
#include <netinet/ip_icmp.h>
#include <sys_sign.h>
#include <db2const.h>
#include <rmxtbox.h>
#include <utils.h>

#include <dcs.h>

void *oiccln_task(void *Env1)
{
    LOG_HEADER      LogStruct;
    LOG_HEADER     *LogFile = &LogStruct;
    uint16_t        status = E_OK, wait = 0;
    pthread_t       MyToken;
    char           *Sbuf = NULL;
    OIC_BSTRUCT    *pOicBstruct = NULL;
    OIC_BSTRUCT   (*ppOicBstruct)[] = NULL;
    OIC_ASTRUCT    *pOicAstruct = NULL;
    OIC_ASTRUCT   (*ppOicAstruct)[] = NULL;
    OIC_REG        *pOicReg =(OIC_REG *)0, OicRegItem, (*ppOicReg)[] = NULL;
    POINT_PROP     *prb = NULL;
    REG_SRC        *pRegSrc = NULL;
    REG_TUNE       *pRegTune = NULL;
    UNITRANS_HEADER cd;
    time_t          rcv_sleep;
    int32_t         GoMimo = 1, i, j;
    int32_t         ok, ns, bad;
    uint32_t        reg_err = 0, reg_err_old = 0;
    int32_t         count_RegSrc;
    char            path[MAX_PATH_LEN];
    char            msg[256];
    REM_ADDR        dst_addr, *pCurAddr = NULL;
    REM_ADDR_EXT   *pCurAddrExt = NULL;
    uint16_t        port_id = 0;
    COMM_PORT      *pCommPort = NULL, *pQueryPort = NULL, *pControlPort = NULL;
    DCS_ENV        *Env = NULL;
    uint32_t        id_gtopt;
    const size_t    cszAddressSize = MAX_HOST_NAME_LEN + 6;
    char            sz_address[cszAddressSize];
    char            szCTick[CTICK_BUFFER_SIZE]; // Буфер для хранения строки времени (результат функции ctick_r)

// Enable pthreads cancel on test points
    pthread_setcancelstate(PTHREAD_CANCEL_ENABLE, NULL);
    pthread_setcanceltype(PTHREAD_CANCEL_DEFERRED, NULL);

// Testing cancel pthread state
    pthread_testcancel();

    rcv_sleep = 0;

    Env = (DCS_ENV*)Env1;
    MyToken = pthread_self();

    /* в списке источников находим первый, для которого не создана задача*/
    count_RegSrc = ListNumItems((*Env).source);
    for (i = 0; i < count_RegSrc; i++)
    {
        pRegSrc = (REG_SRC*)ListGetPtrToItem ((*Env).source, (i+1));
        if ( (*pRegSrc).task_id == (pthread_t)0xFFFF)
        {
            (*pRegSrc).task_id = MyToken;
            (*pRegSrc).src_state = SRC_START;
            break;
        }
    }

    /*если такого источника не найдено, то выходим*/
    if (i == count_RegSrc)
    {
        RSDURTGUtils_ErrCheck(LogFile, ERR_RMX, __LINE__, __FILE__, (int32_t)E_PARAM,ERR_DELETE,
            "oic_cln: start parameters no present ");
    }

    sprintf(path, "%soicnc_%02u.log", Env->LogFilePath, (*pRegSrc).id_src);
    RSDURTGUtils_LogInit(LogFile, DCS_SRC, Env->LogFileName, path, __FUNCTION__);

    /* Look up the main task synchronization semaphore */

    /*
    pCurAddr = RSDURTGUtils_GetServiceState((REM_ADDR *)ListGetDataPtr((*pRegSrc).SrcAddrList),
    (uint32_t)ListNumItems((*pRegSrc).SrcAddrList),
    LogFile,
    RSDURTGUtils_CheckDebug(LogFile));
    */
    /* 17.05.2007 Золотов М.Ю. Перешел на использование новой функции взамен RSDURTGUtils_GetServiceState */
    pCurAddrExt = RSDURTGUtils_GetServiceStateExt((REM_ADDR_EXT *)ListGetDataPtr((*pRegSrc).SrcAddrList),
        (uint32_t)ListNumItems((*pRegSrc).SrcAddrList),
        Env->system_node,
        LogFile,
        RSDURTGUtils_CheckDebug(LogFile));
    if (pCurAddrExt == (REM_ADDR_EXT *)0)
    {
        (*pRegSrc).task_id = 0;
        (*pRegSrc).src_state = SRC_NONPRESENT;
        RSDURTGUtils_SS_SendTaskState(NULL, (uint32_t)SS_SOURCEFAILED, SS_ALARM, LogFile, (*Env).FullPathName);

        RSDURTGUtils_UnilogMessage(LOG_ERR, LogFile,"oic_cln%04hx: OIC source %u - not master or not found",
            MyToken, (*pRegSrc).id_src);

        RSDURTGUtils_SendUnits((void*)&(*Env).ClnSyncSem, (uint16_t)1, &status);
        RSDURTGUtils_LogClose(LogFile);
        RSDURTGUtils_ThrExit(0, NULL, &status);
    }
    else
    {
        pCurAddr = &(pCurAddrExt->remaddr);
    }
    memcpy (&(*pRegSrc).CurAddr, pCurAddr,sizeof (REM_ADDR));
    pCurAddr = &(*pRegSrc).CurAddr;
    memcpy (&(*pRegSrc).save_addr, pCurAddr, sizeof (REM_ADDR));

    RSDURTGUtils_UnilogMessage(LOG_INFO, LogFile,"oic_cln%04hx: Start OIC source %u client session, gtype %u, gtopt %u, address: %s",
        MyToken, (*pRegSrc).id_src, (*pRegSrc).id_gtype, (*pRegSrc).id_gtopt, RSDURTGUtils_AddressToStr_r(pCurAddr, sz_address, cszAddressSize));


    /*создаем себе порт, для обмена данными с другими задачами*/
    port_id = 0;
    pCommPort = RSDURTGUtils_GetCommPort((uint16_t)(*pCurAddr).type, &port_id, &status, LogFile);
    if (pCommPort == (COMM_PORT*)NULL)
    {
        (*pRegSrc).task_id = 0;
        (*pRegSrc).src_state = SRC_NONPRESENT;
        RSDURTGUtils_SS_SendTaskState(NULL, (uint32_t)SS_SOURCEFAILED, SS_ALARM, LogFile, (*Env).FullPathName);
        /*rq_send_units (sync_sem, (uint16_t)1, &status);*/
        RSDURTGUtils_SendUnits((void*)&(*Env).ClnSyncSem, (uint16_t)1, &status);
        RSDURTGUtils_ErrCheck(LogFile, ERR_RMX, __LINE__, __FILE__, (int32_t)status, ERR_DELETE,
            "oic_cln: RSDURTGUtils_GetCommPort() failed ");
    }
    else
    {
        /*rq_send_units (sync_sem, (uint16_t)1, &status);*/
        RSDURTGUtils_SendUnits((void*)&(*Env).ClnSyncSem, (uint16_t)1, &status);
        RSDURTGUtils_ErrCheck(LogFile, ERR_RMX, __LINE__, __FILE__, (int32_t)status, ERR_CONTINUE, (const char *) 0);
    }
    if ((*pRegSrc).tune_num > 0)
    {
        (*pRegSrc).query_num = 0;
        for (i = 0; i < (int32_t)(*pRegSrc).tune_num; i++)
        {
            pRegTune = &(*(*pRegSrc).tune)[i];
            if((*pRegTune).pOwnPoint != (POINT_PROP*)0
                &&(*pRegTune).id_srci == (*(*pRegTune).pOwnPoint).cur_srci
                && (*pRegSrc).id_src == (*(*pRegTune).pOwnPoint).cur_src)
            {
                (*pRegTune).query = QUERY_YES;
                (*pRegSrc).query_num++;
            }
            else
                (*pRegTune).query = QUERY_NO;
        }

        if ((*pRegSrc).query_num == 0)
        {
            GoMimo = 0;
        }
        else /* (query_num > 0) */
        {
            if ((*pRegSrc).query_num > (*pRegSrc).tune_num)
            {
                RSDURTGUtils_UnilogMessage(LOG_ERR, LogFile, "oic_cln%04hx: Error tune, query - %u, present - %u ",
                    MyToken,(*pRegSrc).query_num, (*pRegSrc).tune_num);
            }
            j = 0;
            ListClear ((*pRegSrc).OicRegList);
            if ((*pRegSrc).id_gtopt == GLT_ANALOG_OPT_INSTANT
                || (*pRegSrc).id_gtopt == GLT_BOOL_OPT_INSTANT)
                id_gtopt = OIC_OK;
            else
                id_gtopt = (*pRegSrc).id_gtopt;

            for (i = 0; i < (int32_t)(*pRegSrc).tune_num; i++)
            {
                if ((*(*pRegSrc).tune)[i].query == QUERY_YES)
                {
                    pOicReg = (OIC_REG *)bsearch (&(*(*pRegSrc).tune)[i].src_id, ListGetDataPtr ((*pRegSrc).OicRegList), (size_t)j, sizeof(OIC_REG), oic_reg_id_comp);
                    if (pOicReg != (OIC_REG *)0) continue;
                    OicRegItem.id = (*(*pRegSrc).tune)[i].src_id;
                    OicRegItem.status = id_gtopt;
                    ListInsertInOrder((*pRegSrc).OicRegList,&OicRegItem, (CompareFunction)oic_reg_comp);
                    j++;
                }
            }
            ppOicReg = (OIC_REG(*)[])ListGetDataPtr ((*pRegSrc).OicRegList);
            RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile,"oic_cln%04hx: Query number: all - %u, diff - %u ",MyToken, (*pRegSrc).query_num, j);

            (*pRegSrc).query_num = j;
            if ((*pCurAddr).type == ADV_PROTO_TCP)
            {
                if (RSDURTGUtils_ConnectCommPort(pCommPort, pCurAddr, WAIT_FOREVER,  &status, LogFile) != 0)
                {
                    RSDURTGUtils_ErrCheck(LogFile, ERR_RMX, __LINE__, __FILE__, (int32_t)status, ERR_CONTINUE, "oic_cln: RSDURTGUtils_ConnectCommPort failed");
                    GoMimo = 2;
                }
            }
            memset(&cd, 0, sizeof(UNITRANS_HEADER));
            if (GoMimo == 1)
            {
                /* Отправляем запрос на установку соединения с сервером источником */
                wait = (uint16_t) 1000; // TODO: Remove Magic Numbers
                cd.command = CMD_OIC_OPEN;
                cd.status = OIC_OK;
                cd.dst_uid = 0xffff;
                cd.src_uid = (*Env).UserID;
                cd.param2 = (*pRegSrc).id_gtype;
                cd.data_len = 0;
                (*pRegSrc).src_state = SRC_CONNECT;

                if (RSDURTGUtils_SendCommPort((COMM_PORT *)pCommPort,
                    (REM_ADDR *) pCurAddr,
                    (UNITRANS_HEADER *)&cd,
                    (unsigned char *)0,
                    wait,
                    &status,
                    LogFile) < 0)
                {
                    RSDURTGUtils_ErrCheck(LogFile, ERR_RMX, __LINE__, __FILE__, (int32_t)status,ERR_CONTINUE,
                        "oic_cln: RSDURTGUtils_SendCommPort() failed ");
                    GoMimo = 2;
                }
                else
                {
                    /* Получаем ответ на запрос об установке соединения */
                    if (RSDURTGUtils_ReceiveCommPort((COMM_PORT *)pCommPort,
                        (REM_ADDR *) pCurAddr,
                        (UNITRANS_HEADER *)&cd,
                        (unsigned char **)&Sbuf,
                        wait,
                        &status,
                        LogFile) < 0)
                    {
                        RSDURTGUtils_ErrCheck(LogFile, ERR_RMX, __LINE__, __FILE__, (int32_t)status,ERR_CONTINUE,
                            "oic_cln: RSDURTGUtils_ReceiveCommPort() failed ");
                        GoMimo = 4;
                    }
                    else
                    {
                        if (cd.status == OIC_OK)
                        {
                            /*отправляем запрос на регистрации новых параметров*/
                            cd.command = CMD_OIC_REG;
                            cd.status = OIC_OK;
                            cd.dst_uid = 0xffff;
                            cd.src_uid = (*Env).UserID;
                            cd.param1 = (*pRegSrc).query_num;
                            cd.param2 = (*pRegSrc).id_gtype;
                            cd.data_len = sizeof(OIC_REG)*cd.param1;
                            if (RSDURTGUtils_SendCommPort((COMM_PORT *)pCommPort,
                                (REM_ADDR *) pCurAddr,
                                (UNITRANS_HEADER *)&cd,
                                (unsigned char *)ppOicReg,
                                wait,
                                &status,
                                LogFile) < 0)
                            {
                                RSDURTGUtils_ErrCheck(LogFile, ERR_RMX, __LINE__, __FILE__, (int32_t)status,ERR_CONTINUE,
                                    "oic_cln: RSDURTGUtils_SendCommPort() failed ");
                                GoMimo = 5;
                            }
                        }
                        else
                        {
                            /*после неудачного открытия соединения его надо закрыть*/
                            cd.command = CMD_OIC_CLOSE;
                            cd.status = OIC_OK;
                            cd.dst_uid = 0xffff;
                            cd.src_uid = (*Env).UserID;
                            cd.param1 = 0;
                            cd.param2 = (*pRegSrc).id_gtype;
                            cd.data_len = 0;
                            GoMimo = 8;
                            if (RSDURTGUtils_SendCommPort((COMM_PORT *)pCommPort,
                                (REM_ADDR *) pCurAddr,
                                (UNITRANS_HEADER *)&cd,
                                (unsigned char *)0,
                                wait,
                                &status,
                                LogFile) < 0)
                            {
                                RSDURTGUtils_ErrCheck(LogFile, ERR_RMX, __LINE__, __FILE__, (int32_t)status,ERR_CONTINUE,
                                    "oic_cln: RSDURTGUtils_SendCommPort() failed ");
                                GoMimo = 5;
                            }
                        }
                    }/* end установили соединение*/
                }/*end отправили запрос об установке соединения*/
            }
        }/*end есть текущие настройки*/
    }/*end есть настройки на источник-график*/

    if (GoMimo == 1)
    {
        if ((*pCurAddr).type == ADV_PROTO_TCP)
        {
            pQueryPort = pCommPort;
            pControlPort = pCommPort;
        }
        else
        {
            port_id = 0;
            pQueryPort = RSDURTGUtils_GetCommPort((uint16_t)(*pCurAddr).type, &port_id, &status, LogFile);
            if (pQueryPort == (COMM_PORT*)NULL)
            {
                RSDURTGUtils_ErrCheck(LogFile, ERR_RMX, __LINE__, __FILE__, (int32_t)status, ERR_CONTINUE,
                    "oic_cln: RSDURTGUtils_GetCommPort() failed ");
                GoMimo = 2;
            }
            else
            {
                port_id = 0;
                pControlPort = RSDURTGUtils_GetCommPort((uint16_t)(*pCurAddr).type, &port_id, &status, LogFile);
                if (pControlPort == (COMM_PORT*)NULL)
                {
                    RSDURTGUtils_ErrCheck(LogFile, ERR_RMX, __LINE__, __FILE__, (int32_t)status, ERR_CONTINUE,
                        "oic_cln: RSDURTGUtils_GetCommPort() failed ");
                    GoMimo = 2;
                }
            }
        }
        if (pQueryPort != NULL)
            memcpy (&(*pRegSrc).query_port, pQueryPort, sizeof (COMM_PORT));
        if (pControlPort != NULL)
            memcpy (&(*pRegSrc).control_port, pControlPort, sizeof (COMM_PORT));
    }

    wait = /*(*Env).TechCycle*3*/2000; // TODO: Remove Magic Numbers

    while (GoMimo == 1)
    {
// Testing cancel pthread state
        pthread_testcancel();

        RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "While begin. wait %hu, address: %s",
            wait, RSDURTGUtils_AddressToStr_r(pCurAddr, sz_address, cszAddressSize));

#ifdef _DEBUG
        start_slice = RSDURTGUtils_MonotonicTimeTick();
#endif
        if (RSDURTGUtils_ReceiveCommPort((COMM_PORT *)pCommPort,
            (REM_ADDR *) &dst_addr,
            (UNITRANS_HEADER *)&cd,
            (unsigned char **)&Sbuf,
            wait,
            &status,
            LogFile) == 0)
        {
#ifdef _DEBUG
            end_slice = RSDURTGUtils_MonotonicTimeTick();
            /* Вычисляем сколько висел RSDURTGUtils_ReceiveCommPort */
            rcv_sleep = (end_slice.tv_sec - start_slice.tv_sec)*100  + (end_slice.tv_usec - start_slice.tv_usec)/10000;
            if (rcv_sleep > 2*(*Env).TechCycle) /*  Если ждали дольше, чем тех. цикл, то ругнемся  */
            {
                RSDURTGUtils_ReceiveUnits((void*)&(*Env).FWriteSem,(uint16_t) 1, WAIT_FOREVER, &status);
                RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "oiccln: Wait %d*10ms, tech cycle %d*10ms (address %s) %s",
                    rcv_sleep, (*Env).TechCycle, RSDURTGUtils_AddressToStr_r(&(*pRegSrc).save_addr, sz_address, cszAddressSize), ctick_r(&end_slice, szCTick));

                RSDURTGUtils_SendUnits((void*)&(*Env).FWriteSem, (uint16_t)1, &status);
            }
#endif
            switch (cd.command)
            {
            case CMD_OIC_CLOSE:
                RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "Case CMD_OIC_CLOSE: command is %04x",
                    cd.command);
                GoMimo = 9;
                break;

            case CMD_OIC_REG:
                RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "Case CMD_OIC_REG: command is %04x",
                    cd.command);

                switch (cd.param2)
                {
                case GLOBAL_TYPE_BOOL:
                case GLOBAL_TYPE_ANALOG:
                    if (Sbuf != NULL)
                    {
                        (*pRegSrc).query_fail = cd.param1;
                        ppOicReg = (OIC_REG (*)[])Sbuf;
                        if ((*pRegSrc).query_fail > 0)
                        {
                            sprintf(msg,"REG Source %u registration error, not found %u parameters. ", (*pRegSrc).id_src, (*pRegSrc).query_fail);
                            for (i = 0; i < (int32_t)(*pRegSrc).query_fail; i++)
                            {
                                if ((*ppOicReg)[i].status != 0)
                                {
                                    sprintf(path,"ID %u, status %u ",
                                        (*ppOicReg)[i].id, (*ppOicReg)[i].status);
                                    if((strlen(path) + strlen(msg)) >= 250)
                                        break;
                                    strcat(msg, path);
                                }
                            }
                            RSDURTGUtils_UnilogMessage(LOG_WARNING, LogFile,"%s", msg);
                        }
                        if (cd.status != OIC_OK)
                            RSDURTGUtils_SS_SendTaskState(NULL, (uint32_t )SS_REGFAILED, SS_WARNING, LogFile, (*Env).FullPathName);
                        ppOicReg = NULL;
                        RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "Not registered %u from %u ", cd.param1, (*pRegSrc).query_num);
                    }
                    (*pRegSrc).src_state = SRC_READY;
                    break;
                default:
                    break;
                }
                if (Sbuf != NULL)
                {
                    RSDURTGUtils_SFree (Sbuf);
                    Sbuf = NULL;
                }
                break;
            case CMD_OIC_GETLIST:
                RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "Case CMD_OIC_GETLIST: command is %04x,param1=%u,param2=%u",
                    cd.command, cd.param1, cd.param2);

                reg_err_old = reg_err;

                i = 0; ok = 0; ns = 0; bad = 0; reg_err = 0;
                if (Sbuf != (char *)0)
                {
                    switch (cd.param2)
                    {
                    case GLOBAL_TYPE_BOOL:
                        RSDURTGUtils_SFree(ppOicBstruct);
                        ppOicBstruct = (OIC_BSTRUCT (*)[])Sbuf;
                        break;
                    case GLOBAL_TYPE_ANALOG:
                        RSDURTGUtils_SFree(ppOicAstruct);
                        ppOicAstruct = (OIC_ASTRUCT (*)[])Sbuf;
                        break;
                    default:
                        break;
                    }

                    {
                    RSDURTGUtils_AutoSem asPointSem((*Env).PointSem);
                    asPointSem.Receive(WAIT_FOREVER, &status);

                    /*  Подготовка к вычислению суммы  */
                    for (j = 0; j < (int32_t)(*pRegSrc).tune_num; j++)
                    {
                        pRegTune = &(*(*pRegSrc).tune)[j];
                        prb = (*pRegTune).pOwnPoint;
                        if(prb  == (POINT_PROP*)0
                            || (*pRegTune).query != QUERY_YES
                            || (*pRegTune).id_srci != (*prb).cur_srci
                            || (*pRegSrc).id_src != (*prb).cur_src) continue; /*  Не наш параметр  */
                        memset (&(*prb).CalcVal, 0, sizeof (POINT_VAL));  /*  Обнулили вычисляемое значение  */
                        if (cd.param2 == GLOBAL_TYPE_BOOL)
                        {
                            if (int((*pRegTune).coeff) == COEFFMODE_AND)
                                (*prb).CalcVal.Value.bval = 1;
                        }
                    }

                    /*  Суммирование значений источников  */
                    for (j = 0; j < (int32_t)(*pRegSrc).tune_num; j++)
                    {
                        pRegTune = &(*(*pRegSrc).tune)[j];
                        prb = (*pRegTune).pOwnPoint;
                        if(prb  == (POINT_PROP*)0
                            || (*pRegTune).query != QUERY_YES
                            || (*pRegTune).id_srci != (*prb).cur_srci
                            || (*pRegSrc).id_src != (*prb).cur_src) continue; /*  Не наш параметр  */

                        switch (cd.param2)
                        {
                        case GLOBAL_TYPE_BOOL:
                            /* Параметр нашли, теперь ищем полученное значение */
                            pOicBstruct = (OIC_BSTRUCT *)bsearch (&(*pRegTune).src_id,
                                ppOicBstruct,
                                (size_t)cd.param1,
                                sizeof(OIC_BSTRUCT),
                                oic_bl_id_comp);

                            if (pOicBstruct != (OIC_BSTRUCT *)0)
                            {
                                (*prb).CalcVal.status |= (*pOicBstruct).status;

                                if ((*prb).t_ft == POINT_SRC_NOCHANGED)
                                {
                                    struct timeval ttv = rsdutv2timetv( (*pOicBstruct).timetick );
                                    (*prb).CalcVal.TimeTick = RSDURTGUtils_GetOlderTick(&(*prb).CalcVal.TimeTick, &ttv);
                                }
                                else  /*  Если сменился источник, метка времени - момент перехода  */
                                {
                                    (*prb).CalcVal.TimeTick = RSDURTGUtils_TimeTick();
                                }
                                (*prb).CalcVal.TimeTickUpdate = RSDURTGUtils_TimeTick();

                                /* Zolotov M.Yu. 0-ой приоритет означает основной канал */
                                if (pRegTune->priority != CHANNEL_PRIORITY_HIGH)
                                    (*prb).CalcVal.status |=  OIC_DST_SUBSTITUTION;
                                else
                                    (*prb).CalcVal.status &= ~OIC_DST_SUBSTITUTION;

                                if (((*pOicBstruct).status & OIC_DST_VALID) == OIC_DST_OK)
                                    ok++;
                                else if (((*pOicBstruct).status & OIC_DST_NOPRESENT) == OIC_DST_NOPRESENT)
                                    ns++;
                                else if (((*pOicBstruct).status & OIC_DST_VALUENOCORRECT) == OIC_DST_VALUENOCORRECT)
                                    bad++;

                                if ((*pOicBstruct).value != 0)
                                    (*pOicBstruct).value = 1;

                                if ((*prb).Gtype == GLOBAL_TYPE_ANALOG)
                                    (*prb).CalcVal.Value.aval = (double)(*pOicBstruct).value;
                                else
                                    if (int((*pRegTune).coeff) == COEFFMODE_AND)
                                        (*prb).CalcVal.Value.bval &= (*pOicBstruct).value;
                                    else if (int((*pRegTune).coeff) == COEFFMODE_OR)
                                        (*prb).CalcVal.Value.bval |= (*pOicBstruct).value;
                                    else if (int((*pRegTune).coeff) == COEFFMODE_DBLTS)
                                    {
                                        if (pRegTune->index_val == 1)
                                        {
                                            (*prb).CalcVal.Value.bval = (*pOicBstruct).value;
                                        }
                                        else 
                                        if (pRegTune->index_val == 2)
                                        {
                                            if ((*prb).CalcVal.Value.bval == (*pOicBstruct).value)
                                                (*prb).CalcVal.status |= OIC_DST_VALUENOCORRECT;
                                        }
                                        else
                                            (*prb).CalcVal.status |= OIC_DST_VALUENOCORRECT;
                                    }
                                    else
                                        (*prb).CalcVal.Value.bval = (*pOicBstruct).value;
                            }
                            else
                            {
                                RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "Reg err: unknown id = %u <src_id = %u> ", (*pRegTune).my_id, (*pRegTune).src_id);
                                reg_err++;
                            }
                            break;

                        case GLOBAL_TYPE_ANALOG:
                            /* Параметр нашли, теперь ищем полученное значение */
                            pOicAstruct = (OIC_ASTRUCT *)bsearch (&(*pRegTune).src_id,
                                ppOicAstruct,
                                (size_t)cd.param1,
                                sizeof(OIC_ASTRUCT),
                                oic_an_id_comp);

                            if (pOicAstruct != (OIC_ASTRUCT *)0)
                            {
                                (*prb).CalcVal.status |= (*pOicAstruct).status;

                                if ((*prb).t_ft == POINT_SRC_NOCHANGED)
                                {
                                    struct timeval ttv = rsdutv2timetv( (*pOicAstruct).timetick );
                                    (*prb).CalcVal.TimeTick = RSDURTGUtils_GetOlderTick(&(*prb).CalcVal.TimeTick, &ttv);
                                }
                                else  /*  Если сменился источник, метка времени - момент перехода  */
                                    (*prb).CalcVal.TimeTick = RSDURTGUtils_TimeTick();
                                (*prb).CalcVal.TimeTickUpdate = RSDURTGUtils_TimeTick();

                                /* Zolotov M.Yu. 0-ой приоритет означает основной канал */
                                if (pRegTune->priority != CHANNEL_PRIORITY_HIGH)
                                    (*prb).CalcVal.status |=  OIC_DST_SUBSTITUTION;
                                else
                                    (*prb).CalcVal.status &= ~OIC_DST_SUBSTITUTION;

                                if (((*pOicAstruct).status & OIC_DST_VALID) == OIC_DST_OK)
                                    ok++;
                                else if (((*pOicAstruct).status & OIC_DST_NOPRESENT) == OIC_DST_NOPRESENT)
                                    ns++;
                                else if (((*pOicAstruct).status & OIC_DST_VALUENOCORRECT) == OIC_DST_VALUENOCORRECT)
                                    bad++;

                                (*prb).CalcVal.Value.aval += (*pOicAstruct).value * (*pRegTune).coeff;
                            }
                            else
                            {
                                RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "Reg err: unknown id = %u <src_id = %u> ", (*pRegTune).my_id, (*pRegTune).src_id);
                                reg_err++;
                            }
                            break;

                        default:
                            break;
                        }
                    }

                    /*  Занесение вычисленного значения в БДРВ сервера  */
                    for (j = 0; j < (int32_t)(*pRegSrc).tune_num; j++)
                    {
                        pRegTune = &(*(*pRegSrc).tune)[j];
                        prb = (*pRegTune).pOwnPoint;
                        if(prb  == (POINT_PROP*)0
                            || (*pRegTune).query != QUERY_YES
                            || (*pRegTune).id_srci != (*prb).cur_srci
                            || (*pRegSrc).id_src != (*prb).cur_src) continue; /*  Не наш параметр  */

                        if ((*prb).CalcVal.TimeTickUpdate.tv_sec == 0)  /*  Значение не рассчитано или уже внесено в БДРВ  */
                            continue;

                        (*prb).t_ft = POINT_SRC_NOCHANGED;
                        i++;

                        switch (cd.param2)  /*  Проводим масштабирование  */
                        {
                        case GLOBAL_TYPE_BOOL:
                            switch ((*prb).gtopt)
                            {
                            case GLT_BOOL_OPT_TELECONTROL_SINGLE:
                            case GLT_BOOL_OPT_TELECONTROL_DOUBLE:
                            case GLT_BOOL_OPT_TELECONTROL_SELECT:
                            case GLT_BOOL_OPT_TELECONTROL_PULSE_SHORT:
                            case GLT_BOOL_OPT_TELECONTROL_PULSE_LONG:
                                /* Блокировка ТУ будет снята если получили достоверное значение */
                                if (((*prb).CalcVal.Value.bval == 0) && ((*prb).CalcVal.status & OIC_DST_VALID) == OIC_DST_OK)
                                    (*prb).State &= ~DCP_DST_CONTRLOCK;
                                else
                                    (*prb).State |= DCP_DST_CONTRLOCK;
                                break;

                            default:
                                (*prb).NoScaledCurrentVal = (*prb).CalcVal;  /* Сохраняем неинвертированное значение */
                                (*prb).CurrentVal = (*prb).CalcVal;

                                if ((*prb).Gtype == GLOBAL_TYPE_ANALOG)/* Если у нас преобразование типов (из булевого в аналоговый) */
                                {
                                    if (((*prb).State & DCP_DST_VALUESCALED) == DCP_DST_VALUESCALED)  /* Пересчет из квантов */
                                    {
                                        (*prb).CurrentVal.Value.aval = ((( (*prb).ScaleMax - (*prb).ScaleMin)
                                            / (*prb).Scale)* (*prb).CalcVal.Value.aval)
                                            + (*prb).ScaleMin;
                                    }
                                    else
                                        (*prb).CurrentVal.Value.aval = (*prb).CalcVal.Value.aval * (*prb).Scale; /* Масштабирование ТИ */
                                    RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "Point id %u val (converted) %lf, status %x, tag %s",
                                        (*prb).id, (*prb).CurrentVal.Value.aval, (*prb).CurrentVal.status, ctick_r(&(*prb).CurrentVal.TimeTick, szCTick));
                                }
                                else
                                {
                                    if((*prb).Scale < 0) /* Инверсия ТС */
                                        (*prb).CurrentVal.Value.bval = (~(*prb).CalcVal.Value.bval) & 0x1;
                                    RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "Point id %u val %d, status %x, tag %s",
                                        (*prb).id, (*prb).CurrentVal.Value.bval, (*prb).CurrentVal.status, ctick_r(&(*prb).CurrentVal.TimeTick, szCTick));
                                }
                                break;
                            }
                            break;

                        case GLOBAL_TYPE_ANALOG:
                            (*prb).NoScaledCurrentVal = (*prb).CalcVal;  /* Сохраняем неинвертированное значение */
                            (*prb).CurrentVal = (*prb).CalcVal;

                            if (((*prb).State & DCP_DST_VALUESCALED) == DCP_DST_VALUESCALED)  /* Пересчет из квантов */
                            {
                                (*prb).CurrentVal.Value.aval = ((( (*prb).ScaleMax - (*prb).ScaleMin)
                                    / (*prb).Scale)* (*prb).CalcVal.Value.aval)
                                    + (*prb).ScaleMin;
                            }
                            else
                                (*prb).CurrentVal.Value.aval = (*prb).CalcVal.Value.aval * (*prb).Scale; /* Масштабирование ТИ */

                            RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "Point id %u val %lf, status %x, tag %s",
                                (*prb).id, (*prb).CurrentVal.Value.aval, (*prb).CurrentVal.status, ctick_r(&(*prb).CurrentVal.TimeTick, szCTick));
                            break;

                        default:
                            break;
                        }/* end switch param2 */

                        if (CheckPointUpdated(prb))
                        {
                            (*prb).LastSentVal = (*prb).CurrentVal;
                            (*prb).NoScaledLastSentVal = (*prb).NoScaledCurrentVal;
                            SendToADCPUpdatedValue(Env, prb);
                        }
                        (*prb).CalcVal.TimeTickUpdate.tv_sec = 0;
                        /* переходим к следующей настройке */
                    }
                    (*pRegSrc).last_query_time = RSDURTGUtils_Time70();

                    asPointSem.Send(&status);
                    }
                }

                (*pRegSrc).src_state = SRC_READY;
                /*rq_send_units ((*Env).TechSem, (uint16_t)1, &status);*/
                RSDURTGUtils_SendUnits((void*)&(*Env).TechSem, (uint16_t)1, &status);
                /* 6.11.2009 Вагин А.А. При ошибке регистрации данный сигнал уже приходит при обработке команды CMD_OIC_ADD
                if ((reg_err > 0) && (reg_err != reg_err_old))
                RSDURTGUtils_SS_SendTaskState((COMM_PORT*)NULL, (uint32_t)SS_REGFAILED, SS_WARNING, LogFile, (*Env).FullPathName);  */
                RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "Find %u param from %u ", i, cd.param1);
                RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "Ok %u, Bad %u, No source %u reg_err %u ", ok, bad, ns, reg_err);

                RSDURTGUtils_SFree(Sbuf);
                Sbuf = (char *)0;
                ppOicBstruct = (OIC_BSTRUCT (*)[])0;
                ppOicAstruct = (OIC_ASTRUCT (*)[])0;
                break;

            case CMD_OIC_ADD:
                RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "Case CMD_OIC_ADD: command is %04x",
                    cd.command);

                switch (cd.param2)
                {
                case GLOBAL_TYPE_BOOL:
                case GLOBAL_TYPE_ANALOG:
                    if (Sbuf != NULL)
                    {
                        (*pRegSrc).query_fail = cd.param1;
                        ppOicReg = (OIC_REG (*)[])Sbuf;
                        if (cd.status != OIC_OK)
                        {
                            RSDURTGUtils_SS_SendTaskState(NULL, (uint32_t )SS_REGFAILED, SS_WARNING, LogFile, (*Env).FullPathName);
                            RSDURTGUtils_UnilogMessage(LOG_WARNING, LogFile, "ADD Source %u registration error. Not registered %u from %u parameters.", (*pRegSrc).id_src, cd.param1, (*pRegSrc).query_num);
                        }
                        ppOicReg = NULL;
                    }
                    break;
                default:
                    break;
                }
                if (Sbuf != NULL)
                {
                    RSDURTGUtils_SFree(Sbuf);
                    Sbuf = (char *)0;
                }
                break;
            case CMD_OIC_REM:
                RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "Case CMD_OIC_REM");

                if ((*pRegSrc).query_num == 0)/* Корректное отключение от источника при отсутствии текущих настроек на источник */
                {
                    GoMimo = 10;
                    RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "Case CMD_OIC_REM: List of registration is NULL. Task deleted.");
                }
                if (Sbuf != NULL)
                {
                    RSDURTGUtils_SFree(Sbuf);
                    Sbuf = (char *)0;
                }
                break;

            default:
                RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "Case default: command is %04x", cd.command);

                RSDURTGUtils_SFree(Sbuf);
                Sbuf = NULL;
                break;
            }
        }
        else
        {
            if(Env->DriverAbortFlag)
                break;
#ifdef _DEBUG
            RSDURTGUtils_ReceiveUnits((void*)&(*Env).FWriteSem,(uint16_t) 1, WAIT_FOREVER, &status);
#endif
            if (status != E_TIME && status != EINTR)
                RSDURTGUtils_ErrCheck(LogFile, ERR_RMX, __LINE__, __FILE__, (int32_t)status,ERR_CONTINUE, "RSDURTGUtils_ReceiveCommPort() ");
#ifdef _DEBUG
            RSDURTGUtils_SendUnits((void*)&(*Env).FWriteSem, (uint16_t)1, &status);
#endif
            GoMimo = 7;
        }
    }
    (*pRegSrc).src_state = SRC_NONPRESENT;
    switch (GoMimo)
    {
    case 2:
    case 3:
    case 4:
    case 5:
    case 6:
    case 7:
    case 8:
        RSDURTGUtils_SS_SendTaskState(NULL, (uint32_t)SS_SOURCEFAILED, SS_ALARM, LogFile, (*Env).FullPathName);
        break;
    case 10: /* Корректное отключение от источника при отсутствии текущих настроек на источник */
        cd.command = CMD_OIC_CLOSE;
        cd.status = OIC_OK;
        cd.dst_uid = 0xffff;
        cd.src_uid = (*Env).UserID;
        cd.param1 = 0;
        cd.param2 = (*pRegSrc).id_gtype;
        cd.param3 = 0;
        cd.data_len = 0;
        cd.time1970 = RSDURTGUtils_Time70();
        RSDURTGUtils_SendCommPort((COMM_PORT *)pCommPort,
            (REM_ADDR *) pCurAddr,
            (UNITRANS_HEADER *)&cd,
            (unsigned char *)0,
            wait,
            &status,
            LogFile);
        break;
    default:
        break;
    }

    memset (&(*pRegSrc).query_port, 0, sizeof (COMM_PORT));
    memset (&(*pRegSrc).control_port, 0, sizeof (COMM_PORT));
    memset (&(*pRegSrc).CurAddr, 0, sizeof (REM_ADDR));

    if (pQueryPort != NULL && pQueryPort != pCommPort)
        RSDURTGUtils_DelCommPort(pQueryPort, LogFile);

    if (pControlPort != NULL && pControlPort != pCommPort)
        RSDURTGUtils_DelCommPort(pControlPort, LogFile);

    RSDURTGUtils_DelCommPort(pCommPort, LogFile);

    {
    RSDURTGUtils_AutoSem asPointSem((*Env).PointSem);
    asPointSem.Receive(WAIT_FOREVER, &status);

    for (i = 0; i < ListNumItems ((*Env).Point); i++)
    {
        prb = (POINT_PROP*)ListGetPtrToItem ((*Env).Point, i+1);
        if ((*prb).cur_src != (*pRegSrc).id_src)
            continue;
        if ((prb->gtopt == GLT_BOOL_OPT_TELECONTROL_SINGLE) || 
            (prb->gtopt == GLT_BOOL_OPT_TELECONTROL_DOUBLE) ||
            (prb->gtopt == GLT_BOOL_OPT_TELECONTROL_SELECT) ||
            (prb->gtopt == GLT_BOOL_OPT_TELECONTROL_PULSE_SHORT) ||
            (prb->gtopt == GLT_BOOL_OPT_TELECONTROL_PULSE_LONG)
            )
            (*prb).State |= DCP_DST_CONTRLOCK;

        if (CheckPointMaster(prb))
            continue;
        (*prb).CurrentVal.TimeTickUpdate = RSDURTGUtils_TimeTick();
        (*prb).CurrentVal.status = OIC_DST_NOPRESENT;
        /* Обнуляем свойство смены источника - текущий источник недоступен */
        (*prb).t_ft = POINT_SRC_NOCHANGED;
        /* Сохраняем немасштабированное значение */
        (*prb).NoScaledCurrentVal.TimeTickUpdate = (*prb).CurrentVal.TimeTickUpdate;
        (*prb).NoScaledCurrentVal.status = (*prb).CurrentVal.status;
        if (CheckPointUpdated(prb))
        {
            (*prb).LastSentVal = (*prb).CurrentVal;
            (*prb).NoScaledLastSentVal = (*prb).NoScaledCurrentVal;
            SendToADCPUpdatedValue(Env, prb);
        }
    }

    asPointSem.Send(&status);
    }

    ListClear ((*pRegSrc).OicRegList);
#ifdef _DEBUG
    RSDURTGUtils_ReceiveUnits((void*)&(*Env).FWriteSem,(uint16_t) 1, WAIT_FOREVER, &status);
#endif
    RSDURTGUtils_UnilogMessage(LOG_DEBUG, LogFile, "End OIC client task, address: %s", RSDURTGUtils_AddressToStr_r(&(*pRegSrc).save_addr, sz_address, cszAddressSize));

#ifdef _DEBUG
    /*rq_send_units ((*Env).FWriteSem, (uint16_t)1, &status);*/
    RSDURTGUtils_SendUnits((void*)&(*Env).FWriteSem, (uint16_t)1, &status);
#endif


    RSDURTGUtils_LogClose(LogFile);
    (*pRegSrc).task_id = (pthread_t)0;
    RSDURTGUtils_ThrExit(0, NULL, &status);
    return 0;
}
