------------------------------------------------------
-- #模块名：五彩石助手模块
-- #模块说明：五彩石属性筛选
------------------------------------------------------

AH_Diamond = {
	tLastDiamondData = {
		["Normal"] = {},
		["Simplify"] = {}
	}
}

local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber

local szIniFile = "Interface/AH/ui/AH_Diamond.ini"
local tDiamondType = {"Normal", "Simplify"}

--通用下拉菜单生成
local Menu = class()
function Menu:ctor(text)
	self.text = text
end

function Menu:GetMenu()
	local menu = {}
	local xT, yT = self.text:GetAbsPos()
	local wT, hT = self.text:GetSize()
	menu.nMiniWidth = wT + 16
	menu.x = xT + 2
	menu.y = yT + hT - 1
	return menu
end

--数据筛选
function AH_Diamond.Attribute2Magic(szType, szAttribute)
	for k, v in ipairs(AH_Library.tColorMagic[szType]) do
		if szAttribute == v[1] then
			return v[2]
		end
	end
	return nil
end

function AH_Diamond.IsMagicInAttribute(szType, szMagic, nIndex)
	for k, v in ipairs(AH_Diamond.tLastDiamondData[szType]) do
		if v[nIndex + 2] and szMagic == v[nIndex + 2] then
			return true
		end
	end
	return false
end

--筛选石头
function AH_Diamond.FilterDiamondLevel(szType, szLevel)
	for k, v in ipairs(AH_Library.tColorDiamond[szType]) do
		if StringFindW(v[2], szLevel) then
			table.insert(AH_Diamond.tLastDiamondData[szType], v)
		end
	end
end

function AH_Diamond.FiterDiamondMagic(szType, nIndex, szMagic)
	local temp = {}
	for k, v in ipairs(AH_Diamond.tLastDiamondData[szType]) do
		if AH_Diamond.Attribute2Magic(szType, v[nIndex + 2]) == szMagic then
			table.insert(temp, v)
		end
	end
	AH_Diamond.tLastDiamondData[szType] = temp
end

function AH_Diamond.IsMagicAttribute(szAttribute)
	for k, v in ipairs({"内功", "外功", "阴性", "混元", "毒性", "阴阳", "阳性"}) do
		if szAttribute == v then
			return true
		end
	end
	return false
end

--菜单弹出相关
function AH_Diamond.PopupDiamondLevel(frame, nIndex)
	local hWnd = frame:Lookup(string.format("PageSet_Totle/Page_Type%d/Wnd_Type%d", nIndex, nIndex))
	local handle = hWnd:Lookup("", "")
	local hText = handle:Lookup(string.format("Text_Type%dLevelBg", nIndex))
	local hBtn = hWnd:Lookup(string.format("Btn_Type%dLevel", nIndex))
	local hReset = hWnd:Lookup(string.format("Btn_Type%dReset", nIndex))

	local szType = tDiamondType[nIndex]
	local menu = Menu.new(hText):GetMenu()

	local tLevel = nil
	if nIndex == 1 then
		tLevel = {"壹", "贰", "叁", "肆", "伍", "陆"}
	elseif nIndex == 2 then
		tLevel = {"肆", "伍", "陆"}
	end

	for k, v in ipairs(tLevel) do
		local m = {
			szOption = v,
			fnAction = function()
				hText:SetText(v)
				AH_Diamond.FilterDiamondLevel(szType, v)
				hBtn:Enable(false)
				hReset:Enable(true)
			end
		}
		table.insert(menu, m)
	end
	PopupMenu(menu)
end

