------------------------------------------------------
-- #模块名：交易行模块
-- #模块说明：交易行各类功能的增强
------------------------------------------------------
local L = AH_Library.LoadLangPack()

local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber

--------------------------------------------------------
-- 插件配置
--------------------------------------------------------
AH_Helper = {
	szDefaultValue = "Btn_Min",
	szDefaultTime = L("STR_HELPER_24HOUR"),

	nVersion = 0,
	nPricePercentage = 0.95,
	nDefaultPrices = 1,
	nMaxHistory = 10,

	bFastBid = true,
	bFastBuy = true,
	bFastCancel = true,
	bDBClickFastBuy = false,
	bDBClickFastCancel = false,
	bNoAllPrompt = false,
	bPricePercentage = false,
	bLowestPrices = true,
	bFilterRecipe = false,
	bFilterBook = false,
	bAutoSearch = true,
	bSellNotice = false,
	bFormatMoney = true,
	bDBCtrlSell = false,

	tItemFavorite = {},
	tBlackList = {},
	tItemHistory = {},
	tItemPrice = {},

	szDataPath = "\\Interface\\AH\\data\\data.AH",
	szVersion = "2.1.3",		--用于版本检测

	tVerify = {
		szDate = "",
		bChecked = false
	},
}


--------------------------------------------------------
-- 交易行数据缓存
--------------------------------------------------------
local tBidTime = {}
local bFilterd = false
local bHooked = false
local bAutoSearch = false

--------------------------------------------------------
-- 用户数据存储
--------------------------------------------------------
RegisterCustomData("AH_Helper.szDefaultValue")
RegisterCustomData("AH_Helper.szDefaultTime")
RegisterCustomData("AH_Helper.nDefaultPrices")
RegisterCustomData("AH_Helper.nMaxHistory")
RegisterCustomData("AH_Helper.nPricePercentage")
RegisterCustomData("AH_Helper.bFilterRecipe")
RegisterCustomData("AH_Helper.bFilterBook")
RegisterCustomData("AH_Helper.bAutoSearch")
RegisterCustomData("AH_Helper.bLowestPrices")
RegisterCustomData("AH_Helper.bPricePercentage")
RegisterCustomData("AH_Helper.bSellNotice")
RegisterCustomData("AH_Helper.bFastBid")
RegisterCustomData("AH_Helper.bFastBuy")
RegisterCustomData("AH_Helper.bFastCancel")
RegisterCustomData("AH_Helper.bDBCtrlSell")
RegisterCustomData("AH_Helper.tItemHistory")
RegisterCustomData("AH_Helper.tItemFavorite")
RegisterCustomData("AH_Helper.tBlackList")
RegisterCustomData("AH_Helper.tVerify")
--------------------------------------------------------
-- AH局部变量初始化
--------------------------------------------------------
local PRICE_LIMITED = PackMoney(9000000, 0, 0)
local MAX_BID_PRICE = PackMoney(800000, 0, 0)

local tSearchInfoDefault = {
	["Name"]     = L("STR_HELPER_ITEMNAME"),
	["Level"]    = {"", ""},
	["Quality"]  = L("STR_HELPER_ANYLEVEL"),
	["Status"]   = L("STR_HELPER_ALLSTATE"),
	["MaxPrice"] = {"", "" ,""},
}

local AUCTION_ORDER_TYPE = {
	QUALITY 			= 0,
	LEVEL 				= 1,
	LEFT_TIME 			= 2,
	PRICE				= 3,
	BUY_IT_NOW_PRICE 	= 4,
}

local tItemDataInfo =
{
	["Search"] = {nStart = 1, nCurCount = 0, nTotCount = 0, nSortType = AUCTION_ORDER_TYPE.BUY_IT_NOW_PRICE, bDesc = 0, bUnitPrice=true, nRequestID = 0, szCheckName = "CheckBox_RName"},
	["Sell"]   = {nStart = 1, nCurCount = 0, nTotCount = 0, nSortType = AUCTION_ORDER_TYPE.QUALITY, bDesc = 1, bUnitPrice=false, nRequestID = 1, szCheckName = "CheckBox_AName"},
	["Bid"]    = {nStart = 1, nCurCount = 0, nTotCount = 0, nSortType = AUCTION_ORDER_TYPE.LEFT_TIME, bDesc = 1, bUnitPrice=false, nRequestID = 2, szCheckName = "CheckBox_BRemainTime"},
}

local tItemWidgetInfo =
{
	["Search"] =
	{
		Scroll="Scroll_Result", BtnUp="Btn_RUp", BtnDown="Btn_RDown", Box="Box_Box", Text="Text_BoxName", Level="Text_BoxLevel", Saler="Text_BoxSaler", Time="Text_BoxRemainTime",
		aBidText={"Text_BidGold", "Text_BidSilver", "Text_BidCopper", "Text_MyBid"},
		aBuyText={"Text_PrGold",  "Text_PrSilver",  "Text_PrCopper",  "Text_UnitPrice"},
		aBuyImg ={"Image_PrGold", "Image_PrSilver", "Image_PrCopper"},
		tCheck =
		{
			["CheckBox_RName"]      = {imgUp = "Image_RNameUp",     imgDown = "Image_RNameDown",     nSortType = AUCTION_ORDER_TYPE.QUALITY},
			["CheckBox_RLevel"]     = {imgUp = "Image_RLevelUp",    imgDown = "Image_RLevelDown",    nSortType = AUCTION_ORDER_TYPE.LEVEL},
			["CheckBox_RemainTime"] = {imgUp = "Image_ReNameUp",    imgDown = "Image_ReNameDown",    nSortType = AUCTION_ORDER_TYPE.LEFT_TIME},
			["CheckBox_Bid"]        = {imgUp = "Image_BidNameUp",   imgDown = "Image_BidNameDown",   nSortType = AUCTION_ORDER_TYPE.PRICE},
			["CheckBox_Price"]      = {imgUp = "Image_PriceNameUp", imgDown = "Image_PriceNameDown", nSortType = AUCTION_ORDER_TYPE.BUY_IT_NOW_PRICE},
		}
	},
	["Bid"] =
	{
		Scroll="Scroll_Bid", BtnUp="Btn_BUp", BtnDown="Btn_BDown", Box="Box_BidBox", Text="Text_BidBoxName", Level="Text_BidBoxLevel", Saler="Text_BidBoxSaler", Time="Text_BidBoxRemainTime",
		aBidText={"Text_BidBidGold", "Text_BidBidSilver", "Text_BidBidCopper", "Text_BidMyBid"},
		aBuyText={"Text_BidPrGold",  "Text_BidPrSilver",  "Text_BidPrCopper",  "Text_BUnitPrice"},
		aBuyImg ={"Image_BidPrGold", "Image_BidPrSilver", "Image_BidPrCopper"},
		tCheck =
		{
			["CheckBox_BName"]       = {imgUp = "Image_BNameUp",      imgDown = "Image_BNameDown",      nSortType = AUCTION_ORDER_TYPE.QUALITY},
			["CheckBox_BLevel"]      = {imgUp = "Image_BLevelUp",     imgDown = "Image_BLevelDown",     nSortType = AUCTION_ORDER_TYPE.LEVEL},
			["CheckBox_BRemainTime"] = {imgUp = "Image_BReNameUp",    imgDown = "Image_BReNameDown",    nSortType = AUCTION_ORDER_TYPE.LEFT_TIME},
			["CheckBox_BBid"]        = {imgUp = "Image_BBidNameUp",   imgDown = "Image_BBidNameDown",   nSortType = AUCTION_ORDER_TYPE.PRICE},
			["CheckBox_BPrice"]      = {imgUp = "Image_BPriceNameUp", imgDown = "Image_BPriceNameDown", nSortType = AUCTION_ORDER_TYPE.BUY_IT_NOW_PRICE},
		}
	},
	["Sell"] =
	{
		Scroll="Scroll_Auction", BtnUp="Btn_AUp", BtnDown="Btn_ADown", Box="Box_ABox", Text="Text_ABoxName", Level="Text_ABoxLevel", Saler="Text_ABoxSaler", Time="Text_ABoxRemainTime",
		aBidText={"Text_ABidGold", "Text_ABidSilver", "Text_ABidCopper", "Text_AMyBid",},
		aBuyText={"Text_APrGold",  "Text_APrSilver",  "Text_APrCopper",  "Text_AUnitPrice",},
		aBuyImg ={"Image_APrGold", "Image_APrSilver", "Image_APrCopper"},
		tCheck =
		{
			["CheckBox_AName"]       = {imgUp = "Image_ANameUp",      imgDown = "Image_ANameDown",      nSortType = AUCTION_ORDER_TYPE.QUALITY},
			["CheckBox_ALevel"]      = {imgUp = "Image_ALevelUp",     imgDown = "Image_ALevelDown",     nSortType = AUCTION_ORDER_TYPE.LEVEL},
			["CheckBox_ARemainTime"] = {imgUp = "Image_AReNameUp",    imgDown = "Image_AReNameDown",    nSortType = AUCTION_ORDER_TYPE.LEFT_TIME},
			["CheckBox_ABid"]        = {imgUp = "Image_ABidNameUp",   imgDown = "Image_ABidNameDown",   nSortType = AUCTION_ORDER_TYPE.PRICE},
			["CheckBox_APrice"]      = {imgUp = "Image_APriceNameUp", imgDown = "Image_APriceNameDown", nSortType = AUCTION_ORDER_TYPE.BUY_IT_NOW_PRICE},
		}
	}
}


