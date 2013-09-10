------------------------------------------------------
-- #模块名：技艺助手模块
-- #模块说明：增强交易行、生活技艺搜索以及制造功能
------------------------------------------------------

AH_Produce = {
	nProfessionID = 0,

	nMakeCount = 0,
	nMakeCraftID  = 0,
	nMakeRecipeID = 0,

	nSubMakeCount = 0,
	nSubMakeCraftID  = 0,
	nSubMakeRecipeID = 0,

	bIsMaking = false,
	bSub = false,
	bIsSearch = false,

	nCurCraftID = -1,
	nCurRecipeID = -1,
}

local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber

local szIniFile = "Interface/AH/AH_Produce.ini"
local tRecipeSkill = {{"全部", 0}, {"烹饪", 4}, {"缝纫", 5}, {"铸造", 6}, {"医术", 7}}
local EXPAND_ITEM_TYPE = {}

-- 分类，为了生成有序的表得用这种结构
local tSearchSort = {
	[1] = {
		szType = "附魔",
		tSubSort = {
			"力道","根骨","元气","身法","属性","体质",
			"无双","御劲","化劲","仇恨","移动速度","治疗成效",
			"外功攻击","外功命中","外功破防","外功会效",
			"内功攻击","内功命中","内功破防","内功会效",
		},
	},
	[2] = {
		szType = "钥匙",
		tSubSort = {
			"青铜钥匙","锡制钥匙","精铁钥匙",
		},
	},
	[3] = {
		szType = "包包",
		tSubSort = {
			"挂件包·背部","挂件包·腰部","轻容百花包","蜀染布包","天工锦缎皮包",
			"绫罗皮包","彩锦皮包","梨绒落绢包","碧床落花绒包",
		},
	},
	[4] = {
		szType = "挂件",
		tSubSort = {
			"哈哈哈"
		},
	},
	[5] = {
		szType = "药品增强",
		tSubSort = {
			"拆招","防御","威胁值","攻击力","外功攻击","外功命中","外功会心","外功会效",
			"内功攻击","内功伤害","内功命中","内功会心","内功会效","疗伤成效",
		},
	},
	[6] = {
		szType = "药品辅助",
		tSubSort = {
			"力道","根骨","元气","身法","属性","体质","拆招",
			"外功破防","外功会效","内功破防","内功会效","疗伤成效",
		},
	},
	[7] = {
		szType = "烹饪增强",
		tSubSort = {
			"命中","闪避","拆招","防御","威胁值","攻击力",
			"外功攻击","外功破防","外功会效","内功攻击",
			"内功伤害","内功破防","内功会效","疗伤成效",
		},
	},
	[8] = {
		szType = "烹饪辅助",
		tSubSort = {
			"力道","根骨","元气","身法","属性","体质",
		},
	},
	[9] = {
		szType = "精力体力",
		tSubSort = {
			"毛血旺","麻辣毛血旺","麻辣血肠","好逑汤","剁椒肉爪","佳·回元餐",
			"蒜泥白肉","白肉血肠","冬瓜排骨汤","银丝卷","椒麻口条","佳·转神餐",
			"枸杞瘦肉","血丸子","和合腰子",
		},
	},
}

------------------------------------------------------------
-- 功能函数
------------------------------------------------------------
function AH_Produce:Init(frame)
	self.nProfessionID = 0
	self.bIsSearch = false
	self.bSub = false
	self.bCoolDown = false

	self.nMakeCount = 0
	self.nMakeCraftID  = 0
	self.nMakeRecipeID = 0

	self.nSubMakeCount = 0
	self.nSubMakeCraftID  = 0
	self.nSubMakeRecipeID = 0

	EXPAND_ITEM_TYPE = {}

	self:UpdateItemTypeList(frame)
	self:UpdateList(frame)
end

function AH_Produce:ForamtCoolDownTime(nTime)
	local szText = ""
	local nH, nM, nS = GetTimeToHourMinuteSecond(nTime, true)
	if nH and nH > 0 then
		if (nM and nM > 0) or (nS and nS > 0) then
			nH = nH + 1
		end
		szText = szText .. nH .. g_tStrings.STR_BUFF_H_TIME_H
	else
		nM = nM or 0
		nS = nS or 0
		if nM == 0 and nS == 0 then
			return szText
		end
		if nM > 0 and nS > 0 then
			nM = nM + 1
		end
		if nM >= 60 then
			szText = szText .. math.ceil(nM / 60) .. g_tStrings.STR_BUFF_H_TIME_H
		elseif nM > 0 then
			szText = szText .. nM .. g_tStrings.STR_BUFF_H_TIME_M
		else
			szText = szText .. nS .. g_tStrings.STR_BUFF_H_TIME_S
		end
	end
	return szText
end

function AH_Produce:GetRecipeTotalCount(recipe)
	local nTotalCount = 9999999
	for nIndex = 1, 6, 1 do
		if recipe["dwRequireItemCount" .. nIndex] ~= 0 then
			local nCurrentCount = GetClientPlayer().GetItemAmount(recipe["dwRequireItemType" .. nIndex], recipe["dwRequireItemIndex" .. nIndex])
			local nCount = math.floor(nCurrentCount / recipe["dwRequireItemCount" .. nIndex])
			if nCount < nTotalCount then
				nTotalCount = nCount
			end
		end
	end
	if nTotalCount == 9999999 then
		nTotalCount = 0
	end
	return nTotalCount
end

function AH_Produce:GetDescByItemName(szName, nProID)
	if nProID ~= 0 then
		local szDesc = AH_Data.EnchantData[nProID][szName]
		if szDesc then
			return szDesc
		end
	else
		for k, v in ipairs({4, 5, 6, 7}) do
			szDesc = AH_Data.EnchantData[v][szName]
			if szDesc then
				return szDesc
			end
		end
	end
	return ""
