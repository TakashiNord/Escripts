/*
* RSDU2 electrical and other parameter server
* Alexandr V. Strelnikov
* 06-11-2000
* Start version 3.01
*/

/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
4 марта 2003г., Макаренко Е.А.: изменение чтения значений ручного ввода для уставок 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
#include <stddef.h>
#include <string.h>
#include <errno.h>
#include <stdio.h>
#include <strings.h>
#include <stdlib.h>
#include <rsdu2def.h>
#include <rsdusql.h>
#include <rmxtbox.h>
#include <utils.h>
#include <db2const.h>
#include <sys_sign.h>
#include <elreg30.h>

int32_t set_depend_clear(ELRSRV_ENV *env, LOG_HEADER *lfp)
{
    SET_DEPEND    **ppSetDepend = NULL;
    int32_t         j = 0;

    RSDURTGUtils_UnilogMessage(LOG_DEBUG, lfp, "set_depend_db_read(): Cleaning Sets.");

    if( env != NULL )
    {
        /* Чистим старую таблицу соответствия */
        for (j = ListNumItems(env->SetsDependenceList) - 1; j >= 0; j--)
        {
            ppSetDepend = (SET_DEPEND **)ListGetPtrToItem(env->SetsDependenceList, (int32_t)(j + 1));
            if ((*(*ppSetDepend)).values != NULL)
            {
                ListDispose((*(*ppSetDepend)).values);
                (*(*ppSetDepend)).values = NULL;
            }
            RSDURTGUtils_SFree(*ppSetDepend);
            *ppSetDepend = NULL;
        }
        ListClear(env->SetsDependenceList);
    }

    return 0;
}