AH_Helper.UpdateItemListOrg = AuctionPanel.UpdateItemList
AH_Helper.SetSaleInfoOrg = AuctionPanel.SetSaleInfo
AH_Helper.FormatAuctionTimeOrg = AuctionPanel.FormatAuctionTime
AH_Helper.GetItemSellInfoOrg = AuctionPanel.GetItemSellInfo
AH_Helper.OnMouseEnterOrg = AuctionPanel.OnMouseEnter
AH_Helper.OnMouseLeaveOrg = AuctionPanel.OnMouseLeave
AH_Helper.OnFrameBreatheOrg = AuctionPanel.OnFrameBreathe
AH_Helper.OnLButtonClickOrg = AuctionPanel.OnLButtonClick
AH_Helper.OnExchangeBoxItemOrg = AuctionPanel.OnExchangeBoxItem
AH_Helper.AuctionSellOrg = AuctionPanel.AuctionSell
AH_Helper.UpdateItemPriceInfoOrg = AuctionPanel.UpdateItemPriceInfo
AH_Helper.ApplyLookupOrg = AuctionPanel.ApplyLookup
AH_Helper.OnItemLButtonClickOrg = AuctionPanel.OnItemLButtonClick
AH_Helper.OnItemLButtonDBClickOrg = AuctionPanel.OnItemLButtonDBClick
AH_Helper.OnItemMouseEnterOrg = AuctionPanel.OnItemMouseEnter
AH_Helper.OnItemMouseLeaveOrg = AuctionPanel.OnItemMouseLeave
AH_Helper.OnEditChangedOrg = AuctionPanel.OnEditChanged
AH_Helper.InitOrg = AuctionPanel.Init
AH_Helper.ShowNoticeOrg = AuctionPanel.ShowNotice
AH_Helper.UpdateSaleInfoOrg = AuctionPanel.UpdateSaleInfo
--------------------------------------------------------
-- AH函数重构
--------------------------------------------------------
local function FormatMoney(handle, bText)
	local szMoney = 0
	if bText then
		szMoney = handle
	else
		szMoney = handle:GetText()
	end
	if not szMoney or szMoney == "" then
		szMoney = 0
	end
	return tonumber(szMoney)
end

local function FormatBigMoney(nGold)
	if AH_Helper.bFormatMoney then
		local nLen, szGold = GetIntergerBit(nGold), tostring(nGold)
		if nLen > 3 then
			local a = string.sub(szGold, 0, nLen - 3)
			local b = string.sub(szGold, -3)
			return string.format("%s,%s", a, b)
		end
		return szGold
	end
	return nGold
end

function AH_Helper.UpdateItemList(frame, szDataType, tItemInfo)
	if not tItemInfo then
		tItemInfo = {}
	end

	local INI_FILE_PATH = "UI/Config/Default/AuctionItem.ini"
	local player = GetClientPlayer()
	local hList, szItem = nil, nil
	if szDataType == "Search" then
		hList = frame:Lookup("PageSet_Totle/Page_Business/Wnd_Result2", "Handle_List")
		szItem = "Handle_ItemList"
	elseif szDataType == "Bid" then
		hList = frame:Lookup("PageSet_Totle/Page_State/Wnd_Bid", "Handle_BidList")
		szItem = "Handle_BidItemList"
	elseif szDataType == "Sell" then
		hList = frame:Lookup("PageSet_Totle/Page_Auction/Wnd_Auction", "Handle_AList")
		szItem = "Handle_AItemList"
	end
	if szItem == "Handle_ItemList" or "Handle_AItemList" then
        INI_FILE_PATH = "Interface/AH/ui/AH_AuctionItem.ini"
    end
	hList:Clear()
	for k, v in pairs(tItemInfo) do
		bFilterd = false
		if v["Item"] then
			if szDataType == "Search" then
				--卖家屏蔽
				if not AH_Helper.IsInBlackList(v["SellerName"]) then
					--过滤已读秘籍
					if AH_Helper.bFilterRecipe and v["Item"].nGenre == ITEM_GENRE.MATERIAL and v["Item"].nSub == 5 then
						if not IsMystiqueRecipeRead(v["Item"]) then
							local hItem = hList:AppendItemFromIni(INI_FILE_PATH, szItem)
							AuctionPanel.SetSaleInfo(hItem, szDataType, v)
						else
							bFilterd = true
						end
					elseif AH_Helper.bFilterBook and v["Item"].nGenre == ITEM_GENRE.BOOK then
						local nBookID, nSegmentID = GlobelRecipeID2BookID(v["Item"].nBookID)
						if not GetClientPlayer().IsBookMemorized(nBookID, nSegmentID) then
							local hItem = hList:AppendItemFromIni(INI_FILE_PATH, szItem)
							AuctionPanel.SetSaleInfo(hItem, szDataType, v)
						else
							bFilterd = true
						end
					else
						local hItem = hList:AppendItemFromIni(INI_FILE_PATH, szItem)
						AuctionPanel.SetSaleInfo(hItem, szDataType, v)
					end
				end
			else
				local hItem = hList:AppendItemFromIni(INI_FILE_PATH, szItem)
				AuctionPanel.SetSaleInfo(hItem, szDataType, v)
			end
		else
			Trace("KLUA[ERROR] ui/Config/Default/AuctionPanel.lua UpdateItemList item is nil!!\n")
		end
	end

	AuctionPanel.OnUpdateItemList(hList, szDataType, true)
	AuctionPanel.UpdateItemPriceInfo(hList, szDataType)
	AuctionPanel.UpdateSelectedInfo(frame, szDataType)

	local hWnd = hList:GetParent():GetParent()
	AuctionPanel.OnItemDataInfoUpdate(hWnd, szDataType)

	--历史记录
	if szDataType == "Search" then
		local hEdit = AH_Helper.GetSearchEdit(frame)
		local szKeyName = hEdit:GetText()
		szKeyName = StringReplaceW(szKeyName, " ", "")
		if not AH_Helper.IsInHistory(szKeyName) and szKeyName ~= L("STR_HELPER_ITEMNAME") and szKeyName ~= "" then
			AH_Helper.AddHistory(szKeyName)
		end
	end
end