end

function AH_Produce:GetRecipeByItemName(szName)
	for k, v in pairs(AH_Library.tMergeRecipe) do
		local szRecipeName, nCraftID, nRecipeID = unpack(v)
		if szRecipeName == szName then
			return {nCraftID, nRecipeID}
		end
	end
	return nil
end

function AH_Produce:IsSpecialMaterial(nType, nID)
	if nType == 5 and nID == 3333 then
		return true
	end
	return false
end

function AH_Produce:ProcessKeywords(szName, szKey)
	szKey = string.gsub(szKey, "^%s*(.-)%s*$", "%1")
	szKey = string.gsub(szKey, "[%[%]]", "")
	local tKeys = SplitString(szKey, " ")
	for k, v in ipairs(tKeys) do
		if not StringFindW(szName, v) then
			return false
		end
	end
	return true
end

function AH_Produce:UpdateList(frame, szKey)
	local hList = frame:Lookup("Wnd_List", "")
	local player = GetClientPlayer()
	local bExist = false
	local bSel = false
	local nProID = self.nProfessionID
	hList:Clear()
	local tRecipe = nil
	if nProID < 0 then	--原料搜索配方
		for _, k in ipairs({4, 5, 6, 7}) do
			if self.bIsSearch then
				tRecipe = AH_Library.tMaterialALL[k][szKey]
				if not IsTableEmpty(tRecipe) then
					bExist = true
					for _, v in ipairs(tRecipe) do
						local recipe = GetRecipe(v[1], v[2])
						local nType = recipe.dwCreateItemType1
						local nID	= recipe.dwCreateItemIndex1
						local tInfo = GetItemInfo(nType, nID)
						local hItem = hList:AppendItemFromIni(szIniFile, "TreeLeaf_Search")

						hItem.szName = GetItemNameByItemInfo(tInfo)
						hItem.bItem = true
						hItem.nID	= nID
						hItem.nType = nType
						hItem.tInfo = tInfo
						hItem.nCraftID = v[1]
						hItem.nRecipeID = v[2]
						hItem.nTotalCount = self:GetRecipeTotalCount(recipe)

						local hText  = hItem:Lookup("Text_FoodNameS")
						local hImage = hItem:Lookup("Image_FoodS")
						local szText = hItem.szName
						local szLearn = ""
						if not player.IsRecipeLearned(v[1], v[2]) then
							szLearn = szLearn .. " [未学]"
						end

						szText = szText .. szLearn
						if hItem.nTotalCount ~= 0 then
							szText = szText .. " " .. hItem.nTotalCount
						end

						hText:SetText(szText)
						hText:SetFontColor(GetItemFontColorByQuality(hItem.tInfo.nQuality, false))
						hImage:Hide()
					end
				end
			end
		end
	else	--配方搜索成品
		if nProID ~= 0 then
			tRecipe = AH_Library.tRecipeALL[nProID]
		else
			tRecipe = AH_Library.tMergeRecipe
		end
		if tRecipe then
			for k, v in pairs(tRecipe) do
				local szRecipeName, nCraftID, nRecipeID = unpack(v)
				local recipe = GetRecipe(nCraftID, nRecipeID)
				local nType = recipe.dwCreateItemType1
				local nID	= recipe.dwCreateItemIndex1
				local tInfo = GetItemInfo(nType, nID)
				if self.bIsSearch then
					local szDesc = self:GetDescByItemName(tInfo.szName, nProID)
					local szSearch = szRecipeName .." " .. szDesc
					if self:ProcessKeywords(szSearch, szKey) then
						bExist = true
						local hItem = hList:AppendItemFromIni(szIniFile, "TreeLeaf_Search")

						hItem.szName = szRecipeName
						hItem.bItem = true
						hItem.nID	= nID
						hItem.nType = nType
						hItem.tInfo = tInfo
						hItem.nCraftID = nCraftID
						hItem.nRecipeID = nRecipeID
						hItem.nTotalCount = self:GetRecipeTotalCount(recipe)

						local hText  = hItem:Lookup("Text_FoodNameS")
						local hImage = hItem:Lookup("Image_FoodS")
						local szText = szRecipeName
						local szLearn = ""
						if not player.IsRecipeLearned(nCraftID, nRecipeID) then
							szLearn = szLearn .. " [未学]"
						end

						szText = szText .. szLearn
						if hItem.nTotalCount ~= 0 then
							szText = szText .. " " .. hItem.nTotalCount
						end

						hText:SetText(szText)
						hText:SetFontColor(GetItemFontColorByQuality(hItem.tInfo.nQuality, false))
						hImage:Hide()

						if hItem.nCraftID == self.nCurCraftID and hItem.nRecipeID == self.nCurRecipeID then
							bSel = true
							self:Selected(frame, hItem)
							self:UpdateContent(frame)
						end
					end
				end
			end
		end
	end

	if not bSel then
		self:Selected(frame, nil)
	end
	if self.bIsSearch then
		if not bExist then
			local hItem = hList:AppendItemFromIni(szIniFile, "TreeLeaf_Search")
			hItem:Lookup("Text_FoodNameS"):SetText(g_tStrings.STR_MSG_NOT_FIND_LIST)
			hItem:Lookup("Text_FoodNameS"):SetFontScheme(162)
			hItem:Lookup("Image_FoodS"):Hide()
		else
			hList:Sort()
		end
	end

	hList:Show()
	AH_Produce.OnUpdateScorllList(hList)
end

