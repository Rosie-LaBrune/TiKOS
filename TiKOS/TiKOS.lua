
local TKOS		= {}
TKOS.default		= {
	anchor 		= { TOPLEFT, TOPLEFT, 0, 0},
	bMovable		= true,
	bShow 		= true,
	bAlphaOrdered  	= false,
	kosList		= {},
	warningDuration  	= 5,
	bWarningMovable = false,
	warningAnchor	= { TOPLEFT, TOPLEFT, 100, 100},
	warningText	= "warning!! % is around",
	fontFamily		= "Univers 67",
	fontSize		= 38,
	fontStyle		= "shadow",
	fontColor		= { 0.81,0,0,1},
	groupWarning	= {}
	}
	

TKOS.bShow = true
TKOS.bMovable = true
TKOS.scrollId = 0
TKOS.selectedId = 0
TKOS.bActive = false

TKOS.bWarning = false
TKOS.warningTime = 0
TKOS.warningDuration = 5

TKOS.styles = {
		'normal',
		'outline',
		'thick-outline',
		'shadow',
		'soft-shadow-thick',
		'soft-shadow-thin'
	}

local CENTER_COLOR 		= {0.1, 0.1, 0.1, 0.5}
local EDGE_COLOR 		= {0.2, 0.2, 0.2, 1.0}
local EDIT_CENTER_COLOR 	= {0,0,0,1}
local BUTTON_CENTER_COLOR= {0.1,0.1,0.1,0.9}
local BUTTON_EDGE_COLOR 	= {0.0, 0.0, 0.0, 1.0}
local DEFAULT_GROUP_COLOR = {0.5, 0.5, 0.5, 1.0}
local SLIDER_TEX			= "/esoui/art/chatwindow/chat_scrollbar_track.dds"

local LABEL_HEIGHT		= 26
local NB_ROW			= 12
local MAX_GROUP			= 5

local tex = "ESOUI/art/lorelibrary/lorelibrary_scroll.dds"

local LMP = LibStub:GetLibrary('LibMediaProvider-1.0')
	
