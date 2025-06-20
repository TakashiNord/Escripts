SET serveroutput ON
SET LINESIZE 140
DECLARE 
  nCNT NUMBER ;
  vSQL VARCHAR2(2000);
  i NUMBER := 0;
BEGIN
   dbms_output.ENABLE (100000);
   dbms_output.put_line ('---------------------------');
   -- parameter
   FOR rec IN ( 
    select dp.id_node, dc.name as pribor, dp.id, dp.id_point, dp.name
    from da_param dp, da_cat dc
    where dp.ID_NODE = dc.ID
    and dp.id in ( 
        select id_ownlst
        from da_src_channel
        where id in (
            select distinct id_channel 
            from da_src_channel_tune
            where id in ( select ID_SRC_CHANNEL_TUNE from DA_SRC_CHAN_PAR_KOEF where KOEFF_VAL=2 )
            )
        )   
   )
   LOOP
    i := i+1;
    dbms_output.put_line ( i ||')  (#' || rec.id_node || ')' || rec.pribor ||'   #'||rpad (rec.id, 7)|| ' "'||rec.name ||'"' );   
    FOR lst IN ( 
        select dp.id, dp.id_node, dp.id_point, dp.name, ddd.CVALIF 
        from da_param dp , da_dev_desc ddd
        where id_point = ddd.ID and dp.id in (
            select id_srclst
            from da_src_channel_tune
            where id_channel in ( select id from da_src_channel where ID_OWNLST=rec.id )
        ) 
    )
    LOOP
        dbms_output.put_line (' ------ #'||lst.id ||' "'||lst.name|| '"      id point=' || lst.id_point ||  '   CVALIF=('|| lst.CVALIF||')' );
    END LOOP;
    dbms_output.put_line ('---------------------------'  );    

   END LOOP;

 
EXCEPTION WHEN OTHERS THEN 
  nCnt := SQLCODE;
  vSQL := SQLERRM;
  IF nCnt = -20000 AND vSQL LIKE '%buffer%overflow%'  THEN 
     dbms_output.put_line (chr(10)||' buffer overflow :(');
  ELSE 
    dbms_output.put_line ('ORA-'||nCnt);
    dbms_output.put_line (vSQL);
  END IF;
END;
/