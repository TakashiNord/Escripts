DECLARE 
@idvti as int,
@START_INTERVAL AS DATETIME, 
@END_INTERVAL AS DATETIME, 
@TIMESTAMP AS INT,
@idreq  AS DATETIME, 
@TimeStart  AS DATETIME, 
@TimeEnd AS DATETIME;

-- Определяем интервалы времени, в пределах которых в базе будем искать свежие текущие значения
SELECT @START_INTERVAL =  DATEADD(mi,-5,GETDATE()); --GETDATE();  
SELECT @END_INTERVAL = GETDATE(); -- DATEADD(hh,24,GETDATE()); DATEADD(dd,-1,GETDATE());
-- Получаем текущую метку времени по часам сервера
SELECT @TIMESTAMP = CAST(DATEDIFF(ss , '19700101 00:00:00.000' , GETUTCDATE()) AS INT);

set @idvti=12675;

delete from [e6work].[dbo].[VTIdataList]  where [idvti]=@idvti; 

-- Инициируем формирование архива в оперативной таблице БД КТС (на источнике) через хранимую процедуру
EXECUTE [e6work].[dbo].[ep_Askvtidata]
@cmd='List', 
@idvti=@idvti, --Сюда вписываем искомую idVTI нужного параметра
@idreq=@TIMESTAMP, 
@TimeStart=@START_INTERVAL, 
@TimeEnd=@END_INTERVAL;

-- Теперь можно взять самое свежее найденное значение во временной таблице в БД КТС
 -- SELECT * FROM [e6work].[dbo].[VTIdataList] WHERE [idVTI] = @idvti AND [ValueFL] IS NOT NULL;

-- Теперь очищаем временную таблицу КТС от «мусора»
-- EXECUTE [e6work].[dbo].[ep_Askvtidata] @cmd='Clear', @idreq=@TIMESTAMP;