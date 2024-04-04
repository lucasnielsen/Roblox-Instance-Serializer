local HttpService = game:GetService("HttpService")
local Data = require(script.Parent.PropertiesConfig)

local Serializer = {}

local function serializeValue(value)
	local valueType = typeof(value)
	if valueType == "EnumItem" then
		return {["$type"] = "EnumItem", ["EnumType"] = tostring(value.EnumType), ["Value"] = value.Name}
	elseif valueType == "Vector3" then
		return {["$type"] = "Vector3", x = value.X, y = value.Y, z = value.Z}
	elseif valueType == "Color3" then
		return {["$type"] = "Color3", r = value.r, g = value.g, b = value.b}
	elseif valueType == "CFrame" then
		-- Note: Simplified; consider storing all components for precision
		return {["$type"] = "CFrame", position = serializeValue(value.Position)}
	elseif valueType == "BrickColor" then
		return {["$type"] = "BrickColor", name = value.Name}
	else
		return value
	end
end

local function deserializeValue(serialized)
	if typeof(serialized) == "table" and serialized["$type"] then
		local valueType = serialized["$type"]
		if valueType == "EnumItem" then
			return Enum[serialized["EnumType"]][serialized["Value"]]
		elseif valueType == "Vector3" then
			return Vector3.new(serialized.x, serialized.y, serialized.z)
		elseif valueType == "Color3" then
			return Color3.new(serialized.r, serialized.g, serialized.b)
		elseif valueType == "CFrame" then
			local pos = deserializeValue(serialized.position)
			return CFrame.new(pos)
		elseif valueType == "BrickColor" then
			return BrickColor.new(serialized.name)
		end
	else
		return serialized
	end
end

function Serializer.EncodeToJson(instance)
	local function serializeInstance(inst)
		local serialized = {["$className"] = inst.ClassName, ["$children"] = {}}
		local props = Data[inst.ClassName] or {}
		for _, propName in ipairs(props) do
			local success, value = pcall(function() return inst[propName] end)
			if success then
				serialized[propName] = serializeValue(value)
			end
		end
		for _, child in ipairs(inst:GetChildren()) do
			table.insert(serialized["$children"], serializeInstance(child))
		end
		return serialized
	end
	return HttpService:JSONEncode(serializeInstance(instance))
end

function Serializer.DecodeFromJson(json)
	local function deserializeInstance(serialized)
		if not serialized or not serialized["$className"] then return end
		local instance = Instance.new(serialized["$className"])
		for propName, propValue in pairs(serialized) do
			if propName ~= "$className" and propName ~= "$children" then
				local success = pcall(function() instance[propName] = deserializeValue(propValue) end)
				if not success then
					warn("Failed to set property:", propName)
				end
			end
		end
		for _, childSerialized in ipairs(serialized["$children"]) do
			local child = deserializeInstance(childSerialized)
			if child then child.Parent = instance end
		end
		return instance
	end
	return deserializeInstance(HttpService:JSONDecode(json))
end

function Serializer.Copy(instance)
	local function copyInstance(inst)
		local newInstance = Instance.new(inst.ClassName)
		local props = Data[inst.ClassName] or {}
		for _, propName in ipairs(props) do
			local success, value = pcall(function() return inst[propName] end)
			if success then
				pcall(function() newInstance[propName] = value end)
			end
		end
		for _, child in ipairs(inst:GetChildren()) do
			local newChild = copyInstance(child)
			newChild.Parent = newInstance
		end
		return newInstance
	end
	return copyInstance(instance)
end

return Serializer
