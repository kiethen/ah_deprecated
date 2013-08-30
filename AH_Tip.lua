AH_Tip = {}

local bHooked = false
local bBagHooked = false
local bTipHooked = false
local szItemTip = nil
local szBagItemTip = nil
local bCompact = nil

local function FormatTipEx(h, szText, szTip)
	local i, j = h:GetItemCount(), 0
	if string.find(szText, "不能拆解") and string.find(szText, "调试用信息") then
		j = i - 3
	elseif string.find(szText, "不能拆解") then
		j = i - 1
	elseif string.find(szText, "调试用信息") then
		j = i - 2
	else
		j = i
	end
	h:InsertItemFromString(j, false, szTip)
end

function AH_Tip.OnFrameBreathe()
	if not bTipHooked then
		local frame = Station.Lookup("Topmost1/TipPanel_Normal")
		if frame and frame:IsVisible() then
			if DelayCall then
				DelayCall(2, function() AH_Tip.InitHookTip(frame) end)
			else
				AH_Tip.InitHookTip(frame)
			end
			bTipHooked = true
		end
	end
	local frame = Station.Lookup("Normal/BigBagPanel")
	if frame then
		if not bBagHooked and frame:IsVisible() then
			bCompact = frame:Lookup("CheckBox_Compact"):IsCheckBoxChecked()
			if bCompact then
				AH_Tip.UpdateCompact(frame)
			else
				AH_Tip.UpdateNormal(frame)
			end
			bBagHooked = true
		elseif not frame:IsVisible() then
			bBagHooked = false
		end
	end
end

--Hook TIP
function AH_Tip.InitHookTip(frame)
	local h = frame:Lookup("", "Handle_Message")
	if not h.AppendItemFromStringOrg then
		h.AppendItemFromStringOrg = h.AppendItemFromString
	end
	h.AppendItemFromString = function(h, szText)
		h:AppendItemFromStringOrg(szText)
		local hWnd = Station.GetMouseOverWindow()
		if IsAuctionPanelOpened() and hWnd:GetName() == "Wnd_Result2" then
			if szItemTip then
				FormatTipEx(h, szText, szItemTip)
			end
		elseif IsBigBagPanelOpened() and hWnd:GetName() == "BigBagPanel" then
			if szBagItemTip then
				FormatTipEx(h, szText, szBagItemTip)
			end
		end
	end
end

--背包相关
function AH_Tip.UpdateCompact(frame)
	local handle = frame:Lookup("", "Handle_Bag_Compact")
	local nCount = handle:GetItemCount()
	for i = 0, nCount - 1 do
		local hBox = handle:Lookup(i)
		local box = hBox:Lookup(1)
		AH_Tip.HookBagItemBox(box)
	end
end

function AH_Tip.UpdateNormal(frame)
	for i = 1, 6 do
		local handle = frame:Lookup("", "Handle_Bag_Normal/Handle_Bag" .. i):Lookup("Handle_Bag_Content" .. i)
		for j = 0, GetClientPlayer().GetBoxSize(i) - 1 do
			local hBox = handle:Lookup(j)
			local box = hBox:Lookup(1)
			AH_Tip.HookBagItemBox(box)
		end
	end
end

function AH_Tip.HookBagItemBox(box)
	if box and not box.bBag then
		if not box.SetObjectMouseOverOrg then
			box.SetObjectMouseOverOrg = box.SetObjectMouseOver
		end
		box.SetObjectMouseOver = function(h, bOver)
			box:SetObjectMouseOverOrg(bOver)
			if bOver == 1 then
				szBagItemTip = AH_Tip.GetBagItemTip(this)
			elseif bOver == 0 then
				szBagItemTip = nil
			end
		end
	end
end

--背包物品鼠标提示
function AH_Tip.GetBagItemTip(box)
	local player, szTip = GetClientPlayer(), ""
	local item = player.GetItem(box.dwBox, box.dwX)
	if item then
		local nItemCountInPackage = player.GetItemAmount(item.dwTabType, item.dwIndex)
		local nItemCountTotal = player.GetItemAmountInAllPackages(item.dwTabType, item.dwIndex)
		local nItemCountInBank = nItemCountTotal - nItemCountInPackage

		szTip = szTip .. GetFormatText("物品总数：", 101) .. GetFormatText(nItemCountTotal, 162)
		szTip = szTip .. GetFormatText("    背包：", 101) .. GetFormatText(nItemCountInPackage, 162) .. GetFormatText("    仓库：", 101) .. GetFormatText(nItemCountInBank, 162)

		--配方
		if item.nGenre == ITEM_GENRE.MATERIAL then
			szTip = szTip .. AH_Tip.GetRecipeTip(player, item)
		end

		local v = AH_Helper.tItemPrice[item.nUiId]
		if v and v[1] then
			if MoneyOptCmp(v[1], PRICE_LIMITED) ~= 0 then
				szTip = szTip .. GetFormatText("\n最低一口价：", 163) .. GetMoneyTipText(v[1], 106)
			end
		end
	end
	return szTip
