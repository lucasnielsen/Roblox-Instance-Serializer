local HttpService = game:GetService("HttpService")
local Data = require(script.Parent.PropertiesConfig)

local Serializer = {}

local function serializeValue(value)
	local valueType = typeof(value)
	if valueType == "Vector3" then
		return {["$type"] = "Vector3", x = value.X, y = value.Y, z = value.Z}
	elseif valueType == "Color3" then
		return {["$type"] = "Color3", r = value.r, g = value.g, b = value.b}
	elseif valueType == "CFrame" then
		return {["$type"] = "CFrame", position = serializeValue(value.Position)}
	elseif valueType == "BrickColor" then
		return {["$type"] = "BrickColor", name = value.Name}
	elseif valueType == "EnumItem" then
		return {["$type"] = "EnumItem", enumType = tostring(value.EnumType), name = value.Name}
	else
		return value
	end
end

local function deserializeValue(value)
	if type(value) == "table" and value["$type"] then
		local t = value["$type"]
		if t == "Vector3" then
			return Vector3.new(value.x, value.y, value.z)
		elseif t == "Color3" then
			return Color3.new(value.r, value.g, value.b)
		elseif t == "CFrame" then
			return CFrame.new(value.position.x, value.position.y, value.position.z)
		elseif t == "BrickColor" then
			return BrickColor.new(value.name)
		elseif t == "EnumItem" then
			return Enum[value.enumType][value.name]
		end
	else
		return value
	end
end

function Serializer.EncodeToJson(instance)
	local function serializeInstance(inst)
		local serialized = {["$className"] = inst.ClassName, ["$children"] = {}}
		for _, propName in ipairs(Data) do
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
	local serializedInstance = HttpService:JSONDecode(json)
	local function deserializeInstance(serialized)
		if not serialized["$className"] then return end
		local instance = Instance.new(serialized["$className"])
		for propName, propValue in pairs(serialized) do
			if propName ~= "$className" and propName ~= "$children" then
				local success = pcall(function() instance[propName] = deserializeValue(propValue) end)
				if not success then
					warn("Failed to set property", propName, "on", serialized["$className"])
				end
			end
		end
		for _, childSerialized in ipairs(serialized["$children"]) do
			local childInstance = deserializeInstance(childSerialized)
			if childInstance then
				childInstance.Parent = instance
			end
		end
		return instance
	end
	return deserializeInstance(serializedInstance)
end

function Serializer.Copy(instance)
	local function copyInstance(inst)
		local newInstance = Instance.new(inst.ClassName)
		for _, propName in ipairs(Data) do
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
