------------------------------------------------------
-- #模块名：交易行模块
-- #模块说明：交易行各类功能的增强
------------------------------------------------------

local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber
--------------------------------------------------------
-- 插件配置
--------------------------------------------------------
AH_Helper = {
	szDefaultValue = "Btn_Min",
	szDefaultTime = "24小时",
	szLastSearchKey = nil,

	nVersion = 0,
	nPricePercentage = 0.95,
	nDefaultPrices = 1,
	nMaxHistory = 10,
	nShowTipType = 1,

	bFastBid = true,
	bFastBuy = true,
	bFastCancel = true,
	bNoAllPrompt = false,
	bPricePercentage = false,
	bLowestPrices = true,
	bFilterRecipe = false,
	bFilterBook = false,
	bAutoSearch = true,
	bSaleAlert = false,
	bSellNotice = false,
	nShowTipType = 1,

	tItemFavorite = {},
	tBlackList = {},
	tItemHistory = {},
	tItemPrice = {},

	szDataPath = "\\Interface\\AH\\data\\data.AH",
	szVersion = "2.0.2",		--用于版本检测
}


--------------------------------------------------------
-- 交易行数据缓存
--------------------------------------------------------
local tBidTime = {}
local bFilterd = false
local bHooked = false

--------------------------------------------------------
-- 用户数据存储
--------------------------------------------------------
RegisterCustomData("AH_Helper.szDefaultValue")
RegisterCustomData("AH_Helper.szDefaultTime")
RegisterCustomData("AH_Helper.nDefaultPrices")
RegisterCustomData("AH_Helper.nMaxHistory")
RegisterCustomData("AH_Helper.nShowTipType")
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
RegisterCustomData("AH_Helper.tItemHistory")
RegisterCustomData("AH_Helper.tItemFavorite")
RegisterCustomData("AH_Helper.tBlackList")
--------------------------------------------------------
-- AH局部变量初始化
--------------------------------------------------------
local PRICE_LIMITED = PackMoney(9000000, 0, 0)
local MAX_BID_PRICE = PackMoney(800000, 0, 0)

