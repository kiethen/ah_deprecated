------------------------------------------------------
-- #模块名：邮件仓库模块
-- #模块说明：增强邮件功能
------------------------------------------------------

AH_MailBank = {
	tItemCache = {},
	szDataPath = "\\Interface\\AH\\data\\mail.AH",
	szCurRole = nil,
	nCurIndex = 1,
	szCurKey = "",
	nFilterType = 1,
	bShowNoReturn = false,
	bMail = true,
}

local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber

local szIniFile = "Interface/AH/AH_MailBank.ini"
local bMailHooked = false
local bBagHooked = false
local tFilterType = {"物品名称", "信件标题", "寄信人", "到期时间"}

-- 将数据分页处理，每页98个数据，返回分页数据和页数
function AH_MailBank.GetPageMailData(tItemCache)
	local t, i, n = {}, 1, 1
	for k, v in pairs(tItemCache) do
		t[i] = t[i] or {}
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

	--附加数据
	local tItemCache = AH_MailBank.bShowNoReturn and AH_MailBank.SaveItemCache(false) or AH_MailBank.tItemCache[szName]
	local tCache, nMax = AH_MailBank.GetPageMailData(tItemCache)
	local i = 0
	for k, v in pairs(tCache[nIndex] or {}) do
		if k == "money" then	--金钱
			local box = hBox:Lookup(i)
			box.szType = "money"
			box.szName = "金钱"
			box.data = v
			box:SetObject(UI_OBJECT_NOT_NEED_KNOWN, 0)
			box:SetObjectIcon(582)
			box:SetAlpha(255)
			box:SetOverTextFontScheme(0, 15)
			box:SetOverText(0, "")
		else	--物品
			local box = hBox:Lookup(i)
			box.szType = "item"
			local item = GetItem(v[1])
			box.szName = k
			box.nUiId = v[7]
			box.data = v
			box:SetObject(UI_OBJECT_ITEM_ONLY_ID, v[7], v[1], v[2], v[3], v[4])
			box:SetObjectIcon(Table_GetItemIconID(v[7]))
			box:SetAlpha(255)
			box:SetOverTextFontScheme(0, 15)
			UpdateItemBoxExtend(box, item)
			if v[5] > 1 then
				box:SetOverText(0, v[5])
			else
				box:SetOverText(0, "")
			end
		end
		i = i + 1
	end
	--清空其余box
	for j = i, 97, 1 do
		local box = hBox:Lookup(j)
		if not box:IsEmpty() then
			box:ClearObject()
			box:ClearObjectIcon()
			box:SetOverText(0, "")
			box:SetAlpha(255)
			box:SetOverTextFontScheme(0, 15)
		end
	end

	frame:Lookup("", ""):Lookup("Text_Account"):SetText(szName)
	-- 翻页处理
	local hPrev, hNext = frame:Lookup("Btn_Prev"), frame:Lookup("Btn_Next")
	local hPage = frame:Lookup("", ""):Lookup("Text_Page")
	if nMax > 1 then
		hPrev:Show()
		hNext:Show()
		hPage:Show()
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
		hPage:SetText(string.format("%d/%d", nIndex, nMax))
	else
		hPrev:Hide()
		hNext:Hide()
		hPage:Hide()
	end
	--筛选处理
	frame:Lookup("", ""):Lookup("Text_Filter"):SetText(tFilterType[AH_MailBank.nFilterType])
	local hType = frame:Lookup("", ""):Lookup("Text_Type")
	if AH_MailBank.nFilterType == 4 then
		hType:SetText("少于(天)：")
	else
		hType:SetText("包含字符：")
	end
	frame:Lookup("Btn_Filter"):Enable(AH_MailBank.bMail)
	frame:Lookup("Check_NotReturn"):Enable(AH_MailBank.bMail)
	local tColor = AH_MailBank.bMail and {255, 255, 255} or {180, 180, 180}
	frame:Lookup("", ""):Lookup("Text_Filter"):SetFontColor(unpack(tColor))
	frame:Lookup("", ""):Lookup("Text_NotReturn"):SetFontColor(unpack(tColor))
