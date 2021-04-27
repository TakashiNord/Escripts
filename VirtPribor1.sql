---------------------------------
 Для того, чтобы создать и описать Виртуальный Прибор, нужно предварительно создать и заполнить
 1. Прибор1
     |-(Профиль1)
    Прибор2
     |-(Профиль2)
    Прибор3
     |-(Профиль3)
...

 2. Завести Дополнительные каналы в таблице DA_SOURCE.
    Число каналов желательно завести по числу Каналов, которых вы хотите обединить

    Если в "Виртуальном Приборе" вы планируете обьединять 2а Прибора (из раздела DA) - нужно иметь 2 пары (ТИ, ТС)
      Канал ТИ(вирт1)
      Канал ТС(Вирт1)
      ..
      Канал ТИ(Вирт2)
      Канал ТС(Вирт2)

     аналогично, для обьединения 3х - нужно завести 3 пары (ТИ, ТС).
     Если планируете добавлять Технологический режим (и их больше 1-го), то нужно добавить их.

 3. Создаете Порт и Прибор в Навигаторе (выставляете свойство "Виртуальный Прибор")
    Создаются Параметры исходя Профиля. (Все как обычный прибор).
    Профиль должен или совпадать с Профилем1 или с Профилем2 ...
    или должен быть отдельным (со своей адресацией).

 Виртуальный Прибор по настройке ничем не различается от настройки обычно Прибора на передачу данных,
кроме свойства и принципа работы.

4. На этом этапе, вы начинаете заполнять Источники и параметров Виртуального прибора.

-------------
Вот на этом этапе появляется много вопросов:
 - как обьединять Каналы 2х приборов для 1 виртуального параметра
   (по какому принципу?
    -наименование параметров?
    -совпадение квалификаторов? если Приборы с разными Профиль1/Профиль2 )


DA_SOURCE

ID  ALIAS ID_GTOPT  PRIORITY  PORT_NUM

2 Графики (ан)  1 3 2130
3 Графики (бул) 8 2 2130
4 Электр. режим 1 2 2131
5 Ком. аппараты 8 2 2145
6 Прочие пар. 1 2 2135
7 СРЗиА 8 2 2148
++17  Сбор ТИ (вирт2) 1 2 2202
++16  Сбор ТИ (вирт1) 1 2 2202
8 Сбор ТИ 1 1 2202
10  Сбор ТС 8 2 2191
11  Сбор OPC(ти)12  1 2 2364
12  Сбор OPC(тс)12  8 2 2364
13  Доп.параметры(ан) 1 1 5001
14  Доп.параметры(бул)  1 2 5002

DA_PARAM

ID  ID_NODE ID_POINT  ID_UNIT ID_OBJ  ID_FILEWAV  ID_UCLASS PRIORITY  SCALE SCALE_MAX SCALE_MIN NAME  ALIAS STATE RETFNAME  APERTURE  IS_DELETED  LIMIT_MAX LIMIT_MIN LIMIT_MAXMNL  LIMIT_MINMNL  NCSS_TIMEOUT

6807983 4000906 5010340       1 0 1 1 1 fdf 4 fdf 4 0   0 0         0
+++0вирт)6807982  4000906 5010346       1 0 1 1 1 fdf 10  fdf 10  0   0 0         0
6807981 4000904 5010312       1 0 1 1 1 fdf 4 fdf 4 0   0 0         0
+++2элемент)6807980 4000904 5010318       1 0 1 1 1 fdf 10  fdf 10  0   0 0         0
6807979 4000902 5010284       1 0 1 1 1 fdf 4 fdf 4 0   0 0         0
+++1элемент)6807978 4000902 5010290       1 0 1 1 1 fdf 10  fdf 10  0   0 0         0
        0


DA_SRC_CHANNEL

ID  ID_OWNLST ID_SOURCE ALIAS PRIORITY

++5003711 6807982 4 Канал 0
++5003692 6807982 17  Канал 0
++5003691 6807982 16  Канал 0


DA_VAL
ID_PARAM  ID_CUR_CHANNEL_SRC

6807983 5003676
++6807982 5003692


DA_SRC_CHANNEL_TUNE

ID  ID_CHANNEL  ID_SRCTBL ID_SRCLST

5003689 5003711 29  4004019
5003670 5003692 54  6807980
5003669 5003691 54  6807978
5003654 5003676 54  6807979
5003611 5003632 54  6807482

----------------------------------------------------------------------


--WHENEVER SQLERROR EXIT
SET SERVEROUTPUT on
--SET feedback on
--SET verify off


DECLARE
  nCNT NUMBER ;
  vSQL VARCHAR2(32700);
  i NUMBER := 0;
  nID NUMBER := 0;
  nID2  NUMBER := 0;
  ID_SRC NUMBER := 0;
  nN  NUMBER := 0;
  nCanal  NUMBER := 0;
  id_parentV NUMBER := 0;
  id_parentP NUMBER := 0;
  id1 NUMBER := 0;
  id2 NUMBER := 0;
