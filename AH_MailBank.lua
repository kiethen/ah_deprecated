------------------------------------------------------
-- #模块名：邮件仓库模块
-- #模块说明：增强邮件功能
------------------------------------------------------

AH_MailBank = {}

local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber

local szIniFile = "Interface/AH/AH_MailBank.ini"
local bMailHooked = false

function AH_MailBank:Init(frame)
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
end


function AH_MailBank.OnUpdate()
	local frame = Station.Lookup("Normal/MailPanel")
	if not bMailHooked and frame and frame:IsVisible() then
		local page = frame:Lookup("PageSet_Total/Page_Receive")
		local temp = Wnd.OpenWindow("interface\\AH\\AH_Widget.ini")
		if not page:Lookup("Btn_MailBank") then
			local hBtnMailBank = temp:Lookup("Btn_MailBank")
			if hBtnMailBank then
				hBtnMailBank:ChangeRelation(page, true, true)
				hBtnMailBank:SetRelPos(35, 8)
				hBtnMailBank.OnLButtonClick = function()
					AH_MailBank.OpenPanel()
				end
			end
		end
		Wnd.CloseWindow(temp)
		bMailHooked = true
	elseif not frame or not frame:IsVisible() then
		bMailHooked = false
	end
end
------------------------------------------------------------
-- 回调函数
------------------------------------------------------------
function AH_MailBank.OnFrameCreate()
	this:RegisterEvent("GET_MAIL_CONTENT")
end

function AH_MailBank.OnEvent(event)
	if event == "GET_MAIL_CONTENT" then
	end
end

function AH_MailBank.OnEditChanged()
end

function AH_MailBank.OnLButtonClick()
	local szName = this:GetName()
	if szName == "Btn_Close" then
		AH_MailBank.ClosePanel()
	end
end

function AH_MailBank.OnItemLButtonClick()
	local szName = this:GetName()
end

function AH_MailBank.OnItemRButtonClick()
	local szName = this:GetName()
end

function AH_MailBank.OnItemMouseEnter()
	local szName = this:GetName()
	if not this.bItemBox then
		return
	end
	this:SetObjectMouseOver(1)
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
		AH_MailBank:Init(frame)
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

AH_Library.RegisterBreatheEvent("ON_AH_MAILBANK_UPDATE", AH_MailBank.OnUpdate)