end

-- 以邮件标题筛选
local function IsMailTitleExist(data, szKey)
	local MailClient = GetMailClient()
	for k, v in ipairs(data) do
		local mail = MailClient.GetMailInfo(v)
		if StringFindW(mail.szTitle, szKey) then
			return true
		end
	end
	return false
end

-- 以寄信人筛选
local function IsMailSenderNameExist(data, szKey)
	local MailClient = GetMailClient()
	for k, v in ipairs(data) do
		local mail = MailClient.GetMailInfo(v)
		if StringFindW(mail.szSenderName, szKey) then
			return true
		end
	end
	return false
end

-- 以剩余时间筛选
local function IsLessMailItemTime(data, szKey)
	local nLeft = 86400 * tonumber(szKey) or 0
	local MailClient = GetMailClient()
	for k, v in ipairs(data) do
		local mail = MailClient.GetMailInfo(v)
		if mail.GetLeftTime() < nLeft then
			return true
		end
	end
	return false
end

-- 过滤物品
function AH_MailBank.FilterMailItem(frame, szKey)
	local handle = frame:Lookup("", "")
	local hBox = handle:Lookup("Handle_Box")
	for i = 0, 97, 1 do
		local box = hBox:Lookup(i)
		if not box:IsEmpty() then
			local bExist = false
			if AH_MailBank.nFilterType == 1 then
				bExist = (StringFindW(box.szName, szKey) ~= nil)
			elseif AH_MailBank.nFilterType == 2 then
				bExist = IsMailTitleExist(box.data[6], szKey)
			elseif AH_MailBank.nFilterType == 3 then
				bExist = IsMailSenderNameExist(box.data[6], szKey)
			elseif AH_MailBank.nFilterType == 4 then
				bExist = IsLessMailItemTime(box.data[6], szKey)
			end
			if bExist then
				box:SetAlpha(255)
				box:SetOverTextFontScheme(0, 15)
			else
				box:SetAlpha(50)
				box:SetOverTextFontScheme(0, 30)
			end
		end
	end
end

-- 保存邮件物品数据，以物品nUiId为key的数据表，同种物品全部累加，每种物品包含所属邮件ID
function AH_MailBank.SaveItemCache(bAll)
	local MailClient = GetMailClient()
	local tMail = MailClient.GetMailList("all") or {}
	local t, count, ids, m = {}, {}, {}, 0
	for _, dwID in ipairs(tMail) do
		local mail = MailClient.GetMailInfo(dwID)
		if bAll or (not bAll and not (mail.GetType() == MAIL_TYPE.PLAYER and (mail.bMoneyFlag or mail.bItemFlag))) then
			local tItem = AH_MailBank.GetMailItem(mail)
			for k, v in pairs(tItem) do
				if not ids[k] then
					ids[k] = {dwID}
				else
					table.insert(ids[k], dwID)
				end
				if k == "money" then
					m = MoneyOptAdd(m, v)
					t["money"] = {m, ids["money"]}
				else
					count[k] = count[k] or 0
					if not t[k] then
						count[k] = v[5]
						t[k] = {v[1], v[2], v[3], v[4], v[5], ids[k], v[6]}
					else
						count[k] = count[k] + v[5]
						t[k] = {v[1], v[2], v[3], v[4], count[k], ids[k], v[6]}
					end
				end
			end
		end
	end
	return t
end