function AH_Produce:UpdateContent(frame)
	local hWnd = frame:Lookup("Wnd_Content")
	local hMaterial = hWnd:Lookup("", "")

	local nCurProID = self.nCurCraftID
	local nCurCraftID = self.nCurCraftID
	local nCurRecipeID = self.nCurRecipeID
	local recipe  = GetRecipe(nCurCraftID, nCurRecipeID)
	local bSatisfy = true
	local szProName = Table_GetProfessionName(nCurCraftID)

	hMaterial:Clear()

	local hItem    = hMaterial:AppendItemFromIni(szIniFile, "Handle_Item")
	local hRequire = hMaterial:AppendItemFromIni(szIniFile, "Handle_RequireP")
	local hBox     = hItem:Lookup("Box_Item")
	local hText    = hItem:Lookup("Text_Item")

	if recipe.nCraftType == ALL_CRAFT_TYPE.ENCHANT then
		hBox.bEnchant = true
		local szName = Table_GetEnchantName(nCurProID, nCurCraftID, nCurRecipeID)
		local nIconID = Table_GetEnchantIconID(nCurProID, nCurCraftID, nCurRecipeID)
		local nQuality = Table_GetEnchantQuality(nCurProID, nCurCraftID, nCurRecipeID)

		hText:SetText(szName)
		hText:SetFontColor(GetItemFontColorByQuality(nQuality, false))

		hBox:SetObject(UI_OBJECT_ITEM_INFO, nCurProID, nCurCraftID, nCurRecipeID)
		hBox:SetObjectIcon(nIconID)
		UpdateItemBoxExtend(hBox, nil, nQuality)
		hBox:SetOverText(0, "")
	else
		hBox.bProduct = true
		local nType = recipe.dwCreateItemType1
		local nID	= recipe.dwCreateItemIndex1

		local ItemInfo = GetItemInfo(nType, nID)
		local nMin  = recipe.dwCreateItemMinCount1
		local nMax  = recipe.dwCreateItemMaxCount1

		local szRecipeName = ItemInfo.szName
		hText:SetText(szRecipeName)
		hText:SetFontColor(GetItemFontColorByQuality(ItemInfo.nQuality, false))

		hBox:SetObject(UI_OBJECT_ITEM_INFO, ItemInfo.nUiId, GLOBAL.CURRENT_ITEM_VERSION, nType, nID)
		hBox:SetObjectIcon(Table_GetItemIconID(ItemInfo.nUiId))
		UpdateItemBoxExtend(hBox, ItemInfo)
		hBox:SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
		hBox:SetOverTextFontScheme(0, 15)

		if nMax == nMin then
			if nMin ~= 1 then
				hBox:SetOverText(0, nMin)
			else
				hBox:SetOverText(0, "")
			end
		else
			hBox:SetOverText(0, nMin .. "-" .. nMax)
		end
	end

	local player = GetClientPlayer()
	local szText, nFont = "", 162

	hRequire:Clear()

	szText = szText .. GetFormatText(g_tStrings.NEED, 162)
	--Tool
	local bComma = false
	if recipe.dwToolItemType ~= 0 and recipe.dwToolItemIndex ~= 0 then
		local ItemInfo   = GetItemInfo(recipe.dwToolItemType, recipe.dwToolItemIndex)
		local nToolCount = player.GetItemAmount(recipe.dwToolItemType, recipe.dwToolItemIndex)
		local nPowerfulToolCount = player.GetItemAmount(recipe.dwPowerfulToolItemType, recipe.dwPowerfulToolItemIndex)
		local pItemInfo = GetItemInfo(recipe.dwPowerfulToolItemType, recipe.dwPowerfulToolItemIndex)

		nFont = 162
		if nToolCount <= 0 and nPowerfulToolCount <= 0 then
			nFont = 102
		end
		local szItemName = GetItemNameByItemInfo(ItemInfo)
		szText = szText .. GetFormatText(szItemName, nFont)
		if pItemInfo then
			local szItemName2 = GetItemNameByItemInfo(pItemInfo)
			szText = szText .. GetFormatText(g_tStrings.STR_OR .. szItemName2, nFont)
		end
		bComma = true
	end
	--Stamina
	nFont = 162
	if player.nCurrentStamina < recipe.nStamina then
		nFont = 102
	end
	if bComma then
		szText = szText .. GetFormatText("，", 162)
	end
	szText = szText .. GetFormatText(FormatString(g_tStrings.CRAFT_COST_STAMINA_BLANK, recipe.nStamina), nFont)

	--Doodad
	if recipe.dwRequireDoodadID ~= 0 then
		local doodadTamplate = GetDoodadTemplate(recipe.dwRequireDoodadID)
		if doodadTamplate then
			local szName = Table_GetDoodadTemplateName(doodadTamplate.dwTemplateID)
			szText = szText .. GetFormatText("，" .. szName, 162)
		end
	end
	--技艺要求
	local szCraftText = FormatString("需要技艺：<D0> <D1>", szProName, FormatString(g_tStrings.STR_FRIEND_WTHAT_LEVEL1, recipe.dwRequireProfessionLevel))
	local nFont = 162
	local nMaxLevel    = player.GetProfessionMaxLevel(nCurProID)
    local nLevel       = player.GetProfessionLevel(nCurProID)
    local nAdjustLevel = player.GetProfessionAdjustLevel(nCurProID) or 0

    nLevel = math.min((nLevel + nAdjustLevel), nMaxLevel)
	if recipe.dwRequireProfessionLevel > nLevel then
		nFont = 102
	end
	szText = szText .. GetFormatText("，", 162) .. GetFormatText(szCraftText, nFont)

	--冷却时间
	self.bCoolDown = false
	self.szCoolDownTime = nil

	if recipe.dwCoolDownID and recipe.dwCoolDownID > 0 then
		local szTimeText = ""
		local CDTotalTime  = player.GetCDInterval(recipe.dwCoolDownID)
		local CDRemainTime = player.GetCDLeft(recipe.dwCoolDownID)

		self.bCoolDown = true
		if CDRemainTime <= 0 then
			local szTime = self:ForamtCoolDownTime(CDTotalTime)
			szTimeText = g_tStrings.TIME_CD .. szTime
		else
			local szTime = self:ForamtCoolDownTime(CDRemainTime)
			if not szTime or szTime == "" then
				CDRemainTime = 0
				local szTime = self:ForamtCoolDownTime(CDTotalTime)
				szTimeText = g_tStrings.TIME_CD .. szTime
			else
				self.szCoolDownTime = szTime
				szTimeText = g_tStrings.TIME_CD1 .. szTime
			end
		end

		local nFont = 162
		if CDRemainTime ~= 0 then
			nFont = 102
			bSatisfy = false
		end
		szText = szText .. GetFormatText("，"..szTimeText, nFont)
	end

	hWnd:Show()
	hRequire:Show()
	hRequire:AppendItemFromString(szText)
	hRequire:FormatAllItemPos()
	hRequire:SetSizeByAllItemSize()

	local nMW = hMaterial:GetSize()
	local _, nRH = hRequire:GetSize()
	hRequire:SetSize(nMW, nRH)

	hItem:FormatAllItemPos()

	if self.nCurTotalCount <= 0 then
		bSatisfy = false
	end
	self:SetBtnStatus(frame, recipe.nCraftType, bSatisfy)
	self:UpdateMakeCount(frame)

	hMaterial:FormatAllItemPos()
