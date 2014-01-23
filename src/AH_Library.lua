------------------------------------------------------
-- #模块名：交易行插件函数库模块
-- #模块说明：用于非开放API的重构以及生活技艺数据的生成
------------------------------------------------------

AH_Library = AH_Library or {}

local ipairs = ipairs
local pairs = pairs

local szIniFile = "Interface/AH/ui/AH_Library.ini"
-----------------------------------------------
-- 重构非白名单函数
-----------------------------------------------
if not Table_GetSegmentName then
	Table_GetSegmentName = function(dwBookID, dwSegmentID)
		local szSegmentName = ""
		local tBookSegment = g_tTable.BookSegment:Search(dwBookID, dwSegmentID)
		if tBookSegment then
			szSegmentName = tBookSegment.szSegmentName
		end
		return szSegmentName
	end
end

if not GetItemNameByItem then
	GetItemNameByItem = function(item)
		if item.nGenre == ITEM_GENRE.BOOK then
			local nBookID, nSegID = GlobelRecipeID2BookID(item.nBookID)
			return Table_GetSegmentName(nBookID, nSegID) or g_tStrings.BOOK
		else
			return Table_GetItemName(item.nUiId)
		end
	end
end

if not GetItemNameByItemInfo then
	GetItemNameByItemInfo = function(itemInfo, nBookInfo)
		if itemInfo.nGenre == ITEM_GENRE.BOOK then
			if nBookInfo then
				local nBookID, nSegID = GlobelRecipeID2BookID(nBookInfo)
				return Table_GetSegmentName(nBookID, nSegID) or g_tStrings.BOOK
			else
				return Table_GetItemName(itemInfo.nUiId)
			end
		else
			return Table_GetItemName(itemInfo.nUiId)
		end
	end
end

if not Table_GetCraftBelongName then
	Table_GetCraftBelongName = function(dwProfessionID, dwBelongID)
		local szBelongName = ""
		local tCraft = g_tTable.CraftBelongName:Search(dwProfessionID, dwBelongID)
		if tCraft then
			szBelongName = tCraft.szBelongName
		end
		return szBelongName
	end
end

if not Table_GetProfessionName then
	Table_GetProfessionName = function(dwProfessionID)
		local szName = ""
		local tProfession = g_tTable.ProfessionName:Search(dwProfessionID)
		if tProfession then
			szName = tProfession.szName
		end
		return szName
	end
end

if not Table_GetEnchantName then
	Table_GetEnchantName = function(dwProfessionID, dwCraftID, dwRecipeID)
		local szName = ""
		local tCraft = g_tTable.CraftEnchant:Search(dwProfessionID, dwCraftID, dwRecipeID)
		if tCraft then
			szName = tCraft.szName
		end
		return szName
	end
end

if not Table_GetEnchantIconID then
	Table_GetEnchantIconID = function(dwProfessionID, dwCraftID, dwRecipeID)
		local dwIconID = -1
		local tCraft = g_tTable.CraftEnchant:Search(dwProfessionID, dwCraftID, dwRecipeID)
		if tCraft then
			dwIconID = tCraft.dwIconID
		end
		return dwIconID
	end
end

if not Table_GetEnchantQuality then
	Table_GetEnchantQuality = function(dwProfessionID, dwCraftID, dwRecipeID)
		local nQuality = -1
		local tCraft = g_tTable.CraftEnchant:Search(dwProfessionID, dwCraftID, dwRecipeID)
		if tCraft then
			nQuality = tCraft.nQuality
		end
		return nQuality
	end
end

if not Table_GetDoodadTemplateName then
	Table_GetDoodadTemplateName = function(dwTemplateID)
		local szName = ""
		local tDoodad = g_tTable.DoodadTemplate:Search(dwTemplateID)
		if tDoodad then
			szName = tDoodad.szName
		end
		return szName
	end
end