function AH_Diamond.PopupDiamondAttribute(frame, nIndex, nAtr)
	local hWnd = frame:Lookup(string.format("PageSet_Totle/Page_Type%d/Wnd_Type%d", nIndex, nIndex))
	local handle = hWnd:Lookup("", "")
	local hText = handle:Lookup(string.format("Text_Type%dAttr%dBg", nIndex, nAtr))
	local hBtn = hWnd:Lookup(string.format("Btn_Type%dAttr%d", nIndex, nAtr))
	local hSearch = hWnd:Lookup(string.format("Btn_Type%dSearch", nIndex))

	local hLevel = handle:Lookup(string.format("Text_Type%dLevelBg", nIndex))
	local hPrev = handle:Lookup(string.format("Text_Type%dAttr%dBg", nIndex, nAtr - 1))
	if hLevel:GetText() == "" or (hPrev and hPrev:GetText() == "") then
		return
	end

	local szType = tDiamondType[nIndex]
	local menu = Menu.new(hText):GetMenu()

	local function _get(t, d)
		for k, v in ipairs(t) do
			for k2, v2 in pairs(v) do
				if type(k2) == "string" and k2 == d then
					return v
				end
			end
		end
		return nil
	end

	--处理分类
	local tTemp, i = {}, 1
	for k, v in ipairs(AH_Library.tColorMagic[szType]) do
		if AH_Diamond.IsMagicInAttribute(szType, v[1], nAtr) then
			if not tTemp[i] then
				tTemp[i] = {}
			end
			local szAtr = string.sub(v[2], 1, 4)
			if AH_Diamond.IsMagicAttribute(szAtr) then
				local t = _get(tTemp, szAtr)
				if not t then
					tTemp[i][szAtr] = {}
					t = _get(tTemp, szAtr)
				end
				table.insert(t[szAtr], {v[1], v[2]})
			else
				table.insert(tTemp[i], {v[1], v[2]})
			end
			i = i + 1
		end
	end
	--生成菜单
	for k, v in ipairs(tTemp) do
		for k2, v2 in pairs(v) do
			if type(k2) == "string" then
				local mAtr = {szOption = k2}
				for k3, v3 in pairs(v2) do
					local m = {
						szOption = v3[2],
						fnAction = function()
							hText:SetText(v3[2])
							AH_Diamond.FiterDiamondMagic(szType, nAtr, v3[2])
							hBtn:Enable(false)
							if (nIndex == 1 and nAtr == 3) or (nIndex == 2 and nAtr == 2) then
								hSearch:Enable(true)
							end
						end
					}
					table.insert(mAtr, m)
				end
				table.insert(menu, mAtr)
			else
				local m = {
					szOption = v2[2],
					fnAction = function()
						hText:SetText(v2[2])
						AH_Diamond.FiterDiamondMagic(szType, nAtr, v2[2])
						hBtn:Enable(false)
						if (nIndex == 1 and nAtr == 3) or (nIndex == 2 and nAtr == 2) then
							hSearch:Enable(true)
						end
					end
				}
				table.insert(menu, m)
			end
		end
	end
	PopupMenu(menu)
end

function AH_Diamond.Init(frame, nIndex)
	local hWnd = frame:Lookup(string.format("PageSet_Totle/Page_Type%d/Wnd_Type%d", nIndex, nIndex))
	hWnd:Lookup(string.format("Btn_Type%dReset", nIndex)):Enable(false)
	hWnd:Lookup(string.format("Btn_Type%dSearch", nIndex)):Enable(false)
end

function AH_Diamond.ResetAllOptions(frame, nIndex)
	local hWnd = frame:Lookup(string.format("PageSet_Totle/Page_Type%d/Wnd_Type%d", nIndex, nIndex))
	local handle = hWnd:Lookup("", "")
	hWnd:Lookup(string.format("Btn_Type%dLevel", nIndex)):Enable(true)
	handle:Lookup(string.format("Text_Type%dLevelBg", nIndex)):SetText("")
	handle:Lookup(string.format("Box_Type%dItem", nIndex)):ClearObject()
	handle:Lookup(string.format("Text_Type%dItem", nIndex)):SetText("")

	for i = 1, 3 do
		local hBtn = hWnd:Lookup(string.format("Btn_Type%dAttr%d", nIndex, i))
		if hBtn then
			hBtn:Enable(true)
		end
		local hText = handle:Lookup(string.format("Text_Type%dAttr%dBg", nIndex, i))
		if hText then
			hText:SetText("")
		end
	end

	local szType = tDiamondType[nIndex]
	AH_Diamond.tLastDiamondData[szType] = {}
end

function AH_Diamond.SearchDiamond(frame, nIndex)
	local hWnd = frame:Lookup(string.format("PageSet_Totle/Page_Type%d/Wnd_Type%d", nIndex, nIndex))
	local handle = hWnd:Lookup("", "")
	local box = handle:Lookup(string.format("Box_Type%dItem", nIndex))
	local txt = handle:Lookup(string.format("Text_Type%dItem", nIndex))

	local szType = tDiamondType[nIndex]
	local dwID, szName, _, _ = unpack(AH_Diamond.tLastDiamondData[szType][1])

	local ItemInfo = GetItemInfo(5, dwID)
	if ItemInfo then
		txt:SetText(szName)
		txt:SetFontColor(GetItemFontColorByQuality(ItemInfo.nQuality, false))

		box.szName = szName
		box:SetObject(UI_OBJECT_ITEM_INFO, ItemInfo.nUiId, GLOBAL.CURRENT_ITEM_VERSION, 5, dwID)
		box:SetObjectIcon(Table_GetItemIconID(ItemInfo.nUiId))
		UpdateItemBoxExtend(box, ItemInfo.nGenre, ItemInfo.nQuality, ItemInfo.nStrengthLevel)
	end
