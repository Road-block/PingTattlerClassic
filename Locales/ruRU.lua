local addonName, pingo = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "ruRU")
if not L then return end
--Переводчик ZamestoTV
L["Ping Me"] = "Пингани меня"
L["Pinged"] = "Пинг выполнен"
L["East"] = "Восток"
L["North-East"] = "Северо-Восток"
L["North"] = "Север"
L["North-West"] = "Северо-Запад"
L["West"] = "Запад"
L["South-West"] = "Юго-Запад"
L["South"] = "Юг"
L["South-East"] = "Юго-Восток"
L["Self"] = "Себя"
L["Mute"] = "Отключить звук"
L["Muted"] = "Звук отключен"
L["Not Muted"] = "Звук включен"
L["|cffff7f00Click|r to ping your location"] = "|cffff7f00ЛКМ|r для пинга вашего местоположения"
L["|cffff7f00Right Click|r to open options"] = "|cffff7f00ПКМ|r для открытия настроек"
L["|cffff7f00Middle Click|r to mute"] = "|cffff7f00СКМ|r для отключения звука"
L["Hide from Minimap"] = "Скрыть с миникарты"
L["Screen Notifications"] = "Уведомления на экране"
L["Chat Notifications"] = "Уведомления в чате"
L["Minimap Overlay"] = "Наложение на миникарту"
L["Icon Size"] = "Размер значка"
L["Set size of the directional icon"] = "Установить размер значка направления"
L["Distance"] = "Расстояние"
L["Set icon distance from center"] = "Установить расстояние значка от центра"
L["ChatFrame"] = "Окно чата"
L["Anchor"] = "Привязка"
L["Anchor to Minimap Side"] = "Привязка к стороне миникарты"

ping descuento.L = L
