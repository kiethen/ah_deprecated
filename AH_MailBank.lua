------------------------------------------------------
-- #模块名：邮件仓库模块
-- #模块说明：增强邮件功能
------------------------------------------------------

AH_MailBank = {
	tItemCache = {},
	szDataPath = "\\Interface\\AH\\data\\mail.AH",
	szCurRole = nil,
	nCurIndex = 1,
}

local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber

local szIniFile = "Interface/AH/AH_MailBank.ini"
local bMailHooked = false
local bBagHooked = false

-- UI初始化
function AH_MailBank.Init(frame)
	local handle = frame:Lookup("", "")
	local hBg = handle:Lookup("Handle_Bg")
	local hBox = handle:Lookup("Handle_Box")
	hBg:Clear()
	hBox:Clear()
	local nIndex = 0
	for i = 1, 7, 1 do
		for j = 1, 14, 1 do
			hBg:AppendItemFromString("<image>w=52 h=52 path=\"ui/Image/LootPanel/LootPanel.UITex\" frame=13 </image>")
			local img = hBg:Lookup(nIndex)
			hBox:AppendItemFromString("<box>w=48 h=48 eventid=524607 </box>")
			local box = hBox:Lookup(nIndex)
			box.nIndex = nIndex
			box.bItemBox = true
			local x, y = (j - 1) * 52, (i - 1) * 52
			img:SetRelPos(x, y)
			box:SetRelPos(x + 2, y + 2)
			box:SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
			box:SetOverTextFontScheme(0, 15)

			nIndex = nIndex + 1
		end
	end
	hBg:FormatAllItemPos()
	hBox:FormatAllItemPos()

	frame:Lookup("Btn_Prev"):Hide()
	frame:Lookup("Btn_Next"):Hide()
end

-- 将数据分页处理，每页98个数据，返回分页数据和页数
function AH_MailBank.GetPageMailData(szName)
	local tItemCache = AH_MailBank.tItemCache[szName]
	local t, i, n = {}, 1, 1
	for k, v in pairs(tItemCache) do
		if not t[i] then
			t[i] = {}
		end
		t[i][k] = v
		n = n + 1
		i = math.ceil(n / 98)
	end
	return t, i
end

-- 按页加载该角色的物品数据
function AH_MailBank.LoadMailData(frame, szName, nIndex)
	local handle = frame:Lookup("", "")
	local hBox = handle:Lookup("Handle_Box")
	--清除原有数据
	for i = 0, 97, 1 do
		local box = hBox:Lookup(i)
		box:ClearObject()
		box:ClearObjectIcon()
		box:SetOverText(0, "")
	end

	--重新附加数据
	local tItemCache, nMax = AH_MailBank.GetPageMailData(szName)
	local i = 0
	for k, v in pairs(tItemCache[nIndex]) do
		if type(k) == "number" then		--物品
			local box = hBox:Lookup(i)
			box.szType = "item"
			box.nUiId = k
			box.data = v
			box:SetObject(UI_OBJECT_ITEM_ONLY_ID, k, v[1], v[2], v[3], v[4])
			box:SetObjectIcon(Table_GetItemIconID(k))
			local item = GetItem(v[1])
			if item then
				UpdateItemBoxExtend(box, item)
			end
			if v[5] > 1 then
				box:SetOverText(0, v[5])
			else
				box:SetOverText(0, "")
			end
		elseif type(k) == "string" and k == "money" then	--金钱
			local box = hBox:Lookup(i)
			box.szType = "money"
			box.data = v
			box:SetObject(UI_OBJECT_NOT_NEED_KNOWN, 0)
			box:SetObjectIcon(582)
		end
		i = i + 1
	end
	frame:Lookup("", ""):Lookup("Text_Account"):SetText(szName)
	local hPrev, hNext = frame:Lookup("Btn_Prev"), frame:Lookup("Btn_Next")
	if nMax > 1 then
		hPrev:Show()
		hNext:Show()
		if nIndex == 1 then
			hPrev:Enable(false)
			hNext:Enable(true)
		elseif nIndex == nMax then
			hPrev:Enable(true)
			hNext:Enable(false)
		else
			hPrev:Enable(true)
			hNext:Enable(true)
		end
	else
		hPrev:Hide()
		hNext:Hide()
	end
	frame:Lookup("", ""):Lookup("Text_Page"):SetText(string.format("%d/%d", nIndex, nMax))