-- 获取单封右键的所有物品数据，包括金钱，同种物品做个数累加处理
function AH_MailBank.GetMailItem(mail)
	local t, count = {}, {}
	if mail.bItemFlag then
		for i = 0, 7, 1 do
			local item = mail.GetItem(i)
			if item then
				local szKey = GetItemNameByItem(item)
				local nStack = (item.bCanStack) and item.nStackNum or 1
				count[szKey] = count[szKey] or 0	--邮箱内同种物品计数器
				if not t[szKey] then
					count[szKey] = nStack
					t[szKey] = {item.dwID, item.nVersion, item.dwTabType, item.dwIndex, nStack, item.nUiId}
				else
					count[szKey] = count[szKey] + nStack
					t[szKey] = {item.dwID, item.nVersion, item.dwTabType, item.dwIndex, count[szKey], item.nUiId}
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
		if not bMailHooked then	--邮件界面添加一个按钮
			local page = frame:Lookup("PageSet_Total/Page_Receive")
			local temp = Wnd.OpenWindow("interface\\AH\\AH_Widget.ini")
			if not page:Lookup("Btn_MailBank") then
				local hBtnMailBank = temp:Lookup("Btn_MailBank")
				if hBtnMailBank then
					hBtnMailBank:ChangeRelation(page, true, true)
					hBtnMailBank:SetRelPos(600, 8)
					hBtnMailBank.OnLButtonClick = function()
						if not AH_MailBank.IsPanelOpened() then
							AH_MailBank.bMail = true
							AH_MailBank.nFilterType = 1
							AH_MailBank.OpenPanel()
						else
							AH_MailBank.ClosePanel()
						end
					end
				end
			end
			Wnd.CloseWindow(temp)
			bMailHooked = true
		end
		if GetLogicFrameCount() % 4 == 0 then
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
			AH_MailBank.tItemCache[szName] = AH_MailBank.SaveItemCache(true)
		end
	elseif not frame or not frame:IsVisible() then
		bMailHooked = false
	end

	local frame = Station.Lookup("Normal/BigBagPanel")
	if not bBagHooked and frame and frame:IsVisible() then --背包界面添加一个按钮
		local temp = Wnd.OpenWindow("interface\\AH\\AH_Widget.ini")
		if not frame:Lookup("Btn_Mail") then
			local hBtnMail = temp:Lookup("Btn_Mail")
			if hBtnMail then
				hBtnMail:ChangeRelation(frame, true, true)
				hBtnMail:SetRelPos(55, 0)
				hBtnMail.OnLButtonClick = function()
					if not AH_MailBank.IsPanelOpened() then
						AH_MailBank.bMail = false
						AH_MailBank.OpenPanel()
					else
						AH_MailBank.ClosePanel()
					end
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

-- 附件剩余时间格式化
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

-- 取附件
function AH_MailBank.TakeMailItemToBag(fnAction, nCount)
	local dwID, dwType = Target_GetTargetData()
	local hNpc = dwType == TARGET.NPC and GetNpc(dwID) or nil
	if not hNpc or (hNpc and not StringFindW(hNpc.szTitle, "信使")) then
		OutputMessage("MSG_SYS", "请选中信使再收件\n")
		return false
	end
	local tFreeBoxList = AH_Spliter.GetPlayerBagFreeBoxList()
	if nCount > #tFreeBoxList then
		OutputMessage("MSG_SYS", "背包空间不足\n")
		return false
	end
	fnAction()
	return true
end

--用于拾取物品后手动刷新列表
function  AH_MailBank.UpdateItemCache(szItemName, dwMailID, bDelete)
	local szName = GetClientPlayer().szName
	local tItemCache = AH_MailBank.tItemCache[szName]
	if bDelete then
		if tItemCache[szItemName] then
			tItemCache[szItemName] = nil
		end
	else
		local tMail = (szItemName == "money") and tItemCache[szItemName][2] or tItemCache[szItemName][6]
		if tMail then
			for k, v in ipairs(tMail) do
				if v == dwMailID then
					table.remove(tMail, k)
				end
			end
		end
		if not tMail or IsTableEmpty(tMail) then
			tItemCache[szItemName] = nil
		end
	end
end