function TKOS:OnAddOnLoaded( eventCode, addOnName )
	
	if ( addOnName ~= "TiKOS") then return end
	
	TiKOS:SetHandler( "OnMouseUp", function() TiKOSSaveAnchor() TKOS:HideContextButton(true) TKOS:UpdateView() end )
			
	TKOS.vars = ZO_SavedVars:New("TiKOS_Vars",1,"TiKOS",TKOS.default)
	
	-- Need to clear anchors, since SetAnchor() will just keep adding new ones.
	TiKOS:ClearAnchors();
	TiKOS:SetAnchor(TKOS.vars.anchor[1], TiKOS.parent, TKOS.vars.anchor[2], TKOS.vars.anchor[3], TKOS.vars.anchor[4])
	
	TKOS.movable = TKOS.vars.movable
	TKOS.kosList = TKOS.vars.kosList
	TKOS.bShow = TKOS.vars.bShow
	TKOS.warningDuration = TKOS.vars.warningDuration
			
	-- init delete button
	TKOS_DeleteBG:SetCenterColor(unpack(BUTTON_CENTER_COLOR))
	TKOS_DeleteBG:SetEdgeColor(unpack(BUTTON_EDGE_COLOR))
	TKOS_DeleteBG:SetEdgeTexture("", 1, 1, 2)
	TKOS_DeleteButton:SetNormalFontColor(0.5,0.5,0.5,1.0)
	TKOS_DeleteButton:SetMouseOverFontColor(1.0,1.0,1.0,1.0)
	TKOS_DeleteButton:SetPressedFontColor(0.0,0.0,0.0,1.0)
	TKOS_DeleteButton:SetHandler("OnClicked", function(self) TKOS:DeleteEnemy(self) end)
	
	
	-- init group button
	TKOS_GroupBG:SetCenterColor(unpack(BUTTON_CENTER_COLOR))
	TKOS_GroupBG:SetEdgeColor(unpack(BUTTON_EDGE_COLOR))
	TKOS_GroupBG:SetEdgeTexture("", 1, 1, 2)
	TKOS_GroupButton:SetNormalFontColor(0.5,0.5,0.5,1.0)
	TKOS_GroupButton:SetMouseOverFontColor(1.0,1.0,1.0,1.0)
	TKOS_GroupButton:SetPressedFontColor(0.0,0.0,0.0,1.0)
	TKOS_GroupButton:SetHandler("OnClicked", function(self) TKOS:SetGroupEnemy(self) end)

	self:HideContextButton(true)
	
	
	-- init edit box
	TKOS_EditBox:SetHandler("OnEnter", function() TKOS:AddName() end)
	--TKOS_EditBox:SetMinInputCharacters(CHARNAME_MIN_LENGTH)
	--TKOS_EditBox:SetMaxInputCharacters(CHARNAME_MAX_LENGTH)
		
	-- init panel
	TKOS_BG:SetCenterColor(unpack(CENTER_COLOR))
	TKOS_BG:SetEdgeColor(unpack(EDGE_COLOR))
	TKOS_BG:SetEdgeTexture("", 1, 1, 1)
	TKOS_EditBG:SetCenterColor(unpack(EDIT_CENTER_COLOR))
	TKOS_EditBG:SetEdgeColor(unpack(EDGE_COLOR))
	TKOS_EditBG:SetEdgeTexture("", 1, 1, 1)
	TiKOS:SetHandler("OnMouseWheel", function(self, delta) TKOS:OnMouseWheel(delta) end)
	
	-- init warning
	TKOS_WarningLabel:SetMovable(false)
	TKOS_WarningLabel:SetMouseEnabled(false)
	local swidth = GuiRoot:GetWidth()
	--TKOS_WarningLabel:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,math.floor(swidth*0.5+0.5),300)
	TKOS_WarningLabel:ClearAnchors();
	TKOS_WarningLabel:SetAnchor(TKOS.vars.warningAnchor[1], GuiRoot, TKOS.vars.warningAnchor[2], TKOS.vars.warningAnchor[3], TKOS.vars.warningAnchor[4])
	TKOS_TopWarning:SetHidden(true)
	TKOS_WarningLabel:SetHandler( "OnMouseUp", function() TiKOSSaveWarningAnchor() end)
	self:UpdateFont()
	
	-- init scroll
	self:UpdateScroll()
	
	-- update view
	self:UpdateView()
	
	-- check active
	self:OnZoneChanged(GetUnitZone("player"))
	
	-- keybinding
	ZO_CreateStringId("SI_BINDING_NAME_TOGGLE_TIKOS", "Toggle TiKOS")
	ZO_CreateStringId("SI_BINDING_NAME_ADDTARGET_TIKOS", "Add target on KOS list")
		
	-- update visibility
	self:UpdateShow()
	
	-- init config panel
	self:InitConfigPanel()
end

function TKOS:OnTargetChanged()
	
	if not TKOS.bActive then return end
	
	local target = GetUnitName("reticleover")
	--if (target == nil or not IsUnitPlayer("reticleover") or not IsUnitAttackable("reticleover")) then return end
	if (target == nil or not IsUnitAttackable("reticleover")) then return end
	
	--d("-----")
	--d(GetUnitName("reticleover"))
	
	bFound = false
	idTar = 0
	idGroup = 1 -- default group id
	for i=1,table.getn(TKOS.kosList) do
		if (target == TKOS.kosList[i][2]) then
			bFound = true
			idTar = i
			idGroup = TKOS.kosList[i][1]
			break
		end
	end
	
	if (bFound) then
		if idGroup == 1 then
			self:ShowWarning(target)
		else 
			self:ShowGroupWarning(idGroup-1,target)
		end
	end
end

function TKOS:ShowWarning(target)
	
	local fullText = self.vars.warningText
	local bFound = false
	local idPercent = 0
	
	for i=1,string.len(self.vars.warningText) do
		local char = string.sub(self.vars.warningText,i,i)
		if (char == "%") then
			bFound = true
			idPercent = i
			break
		end
	end
	
	if bFound then
		fullText = ""
		if (idPercent > 1) then
			fullText = string.sub(self.vars.warningText,1,idPercent-1)
		end
		fullText = fullText..target
		if (idPercent < string.len(self.vars.warningText)) then
			fullText = fullText..string.sub(self.vars.warningText,idPercent+1,-1)
		end
	end
	
	TKOS_WarningLabel:SetColor(unpack(self.vars.fontColor))
	TKOS_WarningLabel:SetText(fullText)
	
	TKOS_TopWarning:SetHidden(false)
	TKOS.bWarning = true
	TKOS.warningTime = 0
	--CycleGameCameraPreferredEnemyTarget()
end