end

function AH_Produce:UpdateInfo(frame)
	local hList = frame:Lookup("Wnd_List", "")
	local player = GetClientPlayer()
	local nCount = hList:GetItemCount() - 1
	local bSel = false
	for i = 0, nCount, 1 do
		local hItem = hList:Lookup(i)
		local hText  = hItem:Lookup("Text_FoodNameS")
		local hImage = hItem:Lookup("Image_FoodS")
		local szText = hItem.szName

		local szLearn = ""
		if not player.IsRecipeLearned(hItem.nCraftID, hItem.nRecipeID) then
			szLearn = szLearn .. " [未学]"
		end
		szText = szText .. szLearn
		local recipe = GetRecipe(hItem.nCraftID, hItem.nRecipeID)
		local nTotalCount = self:GetRecipeTotalCount(recipe)
		if nTotalCount ~= 0 then
			szText = szText .. " " .. nTotalCount
		end
		hItem.nTotalCount = nTotalCount
		hText:SetText(szText)

		if not hItem.bSel then
			hText:SetFontColor(GetItemFontColorByQuality(hItem.tInfo.nQuality, false))
			hImage:Hide()
		end

		if hItem.nCraftID == self.nCurCraftID and hItem.nRecipeID == self.nCurRecipeID then
			bSel = true
			self:Selected(frame, hItem)
			self:UpdateContent(frame)
		end
	end
	if not bSel then
		self:Selected(frame, nil)
	end
	self:UpdateMakeCount(frame)
end

function AH_Produce:UpdateBgStatus(hItem)
	if not hItem then
		return
	end
	local img = nil
	local szName = hItem:GetName()
	--Output(szName)
	if szName == "Handle_ListContent" then
		img = hItem:Lookup("Image_SearchListCover")
	elseif szName == "Handle_List01" then
		img = hItem:Lookup("Image_SearchListCover01")
	else
		img  = hItem:Lookup("Image_FoodS")
	end
	if not img then
		return
	end
	if hItem.bSel then
		--img:FromUITex("ui/Image/Common/TextShadow.UITex", 0)
		img:Show()
		img:SetAlpha(255)
	elseif hItem.bOver then
		--img:FromUITex("ui/Image/Common/TextShadow.UITex", 0)
		img:Show()
		img:SetAlpha(128)
	else
		img:Hide()
	end
end

function AH_Produce:SetBtnStatus(frame, nCraftType, bEnable)
	local hText = frame:Lookup("Btn_Make", "Text_Make")
	if nCraftType == ALL_CRAFT_TYPE.ENCHANT then
		frame:Lookup("", "Image_NumFrame"):Hide()
		frame:Lookup("Edit_Number"):Hide()
		frame:Lookup("Btn_MakeAll"):Hide()
		frame:Lookup("Btn_Add"):Hide()
		frame:Lookup("Btn_Del"):Hide()
		hText:SetText(g_tStrings.STR_CRAFT_BOOK_SPECIAL_MAKE_BUTTON_TEXT)
	else
		frame:Lookup("", "Image_NumFrame"):Show()
		frame:Lookup("Edit_Number"):Show()
		frame:Lookup("Btn_MakeAll"):Show()
		frame:Lookup("Btn_Add"):Show()
		frame:Lookup("Btn_Del"):Show()
		frame:Lookup("Btn_MakeAll"):Enable(bEnable)
		hText:SetText(g_tStrings.STR_CRAFT_BOOK_NORMAL_MAKE_BUTTON_TEXT)
	end
	frame:Lookup("Btn_Make"):Enable(bEnable)
	local editNum = frame:Lookup("Edit_Number")
	if bEnable then
		hText:SetFontScheme(162)
		local szText = editNum:GetText()
		if szText == "" then
			editNum:SetText(1)
		end
	else
		hText:SetFontScheme(161)
		editNum:SetText(0)
	end
	if self.nCurRecipeID == 0 then
		frame:Lookup("Edit_Number"):SetText("")
	end
end

function AH_Produce:IsOnMakeRecipe()
	if self.nMakeCraftID == 0 or self.nMakeRecipeID == 0 then
	   return nil
	end
	if self.nMakeCraftID == self.nCurCraftID and self.nMakeRecipeID == self.nCurRecipeID then
		return true
	end
	return nil
end

