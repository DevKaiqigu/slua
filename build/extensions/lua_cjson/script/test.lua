
local succ, cjson_safe = require 'cjson.safe'
if not succ then 
	print 'cjson dynamic library not found'
end

local data = {arr={1,2,3}, x=1, y=3, z=3}
local text = cjson_safe.encode(data)
print(text)

local obj = cjson_safe.decode(text)
for k,v in pairs(obj) do print(k,v) end