end

-- 保存邮件物品数据，以物品nUiId为key的数据表，同种物品全部累加，每种物品包含所属邮件ID
function AH_MailBank.SaveItemCache()
	local MailClient = GetMailClient()
	local tMail = MailClient.GetMailList("all") or {}
	local t, count, ids, m = {}, {}, {}, 0
	for _, dwID in ipairs(tMail) do
		local tItem = AH_MailBank.GetMailItem(dwID)
		for k, v in pairs(tItem) do
			if type(k) == "number" then
				if not count[k] then
					count[k]= 0
				end
				if not ids[k] then
					ids[k] = {dwID}
				else
					table.insert(ids[k], dwID)
				end
				if not t[k] then
					count[k] = v[5]
					t[k] = {v[1], v[2], v[3], v[4], v[5], ids[k]}
				else
					count[k] = count[k] + v[5]
					t[k] = {v[1], v[2], v[3], v[4], count[k], ids[k]}
				end
			elseif type(k) == "string" and k == "money" then
				if not ids["money"] then
					ids["money"] = {dwID}
				else
					table.insert(ids["money"], dwID)
				end
				m = MoneyOptAdd(m, v)
				t["money"] = {m, ids["money"]}
			end
		end
	end
	return t
end

-- 获取单封右键的所有物品数据，包括金钱，同种物品做个数累加处理
function AH_MailBank.GetMailItem(dwID)
	local t, count = {}, {}
	local mail = GetMailClient().GetMailInfo(dwID)
	if mail.bItemFlag then
		for i = 0, 7, 1 do
			local item = mail.GetItem(i)
			if item then
				if not count[item.nUiId] then
					count[item.nUiId] = 0	--邮箱内同种物品计数器
				end
				if not t[item.nUiId] then
					count[item.nUiId] = item.nStackNum
					t[item.nUiId] = {item.dwID, item.nVersion, item.dwTabType, item.dwIndex, item.nStackNum}
				else
					count[item.nUiId] = count[item.nUiId] + item.nStackNum
					t[item.nUiId] = {item.dwID, item.nVersion, item.dwTabType, item.dwIndex, count[item.nUiId]}
				end
			end
		end
	end
	if mail.bMoneyFlag and mail.nMoney ~= 0 then
		t["money"] = mail.nMoney
	end
	return t
end

function AH_MailBank.OnUpdate()
	local frame = Station.Lookup("Normal/MailPanel")
	if frame and frame:IsVisible() then
		if not bMailHooked then
			local page = frame:Lookup("PageSet_Total/Page_Receive")
			local temp = Wnd.OpenWindow("interface\\AH\\AH_Widget.ini")
			if not page:Lookup("Btn_MailBank") then
				local hBtnMailBank = temp:Lookup("Btn_MailBank")
				if hBtnMailBank then
					hBtnMailBank:ChangeRelation(page, true, true)
					hBtnMailBank:SetRelPos(600, 8)
					hBtnMailBank.OnLButtonClick = function()
						AH_MailBank.OpenPanel()
					end
				end
			end
			Wnd.CloseWindow(temp)
			bMailHooked = true
		end
		local MailClient = GetMailClient()
		local tMail = MailClient.GetMailList("all") or {}
		for _, dwID in ipairs(tMail) do
			local mail = MailClient.GetMailInfo(dwID)
			local target = Station.Lookup("Normal/Target")
			if target then
				mail.RequestContent(target.dwID)
			end
		end
		local szName = GetClientPlayer().szName
		AH_MailBank.tItemCache[szName] = AH_MailBank.SaveItemCache()
	elseif not frame or not frame:IsVisible() then
		bMailHooked = false
	end

	local frame = Station.Lookup("Normal/BigBagPanel")
	if not bBagHooked and frame and frame:IsVisible() then
		local temp = Wnd.OpenWindow("interface\\AH\\AH_Widget.ini")
		if not frame:Lookup("Btn_Mail") then
			local hBtnMail = temp:Lookup("Btn_Mail")
			if hBtnMail then
				hBtnMail:ChangeRelation(frame, true, true)
				hBtnMail:SetRelPos(55, 0)
				hBtnMail.OnLButtonClick = function()
					AH_MailBank.OpenPanel()
				end
				hBtnMail.OnMouseEnter = function()
					local x, y = this:GetAbsPos()
					local w, h = this:GetSize()
					local szTip = GetFormatText("邮件仓库", 163) .. GetFormatText("\n单击这里可以打开离线邮件仓库。", 162)
					OutputTip(szTip, 400, {x, y, w, h})
				end
				hBtnMail.OnMouseLeave = function()
					HideTip()
				end
			end
		end
		Wnd.CloseWindow(temp)
		bBagHooked = true
	elseif not frame or not frame:IsVisible() then
		bBagHooked = false
	end
