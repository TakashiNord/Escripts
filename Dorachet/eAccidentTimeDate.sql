SET DEFINE OFF;
Insert into MEAS_FUNCTION_TEMPLATE
   (ID, ID_TYPE, NAME, ALIAS, N_USE, 
    TEMPLATE_ARGNUM, TEMPLATE_HEADER, TEMPLATE_CODE)
 Values
   (301, 2224, 'Время срабатывания и Дата', 'AccidentTimeDate', 0, 
    2, 'REG_VAL AccidentTimeDate(REG_BASE *pCurVal, int type) ;', '/*
 Функция вывода времени наступления уставок. Если у параметра несколько
     уставок выводится время первой сработавшей (min(t1,t2,...)
 Формат : AccidentTimeDate($4003748, 0 или 1) ;
 Возвращает : если
    0 - секунды delta
    1 - минуты delta
    2 - число секунд yyyy-mm-dd delta  в Unix формате
*/
REG_VAL AccidentTimeDate(REG_BASE *pCurVal, int type)
{
    REG_VAL        RegVal;
    uint32_t       j ;
    uint32_t       ELRF ;
    uint32_t       first_time ;
    uint32_t       min_time ;
    uint32_t       curr_time ;
    uint32_t       dt;
    struct tm      *st;
    const time_t   *timep ;
    time_t         ttime ;
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

    curr_time = RSDURTGUtils_Time70(); // time(0)
    
    // Вычисляем разницу
    //dt =(uint32_t)difftime(curr_time,first_time) ;
    dt = curr_time - first_time; // определили текущую delta 
    if (dt<0) dt = 0 ; // (*pCurVal).last_change_time

    ELRF = ELRF_ADERATING ; // ELRF_DERATING;

    if (first_time<=0) {
        dt = 0;
        ELRF = ELRF_ALLCORRECT;
    }


    if (type==1) {

       // получаем число минут
       dt = dt/60 + ((dt%60)?1:0) ;
       
    }

    if (type==2) {

       // наша задача: выделить из времени ГГГГ-MM-DD
       // преобразовать в time_t и прибавить dt
       
       ttime=(time_t)curr_time ;
       timep=&ttime;
       //st=gmtime(&timep) ; // Convert time_t to tm as UTC time (function )
       st=localtime (timep) ; // Convert time_t to tm as local time (function )
       
       //st->tm_year = 
       //st->tm_mon = 
       //st->tm_mday = 
       st->tm_hour = 0;
       st->tm_min = 0;
       st->tm_sec = 0;
       
       dt = mktime(st) + dt ;
    }
 
    RegVal.vl = dt;
    RegVal.ft = ELRF;

    return RegVal;
}');
COMMIT;


SET DEFINE OFF;
Insert into MEAS_FUNCTION_ARGUMENT
   (ID, ID_TEMPLATE, NAME, ALIAS, ARG_POSITION, 
    IS_STATIC)
 Values
   (138, 301, '0 - вывод секунд, 1 - вывод минут, 2 - вывод Даты', 'type', 2, 
    1);
Insert into MEAS_FUNCTION_ARGUMENT
   (ID, ID_TEMPLATE, NAME, ALIAS, ARG_POSITION, 
    IS_STATIC)
 Values
   (139, 301, 'Параметр для получения времени срабатывания Уставки', 'pCurVal', 1, 
    0);
COMMIT;