function TKOS:ShowWarningGroup(idgroup, target)
	
	local groupText, groupColor = self:GetGroupWarning(idgroup)
	local fullText = groupText
	local bFound = false
	local idPercent = 0
	
	for i=1,string.len(groupText) do
		local char = string.sub(groupText,i,i)
		if (char == "%") then
			bFound = true
			idPercent = i
			break
		end
	end
	
	if bFound then
		fullText = ""
		if (idPercent > 1) then
			fullText = string.sub(groupText,1,idPercent-1)
		end
		fullText = fullText..target
		if (idPercent < string.len(groupText)) then
			fullText = fullText..string.sub(groupText,idPercent+1,-1)
		end
	end
	
	TKOS_WarningLabel:SetColor(unpack(groupColor))
	TKOS_WarningLabel:SetText(fullText)
	
	TKOS_TopWarning:SetHidden(false)
	TKOS.bWarning = true
	TKOS.warningTime = 0
	--CycleGameCameraPreferredEnemyTarget()
end


function TKOS:HideWarning()
	TKOS.bWarning = false
	TKOS_TopWarning:SetHidden(true)
end

function TKOS:OnZoneChanged(zone)
	
	local pzone = GetUnitZone("player")
	if (pzone ~= nil and string.len(pzone)>6) then
		TKOS.bActive = (string.sub(pzone,1,6) == "Cyrodi")
	else
		TKOS.bActive = false
	end
end

EVENT_MANAGER:RegisterForEvent("TiKOS" , EVENT_ADD_ON_LOADED , function(_event, _name) TKOS:OnAddOnLoaded(_event, _name) end)
--EVENT_MANAGER:RegisterForEvent("TiKOS", EVENT_RETICLE_TARGET_CHANGED, function(_event) TKOS:OnTargetChanged() end)
EVENT_MANAGER:RegisterForEvent("TiKOS", EVENT_RETICLE_TARGET_PLAYER_CHANGED, function(_event) TKOS:OnTargetChanged() end)
EVENT_MANAGER:RegisterForEvent("TiKOS", EVENT_ZONE_CHANGED, function(_event, _zone, _subzone, _new) TKOS:OnZoneChanged(_zone) end)

function TiKOSUpdate()
	if not TKOS.bWarning then return end
	TKOS.warningTime = TKOS.warningTime + GetFrameDeltaTimeSeconds()
	if (TKOS.warningTime > TKOS.warningDuration) then
		TKOS:HideWarning()
	end
end

function  TiKOSSaveAnchor()
	
	-- Get the new position
	local isValidAnchor, point, relativeTo, relativePoint, offsetX, offsetY = TiKOS:GetAnchor()
	
	-- Save the anchors
	if ( isValidAnchor ) then
	
	TKOS.vars.anchor = { point, relativePoint, offsetX, offsetY }
	
	else
	
	d("TiKOS - anchor not valid")
	
	end
end

function TiKOSSaveWarningAnchor()
	-- Get the new position
	local isValidAnchor, point, relativeTo, relativePoint, offsetX, offsetY = TKOS_WarningLabel:GetAnchor()
	
	-- Save the anchors
	if ( isValidAnchor ) then
	
	TKOS.vars.warningAnchor = { point, relativePoint, offsetX, offsetY }
	
	else
	
	d("TiKOS - warning anchor not valid")
	
	end
end

function TiKOSToggleShow()
	TKOS.bShow = not TKOS.bShow
	TKOS.vars.bShow = TKOS.bShow
	TKOS:UpdateShow()
end

function TKOS:AddName()
	local text = TKOS_EditBox:GetText()
	self:AddKOSName(text)
end

function TiKOSAddTarget()
	local target = GetUnitName("reticleover")
	if (target == nil or not IsUnitPlayer("reticleover") or not IsUnitAttackable("reticleover")) then return end
	TKOS:AddKOSName(target)
end

function TKOS:AddKOSName(nname)
	local ngroup = 0
		
	if (text == "") then return end
	
	-- check if not already
	local bFound = false
	local nbEnemy = table.getn(TKOS.kosList)
	for i=1,nbEnemy do
		--if (TKOS.kosList[i][1] == ntype and TKOS.kosList[i][2] == nname) then
		if (TKOS.kosList[i][2] == nname) then
			bFound = true
			break
		end
	end
	if bFound then return end
	
	
	-- add
	table.insert(TKOS.kosList,{ngroup, nname})
	TKOS.vars.kosList = TKOS.kosList
		
	-- update view
	TKOS_EditBox:SetText("")
	self:HideContextButton(true)
	self:UpdateView()
	self:UpdateScroll()
	if TKOS.slider ~= nil then
		TKOS.slider:SetValue(0)
	end
