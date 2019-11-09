SET DEFINE OFF;
--

Insert into RSDUADMIN.MEAS_FUNCTION_TEMPLATE
   (ID, ID_TYPE, NAME, ALIAS, N_USE, TEMPLATE_ARGNUM, TEMPLATE_HEADER, TEMPLATE_CODE)
 Values
   (283, 2222, 'Остаток от деления', 'Mod', 0, 2, 'REG_VAL Mod(double x, double y);', 'REG_VAL Mod(double x, double y)
{
    REG_VAL result;
    div_t n;
    int v1 = static_cast<long int>(x);
    int v2 = static_cast<long int>(y);

    result.vl = 0;
    result.ft = 0;

    if (v2==0) result.ft = OIC_DST_NOPRESENT;
    else {
      n=div(v1,v2);
      result.vl = n.rem;
    }

    return result;
}
');



Insert into RSDUADMIN.MEAS_FUNCTION_TEMPLATE
   (ID, ID_TYPE, NAME, ALIAS, N_USE, TEMPLATE_ARGNUM, TEMPLATE_HEADER, TEMPLATE_CODE)
 Values
   (284, 2222, 'Усечение до целой части', 'Trunc', 0, 1, 'REG_VAL Trunc(double x);', 'REG_VAL Trunc(double x)
{
    REG_VAL result;

    result.ft = 0;
    result.vl = trunc(x);

    return result;
}
');


COMMIT;