function AH_Helper.SetSaleInfo(hItem, szDataType, tItemData)
	local player = GetClientPlayer()
	local tInfo = tItemWidgetInfo[szDataType]
	local item = tItemData["Item"]

	local nIconID = Table_GetItemIconID(item.nUiId)
	local hBox = hItem:Lookup(tInfo.Box)
	local hTextName = hItem:Lookup(tInfo.Text)
	local hTextSaler = hItem:Lookup(tInfo.Saler)

	hItem.nItemID = item.dwID	--Fix Bug:日月明尊
	hItem.nUiId = item.nUiId
	hItem.nSaleID = tItemData["ID"]
	hItem.nCRC = tItemData["CRC"]
	hItem.szItemName = GetItemNameByItem(item)
	hItem.szBidderName = tItemData["BidderName"] or ""
	hItem.szSellerName = tItemData["SellerName"]
	hItem.tBidPrice = tItemData["Price"]
	hItem.tBuyPrice = tItemData["BuyItNowPrice"]

	if MoneyOptCmp(hItem.tBuyPrice, 0) == 0 then
		hItem.tBuyPrice = PRICE_LIMITED
	end

	local nCount = 1
	if item.nGenre == ITEM_GENRE.EQUIPMENT then
		if item.nSub == EQUIPMENT_SUB.ARROW then --远程武器
			nCount = item.nCurrentDurability
		else
			hBox:SetOverText(1, item.nLevel)
		end
	elseif item.bCanStack then
		nCount = item.nStackNum
	end

	if nCount == 1 then
		hBox:SetOverText(0, "")
	else
		hBox:SetOverText(0, nCount)
	end
	hItem.nCount = nCount

	--附加TIP所需数据到box
	hBox.nItemID = item.dwID
	hBox.tBidPrice = tItemData["Price"]
	hBox.tBuyPrice = tItemData["BuyItNowPrice"]
	hBox.nCount = nCount

	--价格记录
	if szDataType == "Search" then
		local szKey = hItem.szItemName	--改nUiId为name可以解决书籍的出价问题
		--local dwID = (item.nGenre == ITEM_GENRE.BOOK) and item.dwID or nil
		if AH_Helper.tItemPrice[szKey] == nil or AH_Helper.tItemPrice[szKey][2] ~= AH_Helper.nVersion then
			AH_Helper.tItemPrice[szKey] = {PRICE_LIMITED, AH_Helper.nVersion}
		end
		if MoneyOptCmp(hItem.tBuyPrice, PRICE_LIMITED) ~= 0 then
			local tBuyPrice = MoneyOptDiv(hItem.tBuyPrice, hItem.nCount)
			--最低一口
			if MoneyOptCmp(AH_Helper.tItemPrice[szKey][1], tBuyPrice) == 1 then
				AH_Helper.tItemPrice[szKey][1] = tBuyPrice
				if bAutoSearch then
					local szMoney = GetMoneyText(GoldSilverAndCopperToMoney(UnpackMoney(tBuyPrice)), "font=10")
					local szColor = GetItemFontColorByQuality(item.nQuality, true)
					local szItem = MakeItemInfoLink(string.format("[%s]", szKey), string.format("font=10 %s", szColor), item.nVersion, item.dwTabType, item.dwIndex)
					AH_Library.Message({szItem, "最低价：", szMoney}, true)
				end
			end
		end
	end

	hTextName:SetText(hItem.szItemName)
	hTextName:SetFontColor(GetItemFontColorByQuality(item.nQuality, false))

	hBox:SetObject(UI_OBJECT_ITEM_INFO, item.nVersion, item.dwTabType, item.dwIndex)
	hBox:SetObjectIcon(nIconID)
	UpdateItemBoxExtend(hBox, item.nGenre, item.nQuality, item.nStrengthLevel)
	hBox:SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
	hBox:SetOverTextFontScheme(0, 15)
	hBox:SetOverTextPosition(1, ITEM_POSITION.LEFT_TOP)
	hBox:SetOverTextFontScheme(1, 16)

	hItem:Lookup(tInfo.Level):SetText(item.GetRequireLevel())
	if szDataType == "Sell" then
		if hItem.szBidderName == "" then
			hTextSaler:SetText(L("STR_HELPER_NOBODY"))
			hTextSaler:SetFontColor(255, 0, 0)
		else
			hTextSaler:SetText(hItem.szBidderName)
			hTextSaler:SetFontColor(0, 200, 0)
		end
	else
		hTextSaler:SetText(tItemData["SellerName"])
	end

	local nGold, nSliver, nCopper = UnpackMoney(hItem.tBidPrice)
	hItem:Lookup(tInfo.aBidText[1]):SetText(FormatBigMoney(nGold))
	hItem:Lookup(tInfo.aBidText[2]):SetText(nSliver)
	hItem:Lookup(tInfo.aBidText[3]):SetText(nCopper)

	if MoneyOptCmp(hItem.tBuyPrice, PRICE_LIMITED) ~= 0 then
		nGold, nSliver, nCopper = UnpackMoney(hItem.tBuyPrice)
		hItem:Lookup(tInfo.aBuyText[1]):SetText(FormatBigMoney(nGold))
		hItem:Lookup(tInfo.aBuyText[2]):SetText(nSliver)
		hItem:Lookup(tInfo.aBuyText[3]):SetText(nCopper)
	else
		hItem:Lookup(tInfo.aBuyImg[1]):Hide()
		hItem:Lookup(tInfo.aBuyImg[2]):Hide()
		hItem:Lookup(tInfo.aBuyImg[3]):Hide()
		hItem:Lookup(tInfo.aBuyText[4]):Hide()
	end

	--竞拍时间显示秒
	local nLeftTime = tItemData["LeftTime"]
	local hTextTime = hItem:Lookup(tInfo.Time)
	local szTime = AuctionPanel.FormatAuctionTime(nLeftTime)
	if nLeftTime <= 120 then
		hTextTime:SetText(L("STR_HELPER_SECOND", nLeftTime))
		hTextTime:SetFontColor(255, 0, 0)
	else
		hTextTime:SetText(szTime)
	end
	--记录拍卖剩余时间
	if not tBidTime[hItem.nSaleID] or tBidTime[hItem.nSaleID].nVersion ~= AH_Helper.nVersion then
		tBidTime[hItem.nSaleID] = {nTime = nLeftTime * 1000 + GetTickCount(), nVersion = AH_Helper.nVersion}
	end
	hItem:Show()
end

function AH_Helper.FormatAuctionTime(nTime)
	local szText = ""
	local nH, nM, nS = GetTimeToHourMinuteSecond(nTime, false)
	if nH and nH > 0 then
		if (nM and nM > 0) or (nS and nS > 0) then
			nH = nH + 1
		end
		szText = szText..nH..g_tStrings.STR_BUFF_H_TIME_H
	else
		nM = nM or 0
		nS = nS or 0
		if nM == 0 and nS == 0 then
			return szText
		end

		if nS > 0 then
			nM = nM + 1
		end

		if nM >= 60 then
			szText = szText..math.ceil(nM / 60)..g_tStrings.STR_BUFF_H_TIME_H
		else
			szText = szText..nM..g_tStrings.STR_BUFF_H_TIME_M
		end
	end

	return szText
end

--显示即时剩余竞拍时间
function AH_Helper.UpdateAllBidItemTime(frame)
	local tInfo = tItemWidgetInfo["Search"]
	local hList = frame:Lookup("PageSet_Totle/Page_Business/Wnd_Result2", "Handle_List")
	local nCount = hList:GetItemCount()
	for i = 0, nCount - 1, 1 do
		local hItem = hList:Lookup(i)
		local hTextTime = hItem:Lookup(tInfo.Time)
		if tBidTime[hItem.nSaleID] then
			local nLeftTime = math.max(0, math.ceil((tBidTime[hItem.nSaleID].nTime - GetTickCount()) / 1000))
			local szTime = AuctionPanel.FormatAuctionTime(nLeftTime)
			if nLeftTime <= 120 then
				if nLeftTime > 0 then
					hTextTime:SetText(L("STR_HELPER_SECOND", nLeftTime))
				else
					hTextTime:SetText(L("STR_HELPER_SETTLEMENT"))
				end
				hTextTime:SetFontColor(255, 0, 0)
			else
				hTextTime:SetText(szTime)
			end
		end
	end
end

function AH_Helper.UpdatePriceInfo(hList, szDataType)
	local tInfo = tItemWidgetInfo[szDataType]
	local bUnitPrice = AH_Helper.CheckUnitPrice(hList)
	local nCount = hList:GetItemCount()
	local player = GetClientPlayer()

	for i = 0, nCount - 1, 1 do
		local hItem = hList:Lookup(i)
		local tBidPrice = hItem.tBidPrice
		local tBuyPrice = hItem.tBuyPrice

		local hTextBid = hItem:Lookup(tInfo.aBidText[4])
		if bUnitPrice then
			tBidPrice = MoneyOptDiv(hItem.tBidPrice, hItem.nCount)
			tBuyPrice = MoneyOptDiv(hItem.tBuyPrice, hItem.nCount)

			if szDataType == "Search" then
				if hItem.szBidderName == "" then
					hTextBid:SetText(L("STR_HELPER_UNITPRICE"))
				elseif player.szName == hItem.szBidderName then
					hTextBid:SetText(L("STR_HELPER_MYPRICE"))
					hTextBid:SetFontColor(255, 255, 0)
				else
					hTextBid:SetText(hItem.szBidderName)	--显示竞拍者
					hTextBid:SetFontColor(0, 200, 0)
				end
			elseif szDataType == "Bid" then
				hTextBid:SetText(L("STR_HELPER_MYPRICE"))
			elseif szDataType == "Sell" then
				hTextBid:SetText(L("STR_HELPER_UNITPRICE"))
			end

			if MoneyOptCmp(hItem.tBuyPrice, PRICE_LIMITED) ~= 0 then
				hItem:Lookup(tInfo.aBuyText[4]):SetText("")
			end
		else
			if szDataType == "Search" then
				if hItem.szBidderName == "" then
					hTextBid:SetText("")
				elseif player.szName == hItem.szBidderName then
					hTextBid:SetText(L("STR_HELPER_MYPRICE"))
				else
					hTextBid:SetText(hItem.szBidderName)
					hTextBid:SetFontColor(0, 200, 0)
				end
			elseif szDataType == "Bid" then
				hTextBid:SetText(L("STR_HELPER_MYPRICE"))
			elseif szDataType == "Sell" then
				hTextBid:SetText("")
			end

			if MoneyOptCmp(hItem.tBuyPrice, PRICE_LIMITED) ~= 0 then
				hItem:Lookup(tInfo.aBuyText[4]):SetText("")
			end
		end

		local nGold, nSliver, nCopper = UnpackMoney(tBidPrice)
		--hItem:Lookup(tInfo.aBidText[1]):SetText(nGold)
		hItem:Lookup(tInfo.aBidText[1]):SetText(FormatBigMoney(nGold))
		hItem:Lookup(tInfo.aBidText[2]):SetText(nSliver)
		hItem:Lookup(tInfo.aBidText[3]):SetText(nCopper)

		if MoneyOptCmp(hItem.tBuyPrice, PRICE_LIMITED) ~= 0 then
			nGold, nSliver, nCopper = UnpackMoney(tBuyPrice)
			--hItem:Lookup(tInfo.aBuyText[1]):SetText(nGold)
			hItem:Lookup(tInfo.aBuyText[1]):SetText(FormatBigMoney(nGold))
			hItem:Lookup(tInfo.aBuyText[2]):SetText(nSliver)
			hItem:Lookup(tInfo.aBuyText[3]):SetText(nCopper)
		end
	end
end