end

function TKOS:UpdateView()
	local nbEnemy = table.getn(TKOS.kosList)
	
	for i=1,math.min(NB_ROW,nbEnemy) do
		local label = GetControl("TKOS_NameLabel"..tostring(i))
		if label == nil then
			label = CreateControlFromVirtual("TKOS_NameLabel", TKOS_BG, "TKOS_NameLabel", i)
			label:SetHandler("OnMouseUp", function() TKOS:ToggleContextButton(i) end)
		end
		label:SetHidden(false)
		label:ClearAnchors()
		label:SetAnchor(TOPLEFT,TiKOS,TOPLEFT,15,40+LABEL_HEIGHT*i)
		label:SetText(TKOS.kosList[TKOS.scrollId+i][2])
	end
end

function TKOS:UpdateShow()
	TiKOS:SetHidden(not TKOS.bShow)
end


function TKOS:UpdateScroll()
	
	local nbEnemy = table.getn(TKOS.kosList)
		
	if (nbEnemy > NB_ROW) then
		if TKOS.slider == nil then
			TKOS.slider = CreateControl("TKOS_Slider",TKOS_BG,CT_SLIDER)
			TKOS.slider:SetDimensions(10,LABEL_HEIGHT*NB_ROW)
			TKOS.slider:SetMouseEnabled(true)
			--TKOS.slider:SetThumbTexture(SLIDER_TEX,SLIDER_TEX,SLIDER_TEX,15,30,0,0,1,1)
			TKOS.slider:SetValueStep(1)
			TKOS.slider:SetAnchor(TOPLEFT,TiKOS,TOPLEFT,162,70)
			TKOS.slider:SetHandler("OnValueChanged",function(self,value,eventReason)
			TKOS:OnSliderMove(value) end)
		end
		
		local height = math.floor(LABEL_HEIGHT*NB_ROW/(nbEnemy-NB_ROW+1))
		TKOS.slider:SetThumbTexture(SLIDER_TEX,SLIDER_TEX,SLIDER_TEX,15,height,0,0,1,1)
		TKOS.slider:SetMinMax(0,nbEnemy-NB_ROW)
		TKOS.slider:SetHidden(false)	
	else
		if TKOS.slider ~= nil then
			TKOS.slider:SetHidden(true)
		end
	end
end

function TKOS:OnSliderMove(value)
	--d(tostring(value))
	TKOS.scrollId = value
	self:HideContextButton(true)
	self:UpdateView()
end

function TKOS:OnMouseWheel(delta)
	--d(tostring(delta))
	local nbEnemy = table.getn(TKOS.kosList)
	if (nbEnemy <= NB_ROW or TKOS.slider==nil) then return end
	
	if (delta < 0) then
		TKOS.scrollId = math.min(TKOS.scrollId+1,nbEnemy-NB_ROW)
	else
		TKOS.scrollId = math.max(0,TKOS.scrollId-1)
	end
	
	TKOS.slider:SetValue(TKOS.scrollId)
end

function TKOS:ToggleContextButton(labelId)
	
	--d(tostring(labelId))
	
	local label = GetControl("TKOS_NameLabel"..tostring(labelId))
	if label == nil then return end
	
	self:UpdateView()
	
	label:ClearAnchors()
	label:SetAnchor(TOPLEFT,TiKOS,TOPLEFT,60,40+LABEL_HEIGHT*labelId)
	TKOS.selectedId = TKOS.scrollId + labelId
	self:HideContextButton(false,labelId)
	
end