/* Чтение косвенных уставок */
int32_t set_depend_db_read(ELRSRV_ENV *env, DB_ACCES_INFO *ui, char *buf, uint32_t *db_err, LOG_HEADER* lfp)
{
    char                *rec = NULL;
    int32_t              err = 0, count = 0, nscan = 0, i = 0, j = 0;
    uint32_t             cur_id_set = 0;
    uint16_t             status = E_OK;
    SET_DEPEND         **ppSetDepend = NULL;
    SET_DEPEND          *pSetDepend = NULL;
    SET_DEPEND_VALUE     DependValue;
    SET_DEPEND_VALUE_DB (*ppDependValue)[] = NULL;


    if(ui->a_load_info != NULL)
    {
        RSDURTGUtils_UnilogMessage(LOG_DEBUG, lfp, "set_depend_db_read(): Read the depended sets");

        sprintf((char *)buf, EOR_DEPENDENT_SVAL_SQL, BASE_EL_DEPENDENT_SVAL, BASE_SVAL, (*env).MyLstTableName);
        if(ui->a_load_info != NULL)
            count = RSDURTGUtils_DBSQLExecAL(ui, buf, ELR_DB_WAIT, lfp);
        else
            count = RSDURTGUtils_DBSQLExec(ui, buf, ELR_DB_WAIT, lfp);
        if (count >= 0)
        {
            if (count > 0)
            {
                ppDependValue = (SET_DEPEND_VALUE_DB (*)[])RSDURTGUtils_SCalloc(sizeof(SET_DEPEND_VALUE_DB),(uint32_t )count);
                if (ppDependValue == NULL)
                    err = -1;
                else
                {
                    i = 0;
                    if(ui->a_load_info != NULL)
                        rec = RSDURTGUtils_DBFetchAL(ui);
                    else
                        rec = RSDURTGUtils_DBFetch(ui);
                    while (rec != (char *)0)
                    {
                        nscan = sscanf((const char *)rec, (const char *)EOR_DEPENDENT_SVAL_FMT,
                            &(*ppDependValue)[i].id,
                            &(*ppDependValue)[i].id_set,
                            &(*ppDependValue)[i].cr_value,
                            &(*ppDependValue)[i].value_min,
                            &(*ppDependValue)[i].value_max);
                        if (nscan != EOR_DEPENDENT_SVAL_NUM)
                        {
                            RSDURTGUtils_UnilogMessage(LOG_DEBUG, lfp, "set_depend_db_read(): scanf error, need - %d, scan - %d ", EOR_DEPENDENT_SVAL_NUM, nscan);
                            (*db_err)++;
                        }
                        i++;

                        if(ui->a_load_info != NULL)
                            rec = RSDURTGUtils_DBFetchAL(ui);
                        else
                            rec = RSDURTGUtils_DBFetch(ui);
                    }
                }
            }
            else
            {
                RSDURTGUtils_UnilogMessage(LOG_DEBUG, lfp, "There are no depended sets configured.");
                RSDURTGUtils_DBDataDispose(ui);
                return 0;
            }
        }
        else
        {
            RSDURTGUtils_UnilogMessage(LOG_ERR, lfp, "set_depend_db_read(): %s, %s", buf, RSDURTGUtils_DBGetError(ui));
            err = -1;
        }
        RSDURTGUtils_DBDataDispose(ui);

        if (err == 0)
        {
            /* Ждем семафора на доступ к таблице соответствия для косвенных уставок */
            RSDURTGUtils_ReceiveUnits((void*)&env->sets_depend_sem, (uint16_t)1, ELR_COMMON_WAIT, &status);
            RSDURTGUtils_ErrCheck(lfp, ERR_RMX, __LINE__, __FILE__, (int32_t)status, ERR_CONTINUE, "set_depend_db_read(): rq_receive_units on sets_depend_sem ");

            /* Чистим старую таблицу соответствия */
            for (j = ListNumItems(env->SetsDependenceList) - 1; j >= 0; j--)
            {
                ppSetDepend = (SET_DEPEND **)ListGetPtrToItem(env->SetsDependenceList, (int32_t)(j + 1));
                if ((*(*ppSetDepend)).values != NULL)
                {
                    ListDispose((*(*ppSetDepend)).values);
                    (*(*ppSetDepend)).values = NULL;
                }
                RSDURTGUtils_SFree(*ppSetDepend);
                *ppSetDepend = NULL;
            }
            ListClear(env->SetsDependenceList);

            /* А теперь раскидываем полученные значения отдельно по уставкам */
            j = 0;
            while (j < i)
            {
                cur_id_set = (*ppDependValue)[j].id_set;
                pSetDepend = (SET_DEPEND *)RSDURTGUtils_SMalloc((uint32_t)sizeof(SET_DEPEND));
                if (pSetDepend == NULL)
                {
                    err = -1;
                    RSDURTGUtils_ErrCheck(lfp, ERR_RMX, __LINE__, __FILE__, (int32_t)E_MEM, ERR_CONTINUE, "set_depend_db_read(): OUT of Memory ");
                    j++;
                }
                else
                {
                    pSetDepend->id_set = cur_id_set;
                    pSetDepend->values = ListCreate((int32_t)sizeof(SET_DEPEND_VALUE));
                    if (pSetDepend->values == NULL)
                    {
                        err = -1;
                        RSDURTGUtils_ErrCheck(lfp, ERR_RMX, __LINE__, __FILE__, (int32_t)E_MEM, ERR_CONTINUE, "set_depend_db_read(): OUT of Memory ");
                        j++;
                    }
                    else
                    {
                        while (j < i &&
                            cur_id_set == (*ppDependValue)[j].id_set)
                        {
                            DependValue.cr_value = (*ppDependValue)[j].cr_value;
                            DependValue.value_max = (*ppDependValue)[j].value_max;
                            DependValue.value_min = (*ppDependValue)[j].value_min;
                            if (ListInsertItems(pSetDepend->values, (void *)&DependValue, END_OF_LIST, (int32_t)1) == 0)
                                err = -1;
                            j++;
                        }
                        /* sort on cr_value ??? */

                        if (ListInsertItems(env->SetsDependenceList, (void *)&pSetDepend, END_OF_LIST, (int32_t)1) == 0)
                            err = -1;
                    }
                }
            }/* while (j < i) */

            /* Освобождаем семафор на доступ к таблице соответствия для косвенных уставок */
            RSDURTGUtils_SendUnits((void*)&env->sets_depend_sem, (uint16_t)1, &status);
            RSDURTGUtils_ErrCheck(lfp, ERR_RMX, __LINE__, __FILE__, (int32_t)status, ERR_CONTINUE, "set_depend_db_read(): rq_send_units on sets_depend_sem ");
        }/* if (err == 0) */

        if (ppDependValue != NULL)
        {
            RSDURTGUtils_SFree(ppDependValue);
            ppDependValue = NULL;
        }
    }

    return err;
}

