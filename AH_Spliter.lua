AHSpliter = AHSpliter or {}

function AHSpliter.OnFrameCreate()
	this:RegisterEvent("UI_SCALED")
end

function AHSpliter.OnEvent(event)
	if event == "UI_SCALED" then
		if this.rect then
			this:CorrectPos(this.rect[1], this.rect[2], this.rect[3], this.rect[4], ALW.CENTER)
		else
			this:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
		end
	end
end

function AHSpliter.IsOpened()
	local frame = Station.Lookup("Topmost/AHSpliter")
	if frame and frame:IsVisible() then
		return true
	end
	return false
end

function AHSpliter.Open(rect)
	if AHSpliter.IsOpened() then
		return
	end
	Wnd.OpenWindow("AHSpliter")
	local frame = Station.Lookup("Topmost/AHSpliter")
	if not frame then
		frame = Wnd.OpenWindow("Interface\\AHHelper\\AHSpliter.ini", "AHSpliter")
	end
	frame:Show()
	frame:BringToTop()

	frame:Lookup("Edit_Group"):SetText("1")
	frame:Lookup("Edit_Num"):SetText("1")

	frame.rect = rect
	if rect then
		frame:CorrectPos(rect[1], rect[2], rect[3], rect[4], ALW.CENTER)
	else
		frame:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
	end
	PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
end


function AHSpliter.Close()
	if not AHSpliter.IsOpened() then
		return
	end
	Wnd.CloseWindow("AHSpliter")
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

function AHSpliter.OnLButtonClick()
	local szName = this:GetName()
	if szName == "Btn_Split" then
		AHSpliter.Split(this:GetParent())
    	return
    elseif szName == "Btn_Close" then
    	AHSpliter.Close()
		AHSpliter.ClearBox(this:GetParent():Lookup("", ""):Lookup("Box_Item"))
    	return
	end
end

function AHSpliter.OnSetFocus()
  	local szName = this:GetName()
  	if szName == "Edit_Group" then
		local szText = this:GetText()
		if szText == "1" then
			this:SetText("")
		else
			this:SelectAll()
		end
	elseif szName == "Edit_Num" then
		local szText = this:GetText()
		if szText == "1" then
			this:SetText("")
		else
			this:SelectAll()
		end
  	end
end

function AHSpliter.OnKillFocus()
	local szName = this:GetName()
	if szName == "Edit_Group" then
		local szText = this:GetText()
		if not szText or szText == "" then
			this:SetText("1")
		end
	elseif szName == "Edit_Num" then
		local szText = this:GetText()
		if not szText or szText == "" then
			this:SetText("1")
		end
  	end
end


function AHSpliter.StackItem()
	AHHelper.Message("开始堆叠物品")
	local player = GetClientPlayer()
	local tBoxTable = {}
	for i = 1, 6 do
		for j = 0, player.GetBoxSize(i) - 1 do
			local itemLoop =player.GetItem(i,j)
			if itemLoop then
				local szName = itemLoop.szName
				if szName then
					local nStackNum = itemLoop.nStackNum
					local nMaxStackNum = itemLoop.nMaxStackNum
					if nStackNum ~= nMaxStackNum then
						tBoxTable[szName] = tBoxTable[szName] or {}
						table.insert(tBoxTable[szName], {dwBox =i, dwX = j, bCanStack = itemLoop.bCanStack, nStackNum = nStackNum, nMaxStackNum = nMaxStackNum, dwTabType = itemLoop.dwTabType, dwIndex = itemLoop.dwIndex})
					end
				end
			end
		end
	end
	for szName, tTypeBoxTable in pairs(tBoxTable) do
		local tTidyBoxTemp = tBoxTable[szName]
		for i = 1, #tTidyBoxTemp do
			for j = #tTidyBoxTemp, i+1, -1 do
				local item1 = tTidyBoxTemp[i]
				local item2 = tTidyBoxTemp[j]
				if item1.bCanStack and item1.nStackNum ~= item1.nMaxStackNum and item2.nStackNum > 0 and item1.dwTabType == item2.dwTabType and item1.dwIndex == item2.dwIndex then
					local nStackNumtotal = item1.nStackNum + item2.nStackNum
					if nStackNumtotal<=item1.nMaxStackNum then
						tTidyBoxTemp[i].nStackNum = nStackNumtotal
						tTidyBoxTemp[j].nStackNum = 0
					else
						tTidyBoxTemp[j].nStackNum = nStackNumtotal - item1.nMaxStackNum
						tTidyBoxTemp[i].nStackNum = item1.nMaxStackNum
					end
					OnExchangeItem(tTidyBoxTemp[j].dwBox, tTidyBoxTemp[j].dwX, tTidyBoxTemp[i].dwBox, tTidyBoxTemp[i].dwX)
				end
			end
		end
	end
	AHHelper.Message("堆叠物品结束")