function AH_Produce:UpdateMakeCount(frame, nDelta)
	if self.nCurRecipeID == 0 then
		frame:Lookup("Btn_Del"):Enable(false)
		frame:Lookup("Btn_Add"):Enable(false)
		frame:Lookup("Edit_Number"):SetText("")
		return
	end
	if not nDelta then
		nDelta = 0
	end
	local hEdit = frame:Lookup("Edit_Number")
	local szCount = hEdit:GetText()
	local nCount  = 0
	local nValue  = 0
	if self:IsOnMakeRecipe() and nDelta == 0 then
		nCount = self.nMakeCount
	else
		if szCount == "" then
			szCount = 0
		end
		nCount = tonumber(szCount)
	end
	nCount = nCount + nDelta
	nValue = nCount
	frame:Lookup("Btn_Del"):Enable(true)
	frame:Lookup("Btn_Add"):Enable(true)
	if nCount <= 0 then
		nValue = 0
		frame:Lookup("Btn_Del"):Enable(false)
	end
	local nTotCount  = 0
	if self.nCurTotalCount > 0 then
		nTotCount = self.nCurTotalCount
	end
	if nCount >= nTotCount then
		nValue = nTotCount
		frame:Lookup("Btn_Add"):Enable(false)
	end
	hEdit:SetText(nValue)
end

function AH_Produce:SetMakeInfo(frame, bAll)
	if bAll then
		self.nMakeCount = self.nCurTotalCount
	else
		local szCount = frame:Lookup("Edit_Number"):GetText()
		if szCount == "" then
			self.nMakeCount = 0
		else
			self.nMakeCount = tonumber(szCount)
		end
		if self.nMakeCount > self.nCurTotalCount then
			self.nMakeCount = self.nCurTotalCount
		end
	end
	self.nMakeCraftID = self.nCurCraftID
	self.nMakeRecipeID = self.nCurRecipeID
	self:UpdateMakeCount(frame)
end

function AH_Produce:ClearMakeInfo()
	if self.bSub then
		self.nSubMakeCount, self.nSubMakeCraftID, self.nSubMakeRecipeID = 0, 0, 0
	else
		self.nMakeCount, self.nMakeCraftID, self.nMakeRecipeID = 0, 0, 0
	end
end

function AH_Produce:OnMakeRecipe()
	local nCount, nCraftID, nRecipeID = 0, 0, 0
	if self.bSub then
		nCount, nCraftID, nRecipeID = self.nSubMakeCount, self.nSubMakeCraftID, self.nSubMakeRecipeID
	else
		nCount, nCraftID, nRecipeID = self.nMakeCount, self.nMakeCraftID, self.nMakeRecipeID
	end
	if nCount > 0 then
		GetClientPlayer().CastProfessionSkill(nCraftID, nRecipeID)
	else
		self:ClearMakeInfo()
	end
end

function AH_Produce:OnCastProfessionSkill(nCraftID, nRecipeID, nSubMakeCount)
	self.bSub = true
	if IsShiftKeyDown() then
		GetUserInputNumber(nSubMakeCount, nSubMakeCount, nil,
			function(nCount)
				self.nSubMakeCraftID, self.nSubMakeRecipeID, self.nSubMakeCount = nCraftID, nRecipeID, nCount
				self:OnMakeRecipe()
			end, nil, nil
		)
	else
		self.nSubMakeCraftID, self.nSubMakeRecipeID, self.nSubMakeCount = nCraftID, nRecipeID, 1
		self:OnMakeRecipe()
	end
end

function AH_Produce:OnEnchantItem()
	local fnAction = function(dwTargetBox, dwTargetX)
		local item = GetPlayerItem(GetClientPlayer(), dwTargetBox, dwTargetX)
		if item then
			GetClientPlayer().CastProfessionSkill(self.nMakeCraftID, self.nMakeRecipeID, TARGET.ITEM, item.dwID)
		end
	end
	local fnCancel = function()
		return
	end
	local fnCondition = function(dwTargetBox, dwTargetX)
		local item   = GetPlayerItem(GetClientPlayer(), dwTargetBox, dwTargetX)
		local recipe = GetRecipe(self.nMakeCraftID, self.nMakeRecipeID)
		if not item then
			return false
		end
		if not recipe then
			return false
		end

		return true
	end
	UserSelect.SelectItem(fnAction, fnCancel, fnCondition, nil)
end

function AH_Produce:Selected(frame, hItem)
	if hItem then
		local hList = hItem:GetParent()
		local nCount = hList:GetItemCount() - 1
		for i = 0, nCount, 1 do
			local hI = hList:Lookup(i)
			if hI.bSel then
				hI.bSel = false
				hI:Lookup("Image_FoodS"):Hide()
				hI:Lookup("Text_FoodNameS"):SetFontColor(GetItemFontColorByQuality(hI.tInfo.nQuality, false))
			end
		end

		hItem.bSel = true
		self.nCurCraftID  = hItem.nCraftID
		self.nCurRecipeID = hItem.nRecipeID
		self.nCurTotalCount = hItem.nTotalCount

		if hItem.nTotalCount > 0 then
			frame:Lookup("Edit_Number"):SetText(1)
		else
			frame:Lookup("Edit_Number"):SetText(0)
		end

		self:UpdateBgStatus(hItem)
	else
		self.nCurCraftID  = -1
		self.nCurRecipeID = -1

		frame:Lookup("Wnd_Content"):Hide()
		frame:Lookup("Btn_MakeAll"):Enable(false)
		frame:Lookup("Btn_Make"):Enable(false)
	end
end

