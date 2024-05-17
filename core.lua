local _
local addonName, pingo = ...
local addon = LibStub("AceAddon-3.0"):NewAddon(pingo, addonName, "AceConsole-3.0", "AceHook-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceBucket-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local ADBO = LibStub("AceDBOptions-3.0")
local LDBO = LibStub("LibDataBroker-1.1"):NewDataObject(addonName)
local LDI = LibStub("LibDBIcon-1.0")
local LS = LibStub("LibSink-2.0")

addon._version = C_AddOns.GetAddOnMetadata(addonName,"Version")
addon._addonName = addonName.." "..addon._version
addon._addonNameC = LIGHTBLUE_FONT_COLOR:WrapTextInColorCode(addon._addonName)
addon._addonNameS = LIGHTBLUE_FONT_COLOR:WrapTextInColorCode("PTC")
local _p = {}
_p.PI = math.pi
_p.TWOPI = 2*_p.PI
_p.QUAD = _p.PI/2
_p.textureMarkup = {}
local CLASS_COLORS = (_G.CUSTOM_CLASS_COLORS or _G.RAID_CLASS_COLORS)
local CLASS_ICON_TCOORDS = CLASS_ICON_TCOORDS or {
  ["WARRIOR"]     = {0, 0.25, 0, 0.25},
  ["MAGE"]        = {0.25, 0.49609375, 0, 0.25},
  ["ROGUE"]       = {0.49609375, 0.7421875, 0, 0.25},
  ["DRUID"]       = {0.7421875, 0.98828125, 0, 0.25},
  ["HUNTER"]      = {0, 0.25, 0.25, 0.5},
  ["SHAMAN"]      = {0.25, 0.49609375, 0.25, 0.5},
  ["PRIEST"]      = {0.49609375, 0.7421875, 0.25, 0.5},
  ["WARLOCK"]     = {0.7421875, 0.98828125, 0.25, 0.5},
  ["PALADIN"]     = {0, 0.25, 0.5, 0.75},
  ["DEATHKNIGHT"] = {0.25, .5, 0.5, .75},
}
local ROLE_ICON_TCOORDS = {
  ["TANK"]        = {0, 0.25, 0.25, 0.5},
  ["HEALER"]      = {0.25, 0.49609375, 0, 0.25},
  ["DAMAGER"]     = {0.25, 0.49609375, 0.25, 0.5},
}
local MSG_FMT = "$C $N $M $R" -- $C class icon, $N name, $M raid mark icon, $R rank/role
local classTexSize, mtTexSize, leadTexSize, assistantTexSize, icoTexSize, roleTexSize =
  256, 64, 128, 128, 64, 256 -- let's keep this around in case hires textures become a thing
local function cacheMarkups(what)
  _p.textureMarkup["CLASS"] = _p.textureMarkup["CLASS"] or {}
  _p.textureMarkup["ROLE"] = _p.textureMarkup["ROLE"] or {}
  _p.textureMarkup["RAIDTARGET"] = _p.textureMarkup["RAIDTARGET"] or {}
  for _, eClass in ipairs(CLASS_SORT_ORDER) do
    _p.textureMarkup["CLASS"][eClass] = CreateTextureMarkup("Interface\\TARGETINGFRAME\\ui-classes-circles",classTexSize,classTexSize, 16, 16, CLASS_ICON_TCOORDS[eClass][1], CLASS_ICON_TCOORDS[eClass][2], CLASS_ICON_TCOORDS[eClass][3], CLASS_ICON_TCOORDS[eClass][4])
  end
  _p.textureMarkup["ROLE"]["MAINTANK"] = CreateTextureMarkup("Interface\\RAIDFRAME\\UI-RAIDFRAME-MAINTANK", mtTexSize, mtTexSize, 16, 16, 0, 1, 0, 1)
  _p.textureMarkup["ROLE"]["LEADER"] = CreateTextureMarkup("Interface\\PVPFrame\\Icons\\prestige-icon-7-3", leadTexSize, leadTexSize, 16, 16, 0, 1, 0, 1)
  _p.textureMarkup["ROLE"]["ASSISTANT"] = CreateTextureMarkup("Interface\\PVPFrame\\Icons\\prestige-icon-7-2", assistantTexSize, assistantTexSize, 16, 16, 0, 1, 0, 1)
  for i=1, NUM_RAID_ICONS do
    _p.textureMarkup["RAIDTARGET"][i] = CreateTextureMarkup("Interface\\TargetingFrame\\UI-RaidTargetingIcon_"..i,  icoTexSize, icoTexSize, 16, 16, 0, 1, 0, 1)
  end
  for role, coords in pairs(ROLE_ICON_TCOORDS) do
    _p.textureMarkup["ROLE"][role] = CreateTextureMarkup("Interface\\LFGFRAME\\ui-lfg-icon-roles", roleTexSize, roleTexSize, 16, 16, ROLE_ICON_TCOORDS[role][1], ROLE_ICON_TCOORDS[role][2], ROLE_ICON_TCOORDS[role][3], ROLE_ICON_TCOORDS[role][4])
  end
end
local function GetExtraChatFrames()
  local chatframes = {
    [0] = _G.DEFAULT
  }
  for i=1,NUM_CHAT_WINDOWS do
    local name, fontsize, r, g, b, a, isShown, isLocked, isDocked = GetChatWindowInfo(i)
    local cf = _G["ChatFrame"..i]
    if (isShown or isDocked) and not IsBuiltinChatWindow(cf) then
      chatframes[i] = name
    end
  end
  return chatframes
end
_p.directionDesc = {
  [-1] = L["Self"],
  [0]  = L["East"],
  [1]  = L["North-East"],
  [2]  = L["North"],
  [3]  = L["North-West"],
  [4]  = L["West"],
  [5]  = L["South-West"],
  [6]  = L["South"],
  [7]  = L["South-East"],
}

-- 8 slices, 45 deg tolerance
local function GetRelativeDirection(radian)
   if radian >= 5.899213 or radian < 0.401426 then
      return 0 -- "East" -- "Right"
   elseif radian >= 0.401426 and radian < 1.186824 then
      return 1 -- "North-East" -- "Up-Right"
   elseif radian >= 1.186824 and radian < 1.972222 then
      return 2 -- "North" -- "Up"
   elseif radian >= 1.972222 and radian < 2.75762 then
      return 3 -- "North-West" -- "Up-Left"
   elseif radian >= 2.75762 and radian < 3.543018 then
      return 4 -- "West" -- "Left"
   elseif radian >= 3.543018 and radian < 4.328417 then
      return 5 -- "South-West" -- "Down-Left"
   elseif radian >= 4.328417 and radian < 5.113815 then
      return 6 -- "South" -- "Down"
   elseif radian >= 5.113815 and radian < 5.899213 then
      return 7 -- "South-East" -- "Down-Right"
   end
end

local function XYtoRadian(x, y)
   local radian = math.atan2(y, x)
   if MinimapCompassTexture:IsVisible() then
      local baseEast = MinimapCompassTexture:GetRotation()
      baseEast = baseEast + _p.QUAD*3
      radian = radian - baseEast - _p.QUAD
   end
   radian = radian >=0 and radian or radian + _p.TWOPI
   return radian
end

-- [[ ADDON INSTATIATION ]]
_p.mute = false -- not stored
_p.defaults = {
  global = {
    minimap = {hide = false,},
  },
  profile = {
    screen = {
      enable = true,
      size = 64,
      radius = 150,
    },
    chat = {
      enable = true,
      frame = 0,
    },
    overlay = {
      enable = false,
      anchor = 2,
    },
  },
}
_p.anchors = {
  [1] = "TOPLEFT",
  [2] = "TOP",
  [3] = "TOPRIGHT",
  [4] = "BOTTOMLEFT",
  [5] = "BOTTOM",
  [6] = "BOTTOMRIGHT",
}
_p.consolecmd = {type = "group", handler = addon, args = {
  mute = {type="execute",name=L["Mute"],desc=L["Mute"],func=function()addon:ToggleMute()end,order=1},
  opt = {type="execute",name=_G.OPTIONS,desc=_G.OPTIONS,func=function()addon:ToggleOptionsFrame()end,order=2},
}}
function addon:GetOptionTable()
  if _p.Options and type(_p.Options)=="table" then return _p.Options end
  _p.Options = {type = "group", handler = addon, args = {
    general = {
      type = "group",
      name = _G.OPTIONS,
      childGroups = "tab",
      args = {
        main = {
          type = "group",
          name = _G.GENERAL,
          order = 1,
          args = { },
        },
      }
    }
  }}
  _p.Options.args.general.args.main.args.minimap = {
    type = "toggle",
    name = L["Hide from Minimap"],
    desc = L["Hide from Minimap"],
    order = 10,
    get = function(info) return not not addon.db.global.minimap.hide end,
    set = function(info, val)
      addon.db.global.minimap.hide = not addon.db.global.minimap.hide
    end,
  }
  _p.Options.args.general.args.main.args.screen = {
    type = "group",
    name = L["Screen Notifications"],
    args = { },
    order = 11,
  }
  _p.Options.args.general.args.main.args.chat = {
    type = "group",
    name = L["Chat Notifications"],
    args = { },
    order = 12,
  }
  _p.Options.args.general.args.main.args.overlay = {
    type = "group",
    name = L["Minimap Overlay"],
    args = { },
    order = 13,
  }
  local screenOpt = _p.Options.args.general.args.main.args.screen.args
  local chatOpt = _p.Options.args.general.args.main.args.chat.args
  local overlayOpt = _p.Options.args.general.args.main.args.overlay.args
  screenOpt.enable = {
    type = "toggle",
    name = _G.ENABLE,
    desc = _G.ENABLE,
    order = 1,
    get = function(info) return addon.db.profile.screen.enable end,
    set = function(info,val)
      addon.db.profile.screen.enable = val
    end,
  }
  screenOpt.size = {
    type = "range",
    name = L["Icon Size"],
    desc = L["Set size of the directional icon"],
    order = 2,
    get = function(info) return addon.db.profile.screen.size end,
    set = function(info, val)
      addon.db.profile.screen.size = val
    end,
    min = 32,
    max = 128,
    step = 16,
  }
  screenOpt.radius = {
    type = "range",
    name = L["Distance"],
    desc = L["Set icon distance from center"],
    order = 3,
    get = function(info) return addon.db.profile.screen.radius end,
    set = function(info, val)
      addon.db.profile.screen.radius = val
    end,
    min = 50,
    max = 250,
    step = 10,
  }
  chatOpt.enable = {
    type = "toggle",
    name = _G.ENABLE,
    desc = _G.ENABLE,
    order = 1,
    get = function(info) return addon.db.profile.chat.enable end,
    set = function(info,val)
      addon.db.profile.chat.enable = val
    end,
  }
  chatOpt.frame = {
    type = "select",
    name = L["ChatFrame"],
    desc = L["ChatFrame"],
    order = 2,
    get = function(info) return addon.db.profile.chat.frame end,
    set = function(info,val) addon.db.profile.chat.frame = tonumber(val)  end,
    values = function() return GetExtraChatFrames() end,
  }
  overlayOpt.enable = {
    type = "toggle",
    name = _G.ENABLE,
    desc = _G.ENABLE,
    order = 1,
    get = function(info) return addon.db.profile.overlay.enable end,
    set = function(info,val)
      addon.db.profile.overlay.enable = val
    end,
  }
  overlayOpt.anchor = {
    type = "select",
    name = L["Anchor"],
    desc = L["Anchor to Minimap Side"],
    order = 2,
    get = function(info) return addon.db.profile.overlay.anchor end,
    set = function(info,val)
      addon.db.profile.overlay.anchor = tonumber(val)
      addon:MinimapOverlayUpdate()
    end,
    values = _p.anchors,
  }
  return _p.Options
end

function addon:RefreshConfig()

end

function addon:OnInitialize() -- ADDON_LOADED
  self.db = LibStub("AceDB-3.0"):New("PingTattlerClassicDB", _p.defaults)
  _p.Options = self:GetOptionTable()
  _p.Options.args.profile = ADBO:GetOptionsTable(self.db)
  _p.Options.args.profile.guiHidden = true
  _p.Options.args.profile.cmdHidden = true
  AC:RegisterOptionsTable(addonName.."_cmd", _p.consolecmd, {addonName:lower(),"ptc"})
  AC:RegisterOptionsTable(addonName, _p.Options)
  self.blizzoptions = ACD:AddToBlizOptions(addonName,nil,nil,"general")
  self.blizzoptions.profile = ACD:AddToBlizOptions(addonName, "Profiles", addonName, "profile")
  self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
  self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
  self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

  cacheMarkups()

  LDBO.type = "data source"
  LDBO.text = addon._addonNameC
  LDBO.label = addon._addonNameS
  LDBO.icon = 136437
  LDBO.OnClick = addon.OnLDBClick
  LDBO.OnTooltipShow = addon.OnLDBTooltipShow
  LDI:Register(addonName, LDBO, addon.db.global.minimap)
end

function addon:OnEnable() -- PLAYER_LOGIN
  self.MiniMessage = self.MiniMessage or CreateFrame("MessageFrame",nil,Minimap)
  self.MiniMessage:SetWidth(Minimap:GetWidth()+20)
  self.MiniMessage:SetHeight(80)
  self.MiniMessage:SetFadeDuration(0.5)
  self.MiniMessage:SetFadePower(3)
  self.MiniMessage:SetTimeVisible(2)
  self.MiniMessage:SetFrameStrata("FULLSCREEN_DIALOG")
  self.MiniMessage:SetFrameLevel(1)
  self.MiniMessage:SetToplevel(true)
  self.MiniMessage:SetFont(DEFAULT_CHAT_FRAME:GetFont())
  self.MiniMessage:SetShadowColor(0,0,0,0.9)
  self.MiniMessage:SetShadowOffset(1,-1)
  self.MiniMessage:SetDrawLayerEnabled("OVERLAY")
  self.MiniMessage:EnableMouse(false)
  self.MiniMessage:EnableMouseWheel(false)
  self:MinimapOverlayUpdate()

  self:RegisterEvent("MINIMAP_PING")
  if IsInGuild() then
    self:RegisterEvent("GUILD_ROSTER_UPDATE")
  else
    self:RegisterEvent("PLAYER_GUILD_UPDATE")
  end
end

function addon:MinimapOverlayUpdate()
  local anchor = _p.anchors[self.db.profile.overlay.anchor] or "TOP"
  if strfind(anchor,"TOP") then
    self.MiniMessage:ClearAllPoints()
    self.MiniMessage:SetPoint("TOP")
    self.MiniMessage:SetInsertMode("TOP")
    self.MiniMessage:SetJustifyV("TOP")
  else
    self.MiniMessage:ClearAllPoints()
    self.MiniMessage:SetPoint("BOTTOM")
    self.MiniMessage:SetInsertMode("BOTTOM")
    self.MiniMessage:SetJustifyV("BOTTOM")
  end
  if strfind(anchor,"LEFT") then
    self.MiniMessage:SetJustifyH("LEFT")
  elseif strfind(anchor,"RIGHT") then
    self.MiniMessage:SetJustifyH("RIGHT")
  else
    self.MiniMessage:SetJustifyH("CENTER")
  end
  self.MiniMessage:Show()
end

function addon:PingMe(reason)
  Minimap:PingLocation(0,0)
end

function addon:Print(msg, chatNum)
  local chatFrame = (_G.SELECTED_CHAT_FRAME or _G.DEFAULT_CHAT_FRAME)
  if type(chatNum)=="number" then
    local _, _, _, _, _, _, isShown, _, isDocked = GetChatWindowInfo(chatNum)
    if isShown or isDocked then
      chatFrame = _G["ChatFrame"..chatNum]
    end
  end
  chatFrame:AddMessage(string.format("%s: %s", self._addonNameS, msg))
end

function addon:ToggleMute()
  _p.mute = not _p.mute
  self:Print(_p.mute and L["Muted"] or L["Not Muted"])
end

function addon:PrintNotification(direction, me, name, class, raidtarget, maintank, leader, assistant, role, guild)
  if _p.mute then return end
  if not self.db.profile.chat.enable then return end
  local directionDesc = _p.directionDesc[direction]
  local classColor = CLASS_COLORS[class] or GRAY_FONT_COLOR
  local name_c = classColor:WrapTextInColorCode(name)
  local namelink = GetPlayerLink(name, name_c) or name_c
  local classIcon = _p.textureMarkup["CLASS"][class] or ""
  local raidIcon = _p.textureMarkup["RAIDTARGET"][raidtarget] or ""
  local mtIcon = _p.textureMarkup["ROLE"][maintank] or ""
  local leadIcon = _p.textureMarkup["ROLE"][leader] or ""
  local assistIcon = _p.textureMarkup["ROLE"][assistant] or ""
  local roleIcon = _p.textureMarkup["ROLE"][role] or ""
  if maintank == "MAINTANK" and role == "TANK" then
    roleIcon = ""
  end
  local msg = string.format("%s%s%s%s%s%s%s "..L["Pinged"].." > %s",raidIcon,classIcon,namelink,leadIcon,mtIcon,assistIcon,roleIcon,directionDesc)
  self:Print(msg, addon.db.profile.chat.frame)
end

function addon:MessageNotification(direction, me, name, class, raidtarget, maintank, leader, assistant, role, guild)
  if _p.mute then return end
  if not self.db.profile.screen.enable then return end
  local directionDesc = _p.directionDesc[direction]
  local classColor = CLASS_COLORS[class] or GRAY_FONT_COLOR
  local name_c = classColor:WrapTextInColorCode(name)
  local classIcon = _p.textureMarkup["CLASS"][class] or ""
  local raidIcon = _p.textureMarkup["RAIDTARGET"][raidtarget] or ""
  local mtIcon = _p.textureMarkup["ROLE"][maintank] or ""
  local leadIcon = _p.textureMarkup["ROLE"][leader] or ""
  local assistIcon = _p.textureMarkup["ROLE"][assistant] or ""
  local roleIcon = _p.textureMarkup["ROLE"][role] or ""
  if maintank == "MAINTANK" and role == "TANK" then
    roleIcon = ""
  end
  local msg = string.format("%s %s%s%s%s%s%s%s",directionDesc, raidIcon,classIcon,name_c,leadIcon,mtIcon,assistIcon,roleIcon)
  RaidNotice_AddMessage(RaidBossEmoteFrame, msg, ChatTypeInfo.RAID_BOSS_EMOTE, 3.0)
end

function addon:ShowDirectionIcon(dir, size, radius)
  -- 0 = standard position (on x-axis, "East", "Right")
  -- incrementing by 1 ccw for 2PI/8 slices
  if _p.mute then return end
  if not addon.db.profile.screen.enable then return end
  local size = size or 64
  local radius = radius or 200
  if not _p.directionIcon then
    _p.directionIcon = UIParent:CreateTexture(addonName.."DirectionArrow","OVERLAY")
    _p.directionIcon:SetTexture("Interface\\AddOns\\"..addonName.."\\Media\\misc_arrowright") -- "Interface\\ICONS\\misc_arrowright"
    _p.directionIcon:SetTexCoord(0.05,0.95,0.05,0.95)
    _p.directionIcon:SetSize(size,size)
    _p.directionIcon:SetPoint("CENTER")
    _p.directionIcon.ag = _p.directionIcon:CreateAnimationGroup()
    _p.directionIcon.fadein = _p.directionIcon.ag:CreateAnimation("Alpha")
    _p.directionIcon.fadein:SetOrder(0)
    _p.directionIcon.fadein:SetDuration(0.5)
    _p.directionIcon.fadein:SetFromAlpha(0)
    _p.directionIcon.fadein:SetToAlpha(1.0)
    _p.directionIcon.hold = _p.directionIcon.ag:CreateAnimation("Alpha")
    _p.directionIcon.hold:SetOrder(1)
    _p.directionIcon.hold:SetDuration(1.0)
    _p.directionIcon.hold:SetFromAlpha(1.0)
    _p.directionIcon.hold:SetToAlpha(1.0)
    _p.directionIcon.fadeout = _p.directionIcon.ag:CreateAnimation("Alpha")
    _p.directionIcon.fadeout:SetOrder(2)
    _p.directionIcon.fadeout:SetDuration(1.0)
    _p.directionIcon.fadeout:SetFromAlpha(1.0)
    _p.directionIcon.fadeout:SetToAlpha(0)
    _p.directionIcon.ag:SetScript("OnFinished",function()
      _p.directionIcon:SetAlpha(0)
      _p.directionIcon:Hide()
    end)
    _p.directionIcon:Hide()
  end
  _p.directionIcon:SetSize(size,size)
  local angle = dir*_p.PI/4
  _p.directionIcon:SetRotation(angle)
  local offx, offy = radius*math.cos(angle), radius*math.sin(angle)
  _p.directionIcon:ClearAllPoints()
  _p.directionIcon:SetPoint("CENTER",UIParent,"CENTER",offx,offy)
  _p.directionIcon:Show()
  if _p.directionIcon.ag:IsPlaying() then
    _p.directionIcon.ag:Stop()
  end
  _p.directionIcon.ag:Play()
end

function addon:MinimapNotification(direction, me, name, class, raidtarget, maintank, leader, assistant, role, guild)
  if _p.mute then return end
  if not self.db.profile.overlay.enable then return end
  local directionDesc = _p.directionDesc[direction]
  local classColor = CLASS_COLORS[class] or GRAY_FONT_COLOR
  local name_c = classColor:WrapTextInColorCode(name)
  if maintank == "MAINTANK" and role == "TANK" then
    roleIcon = ""
  end
  local msg = string.format("%s > %s",name_c,directionDesc)
  if self.MiniMessage then
    self.MiniMessage:AddMessage(msg)
  end
end

function addon:ToggleOptionsFrame()
  if ACD.OpenFrames[addonName] then
    ACD:Close(addonName)
  else
    ACD:Open(addonName,"general")
  end
end

function addon:GetRole(unit)
  local role = "NONE"
  if IsInRaid() and GetNumGroupMembers() > 1 then
    for i=1,MAX_RAID_MEMBERS do
      local name, rank, _, level, _, fileName, _, _, _, role, _, combatRole = GetRaidRosterInfo(i)
      if name and (name ~= _G.UNKNOWNOBJECT) and level and (level > 0) then
        if UnitIsUnit(unit, "raid"..i) then
          role = combatRole
          break
        end
      end
    end
  end
  if not role or (role == "NONE") then
    role = UnitGroupRolesAssigned(unit)
  end
  return role
end

function addon.OnLDBClick(obj,button)
  if button == "LeftButton" then
    addon:PingMe("minimap-button")
  elseif button == "RightButton" then
    addon:ToggleOptionsFrame()
  elseif button == "MiddleButton" then
    addon:ToggleMute()
  end
end
function addon.OnLDBTooltipShow(tooltip)
  tooltip = tooltip or GameTooltip
  local title = addon._addonNameC
  tooltip:SetText(title)
  local hint = L["|cffff7f00Click|r to ping your location"]
  tooltip:AddLine(hint)
  hint = L["|cffff7f00Right Click|r to open options"]
  tooltip:AddLine(hint)
  hint = L["|cffff7f00Middle Click|r to mute"]
  tooltip:AddLine(hint)
end

function addon:GUILD_ROSTER_UPDATE(event)
  _p.guildRoster = table.wipe(_p.guildRoster or {})
  for i=1,GetNumGuildMembers(1) do
    local name, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote, isOnline, status, class, achievementPoints, achievementRank, isMobile, canSoR, repStanding, guid = GetGuildRosterInfo(i)
    if name and (name ~= UNKNOWNOBJECT) and level and (level > 0) then
      _p.guildRoster[guid] = {name=name,class=class}
      _p.guildRoster[name] = {guid=guid,level=level}
    end
  end
end

function addon:PLAYER_GUILD_UPDATE(event,unit)
  if UnitIsUnit("player", unit) then
    if IsInGuild() then
      self:RegisterEvent("GUILD_ROSTER_UPDATE")
      self:GUILD_ROSTER_UPDATE("GUILD_ROSTER_UPDATE")
    else
      _p.guildRoster = table.wipe(_p.guildRoster or {})
    end
  end
end

function addon:MINIMAP_PING(event, ...)
  local unit, x, y = ...
  x = x or 0
  y = y or 0
  if not UnitExists(unit) then return end
  local now = GetTime()
  if _p.lastPing and ((now - _p.lastPing.when) <= 0.5) and (UnitIsUnit(_p.lastPing.who, unit)) then
    return -- throttle consecutive pings from same unit
  end
  _p.lastPing = _p.lastPing or {}
  _p.lastPing.when = now
  _p.lastPing.who = unit
  local me = unit and UnitIsUnit("player",unit)
  local name = (UnitNameUnmodified(unit))
  local class = UnitClassBase(unit)
  local guid = UnitGUID(unit)
  local raidtarget = GetRaidTargetIndex(unit) or false
  local inRaid = UnitInRaid(unit) or false
  local inParty = UnitInParty(unit) or false
  local maintank = inRaid and GetPartyAssignment("MAINTANK", unit) and "MAINTANK" or "NONE"
  local leader = UnitIsGroupLeader(unit) and "LEADER" or "NONE"
  local assistant = UnitIsGroupAssistant(unit) or IsEveryoneAssistant() and "ASSISTANT" or "NONE"
  local role = self:GetRole(unit)
  local guild = IsInGuild() and _p.guildRoster[guid] and true or false
  local direction = GetRelativeDirection(XYtoRadian(x,y))
  local on_self = not (abs(x) > 0.01 and abs(y) > 0.01)
  if on_self then
    direction = -1
  end

  self:PrintNotification(direction, me,name,class,raidtarget,maintank,leader,assistant,role,guild)
  self:MessageNotification(direction, me,name,class,raidtarget,maintank,leader,assistant,role,guild)
  self:MinimapNotification(direction, me,name,class,raidtarget,maintank,leader,assistant,role,guild)
  if not on_self then
    self:ShowDirectionIcon(direction, self.db.profile.screen.size, self.db.profile.screen.radius)
  end
end
_G[addonName] = addon


_G["BINDING_HEADER_PINGTATTLERCLASSIC"] = addonName
_G["BINDING_NAME_PINGTATTLERCLASSICME"] = L["Ping Me"]