if not EditBox_AppendLinkRecipe then
	EditBox_AppendLinkRecipe = function(dwCraftID, dwRecipeID)
		local recipe = GetRecipe(dwCraftID, dwRecipeID)
		if not recipe then
			return false
		end
		local ItemInfo = GetItemInfo(recipe.dwCreateItemType1, recipe.dwCreateItemIndex1)

		local szRecipeName = ItemInfo.szName
		local szName = "["..szRecipeName.."]"

		local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
		edit:InsertObj(szName, {type = "recipe", text = szName, craftid = dwCraftID, recipeid = dwRecipeID})

		Station.SetFocusWindow(edit)
		return true
	end
end

if not EditBox_AppendLinkEnchant then
	EditBox_AppendLinkEnchant = function(dwProID, dwCraftID, dwRecipeID)
		local szName = "["..Table_GetEnchantName(dwProID, dwCraftID, dwRecipeID).."]"

		local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
		edit:InsertObj(szName, {type = "enchant", text = szName, proid = dwProID, craftid = dwCraftID, recipeid = dwRecipeID})

		Station.SetFocusWindow(edit)
		return true
	end
end

if not EditBox_AppendLinkItemInfo then
	EditBox_AppendLinkItemInfo = function(nVersion, nTabtype, nIndex, nBookInfo)
		local itemInfo = GetItemInfo(nTabtype, nIndex)
		if not itemInfo then
			return false
		end
		if itemInfo.nGenre == ITEM_GENRE.BOOK then
			if not nBookInfo then
				return false
			end

			local nBookID, nSegmentID = GlobelRecipeID2BookID(nBookInfo)
			local szName = "["..Table_GetSegmentName(nBookID, nSegmentID).."]"

			local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
			edit:InsertObj(szName, {type = "book", text = szName, version = nVersion, tabtype = nTabtype, index = nIndex, bookinfo = nBookInfo})
			Station.SetFocusWindow(edit)
		else
			local szName = "["..GetItemNameByItemInfo(itemInfo).."]"

			local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
			edit:InsertObj(szName, {type = "iteminfo", text = szName, version = nVersion, tabtype = nTabtype, index = nIndex})
			Station.SetFocusWindow(edit)
		end
		return true
	end
end

if not SetEditTextStruct then
	SetEditTextStruct = function(edit, t)
		edit:ClearText()
		for k, v in ipairs(t) do
			if v.type == "text" then
				edit:InsertText(v.text)
			else
				edit:InsertObj(v.text, v)
			end
		end
	end
end

if not EditBox_TalkToSomebody then
	EditBox_TalkToSomebody = function(szName)
		local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
		local t = edit:GetTextStruct()
		t = t or {}
		if t[1] then
			if t[1].type == "text" then
				t[1].text = "/w "..szName.." "..t[1].text
			else
				table.insert(t, 1, {type = "text", text = "/w "..szName.." "})
			end
		else
			t[1] = {type = "text", text = "/w "..szName.." "}
		end
		SetEditTextStruct(edit, t)
		Station.SetFocusWindow(edit)
	end
end

if not IsAuctionPanelOpened then
	IsAuctionPanelOpened = function()
		local frame = Station.Lookup("Normal/AuctionPanel")
		if frame and frame:IsVisible() then
			return true
		end
		return false
	end
end

if not IsBigBagPanelOpened then
	IsBigBagPanelOpened = function()
		local frame = Station.Lookup("Normal/BigBagPanel")
		if frame and frame:IsVisible() then
			return true
		end
		return false
	end
end

if not IsMailPanelOpened then
	IsMailPanelOpened = function()
		local frame = Station.Lookup("Normal/MailPanel")
		if frame and frame:IsVisible() then
			return true
		end
		return false
	end
end

if not ALL_CRAFT_TYPE then
	ALL_CRAFT_TYPE = {
		COPY = 6,
		READ = 3,
		TOTAL = 8,
		RADAR = 5,
		ENCHANT = 4,
		PRODUCE = 2,
		COLLECTION = 1
	}
end

