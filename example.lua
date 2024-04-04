local Serializer = require(game.ServerScriptService.Modules.Serializer)

-- Encode to JSON
local partPath = game.Workspace.Part -- Replace with your path
local oldInstanceJSON = Serializer.EncodeToJson(partPath)
print(oldInstanceJSON)

-- Decode from JSON
local newInstance = Serializer.DecodeFromJson(oldInstanceJSON)
newInstance.Parent = partPath.Parent

-- Copy
local copiedInstance = Serializer.Copy(newInstance)
copiedInstance.Parent = newInstance.Parent