--无记录时调整寄售时间
function AH_Helper.UpdateSaleInfo(frame, bDefault)
	AH_Helper.UpdateSaleInfoOrg(frame, bDefault)
	if bDefault then
		local hWndSale = frame:Lookup("PageSet_Totle/Page_Auction/Wnd_Sale")
		local handle = hWndSale:Lookup("", "")
		local box = handle:Lookup("Box_Item")
		local textTime = handle:Lookup("Text_Time")
		local textItemName = handle:Lookup("Text_ItemName")
		if not box:IsEmpty() then
			local szItemName = textItemName:GetText()
			if not AH_Helper.tItemPrice[szItemName] then
				local szText = textTime:GetText()
				if szText ~= AH_Helper.szDefaultTime then
					textTime:SetText(AH_Helper.szDefaultTime)
				end
			end
		end
	end
end

function AH_Helper.GetItemSellInfo(szItemName)
	local frame = Station.Lookup("Normal/AuctionPanel")
	local szText = frame:Lookup("PageSet_Totle/Page_Auction/Wnd_Sale", "Text_ItemName"):GetText()
	szItemName = (szItemName == L("STR_HELPER_BOOK")) and szText or szItemName	--书籍名字转化
    if AH_Helper.szDefaultValue == "Btn_Min" then
		for k, v in pairs(AH_Helper.tItemPrice) do
			if szItemName == k and MoneyOptCmp(v[1], PRICE_LIMITED) ~= 0 then
				local u = {szName = k, tBidPrice = 0, tBuyPrice = 0, szTime = AH_Helper.szDefaultTime}
                if AH_Helper.szDefaultValue == "Btn_Min" then
                    AH_Library.Message(L("STR_HELPER_LOWPRICE"))
                    u.tBidPrice = v[1]
                    u.tBuyPrice = v[1]
					if AH_Helper.bLowestPrices then
						if AH_Helper.bPricePercentage then
							u.tBidPrice = MoneyOptMult(u.tBidPrice, AH_Helper.nPricePercentage)
							u.tBuyPrice = MoneyOptMult(u.tBuyPrice, AH_Helper.nPricePercentage)
						else
							--单价判断，防止差价溢出
							if MoneyOptCmp(u.tBidPrice, AH_Helper.nDefaultPrices) == 1 then
								u.tBidPrice = MoneyOptSub(u.tBidPrice, AH_Helper.nDefaultPrices)
							end
							if MoneyOptCmp(u.tBuyPrice, AH_Helper.nDefaultPrices) == 1 then
								u.tBuyPrice = MoneyOptSub(u.tBuyPrice, AH_Helper.nDefaultPrices)
							end
						end
					end
					return u
                end
            end
		end
        AH_Library.Message(L("STR_HELPER_NOITEMPRICE"))
	else
		AH_Library.Message(L("STR_HELPER_SYSTEMPRICE"))
		for k, v in pairs(AuctionPanel.tItemSellInfoCache) do
			if v.szName == szItemName then
				return v
			end
		end
		AH_Library.Message(L("STR_HELPER_NOITEMPRICE"))
    end
	return nil
end

function AH_Helper.OnMouseEnter()
	local szName = this:GetName()
	if szName == "Btn_Sale" then
		AH_Helper.OutputTip(L("STR_HELPER_TIP1"))
	elseif szName == "Btn_History" then
		AH_Helper.OutputTip(L("STR_HELPER_TIP2"))
	end
end

function AH_Helper.OnMouseLeave()
	local szName = this:GetName()
	if szName == "Btn_Sale" then
		HideTip()
	elseif szName == "Btn_History" then
		HideTip()
	end
end

function AH_Helper._OnFrameBreathe()
	AH_Helper.OnFrameBreatheOrg()
	AH_Helper.OnBreathe()
end

function AH_Helper.OnLButtonClick()
	local szName  = this:GetName()
	if szName == "Btn_Search" then
		local hEdit = AH_Helper.GetSearchEdit()
		local szText = hEdit:GetText()
		szText = string.gsub(szText, "^%s*(.-)%s*$", "%1")
		szText = string.gsub(szText, "[%[%]]", "")
		hEdit:SetText(szText)
		bAutoSearch = false
	end
	AH_Helper.OnLButtonClickOrg()
end

function AH_Helper.OnExchangeBoxItem(boxItem, boxDsc, nHandCount, bHand)
	if boxDsc == AH_Helper.boxDsc and not boxItem:IsEmpty() then
		local frame = Station.Lookup("Normal/AuctionPanel")
		if AH_Helper.bDBCtrlSell then
			--[[local tMsg = {
				szName = "AuctionSell3",
				szMessage = L("STR_HELPER_MESSAGE1"),
				{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() AH_Helper.AuctionAutoSell(frame) end, },
				{szOption = g_tStrings.STR_HOTKEY_CANCEL, fnAction = function() AH_Helper.AuctionSellOrg(frame) end,},
			}
			MessageBox(tMsg)]]
			AH_Helper.AuctionAutoSell(frame)
		else
			AH_Helper.AuctionSellOrg(frame)
		end
	else
		AH_Helper.OnExchangeBoxItemOrg(boxItem, boxDsc, nHandCount, bHand)
		AH_Helper.boxDsc = boxDsc
		RemoveUILockItem("Auction")
	end
end

function AH_Helper.OnEditChanged()
	local szName = this:GetName()
	if szName == "Edit_ItemName" and AH_Helper.bAutoSearch then
		local hFocus = Station.GetFocusWindow()
		if hFocus then
			local szName = hFocus:GetName()
			if this:GetTextLength() > 0 and szName == "BigBagPanel" then
				bAutoSearch = true
				AH_Helper.UpdateList(this:GetText(), "", true)
			end
		end
	else
		AH_Helper.OnEditChangedOrg()
	end
end

function AH_Helper.AuctionSell(frame)
	if IsShiftKeyDown() then
		if not AH_Helper.bSellNotice then
			local tMsg =
			{
				szName = "AuctionSell",
				szMessage = L("STR_HELPER_MESSAGE2"),
				{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() AH_Helper.AuctionAutoSell(frame) end, },
				{szOption = g_tStrings.STR_HOTKEY_CANCEL, },
			}
			MessageBox(tMsg)
		else
			AH_Helper.AuctionAutoSell(frame)
		end
	elseif IsAltKeyDown() then
		if not AH_Helper.bSellNotice then
			local tMsg =
			{
				szName = "AuctionSell2",
				szMessage = L("STR_HELPER_MESSAGE2"),
				{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() AH_Helper.AuctionAutoSell2(frame) end, },
				{szOption = g_tStrings.STR_HOTKEY_CANCEL, },
			}
			MessageBox(tMsg)
		else
			AH_Helper.AuctionAutoSell2(frame)
		end
	else
		AH_Helper.AuctionSellOrg(frame)
	end
end

function AH_Helper.UpdateItemPriceInfo(hList,szDataType)
	if szDataType == "Search" then
		AH_Helper.UpdatePriceInfo(hList, szDataType)
		local frame = Station.Lookup("Normal/AuctionPanel")
		local page  = frame:Lookup("PageSet_Totle/Page_Business")
		local hWndResult = page:Lookup("Wnd_Result2")
		local btn  = hWndResult:Lookup("Btn_Next")

		if bFilterd then
			if btn:IsEnabled() then
				OutputMessage("MSG_ANNOUNCE_YELLOW", L("STR_HELPER_ALERT1"))
			else
				OutputMessage("MSG_ANNOUNCE_YELLOW", L("STR_HELPER_ALERT2"))
			end
		end
	else
		AH_Helper.UpdateItemPriceInfoOrg(hList,szDataType)
	end
end

function AH_Helper.ApplyLookup(frame, szType, nSortType, szKey, nStart, bDesc)
    tItemDataInfo[szType].nStart = nStart
    if szType == "Search" and nStart == 1 then
       AH_Helper.nVersion = GetCurrentTime()
    end
    return AH_Helper.ApplyLookupOrg(frame, szType, nSortType, szKey, nStart, bDesc)
end

function AH_Helper.ShowNotice(szNotice, bSure, fun, bCancel, bText)
	if AH_Helper.bNoAllPrompt then
		fun()
	else
		AH_Helper.ShowNoticeOrg(szNotice, bSure, fun, bCancel, bText)
	end
end

function AH_Helper.OnItemLButtonDBClick()
	local szName = this:GetName()
	if szName == "Handle_ItemList" and AH_Helper.bDBClickFastBuy then
		if MoneyOptCmp(this.tBuyPrice, PRICE_LIMITED) ~= 0 then
			AuctionPanel.AuctionBuy(this, "Search")
		end
	elseif szName == "Handle_AItemList" and AH_Helper.bDBClickFastCancel then
		AuctionPanel.AuctionCancel(this)
	else
		AH_Helper.OnItemLButtonDBClickOrg()
	end
end

function AH_Helper.OnItemLButtonClick()
	local szName = this:GetName()
	if szName == "Handle_ItemList" then
		AuctionPanel.Selected(this)
		AuctionPanel.UpdateSelectedInfo(this:GetRoot(), "Search", true)
		if AH_Helper.bFastBid and IsShiftKeyDown() and IsCtrlKeyDown() then
			AuctionPanel.AuctionBid(this)
		elseif AH_Helper.bFastBuy and IsAltKeyDown() and IsCtrlKeyDown() then
			if MoneyOptCmp(this.tBuyPrice, PRICE_LIMITED) ~= 0 then
				AuctionPanel.AuctionBuy(this, "Search")
			end
		end
	elseif szName == "Handle_AItemList" then
		AuctionPanel.Selected(this)
			AuctionPanel.UpdateSelectedInfo(this:GetRoot(), "Sell", true)
		if AH_Helper.bFastCancel and IsAltKeyDown() and IsCtrlKeyDown() then
			AuctionPanel.AuctionCancel(this)
		end
	else
		AH_Helper.OnItemLButtonClickOrg()
	end
