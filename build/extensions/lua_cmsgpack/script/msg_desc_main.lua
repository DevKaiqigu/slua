
-- for easy test
-- package.cpath = package.cpath .. ';./lib/win/?.dll'

local ok, cmsgpack_safe = pcall(require, 'cmsgpack.safe')
if not ok then cmsgpack_safe = nil end

local key = ""

local printTable
printTable = function(table, level)
  if level == nil then
  	key = ''
  end

  level = level or 1
  local indent = ""

  for i = 1, level do
    indent = indent.."  "
  end

  if key ~= "" then
    print(indent..key.." ".."=".." ".."{")
  else
    print(indent .. "{")
  end

  key = ""

  for k,v in pairs(table) do
    if type(v) == "table" then
      key = k
      printTable(v, level + 1)
    else
      local content = string.format("%s[%s] -> (%s)", indent .. "  ",tostring(k), tostring(v))
      print(content)  
    end
  end

  print(indent .. "}")
end

-- array without hole
local isArrayWithoutHole = function(tbl)
	if type(tbl) ~= 'table' then return false end

	local n = 0
	local max = 0

	for k in pairs(tbl) do
	    if type(k) == 'number' and k > 0 then
	        if k > max then
	            max = k
	        end
	    else
	        return false
	    end
	    
	    n = n + 1
	end

	if max ~= n then  -- there are holes
	    return false
	end

	return true
end

local MSGPACK_DESC_INFO_BEGIN_TAG = 'MSGPACK_DESC_INFO_'

-- t: table
-- 返回值：[string] 数组字段描述信息
local getDescInfoFromObj = function(t)
	if type(t) ~= 'table' then
		return nil, 'not table'
	end

	local err = 'no desc info'

	--print(#t)

	if #t < 3 then return nil, err  end
	if #t%2 == 0 then return nil, 'table len is even' end

	local idx_tag = math.ceil(#t/2)
	local desc = {}

	if t[idx_tag] == MSGPACK_DESC_INFO_BEGIN_TAG then
		for i=idx_tag+1,#t do
			desc[#desc+1] = t[i]
		end

		return desc
	end

	return nil, err
end

-- msg_str: 原始数据
-- 返回值：[string] 数组字段描述信息
local getDescInfoFromRawData = function(msg_str)
	local t, err = cmsgpack_safe.unpack(msg_str)

	--for k,v in pairs(t) do print(k,v) end

	if t == nil then return t,err end

	return getDescInfoFromObj(t)
end

-- 打印数组字段描述信息
local printDescInfo = function(input)
	local t = type(input)
	local info = {}
	local err = ''

	if t == 'table' then
		info, err = getDescInfoFromObj(input)
	elseif t == 'string' then
		info, err = getDescInfoFromRawData(input)
	else
		return nil, 'wrong type'
	end

	if info == nil then
		return info, err
	end

	--for k,v in pairs(info) do print(k,v) end

	printTable(info)
end

-- only work with array without hole
local msgArrayDesc = function(msg)
	print('a')
	if not isArrayWithoutHole(msg) then return nil,'not array without hole' end

	print('b')
	if #msg<2 then return nil,'table len < 2' end
	if #msg%2 > 0 then return nil,'table len is odd' end

	local proto = {}
	local half_len = #msg/2
	local desc_tag_idx = half_len + 1
	local tmp = desc_tag_idx

	for i,v in ipairs(msg) do
		if i%2 ~= 0 then 
			tmp = tmp+1
			print(1)
			proto[tmp] = v
			--print(1, tmp, v)
		else
			print(2)
			proto[i/2] = v
			--print(2, i/2, v)
		end
	end

	print(3)
	proto[desc_tag_idx] = MSGPACK_DESC_INFO_BEGIN_TAG
	--print(3, desc_tag_idx, 'tag')
	return proto
end

-- test
--[[
tbl = {
  {1,2,3},
  {},
  {x=1,y=2},
  {4,5,6,'aaa'},
  {a={b={c='abc'}}},
}
printTable(tbl)
printTable({1,2,3; {x=1, y=2}; {a={b=1}}})

local proto = msgArrayDesc({
	'name', 'Tom',
	'age', 20,
	'level', 3,
	})
local proto_packed = cmsgpack_safe.pack(proto)
print(proto_packed)
print(type(proto_packed))
local info,err = printDescInfo(proto_packed)
--print(info, err)

local proto = msgArrayDesc({
	'name', 'Tom',
	'age', 20,
	'level', 3,
	'coord', {x=1, y=2},
	'time', '2000/01/01',
	'userinfo', {country='China'}
	})
local proto_packed = cmsgpack_safe.pack(proto)
printDescInfo(proto_packed)
]]

msg_desc_ = {
	msgArrayDesc=msgArrayDesc, 
	printDescInfo=printDescInfo
}