end

function AHSpliter.Split(frame)
	local hGroup = frame:Lookup("Edit_Group")
    local hNum = frame:Lookup("Edit_Num")
    local hBox = frame:Lookup("", "Box_Item")

	local nGroup = tonumber(hGroup:GetText())
	local nNum = tonumber(hNum:GetText())

	local player = GetClientPlayer()

	if not GetPlayerItem(player, hBox.dwBox, hBox.dwX) then
		AHHelper.Message("找不到物品")
		return
	end

	if hBox.nCount < nGroup * nNum or nGroup * nNum == 0 then
       AHHelper.Message("请输入正确的组数或个数")
        return
    end

	local tFreeBoxList = AHSpliter.GetPlayerBagFreeBoxList()
	if #tFreeBoxList < nGroup then
		AHHelper.Message("背包空间不足\n")
		return
	end

	AHHelper.Message("开始拆分物品")
	for i = 1, nGroup do
		local dwBox, dwX = tFreeBoxList[i][1], tFreeBoxList[i][2]
		player.ExchangeItem(hBox.dwBox, hBox.dwX, dwBox, dwX, nNum)
	end
	AHHelper.Message("拆分物品结束")
	Wnd.CloseWindow("AHSpliter")
end

function AHSpliter.GetPlayerBagFreeBoxList()
	local player = GetClientPlayer()
	local tBoxTable = {}
	for nIndex = 6, 1, -1 do
		local dwBox = INVENTORY_INDEX.PACKAGE + nIndex - 1
		local dwSize = player.GetBoxSize(dwBox)
		if dwSize > 0 then
			for dwX = dwSize, 1, -1 do
				local item = player.GetItem(dwBox, dwX - 1)
				if not item then
					local i, j = dwBox, dwX - 1
					table.insert(tBoxTable, {i, j})
				end
			end
		end
	end
	return tBoxTable
end

function AHSpliter.OnExchangeBoxItem(boxItem, boxDsc, nHandCount, bHand)
	if not boxItem or not boxDsc then
		return
	end

	local nSourceType = boxDsc:GetObjectType()
	local _, dwBox1, dwX1 = boxDsc:GetObjectData()
	local player = GetClientPlayer()

	if nSourceType ~= UI_OBJECT_ITEM or (not dwBox1 or dwBox1 < INVENTORY_INDEX.PACKAGE or dwBox1 > INVENTORY_INDEX.PACKAGE4) then
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_ERROR_ITEM_CANNOT_SPLIT)
		AHSpliter.PlayTipSound("002")
		return
	end

	local item = GetPlayerItem(player, dwBox1, dwX1)
	if not item then
		return
	end

	local itemInfo = GetItemInfo(item.dwTabType, item.dwIndex)

	local nCount = 1
	if item.bCanStack then
		nCount = item.nStackNum
	end

	if nCount < 2 then
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_ERROR_ITEM_CANNOT_SPLIT)
		AHSpliter.PlayTipSound("002")
		return
	end

	if nHandCount and nHandCount ~= nCount then
		OutputMessage("MSG_ANNOUNCE_RED", "请把拆开的物品放进背包后再拆分\n")
		return
	end

	boxItem.szName = item.szName
	boxItem.dwBox = dwBox1
	boxItem.dwX   = dwX1
	boxItem.nCount = nCount

	UpdataItemBoxObject(boxItem, boxItem.dwBox, boxItem.dwX, item)
	if bHand then
		Hand_Clear()
	end