BEGIN

----------------------------------
-- Прибора Виртуального (куда)
   id_parentV := 4000906 ;

-- 1-ый Прибор (откуда)
   id_parentP := 4000904 ; -- меняем при смене прибора

   ID_SRC := 54 ;

-- DA_SOURCE
-- id1 Канала ТИ
   id1 := 8 ;  -- меняем при смене прибора
-- id2 Канала ТС
   id2 := 10 ;  -- меняем при смене прибора
----------------------------------

   dbms_output.ENABLE (200000);
   dbms_output.put_line ( '----------------------------------------------------------------' );

   -- Получаем Параметры из Прибора для вставки
   FOR rec IN (
     select da.id, da.id_point, da.name, dd.cvalif
     from da_param da
     JOIN da_dev_desc dd ON dd.ID = da.id_point
     where da.id_node = id_parentP
   )
   LOOP
    i := i+1;
    dbms_output.put_line ( i ||';' || rec.id || ';' || rec.id_point || ' ' );

    -- получаем ТИП параметра вставки
    FOR lst IN (
        SELECT da.ID, da.id_node, da.NAME, dd.cvalif,
          (CASE
              WHEN REGEXP_LIKE (gt.define_alias, 'ANALOG')
                 THEN 'ANALOG'
              WHEN REGEXP_LIKE (gt.define_alias, 'TELECONTROL')
                 THEN 'TELECONTROL'
              WHEN REGEXP_LIKE (gt.define_alias, 'BOOL')
                 THEN 'BOOL'
              ELSE '??'
           END
          ) AS gtype_name
        FROM da_param da
        JOIN da_dev_desc dd ON dd.ID = da.id_point
        -- AND da.ID=
        -- AND da.id_point = rec.id_point
        AND dd.cvalif = rec.cvalif
        -- AND rec.name like '%'||da.NAME||'%'
        AND da.id_node = id_parentV
        LEFT JOIN sys_gtopt gt ON gt.ID = dd.id_gtopt
    )
    LOOP
        dbms_output.put_line (lst.gtype_name );
        nCanal:=-1;
        IF lst.gtype_name='ANALOG' THEN
            nCanal:=id1 ;
        END IF ;
        IF lst.gtype_name='TELECONTROL' THEN
            dbms_output.put_line (' ');
        END IF ;
        IF lst.gtype_name='BOOL' THEN
            nCanal:=id2 ;
        END IF ;
        IF lst.gtype_name='??' THEN
            dbms_output.put_line (' ');
        END IF ;

        -- если канал задан - вставляем
        IF nCanal>0 THEN

           dbms_output.put_line (' Insert ' );

           -- DA_SRC_CHANNEL
           -- получаем новый ID канала для вставки
           select max(id)+1 into nID from RSDUADMIN.DA_SRC_CHANNEL;
           -- Вставляем Канал
           INSERT INTO DA_SRC_CHANNEL (ID,ID_OWNLST,ID_SOURCE,ALIAS,PRIORITY) VALUES
              ( nID, lst.id , nCanal, 'Canal', 0 ) ;

           -- DA_SRC_CHANNEL_TUNE
           -- получаем новый ID канала для вставки
           select max(id)+1 into nID2 from RSDUADMIN.DA_SRC_CHANNEL_TUNE;
           -- Вставляем Канал
           INSERT INTO DA_SRC_CHANNEL_TUNE (ID , ID_CHANNEL, ID_SRCTBL, ID_SRCLST) VALUES
              ( nID2, nID , ID_SRC , rec.id  ) ;

           -- Фиксируем канал
           INSERT INTO DA_SRC_CHAN_PAR_KOEF (ID_SRC_CHANNEL_TUNE, KOEFF_VAL) VALUES
              ( nID2, 1 ) ;

           -- DA_VAL
           -- устанавливаем Источник по умолчанию, если его нет
           SELECT count(*) into nN FROM RSDUADMIN.DA_VAL WHERE ID_PARAM=lst.id ;
           IF nN=0 THEN
              INSERT INTO DA_VAL (ID_PARAM,ID_CUR_CHANNEL_SRC) VALUES (lst.id, nID) ;
           END IF ;

           -- фиксируем
           commit ;

        END IF ;


    END LOOP;
    --dbms_output.put_line ('' );

   END LOOP;


EXCEPTION WHEN OTHERS THEN
  nCnt := SQLCODE;
  vSQL := SQLERRM;
--  IF nCnt = -20000 AND vSQL LIKE '%buffer%overflow%'  THEN
--     dbms_output.put_line (chr(10)||' buffer overflow :(');
--  ELSE
    dbms_output.put_line ('ORA-'||nCnt);
    dbms_output.put_line (vSQL);
--  END IF;
END;
/