end

------------------------------------------------------------
-- 回调函数
------------------------------------------------------------
function AH_Diamond.OnFrameCreate()
	InitFrameAutoPosInfo(this, 1, nil, nil, function() AH_Diamond.ClosePanel() end)
end

function AH_Diamond.OnLButtonClick()
	local frame, szName = this:GetRoot(), this:GetName()
	if szName == "Btn_Close" then
		AH_Diamond.ClosePanel()
	elseif szName == "Btn_Type1Level" then
		AH_Diamond.PopupDiamondLevel(frame, 1)
	elseif szName == "Btn_Type2Level" then
		AH_Diamond.PopupDiamondLevel(frame, 2)
	elseif szName == "Btn_Type1Attr1" then
		AH_Diamond.PopupDiamondAttribute(frame, 1, 1)
	elseif szName == "Btn_Type1Attr2" then
		AH_Diamond.PopupDiamondAttribute(frame, 1, 2)
	elseif szName == "Btn_Type1Attr3" then
		AH_Diamond.PopupDiamondAttribute(frame, 1, 3)
	elseif szName == "Btn_Type2Attr1" then
		AH_Diamond.PopupDiamondAttribute(frame, 2, 1)
	elseif szName == "Btn_Type2Attr2" then
		AH_Diamond.PopupDiamondAttribute(frame, 2, 2)
	elseif szName == "Btn_Type1Reset" then
		AH_Diamond.ResetAllOptions(frame, 1)
		AH_Diamond.Init(frame, 1)
	elseif szName == "Btn_Type2Reset" then
		AH_Diamond.ResetAllOptions(frame, 2)
		AH_Diamond.Init(frame, 2)
	elseif szName == "Btn_Type1Search" then
		AH_Diamond.SearchDiamond(frame, 1)
	elseif szName == "Btn_Type2Search" then
		AH_Diamond.SearchDiamond(frame, 2)
	end
end

function AH_Diamond.OnItemLButtonClick()
	local frame, szName = this:GetRoot(), this:GetName()
	if szName == "Box_Type1Item" or szName == "Box_Type2Item" then
		if not this:IsEmpty() then
			if IsCtrlKeyDown() then
				local _, dwVer, nTabType, nIndex = this:GetObjectData()
				EditBox_AppendLinkItemInfo(dwVer, nTabType, nIndex)
				return
			end
			if IsAuctionPanelOpened() then
				AH_Helper.UpdateList(this.szName, false)
			end
		end
	end
end

function AH_Diamond.OnItemMouseEnter()
	local frame, szName = this:GetRoot(), this:GetName()
	if szName == "Box_Type1Item" or szName == "Box_Type2Item" then
		if not this:IsEmpty() then
			this:SetObjectMouseOver(true)
			local _, dwVer, nTabType, nIndex = this:GetObjectData()
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			OutputItemTip(UI_OBJECT_ITEM_INFO, dwVer, nTabType, nIndex, {x, y, w, h})
		end
	end
end

function AH_Diamond.OnItemMouseLeave()
	local frame, szName = this:GetRoot(), this:GetName()
	if szName == "Box_Type1Item" or szName == "Box_Type2Item" then
		if not this:IsEmpty() then
			this:SetObjectMouseOver(false)
			HideTip()
		end
	end
end

function AH_Diamond.IsPanelOpened()
	local frame = Station.Lookup("Normal/AH_Diamond")
	if frame and frame:IsVisible() then
		return true
	end
	return false
end

function AH_Diamond.OpenPanel()
	local frame = nil
	if not AH_Diamond.IsPanelOpened()  then
		frame = Wnd.OpenWindow(szIniFile, "AH_Diamond")
		for nIndex = 1, 2 do
			AH_Diamond.Init(frame, nIndex)
		end
	else
		AH_Diamond.ClosePanel()
	end
	PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
end

function AH_Diamond.ClosePanel()
	if AH_Diamond.IsPanelOpened() then
		Wnd.CloseWindow("AH_Diamond")
	end
	PlaySound(SOUND.UI_SOUND,g_sound.CloseFrame)
end

RegisterEvent("LOGIN_GAME", function()
	TraceButton_AppendAddonMenu({{
		szOption = "五彩石助手",
		fnAction = function()
			AH_Diamond.OpenPanel()
		end,
	}})
end)