-- 左侧分类
function AH_Produce:UpdateItemTypeList(frame)
	local hListLv1 = frame:Lookup("Wnd_Search", "")
	hListLv1:Clear()
	for _, v in ipairs(tSearchSort) do
		local hListLv2 = hListLv1:AppendItemFromIni(szIniFile, "Handle_ListContent")
		local imgBg1 = hListLv2:Lookup("Image_SearchListBg1")
		local imgBg2 = hListLv2:Lookup("Image_SearchListBg2")
		local imgCover = hListLv2:Lookup("Image_SearchListCover")
		local imgMin = hListLv2:Lookup("Image_Minimize")

		if EXPAND_ITEM_TYPE.szType == v.szType then
			hListLv2.bSel = true
			local hListLv3 = hListLv2:Lookup("Handle_Items")
	    	local w, h = self:AddItemSubTypeList(hListLv3, v.tSubSort or {})
	    	imgBg1:Hide()
	    	imgBg2:Show()
	    	imgCover:Show()
	    	imgMin:SetFrame(8)

	    	local wB, _ = imgBg2:GetSize()
	    	imgBg2:SetSize(wB, h + 50)

	    	local wL, _ = hListLv2:GetSize()
	    	hListLv2:SetSize(wL, h + 50)
	    else
	    	imgBg1:Show()
	    	imgBg2:Hide()
	    	imgCover:Hide()
	    	imgMin:SetFrame(12)
	    	imgBg2:SetSize(0, 0)

	    	local w, h = imgBg1:GetSize()
	    	hListLv2:SetSize(w, h)
	    end
		hListLv2:Lookup("Text_ListTitle"):SetText(v.szType)
	end
	self:OnUpdateItemTypeList(hListLv1)
end

function AH_Produce:AddItemSubTypeList(hList, tSubType)
	for _, v in ipairs(tSubType) do
		local hItem = hList:AppendItemFromIni(szIniFile, "Handle_List01")
		local imgCover =  hItem:Lookup("Image_SearchListCover01")
		if EXPAND_ITEM_TYPE.szSubType == v then
			hItem.bSel = true
			imgCover:Show()
		else
			imgCover:Hide()
		end
		hItem:Lookup("Text_List01"):SetText(v)
	end
	hList:Show()
	hList:FormatAllItemPos()
	hList:SetSizeByAllItemSize()
	return hList:GetSize()
end

function AH_Produce:OnUpdateItemTypeList(hList)
	hList:FormatAllItemPos()
	local hWnd = hList:GetParent()
	local scroll = hWnd:Lookup("Scroll_Search")
	local w, h = hList:GetSize()
	local wAll, hAll = hList:GetAllItemSize()
	local nStepCount = math.ceil((hAll - h) / 10)

	scroll:SetStepCount(nStepCount)
	if nStepCount > 0 then
		scroll:Show()
		hWnd:Lookup("Btn_SUp"):Show()
		hWnd:Lookup("Btn_SDown"):Show()
	else
		scroll:Hide()
		hWnd:Lookup("Btn_SUp"):Hide()
		hWnd:Lookup("Btn_SDown"):Hide()
	end
end

function AH_Produce:OnSearch(frame)
	local szKey = frame:Lookup("Edit_Search"):GetText()
	if not szKey or szKey == "" then
		if self.bIsSearch then
			self.bIsSearch = false
			self:Selected(frame, nil)
			self:UpdateList(frame)
		end
	else
		self.bIsSearch = true
		self:Selected(frame, nil)
		self:UpdateList(frame, szKey)
	end
end

function AH_Produce:SelectProfession(frame)
	local hEdit = frame:Lookup("Edit_Search")
	local hText = frame:Lookup("", ""):Lookup("Text_ComboBox")
	local menu = {}
	for k, v in pairs(tRecipeSkill) do
		local m = {
			szOption = v[1],
			fnAction = function()
				self.nProfessionID = v[2]
				local text = hEdit:GetText()
				hEdit:ClearText()
				hEdit:SetText(text)
				hText:SetText(v[1])
			end
		}
		table.insert(menu, m)
	end
	local m1 = {
		szOption = "材料",
		rgb = {255, 128, 0},
		fnAction = function()
			self.nProfessionID = -1
			local text = hEdit:GetText()
			hEdit:ClearText()
			hEdit:SetText(text)
			hText:SetText("材料")
		end
	}
	table.insert(menu, m1)
	local xT, yT = hText:GetAbsPos()
	local wT, hT = hText:GetSize()
	menu.nMiniWidth = wT + 16
	menu.x = xT + 2
	menu.y = yT + hT - 1
	PopupMenu(menu)
end

--递归生成菜单
function AH_Produce:GenerateMenu(menu, recipe)
	local player = GetClientPlayer()
	for nIndex = 1, 6, 1 do
		local nType  = recipe["dwRequireItemType" .. nIndex]
		local nID	 = recipe["dwRequireItemIndex" .. nIndex]
		local nNeed  = recipe["dwRequireItemCount" .. nIndex]
		if nNeed > 0 then
			local nCount = player.GetItemAmount(nType, nID)
			local ItemInfo = GetItemInfo(nType, nID)
			local szName = ItemInfo.szName .. " (" .. nCount .. "/" .. nNeed.. ")"
			local m0 = {szOption = szName,}
			table.insert(menu, m0)
			local data = self:GetRecipeByItemName(ItemInfo.szName)
			if data and not self:IsSpecialMaterial(nType, nID) then
				local nCraftID, nRecipeID = unpack(data)
				local recipe = GetRecipe(nCraftID, nRecipeID)
				local nSubMakeCount = self:GetRecipeTotalCount(recipe)
				if player.IsRecipeLearned(nCraftID, nRecipeID) then
					local m_0 = {
						szOption = "制造 (" .. nSubMakeCount .. ")",
						fnAction = function()
							self:OnCastProfessionSkill(nCraftID, nRecipeID, nSubMakeCount)
						end
					}
					table.insert(m0, m_0)
					table.insert(m0, {bDevide = true})
				end
				self:GenerateMenu(m0, recipe)
			end
		end
	end
end

------------------------------------------------------------
-- 回调函数
------------------------------------------------------------
function AH_Produce.OnFrameCreate()
	this:RegisterEvent("OT_ACTION_PROGRESS_BREAK")
	this:RegisterEvent("SYS_MSG")
	this:RegisterEvent("BAG_ITEM_UPDATE")
	InitFrameAutoPosInfo(this, 1, nil, nil, function() AH_Produce.ClosePanel() end)
