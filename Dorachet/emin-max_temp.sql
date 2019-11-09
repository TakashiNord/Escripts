SET DEFINE OFF;
Insert into RSDUADMIN.MEAS_FUNCTION_TEMPLATE
   (ID, ID_TYPE, NAME, ALIAS, N_USE, TEMPLATE_ARGNUM, TEMPLATE_HEADER, TEMPLATE_CODE)
 Values
   (127, 2224, 'Минимум (из 10 параметров)', 'Min10', 0, 10, 'REG_VAL Min10(double v1, double v2, double v3, double v4, double v5, double v6, double v7,double v8,double v9,double v10);
', 'REG_VAL Min10(double v1, double v2, double v3, double v4, double v5, double v6, double v7,double v8,double v9,double v10)
{
    REG_VAL result;
    double v0[] = {v1,v2,v3,v4,v5,v6,v7,v8,v9,v10};
    double minV = v0[0];
    int i ;
    
    for ( i = 1; i<10; i++) {
       if (minV>v0[i]) minV=v0[i]; 
    }

    result.vl = minV;
    result.ft = ELRF_ALLCORRECT ; // ELRF_ADERATING  ELRF_DERATING  ELRF_ALLCORRECT  

    return result;
}
');
Insert into RSDUADMIN.MEAS_FUNCTION_TEMPLATE
   (ID, ID_TYPE, NAME, ALIAS, N_USE, TEMPLATE_ARGNUM, TEMPLATE_HEADER, TEMPLATE_CODE)
 Values
   (128, 2224, 'Максимум (из 10 параметров)', 'Max10', 0, 10, 'REG_VAL Max10(double v1, double v2, double v3, double v4, double v5, double v6, double v7,double v8,double v9,double v10);
', 'REG_VAL Max10(double v1, double v2, double v3, double v4, double v5, double v6, double v7,double v8,double v9,double v10)
{
    REG_VAL result;
    double v0[] = {v1,v2,v3,v4,v5,v6,v7,v8,v9,v10};
    double maxV = v0[0];
    int i ;
    
    for ( i = 1; i<10; i++) {
       if (maxV<v0[i]) maxV=v0[i]; 
    }

    result.vl = maxV;
    result.ft = ELRF_ALLCORRECT ; // ELRF_ADERATING  ELRF_DERATING  ELRF_ALLCORRECT  

    return result;
}');
COMMIT;