end

function AH_Helper.OnItemMouseEnter()
	local szName = this:GetName()
	if szName == "Box_Box" then
		if not this:IsEmpty() then
			AH_Tip.szItemTip = AH_Helper.GetItemTip(this)
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			OutputItemTip(UI_OBJECT_ITEM_ONLY_ID, this.nItemID, nil, nil, {x, y, w, h})
		end
	elseif szName == "Handle_ItemList" then
		this.bOver = true
		AuctionPanel.UpdateBgStatus(this)
	elseif szName == "Handle_AItemList" then
		this.bOver = true
		AuctionPanel.UpdateBgStatus(this)
	else
		AH_Helper.OnItemMouseEnterOrg()
	end
end

function AH_Helper.OnItemMouseLeave()
	local szName = this:GetName()
	if szName == "Box_Box" then
		HideTip()
		AH_Tip.szItemTip = nil
	else
		AH_Helper.OnItemMouseLeaveOrg()
	end
end

function AH_Helper.OnItemRButtonClick()
	local szName = this:GetName()
	if szName == "Box_Item" then
		if not this:IsEmpty() then
			RemoveUILockItem("Auction")
			AuctionPanel.ClearBox(this)
			AuctionPanel.UpdateSaleInfo(this:GetRoot(), true)
		end
	elseif szName == "Handle_ItemList" then
		AuctionPanel.Selected(this)
		local szItemName = this.szItemName
		local szSellerName = this.szSellerName
		local menu = {
			{szOption = L("STR_HELPER_SEARCHALL"), fnAction = function() bAutoSearch = false AH_Helper.UpdateList(szItemName) end,},
			{szOption = L("STR_HELPER_CONTACTSELLER"), fnAction = function() EditBox_TalkToSomebody(szSellerName) end,},
			{szOption = L("STR_HELPER_SHIELDEDSELLER"), fnAction = function() AH_Helper.AddBlackList(szSellerName) AH_Helper.UpdateList() end,},
			{szOption = L("STR_HELPER_ADDTOFAVORITES"), fnAction = function() AH_Helper.AddFavorite(szItemName) end,},
		}
		local m = AH_Helper.GetGuiShiDrop(this)
		if m then
			table.insert(menu, m)
		end
		PopupMenu(menu)
	end
end