end

function AH_Produce.OnEvent(event)
	local frame = this:GetRoot()
	if event == "OT_ACTION_PROGRESS_BREAK" then
		if GetClientPlayer().dwID == arg0 then
			AH_Produce:ClearMakeInfo()
		end
	elseif event == "BAG_ITEM_UPDATE" then
		AH_Produce:UpdateInfo(frame)
	elseif event == "SYS_MSG" then
		if arg0 == "UI_OME_LEARN_RECIPE" then
			if AH_Produce.bIsSearch then
				AH_Produce:UpdateList(frame)
			end
		elseif arg0 == "UI_OME_CRAFT_RESPOND" then
			if arg1 == 1 then
				if AH_Produce.bSub then
					AH_Produce.nSubMakeCount = AH_Produce.nSubMakeCount - 1
				else
					AH_Produce.nMakeCount = AH_Produce.nMakeCount - 1
				end
				AH_Produce:OnMakeRecipe()
				AH_Produce:UpdateInfo(frame)
			else
				AH_Produce:ClearMakeInfo()
			end
		end
	end
end

function AH_Produce.OnFrameBreathe()
	if AH_Produce.bCoolDown then
		local nCurProID = AH_Produce.nCurCraftID
		local nCurCraftID = AH_Produce.nCurCraftID
		local nCurRecipeID = AH_Produce.nCurRecipeID
		local recipe  = GetRecipe(nCurCraftID, nCurRecipeID)
		if not recipe then
			Trace(string.format("Error: GetRecipe(%d, %d) return nil", nCurCraftID, nCurRecipeID))
			return
		end

		if recipe.dwCoolDownID and recipe.dwCoolDownID > 0 and AH_Produce.szCoolDownTime then
			local CDRemainTime = GetClientPlayer().GetCDLeft(recipe.dwCoolDownID)
			local szNTime = AH_Produce:ForamtCoolDownTime(CDRemainTime)
			if szNTime ~= AH_Produce.szCoolDownTime then
				AH_Produce:UpdateContent(this)
			end
		end
	end
end

function AH_Produce.OnUpdateScorllList(hList)
	hList:FormatAllItemPos()
	local hWnd  = hList:GetRoot():Lookup("Wnd_List")
	local hScroll = hWnd:Lookup("Scroll_List")
	local w, h = hList:GetSize()
	local wAll, hAll = hList:GetAllItemSize()
	local nStepCount = math.ceil((hAll - h) / 10)

	hScroll:SetStepCount(nStepCount)
	if nStepCount > 0 then
		hScroll:Show()
		hWnd:Lookup("Btn_ListUp"):Show()
		hWnd:Lookup("Btn_ListDown"):Show()
	else
		hScroll:Hide()
		hWnd:Lookup("Btn_ListUp"):Hide()
		hWnd:Lookup("Btn_ListDown"):Hide()
	end
end

function AH_Produce.OnEditChanged()
	local szName = this:GetName()
	if szName == "Edit_Search" then
		AH_Produce:OnSearch(this:GetRoot())
	end
end

function AH_Produce.OnSetFocus()
	local szName = this:GetName()
	if szName == "Edit_Search" then
		this:SelectAll()
	end
end

function AH_Produce.OnKillFocus()
	local szName = this:GetName()
	if szName == "Edit_Search" then
	end
end

function AH_Produce.OnLButtonClick()
	local frame, szName = this:GetRoot(), this:GetName()
	if szName == "Btn_Close" then
		AH_Produce.ClosePanel()
	elseif szName == "Btn_ComboBox" then
		AH_Produce:SelectProfession(frame)
	elseif szName == "Btn_Add" then
		AH_Produce:UpdateMakeCount(frame, 1)
	elseif szName == "Btn_Del" then
		AH_Produce:UpdateMakeCount(frame, -1)
	elseif szName == "Btn_Make" then
		AH_Produce.bSub = false
		local nCraftID = AH_Produce.nCurCraftID
		local nRecipeID = AH_Produce.nCurRecipeID
		local recipe = GetRecipe(nCraftID, nRecipeID)
		if recipe.nCraftType == ALL_CRAFT_TYPE.PRODUCE then
			AH_Produce:SetMakeInfo(frame)
			AH_Produce:OnMakeRecipe()
		elseif recipe.nCraftType == ALL_CRAFT_TYPE.ENCHANT then
			AH_Produce.nMakeCraftID  = nCraftID
			AH_Produce.nMakeRecipeID = nRecipeID
			AH_Produce.nMakeCount = 1
			AH_Produce:OnEnchantItem()
		end
	elseif szName == "Btn_MakeAll" then
		AH_Produce.bSub = false
		AH_Produce:SetMakeInfo(frame, true)
		AH_Produce:OnMakeRecipe()
	end
end

function AH_Produce.OnItemLButtonClick()
	local frame, szName = this:GetRoot(), this:GetName()
	if this.bItem then
		if IsCtrlKeyDown() then
			EditBox_AppendLinkRecipe(this.nCraftID, this.nRecipeID)
			return
		end
		AH_Produce:Selected(frame, this)
		AH_Produce:UpdateContent(frame)
		PlaySound(SOUND.UI_SOUND, g_sound.Button)
		if IsAuctionPanelOpened() then
			AH_Helper.UpdateList(this.szName)
		end
	elseif this.bEnchant then
		if IsCtrlKeyDown() then
			local nProID, nCraftID, nRecipeID = this:GetObjectData()
			EditBox_AppendLinkEnchant(nProID, nCraftID, nRecipeID)
		end
	elseif this.bProduct then
		if IsCtrlKeyDown() then
			local _, dwVer, nTabType, nIndex = this:GetObjectData()
			EditBox_AppendLinkItemInfo(dwVer, nTabType, nIndex)
		end
	elseif szName == "Handle_ListContent" then
		local szType = this:Lookup("Text_ListTitle"):GetText()
		if EXPAND_ITEM_TYPE.szType == szType then
			EXPAND_ITEM_TYPE = {}
		else
			EXPAND_ITEM_TYPE.szType = szType
		end
		AH_Produce:UpdateItemTypeList(this:GetRoot())
		PlaySound(SOUND.UI_SOUND,g_sound.Button)
	elseif szName == "Handle_List01" then
		local szSubType = this:Lookup("Text_List01"):GetText()
		EXPAND_ITEM_TYPE.szSubType = szSubType
		AH_Produce:UpdateItemTypeList(this:GetRoot())
	end
