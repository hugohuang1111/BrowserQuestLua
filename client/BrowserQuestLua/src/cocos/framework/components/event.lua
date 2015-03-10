
local Event = class("Event")

local EXPORTED_METHODS = {
    "on",
    "addEventListener",
    "dispatchEvent",
    "removeEventListener",
    "removeEventListenersByTag",
    "removeEventListenersByEvent",
    "removeAllEventListeners",
    "hasEventListener",
    "dumpAllEventListeners",
}

function Event:init_()
    self.target_ = nil
    self.listeners_ = {}
    self.nextListenerHandleIndex_ = 0
end

function Event:bind(target)
    self:init_()
    cc.setmethods(target, self, EXPORTED_METHODS)
    self.target_ = target
end

function Event:unbind(target)
    cc.unsetmethods(target, EXPORTED_METHODS)
    self:init_()
end

function Event:on(eventName, listener, tag)
    assert(type(eventName) == "string" and eventName ~= "",
        "Event:addEventListener() - invalid eventName")
    if self:hasEventListener(eventName, tag) then
        if DEBUG > 1 then
            printInfo("%s [Event] addEventListener() - event: %s, handle: %s, tag: \"%s\" exist",
                      tostring(self.target_), eventName, handle, tostring(tag))
        end
        return
    end

    eventName = string.upper(eventName)
    if self.listeners_[eventName] == nil then
        self.listeners_[eventName] = {}
    end

    self.nextListenerHandleIndex_ = self.nextListenerHandleIndex_ + 1
    local handle = tostring(self.nextListenerHandleIndex_)
    tag = tag or ""
    self.listeners_[eventName][handle] = {listener, tag}

    if DEBUG > 1 then
        printInfo("%s [Event] addEventListener() - event: %s, handle: %s, tag: \"%s\"",
                  tostring(self.target_), eventName, handle, tostring(tag))
    end

    return self.target_, handle
end

Event.addEventListener = Event.on

function Event:dispatchEvent(event)
    event.name = string.upper(tostring(event.name))
    local eventName = event.name
    if DEBUG > 1 then
        printInfo("%s [Event] dispatchEvent() - event %s", tostring(self.target_), eventName)
    end

    if self.listeners_[eventName] == nil then return end
    event.target = self.target_
    event.stop_ = false
    event.stop = function(self)
        self.stop_ = true
    end

    for handle, listener in pairs(self.listeners_[eventName]) do
        if DEBUG > 1 then
            printInfo("%s [Event] dispatchEvent() - dispatching event %s to listener %s", tostring(self.target_), eventName, handle)
        end
        -- listener[1] = listener
        -- listener[2] = tag
        event.tag = listener[2]
        if listener[1](event) then
            self.listeners_[eventName][handle] = nil
        end
        if event.stop_ then
            if DEBUG > 1 then
                printInfo("%s [Event] dispatchEvent() - break dispatching for event %s", tostring(self.target_), eventName)
            end
            break
        end
    end

    return self.target_
end

function Event:removeEventListener(handleToRemove)
    for eventName, listenersForEvent in pairs(self.listeners_) do
        for handle, _ in pairs(listenersForEvent) do
            if handle == handleToRemove then
                listenersForEvent[handle] = nil
                if DEBUG > 1 then
                    printInfo("%s [Event] removeEventListener() - remove listener [%s] for event %s", tostring(self.target_), handle, eventName)
                end
                return self.target_
            end
        end
    end

    return self.target_
end

function Event:removeEventListenersByTag(tagToRemove)
    for eventName, listenersForEvent in pairs(self.listeners_) do
        for handle, listener in pairs(listenersForEvent) do
            -- listener[1] = listener
            -- listener[2] = tag
            if listener[2] == tagToRemove then
                listenersForEvent[handle] = nil
                if DEBUG > 1 then
                    printInfo("%s [Event] removeEventListener() - remove listener [%s] for event %s", tostring(self.target_), handle, eventName)
                end
            end
        end
    end

    return self.target_
end

function Event:removeEventListenersByEvent(eventName)
    self.listeners_[string.upper(eventName)] = nil
    if DEBUG > 1 then
        printInfo("%s [Event] removeAllEventListenersForEvent() - remove all listeners for event %s", tostring(self.target_), eventName)
    end
    return self.target_
end

function Event:removeAllEventListeners()
    self.listeners_ = {}
    if DEBUG > 1 then
        printInfo("%s [Event] removeAllEventListeners() - remove all listeners", tostring(self.target_))
    end
    return self.target_
end

function Event:hasEventListener(eventName, tag)
    eventName = string.upper(tostring(eventName))
    local t = self.listeners_[eventName]
    if not t then
        return false
    end
    for _, listener in pairs(t) do
        -- listener[1] = listener
        -- listener[2] = tag
        if not tag then
            return true
        elseif listener[2] == tag then
            return true
        end
    end
    return false
end

function Event:dumpAllEventListeners()
    print("---- Event:dumpAllEventListeners() ----")
    for name, listeners in pairs(self.listeners_) do
        printf("-- event: %s", name)
        for handle, listener in pairs(listeners) do
            printf("--     listener: %s, handle: %s", tostring(listener[1]), tostring(handle))
        end
    end
    return self.target_
end

return Event
