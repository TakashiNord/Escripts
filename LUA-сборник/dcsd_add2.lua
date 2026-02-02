-- ****************************************************************************************************************************************
-- Блок исходных данных
-- Выполняется расчет скорости нарастания контролируемого параметра (ControlParamID) на интервале ControlPeriod
-- Результатом расчета является рассчитываемый параметр (VelocityParamID), на который могут настраиваться панели и схемы
-- На этот же параметр настраивается параметр электрического режима, на котором заводятся уставки на скорость изменения.
-- Введено ограничение на период контроля, равное 30 минутам

-- ******************************************************************************************************
-- В этом блоке ничего изменять нельзя, это внутренние настройки сервера распределенной системы сбора DCS
-- Технологический цикл выполнения расчета в DCS, в сек. (не менять!!)
TechCycle = 1
-- ******************************************************************************************************
-- Период контроля скорости нарастания, в мин.
ControlPeriod = 1
-- ***********************************************************************************

-- функция первоначальной инициализации параметра
function init(BlockParam, ControlParamID, VelocityParamID) 
	BlockParam['ControlParamID'] = ControlParamID
	BlockParam['VelocityParamID'] = VelocityParamID
	BlockParam['RetroValue'] = {}
	BlockParam['RetroStatus'] = {}

	data[VelocityParamID]:setValue(0)
	data[VelocityParamID]:setValueNoCorrect()
end

-- функция циклического расчета скорости нарастания параметра
function calculate(BlockParam)
	-- Записываем в ретроспективу по текущему индексу мгновенное значение и статус контролируемого параметра в данный момент времени
	local ControlParamID = BlockParam['ControlParamID']
	local VelocityParamID = BlockParam['VelocityParamID']
	local CurrentValueIndex = global['CurrentValueIndex'] 
	local RetroValueIndex = global['RetroValueIndex']

	BlockParam['RetroValue'][CurrentValueIndex]  = data[ControlParamID]:getValue()
	if (data[ControlParamID]:isValueNoCorrect() or data[ControlParamID]:isNoPresent() or data[ControlParamID]:isNoScanned() or data[ControlParamID]:isSrcNoCorrect() or data[ControlParamID]:isDevNoCorrect()) then
        	BlockParam['RetroStatus'][CurrentValueIndex] = 1
	else
		BlockParam['RetroStatus'][CurrentValueIndex] = 0
	end

	-- Выполняем расчет только в случае, если ретроспектива заполнена на требуемую величину периода контроля скорости нарастания
	-- Вычисляем количество значений в ретроспективе на одном периоде контроля скорости нарастания
	if (global['FillRetroFlag'] == ON) then
		-- Вычисляем значения индекса для запроса ретроспективного значения с учетом ширины ретроспективы, задаваемой параметром RetroWidth
	
		if ((BlockParam['RetroStatus'][CurrentValueIndex] == 0) and (BlockParam['RetroStatus'][RetroValueIndex] == 0)) then
			data[VelocityParamID]:setStatus(0)
			data[VelocityParamID]:setValue(BlockParam['RetroValue'][CurrentValueIndex] - BlockParam['RetroValue'][RetroValueIndex])
		else
			data[VelocityParamID]:setValueNoCorrect()
		end
	end

	data[VelocityParamID]:update()
end

