-- LibDataBroker-1.1
-- License: Public Domain
-- Originally by Tekkub

assert(LibStub, "LibDataBroker-1.1 requires LibStub")

local lib, oldminor = LibStub:NewLibrary("LibDataBroker-1.1", 4)
if not lib then return end

lib.callbacks = lib.callbacks or LibStub("CallbackHandler-1.0"):New(lib)
lib.attributestorage = lib.attributestorage or {}
lib.namestorage = lib.namestorage or {}
lib.proxystorage = lib.proxystorage or {}

local attributestorage = lib.attributestorage
local namestorage = lib.namestorage
local proxystorage = lib.proxystorage
local callbacks = lib.callbacks

function lib:NewDataObject(name, dataobj)
    if proxystorage[name] then return proxystorage[name] end

    if dataobj then
        assert(type(dataobj) == "table", "Invalid dataobj, must be a table")
        attributestorage[name] = dataobj
    else
        attributestorage[name] = {}
    end

    local dataobj_proxy = setmetatable({}, {
        __index = function(_, key)
            return attributestorage[name][key]
        end,
        __newindex = function(_, key, value)
            attributestorage[name][key] = value
            callbacks:Fire("LibDataBroker_AttributeChanged", name, key, value, attributestorage[name])
            callbacks:Fire("LibDataBroker_AttributeChanged_" .. name, name, key, value, attributestorage[name])
            callbacks:Fire("LibDataBroker_AttributeChanged_" .. name .. "_" .. key, name, key, value, attributestorage[name])
            callbacks:Fire("LibDataBroker_AttributeChanged__" .. key, name, key, value, attributestorage[name])
        end,
    })

    proxystorage[name] = dataobj_proxy
    namestorage[name] = name
    callbacks:Fire("LibDataBroker_DataObjectCreated", name, dataobj_proxy)
    return dataobj_proxy
end

function lib:DataObjectIterator()
    return pairs(proxystorage)
end

function lib:GetDataObjectByName(name)
    return proxystorage[name]
end

function lib:GetNameByDataObject(dataobj)
    for name, proxy in pairs(proxystorage) do
        if proxy == dataobj then return name end
    end
end
