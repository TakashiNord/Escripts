SET DEFINE OFF;
Insert into MEAS_FUNCTION_TEMPLATE
   (ID, ID_TYPE, NAME, ALIAS, N_USE, 
    TEMPLATE_ARGNUM, TEMPLATE_HEADER, TEMPLATE_CODE)
 Values
   (3005, 2224, 'Время прихода сигнала', 'GetTime', 0, 
    1, 'REG_VAL GetTime(REG_BASE *pCurVal1);', 'REG_VAL GetTime(REG_BASE *pCurVal1)
{
    REG_VAL        result;

    ELRSRV_ENV    *pEnv = NULL;
    int            current_index1  ;
    int            last_index1  ;
    double         vl1 ;

    uint32_t       last_change_time;   /* Last value change time */
    uint32_t       last_valid_value_time;

    pEnv = pCurVal1->pEnv;
    current_index1 = (*pEnv).ret_index;  /*      Текущий цикл    */
    last_index1 = (*pEnv).cur_index;  /* Предыдущий цикл */
    vl1 = (*pCurVal1).rv[current_index1].vl;

    result.vl = (*pCurVal1).last_change_time;
    result.ft = 0;
    return result;

}');
COMMIT;


SET DEFINE OFF;
Insert into MEAS_FUNCTION_ARGUMENT
   (ID, ID_TEMPLATE, NAME, ALIAS, ARG_POSITION, 
    IS_STATIC)
 Values
   (142, 3005, 'Время прихода сигнала', 'pCurVal', 1, 
    0);
COMMIT;

