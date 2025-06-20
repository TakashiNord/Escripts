-- read file to rsdu used dcsd(lua)

function string:split(sep)
  return self:match("([^" .. sep .. "]+)[" .. sep .. "]+(.+)")
end

function string:trim()
  return self:match("^%s*(.-)%s*$")
end    

-- see if the file exists
function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

-- get all lines from a file, returns an empty 
-- list/table if the file does not exist
function lines_from(file)
  if not file_exists(file) then return {} end
  lines = {}
  for line in io.lines(file) do 
    lines[#lines + 1] = line
  end
  return lines
end

-- var path to file
local file = 'C:/out_u_g.txt'
local lines = lines_from(file)

-- table for test
--local data = {}
--data[0]=0

action = {
["HC1_G1"] = function (x) data[6807252]=x end,
["HC1_G2"] = function (x) data[6807253]=x end,
["HC2_G1"] = function (x) data[6807254]=x end,
["HC2_G2"] = function (x) data[6807255]=x end,
["HC3_G1"] = function (x) data[6807256]=x end,
["HC3_G2"] = function (x) data[6807257]=x end,
["HC4_G1"] = function (x) data[6807258]=x end,
["HC4_G2"] = function (x) data[6807259]=x end,
["HC5_G1"] = function (x) data[6807260]=x end,
["HC5_G2"] = function (x) data[6807261]=x end,
--["HC8_G1"] = function (x) data[600000]=x end,
--["HC8_G2"] = function (x) data[600000]=x end,
--["HC9_G11"]= function (x) data[600000]=x end,
--["HC9_G12"]= function (x) data[600000]=x end,
--["HC9_G13"]= function (x) data[600000]=x end,
--["HC9_G14"]= function (x) data[600000]=x end,
--["HC9_G21"]= function (x) data[600000]=x end,
--["HC9_G22"]= function (x) data[600000]=x end,
--["HC9_G23"]= function (x) data[600000]=x end,
--["HC9_G24"]= function (x) data[600000]=x end,
--["HC10_G1"]= function (x) data[600000]=x end,
--["HC10_G2"]= function (x) data[600000]=x end,
--["HC10_G3"]= function (x) data[600000]=x end,
--["KC12_G1"]= function (x) data[600000]=x end,
--["KC12_G2"]= function (x) data[600000]=x end,
--["KC14_G1"]= function (x) data[600000]=x end,
--["KC14_G2"]= function (x) data[600000]=x end,
--["HKT_G11"]= function (x) data[600000]=x end,
--["HKT_G12"]= function (x) data[600000]=x end,
--["HKT_G13"]= function (x) data[600000]=x end,
--["HKT_G21"]= function (x) data[600000]=x end,
--["HKT_G22"]= function (x) data[600000]=x end,
--["HKT_G23"]= function (x) data[600000]=x end,
--["HKT_G31"]= function (x) data[600000]=x end,
--["HKT_G32"]= function (x) data[600000]=x end,
--["BK_G11"] = function (x) data[600000]=x end,
--["BK_G12"] = function (x) data[600000]=x end,
--["BK_G13"] = function (x) data[600000]=x end,
--["BK_G21"] = function (x) data[600000]=x end,
--["BK_G22"] = function (x) data[600000]=x end,
--["BK_G23"] = function (x) data[600000]=x end,
--["BK_G31"] = function (x) data[600000]=x end,
--["BK_H1"]  = function (x) data[600000]=x end,
--["BK_H2"]  = function (x) data[600000]=x end,
--["BK_H3"]  = function (x) data[600000]=x end,
--["BK_H4"]  = function (x) data[600000]=x end,
--["HC11_G1"]= function (x) data[600000]=x end,
--["HC11_G2"]= function (x) data[600000]=x end,
}

function save_to_rsdu(file)
  -- all line numbers and their contents
  for k,v in pairs(lines) do
    --print('['..k..']', v)
    local key, val = v:split("=")
    key, val = key:trim(), val:trim();
    --print(val)
    num=tonumber(val)
    if action[key] then action[key](num) end 
  end
  return 0
end

status, err = pcall(save_to_rsdu, file) -- f:функция, x-y: ее аргументы
if not status then 
  -- обработать ошибку err. В нашем случае в err находится текст ошибки
end

-- print(data[6807258])