--添加按钮
function AH_Helper.AddWidget(frame)
	if not frame then return end
	local page  = frame:Lookup("PageSet_Totle/Page_Business")
	local hWndSrch = page:Lookup("Wnd_Search")
	local temp = Wnd.OpenWindow("Interface\\AH\\ui\\AH_Widget.ini")
	if not hWndSrch:Lookup("Btn_History") then
		local hBtnHistory = temp:Lookup("Btn_History")
		if hBtnHistory then
			local hEdit = AH_Helper.GetSearchEdit(frame)
			hEdit:SetSize(125, 20)
			hBtnHistory:ChangeRelation(hWndSrch, true, true)
			hBtnHistory:SetRelPos(148, 32)
			hBtnHistory.OnLButtonClick = function()
				local xT, yT = hEdit:GetAbsPos()
				local wT, hT = hEdit:GetSize()
				local menu = AH_Helper.GetHistory()
				menu.nMiniWidth = wT + 32
				menu.x = xT - 5
				menu.y = yT + hT
				PopupMenu(menu)
			end
		end
	end

	if not frame:Lookup("Wnd_Side") then
		local hWndSide = temp:Lookup("Wnd_Side")
		if hWndSide then
			hWndSide:ChangeRelation(frame, true, true)
			hWndSide:SetRelPos(960, 8)

			local hBtnPrice = hWndSide:Lookup("Btn_Price")
			hBtnPrice:Lookup("", ""):Lookup("Text_Price"):SetText(L("STR_HELPER_TEXTPRICE"))
			hBtnPrice.OnLButtonClick = function()
				local menu =
				{
					{szOption = L("STR_HELPER_USELOWEST"), bMCheck = true, bChecked = (AH_Helper.szDefaultValue == "Btn_Min"), fnAction = function() AH_Helper.szDefaultValue = "Btn_Min" AH_Helper.SetSellPriceType() end,},
					{szOption = L("STR_HELPER_USESYSTEM"), bMCheck = true, bChecked = (AH_Helper.szDefaultValue == "Btn_Save"), fnAction = function() AH_Helper.szDefaultValue = "Btn_Save" AH_Helper.SetSellPriceType() end,},
				}
				PopupMenu(menu)
			end

			local hBtnFavorite = hWndSide:Lookup("Btn_Favorite")
			hBtnFavorite:Lookup("", ""):Lookup("Text_Favorite"):SetText(L("STR_HELPER_TEXTFAVORITE"))
			hBtnFavorite.OnLButtonClick = function()
				local menu = {}
				local m_1 = {szOption = L("STR_HELPER_FAVORITES")}
				for k, v in pairs(AH_Helper.tItemFavorite) do
					table.insert(m_1,
					{
						szOption = k,
						{szOption = L("STR_HELPER_SEARCH"), fnAction = function() bAutoSearch = false AH_Helper.UpdateList(k, L("STR_HELPER_FAVORITEITEMS")) end,},
						{szOption = L("STR_HELPER_DELETE"), fnAction = function() local szText = L("STR_HELPER_DELETEITEMS", k) AH_Library.Message(szText) AH_Helper.tItemFavorite[k] = nil end,},
					})
				end
				local m_3 = {szOption = L("STR_HELPER_BLACKLIST")}
				for k, v in pairs(AH_Helper.tBlackList) do
					table.insert(m_3,
					{
						szOption = k,
						{szOption = L("STR_HELPER_DELETE"), fnAction = function() local szText = L("STR_HELPER_DELETESELLERS", k) AH_Library.Message(szText) AH_Helper.tBlackList[k] = nil AH_Helper.UpdateList() end,},
					})
				end
				table.insert(menu, m_1)
				table.insert(menu, m_3)
				PopupMenu(menu)
			end

			local hBtnSplit = hWndSide:Lookup("Btn_Split")
			hBtnSplit:Lookup("", ""):Lookup("Text_Split"):SetText(L("STR_HELPER_TEXTSPLIT"))
			hBtnSplit.OnLButtonClick = function()
				local x, y = this:GetAbsPos()
				local w, h = this:GetSize()
				AH_Spliter.OnSplitBoxItem({x, y, w, h})
			end
			hBtnSplit.OnRButtonClick = function()
				AH_Spliter.StackItem()
			end

			local hBtnProduce = hWndSide:Lookup("Btn_Produce")
			hBtnProduce:Lookup("", ""):Lookup("Text_Produce"):SetText(L("STR_HELPER_TEXTPRODUCE"))
			hBtnProduce.OnLButtonClick = function()
				AH_Produce.OpenPanel()
			end

			local hBtnDiamond = hWndSide:Lookup("Btn_Diamond")
			hBtnDiamond:Lookup("", ""):Lookup("Text_Diamond"):SetText(L("STR_HELPER_TEXTDIAMOND"))
			hBtnDiamond.OnLButtonClick = function()
				AH_Diamond.OpenPanel()
			end

			local hBtnOption = hWndSide:Lookup("Btn_Option")
			hBtnOption:Lookup("", ""):Lookup("Text_Option"):SetText(L("STR_HELPER_TEXTOPTION"))
			hBtnOption.OnLButtonClick = function()
				local menu =
				{
					{szOption = L("STR_HELPER_VERSION", AH_Helper.szVersion), fnDisable = function() return true end},
					{ bDevide = true },
					{szOption = L("STR_HELPER_FILTERRECIPE"), bCheck = true, bChecked = AH_Helper.bFilterRecipe, fnAction = function() AH_Helper.bFilterRecipe = not AH_Helper.bFilterRecipe end, fnMouseEnter = function() AH_Helper.OutputTip(L("STR_HELPER_FILTERRECIPETIPS")) end,},
					{szOption = L("STR_HELPER_FILTERBOOK"), bCheck = true,bChecked = AH_Helper.bFilterBook,fnAction = function()AH_Helper.bFilterBook = not AH_Helper.bFilterBook end, fnMouseEnter = function() AH_Helper.OutputTip(L("STR_HELPER_FILTERBOOKTIPS")) end,},
					{ bDevide = true },
					{szOption = L("STR_HELPER_MAXHISTORY"), fnMouseEnter = function() AH_Helper.OutputTip(L("STR_HELPER_MAXHISTORYTIPS")) end,
						{szOption = "5", bMCheck = true, bChecked = (AH_Helper.nMaxHistory == 5), fnAction = function() AH_Helper.nMaxHistory = 5 end,},
						{szOption = "10", bMCheck = true, bChecked = (AH_Helper.nMaxHistory == 10), fnAction = function() AH_Helper.nMaxHistory = 10 end,},
						{szOption = "15", bMCheck = true, bChecked = (AH_Helper.nMaxHistory == 15), fnAction = function() AH_Helper.nMaxHistory = 15 end,},
						{szOption = "20", bMCheck = true, bChecked = (AH_Helper.nMaxHistory == 20), fnAction = function() AH_Helper.nMaxHistory = 20 end,},
					},
					{ bDevide = true },
					{szOption = L("STR_HELPER_SELLTIME"), fnMouseEnter = function() AH_Helper.OutputTip(L("STR_HELPER_SELLTIMETIPS")) end,
						{szOption = L("STR_HELPER_12HOUR"), bMCheck = true, bChecked = (AH_Helper.szDefaultTime == L("STR_HELPER_12HOUR")), fnAction = function() AH_Helper.szDefaultTime = L("STR_HELPER_12HOUR") end,},
						{szOption = L("STR_HELPER_24HOUR"), bMCheck = true, bChecked = (AH_Helper.szDefaultTime == L("STR_HELPER_24HOUR")), fnAction = function() AH_Helper.szDefaultTime = L("STR_HELPER_24HOUR") end,},
						{szOption = L("STR_HELPER_48HOUR"), bMCheck = true, bChecked = (AH_Helper.szDefaultTime == L("STR_HELPER_48HOUR")), fnAction = function() AH_Helper.szDefaultTime = L("STR_HELPER_48HOUR") end,},
					},
					{szOption = L("STR_HELPER_AUTOMATICSPREAD"), bCheck = true, bChecked = AH_Helper.bLowestPrices, fnAction = function() AH_Helper.bLowestPrices = not AH_Helper.bLowestPrices end, fnMouseEnter = function() AH_Helper.OutputTip(L("STR_HELPER_AUTOMATICSPREADTIPS")) end,
						{szOption = L("STR_HELPER_DISCOUNT"), bCheck = true, bChecked = AH_Helper.bPricePercentage, fnDisable = function() return not AH_Helper.bLowestPrices end, fnAction = function() AH_Helper.bPricePercentage = not AH_Helper.bPricePercentage end,
							{szOption = L("STR_HELPER_MODIFY", AH_Helper.nPricePercentage), fnDisable = function() return not AH_Helper.bPricePercentage end, fnAction = function()
									GetUserInput(L("STR_HELPER_INPUTDISCOUNT"), function(szText)
										local n = tonumber(szText)
										if n > 0 then
											AH_Helper.nPricePercentage = n
										end
									end, nil, nil, nil, nil, nil)
								end,
							}
						},
						{ bDevide = true },
						{szOption = L("STR_HELPER_COPPER"), bMCheck = true, bChecked = (AH_Helper.nDefaultPrices == 1), fnDisable = function() return AH_Helper.bPricePercentage or not AH_Helper.bLowestPrices end, fnAction = function() AH_Helper.nDefaultPrices = 1 end,},
						{szOption = L("STR_HELPER_SLIVER"), bMCheck = true, bChecked = (AH_Helper.nDefaultPrices == 1 * 100), fnDisable = function() return AH_Helper.bPricePercentage or not AH_Helper.bLowestPrices end, fnAction = function() AH_Helper.nDefaultPrices = 1 * 100 end,},
						{szOption = L("STR_HELPER_GOLD"), bMCheck = true, bChecked = (AH_Helper.nDefaultPrices == 100 * 100), fnDisable = function() return AH_Helper.bPricePercentage or not AH_Helper.bLowestPrices end, fnAction = function() AH_Helper.nDefaultPrices = 100 * 100 end,},
					},
					{ bDevide = true },
					{szOption = L("STR_HELPER_NOALLPROMPT"), bCheck = true, bChecked = AH_Helper.bNoAllPrompt, fnAction = function() AH_Helper.bNoAllPrompt = not AH_Helper.bNoAllPrompt end, fnMouseEnter = function() AH_Helper.OutputTip(L("STR_HELPER_NOALLPROMPTTIPS")) end,
						{szOption = L("STR_HELPER_NOSELLNOTICE"), bCheck = true, bChecked = AH_Helper.bSellNotice, fnAction = function() AH_Helper.bSellNotice = not AH_Helper.bSellNotice end,},
						{szOption = L("STR_HELPER_DBCTRLSELL"), bCheck = true, bChecked = AH_Helper.bDBCtrlSell, fnAction = function() AH_Helper.bDBCtrlSell = not AH_Helper.bDBCtrlSell end,},
					},
					{ bDevide = true },
					{szOption = L("STR_HELPER_FASTBID"), bCheck = true, bChecked = AH_Helper.bFastBid, fnAction = function() AH_Helper.bFastBid = not AH_Helper.bFastBid end, fnMouseEnter = function() AH_Helper.OutputTip(L("STR_HELPER_FASTBIDTIPS")) end,},
					{szOption = L("STR_HELPER_FASTBUY"), bCheck = true, bChecked = AH_Helper.bFastBuy, fnAction = function() AH_Helper.bFastBuy = not AH_Helper.bFastBuy end, fnMouseEnter = function() AH_Helper.OutputTip(L("STR_HELPER_FASTBUYTIPS")) end,
						{szOption = L("STR_HELPER_DBCLICKTYPE"), bCheck = true, bChecked = AH_Helper.bDBClickFastBuy, fnAction = function() AH_Helper.bDBClickFastBuy = not AH_Helper.bDBClickFastBuy end,},
					},
					{szOption = L("STR_HELPER_FASTCANCEL"), bCheck = true, bChecked = AH_Helper.bFastCancel, fnAction = function() AH_Helper.bFastCancel = not AH_Helper.bFastCancel end, fnMouseEnter = function() AH_Helper.OutputTip(L("STR_HELPER_FASTCANCELTIPS")) end,
						{szOption = L("STR_HELPER_DBCLICKTYPE"), bCheck = true, bChecked = AH_Helper.bDBClickFastCancel, fnAction = function() AH_Helper.bDBClickFastCancel = not AH_Helper.bDBClickFastCancel end,},
					},
					{ bDevide = true },
					{szOption = L("STR_HELPER_AUTOSEARCH"), bCheck = true, bChecked = AH_Helper.bAutoSearch, fnAction = function() AH_Helper.bAutoSearch = not AH_Helper.bAutoSearch end, fnMouseEnter = function() AH_Helper.OutputTip(L("STR_HELPER_AUTOSEARCHTIPS")) end,},
					{szOption = L("STR_HELPER_FORMATMONEY"), bCheck = true, bChecked = AH_Helper.bFormatMoney, fnAction = function() AH_Helper.bFormatMoney = not AH_Helper.bFormatMoney end, fnMouseEnter = function() AH_Helper.OutputTip(L("STR_HELPER_FORMATMONEYTIPS")) end,},
					{szOption = L("STR_HELPER_SHOWTIPEX"), bCheck = true, bChecked = AH_Tip.bShowTipEx, fnAction = function() AH_Tip.bShowTipEx = not AH_Tip.bShowTipEx end, fnMouseEnter = function() AH_Helper.OutputTip(L("STR_HELPER_SHOWTIPEXTIPS")) end,},
					{ bDevide = true },
					{szOption = L("STR_HELPER_RESETPRICE"), fnAction = function() AH_Helper.tItemPrice = {} AH_Library.Message(L("STR_HELPER_RESETPRICETIPS")) end,},
				}
				PopupMenu(menu)
			end
		end
	end
	Wnd.CloseWindow(temp)

	local nW, nH = frame:GetSize()
	frame:SetSize(nW + 56, nH)
end

function AH_Helper.OutputTip(szText, nFont)
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	OutputTip(GetFormatText(szText, nFont or 18), 300, {x, y, w, h})
end

function AH_Helper.GetGuiShiDrop(hItem)
	local item = GetItem(hItem.nItemID)
	local tItemInfo = GetItemInfo(item.dwTabType, item.dwIndex)
	local tDesc = Table_GetItemDesc(item.nUiId)
	if string.find(tDesc, L("STR_HELPER_ADDITIONALDROP")) then
		local m = {szOption = L("STR_HELPER_VIEWDROP")}
		local drops = string.gsub(tDesc,  "this\.dwTabType\=(%d+) this.dwIndex=(%d+) ", function(k, v)
			local itm = GetItemInfo(k, v)
			table.insert(m, {
				szOption = itm.szName,
				fnMouseEnter = function()
					local x, y = this:GetAbsPos()
					local w, h = this:GetSize()
					OutputItemTip(UI_OBJECT_ITEM_INFO, 0, k, v, {x, y, w, h}, false)
				end,
			})
		end)
		return m
	end
	return nil
end

function AH_Helper.SetSellPriceType()
	local hWndSide = Station.Lookup("Normal/AuctionPanel"):Lookup("Wnd_Side")
	local hText = hWndSide:Lookup("Btn_Price"):Lookup("", ""):Lookup("Text_Price")
	if AH_Helper.szDefaultValue == "Btn_Min" then
        hText:SetText(L("STR_HELPER_LOWEST"))
    elseif AH_Helper.szDefaultValue == "Btn_Save" then
        hText:SetText(L("STR_HELPER_SYSTEM"))
    end
end