-- 重新筛选
function AH_MailBank.ReFilter(frame)
	if AH_MailBank.szCurKey ~= "" then
		AH_MailBank.FilterMailItem(frame, AH_MailBank.szCurKey)
	end
end

-- 检查当前角色
function AH_MailBank.CheckCurRole(frame)
	AH_MailBank.nFilterType = 1
	frame:Lookup("", ""):Lookup("Text_Filter"):SetText(tFilterType[AH_MailBank.nFilterType])
	local bTrue = (AH_MailBank.szCurRole == GetClientPlayer().szName)
	frame:Lookup("Btn_Filter"):Enable(bTrue)
	frame:Lookup("Check_NotReturn"):Enable(bTrue)
end

------------------------------------------------------------
-- 回调函数
------------------------------------------------------------
function AH_MailBank.OnFrameCreate()
	local handle = this:Lookup("", "")
	local hBg = handle:Lookup("Handle_Bg")
	local hBox = handle:Lookup("Handle_Box")
	hBg:Clear()
	hBox:Clear()
	local nIndex = 0
	for i = 1, 7, 1 do
		for j = 1, 14, 1 do
			hBg:AppendItemFromString("<image>w=52 h=52 path=\"ui/Image/LootPanel/LootPanel.UITex\" frame=13 </image>")
			local img = hBg:Lookup(nIndex)
			hBox:AppendItemFromString("<box>w=48 h=48 eventid=304 </box>")
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
end

function AH_MailBank.OnEditChanged()
	local szName, frame = this:GetName(), this:GetRoot()
	if szName == "Edit_Search" then
		AH_MailBank.szCurKey = this:GetText()
		AH_MailBank.FilterMailItem(frame, AH_MailBank.szCurKey)
	end
end

function AH_MailBank.OnCheckBoxCheck()
	local szName, frame = this:GetName(), this:GetRoot()
	if szName == "Check_NotReturn" then
		AH_MailBank.bShowNoReturn = true
		AH_MailBank.LoadMailData(frame, AH_MailBank.szCurRole, AH_MailBank.nCurIndex)
		AH_MailBank.ReFilter(frame)
	end
end

function AH_MailBank.OnCheckBoxUncheck()
	local szName, frame = this:GetName(), this:GetRoot()
	if szName == "Check_NotReturn" then
		AH_MailBank.bShowNoReturn = false
		AH_MailBank.LoadMailData(frame, AH_MailBank.szCurRole, AH_MailBank.nCurIndex)
		AH_MailBank.ReFilter(frame)
	end
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
					AH_MailBank.ReFilter(frame)
					AH_MailBank.CheckCurRole(frame)
				end
			}
			table.insert(menu, m)
		end
		PopupMenu(menu)
	elseif szName == "Btn_Filter" then
		local hText = frame:Lookup("", ""):Lookup("Text_Filter")
		local x, y = hText:GetAbsPos()
		local w, h = hText:GetSize()
		local menu = {}
		menu.nMiniWidth = w + 20
		menu.x = x
		menu.y = y + h
		for k, v in ipairs(tFilterType) do
			local m = {
				szOption = v,
				fnAction = function()
					hText:SetText(v)
					AH_MailBank.nFilterType = k
					local hType = frame:Lookup("", ""):Lookup("Text_Type")
					if k == 4 then
						hType:SetText("少于(天)：")
					else
						hType:SetText("包含字符：")
					end
					AH_MailBank.ReFilter(frame)
				end
			}
			table.insert(menu, m)
		end
		PopupMenu(menu)
	elseif szName == "Btn_Setting" then
		local menu = {}
		for k, v in pairs(AH_MailBank.tItemCache) do
			local m = {
				szOption = k,
				{
					szOption = "删除",
					fnAction = function()
						AH_MailBank.tItemCache[k] = nil
						--AH_MailBank.LoadMailData(frame, AH_MailBank.szCurRole, AH_MailBank.nCurIndex)
					end
				}
			}
			table.insert(menu, m)
		end
		PopupMenu(menu)
	elseif szName == "Btn_Prev" then
		AH_MailBank.nCurIndex = AH_MailBank.nCurIndex - 1
		AH_MailBank.LoadMailData(frame, AH_MailBank.szCurRole, AH_MailBank.nCurIndex)
		AH_MailBank.ReFilter(frame)
	elseif szName == "Btn_Next" then
		AH_MailBank.nCurIndex = AH_MailBank.nCurIndex + 1
		AH_MailBank.LoadMailData(frame, AH_MailBank.szCurRole, AH_MailBank.nCurIndex)
		AH_MailBank.ReFilter(frame)
	elseif szName == "Btn_Refresh" then
		AH_MailBank.LoadMailData(frame, AH_MailBank.szCurRole, AH_MailBank.nCurIndex)
		AH_MailBank.ReFilter(frame)
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
		local bSuccess = false
		if this.szType == "item" then
			local item = GetItem(data[1])
			if item then
				local MailClient = GetMailClient()
				for k, v in ipairs(data[6]) do
					local mail = MailClient.GetMailInfo(v)
					if mail.bItemFlag then
						for i = 0, 7, 1 do
							local item2 = mail.GetItem(i)
							if item2 and item2.nUiId == this.nUiId then
								bSuccess = AH_MailBank.TakeMailItemToBag(function() mail.TakeItem(i) end, math.ceil(data[5] / item.nMaxStackNum))
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
					bSuccess = AH_MailBank.TakeMailItemToBag(function() mail.TakeMoney() end, 0)
				end
			end
		end
		if bSuccess then
			this:ClearObject()
			this:ClearObjectIcon()
			this:SetOverText(0, "")
			AH_MailBank.UpdateItemCache(this.szName, nil, true)
		end
	end