if not OpenInternetExplorer then
	IsInternetExplorerOpened = function(nIndex)
		local frame = Station.Lookup("Topmost/IE"..nIndex)
		if frame and frame:IsVisible() then
			return true
		end
		return false
	end

	IE_GetNewIEFramePos = function()
		local nLastTime = 0
		local nLastIndex = nil
		for i = 1, 10, 1 do
			local frame = Station.Lookup("Topmost/IE"..i)
			if frame and frame:IsVisible() then
				if frame.nOpenTime > nLastTime then
					nLastTime = frame.nOpenTime
					nLastIndex = i
				end
			end
		end
		if nLastIndex then
			local frame = Station.Lookup("Topmost/IE"..nLastIndex)
			x, y = frame:GetAbsPos()
			local wC, hC = Station.GetClientSize()
			if x + 890 <= wC and y + 630 <= hC then
				return x + 30, y + 30
			end
		end
		return 40, 40
	end

	OpenInternetExplorer = function(szAddr, bDisableSound)
		local nIndex, nLast = nil, nil
		for i = 1, 10, 1 do
			if not IsInternetExplorerOpened(i) then
				nIndex = i
				break
			elseif not nLast then
				nLast = i
			end
		end
		if not nIndex then
			OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.MSG_OPEN_TOO_MANY)
			return nil
		end
		local x, y = IE_GetNewIEFramePos()
		local frame = Wnd.OpenWindow("InternetExplorer", "IE"..nIndex)
		frame.bIE = true
		frame.nIndex = nIndex

		frame:BringToTop()
		if nLast then
			frame:SetAbsPos(x, y)
			frame:CorrectPos()
			frame.x = x
			frame.y = y
		else
			frame:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
			frame.x, frame.y = frame:GetAbsPos()
		end
		local webPage = frame:Lookup("WebPage_Page")
		if szAddr then
			webPage:Navigate(szAddr)
		end
		Station.SetFocusWindow(webPage)
		if not bDisableSound then
			PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
		end
		return webPage
	end
end
-----------------------------------------------
-- 外部数据加载
-----------------------------------------------
local _, _, szLang = GetVersion()
local _FILE = {
	Enchant = {
		Path = string.format("Interface\\AH\\data\\%s\\Enchant.tab", szLang),
		Title = {
			{f = "s", t = "szName"},
			{f = "s", t = "szDesc"},
		},
	},
	AtNormal = {
		Path = string.format("Interface\\AH\\data\\%s\\Normal.txt", szLang),
		Title = {
			{f = "s", t = "szAttributeName"},
			{f = "S", t = "szGeneratedMagic"},
		},
	},
	AtSimplify = {
		Path = string.format("Interface\\AH\\data\\%s\\Simplify.txt", szLang),
		Title = {
			{f = "s", t = "szAttributeName"},
			{f = "S", t = "szGeneratedMagic"},
		},
	},
	Normal = {
		Path = string.format("Interface\\AH\\data\\%s\\Normal.tab", szLang),
		Title = {
			{f = "i", t = "dwID"},
			{f = "s", t = "szName"},
			{f = "S", t = "szAttributeOne"},
			{f = "s", t = "szAttributeTwo"},
			{f = "S", t = "szAttributeThree"},
		},
	},
	Simplify = {
		Path = string.format("Interface\\AH\\data\\%s\\Simplify.tab", szLang),
		Title = {
			{f = "i", t = "dwID"},
			{f = "s", t = "szName"},
			{f = "S", t = "szAttributeOne"},
			{f = "s", t = "szAttributeTwo"},
		},
	},
	Lang = {
		Path = string.format("Interface\\AH\\lang\\%s.tab", szLang),
		Title = {
			{f = "s", t = "szKey"},
			{f = "S", t = "szValue"},
		},
	}
}

-----------------------------------------------
-- 多语言处理
-----------------------------------------------
function AH_Library.LoadLangPack()
	local tRes = {}
	local tTable = KG_Table.Load(_FILE.Lang.Path, _FILE.Lang.Title, FILE_OPEN_MODE.NORMAL)
	if tTable then
		local nRow = tTable:GetRowCount()
		for i = 1, nRow do
			local tRow = tTable:GetRow(i)
			if not tRes[tRow.szKey] then
				tRes[tRow.szKey] = tRow.szValue
			end
		end
	end
	setmetatable(tRes, {
		__index = function(t, k) return k end,
		__call = function(t, k, ...) return string.format(t[k], ...) end,
	})
	return tRes