-- ****************************************************************************************************************************************
-- При старте сервера DCS однократно инициализируем глобальные массивы значений и статусов для записи в них ретроспективных значений
-- Запись в массивы будет производиться по единому глобальному индексу RetroIndex
if global['StartFlag'] == 0 then 
	global['StartFlag'] = 1									-- Флаг первого запуска
	global['FillRetroFlag'] = OFF							-- Флаг заполнения ретроспективы
	global['RetroWidth'] = ControlPeriod * 60 / TechCycle	-- Глубина ретроспективы для записи архивных значений. Вычисляется в технологических циклах.
	global['CurrentValueIndex'] = 0							-- Индекс текущего значения
	global['RetroValueIndex'] = 0							-- Индекс ретро-значения

	param_TEC3_K7_T_mid_down = {}							-- Блок конфигурации параметра
	init(param_TEC3_K7_T_mid_down, 15843, 15823)			-- Инициализация расчета (блокПараметра, ID исходного параметра, ID рассчитанного параметра)

	param_TEC3_K7_T_left_down = {}
	init(param_TEC3_K7_T_left_down, 15844, 15824)

	param_TEC3_K7_T_right_down = {} 
	init(param_TEC3_K7_T_right_down, 15845, 15825)

	param_TEC3_K8_T_mid_down = {}								
	init(param_TEC3_K8_T_mid_down, 16236, 16233)					

	param_TEC3_K8_T_left_down = {}
	init(param_TEC3_K8_T_left_down, 16237, 16234)

	param_TEC3_K8_T_right_down = {} 
	init(param_TEC3_K8_T_right_down, 16238, 16235)

	param_TEC3_K9_T_mid_down = {}								
	init(param_TEC3_K9_T_mid_down, 16242, 16239)					

	param_TEC3_K9_T_left_down = {}
	init(param_TEC3_K9_T_left_down, 16243, 16240)

	param_TEC3_K9_T_right_down = {} 
	init(param_TEC3_K9_T_right_down, 16244, 16241)

	param_TEC3_K10_T_mid_down = {}								
	init(param_TEC3_K10_T_mid_down, 16206, 16203)					

	param_TEC3_K10_T_left_down = {}
	init(param_TEC3_K10_T_left_down, 16207, 16204)

	param_TEC3_K10_T_right_down = {} 
	init(param_TEC3_K10_T_right_down, 16208, 16205)

	param_TEC3_K11_T_mid_down = {}								
	init(param_TEC3_K11_T_mid_down, 16212, 16209)					

	param_TEC3_K11_T_left_down = {}
	init(param_TEC3_K11_T_left_down, 16213, 16210)

	param_TEC3_K11_T_right_down = {} 
	init(param_TEC3_K11_T_right_down, 16214, 16211)

	param_TEC3_K12_T_mid_down = {}								
	init(param_TEC3_K12_T_mid_down, 16218, 16215)					

	param_TEC3_K12_T_left_down = {}
	init(param_TEC3_K12_T_left_down, 16219, 16216)

	param_TEC3_K12_T_right_down = {} 
	init(param_TEC3_K12_T_right_down, 16220, 16217)

	param_TEC3_K13_T_mid_down = {}								
	init(param_TEC3_K13_T_mid_down, 16224, 16221)					

	param_TEC3_K13_T_left_down = {}
	init(param_TEC3_K13_T_left_down, 16225, 16222)

	param_TEC3_K13_T_right_down = {} 
	init(param_TEC3_K13_T_right_down, 16226, 16223)

	param_TEC3_K14_T_mid_down = {}								
	init(param_TEC3_K14_T_mid_down, 16230, 16227)					

	param_TEC3_K14_T_left_down = {}
	init(param_TEC3_K14_T_left_down, 16231, 16228)

	param_TEC3_K14_T_right_down = {} 
	init(param_TEC3_K14_T_right_down, 16232, 16229)
end


-- ****************************************************************************************************************************************
-- секция циклического расчета значений
	calculate(param_TEC3_K7_T_mid_down)
	calculate(param_TEC3_K7_T_left_down)
	calculate(param_TEC3_K7_T_right_down)

	calculate(param_TEC3_K8_T_mid_down)
	calculate(param_TEC3_K8_T_left_down)
	calculate(param_TEC3_K8_T_right_down)

	calculate(param_TEC3_K9_T_mid_down)
	calculate(param_TEC3_K9_T_left_down)
	calculate(param_TEC3_K9_T_right_down)

	calculate(param_TEC3_K10_T_mid_down)
	calculate(param_TEC3_K10_T_left_down)
	calculate(param_TEC3_K10_T_right_down)

	calculate(param_TEC3_K11_T_mid_down)
	calculate(param_TEC3_K11_T_left_down)
	calculate(param_TEC3_K11_T_right_down)

	calculate(param_TEC3_K12_T_mid_down)
	calculate(param_TEC3_K12_T_left_down)
	calculate(param_TEC3_K12_T_right_down)

	calculate(param_TEC3_K13_T_mid_down)
	calculate(param_TEC3_K13_T_left_down)
	calculate(param_TEC3_K13_T_right_down)

	calculate(param_TEC3_K14_T_mid_down)
	calculate(param_TEC3_K14_T_left_down)
	calculate(param_TEC3_K14_T_right_down)

-- ****************************************************************************************************************************************
-- Изменяем индекс записи в архив с учетом контроля глубины ретроспективы
global ['CurrentValueIndex'] = global['CurrentValueIndex'] + 1
if global['CurrentValueIndex'] == global['RetroWidth'] then
	global['FillRetroFlag'] = ON
	global['CurrentValueIndex'] = 0
end

global['RetroValueIndex'] = global['CurrentValueIndex'] + 1
if global['RetroValueIndex'] == global['RetroWidth'] then
	global['RetroValueIndex'] = 0
end
