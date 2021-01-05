-- upvalue the globals
local _G = getfenv(0)
local LibStub = _G.LibStub
local GetAddOnMetadata = _G.GetAddOnMetadata
local InterfaceOptionsFrame_OpenToCategory = _G.InterfaceOptionsFrame_OpenToCategory
local coroutine = _G.coroutine

local addonName = ...
local IOW = LibStub("AceAddon-3.0"):GetAddon(addonName);
if not IOW then return end

IOW.Config = IOW.Config or {}
local Config = IOW.Config

Config.version = GetAddOnMetadata(addonName, "Version") or ""

local function getCounter(start, increment)
    start = start or 1
    increment = increment or 1
    return coroutine.wrap(function()
        local count = start
        while true do
            count = count + increment
            coroutine.yield(count)
        end
    end)
end

function Config:GetOptions()
    local orderCount = getCounter()
    local options = {
        type = 'group',
        get = function(info) return Config:GetConfig(info[#info]); end,
        set = function(info, value) return Config:SetConfig(info[#info], value); end,
        args = {
            version = {
                order = orderCount(),
                type = "description",
                name = "Version: " .. self.version
            },
            confirm = {
                order = orderCount(),
                name = "Confirmation",
                desc = "Asks for confirmation for group invites",
                descStyle = 'inline',
                width = "full",
                type = "toggle",
            },
            triggerOutgoingGInv = {
                order = orderCount(),
                name = "Trigger on outgoing whispers for Guild invites",
                descStyle = 'inline',
                width = "full",
                type = "toggle",
            },
            triggerOutgoingInv = {
                order = orderCount(),
                name = "Trigger on outgoing whispers for Group invites",
                descStyle = 'inline',
                width = "full",
                type = "toggle",
            },
            keywordMatchMiddle = {
                order = orderCount(),
                name = "Toggle Smart Match",
                desc = "Smart Match will search your received whispers for an invite keyword. The 'invite' keyword would then be triggered from \"Could you send me an invite please?\"",
                width = "full",
                type = "toggle",
            },
            addGuildInviteTrigger = {
                order = orderCount(),
                type = "input",
                name = "Add Guild invite trigger phrase",
                set = function(_, phrase)
                    IOW.DB.ginv[phrase:lower()] = true
                end,
            },
            removeGuildInviteTrigger = {
                order = orderCount(),
                type = "select",
                style = "dropdown",
                name = "Remove Guild invite trigger phrase",
                desc = "Select a Guild invite trigger phrase to remove it",
                width = "double",
                values = function()
                    local tempTable = {}
                    for phrase, _ in pairs(IOW.DB.ginv) do
                        tempTable[phrase] = phrase
                    end
                    return tempTable
                end,
                get = function(_, _) return false end,
                set = function(_, phrase, ...)
                    IOW.DB.ginv[phrase] = nil
                end,
            },
            addGroupInviteTrigger = {
                order = orderCount(),
                type = "input",
                name = "Add Group invite trigger phrase",
                set = function(_, phrase)
                    IOW.DB.inv[phrase:lower()] = true
                end,
            },
            removeGroupInviteTrigger = {
                order = orderCount(),
                type = "select",
                style = "dropdown",
                name = "Remove Group invite trigger phrase",
                desc = "Select a Group invite trigger phrase to remove it",
                width = "double",
                values = function()
                    local tempTable = {}
                    for phrase, _ in pairs(IOW.DB.inv) do
                        tempTable[phrase] = phrase
                    end
                    return tempTable
                end,
                get = function(_, _) return false end,
                set = function(_, phrase, ...)
                    IOW.DB.inv[phrase] = nil
                end,
            },
        },
    }

    return options
end

function Config:Initialize()
    self:RegisterOptions()
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Invite On Whisper", "Invite On Whisper")
end

function Config:RegisterOptions()
    LibStub("AceConfig-3.0"):RegisterOptionsTable("Invite On Whisper", self:GetOptions())
end

function Config:OpenConfig()
    -- after a reload, you need to open to category twice to actually open the correct page
    InterfaceOptionsFrame_OpenToCategory('Invite On Whisper')
    InterfaceOptionsFrame_OpenToCategory('Invite On Whisper')
end

function Config:GetConfig(property)
    return IOW.DB[property];
end

function Config:SetConfig(property, value)
    IOW.DB[property] = value;
end