end

function AH_MailBank.FormatItemLeftTime(nTime)
	if nTime >= 86400 then
		return FormatString(g_tStrings.STR_MAIL_LEFT_DAY, math.floor(nTime / 86400))
	elseif nTime >= 3600 then
		return FormatString(g_tStrings.STR_MAIL_LEFT_HOURE, math.floor(nTime / 3600))
	elseif nTime >= 60 then
		return FormatString(g_tStrings.STR_MAIL_LEFT_MINUTE, math.floor(nTime / 60))
	else
		return g_tStrings.STR_MAIL_LEFT_LESS_ONE_M
	end
end

function AH_MailBank.FormatMailMoney(nMoney)
	local tMoney = FormatMoneyTab(nMoney)
	local szMoney = ""
	if tMoney["nGold"] and tMoney["nGold"] > 0 then
		szMoney = szMoney .. tMoney["nGold"] .. "金 "
	end
	if tMoney["nSilver"] and tMoney["nSilver"] > 0 then
		szMoney = szMoney .. tMoney["nSilver"] .. "银 "
	end
	if tMoney["nCopper"] and tMoney["nCopper"] > 0 then
		szMoney = szMoney .. tMoney["nCopper"] .. "铜"
	end
	return szMoney
end

function AH_MailBank.TakeMailItemToBag(fnAction, nCount)
	local tFreeBoxList = AH_Spliter.GetPlayerBagFreeBoxList()
	if nCount > #tFreeBoxList then
		OutputMessage("MSG_SYS", "背包空间不足\n")
		return
	end
	fnAction()
end
------------------------------------------------------------
-- 回调函数
------------------------------------------------------------
function AH_MailBank.OnEditChanged()
end

function AH_MailBank.OnLButtonClick()
	local szName, frame = this:GetName(), this:GetRoot()
	if szName == "Btn_Close" then
		AH_MailBank.ClosePanel()
	elseif szName == "Btn_Account" then
		local hText = frame:Lookup("", ""):Lookup("Text_Account")
		local x, y = hText:GetAbsPos()
		local w, h = hText:GetSize()
		local menu = {}
		menu.nMiniWidth = w + 20
		menu.x = x
		menu.y = y + h
		for k, v in pairs(AH_MailBank.tItemCache) do
			local m = {
				szOption = k,
				fnAction = function()
					AH_MailBank.szCurRole = k
					AH_MailBank.LoadMailData(frame, k, 1)
				end
			}
			table.insert(menu, m)
		end
		PopupMenu(menu)
	elseif szName == "Btn_Prev" then
		AH_MailBank.nCurIndex = AH_MailBank.nCurIndex - 1
		AH_MailBank.LoadMailData(frame, AH_MailBank.szCurRole, AH_MailBank.nCurIndex)
	elseif szName == "Btn_Next" then
		AH_MailBank.nCurIndex = AH_MailBank.nCurIndex + 1
		AH_MailBank.LoadMailData(frame, AH_MailBank.szCurRole, AH_MailBank.nCurIndex)
	elseif szName == "Btn_Refresh" then
		AH_MailBank.LoadMailData(frame, AH_MailBank.szCurRole, AH_MailBank.nCurIndex)
	end