function TKOS:HideContextButton(bHide, labelId)

	if (bHide) then
		TKOS_DeleteBG:SetHidden(true)
		TKOS_DeleteButton:SetHidden(true)
		
		TKOS_GroupBG:SetHidden(true)
		TKOS_GroupButton:SetHidden(true)
	else
		TKOS_DeleteBG:ClearAnchors()
		TKOS_DeleteBG:SetAnchor(TOPLEFT,TiKOS,TOPLEFT,10,45+LABEL_HEIGHT*labelId)
		TKOS_DeleteBG:SetHidden(false)
		TKOS_DeleteButton:ClearAnchors()
		TKOS_DeleteButton:SetAnchor(TOPLEFT,TiKOS,TOPLEFT,10,43+LABEL_HEIGHT*labelId)
		TKOS_DeleteButton:SetHidden(false)
		
		TKOS_GroupBG:ClearAnchors()
		TKOS_GroupBG:SetAnchor(TOPLEFT,TiKOS,TOPLEFT,35,45+LABEL_HEIGHT*labelId)
		TKOS_GroupBG:SetHidden(false)
		TKOS_GroupButton:ClearAnchors()
		TKOS_GroupButton:SetAnchor(TOPLEFT,TiKOS,TOPLEFT,35,44+LABEL_HEIGHT*labelId)
		TKOS_GroupButton:SetHidden(false)
		local ngroup = TKOS.kosList[TKOS.selectedId][1]
		local nlabel = self:GetLabelFromGroup(ngroup)
		TKOS_GroupButton:SetText(nlabel)
	end
end

function TKOS:DeleteEnemy()
	if (TKOS.selectedId < 1 or TKOS.selectedId > table.getn(TKOS.kosList)) then return end
	
	table.remove(TKOS.kosList,TKOS.selectedId)
	TKOS.vars.kosList = TKOS.kosList
	
	if (table.getn(TKOS.kosList) < NB_ROW) then
		local label = GetControl("TKOS_NameLabel"..tostring(table.getn(TKOS.kosList)+1))
		if label ~= nil then
			label:SetHidden(true)
		end
	end
		
	TKOS.scrollId = math.max(0,TKOS.scrollId - 1)
	
	self:HideContextButton(true)
	self:UpdateView()
	self:UpdateScroll()
end

-- group function
function TKOS:GetLabelFromGroup(idgroup)

	local glabel = "#"
	if idgroup > 1 and idgroup <= MAX_GROUP + 1 then
		glabel = tostring(idgroup-1)
	end
	
	return glabel
end

function TKOS:SetGroupEnemy()
	if (TKOS.selectedId < 1 or TKOS.selectedId > table.getn(TKOS.kosList)) then return end
	
	local ngroup = TKOS.kosList[TKOS.selectedId][1]
	ngroup = ngroup + 1
	if ngroup > MAX_GROUP + 1 then
		ngroup = 1
	end
	--d("ngroup = "..tostring(ngroup))
	
	TKOS.kosList[TKOS.selectedId][1] = ngroup
	TKOS.vars.kosList = TKOS.kosList
	
	local nlabel = self:GetLabelFromGroup(ngroup)
	--d("nlabel = "..nlabel)
	TKOS_GroupButton:SetText(nlabel)
end


function TKOS:GetGroupWarning(idgroup)
	
	for i=1, table.getn(TKOS.vars.groupWarning) do
		if TKOS.vars.groupWarning[i]["id"] == idgroup then
			return TKOS.vars.groupWarning[i]["text"], TKOS.vars.groupWarning[i]["color"]
		end
	end
	
	return "", DEFAULT_GROUP_COLOR

end

function TKOS:SetGroupWarningText(idgroup, gtext)
	local bFound = false
	
	for i=1, table.getn(TKOS.vars.groupWarning) do
		if TKOS.vars.groupWarning[i]["id"] == idgroup then
			bFound = true
			TKOS.vars.groupWarning[i]["text"] = gtext
			break
		end
	end
	
	if not bFound then
		table.insert(TKOS.vars.groupWarning,{["id"]=idgroup, ["text"]=gtext, ["color"]=DEFAULT_GROUP_COLOR})
	end
	
end

function TKOS:SetGroupWarningColor(idgroup, gcolor)
	local bFound = false
	
	for i=1, table.getn(TKOS.vars.groupWarning) do
		if TKOS.vars.groupWarning[i]["id"] == idgroup then
			bFound = true
			TKOS.vars.groupWarning[i]["color"] = gcolor
			break
		end
	end
	
	if not bFound then
		table.insert(TKOS.vars.groupWarning,{["id"]=idgroup, ["text"]="", ["color"]=gcolor})
	end
end

-- config function
function TKOS:UpdateWarningMovable()
	
	TKOS_WarningLabel:SetMovable(self.vars.bWarningMovable)
	TKOS_WarningLabel:SetMouseEnabled(self.vars.bWarningMovable)
	TKOS_TopWarning:SetHidden(not self.vars.bWarningMovable)
	
end

