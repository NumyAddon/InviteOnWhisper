-- upvalue the globals
local _G = getfenv(0)
local LibStub = _G.LibStub
local pairs = _G.pairs
local GuildInvite = _G.GuildInvite
local C_PartyInfo = _G.C_PartyInfo
local C_BattleNet = _G.C_BattleNet
local StaticPopupDialogs = _G.StaticPopupDialogs
local StaticPopup_Show = _G.StaticPopup_Show

local addonName = ...

local IOW = LibStub('AceAddon-3.0'):NewAddon(addonName, 'AceConsole-3.0', 'AceHook-3.0', 'AceEvent-3.0');
if not IOW then return end

IOWDB = IOWDB or {}

function IOW:OnInitialize()
    self.DB = IOWDB
    self:InitDefaults()

    self.Config:Initialize()

    self:RegisterEvent("CHAT_MSG_BN_WHISPER", function(_, message, _, _, _, _, _, _, _, _, _, _, _, bnetIDAccount, _)
        self:HandleBnetWhisper(message, bnetIDAccount, false)
    end)
    self:RegisterEvent("CHAT_MSG_BN_WHISPER_INFORM", function(_, message, _, _, _, _, _, _, _, _, _, _, _, bnetIDAccount, _)
        self:HandleBnetWhisper(message, bnetIDAccount, true)
    end)
    self:RegisterEvent("CHAT_MSG_WHISPER", function(_, message, characterName, _)
        self:HandleWhisper(message, characterName, false)
    end)
    self:RegisterEvent("CHAT_MSG_WHISPER_INFORM", function(_, message, characterName, _)
        self:HandleWhisper(message, characterName, true)
    end)
    self:RegisterChatCommand('iow', self.Config.OpenConfig)

    StaticPopupDialogs["IOWguildinvPopup"] = {
        text = "Do you want to invite %s to your guild?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function(_, characterName)
            GuildInvite(characterName)
        end,
        OnCancel = function() end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopupDialogs["IOWgroupinvPopup"] = {
        text = "Do you want to invite %s to your party/raid?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function(_, characterName)
            C_PartyInfo.InviteUnit(characterName)
        end,
        OnCancel = function() end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

function IOW:InitDefaults()
    local defaults = {
        ginv = {
            ginv = true,
            guildinv = true,
            ginvite = true
        },
        inv = {
            inv = true,
            invite = true
        },
        confirm = true,
        keywordMatchMiddle = true,
        triggerOutgoingGInv = true,
        triggerOutgoingInv = false,
    }

    for property, value in pairs(defaults) do
        if self.DB[property] == nil then
            self.DB[property] = value
        end
    end
end

function IOW:HandleWhisper(message, characterName, outgoing)
    self:ProcessMessage(message, characterName, outgoing)
end

function IOW:HandleBnetWhisper(message, bnetIDAccount, outgoing)
    local accountInfo = C_BattleNet.GetAccountInfoByID(bnetIDAccount)
    if(accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.characterName and accountInfo.gameAccountInfo.realmName) then
        local characterName = accountInfo.gameAccountInfo.characterName .. '-' .. accountInfo.gameAccountInfo.realmName
        self:ProcessMessage(message, characterName, outgoing)
    end
end

function IOW:ProcessMessage(message, characterName, outgoing)
    message = message:lower():trim()
    if self.DB.ginv[message] and (not outgoing or self.DB.triggerOutgoingGInv) then
        local dialog = StaticPopup_Show("IOWguildinvPopup", characterName)
        if (dialog) then
            dialog.data = characterName
        end
        return
    elseif self.DB.inv[message] and (not outgoing or self.DB.triggerOutgoingInv) then
        if(self.DB.confirm) then
            local dialog = StaticPopup_Show("IOWgroupinvPopup", characterName)
            if (dialog) then
                dialog.data = characterName
            end
        else
            self:Print("Trying to invite" .. characterName .." to your party/raid")
            C_PartyInfo.InviteUnit(characterName)
        end
        return
    end

    if self.DB.keywordMatchMiddle then
        local found = false
        message = ' ' .. message .. ' '
        -- wrapping spaces around message, so that it starts and ends with a non alphabetical letter
        for phrase in pairs(self.DB.ginv) do
            if (not outgoing) and message:find('[^A-z]' .. phrase:lower():trim() .. '[^A-z]') then
                local dialog = StaticPopup_Show("IOWguildinvPopup", characterName)
                if (dialog) then
                    found = true
                    dialog.data = characterName
                end
                break
            end
        end

        if not found then
            for phrase in pairs(self.DB.inv) do
                if (not outgoing) and message:find('[^A-z]' .. phrase:lower():trim() .. '[^A-z]') then
                    local dialog = StaticPopup_Show("IOWgroupinvPopup", characterName)
                    if (dialog) then
                        found = true
                        dialog.data = characterName
                    end
                    break
                end
            end
        end

        if found then
            self:Print("An invite keyword was found in the whisper you received. Type \"/iow\" and disable 'Smart Match' if you don't want long whispers to trigger an invite.")
            if(not self.DB.confirm) then
                self:Print("The confirmation dialog cannot be disabled when Smart Match got triggered")
            end
        end
    end
end