function AH_Helper.AuctionAutoSell(frame)
	local hWndSale  = frame:Lookup("PageSet_Totle/Page_Auction/Wnd_Sale")
	local handle    = hWndSale:Lookup("", "")
	local box       = handle:Lookup("Box_Item")
	local text      = handle:Lookup("Text_Time")
	local szTime    = text:GetText()
	local nTime     = tonumber(string.sub(szTime, 1, 2))
	local tBidPrice = nil
	local tBuyPrice = nil
	local player    = GetClientPlayer()

	local item = GetPlayerItem(player, box.dwBox, box.dwX);
	if not item or item.szName ~= box.szName then
		AuctionPanel.ClearBox(box)
		AuctionPanel.UpdateSaleInfo(frame, true)
		RemoveUILockItem("Auction")
		OutputMessage("MSG_ANNOUNCE_RED", L("STR_HELPER_SELLERROR"))
		return
	end
	local nGold   = FormatMoney(hWndSale:Lookup("Edit_OPGold"))
	local nSliver = FormatMoney(hWndSale:Lookup("Edit_OPSilver"))
	local nCopper = FormatMoney(hWndSale:Lookup("Edit_OPCopper"))
	tBidPrice = PackMoney(nGold, nSliver, nCopper)

	nGold   = FormatMoney(hWndSale:Lookup("Edit_PGold"))
	nSliver = FormatMoney(hWndSale:Lookup("Edit_PSilver"))
	nCopper = FormatMoney(hWndSale:Lookup("Edit_PCopper"))
	tBuyPrice = PackMoney(nGold, nSliver, nCopper)

	box.szTime = szTime
	box.tBidPrice = tBidPrice
	box.tBuyPrice = tBuyPrice

	local nStackNum = item.nStackNum
	local tSBidPrice = MoneyOptDiv(tBidPrice, nStackNum)
	local tSBuyPrice = MoneyOptDiv(tBuyPrice, nStackNum)
	local AtClient = GetAuctionClient()
	FireEvent("SELL_AUCTION_ITEM")

	for i = 1, 6 do
		if player.GetBoxSize(i) > 0 then
			for j = 0, player.GetBoxSize(i) - 1 do
				local item2 = player.GetItem(i, j)
				if item2 and GetItemNameByItem(item2) == GetItemNameByItem(item) then
					if item2.nStackNum <= nStackNum then
						local tBidPrice2 = MoneyOptMult(tSBidPrice, item2.nStackNum)
						local tBuyPrice2 = MoneyOptMult(tSBuyPrice, item2.nStackNum)
						AtClient.Sell(AuctionPanel.dwTargetID, i, j, tBidPrice2.nGold, tBidPrice2.nSilver, tBidPrice2.nCopper, tBuyPrice2.nGold, tBuyPrice2.nSilver, tBuyPrice2.nCopper, nTime)
					end
				end
			end
		end
	end
	PlaySound(SOUND.UI_SOUND, g_sound.Trade)
end

local function IsSameSellItem(item1, item2)
	if item1.nGenre == ITEM_GENRE.BOOK then
		if item2 and item1.nQuality == item2.nQuality and item1.nGenre == item2.nGenre and item1.szName == item2.szName then
			return true
		end
		return false
	elseif item1.nGenre == ITEM_GENRE.MATERIAL and item1.nSub == 5 then
		if item2 and item1.nQuality == item2.nQuality and item1.nGenre == item2.nGenre and item1.nSub == item2.nSub then
			return true
		end
		return false
	elseif item1.nGenre == ITEM_GENRE.COLOR_DIAMOND then
		if item2 and item1.nQuality == item2.nQuality and item1.nGenre == item2.nGenre then
			local szName1, szName2 = GetItemNameByItem(item1), GetItemNameByItem(item2)
			local _, _, _, szLevel1 = szName1:match(L("STR_HELPER_COLORDIAMOND"))
			local _, _, _, szLevel2 = szName2:match(L("STR_HELPER_COLORDIAMOND"))
			if szLevel1 == szLevel2 then
				return true
			end
			return false
		end
		return false
	end
	return false
end

function AH_Helper.AuctionAutoSell2(frame)
	local hWndSale  = frame:Lookup("PageSet_Totle/Page_Auction/Wnd_Sale")
	local handle    = hWndSale:Lookup("", "")
	local box       = handle:Lookup("Box_Item")
	local text      = handle:Lookup("Text_Time")
	local szTime    = text:GetText()
	local nTime     = tonumber(string.sub(szTime, 1, 2))
	local tBidPrice = nil
	local tBuyPrice = nil
	local player    = GetClientPlayer()

	local item = GetPlayerItem(player, box.dwBox, box.dwX);
	if not item or item.szName ~= box.szName then
		AuctionPanel.ClearBox(box)
		AuctionPanel.UpdateSaleInfo(frame, true)
		RemoveUILockItem("Auction")
		OutputMessage("MSG_ANNOUNCE_RED", L("STR_HELPER_SELLERROR"))
		return
	end
	local nGold   = FormatMoney(hWndSale:Lookup("Edit_OPGold"))
	local nSliver = FormatMoney(hWndSale:Lookup("Edit_OPSilver"))
	local nCopper = FormatMoney(hWndSale:Lookup("Edit_OPCopper"))
	tBidPrice = PackMoney(nGold, nSliver, nCopper)

	nGold   = FormatMoney(hWndSale:Lookup("Edit_PGold"))
	nSliver = FormatMoney(hWndSale:Lookup("Edit_PSilver"))
	nCopper = FormatMoney(hWndSale:Lookup("Edit_PCopper"))
	tBuyPrice = PackMoney(nGold, nSliver, nCopper)

	box.szTime = szTime
	box.tBidPrice = tBidPrice
	box.tBuyPrice = tBuyPrice

	local nStackNum = item.bCanStack and item.nStackNum or 1	--修复不可叠加类物品定价错误
	local tSBidPrice = MoneyOptDiv(tBidPrice, nStackNum)
	local tSBuyPrice = MoneyOptDiv(tBuyPrice, nStackNum)
	local AtClient = GetAuctionClient()
	FireEvent("SELL_AUCTION_ITEM")

	for i = 1, 6 do
		if player.GetBoxSize(i) > 0 then
			for j = 0, player.GetBoxSize(i) - 1 do
				local item2 = player.GetItem(i, j)
				if IsSameSellItem(item, item2) then
					local nStack = item2.bCanStack and item2.nStackNum or 1
					local tBidPrice2 = MoneyOptMult(tSBidPrice, nStack)
					local tBuyPrice2 = MoneyOptMult(tSBuyPrice, nStack)
					AtClient.Sell(AuctionPanel.dwTargetID, i, j, tBidPrice2.nGold, tBidPrice2.nSilver, tBidPrice2.nCopper, tBuyPrice2.nGold, tBuyPrice2.nSilver, tBuyPrice2.nCopper, nTime)
				end
			end
		end
	end
	PlaySound(SOUND.UI_SOUND, g_sound.Trade)
end

function AH_Helper.UpdateList(szItemName, szType, bNotInit)
	if not szItemName then
		szItemName = ""
	end
	local t = tItemDataInfo["Search"]
	local frame = Station.Lookup("Normal/AuctionPanel")
	AuctionPanel.tSearch = tSearchInfoDefault
	AuctionPanel.tSearch["Name"] = szItemName
	if not bNotInit then
		AuctionPanel.InitSearchInfo(frame, AuctionPanel.tSearch)
	end
	AuctionPanel.SaveSearchInfo(frame)

	if szType and szType ~= "" then
		local szText = L("STR_HELPER_SEARCHITEM", szType, szItemName)
		AH_Library.Message(szText)
	end
	AuctionPanel.ApplyLookup(frame, "Search", t.nSortType, "", 1, t.bDesc)
end

function AH_Helper.CheckUnitPrice(hList)
	local frame = hList:GetRoot()
	local hWndRes = frame:Lookup("PageSet_Totle/Page_Business/Wnd_Result2")
	local hCheckboxPerValue = hWndRes:Lookup("CheckBox_PerValue")
	local bChecked = hCheckboxPerValue:IsCheckBoxChecked()
	if bChecked then
		return true
	end
	return false
end

function AH_Helper.IsInBlackList(szSellerName)
	for k, v in pairs(AH_Helper.tBlackList) do
		if k == szSellerName then
			return true
		end
	end
	return false
end

function AH_Helper.IsInHistory(szKeyName)
	for k, v in pairs(AH_Helper.tItemHistory) do
		if v.szName == szKeyName then
			return true
		end
	end
	return false
end

function AH_Helper.AddFavorite(szItemName)
    AH_Helper.tItemFavorite[szItemName] = 1
	local szText = L("STR_HELPER_BEADDTOFAVORITES", szItemName)
    AH_Library.Message(szText)
end

function AH_Helper.AddBlackList(szSellerName)
    AH_Helper.tBlackList[szSellerName] = 1
    local szText = L("STR_HELPER_BEADDTOBLACKLIST", szSellerName)
	AH_Library.Message(szText)
end

function AH_Helper.AddHistory(szKeyName)
	local index = nil
	for k, v in pairs(AH_Helper.tItemHistory) do
		if v.szName == szKeyName then
			index = k
			break
		end
	end
	if index then
		table.remove(AH_Helper.tItemHistory, index)
	end
	table.insert(AH_Helper.tItemHistory, {szName = szKeyName})
	local nCount = table.getn(AH_Helper.tItemHistory)
	if nCount > AH_Helper.nMaxHistory then
		table.remove(AH_Helper.tItemHistory, 1)
	end