end

function AH_Tip.GetRecipeByItemName(dwProfessionID, szName)
	local player, t = GetClientPlayer(), {}
	for _, v in ipairs(player.GetRecipe(dwProfessionID)) do
		local recipe = GetRecipe(v.CraftID, v.RecipeID)
		if recipe and recipe.nCraftType ~= ALL_CRAFT_TYPE.ENCHANT then
			for nIndex = 1, 6, 1 do
				local nType  = recipe["dwRequireItemType"..nIndex]
				local nID	 = recipe["dwRequireItemIndex"..nIndex]
				local nNeed  = recipe["dwRequireItemCount"..nIndex]
				if nNeed > 0 then
					if GetItemInfo(nType, nID).szName == szName then
						table.insert(t, {v.CraftID, v.RecipeID})
					end
				end
			end
		end
	end
	table.sort(t, function(a, b) return a[2] > b[2] end)
	return t
end

function AH_Tip.GetRecipeTip(player, item)
	local szTip, bFlag = "", false
	local szItemName = GetItemNameByItem(item)
	local szOuter, szInner = GetFormatText("\n相关技艺配方<已学习>", 165), ""
	for k, v in ipairs(tRecipeSkill) do
		if player.IsProfessionLearnedByCraftID(v[2]) then
			local tRecipe = AH_Tip.GetRecipeByItemName(v[2], szItemName)
			if not IsTableEmpty(tRecipe) then
				bFlag, szInner = true, szInner .. GetFormatText(FormatString("\n<D0>：\n", v[1]), 163) .. GetFormatText("      ")
				local t1 = {}
				for k2, v2 in ipairs(tRecipe) do
					local recipe = GetRecipe(v2[1], v2[2])
					if recipe then
						local tItemInfo = GetItemInfo(recipe.dwCreateItemType1, recipe.dwCreateItemIndex1)
						table.insert(t1, "<text>text=" .. EncodeComponentsString(GetItemNameByItemInfo(tItemInfo)) .. " font=162 " .. GetItemFontColorByQuality(tItemInfo.nQuality, true).."</text>")
					end
				end
				szInner = szInner .. table.concat(t1, GetFormatText("，", 162))
			end
		end
	end
	if bFlag and szInner ~= "" then szTip = szTip .. szOuter .. szInner end
	if IsAltKeyDown() or IsShiftKeyDown() then
		szOuter, szInner = GetFormatText("\n相关技艺配方<未学习>", 166), ""
		for k, v in ipairs(tRecipeSkill) do
			if player.IsProfessionLearnedByCraftID(v[2]) then
				local tRecipe = tRecipeALL[v[2]][szItemName]
				if not IsTableEmpty(tRecipe) then
					local temp = {}
					for m, n in ipairs(tRecipe) do
						if not player.IsRecipeLearned(n[1], n[2]) then
							table.insert(temp, {n[1], n[2]})
						end
					end
					if not IsTableEmpty(temp) then
						bFlag, szInner = true, szInner .. GetFormatText(FormatString("\n<D0>：\n", v[1]), 163) .. GetFormatText("      ")
						local t2 = {}
						for k2, v2 in ipairs(temp) do
							local recipe = GetRecipe(v2[1], v2[2])
							if recipe then
								local tItemInfo = GetItemInfo(recipe.dwCreateItemType1, recipe.dwCreateItemIndex1)
								table.insert(t2, "<text>text=" .. EncodeComponentsString(GetItemNameByItemInfo(tItemInfo)) .. " font=162 " .. GetItemFontColorByQuality(tItemInfo.nQuality, true).."</text>")
							end
						end
						szInner = szInner .. table.concat(t2, GetFormatText("，", 162))
					end
				end
			end
		end
		if bFlag and szInner ~= "" then szTip = szTip .. szOuter .. szInner end
	end
	return szTip
end