-- CallbackHandler-1.0
-- License: Public Domain
-- Originally by Ace3 Development Team

local MAJOR, MINOR = "CallbackHandler-1.0", 7
local CallbackHandler = LibStub:NewLibrary(MAJOR, MINOR)
if not CallbackHandler then return end

local meta = {__index = function(tbl, key) tbl[key] = {} return tbl[key] end}

function CallbackHandler.New(_self, target)
    local events = setmetatable({}, meta)
    local registry = {recurse = 0}

    function registry:Fire(eventname, ...)
        local oldrecurse = registry.recurse
        registry.recurse = oldrecurse + 1

        local handlers = rawget(events, eventname)
        if handlers then
            for obj, method in pairs(handlers) do
                local newmethod = method or eventname
                if type(newmethod) == "string" then
                    obj[newmethod](obj, ...)
                elseif type(newmethod) == "function" then
                    newmethod(...)
                end
            end
        end

        registry.recurse = oldrecurse
    end

    target[MAJOR] = registry

    function target.RegisterCallback(self_or_target, eventname, method)
        local self = self_or_target
        if type(eventname) == "string" then
            if type(method) ~= "string" and type(method) ~= "function" then
                method = eventname
            end
            events[eventname][self] = method
        end
    end

    function target.UnregisterCallback(self_or_target, eventname)
        local self = self_or_target
        if rawget(events, eventname) then
            events[eventname][self] = nil
        end
    end

    function target.UnregisterAllCallbacks(self_or_target)
        local self = self_or_target
        for eventname, handlers in pairs(events) do
            handlers[self] = nil
        end
    end

    return registry
end