end

function AH_Helper.GetItemTip(hItem)
	local player, szTip = GetClientPlayer(), ""
	local item = GetItem(hItem.nItemID)
	if item then
		local nItemCountInPackage = player.GetItemAmount(item.dwTabType, item.dwIndex)
		local nItemCountTotal = player.GetItemAmountInAllPackages(item.dwTabType, item.dwIndex)
		local nItemCountInBank = nItemCountTotal - nItemCountInPackage

		szTip = szTip .. GetFormatText(L("STR_TIP_TOTAL"), 101) .. GetFormatText(nItemCountTotal, 162)
		szTip = szTip .. GetFormatText(L("STR_TIP_BAG"), 101) .. GetFormatText(nItemCountInPackage, 162) .. GetFormatText(L("STR_TIP_BANk"), 101) .. GetFormatText(nItemCountInBank, 162)

		--配方
		if item.nGenre == ITEM_GENRE.MATERIAL then
			szTip = szTip .. AH_Tip.GetRecipeTip(player, item)
		end

		if MoneyOptCmp(hItem.tBuyPrice, 0) == 1 and MoneyOptCmp(hItem.tBuyPrice, PRICE_LIMITED) ~= 0 then
			if AH_Helper.GetCheckPervalue() then
				szTip = szTip .. GetFormatText("\n" .. L("STR_HELPER_PRICE1"), 157) .. GetMoneyTipText(hItem.tBuyPrice, 106)
			else
				szTip = szTip .. GetFormatText("\n" .. L("STR_HELPER_PRICE2"), 157) .. GetMoneyTipText(MoneyOptDiv(hItem.tBuyPrice, hItem.nCount), 106)
			end
		end
		--szTip = szTip .. GetFormatText("\n"..item.dwID .. "-" .. GetItemNameByItem(GetItem(item.dwID)))
	end
	return szTip
end

function AH_Helper.GetHistory()
	local menu = {}
	local nCount = table.getn(AH_Helper.tItemHistory)
	for i = nCount, 1, -1 do
		local m = {
			szOption = AH_Helper.tItemHistory[i].szName,
			fnAction = function()
				bAutoSearch = false
				AH_Helper.UpdateList(AH_Helper.tItemHistory[i].szName)
			end,
		}
		table.insert(menu, m)
	end
	table.insert(menu, {bDevide = true})
	local d = {
		szOption = L("STR_HELPER_CLEARHISTORY"),
		fnAction = function()
			AH_Helper.tItemHistory = {}
		end,
	}
	table.insert(menu, d)

	return menu
end

function AH_Helper.GetSearchEdit(frame)
	if not frame then
		frame = Station.Lookup("Normal/AuctionPanel")
	end
	local hWndSch = frame:Lookup("PageSet_Totle/Page_Business/Wnd_Search")
	if hWndSch then
		return hWndSch:Lookup("Edit_ItemName")
	end
	return nil
end

function AH_Helper.GetCheckPervalue(frame)
	if not frame then
		frame = Station.Lookup("Normal/AuctionPanel")
	end
	local hWndRes = frame:Lookup("PageSet_Totle/Page_Business/Wnd_Result2")
	if hWndRes then
		return hWndRes:Lookup("CheckBox_PerValue"):IsCheckBoxChecked()
	end
	return nil
end

function AH_Helper.OnBreathe()
	local frame = Station.Lookup("Normal/AuctionPanel")
	if not frame then
		return
	end
	AH_Helper.UpdateAllBidItemTime(frame)
end

function AuctionPanel.Init(frame)
	AH_Helper.InitOrg(frame)
	--默认单价
	local hWndRes = frame:Lookup("PageSet_Totle/Page_Business/Wnd_Result2")
	local hCheckPervalue = hWndRes:Lookup("CheckBox_PerValue")
	local hCheckPrice = hWndRes:Lookup("CheckBox_Price")
	hCheckPervalue:Check(true)
	AuctionPanel.OnSortStateUpdate(hCheckPrice)
	if hCheckPrice:Lookup("", "Image_PriceNameDown"):IsVisible() then
		AuctionPanel.OnSortStateUpdate(hCheckPrice)
	end
	AH_Helper.AddWidget(frame)
	--Hook
	if not bHooked then
		AH_Helper.FuncHook()
		bHooked = true
	end
end

function AH_Helper.FuncHook()
	AuctionPanel.UpdateItemList = AH_Helper.UpdateItemList
	AuctionPanel.SetSaleInfo = AH_Helper.SetSaleInfo
	AuctionPanel.FormatAuctionTime = AH_Helper.FormatAuctionTime
	AuctionPanel.GetItemSellInfo = AH_Helper.GetItemSellInfo
	AuctionPanel.OnMouseEnter = AH_Helper.OnMouseEnter
	AuctionPanel.OnMouseLeave = AH_Helper.OnMouseLeave
	AuctionPanel.OnFrameBreathe = AH_Helper._OnFrameBreathe
	AuctionPanel.OnLButtonClick = AH_Helper.OnLButtonClick
	AuctionPanel.OnExchangeBoxItem = AH_Helper.OnExchangeBoxItem
	AuctionPanel.AuctionSell = AH_Helper.AuctionSell
	AuctionPanel.UpdateItemPriceInfo = AH_Helper.UpdateItemPriceInfo
	AuctionPanel.ApplyLookup = AH_Helper.ApplyLookup
	AuctionPanel.OnItemLButtonClick = AH_Helper.OnItemLButtonClick
	AuctionPanel.OnItemLButtonDBClick = AH_Helper.OnItemLButtonDBClick
	AuctionPanel.OnItemRButtonClick = AH_Helper.OnItemRButtonClick
	AuctionPanel.OnItemMouseEnter = AH_Helper.OnItemMouseEnter
	AuctionPanel.OnItemMouseLeave = AH_Helper.OnItemMouseLeave
	AuctionPanel.OnEditChanged = AH_Helper.OnEditChanged
	AuctionPanel.ShowNotice = AH_Helper.ShowNotice
	AuctionPanel.UpdateSaleInfo = AH_Helper.UpdateSaleInfo
end

function AH_Helper.VerifyVersion()
	local player = GetClientPlayer()
	if not player or not AH_Library.bCheckVersion then
		return
	end
	local nTime = GetCurrentTime()
	local t = TimeToDate(nTime)
	local szDate = string.format("%d-%d-%d", t.year, t.month, t.day)
	--local szName = StringFindW(player.szName, "@") and player.szName:match("(.+)@") or player.szName
	local szName = base64(player.szName)
	local szUrl = string.format("http://jx3auction.duapp.com/verify?uid=%d&user=%s&version=%s", player.dwID, base64(szName), AH_Helper.szVersion)
	--Output(szUrl)
	if szDate == AH_Helper.tVerify["szDate"] and AH_Helper.tVerify["bChecked"] then
		return
	end
	AH_Helper.tVerify["bChecked"] = false
	local page = Station.Lookup("Lowest/AH_Library/Page_IE")
	if page then
		page:Navigate(szUrl)
		AH_Helper.tVerify["szDate"] = szDate
		AH_Helper.tVerify["bChecked"] = true
	end
end

RegisterEvent("LOGIN_GAME", function()
	if IsFileExist(AH_Helper.szDataPath) then
		AH_Helper.tItemPrice = LoadLUAData(AH_Helper.szDataPath)
	end
end)

RegisterEvent("GAME_EXIT", function()
	SaveLUAData(AH_Helper.szDataPath, AH_Helper.tItemPrice)
end)

RegisterEvent("PLAYER_EXIT_GAME", function()
	SaveLUAData(AH_Helper.szDataPath, AH_Helper.tItemPrice)
end)

RegisterEvent("OPEN_AUCTION", function()
	local bNotExistOtherAddon = false
	if AuctionTip and AuctionTip.bFilter then
		AuctionTip.bFilter = false
		bNotExistOtherAddon = true
	elseif HM_ToolBox and HM_ToolBox.bShiftAuction then
		HM_ToolBox.bShiftAuction = false
		bNotExistOtherAddon = true
	end
	if bNotExistOtherAddon then
		AH_Library.Message(L("STR_HELPER_INCOMPATIBLETIPS"))
		AH_Helper.FuncHook()
	end
	AH_Helper.SetSellPriceType()
	AH_Helper.VerifyVersion()
end)

Hotkey.AddBinding("AH_Produce_Open", L("STR_PRODUCE_PRODUCEHELPER"), L("STR_HELPER_HELPER"), function() AH_Produce.OpenPanel() end, nil)
Hotkey.AddBinding("AH_Diamond_Open", L("STR_DIAMOND_DIAMONDHELPER"), "", function() AH_Diamond.OpenPanel() end, nil)
Hotkey.AddBinding("AH_Spliter_Open", L("STR_HELPER_SLPITITEM"), "", function() AH_Spliter.OnSplitBoxItem() end, nil)
Hotkey.AddBinding("AH_Spliter_StackItem", L("STR_HELPER_STACKITEM"), "", function() AH_Spliter.StackItem() end, nil)