end

function AHSpliter.OnItemLButtonClick()
	local szName = this:GetName()
	if szName == "Box_Item" then
		if Hand_IsEmpty() then
			if not this:IsEmpty() then
				if IsCursorInExclusiveMode() then
					OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.SRT_ERROR_CANCEL_CURSOR_STATE)
				else
					Hand_Pick(this)
					AHSpliter.ClearBox(this)
				end
				HideTip()
			end
		else
			local boxHand, nHandCount = Hand_Get()
			AHSpliter.OnExchangeBoxItem(this, boxHand, nHandCount, true)
		end
	end
end

function AHSpliter.OnItemRButtonClick()
	local szName = this:GetName()
	if szName == "Box_Item" then
		if not this:IsEmpty() then
			AHSpliter.ClearBox(this)
		end
	end
end

function AHSpliter.OnItemLButtonUp()
	local szName = this:GetName()
	if szName == "Box_Item" then
		this:SetObjectPressed(0)
	end
end

function AHSpliter.OnItemLButtonDown()
	local szName = this:GetName()
	if szName == "Box_Item" then
		this:SetObjectStaring(false)
		this:SetObjectPressed(1)
	end
end

function AHSpliter.OnItemMouseEnter()
	this:SetObjectMouseOver(1)
	local szName = this:GetName()
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	if szName == "Box_Item" then
		if this:IsEmpty() then
			local szText = "<text>text=\"\将需要拆分的物品放入其中\" font=18</text>"
			OutputTip(szText, 400, {x, y ,w, h})
		else
			local _, dwBox, dwX = this:GetObjectData()
			OutputItemTip(UI_OBJECT_ITEM, dwBox, dwX, nil, {x, y, w, h})
		end
	end
end

function AHSpliter.OnItemMouseLeave()
	this:SetObjectMouseOver(0)
	local szName = this:GetName()
	if szName == "Box_Item" then
		HideTip()
	end
end

function AHSpliter.OnItemLButtonDragEnd()
	this.bIgnoreClick = true
	if not Hand_IsEmpty() then
		local boxHand, nHandCount = Hand_Get()
		AHSpliter.OnExchangeBoxItem(this, boxHand, nHandCount, true)
	end
end

function AHSpliter.OnItemLButtonDrag()
	this:SetObjectPressed(0)
	if Hand_IsEmpty() then
		if not this:IsEmpty() then
			if IsCursorInExclusiveMode() then
				OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.SRT_ERROR_CANCEL_CURSOR_STATE)
			else
				Hand_Pick(this)
				AHSpliter.ClearBox(this)
			end
		end
	end
end

function AHSpliter.ClearBox(hBox)
	hBox.dwBox = nil
	hBox.dwX = nil
	hBox.szName = nil
	hBox:ClearObject()
	hBox:SetOverText(0, "")
end

function AHSpliter.PlayTipSound(szSound)
	local szFile = "ui\\sound\\female\\"..szSound..".wav"
	PlaySound(SOUND.UI_SOUND, szFile)
end

Wnd.OpenWindow("Interface\\AHHelper\\AHSpliter.ini", "AHSpliter"):Hide()
Hotkey.AddBinding("AHSpliter_Open", "拆分物品", "交易行助手", function() AHSpliter.Open() end, nil)
Hotkey.AddBinding("AHSpliter_StackItem", "堆叠物品", "", function() AHSpliter.StackItem() end, nil)
