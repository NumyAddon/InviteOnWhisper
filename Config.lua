local addonName = ...;

---@class (partial) InviteOnWhisper
local IOW = LibStub("AceAddon-3.0"):GetAddon(addonName);
if not IOW then return; end

local Config = {};
IOW.Config = Config;

Config.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or ""
Config.name = "Invite On Whisper";

function Config:GetOptions()
    local increment = CreateCounter();
    local options = {
        type = 'group',
        get = function(info) return self:GetConfig(info[#info]); end,
        set = function(info, value) return self:SetConfig(info[#info], value); end,
        args = {
            version = {
                order = increment(),
                type = "description",
                name = "Version: " .. self.version,
            },
            confirm = {
                order = increment(),
                name = "Confirmation",
                desc = "Asks for confirmation for group invites",
                descStyle = 'inline',
                width = "full",
                type = "toggle",
            },
            triggerOutgoingGInv = {
                order = increment(),
                name = "Trigger on outgoing whispers for Guild invites",
                descStyle = 'inline',
                width = "full",
                type = "toggle",
            },
            triggerOutgoingInv = {
                order = increment(),
                name = "Trigger on outgoing whispers for Group invites",
                descStyle = 'inline',
                width = "full",
                type = "toggle",
            },
            keywordMatchMiddle = {
                order = increment(),
                name = "Toggle Smart Match",
                desc = "Smart Match will search your received whispers for an invite keyword. If any invite keyword is found in the whisper, it will trigger an invite. For example, the 'invite' keyword would then be triggered from \"Invite please?\"",
                width = "full",
                type = "toggle",
            },
            addGuildInviteTrigger = {
                order = increment(),
                type = "input",
                name = "Add Guild invite trigger phrase",
                set = function(_, phrase)
                    IOW.DB.ginv[phrase:lower()] = true;
                end,
            },
            removeGuildInviteTrigger = {
                order = increment(),
                type = "select",
                style = "dropdown",
                name = "Remove Guild invite trigger phrase",
                desc = "Select a Guild invite trigger phrase to remove it",
                width = "double",
                values = function()
                    local tempTable = {};
                    for phrase, _ in pairs(IOW.DB.ginv) do
                        tempTable[phrase] = phrase;
                    end

                    return tempTable;
                end,
                get = function() return false; end,
                set = function(_, phrase)
                    IOW.DB.ginv[phrase] = nil;
                end,
            },
            addGroupInviteTrigger = {
                order = increment(),
                type = "input",
                name = "Add Group invite trigger phrase",
                set = function(_, phrase)
                    IOW.DB.inv[phrase:lower()] = true;
                end,
            },
            removeGroupInviteTrigger = {
                order = increment(),
                type = "select",
                style = "dropdown",
                name = "Remove Group invite trigger phrase",
                desc = "Select a Group invite trigger phrase to remove it",
                width = "double",
                values = function()
                    local tempTable = {};
                    for phrase, _ in pairs(IOW.DB.inv) do
                        tempTable[phrase] = phrase;
                    end

                    return tempTable;
                end,
                get = function() return false end,
                set = function(_, phrase, ...)
                    IOW.DB.inv[phrase] = nil;
                end,
            },
        },
    };

    return options;
end

function Config:Initialize()
    self:RegisterOptions();
    local _, categoryID = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(self.name, self.name);
    self.categoryID = categoryID;
end

function Config:RegisterOptions()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(self.name, self:GetOptions());
end

function Config:OpenConfig()
    Settings.OpenToCategory(self.categoryID);
end

function Config:GetConfig(property)
    return IOW.DB[property];
end

function Config:SetConfig(property, value)
    IOW.DB[property] = value;
end