end

function AH_MailBank.OnItemRButtonClick()
	local szName, frame = this:GetName(), this:GetRoot()
	if not this.bItemBox then
		return
	end
	this:SetObjectMouseOver(1)
	local box = this
	if not this:IsEmpty() then
		local data = this.data
		if this.szType == "item" then
			local bSuccess = false
			local item = GetItem(data[1])
			if item then
				local menu = {}
				local MailClient = GetMailClient()
				for k, v in ipairs(data[6]) do
					local mail = MailClient.GetMailInfo(v)
					if mail.bItemFlag then
						local nUiId = this.nUiId
						local m = {
							szOption = string.format(" %s『%s』", mail.szSenderName, mail.szTitle),
							szIcon = "UI\\Image\\UICommon\\CommonPanel2.UITex",
							nFrame = 105,
							nMouseOverFrame = 106,
							szLayer = "ICON_LEFT",
							fnClickIcon = function()
								for i = 0, 7, 1 do
									local item2 = mail.GetItem(i)
									if item2 and item2.nUiId == nUiId then
										local nStack = (item.bCanStack) and item.nStackNum or 1
										bSuccess = AH_MailBank.TakeMailItemToBag(function() mail.TakeItem(i) end, nStack / item.nMaxStackNum)
										if bSuccess then
											data[5] = data[5] - nStack
											--将取走附件的邮件删除
											for kk, vv in ipairs(data[6]) do
												if vv == v then
													table.remove(data[6], kk)
												end
											end
											--相应的更改box数字
											if data[5] > 1 then
												box:SetOverText(0, data[5])
											elseif data[5] == 1 then
												box:SetOverText(0, "")
											else
												box:ClearObject()
												box:ClearObjectIcon()
												box:SetOverText(0, "")
											end
											AH_MailBank.UpdateItemCache(GetItemNameByItem(item2), v)
										end
									end
								end
							end,
						}
						for i = 0, 7, 1 do
							local item2 = mail.GetItem(i)
							if item2 and item2.nUiId == nUiId then
								local nStack = (item2.bCanStack) and item2.nStackNum or 1
								local m_1 = {
									szOption = string.format("%s x%d", GetItemNameByItem(item2), nStack),
									fnAction = function()
										bSuccess = AH_MailBank.TakeMailItemToBag(function() mail.TakeItem(i) end, 1)
										if bSuccess then
											data[5] = data[5] - nStack
											--将取走附件的邮件删除
											for kk, vv in ipairs(data[6]) do
												if vv == v then
													table.remove(data[6], kk)
												end
											end
											--相应的更改box数字
											if data[5] > 1 then
												box:SetOverText(0, data[5])
											elseif data[5] == 1 then
												box:SetOverText(0, "")
											else
												box:ClearObject()
												box:ClearObjectIcon()
												box:SetOverText(0, "")
											end
											AH_MailBank.UpdateItemCache(GetItemNameByItem(item2), v)
										end
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
			local bSuccess = false
			local MailClient = GetMailClient()
			for k, v in ipairs(data[2]) do
				local mail = MailClient.GetMailInfo(v)
				if mail.bMoneyFlag then
					local m = {
						szOption = string.format("%s『%s』", mail.szSenderName, mail.szTitle),
						{
							szOption = GetMoneyPureText(mail.nMoney),
							fnAction = function()
								bSuccess = AH_MailBank.TakeMailItemToBag(function() mail.TakeMoney() end, 0)
								if bSuccess then
									data[1] = MoneyOptSub(data[1], mail.nMoney)
									--将取走金钱的那封邮件删除
									for kk, vv in ipairs(data[2]) do
										if vv == v then
											table.remove(data[2], kk)
										end
									end
									--Output(data[1])
									if MoneyOptCmp(data[1], 0) == 0 then
										box:ClearObject()
										box:ClearObjectIcon()
										box:SetOverText(0, "")
									end
									AH_MailBank.UpdateItemCache("money", v)
								end
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
					local szName = GetItemNameByItem(item)
					local szTip = "<Text>text=" .. EncodeComponentsString(szName) .. " font=60" .. GetItemFontColorByQuality(item.nQuality, true) .. " </text>"
					szTip = szTip .. GetFormatText("\n<ALT键显示物品信息，左键点击全部拾取，右键点击分件拾取>", 165)
					local MailClient = GetMailClient()
					for k, v in ipairs(data[6]) do
						local mail = MailClient.GetMailInfo(v)
						szTip = szTip .. GetFormatText(string.format("\n\n%s", mail.szSenderName), 164)
						szTip = szTip .. GetFormatText(string.format(" 『%s』\n", mail.szTitle), 163)
						local szLeft = AH_MailBank.FormatItemLeftTime(mail.GetLeftTime())
						szTip = szTip .. GetFormatText(string.format("剩余时间：%s", szLeft), 162)
						local nCount = AH_MailBank.GetMailItem(mail)[szName][5]
						szTip = szTip .. GetFormatText(string.format("  数量：%d", nCount), 162)
					end
					OutputTip(szTip, 300, {x, y, w, h})
				else
					local szTip = GetFormatText(this.szName, 162)
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
				szTip = szTip .. GetFormatText(string.format("剩余时间：%s ", szLeft), 162)
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
	local frame = Station.Lookup("Normal/AH_MailBank")
	if not frame then
		frame = Wnd.OpenWindow(szIniFile, "AH_MailBank")
	end
	frame:Show()
	frame:BringToTop()
	AH_MailBank.szCurRole = GetClientPlayer().szName
	if not AH_MailBank.tItemCache[AH_MailBank.szCurRole] then
		AH_MailBank.tItemCache[AH_MailBank.szCurRole] = {}
	end
	AH_MailBank.LoadMailData(frame, AH_MailBank.szCurRole, AH_MailBank.nCurIndex)
	PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
end

function AH_MailBank.ClosePanel()
	local frame = Station.Lookup("Normal/AH_MailBank")
	if frame and frame:IsVisible() then
		frame:Hide()
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