function TKOS:UpdateFont()

	TKOS_WarningLabel:SetFont(self:GetFontString())
	TKOS_WarningLabel:SetColor(unpack(self.vars.fontColor))
end

function TKOS:GetFontString()

	local fontPath = LMP:Fetch('font', self.vars.fontFamily)
	local fontString = string.format('%s|%u|%s', fontPath, self.vars.fontSize, self.vars.fontStyle)

	return fontString

end


function TKOS:InitConfigPanel()
	local LAM = LibStub("LibAddonMenu-1.0")
		
	local panelName = "TKOSSettingsPanel"
	local panelId = LAM:CreateControlPanel(panelName, "TiKOS")
	
	-- Components
	local headerName = panelName .. "FrameHeader"
	LAM:AddHeader(panelId, headerName, "Frame")
	LAM:AddCheckbox(panelId, headerName.."Lock", "Lock Warning Frame", "Lock or move warning frame?",
		function()
			return not self.vars.bWarningMovable
		end,
		function(bLock)
			self.vars.bWarningMovable = not bLock
			self:UpdateWarningMovable()
		end)
	
	headerName = panelName .. "TextHeader"
	LAM:AddHeader(panelId, headerName, "Text")
--function lam:AddDescription(panelID, controlName, text, titleText)
	local descText = "Use \"%\" as the KOS name => \"Warning!! % is around\" will give \"Warning!! Rosie is around\""
	LAM:AddDescription(panelId, headerName.."Desc", descText)

--function lam:AddEditBox(panelID, controlName, text, tooltip, isMultiLine, getFunc, setFunc, warning, warningText)	
	LAM:AddEditBox(panelId, headerName.."Text", "Warning Text", "Set the text when a KOS name is on target", 
		false,
		function()
			return self.vars.warningText;
		end,
		function(value)
			self.vars.warningText = value
			self:ShowWarning("Rosie")
		end);
	
	headerName = panelName .. "FontHeader"
	LAM:AddHeader(panelId, headerName, "Font")
	
	-- Font family
	LAM:AddDropdown(panelId,headerName.."Family","Family","Set the font family of the warning text",
		LMP:List('font'),
		function() return self.vars.fontFamily end,
		function(value) 
				self.vars.fontFamily=value 
				self:UpdateFont()
				self:ShowWarning("Rosie")
		end)
	
	-- Font size
	LAM:AddSlider(panelId,headerName.."Size","Size","Set the font size of the warning text",
		12,
		48,
		1,
		function() return self.vars.fontSize end,
		function(value) 
			self.vars.fontSize = value
			self:UpdateFont()
			self:ShowWarning("Rosie")
		end)
		
	-- Font style
	LAM:AddDropdown(panelId,headerName.."Style","Style","Add borders and shadows for the warning text",
		self.styles,
		function() return self.vars.fontStyle end,
		function(value)
			self.vars.fontStyle = value
			self:UpdateFont()
			self:ShowWarning("Rosie")
		end)
		
		
	-- Font color
	LAM:AddColorPicker(panelId,headerName.."Color","Color","Set the color of the warning text",
		function() return unpack(self.vars.fontColor) end,
		function(r, g, b, a) 
			self.vars.fontColor = {r,g,b,a}
			self:UpdateFont()
			self:ShowWarning("Rosie")
		end)
	
	-- groups options
	headerName = panelName .. "GroupHeader"
	LAM:AddHeader(panelId, headerName, "Group")
	
	for idg = 1, MAX_GROUP do
	
		LAM:AddDescription(panelId, headerName.."Desc"..tostring(idg), "Group #"..tostring(idg))
		LAM:AddEditBox(panelId, headerName.."Text"..tostring(idg), "Warning Text", "Set the text when a group#"..tostring(idg).." KOS name is on target", 
		false,
		function()
			return self:GetGroupWarning(idg);
		end,
		function(value)
			self:SetGroupWarningText(idg,value)
			self:ShowWarningGroup(idg,"Rosie")
		end);
		LAM:AddColorPicker(panelId,headerName.."Color"..tostring(idg),"Color","Set the color of the warning text of group#"..tostring(idg),
		function() local gt, gc =  self:GetGroupWarning(idg)
			return unpack(gc) end,
		function(r, g, b, a) 
			self:SetGroupWarningColor(idg,{r,g,b,a})
			--self:UpdateFont()
			self:ShowWarningGroup(idg,"Rosie")
		end)
	
	
	end
end