local tSearchInfoDefault = {
	["Name"]     = "物品名称",
	["Level"]    = {"", ""},
	["Quality"]  = "任何品质",
	["Status"]   = "所有状态",
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
AH_Helper.InitOrg = AuctionPanel.Init
AH_Helper.ShowNoticeOrg = AuctionPanel.ShowNotice
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
        INI_FILE_PATH = "interface/AH/AH_AuctionItem.ini"
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
		if not AH_Helper.IsInHistory(szKeyName) and szKeyName ~= "物品名称" then
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
		--tMinBid = PRICE_LIMITED, tMaxBid = 0, tMinBuy = PRICE_LIMITED, tMaxBuy = 0, nVersion = AH_Helper.nVersion
		if AH_Helper.tItemPrice[item.nUiId] == nil or AH_Helper.tItemPrice[item.nUiId][2] ~= AH_Helper.nVersion then
			AH_Helper.tItemPrice[item.nUiId] = {PRICE_LIMITED, AH_Helper.nVersion}
		end
		if MoneyOptCmp(hItem.tBuyPrice, PRICE_LIMITED) ~= 0 then
			local tBuyPrice = MoneyOptDiv(hItem.tBuyPrice, hItem.nCount)
			--最低一口
			if MoneyOptCmp(AH_Helper.tItemPrice[item.nUiId][1], tBuyPrice) == 1 then
				AH_Helper.tItemPrice[item.nUiId][1] = tBuyPrice
			end
		end
	end

	hTextName:SetText(hItem.szItemName)
	hTextName:SetFontColor(GetItemFontColorByQuality(item.nQuality, false))

	hBox:SetObject(UI_OBJECT_ITEM_INFO, item.nVersion, item.dwTabType, item.dwIndex)
	hBox:SetObjectIcon(nIconID)
	UpdateItemBoxExtend(hBox, item)
	hBox:SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
	hBox:SetOverTextFontScheme(0, 15)
	hBox:SetOverTextPosition(1, ITEM_POSITION.LEFT_TOP)
	hBox:SetOverTextFontScheme(1, 16)

	hItem:Lookup(tInfo.Level):SetText(item.GetRequireLevel())
	if szDataType == "Sell" then
		if hItem.szBidderName == "" then
			hTextSaler:SetText("无人出价")
			hTextSaler:SetFontColor(255, 0, 0)
		else
			hTextSaler:SetText(hItem.szBidderName)
			hTextSaler:SetFontColor(0, 200, 0)
		end
	else
		hTextSaler:SetText(tItemData["SellerName"])
	end

	local nGold, nSliver, nCopper = UnpackMoney(hItem.tBidPrice)
	hItem:Lookup(tInfo.aBidText[1]):SetText(nGold)
	hItem:Lookup(tInfo.aBidText[2]):SetText(nSliver)
	hItem:Lookup(tInfo.aBidText[3]):SetText(nCopper)

	if MoneyOptCmp(hItem.tBuyPrice, PRICE_LIMITED) ~= 0 then
		nGold, nSliver, nCopper = UnpackMoney(hItem.tBuyPrice)
		hItem:Lookup(tInfo.aBuyText[1]):SetText(nGold)
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
		hTextTime:SetText(""..nLeftTime.."秒")
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
				hTextTime:SetText(""..nLeftTime.."秒")
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
					hTextBid:SetText("单")
				elseif player.szName == hItem.szBidderName then
					hTextBid:SetText("我的单价")
				else
					hTextBid:SetText(hItem.szBidderName)	--显示竞拍者
					hTextBid:SetFontColor(0, 200, 0)
				end
			elseif szDataType == "Bid" then
				hTextBid:SetText("我的单价")
			elseif szDataType == "Sell" then
				hTextBid:SetText("单价")
			end

			if MoneyOptCmp(hItem.tBuyPrice, PRICE_LIMITED) ~= 0 then
				hItem:Lookup(tInfo.aBuyText[4]):SetText("单")
			end
		else
			if szDataType == "Search" then
				if hItem.szBidderName == "" then
					hTextBid:SetText("")
				elseif player.szName == hItem.szBidderName then
					hTextBid:SetText("我的出价")
				else
					hTextBid:SetText(hItem.szBidderName)
					hTextBid:SetFontColor(0, 200, 0)
				end
			elseif szDataType == "Bid" then
				hTextBid:SetText("我的出价")
			elseif szDataType == "Sell" then
				hTextBid:SetText("")
			end

			if MoneyOptCmp(hItem.tBuyPrice, PRICE_LIMITED) ~= 0 then
				hItem:Lookup(tInfo.aBuyText[4]):SetText("")
			end
		end

		local nGold, nSliver, nCopper = UnpackMoney(tBidPrice)
		hItem:Lookup(tInfo.aBidText[1]):SetText(nGold)
		hItem:Lookup(tInfo.aBidText[2]):SetText(nSliver)
		hItem:Lookup(tInfo.aBidText[3]):SetText(nCopper)

		if MoneyOptCmp(hItem.tBuyPrice, PRICE_LIMITED) ~= 0 then
			nGold, nSliver, nCopper = UnpackMoney(tBuyPrice)
			hItem:Lookup(tInfo.aBuyText[1]):SetText(nGold)
			hItem:Lookup(tInfo.aBuyText[2]):SetText(nSliver)
			hItem:Lookup(tInfo.aBuyText[3]):SetText(nCopper)
		end
	end
end

function AH_Helper.GetItemSellInfo(szItemName)
    if AH_Helper.szDefaultValue == "Btn_Max" or AH_Helper.szDefaultValue == "Btn_Min" then
		for i, v in pairs(AH_Helper.tItemPrice) do
			if szItemName == Table_GetItemName(i) then
				local u = {szName = szItemName, tBidPrice = 0, tBuyPrice = 0, szTime = AH_Helper.szDefaultTime}
                if AH_Helper.szDefaultValue == "Btn_Min" then
                    AH_Helper.Message("当前寄售价格为【最低价格】")
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
        AH_Helper.Message("没有找到该种物品价格")
	else
		AH_Helper.Message("当前寄售价格为【系统保存价格】")
		for k, v in pairs(AuctionPanel.tItemSellInfoCache) do
			if v.szName == szItemName then
				return v
			end
		end
		AH_Helper.Message("没有找到该种物品价格")
    end
	return nil
end

function AH_Helper.OnMouseEnter()
	local szName = this:GetName()
	if szName == "Btn_Sale" then
		AH_Helper.OutputTip("批量寄售：按住SHIFT键，再点击此按钮（ALT寄售五彩石及书籍）")
	elseif szName == "Btn_History" then
		AH_Helper.OutputTip("左键点击显示历史记录")
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
	if szName == "Btn_SearchDefault" then
		AH_Helper.szLastSearchKey = nil
	elseif szName == "Btn_Search" then
		local hEdit = AH_Helper.GetSearchEdit()
		local szText = hEdit:GetText()
		szText = string.gsub(szText, "^%s*(.-)%s*$", "%1")
		szText = string.gsub(szText, "[%[%]]", "")
		hEdit:SetText(szText)
	end
	AH_Helper.OnLButtonClickOrg()
end

function AH_Helper.OnExchangeBoxItem(boxItem, boxDsc, nHandCount, bHand)
	if boxDsc == AH_Helper.boxDsc and not boxItem:IsEmpty() then
		local frame = Station.Lookup("Normal/AuctionPanel")
		AH_Helper.AuctionSellOrg(frame)
	else
		AH_Helper.OnExchangeBoxItemOrg(boxItem, boxDsc, nHandCount, bHand)
		AH_Helper.boxDsc = boxDsc
		RemoveUILockItem("Auction")
	end
end

function AH_Helper.AuctionSell(frame)
	if IsShiftKeyDown() then
		if not AH_Helper.bSellNotice then
			local tMsg =
			{
				szName = "AuctionSell",
				szMessage = "        是否需要开始批量寄售",
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
				szMessage = "        是否需要开始批量寄售",
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
				OutputMessage("MSG_ANNOUNCE_YELLOW", "**此页部分物品已被【交易行助手】过滤，请点击下一页继续**")
			else
				OutputMessage("MSG_ANNOUNCE_YELLOW", "**此页部分物品已被【交易行助手】全部过滤**")
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

function AH_Helper.OnItemLButtonClick()
	local szName = this:GetName()
	if szName == "Handle_ItemList" then
		if AH_Helper.bFastBid and IsShiftKeyDown() and IsCtrlKeyDown() then
			AuctionPanel.AuctionBid(this)
		elseif AH_Helper.bFastBuy and IsAltKeyDown() and IsCtrlKeyDown() then
			AuctionPanel.AuctionBuy(this, "Search")
		end
	elseif szName == "Handle_AItemList" then
		if AH_Helper.bFastCancel and IsAltKeyDown() and IsCtrlKeyDown() then
			AuctionPanel.AuctionCancel(this)
		end
	end
	AH_Helper.OnItemLButtonClickOrg()
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
		if (IsShiftKeyDown() and IsCtrlKeyDown()) or (IsAltKeyDown() and IsCtrlKeyDown()) then
			AuctionPanel.Selected(this)
			AuctionPanel.UpdateSelectedInfo(this:GetRoot(), "Search", true)
		end
	elseif szName == "Handle_AItemList" then
		this.bOver = true
		AuctionPanel.UpdateBgStatus(this)
		if IsAltKeyDown() and IsCtrlKeyDown() then
			AuctionPanel.Selected(this)
			AuctionPanel.UpdateSelectedInfo(this:GetRoot(), "Sell", true)
		end
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
			{szOption = "搜索全部", fnAction = function() AH_Helper.UpdateList(szItemName) end,},
			{szOption = "联系卖家", fnAction = function() EditBox_TalkToSomebody(szSellerName) end,},
			{szOption = "屏蔽卖家", fnAction = function() AH_Helper.AddBlackList(szSellerName) AH_Helper.UpdateList() end,},
			{szOption = "加入收藏", fnAction = function() AH_Helper.AddFavorite(szItemName) end,},
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
	if not hWndSrch:Lookup("Btn_History") then
		local temp = Wnd.OpenWindow("interface\\AH\\AH_Widget.ini")
		if temp then
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
					menu.nMiniWidth = wT
					menu.x = xT - 5
					menu.y = yT + hT
					PopupMenu(menu)
				end
				hBtnHistory.OnRButtonClick = function ()
					local menu = AH_Helper.GetHotItem()
					PopupMenu(menu)
				end
			end
		end
		Wnd.CloseWindow(temp)
	end

	if not hWndSrch:Lookup("Btn_Produce") then
		local temp = Wnd.OpenWindow("interface\\AH\\AH_Widget.ini")
		if temp then
			local hBtnProduce = temp:Lookup("Btn_Produce")
			if hBtnProduce then
				hBtnProduce:ChangeRelation(hWndSrch, true, true)
				hBtnProduce:SetRelPos(854, 0)
				hBtnProduce.OnLButtonClick = function()
					AH_Produce.OpenPanel()
				end
			end
		end
		Wnd.CloseWindow(temp)
	end

	if not frame:Lookup("Wnd_Side") then
		local temp = Wnd.OpenWindow("interface\\AH\\AH_Widget.ini")
		if temp then
			local hWndSide = temp:Lookup("Wnd_Side")
			if hWndSide then
				hWndSide:ChangeRelation(frame, true, true)
				hWndSide:SetRelPos(960, 8)
				hWndSide:Lookup("Btn_Price").OnLButtonClick = function()
					local menu =
					{
						--{szOption = "使用最高价", bMCheck = true, bChecked = (AH_Helper.szDefaultValue == "Btn_Max"), fnAction = function() AH_Helper.szDefaultValue = "Btn_Max" AH_Helper.SetSellPriceType() end,},
						{szOption = "使用最低价", bMCheck = true, bChecked = (AH_Helper.szDefaultValue == "Btn_Min"), fnAction = function() AH_Helper.szDefaultValue = "Btn_Min" AH_Helper.SetSellPriceType() end,},
						{szOption = "使用系统保存价格", bMCheck = true, bChecked = (AH_Helper.szDefaultValue == "Btn_Save"), fnAction = function() AH_Helper.szDefaultValue = "Btn_Save" AH_Helper.SetSellPriceType() end,},
						--{bDevide = true},
						--{szOption = "起拍价等于一口价", bCheck = true, bChecked = AH_Helper.bBidEqualBuy, fnAction = function() AH_Helper.bBidEqualBuy = not AH_Helper.bBidEqualBuy end,},
					}
					PopupMenu(menu)
				end
				hWndSide:Lookup("Btn_Favorite").OnLButtonClick = function()
					local menu = {}
					local m_1 = {szOption = "收藏夹"}
					for k, v in pairs(AH_Helper.tItemFavorite) do
						table.insert(m_1,
						{
							szOption = k,
							{szOption = "搜索", fnAction = function() AH_Helper.UpdateList(k, "收藏物品") AH_Helper.szLastSearchKey = nil end,},
							{szOption = "删除", fnAction = function() local szText = "删除收藏物品: "..k AH_Helper.Message(szText) AH_Helper.tItemFavorite[k] = nil end,},
						})
					end
					local m_3 = {szOption = "黑名单"}
					for k, v in pairs(AH_Helper.tBlackList) do
						table.insert(m_3,
						{
							szOption = k,
							{szOption = "删除", fnAction = function() local szText = "删除黑心卖家: "..k AH_Helper.Message(szText) AH_Helper.tBlackList[k] = nil AH_Helper.UpdateList() end,},
						})
					end
					table.insert(menu, m_1)
					table.insert(menu, m_3)
					PopupMenu(menu)
				end
				hWndSide:Lookup("Btn_Split").OnLButtonClick = function()
					local x, y = this:GetAbsPos()
					local w, h = this:GetSize()
					AH_Spliter.OnSplitBoxItem({x, y, w, h})
				end
				hWndSide:Lookup("Btn_Split").OnRButtonClick = function()
					AH_Spliter.StackItem()
				end
				hWndSide:Lookup("Btn_Option").OnLButtonClick = function()
					local menu =
					{
						{szOption = "版本：v" .. AH_Helper.szVersion, fnDisable = function() return true end,},
						{ bDevide = true },
						{szOption = "过滤已读秘籍", bCheck = true, bChecked = AH_Helper.bFilterRecipe, fnAction = function() AH_Helper.bFilterRecipe = not AH_Helper.bFilterRecipe end, fnMouseEnter = function() AH_Helper.OutputTip("勾选此项后，将过滤掉已阅读的秘籍") end,},
						{szOption = "过滤已读书籍",bCheck = true,bChecked = AH_Helper.bFilterBook,fnAction = function()AH_Helper.bFilterBook = not AH_Helper.bFilterBook end, fnMouseEnter = function() AH_Helper.OutputTip("勾选此项后，将过滤掉已阅读的书籍") end,},
						{ bDevide = true },
						{szOption = "最大历史记录", fnMouseEnter = function() AH_Helper.OutputTip("记录物品搜索历史，点击搜索框下拉按钮中的记录可以快速搜索") end,
							{szOption = "5", bMCheck = true, bChecked = (AH_Helper.nMaxHistory == 5), fnAction = function() AH_Helper.nMaxHistory = 5 end,},
							{szOption = "10", bMCheck = true, bChecked = (AH_Helper.nMaxHistory == 10), fnAction = function() AH_Helper.nMaxHistory = 10 end,},
							{szOption = "15", bMCheck = true, bChecked = (AH_Helper.nMaxHistory == 15), fnAction = function() AH_Helper.nMaxHistory = 15 end,},
							{szOption = "20", bMCheck = true, bChecked = (AH_Helper.nMaxHistory == 20), fnAction = function() AH_Helper.nMaxHistory = 20 end,},
						},
						{ bDevide = true },
						{szOption = "寄售保管时间", fnMouseEnter = function() AH_Helper.OutputTip("寄售物品时默认的保管时间") end,
							{szOption = "12小时", bMCheck = true, bChecked = (AH_Helper.szDefaultTime == "12小时"), fnAction = function() AH_Helper.szDefaultTime = "12小时" end,},
							{szOption = "24小时", bMCheck = true, bChecked = (AH_Helper.szDefaultTime == "24小时"), fnAction = function() AH_Helper.szDefaultTime = "24小时" end,},
							{szOption = "48小时", bMCheck = true, bChecked = (AH_Helper.szDefaultTime == "48小时"), fnAction = function() AH_Helper.szDefaultTime = "48小时" end,},
						},
						{szOption = "启用自动差价", bCheck = true, bChecked = AH_Helper.bLowestPrices, fnAction = function() AH_Helper.bLowestPrices = not AH_Helper.bLowestPrices end, fnMouseEnter = function() AH_Helper.OutputTip("勾选此项后，寄售物品时将自动乘以差价系数或减去差价") end,
							{szOption = "差价系数", bCheck = true, bChecked = AH_Helper.bPricePercentage, fnDisable = function() return not AH_Helper.bLowestPrices end, fnAction = function() AH_Helper.bPricePercentage = not AH_Helper.bPricePercentage end,
								{szOption = "修改 [" .. AH_Helper.nPricePercentage.."]", fnDisable = function() return not AH_Helper.bPricePercentage end, fnAction = function()
										GetUserInput("输入差价系数：", function(szText)
											local n = tonumber(szText)
											if n > 0 then
												AH_Helper.nPricePercentage = n
											end
										end, nil, nil, nil, nil, nil)
									end,
								}
							},
							{ bDevide = true },
							{szOption = "1铜", bMCheck = true, bChecked = (AH_Helper.nDefaultPrices == 1), fnDisable = function() return AH_Helper.bPricePercentage or not AH_Helper.bLowestPrices end, fnAction = function() AH_Helper.nDefaultPrices = 1 end,},
							{szOption = "1银", bMCheck = true, bChecked = (AH_Helper.nDefaultPrices == 1 * 100), fnDisable = function() return AH_Helper.bPricePercentage or not AH_Helper.bLowestPrices end, fnAction = function() AH_Helper.nDefaultPrices = 1 * 100 end,},
							{szOption = "1金", bMCheck = true, bChecked = (AH_Helper.nDefaultPrices == 100 * 100), fnDisable = function() return AH_Helper.bPricePercentage or not AH_Helper.bLowestPrices end, fnAction = function() AH_Helper.nDefaultPrices = 100 * 100 end,},
						},
						{ bDevide = true },
						{szOption = "屏蔽确认提示", bCheck = true, bChecked = AH_Helper.bNoAllPrompt, fnAction = function() AH_Helper.bNoAllPrompt = not AH_Helper.bNoAllPrompt end, fnMouseEnter = function() AH_Helper.OutputTip("勾选此项后，所以操作都将无确认提示（配合快速竞拍、购买、取消，谨慎勾选）") end,
							{szOption = "屏蔽批量寄售确认提示", bCheck = true, bChecked = AH_Helper.bSellNotice, fnAction = function() AH_Helper.bSellNotice = not AH_Helper.bSellNotice end,},
						},
						{ bDevide = true },
						{szOption = "启用快速竞拍", bCheck = true, bChecked = AH_Helper.bFastBid, fnAction = function() AH_Helper.bFastBid = not AH_Helper.bFastBid end, fnMouseEnter = function() AH_Helper.OutputTip("按住SHIFT+CTRL，鼠标左键点击物品栏可以快速出价") end,},
						{szOption = "启用快速购买", bCheck = true, bChecked = AH_Helper.bFastBuy, fnAction = function() AH_Helper.bFastBuy = not AH_Helper.bFastBuy end, fnMouseEnter = function() AH_Helper.OutputTip("按住ALT+CTRL，鼠标左键点击物品栏可以快速购买") end,},
						{szOption = "启用快速取消", bCheck = true, bChecked = AH_Helper.bFastCancel, fnAction = function() AH_Helper.bFastCancel = not AH_Helper.bFastCancel end, fnMouseEnter = function() AH_Helper.OutputTip("按住ALT+CTRL，鼠标左键点击物品栏可以快速取消") end,},
						{ bDevide = true },
						{szOption = "启用自动搜索", bCheck = true, bChecked = AH_Helper.bAutoSearch, fnAction = function() AH_Helper.bAutoSearch = not AH_Helper.bAutoSearch end, fnMouseEnter = function() AH_Helper.OutputTip("按住CTRL，鼠标左键点击背包中的物品栏可以快速搜索该物品") end,},
						{szOption = "材料配方提示", bCheck = true, bChecked = AH_Tip.bShowTipEx, fnAction = function() AH_Tip.bShowTipEx = not AH_Tip.bShowTipEx end, fnMouseEnter = function() AH_Helper.OutputTip("按住ALT或SHIFT亦可以显示提示") end,},
					}
					PopupMenu(menu)
				end
			end
		end
		Wnd.CloseWindow(temp)
	end
	local nW, nH = frame:GetSize()
	frame:SetSize(nW + 56, nH)
end

function AH_Helper.OutputTip(szText)
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	OutputTip(GetFormatText(szText, 101), 300, {x, y, w, h})
end

function AH_Helper.GetGuiShiDrop(hItem)
	local item = GetItem(hItem.nItemID)
	local tItemInfo = GetItemInfo(item.dwTabType, item.dwIndex)
	local tDesc = Table_GetItemDesc(item.nUiId)
	if string.find(tDesc, "可额外掉落") then
		local m = {szOption = "查看掉落"}
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
        hText:SetText("最低")
    elseif AH_Helper.szDefaultValue == "Btn_Save" then
        hText:SetText("系统")
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
		OutputMessage("MSG_ANNOUNCE_RED", "寄卖失败！您要寄卖的物品信息有误。")
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
		if item2 and item1.nQuality == item2.nQuality and item1.nGenre == item2.nGenre then
			return true
		end
		return false
	elseif item1.nGenre == ITEM_GENRE.COLOR_DIAMOND then
		if item2 and item1.nQuality == item2.nQuality and item1.nGenre == item2.nGenre then
			local szName1, szName2 = GetItemNameByItem(item1), GetItemNameByItem(item2)
			local _, _, _, szLevel1 = szName1:match("彩·(.+)·(.+)·(.+)%p(.+)%p")
			local _, _, _, szLevel2 = szName2:match("彩·(.+)·(.+)·(.+)%p(.+)%p")
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
		OutputMessage("MSG_ANNOUNCE_RED", "寄卖失败！您要寄卖的物品信息有误。")
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
				if IsSameSellItem(item, item2) then
					local tBidPrice2 = MoneyOptMult(tSBidPrice, item2.nStackNum)
					local tBuyPrice2 = MoneyOptMult(tSBuyPrice, item2.nStackNum)
					AtClient.Sell(AuctionPanel.dwTargetID, i, j, tBidPrice2.nGold, tBidPrice2.nSilver, tBidPrice2.nCopper, tBuyPrice2.nGold, tBuyPrice2.nSilver, tBuyPrice2.nCopper, nTime)
				end
			end
		end
	end
	PlaySound(SOUND.UI_SOUND, g_sound.Trade)
end

function AH_Helper.Message(szMsg)
	OutputMessage("MSG_SYS", "<交易行助手>"..szMsg.."\n")
end

function AH_Helper.UpdateList(szItemName, szType)
	if not szItemName then
		szItemName = ""
	end
	local t = tItemDataInfo["Search"]
	local frame = Station.Lookup("Normal/AuctionPanel")
	AuctionPanel.tSearch = tSearchInfoDefault
	AuctionPanel.tSearch["Name"] = szItemName
	AuctionPanel.InitSearchInfo(frame, AuctionPanel.tSearch)
	AuctionPanel.SaveSearchInfo(frame)

	if szType and szType ~= "" then
		local szText = "搜索"..szType..": "..szItemName
		AH_Helper.Message(szText)
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
	local szText = szItemName.." 已加入收藏夹"
    AH_Helper.Message(szText)
end

function AH_Helper.AddBlackList(szSellerName)
    AH_Helper.tBlackList[szSellerName] = 1
    local szText = szSellerName.." 已加入黑名单"
	AH_Helper.Message(szText)
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

		szTip = szTip .. GetFormatText("物品总数：", 101) .. GetFormatText(nItemCountTotal, 162)
		szTip = szTip .. GetFormatText("    背包：", 101) .. GetFormatText(nItemCountInPackage, 162) .. GetFormatText("    仓库：", 101) .. GetFormatText(nItemCountInBank, 162)

		--配方
		if item.nGenre == ITEM_GENRE.MATERIAL then
			szTip = szTip .. AH_Tip.GetRecipeTip(player, item)
		end

		if MoneyOptCmp(hItem.tBuyPrice, 0) == 1 and MoneyOptCmp(hItem.tBuyPrice, PRICE_LIMITED) ~= 0 then
			if AH_Helper.GetCheckPervalue() then
				szTip = szTip .. GetFormatText("\n一口价总价：", 163) .. GetMoneyTipText(hItem.tBuyPrice, 106)
			else
				szTip = szTip .. GetFormatText("\n一口价单价：", 163) .. GetMoneyTipText(MoneyOptDiv(hItem.tBuyPrice, hItem.nCount), 106)
			end
		end
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
				AH_Helper.UpdateList(AH_Helper.tItemHistory[i].szName)
			end,
		}
		table.insert(menu, m)
	end
	table.insert(menu, {bDevide = true})
	local d = {
		szOption = "清空历史记录",
		fnAction = function()
			AH_Helper.tItemHistory = {}
		end,
	}
	table.insert(menu, d)

	return menu
end

function AH_Helper.GetHotItem()
	local menu = {}
	for k1, v1 in pairs(AH_Data.HotItem) do
		local m_1 = { szOption = k1 }
		for k2, v2 in pairs(v1) do
			local m_2 = { szOption = k2 }
			for k3, v3 in pairs(v2) do
				local m_3 = {
					szOption = "  " .. v3[1],
					rgb = {GetItemFontColorByQuality(v3[2], false)},
					fnAction = function ()
						AH_Helper.UpdateList(v3[1])
					end,
				}
				table.insert(m_2, m_3)
			end
			table.insert(m_1, m_2)
		end
		table.insert(menu, m_1)
	end
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

	if not AH_Helper.bAutoSearch then
		return
	end
	local hEdit = AH_Helper.GetSearchEdit(frame)
	local szSearchKey = hEdit:GetText()
	local hFocusEdit = Station.GetFocusWindow()
	local szName = nil
	if hFocusEdit then
		szName = hFocusEdit:GetName()
	end
	if szSearchKey ~= "物品名称" and szSearchKey ~= AH_Helper.szLastSearchKey and szName == "BigBagPanel" then
		AH_Helper.szLastSearchKey = szSearchKey
		AH_Helper.UpdateList(szSearchKey)
	end
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
	AuctionPanel.OnItemRButtonClick = AH_Helper.OnItemRButtonClick
	AuctionPanel.OnItemMouseEnter = AH_Helper.OnItemMouseEnter
	AuctionPanel.OnItemMouseLeave = AH_Helper.OnItemMouseLeave
	AuctionPanel.ShowNotice = AH_Helper.ShowNotice
end

function AH_Helper.OnFrameCreate()
	this:RegisterEvent("GAME_EXIT")
	this:RegisterEvent("LOGIN_GAME")
	this:RegisterEvent("PLAYER_EXIT_GAME")
	this:RegisterEvent("OPEN_AUCTION")
end

--[[function AH_Helper.CheckVersion()
	local page = Station.Lookup("Lowest/AH_Helper/Page_IE")
	if page then
		page:Navigate("http://jx3server.duapp.com/update")
	end
end

function AH_Helper.OnTitleChanged()
	local szDoc = this:GetDocument()
	if szDoc ~= ""  then
		szDoc = string.sub(szDoc:match("%b()"), 2, -2)
		local a1, b1, c1 = szDoc:match("(%d+).(%d+).(%d+)")
		local a2, b2, c2 = AH_Helper.szVersion:match("(%d+).(%d+).(%d+)")
		if a1 >= a2 and b1 >= b2 and c1 > c2 then
			local tVersionInfo = {
				szName = "AH_HelperVersionInfo",
				szMessage = "发现交易行助手新版本：" .. szDoc .. "，去下载页面？",
				{
					szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function()
						OpenInternetExplorer("http://jx3server.duapp.com/", true)
					end
				},
				{
					szOption = g_tStrings.STR_HOTKEY_CANCEL,fnAction = function() end
				}
			}
			MessageBox(tVersionInfo)
		end
	end
end]]

function AH_Helper.OnEvent(szEvent)
	if szEvent == "LOGIN_GAME" then
		if IsFileExist(AH_Helper.szDataPath) then
			AH_Helper.tItemPrice = LoadLUAData(AH_Helper.szDataPath)
		end
	elseif szEvent == "GAME_EXIT" or szEvent == "PLAYER_EXIT_GAME" then
		SaveLUAData(AH_Helper.szDataPath, AH_Helper.tItemPrice)
	elseif szEvent == "OPEN_AUCTION" then
		local bNotExistOtherAddon = false
		if AuctionTip and AuctionTip.bFilter then
			AuctionTip.bFilter = false
			bNotExistOtherAddon = true
		elseif HM_ToolBox and HM_ToolBox.bShiftAuction then
			HM_ToolBox.bShiftAuction = false
			bNotExistOtherAddon = true
		end
		if bNotExistOtherAddon then
			AH_Helper.Message("检测到非兼容交易行插件，已强制将其关闭")
			AH_Helper.FuncHook()
		end
		AH_Helper.SetSellPriceType()
		--AH_Helper.CheckVersion()
	end
end

Wnd.OpenWindow("Interface\\AH\\AH_Helper.ini", "AH_Helper")

Hotkey.AddBinding("AH_Produce_Open", "技艺助手", "交易行助手", function() AH_Produce.OpenPanel() end, nil)
Hotkey.AddBinding("AH_Spliter_Open", "拆分物品", "", function() AH_Spliter.OnSplitBoxItem() end, nil)
Hotkey.AddBinding("AH_Spliter_StackItem", "堆叠物品", "", function() AH_Spliter.StackItem() end, nil)
