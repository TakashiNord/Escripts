/*
 ‘ункци€ вывода времени наступлени€ уставок. ≈сли у параметра несколько
     уставок выводитс€ врем€ первой сработавшей (min(t1,t2,...)
 ‘ормат : AccidentTime($4003748) ;
 ¬озвращает : число секунд в Unix формате
*/
REG_VAL AccidentTime(REG_BASE *pCurVal )
{
    REG_VAL        RegVal;
    uint32_t       j ;
    uint32_t       ELRF ;
    uint32_t       first_time ;
    uint32_t       min_time ;
    uint32_t       curr_time ;
    uint32_t       notify_period ;
 
    min_time =0; // для поиска минимального начального времени
                 // (*pCurVal).last_valid_value_time ;
                 
    /* Цикл по всем уровням уставок j для текущего параметра */
    for (j = 0; j < (*pCurVal).set_level_number; j++)
    {
        //   
        notify_period = (*(*pCurVal).set)[j].notify_period ; // max = 0..3600
        if (notify_period<=3600)  (*(*pCurVal).set)[j].notify_period = 3600*24 ; 

        first_time = (*(*pCurVal).set)[j].begintime ; //firstbegintime
        if (j==0) min_time = first_time ;
        else if (min_time>first_time) min_time = first_time ;
    }
    first_time = min_time ;

    ELRF = ELRF_ADERATING ; // ELRF_DERATING;

    curr_time = RSDURTGUtils_Time70();
    if ((first_time>curr_time)||(first_time<=0)) {
       first_time = curr_time; // (*pCurVal).last_change_time
       ELRF = ELRF_ALLCORRECT;
    }

    RegVal.vl = first_time;
    RegVal.ft = ELRF;

    return RegVal;
}

