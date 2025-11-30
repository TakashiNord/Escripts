-- ******************************************************************************************************
-- В этом блоке ничего изменять нельзя, это внутренние настройки сервера распределенной системы сбора DCS
-- Технологический цикл выполнения расчета в DCS, в сек. (не менять!!)
DeltaTechCycle = 1
-- ******************************************************************************************************
-- Период контроля скорости нарастания, в мин.
DeltaControlPeriod = 6
-- ***********************************************************************************

-- функция первоначальной инициализации параметра
function Deltainit(BlockParam, ControlParamID, VelocityParamID) 
	BlockParam['DeltaControlParamID'] = ControlParamID
	BlockParam['DeltaVelocityParamID'] = VelocityParamID
	BlockParam['DeltaRetroValue'] = {}
	BlockParam['DeltaRetroStatus'] = {}

	data[VelocityParamID]:setValue(0)
	data[VelocityParamID]:setValueNoCorrect()
end

-- функция циклического расчета скорости нарастания параметра
function Deltacalculate(BlockParam)
	-- Записываем в ретроспективу по текущему индексу мгновенное значение и статус контролируемого параметра в данный момент времени
	local ControlParamID = BlockParam['DeltaControlParamID']
	local VelocityParamID = BlockParam['DeltaVelocityParamID']
	local CurrentValueIndex = global['DeltaCurrentValueIndex'] 
	local RetroValueIndex = global['DeltaRetroValueIndex']

	BlockParam['DeltaRetroValue'][CurrentValueIndex]  = data[ControlParamID]:getValue()
	if (data[ControlParamID]:isValueNoCorrect() or data[ControlParamID]:isNoPresent() or data[ControlParamID]:isNoScanned() or data[ControlParamID]:isSrcNoCorrect() or data[ControlParamID]:isDevNoCorrect()) then
        	BlockParam['DeltaRetroStatus'][CurrentValueIndex] = 1
	else
		BlockParam['DeltaRetroStatus'][CurrentValueIndex] = 0
	end

	-- Выполняем расчет только в случае, если ретроспектива заполнена на требуемую величину периода контроля скорости нарастания
	-- Вычисляем количество значений в ретроспективе на одном периоде контроля скорости нарастания
	if (global['DeltaFillRetroFlag'] == ON) then
		-- Вычисляем значения индекса для запроса ретроспективного значения с учетом ширины ретроспективы, задаваемой параметром RetroWidth
	
		if ((BlockParam['DeltaRetroStatus'][CurrentValueIndex] == 0) and (BlockParam['DeltaRetroStatus'][RetroValueIndex] == 0)) then
			data[VelocityParamID]:setStatus(0)
			data[VelocityParamID]:setValue(BlockParam['DeltaRetroValue'][CurrentValueIndex] - BlockParam['DeltaRetroValue'][RetroValueIndex])
		else
			data[VelocityParamID]:setValueNoCorrect()
		end
	end

	data[VelocityParamID]:update()
end


-- G = 687,105 ⸱ (dН'баптс1 + dН’баптс2)
function DeltaG(ParamG, BlockParam1, BlockParam2)
	local VelocityParamID1 = BlockParam1['DeltaVelocityParamID']
	local VelocityParamID2 = BlockParam2['DeltaVelocityParamID']
        local v = 0

	if (global['DeltaFillRetroFlag'] == ON) then
	   v = 687.105 * ( data[VelocityParamID1]:getValue() + data[VelocityParamID2]:getValue() )
           data[ParamG]:setValue(v)
           data[ParamG]:setStatus(0)
	else
	   data[ParamG]:setValueNoCorrect()
	end

	data[ParamG]:update()
end


-- ****************************************************************************************************************************************
-- При старте сервера DCS однократно инициализируем глобальные массивы значений и статусов для записи в них ретроспективных значений
-- Запись в массивы будет производиться по единому глобальному индексу RetroIndex
if global['DeltaStartFlag'] == 0 then 
	global['DeltaStartFlag'] = 1									-- Флаг первого запуска
	global['DeltaFillRetroFlag'] = OFF							-- Флаг заполнения ретроспективы
	global['DeltaRetroWidth'] = DeltaControlPeriod * 60 / DeltaTechCycle	-- Глубина ретроспективы для записи архивных значений. Вычисляется в технологических циклах.
	global['DeltaCurrentValueIndex'] = 0							-- Индекс текущего значения
	global['DeltaRetroValueIndex'] = 0							-- Индекс ретро-значения

	param_dН1 = {}							-- Блок конфигурации параметра
	Deltainit(param_dН1, 600000, 600001)			-- Инициализация расчета (блокПараметра, ID исходного параметра, ID рассчитанного параметра)

	param_dН2 = {}
	Deltainit(param_dН2, 700000, 700001)

end


-- ****************************************************************************************************************************************
-- секция циклического расчета значений
	Deltacalculate(param_dН1)
        Deltacalculate(param_dН2)
       
        DeltaG(800000, param_dН1, param_dН2)


-- ****************************************************************************************************************************************
-- Изменяем индекс записи в архив с учетом контроля глубины ретроспективы
global ['DeltaCurrentValueIndex'] = global['DeltaCurrentValueIndex'] + 1
if global['DeltaCurrentValueIndex'] == global['DeltaRetroWidth'] then
	global['DeltaFillRetroFlag'] = ON
	global['DeltaCurrentValueIndex'] = 0
end

global['DeltaRetroValueIndex'] = global['DeltaCurrentValueIndex'] + 1
if global['DeltaRetroValueIndex'] == global['DeltaRetroWidth'] then
	global['DeltaRetroValueIndex'] = 0
end