end

function AH_MailBank.OnItemLButtonClick()
	local szName, frame = this:GetName(), this:GetRoot()
	if not this.bItemBox then
		return
	end
	this:SetObjectMouseOver(1)

	if not this:IsEmpty() then
		local data = this.data
		if this.szType == "item" then
			local item = GetItem(data[1])
			if item then
				local MailClient = GetMailClient()
				for k, v in ipairs(data[6]) do
					local mail = MailClient.GetMailInfo(v)
					if mail.bItemFlag then
						for i = 0, 7, 1 do
							local item2 = mail.GetItem(i)
							if item2 then
								AH_MailBank.TakeMailItemToBag(mail.TakeItem(i), math.ceil(data[5] / item.nMaxStackNum))
							end
						end
					end
				end
			end
		elseif this.szType == "money" then
			local MailClient = GetMailClient()
			for k, v in ipairs(data[2]) do
				local mail = MailClient.GetMailInfo(v)
				if mail.bMoneyFlag then
					mail.TakeMoney()
				end
			end
		end
	end
	AH_Library.DelayCall(0.5, function()
		AH_MailBank.LoadMailData(frame, AH_MailBank.szCurRole, AH_MailBank.nCurIndex)
	end)
end

function AH_MailBank.OnItemRButtonClick()
	local szName, frame = this:GetName(), this:GetRoot()
	if not this.bItemBox then
		return
	end
	this:SetObjectMouseOver(1)

	if not this:IsEmpty() then
		local data = this.data
		if this.szType == "item" then
			local item = GetItem(data[1])
			if item then
				local menu = {}
				local MailClient = GetMailClient()
				for k, v in ipairs(data[6]) do
					local mail = MailClient.GetMailInfo(v)
					if mail.bItemFlag then
						local m = {szOption = string.format("%s『%s』", mail.szSenderName, mail.szTitle)}
						for i = 0, 7, 1 do
							local item2 = mail.GetItem(i)
							if item2 and item2.nUiId == this.nUiId then
								local m_1 = {
									szOption = string.format("%s x%d", item2.szName, item2.nStackNum),
									fnAction = function()
										AH_MailBank.TakeMailItemToBag(mail.TakeItem(i), 1)
										AH_Library.DelayCall(0.5, function()
											AH_MailBank.LoadMailData(frame, AH_MailBank.szCurRole, AH_MailBank.nCurIndex)
										end)
									end
								}
								table.insert(m, m_1)
							end
						end
						table.insert(menu, m)
					end
				end
				PopupMenu(menu)
			end
		elseif this.szType == "money" then
			local menu = {}
			local MailClient = GetMailClient()
			for k, v in ipairs(data[2]) do
				local mail = MailClient.GetMailInfo(v)
				if mail.bMoneyFlag then
					local m = {
						szOption = string.format("%s『%s』", mail.szSenderName, mail.szTitle),
						{
							szOption = AH_MailBank.FormatMailMoney(mail.nMoney),
							fnAction = function()
								mail.TakeMoney()
								AH_Library.DelayCall(0.5, function()
									AH_MailBank.LoadMailData(frame, AH_MailBank.szCurRole, AH_MailBank.nCurIndex)
								end)
							end
						}
					}
					table.insert(menu, m)
				end
			end
			PopupMenu(menu)
		end
	end
end