int32_t set_clear(ELRSRV_ENV *env, LOG_HEADER *lfp)
{
    RSDURTGUtils_UnilogMessage(LOG_DEBUG, lfp, "set_db_read(): Cleaning Sets.");

    if( env != NULL )
    {
        ListClear(env->SetsList);
        ListClear(env->Sets_ManualSrcList);
        ListClear(env->Sets_OwnList);

        if( env->ppReg_Set != NULL )
        {
            RSDURTGUtils_SFree(env->ppReg_Set);
            env->ppReg_Set = NULL;
        }
    }

    return 0;
}

/* Чтение уставок */
int32_t set_db_read(ELRSRV_ENV *env, DB_ACCES_INFO *ui, char *buf, uint32_t *db_err, LOG_HEADER* lfp)
{
    REG_SET     (*ppRegSet)[] = NULL;
    REG_BASE     *pRegBase = NULL;
    SET_MANUAL  (*ppSetManual)[] = NULL;
    SET_OWN     (*ppSetOwn)[] = NULL;
    uint32_t      par_id = 0;
    char         *rec = NULL;
    int32_t       err = 0, count,  nscan, i = 0, ii = 0;

    if(ui->a_load_info != NULL)
    {
        RSDURTGUtils_UnilogMessage(LOG_DEBUG, lfp, "set_db_read(): Read the sets");

        sprintf((char *)buf, EOR_SVAL_SQL, BASE_SVAL, BASE_LEV, BASE_SSRC_CHANNEL, (*env).MyLstTableName);
        (*env).ppReg_Set = NULL;
        RSDURTGUtils_UnilogMessage(LOG_DEBUG, lfp, "set_db_read(): prepare to exec=<%s> ", buf);

        if ((count = RSDURTGUtils_DBSQLExecAL(ui, buf, ELR_DB_WAIT, lfp)) >= 0)
        {
            if (count > 0)
            {
                ppRegSet = (REG_SET (*)[])RSDURTGUtils_SCalloc(sizeof(REG_SET),(uint32_t )count);
                (*env).ppReg_Set = (REG_SET **)RSDURTGUtils_SCalloc(sizeof(REG_SET *),(uint32_t )count);
                if ((ppRegSet == NULL) || ((*env).ppReg_Set == NULL))
                    err=-1;
                else
                {
                    i = 0;
                    while ((rec = RSDURTGUtils_DBFetchAL(ui)) != (char *)0)
                    {
                        nscan = sscanf((const char *)rec, (const char *)EOR_SVAL_FMT,
                            &(*ppRegSet)[i].id,
                            &(*ppRegSet)[i].id_param,
                            &(*ppRegSet)[i].id_level,
                            &(*ppRegSet)[i].id_src,
                            &(*ppRegSet)[i].id_srci,
                            &(*ppRegSet)[i].notify_period,
                            /*&(*ppRegSet)[i].m_min_val,
                            &(*ppRegSet)[i].m_max_val,*/
                            &(*ppRegSet)[i].sets_type,
                            &(*ppRegSet)[i].priority,
                            &(*ppRegSet)[i].start_signal_id,
                            &(*ppRegSet)[i].cont_signal_id,
                            &(*ppRegSet)[i].hyst_period
                            );

                        if (nscan != EOR_SVAL_NUM)
                        {
                            RSDURTGUtils_UnilogMessage(LOG_DEBUG, lfp, "set_db_read(): scanf error, need - %d, scan - %d ", EOR_SVAL_NUM, nscan);
                            (*db_err)++;
                        }
                        (*ppRegSet)[i].min_val = (*ppRegSet)[i].min_val_final = MIN_PARAM_VALUE;
                        (*ppRegSet)[i].max_val = (*ppRegSet)[i].max_val_final = MAX_PARAM_VALUE;
                        (*ppRegSet)[i].val_is_get = 0;
                        i++;
                    }
                    if (ListInsertItems((*env).SetsList, (void *)ppRegSet, FRONT_OF_LIST, (int32_t) count) == 0)
                        err = -1;
                    RSDURTGUtils_SFree(ppRegSet);
                    ppRegSet = NULL;
                }
            }
            else
            {
                RSDURTGUtils_UnilogMessage(LOG_DEBUG, lfp, "There are no sets configured.");
                RSDURTGUtils_DBDataDispose(ui);
                return(0);
            }
        }
        else
        {
            RSDURTGUtils_UnilogMessage(LOG_ERR, lfp, "set_db_read(): %s, %s ", buf, RSDURTGUtils_DBGetError(ui));
            err = -1;
        }
        RSDURTGUtils_DBDataDispose(ui);

        if (err < 0)
        {
            if(ppRegSet != NULL)
                RSDURTGUtils_SFree(ppRegSet);
            if ((*env).ppReg_Set != NULL)
            {
                RSDURTGUtils_SFree((*env).ppReg_Set);
                (*env).ppReg_Set = NULL;
            }
            return(err);
        }
        /* ~~~~~~~~~~~~ 4 марта 2003г., Макаренко Е.А.: чтение ручного ввода уставок ~~~~~~~~~~~~ */
        RSDURTGUtils_UnilogMessage(LOG_DEBUG, lfp, "set_db_read(): READ the sets MANUAL values");


        sprintf((char *)buf, EOR_SETS_MAN_SQL, BASE_SSRC_CHANNEL, BASE_SVAL, BASE_SSRC_CHANNEL_MNL, (*env).MyLstTableName);
        RSDURTGUtils_UnilogMessage(LOG_DEBUG, lfp, "set_db_read(): prepare to exec=<%s> ", buf);

        if ((count = RSDURTGUtils_DBSQLExecAL(ui, buf, ELR_DB_WAIT, lfp)) >= 0)
        {
            if (count > 0)
            {
                ppSetManual = (SET_MANUAL (*)[])RSDURTGUtils_SCalloc(sizeof(SET_MANUAL), (uint32_t )count);
                if (ppSetManual == (SET_MANUAL (*)[])0)
                {
                    RSDURTGUtils_UnilogMessage(LOG_DEBUG, lfp, "set_db_read(): READ the sets MANUAL RSDURTGUtils_SCalloc was FAILED ");
                    err = -1;
                }
                else
                {
                    i = 0;
                    while ((rec = RSDURTGUtils_DBFetchAL(ui)) != (char *)0)
                    {
                        RSDURTGUtils_UnilogMessage(LOG_DEBUG, lfp, "set_db_read(): READ the sets MANUAL RSDURTGUtils_DBFetch: %s ", rec);

                        nscan = sscanf((const char *)rec, (const char *)EOR_SETS_MAN_SQL_FMT,
                        &(*ppSetManual)[i].id_set,
                        &(*ppSetManual)[i].id_srci,
                        &(*ppSetManual)[i].id_src,
                        &(*ppSetManual)[i].m_min_val,
                        &(*ppSetManual)[i].m_max_val,
                        &(*ppSetManual)[i].m_disper,
                        &(*ppSetManual)[i].m_state);
                        if (nscan != EOR_SETS_MAN_NUM)
                        {
                            RSDURTGUtils_UnilogMessage(LOG_DEBUG, lfp, "set_db_read(): SETS manual values scanf error, need - %d, scan - %d, SET_ID %u ",
                                EOR_SETS_MAN_NUM, nscan, (*ppSetManual)[i].id_set);
                            (*db_err)++;
                        }
                        i++;
                    }/* end of while ... RSDURTGUtils_DBFetch ... */

                    if (ListInsertItems((*env).Sets_ManualSrcList, (void *)ppSetManual, FRONT_OF_LIST, (int32_t) count) == 0)
                        err = -1;
                    RSDURTGUtils_SFree(ppSetManual);
                }
            }
        }/* end of if ... RSDURTGUtils_DBSQLExec ... */
        else
        {
            RSDURTGUtils_UnilogMessage(LOG_ERR, lfp, "set_db_read( sets manual values): %s, %s", buf, RSDURTGUtils_DBGetError(ui));
            err = -1;
        }
        RSDURTGUtils_DBDataDispose(ui);

        /* 29.06.2005 Вагин А.А. чтение параметров собственных источников уставок */
        RSDURTGUtils_UnilogMessage(LOG_DEBUG, lfp, "set_db_read(): READ the sets OWN values");

        sprintf((char *)buf, EOR_SETS_OWN_SQL, BASE_SVAL,BASE_SSRC_CHANNEL_TUNE, BASE_SSRC_CHANNEL, BASE_SSRC_CHAN_PAR_KOEF,
            (*env).MyLstTableName, (*env).MyLstTableID);

        RSDURTGUtils_UnilogMessage(LOG_DEBUG, lfp, "set_db_read(): prepare to exec=<%s> ", buf);

        (*env).Sets_OnwSrcId = 0;
        if ((count = RSDURTGUtils_DBSQLExecAL(ui, buf, ELR_DB_WAIT, lfp)) >= 0)
        {
            if (count > 0)
            {
                ppSetOwn = (SET_OWN (*)[])RSDURTGUtils_SCalloc(sizeof(SET_OWN),(uint32_t )count);
                if (ppSetOwn == (SET_OWN (*)[])0)
                {
                    RSDURTGUtils_UnilogMessage(LOG_DEBUG, lfp, "set_db_read(): READ the sets OWN RSDURTGUtils_SCalloc was FAILED ");
                    err = -1;
                }
                else
                {
                    i = 0;
                    while ((rec = RSDURTGUtils_DBFetchAL(ui)) != (char *)0)
                    {
                        nscan = sscanf((const char *)rec, (const char *)EOR_SETS_OWN_SQL_FMT,
                            &(*ppSetOwn)[i].id_set,
                            &(*ppSetOwn)[i].id_srci,
                            &(*ppSetOwn)[i].id_src,
                            &(*ppSetOwn)[i].src_id,
                            &(*ppSetOwn)[i].coeff);
                        if (nscan != EOR_SETS_OWN_NUM)
                        {
                            RSDURTGUtils_UnilogMessage(LOG_DEBUG, lfp, "set_db_read(): SETS own values scanf error, need - %d, scan - %d, SET_ID %u ",
                                    EOR_SETS_OWN_NUM, nscan, (*ppSetOwn)[i].id_set);

                            (*db_err)++;
                        }
                        if ((*env).Sets_OnwSrcId == 0)
                            (*env).Sets_OnwSrcId = (*ppSetOwn)[i].id_src;
                        else if ((*env).Sets_OnwSrcId != (*ppSetOwn)[i].id_src)
                        {
                            RSDURTGUtils_UnilogMessage(LOG_WARNING, lfp, "set_db_read(): WARNING: More than 1 own source (%u, %u)",(*env).Sets_OnwSrcId, (*ppSetOwn)[i].id_src);
                        }
                        i++;
                    }/* end of while ... RSDURTGUtils_DBFetch ... */

                    if (ListInsertItems((*env).Sets_OwnList, (void *)ppSetOwn, FRONT_OF_LIST, (int32_t) count) == 0)
                        err = -1;
                    RSDURTGUtils_SFree(ppSetOwn);
                }
            }
        }/* end of if ... RSDURTGUtils_DBSQLExec ... */
        else
        {
            RSDURTGUtils_UnilogMessage(LOG_ERR, lfp, "set_db_read( sets own values): %s, %s ", buf, RSDURTGUtils_DBGetError(ui));
            err = -1;
        }
        RSDURTGUtils_DBDataDispose(ui);

        /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
        nscan = ListNumItems((*env).SetsList);
        ppRegSet = (REG_SET (*)[])ListGetDataPtr((*env).SetsList);
        for (i = 0; i < nscan; i++)
        {
            (*env).ppReg_Set[i] = &(*ppRegSet)[i];
            if (par_id != (*ppRegSet)[i].id_param)
            {
                if ((ii != i) && (pRegBase != NULL))
                {
                    (*pRegBase).set_level_number = i - ii;
                }
                ii = i;
                par_id = (*ppRegSet)[i].id_param;
                pRegBase = (REG_BASE *)bsearch (&par_id, (*env).ppRegBase,
                    (size_t)ListNumItems ((*env).RegBaseList), (size_t)ListGetItemSize((*env).RegBaseList), base_id_comp);
                if (pRegBase != NULL)
                {
                    /* что то я не понимаю, и компилятор тоже!!!! */
#ifdef RH
                    (*pRegBase).set = (REG_SET (*)[0])&((*ppRegSet)[i]);
#else
                    (*pRegBase).set = (REG_SET (*)[])&((*ppRegSet)[i]);
#endif
                }
                else
                {
                    pRegBase = NULL;
                    RSDURTGUtils_UnilogMessage(LOG_ERR, lfp, "set_db_read(): for par ID %u REG_BASE no present (p_number = %d, ppRegBase = %p) ", par_id, ListNumItems ((*env).RegBaseList), (*env).ppRegBase);
                    (*db_err)++;
                }
            }
        }
        if ((ii != i) && (pRegBase != NULL))
        {
            (*pRegBase).set_level_number = i - ii;
        }
        if ((*env).ppReg_Set != NULL)
            qsort((*env).ppReg_Set,(size_t) nscan, sizeof(REG_SET *), p_set_comp);

        RSDURTGUtils_UnilogMessage(LOG_DEBUG, lfp, "set_db_read(): all sets read %d", count);
    }
    return(err);
}
