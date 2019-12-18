IOWDB= {
	ginv = {
        ginv = true,
        guildinv = true,
        ginvite = true
    },
    inv = {
        inv = true,
        invite = true
    },
    confirm = true
}
local nameAndVersion = "InviteOnWhisper v"..GetAddOnMetadata("InviteOnWhisper", "Version")
local IOWmsgPrefix = "<InviteOnWhisper> "

local GuildInvite = GuildInvite
local InviteUnit = C_PartyInfo.InviteUnit
local print = print
local BNGetFriendInfoByID = BNGetFriendInfoByID
local lower = lower
local trim = trim
local strlower = strlower
local tinsert = tinsert
local _M = {}
IOWFunctions = _M

local IOW = CreateFrame("Frame", "InviteOnWhisper")

local function OnEvent(self, event, ...)
	local dispatch = self[event]

	if dispatch then
		dispatch(self, ...)
	end
end

IOW:SetScript("OnEvent", OnEvent)
IOW:RegisterEvent("ADDON_LOADED")
IOW:RegisterEvent("CHAT_MSG_BN_WHISPER")
IOW:RegisterEvent("CHAT_MSG_WHISPER")
--IOW:RegisterEvent("CHAT_MSG_GUILD")

function IOW:ADDON_LOADED(addonName)
    print("Loaded " .. nameAndVersion .. "; type '/iow info', for more info")
    
    if IOWDB.ginv == nil then
        IOWDB.ginv = {
            ginv = true,
            guildinv = true,
            ginvite = true
        }
    end
    if IOWDB.inv == nil then
        IOWDB.inv = {
            inv = true,
            invite = true
        }
    end
    if IOWDB.confirm == nil then
        IOWDB.confirm = true
    end
    if IOWDB.keywordMatchMiddle == nil then
        IOWDB.keywordMatchMiddle = true
    end
    
    StaticPopupDialogs["IOWguildinvPopup"] = {
        text = "Do you want to invite %s to your guild?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function(self, data)
            GuildInvite(data)
        end,
        OnCancel = function()
            --do nuffin
            return
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3, 
    }
    
    StaticPopupDialogs["IOWgroupinvPopup"] = {
        text = "Do you want to invite %s to your party/raid?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function(self, data)
            InviteUnit(data)
        end,
        OnCancel = function()
            --do nuffin
            return
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3, 
    }
    
    self:UnregisterEvent("ADDON_LOADED")
end

function IOW:CHAT_MSG_BN_WHISPER(msg, _, _, _, _, _, _, _, _, _, _, _, bnetIDAccount,_)
    local _, _, _, _, charname, _ = BNGetFriendInfoByID(bnetIDAccount)
    _M.process_msg(msg, charname)
end

function IOW:CHAT_MSG_WHISPER(msg,charname,_)
    _M.process_msg(msg,charname)
end

function IOW:CHAT_MSG_GUILD(msg,charname,_)
    return
end


_M.process_msg = function(msg,charname)
    msg = msg:lower():trim()
    if IOWDB.ginv[msg] then
        local dialog = StaticPopup_Show("IOWguildinvPopup", charname)
        if (dialog) then
            dialog.data = charname
        end
    elseif IOWDB.inv[msg] then
        if(IOWDB.confirm) then
            local dialog = StaticPopup_Show("IOWgroupinvPopup", charname)
            if (dialog) then
                dialog.data = charname
            end
        else
            print(IOWmsgPrefix .. "Trying to invite" ..charname .." to your party/raid")
            print(IOWmsgPrefix .. "Type '/iow toggleconfirm' to ask for confirmation before inviting")
            InviteUnit(charname)
        end
    end
    if IOWDB.keywordMatchMiddle then
        local found = false
        msg = ' ' .. msg .. ' '
        -- wrapping msg around spaces, so that it starts and ends with a non alphabetical letter
        for phrase in pairs(IOWDB.ginv) do
            if msg:find('[^A-z]' .. phrase:lower():trim() .. '[^A-z]') then
                local dialog = StaticPopup_Show("IOWguildinvPopup", charname)
                if (dialog) then
                    found = true
                    dialog.data = charname
                end
                break
            end
        end
        if not found then
            for phrase in pairs(IOWDB.inv) do
                if msg:find('[^A-z]' .. phrase:lower():trim() .. '[^A-z]') then
                    local dialog = StaticPopup_Show("IOWgroupinvPopup", charname)
                    if (dialog) then
                        found = true
                        dialog.data = charname
                    end
                    break
                end
            end
        end
        if found then
            print(IOWmsgPrefix .. "an invite keyword was found in the whisper you received. Type \"/iow toggleSmartMatch\" if you don't want long whispers to trigger an invite.")
            if(not IOWDB.confirm) then
                print(IOWmsgPrefix .. "The confirmation dialog cannot be disabled when Smart Match got triggered")
            end
        end
    end
end

_M.printInfo = function(subject)
    print(nameAndVersion)
    print("This addon is a work in progress!")
    print("If someone whispers you 'ginv', 'ginvite' or 'guildinv', they'll be invited to your guild if possible")
    print("If they whisper 'inv' or 'invite', they'll be invited to your party/raid")
end

_M.alterList = function(invtype, keyword, add)
    local syntaxerror = false
    if(invtype == nil) or (keyword == nil) then
        syntaxerror = true
    end
    if(invtype ~= "ginv" and invtype ~= "inv") then
        syntaxerror = true
    end
    if (syntaxerror) then
        if (add) then
            print(IOWmsgPrefix .. "Incorrect usage; correct ussage is: /iow add [inv || ginv] [*new keyword*]")
            print(IOWmsgPrefix .. "Example, to invite someone when they whisper you 'hi': /iow add inv hi")
        else
            print(IOWmsgPrefix .. "Incorrect usage; correct ussage is: /iow remove [inv || ginv] [*new keyword*]")
            print(IOWmsgPrefix .. "Example, to guildinvite someone when they whisper you 'hi': /iow add ginv hi")
        end
        return
    end
    IOWDB[invtype][keyword] = val
    
    if (add) then
        print(IOWmsgPrefix .. "added '" .. keyword .. "' to the list: " .. invtype)
    else
        print(IOWmsgPrefix .. "removed '" .. keyword .. "' from the list: " .. invtype)
    end
end


SLASH_IOW1="/iow"
SlashCmdList["IOW"] =
	function(msg)
		local a1, a2, a3 = strsplit(" ", strlower(msg), 3)
        if (a1 == "") then 
            _M.printInfo()
        elseif (a1 == "info")  then 
            _M.printInfo(a2)
        elseif(a1 == "add") then
            _M.alterList(a2, a3, true)
        elseif(a1 == "remove") then
            _M.alterList(a2, a3, false)
        elseif(a1 == "toggleconfirm") then
            IOWDB.confirm = (not IOWDB.confirm)
            if(IOWDB.confirm) then
                print(IOWmsgPrefix .. "confirmation for group invites is now turned ON")
            else
                print(IOWmsgPrefix .. "confirmation for group invites is now turned OFF")
            end
        elseif(a1 == "togglesmartmatch") then
            IOWDB.keywordMatchMiddle = (not IOWDB.keywordMatchMiddle)
            print(IOWmsgPrefix .. "smart match will search your received whispers for an invite keyword. the 'invite' keyword would then be triggered from \"Could you send me an invite please?\"")
            if(IOWDB.keywordMatchMiddle) then
                print(IOWmsgPrefix .. "smart match is now turned ON")
            else
                print(IOWmsgPrefix .. "smart match is now turned OFF")
            end
        end
    end   