function AH_MailBank.OnItemMouseEnter()
	local szName = this:GetName()
	if not this.bItemBox then
		return
	end
	this:SetObjectMouseOver(1)

	if not this:IsEmpty() then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local data = this.data
		if this.szType == "item" then
			if IsAltKeyDown() then
				local _, dwID = this:GetObjectData()
				OutputItemTip(UI_OBJECT_ITEM_ONLY_ID, dwID, nil, nil, {x, y, w, h})
			else
				local item = GetItem(data[1])
				if item then
					local szTip = "<Text>text=" .. EncodeComponentsString(item.szName) .. " font=60" .. GetItemFontColorByQuality(item.nQuality, true) .. " </text>"
					szTip = szTip .. GetFormatText("\n<ALT键显示物品信息，左键点击全部拾取，右键点击分件拾取>", 165)
					local MailClient = GetMailClient()
					for k, v in ipairs(data[6]) do
						local mail = MailClient.GetMailInfo(v)
						szTip = szTip .. GetFormatText(string.format("\n\n%s", mail.szSenderName), 164)
						szTip = szTip .. GetFormatText(string.format(" 『%s』\n", mail.szTitle), 163)
						local szLeft = AH_MailBank.FormatItemLeftTime(mail.GetLeftTime())
						szTip = szTip .. GetFormatText(string.format("剩余时间：%s", szLeft), 162)
						local nCount = AH_MailBank.GetMailItem(v)[this.nUiId][5]
						szTip = szTip .. GetFormatText(string.format("  数量：%d", nCount), 162)
					end
					OutputTip(szTip, 300, {x, y, w, h})
				else
					local szTip = GetFormatText(Table_GetItemName(this.nUiId), 162)
					OutputTip(szTip, 300, {x, y, w, h})
				end
			end
		elseif this.szType == "money" then
			local szTip = GetFormatText(g_tStrings.STR_MAIL_HAVE_MONEY, 101) .. GetMoneyTipText(data[1], 106)
			local MailClient = GetMailClient()
			for k, v in ipairs(data[2]) do
				local mail = MailClient.GetMailInfo(v)
				szTip = szTip .. GetFormatText(string.format("\n\n%s", mail.szSenderName), 164)
				szTip = szTip .. GetFormatText(string.format(" 『%s』\n", mail.szTitle), 163)
				local szLeft = AH_MailBank.FormatItemLeftTime(mail.GetLeftTime())
				szTip = szTip .. GetFormatText(string.format("剩余时间：%s", szLeft), 162)
				szTip = szTip .. GetFormatText(g_tStrings.STR_MAIL_HAVE_MONEY, 162) .. GetMoneyTipText(mail.nMoney, 106)
			end
			OutputTip(szTip, 300, {x, y, w, h})
		end
	end
end

function AH_MailBank.OnItemMouseLeave()
	local szName = this:GetName()
	if not this.bItemBox then
		return
	end

	this:SetObjectMouseOver(0)
	HideTip()
end

function AH_MailBank.IsPanelOpened()
	local frame = Station.Lookup("Normal/AH_MailBank")
	if frame and frame:IsVisible() then
		return true
	end
	return false
end

function AH_MailBank.OpenPanel()
	local frame = nil
	if not AH_MailBank.IsPanelOpened()  then
		frame = Wnd.OpenWindow(szIniFile, "AH_MailBank")
		AH_MailBank.Init(frame)
		AH_MailBank.szCurRole = GetClientPlayer().szName
		AH_MailBank.LoadMailData(frame, AH_MailBank.szCurRole, AH_MailBank.nCurIndex)
	else
		AH_MailBank.ClosePanel()
	end
	PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
end

function AH_MailBank.ClosePanel()
	if AH_MailBank.IsPanelOpened() then
		Wnd.CloseWindow("AH_MailBank")
	end
	PlaySound(SOUND.UI_SOUND,g_sound.CloseFrame)
end

RegisterEvent("LOGIN_GAME", function()
	if IsFileExist(AH_MailBank.szDataPath) then
		AH_MailBank.tItemCache = LoadLUAData(AH_MailBank.szDataPath)
	end
end)

RegisterEvent("GAME_EXIT", function()
	SaveLUAData(AH_MailBank.szDataPath, AH_MailBank.tItemCache)
end)

RegisterEvent("PLAYER_EXIT_GAME", function()
	SaveLUAData(AH_MailBank.szDataPath, AH_MailBank.tItemCache)
end)

AH_Library.RegisterBreatheEvent("ON_AH_MAILBANK_UPDATE", AH_MailBank.OnUpdate)
