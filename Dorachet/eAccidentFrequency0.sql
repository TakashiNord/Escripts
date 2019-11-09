SET DEFINE OFF;
Insert into MEAS_FUNCTION_TEMPLATE
   (ID, ID_TYPE, NAME, ALIAS, N_USE, 
    TEMPLATE_ARGNUM, TEMPLATE_HEADER, TEMPLATE_CODE)
 Values
   (3007, 2224, 'признак недостоверности при условии, если он равен 0', 'AccidentFrequency0', 1, 
    1, 'REG_VAL AccidentFrequency0(REG_BASE *pCurVal);', '/*
 Функция  присваивания  параметру электрического режима признак недостоверности при условии, если он равен 0
 Формат : AccidentFrequency0($4003748) ;
 Возвращает : RegVal
*/
REG_VAL AccidentFrequency0(REG_BASE *pCurVal)
{
  REG_VAL        RegVal;
  ELRSRV_ENV    *pEnv = NULL;
  int            current_index1  ;
  int            last_index1  ;
  double         vl1 ;

  pEnv = pCurVal->pEnv;
  current_index1 = (*pEnv).ret_index;  /*      Текущий цикл    */
  last_index1 = (*pEnv).cur_index;  /* Предыдущий цикл */
  vl1 = (*pCurVal).rv[current_index1].vl;

// ((vl1>-0.001)&&(vl1<=0.001)) 
  if (vl1<=26.005) {
      if (((*pCurVal).c_ft & ELRF_VALUENOCORRECT) != ELRF_VALUENOCORRECT)
          (*pCurVal).c_ft |= ELRF_VALUENOCORRECT;
  }else{
      if (((*pCurVal).c_ft & ELRF_VALUENOCORRECT) == ELRF_VALUENOCORRECT)
          (*pCurVal).c_ft &=~ ELRF_VALUENOCORRECT;
  }
    
  RegVal.vl = vl1;
  RegVal.ft = (*pCurVal).c_ft;
  return RegVal;
}
');
COMMIT;


SET DEFINE OFF;
Insert into MEAS_FUNCTION_ARGUMENT
   (ID, ID_TEMPLATE, NAME, ALIAS, ARG_POSITION, 
    IS_STATIC)
 Values
   (143, 3007, 'Параметр (при 0 получает Недостоверность)', 'pCurVal', 1, 
    0);
COMMIT;