end
local L = AH_Library.LoadLangPack()

OutputMessage("MSG_SYS", "----------------------------\n")

-----------------------------------------------
-- 生活技艺数据生成
-----------------------------------------------

AH_Library.tMergeRecipe = {}
AH_Library.tEnchantData = {}

-- 返回 {nRecipeID, szRecipeName} 数据的表
function AH_Library.GetCraftRecipe(nCraftID)
	local tRes = {}
	local tCraft = g_tTable.UICraft:Search(nCraftID)
	if tCraft.szPath ~= "" then
		local tTable = KG_Table.Load(tCraft.szPath,
		{
			{f = "i", t = "dwID"},
			{f = "s", t = "szName"},
		},
		FILE_OPEN_MODE.NORMAL)
		if tTable then
			local nRow = tTable:GetRowCount()
			for i = 2, nRow do
				local tRow = tTable:GetRow(i)
				table.insert(tRes, {tRow.dwID, tRow.szName})
			end
		end
	end
	table.sort(tRes, function(a, b) return a[1] > b[1] end)
	return tRes
end

-- 返回 {szRecipeName, nCraftID, nRecipeID} 数据的表
function AH_Library.GetAllRecipe()
	local t = {}
	for _, k in pairs({4, 5, 6, 7}) do
		local tRes = AH_Library.GetCraftRecipe(k)
		for _, v in ipairs(tRes) do
			local recipe = GetRecipe(k, v[1])
			if recipe then
				if t[k] then
					table.insert(t[k], {v[2], k, v[1]})
				else
					t[k] = {{v[2], k, v[1]}}
				end
			end
		end
	end
	return t
end

-- 返回以szItemName为索引的 {nCraftID, nRecipeID} 的表
function AH_Library.GetAllMaterial()
	local t = {}
	for _, k in pairs({4, 5, 6, 7}) do
		if not t[k] then t[k] = {} end
		local tRes = AH_Library.GetCraftRecipe(k)
		for _, v in ipairs(tRes) do
			local recipe = GetRecipe(k, v[1])
			if recipe and recipe.nCraftType ~= ALL_CRAFT_TYPE.ENCHANT then
				for nIndex = 1, 6, 1 do
					local nType  = recipe["dwRequireItemType" .. nIndex]
					local nID	 = recipe["dwRequireItemIndex" .. nIndex]
					local nNeed  = recipe["dwRequireItemCount" .. nIndex]
					if nNeed > 0 then
						local szName = GetItemInfo(nType, nID).szName
						if not t[k][szName] then
							t[k][szName] = {}
						end
						table.insert(t[k][szName], {k, v[1]})
					end
				end
			end
		end
	end
	return t
end

AH_Library.tRecipeALL = AH_Library.GetAllRecipe()
AH_Library.tMaterialALL = AH_Library.GetAllMaterial()
do
	local mt = {}
	mt.__add = function(t1, t2)
		for _, v in ipairs(t2) do
			table.insert(t1, v)
		end
		return t1
	end
	setmetatable(AH_Library.tMergeRecipe, mt)
	for k, v in ipairs({4, 5, 6, 7}) do
		AH_Library.tMergeRecipe = AH_Library.tMergeRecipe + AH_Library.tRecipeALL[v]
	end

	local tTable = KG_Table.Load(_FILE.Enchant.Path, _FILE.Enchant.Title, FILE_OPEN_MODE.NORMAL)
	if tTable then
		local nRow = tTable:GetRowCount()
		for i = 1, nRow do
			local tRow = tTable:GetRow(i)
			if not AH_Library.tEnchantData[tRow.szName] then
				AH_Library.tEnchantData[tRow.szName] = tRow.szDesc
			end
		end
	end