end

function AH_Produce.OnItemRButtonClick()
	local frame = this:GetRoot()
	if this.bItem then
		AH_Produce:Selected(frame, this)
		AH_Produce:UpdateContent(frame)
		local menu = {}
		local recipe = GetRecipe(this.nCraftID, this.nRecipeID)
		AH_Produce:GenerateMenu(menu, recipe)
		PopupMenu(menu)
	end
end

function AH_Produce.OnItemMouseEnter()
	local frame, szName = this:GetRoot(), this:GetName()
	if this.bItem then
		this.bOver = true
		AH_Produce:UpdateBgStatus(this)
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputItemTip(UI_OBJECT_ITEM_INFO, GLOBAL.CURRENT_ITEM_VERSION, this.nType, this.nID, {x, y, w, h})
	elseif this.bEnchant then
		local nProID, nCraftID, nRecipeID = this:GetObjectData()
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputEnchantTip(nProID, nCraftID, nRecipeID, {x, y, w, h})
	elseif this.bProduct then
		local _, dwVer, nTabType, nIndex = this:GetObjectData()
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputItemTip(UI_OBJECT_ITEM_INFO, dwVer, nTabType, nIndex, {x, y, w, h})
	elseif szName == "Handle_ListContent" or szName == "Handle_List01" then
		this.bOver = true
		AH_Produce:UpdateBgStatus(this)
	end
end

function AH_Produce.OnItemMouseLeave()
	local frame, szName = this:GetRoot(), this:GetName()
	if this.bItem then
		this.bOver = false
		AH_Produce:UpdateBgStatus(this)
		HideTip()
	elseif this.bEnchant then
		HideTip()
	elseif this.bProduct then
		HideTip()
	elseif szName == "Handle_ListContent" or szName == "Handle_List01" then
		this.bOver = false
		AH_Produce:UpdateBgStatus(this)
	end
end

function AH_Produce.OnLButtonHold()
	local szName = this:GetName()
	if szName == "Btn_ListUp" then
		this:GetRoot():Lookup("Wnd_List/Scroll_List"):ScrollPrev(1)
	elseif szName == "Btn_ListDown" then
		this:GetRoot():Lookup("Wnd_List/Scroll_List"):ScrollNext(1)
	elseif szName == "Btn_SUp" then
		this:GetRoot():Lookup("Wnd_Search/Scroll_Search"):ScrollPrev(1)
	elseif szName == "Btn_SDown" then
		this:GetRoot():Lookup("Wnd_Search/Scroll_Search"):ScrollNext(1)
    end
end

function AH_Produce.OnLButtonDown()
	AH_Produce.OnLButtonHold()
end

function AH_Produce.OnItemMouseWheel()
	local szName = this:GetName()
	local nDistance = Station.GetMessageWheelDelta()
	if szName == "Handle_List" then
		this:GetRoot():Lookup("Wnd_List/Scroll_List"):ScrollNext(nDistance)
	elseif szName == "Handle_SearchList" then
		this:GetRoot():Lookup("Wnd_Search/Scroll_Search"):ScrollNext(nDistance)
	end
	return true
end

function AH_Produce.OnScrollBarPosChanged()
	local hWnd  = this:GetParent()
	local szName = this:GetName()
	local nCurrentValue = this:GetScrollPos()
	if szName == "Scroll_List" then
		hBtnUp = hWnd:Lookup("Btn_ListUp")
		hBtnDown = hWnd:Lookup("Btn_ListUp")
		hList = hWnd:Lookup("", "")
	elseif szName == "Scroll_Search" then
		hBtnUp = hWnd:Lookup("Btn_SUp")
		hBtnDown = hWnd:Lookup("Btn_SDown")
		hList = hWnd:Lookup("", "")
	end
	if nCurrentValue == 0 then
		hBtnUp:Enable(false)
	else
		hBtnUp:Enable(true)
	end

	if nCurrentValue == this:GetStepCount() then
		hBtnDown:Enable(false)
	else
		hBtnDown:Enable(true)
	end
	hList:SetItemStartRelPos(0, -nCurrentValue * 10)
end

function AH_Produce.IsPanelOpened()
	local frame = Station.Lookup("Normal/AH_Produce")
	if frame and frame:IsVisible() then
		return true
	end
	return false
end

function AH_Produce.OpenPanel()
	local frame = nil
	if not AH_Produce.IsPanelOpened()  then
		frame = Wnd.OpenWindow(szIniFile, "AH_Produce")
		AH_Produce:Init(frame)
	else
		AH_Produce.ClosePanel()
	end
	PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
end

function AH_Produce.ClosePanel()
	if AH_Produce.IsPanelOpened() then
		Wnd.CloseWindow("AH_Produce")
	end
	PlaySound(SOUND.UI_SOUND,g_sound.CloseFrame)
end

RegisterEvent("LOGIN_GAME", function()
	TraceButton_AppendAddonMenu({{
		szOption = "技艺助手",
		fnAction = function()
			AH_Produce.OpenPanel()
		end,
	}})
end)