end
OutputMessage("MSG_SYS", L("STR_LIBRARY_RECIPEINIT") .. "\n")
-----------------------------------------------
-- 五彩石数据生成
-----------------------------------------------
AH_Library.tColorMagic = {}
AH_Library.tColorDiamond = {}

function AH_Library.ID2MagicTable(szType)
	local tRes = {}
	local tTable = KG_Table.Load(_FILE[szType].Path, _FILE[szType].Title, FILE_OPEN_MODE.NORMAL)
	if tTable then
		local nRow = tTable:GetRowCount()
		for i = 2, nRow do
			local tRow = tTable:GetRow(i)
			tRes[i - 1] = {tRow.szAttributeName, tRow.szGeneratedMagic}
		end
	end
	return tRes
end

function AH_Library.ColorDiamondTable(szType)
	local tRes = {}
	local tTable = KG_Table.Load(_FILE[szType].Path, _FILE[szType].Title, FILE_OPEN_MODE.NORMAL)
	if tTable then
		local nRow = tTable:GetRowCount()
		if szType == "Normal" then
			for i = 1, nRow do
				local tRow = tTable:GetRow(i)
				tRes[i] = {tRow.dwID, tRow.szName, tRow.szAttributeOne, tRow.szAttributeTwo, tRow.szAttributeThree}
			end
		elseif szType == "Simplify" then
			for i = 1, nRow do
				local tRow = tTable:GetRow(i)
				tRes[i] = {tRow.dwID, tRow.szName, tRow.szAttributeOne, tRow.szAttributeTwo}
			end
		end
	end
	return tRes
end

do
	for k, v in pairs({"Normal", "Simplify"}) do
		AH_Library.tColorMagic[v] = AH_Library.ID2MagicTable("At"..v)
		AH_Library.tColorDiamond[v] = AH_Library.ColorDiamondTable(v)
	end
end
OutputMessage("MSG_SYS", L("STR_LIBRARY_DIAMONDINIT") .. "\n")
OutputMessage("MSG_SYS", "----------------------------\n")
-----------------------------------------------
-- 统一所用模块的刷新事件及延迟调用
-----------------------------------------------
local tBreatheAction = {}
local tDelayCall = {}
function AH_Library.OnFrameBreathe()
	local nTime = GetTickCount()
	local nCount = #tDelayCall
	for i = nCount, 1, -1 do
		local v = tDelayCall[i]
		if nTime >= v[1] then
			local f = v[2]
			table.remove(tDelayCall, i)
			if v[3] then
				f(unpack(v[3]))
			else
				f()
			end
		end
	end

	for szKey, fnAction in pairs(tBreatheAction) do
		assert(fnAction)
		fnAction()
	end
end

function AH_Library.RegisterBreatheEvent(szKey, fnAction)
	assert(type(szKey) == "string")
	tBreatheAction[szKey] = fnAction
end

function AH_Library.DelayCall(nTime, fnAction, ...)
	table.insert(tDelayCall, {GetTickCount() + nTime * 1000, fnAction, {...}})
end


function AH_Library.OnTitleChanged()
	local szDoc = this:GetDocument()
	if szDoc ~= "" and szDoc > AH_Helper.szVersion then
		local tVersionInfo = {
			szName = "AH_HelperVersionInfo",
			szMessage = L("STR_LIBRARY_NEWVERSION", szDoc), {
				szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function()
					OpenInternetExplorer("http://jx3auction.duapp.com/down", true)
				end
			},{szOption = g_tStrings.STR_HOTKEY_CANCEL,fnAction = function() end},
		}
		MessageBox(tVersionInfo)
	end
end

--LUA base64加密
local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
function base64(data)
    return ((data:gsub('.', function(x)
        local r,b = '',x:byte()
        for i = 8,1,-1 do r = r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c = 0
        for i = 1,6 do c = c+(x:sub(i,i) == '1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

Wnd.OpenWindow(szIniFile, "AH_Library")

RegisterEvent("CALL_LUA_ERROR", function()
	OutputMessage("MSG_SYS", arg0)
end)
