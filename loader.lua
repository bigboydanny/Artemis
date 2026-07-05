local ArtemisUI = {}

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local lp  = Players.LocalPlayer
local pgu = lp:WaitForChild("PlayerGui")

local SHADOW_IMG   = "rbxassetid://6014261993"
local SHADOW_SLICE = Rect.new(49, 49, 450, 450)

local R = { win=12, card=10, elem=7, track=3, toggle=10, ind=2, knob=6 }

local WIN_W, WIN_H = 720, 440
local TOPBAR_H     = 46
local TABBAR_H     = 38
local CONTENT_H    = WIN_H - TOPBAR_H - TABBAR_H

local Icons  = nil
local Icons2 = nil

task.spawn(function()
	local ok, r = pcall(function() return loadstring(game:HttpGet("https://artemisgg.vercel.app//Icons.lua"))() end)
	if ok then Icons = r end
end)

local function getIcon(name)
	if not Icons then return nil end
	name = string.match(string.lower(name),"^%s*(.-)%s*$")
	local s = Icons["48px"]; if not s then return nil end
	local r = s[name]; if not r then return nil end
	if type(r[1])~="number" or type(r[2])~="table" or type(r[3])~="table" then return nil end
	return {id=r[1], imageRectSize=Vector2.new(r[2][1],r[2][2]), imageRectOffset=Vector2.new(r[3][1],r[3][2])}
end

local function getIcon2(name)
	if not Icons2 then return nil end
	name = string.match(string.lower(name),"^%s*(.-)%s*$")
	local s = Icons2["48px"]; if not s then return nil end
	local r = s[name]; if not r then return nil end
	if type(r[1])~="number" or type(r[2])~="table" or type(r[3])~="table" then return nil end
	return {id=r[1], imageRectSize=Vector2.new(r[2][1],r[2][2]), imageRectOffset=Vector2.new(r[3][1],r[3][2])}
end

local function avatarThumb(uid, w, h)
	return "rbxthumb://type=AvatarHeadShot&id="..uid.."&w="..(w or 150).."&h="..(h or 150)
end

local function parseLabel(str)
	local c = str:sub(1,1)
	if c=="@" then
		local src, t = str:match("^@image%-(%S+)%s+(.+)$")
		if not src then src = str:match("^@image%-(%S+)$"); t = "" end
		if src then return src, (t or ""), 3 end
		local n, t2 = str:match("^@([%w%-_]+)%s+(.+)$")
		if not n then n = str:match("^@([%w%-_]+)$"); t2 = "" end
		if n then return n:lower(), (t2 or ""), 2 end; return nil, str:sub(2), 1
	elseif c=="#" then
		local n, t = str:match("^#([%w%-_]+)%s+(.+)$")
		if not n then n = str:match("^#([%w%-_]+)$"); t = "" end
		if n then return n:lower(), (t or ""), 1 end; return nil, str:sub(2), 1
	end
	return nil, str, 1
end

local function safeCall(fn, ...)
	if not fn then return true end
	local ok, err = pcall(fn, ...)
	if not ok then warn("[ArtemisUI] "..tostring(err)) end
	return ok, err
end

local function saveConfig(file, flags)
	if not(file and writefile and flags) then return end
	local ok, enc = pcall(function() return game:GetService("HttpService"):JSONEncode(flags) end)
	if not ok or not enc then return end
	pcall(function() makefolder("ArtemisUI"); writefile("ArtemisUI/"..file..".json", enc) end)
end

local function loadConfig(file, flags)
	if not(file and isfile and readfile and flags) then return end
	local ok, raw = pcall(readfile, "ArtemisUI/"..file..".json")
	if not ok or not raw or raw=="" then return end
	local ok2, data = pcall(function() return game:GetService("HttpService"):JSONDecode(raw) end)
	if not ok2 or type(data)~="table" then
		pcall(function() writefile("ArtemisUI/"..file..".json", "{}") end)
		return
	end
	for k, v in pairs(data) do flags[k] = v end
end

local THEMES = {
	Valence = {
		bg0=Color3.fromRGB(7,7,10),    bg1=Color3.fromRGB(12,12,17),
		bg2=Color3.fromRGB(17,17,25),  bg3=Color3.fromRGB(24,24,36),
		bg4=Color3.fromRGB(32,32,48),  brd0=Color3.fromRGB(40,40,60),
		brd1=Color3.fromRGB(55,55,80), textHi=Color3.fromRGB(248,246,255),
		textMid=Color3.fromRGB(150,146,182), textLo=Color3.fromRGB(70,67,104),
		white=Color3.fromRGB(255,255,255), red=Color3.fromRGB(240,65,65),
	},
	Midnight = {
		bg0=Color3.fromRGB(4,6,14),    bg1=Color3.fromRGB(7,10,22),
		bg2=Color3.fromRGB(10,15,32),  bg3=Color3.fromRGB(14,21,44),
		bg4=Color3.fromRGB(19,29,58),  brd0=Color3.fromRGB(28,44,82),
		brd1=Color3.fromRGB(42,64,116),textHi=Color3.fromRGB(220,230,255),
		textMid=Color3.fromRGB(108,132,188), textLo=Color3.fromRGB(46,62,110),
		white=Color3.fromRGB(255,255,255), red=Color3.fromRGB(240,65,65),
	},
	Obsidian = {
		bg0=Color3.fromRGB(5,5,5),     bg1=Color3.fromRGB(10,10,10),
		bg2=Color3.fromRGB(15,15,15),  bg3=Color3.fromRGB(21,21,21),
		bg4=Color3.fromRGB(29,29,29),  brd0=Color3.fromRGB(44,44,44),
		brd1=Color3.fromRGB(62,62,62), textHi=Color3.fromRGB(245,245,245),
		textMid=Color3.fromRGB(152,152,152), textLo=Color3.fromRGB(70,70,70),
		white=Color3.fromRGB(255,255,255), red=Color3.fromRGB(240,65,65),
	},
	Dusk = {
		bg0=Color3.fromRGB(12,7,16),   bg1=Color3.fromRGB(18,11,25),
		bg2=Color3.fromRGB(25,15,34),  bg3=Color3.fromRGB(34,20,47),
		bg4=Color3.fromRGB(45,26,62),  brd0=Color3.fromRGB(66,38,90),
		brd1=Color3.fromRGB(90,52,122),textHi=Color3.fromRGB(252,244,255),
		textMid=Color3.fromRGB(170,138,200), textLo=Color3.fromRGB(82,56,112),
		white=Color3.fromRGB(255,255,255), red=Color3.fromRGB(240,65,65),
	},
	Carbon = {
		bg0=Color3.fromRGB(7,8,10),    bg1=Color3.fromRGB(11,13,16),
		bg2=Color3.fromRGB(16,19,23),  bg3=Color3.fromRGB(22,26,31),
		bg4=Color3.fromRGB(30,35,42),  brd0=Color3.fromRGB(44,52,62),
		brd1=Color3.fromRGB(62,72,86), textHi=Color3.fromRGB(234,238,245),
		textMid=Color3.fromRGB(130,142,160), textLo=Color3.fromRGB(58,68,82),
		white=Color3.fromRGB(255,255,255), red=Color3.fromRGB(240,65,65),
	},
	Ember = {
		bg0=Color3.fromRGB(10,6,4),    bg1=Color3.fromRGB(16,9,5),
		bg2=Color3.fromRGB(22,13,7),   bg3=Color3.fromRGB(30,18,9),
		bg4=Color3.fromRGB(40,24,12),  brd0=Color3.fromRGB(62,36,16),
		brd1=Color3.fromRGB(88,50,22), textHi=Color3.fromRGB(255,242,226),
		textMid=Color3.fromRGB(192,148,108), textLo=Color3.fromRGB(102,66,36),
		white=Color3.fromRGB(255,255,255), red=Color3.fromRGB(240,65,65),
	},
}

local THEME_ACCENTS = {
	Valence  = Color3.fromRGB(108,99,255),
	Midnight = Color3.fromRGB(64,140,255),
	Obsidian = Color3.fromRGB(214,214,214),
	Dusk     = Color3.fromRGB(189,88,222),
	Carbon   = Color3.fromRGB(56,189,204),
	Ember    = Color3.fromRGB(255,133,51),
}

local BASE = {}
for k, v in pairs(THEMES.Valence) do BASE[k] = v end

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end

local function mkIcon(parent, iconName, size, col, zi, lib)
	local img = new("ImageLabel",{Size=UDim2.new(0,size,0,size),BackgroundTransparency=1,ImageColor3=col,ZIndex=zi or 4},parent)
	if lib==3 then
		local src=iconName
		if src:match("^%d+$") then src="rbxassetid://"..src
		elseif not src:match("^rbxassetid://") and not src:match("^rbxthumb://") and not src:match("^rbxasset://") and not src:match("^https?://") then
			src="rbxassetid://"..src
		end
		img.Image=src; img.ImageColor3=Color3.new(1,1,1)
		return img
	end
	task.spawn(function()
		local dl = tick()+6; local asset
		if lib==2 then while not Icons2 and tick()<dl do task.wait(0.1) end; asset=getIcon2(iconName)
		else while not Icons and tick()<dl do task.wait(0.1) end; asset=getIcon(iconName) end
		if asset and img.Parent then img.Image="rbxassetid://"..asset.id; img.ImageRectSize=asset.imageRectSize; img.ImageRectOffset=asset.imageRectOffset end
	end)
	return img
end

local function colorToHex(c)
	return string.format("%02X%02X%02X",math.clamp(math.round(c.R*255),0,255),math.clamp(math.round(c.G*255),0,255),math.clamp(math.round(c.B*255),0,255))
end

local function hexToColor(hex)
	hex=hex:gsub("#",""):upper(); if #hex~=6 then return nil end
	local r=tonumber(hex:sub(1,2),16); local g=tonumber(hex:sub(3,4),16); local b=tonumber(hex:sub(5,6),16)
	if not(r and g and b) then return nil end; return Color3.fromRGB(r,g,b)
end

local function corner(px,p) new("UICorner",{CornerRadius=UDim.new(0,px)},p) end
local function outline(col,thick,p) return new("UIStroke",{Color=col,Thickness=thick,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},p) end
local function inset(t,b,l,r,p) new("UIPadding",{PaddingTop=UDim.new(0,t),PaddingBottom=UDim.new(0,b),PaddingLeft=UDim.new(0,l),PaddingRight=UDim.new(0,r)},p) end
local function vstack(gap,p) new("UIListLayout",{Padding=UDim.new(0,gap),FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder,HorizontalAlignment=Enum.HorizontalAlignment.Left,VerticalAlignment=Enum.VerticalAlignment.Top},p) end

local function tw(o,t,props,style,dir) TweenService:Create(o,TweenInfo.new(t,style or Enum.EasingStyle.Exponential,dir or Enum.EasingDirection.Out),props):Play() end
local function twQuint(o,t,props) TweenService:Create(o,TweenInfo.new(t,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),props):Play() end
local function twBack(o,t,props) TweenService:Create(o,TweenInfo.new(t,Enum.EasingStyle.Back,Enum.EasingDirection.Out),props):Play() end
local function twHover(o,t,props) TweenService:Create(o,TweenInfo.new(t,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),props):Play() end

local function spawnOrbit(parent,cx,cy,radius,color,count)
	count=count or 6
	local dots={}
	for i=1,count do
		local d=new("Frame",{Size=UDim2.new(0,4,0,4),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=color,BackgroundTransparency=1,BorderSizePixel=0,ZIndex=503},parent)
		corner(99,d); dots[i]=d
	end
	local running=true; local conn
	local t0=tick()
	conn=RunService.RenderStepped:Connect(function()
		if not running then return end
		local t=(tick()-t0)*3.2
		for i,d in ipairs(dots) do
			if d.Parent then
				local a=t+(i-1)*(2*math.pi/count)
				d.Position=UDim2.new(0.5,cx+math.cos(a)*radius,0,cy+math.sin(a)*radius)
				d.BackgroundTransparency=1-(0.18+0.62*((math.sin(a-1.15)+1)/2))
			end
		end
	end)
	return function()
		running=false; if conn then conn:Disconnect() end
		for _,d in ipairs(dots) do if d.Parent then tw(d,0.22,{BackgroundTransparency=1}) end end
	end
end

local function fadeGuiTreeOut(root,dur,style)
	style=style or Enum.EasingStyle.Exponential; local tweens={}
	local function add(obj,prop,target) table.insert(tweens,TweenService:Create(obj,TweenInfo.new(dur,style,Enum.EasingDirection.Out),{[prop]=target})) end
	add(root,"BackgroundTransparency",1)
	for _,d in ipairs(root:GetDescendants()) do
		if d:IsA("UIStroke") then add(d,"Transparency",1)
		elseif d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then add(d,"TextTransparency",1)
		elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then add(d,"ImageTransparency",1)
		elseif d:IsA("Frame") and d~=root then add(d,"BackgroundTransparency",1) end
	end
	for _,t in ipairs(tweens) do t:Play() end
end

local function mkShadow(parent,color,alpha,zi)
	return new("ImageLabel",{
		Image=SHADOW_IMG, ImageColor3=color, ImageTransparency=alpha,
		ScaleType=Enum.ScaleType.Slice, SliceCenter=SHADOW_SLICE,
		Size=UDim2.new(1,54,1,54), Position=UDim2.new(0,-27,0,-27),
		BackgroundTransparency=1, ZIndex=zi or 1,
	},parent)
end

local function mkGlowLine(parent,color,alpha,zi)
	local f=new("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=color,BackgroundTransparency=alpha or 0.4,BorderSizePixel=0,ZIndex=zi or 3},parent)
	new("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.08,0),NumberSequenceKeypoint.new(0.92,0),NumberSequenceKeypoint.new(1,1)})},f)
	return f
end

local function ripple(parent,col,scale)
	local rip=new("Frame",{Size=UDim2.new(0,0,0,0),Position=UDim2.new(0.5,0,0.5,0),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=col,BackgroundTransparency=0.6,BorderSizePixel=0,ZIndex=22},parent)
	corner(99,rip); tw(rip,0.5,{Size=UDim2.new((scale or 2.2),0,(scale or 2.2)+2,0),BackgroundTransparency=1},Enum.EasingStyle.Quad)
	task.delay(0.5,function() if rip.Parent then rip:Destroy() end end)
end

local function draggable(handle,frame,also)
	local on,o0,p0,ap0=false,nil,nil,{}
	handle.InputBegan:Connect(function(i)
		if i.UserInputType~=Enum.UserInputType.MouseButton1 and i.UserInputType~=Enum.UserInputType.Touch then return end
		on=true; o0=i.Position; p0=frame.Position
		for _,f in ipairs(also or {}) do ap0[f]=f.Position end
	end)
	handle.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then on=false end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if not on or (i.UserInputType~=Enum.UserInputType.MouseMovement and i.UserInputType~=Enum.UserInputType.Touch) then return end
		local d=i.Position-o0; frame.Position=UDim2.new(p0.X.Scale,p0.X.Offset+d.X,p0.Y.Scale,p0.Y.Offset+d.Y)
		for _,f in ipairs(also or {}) do local s=ap0[f]; if s then f.Position=UDim2.new(s.X.Scale,s.X.Offset+d.X,s.Y.Scale,s.Y.Offset+d.Y) end end
	end)
end

local MB_NAMES={[Enum.UserInputType.MouseButton1]="MB1",[Enum.UserInputType.MouseButton2]="MB2",[Enum.UserInputType.MouseButton3]="MB3"}
local MB_TYPES={MB1=Enum.UserInputType.MouseButton1,MB2=Enum.UserInputType.MouseButton2,MB3=Enum.UserInputType.MouseButton3}

local function resolveKeyDisplay(kd)
	if not kd then return "—" end
	if kd.mouse then return kd.name end
	return tostring(kd.keyCode):gsub("Enum%.KeyCode%.","")
end

local function keyDataFromDefault(default)
	if not default then return nil end
	if typeof(default)=="EnumItem" then return {mouse=false,keyCode=default,name=tostring(default):gsub("Enum%.KeyCode%.","")} end
	if type(default)=="string" then
		if MB_TYPES[default] then return {mouse=true,inputType=MB_TYPES[default],name=default} end
		local ok,kc=pcall(function() return Enum.KeyCode[default] end)
		if ok and kc then return {mouse=false,keyCode=kc,name=default} end
	end
	return nil
end

function ArtemisUI:Window(cfg)
	cfg=cfg or {}
	local WIN_W       = cfg.Width  or WIN_W
	local WIN_H       = cfg.Height or WIN_H
	local TITLE       = cfg.Title            or "ArtemisUI"
	local SUB         = cfg.Subtitle         or ""
	local ACCENT      = cfg.Accent           or Color3.fromRGB(108,99,255)
	local CONFIG_FILE = cfg.ConfigFile       or nil
	local LOAD_ANIM   = cfg.LoadingAnimation or 1
	local FADE_TOGGLE = cfg.FadeToggle       == true
	local LOGO_ID     = cfg.LogoId          or ""
	local TAB_SIDE    = cfg.TabPosition=="top" and "top" or "left"
	local RAIL_MIN    = cfg.SidebarWidth or 54
	local RAIL_MAX    = cfg.SidebarExpandedWidth or 176
	local PROFILE_H   = 58
	local PROFILE_NAME= cfg.ProfileName or lp.DisplayName or lp.Name
	local PROFILE_SUB = cfg.ProfileSubtext or ""
	local BAR_H       = TAB_SIDE=="top" and TABBAR_H or 0
	local BAR_W       = TAB_SIDE=="left" and RAIL_MIN or 0
	local CONTENT_H   = WIN_H - TOPBAR_H - BAR_H
	local FLAGS       = {}
	local flagHandlers= {}
	local toggleKey   = nil

	pcall(function()
		local e=game:GetService("CoreGui"):FindFirstChild("ArtemisUI"); if e then e:Destroy() end
	end)

	if cfg.AltIconLibrary and not Icons2 then
		task.spawn(function()
			local ok,r=pcall(function() return loadstring(game:HttpGet(cfg.AltIconLibrary))() end)
			if ok then Icons2=r end
		end)
	end

	if CONFIG_FILE then pcall(function() makefolder("ArtemisUI") end); loadConfig(CONFIG_FILE,FLAGS) end

	local function resolveTheme(name)
		if not name then return nil, nil end
		local t = THEMES[name]
		if t then return t, name end
		local lower = tostring(name):lower()
		for k,v in pairs(THEMES) do if k:lower()==lower then return v, k end end
		return nil, nil
	end

	local loadedThemeName = nil
	if FLAGS["__theme"] then
		local t, resolved = resolveTheme(FLAGS["__theme"])
		if t then for k,v in pairs(t) do BASE[k]=v end; FLAGS["__theme"]=resolved; loadedThemeName=resolved end
	end
	if FLAGS["__accent"] and type(FLAGS["__accent"])=="table" then
		local a = FLAGS["__accent"]
		if a[1] and a[2] and a[3] then ACCENT = Color3.new(a[1],a[2],a[3]) end
	elseif loadedThemeName and THEME_ACCENTS[loadedThemeName] then
		ACCENT = THEME_ACCENTS[loadedThemeName]
	end
	if FLAGS["__tabside"]=="left" or FLAGS["__tabside"]=="top" then TAB_SIDE=FLAGS["__tabside"] end
	if FLAGS["__togglekey"] then
		local ok,kc=pcall(function() return Enum.KeyCode[FLAGS["__togglekey"]] end)
		if ok and kc then toggleKey=kc end
	end
	BAR_H     = TAB_SIDE=="top" and TABBAR_H or 0
	BAR_W     = TAB_SIDE=="left" and RAIL_MIN or 0
	CONTENT_H = WIN_H - TOPBAR_H - BAR_H
	local AccentRefs = {}
	local ThemeRefs  = {}
	local rainbowConn = nil
	local tabs={}; local tabBtns={}; local activeTab=nil
	local railOpen=false; local railRows={}
	local activateTab
	local moveTabIndicator
	local applyProfileLayout

	local function buildC()
		local r255,g255,b255 = ACCENT.R*255, ACCENT.G*255, ACCENT.B*255
		return {
			ac      = ACCENT,
			acDim   = Color3.fromRGB(math.clamp(math.floor(r255*0.14),0,255),math.clamp(math.floor(g255*0.14),0,255),math.clamp(math.floor(b255*0.14),0,255)),
			acMid   = Color3.fromRGB(math.clamp(math.floor(r255*0.48),0,255),math.clamp(math.floor(g255*0.48),0,255),math.clamp(math.floor(b255*0.48),0,255)),
			acLight = Color3.fromRGB(math.clamp(math.floor(r255+(255-r255)*0.5),0,255),math.clamp(math.floor(g255+(255-g255)*0.5),0,255),math.clamp(math.floor(b255+(255-b255)*0.5),0,255)),
		}
	end

	local C = setmetatable(buildC(), {__index=BASE})

	local function regAc(obj, prop, mod)
		if obj then table.insert(AccentRefs,{obj,prop,mod}) end; return obj
	end
	local function regAcIf(obj, prop, condFn, mod)
		if obj then table.insert(AccentRefs,{obj,prop,mod,condFn}) end; return obj
	end
	local function regTh(obj, prop, key, condFn)
		if obj then table.insert(ThemeRefs,{obj,prop,key,condFn}) end; return obj
	end
	local function applyTheme()
		for _,ref in ipairs(ThemeRefs) do
			local obj,prop,key,cond = ref[1],ref[2],ref[3],ref[4]
			if obj and obj.Parent and (not cond or cond()) then obj[prop]=C[key] end
		end
	end

	local function ApplyAccent(newAc)
		ACCENT = newAc
		local r255,g255,b255 = newAc.R*255, newAc.G*255, newAc.B*255
		C.ac      = newAc
		C.acDim   = Color3.fromRGB(math.clamp(math.floor(r255*0.14),0,255),math.clamp(math.floor(g255*0.14),0,255),math.clamp(math.floor(b255*0.14),0,255))
		C.acMid   = Color3.fromRGB(math.clamp(math.floor(r255*0.48),0,255),math.clamp(math.floor(g255*0.48),0,255),math.clamp(math.floor(b255*0.48),0,255))
		C.acLight = Color3.fromRGB(math.clamp(math.floor(r255+(255-r255)*0.5),0,255),math.clamp(math.floor(g255+(255-g255)*0.5),0,255),math.clamp(math.floor(b255+(255-b255)*0.5),0,255))
		for _,ref in ipairs(AccentRefs) do
			local obj,prop,mod,cond = ref[1],ref[2],ref[3],ref[4]
			if obj and obj.Parent and (not cond or cond()) then
				obj[prop] = mod=="dim" and C.acDim or mod=="mid" and C.acMid or mod=="light" and C.acLight or ACCENT
			end
		end
		if activeTab then activateTab(activeTab) end
	end

	local gui=new("ScreenGui",{Name="ArtemisUI",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Global,DisplayOrder=999,IgnoreGuiInset=true},game.CoreGui)

	local shHolder=new("Frame",{Size=UDim2.new(0,WIN_W,0,WIN_H),Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=1},gui)
	corner(R.win,shHolder)
	local shadowOn=cfg.Shadow==true
	local shadowImg=mkShadow(shHolder,Color3.new(0,0,0),shadowOn and 0.5 or 1,1)

	local win=new("Frame",{Name="Win",Size=UDim2.new(0,WIN_W,0,WIN_H),Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2),BackgroundColor3=C.bg1,BorderSizePixel=0,ClipsDescendants=true,ZIndex=2},gui)
	regTh(win,"BackgroundColor3","bg1")
	local ViewSz=workspace.CurrentCamera.ViewportSize
	local AutoScale=math.clamp(math.min(ViewSz.X/1280,ViewSz.Y/720),0.65,1.25)
	local uiScale=new("UIScale",{Scale=getgenv().Scale or AutoScale},win)
	corner(R.win,win)
	local winChrome=new("Frame",{Name="Chrome",Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=900},win)
	corner(R.win,winChrome); local winStroke=outline(Color3.fromRGB(120,120,128),1,winChrome)
	winStroke.Transparency=0.45

	win.AnchorPoint = Vector2.new(0.5, 0.5)
	shHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	win.Size = UDim2.new(0, 0, 0, 0); win.Position = UDim2.new(0.5, 0, 0.5, 0)
	shHolder.Size = UDim2.new(0, 0, 0, 0); shHolder.Position = UDim2.new(0.5, 0, 0.5, 0)

	local FULL_SIZE=UDim2.new(0,WIN_W,0,WIN_H)
	local FULL_POS =UDim2.new(0.5,0,0.5,0)
	local MIN_SIZE =UDim2.new(0,WIN_W,0,TOPBAR_H+BAR_H)
	local savedWinPos=FULL_POS; local savedShPos=FULL_POS

	local fadeOverlay
	if FADE_TOGGLE then fadeOverlay=new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=C.bg0,BackgroundTransparency=1,BorderSizePixel=0,ZIndex=997},win) end

	local function revealMainWindow()
		local targetScale=getgenv().Scale or 1; uiScale.Scale=targetScale*0.88
		twBack(win,0.52,{Size=FULL_SIZE,Position=FULL_POS}); twBack(shHolder,0.52,{Size=FULL_SIZE,Position=FULL_POS})
		task.delay(0.08,function()
			twBack(uiScale,0.45,{Scale=targetScale}); tw(winStroke,0.6,{Color=ACCENT,Transparency=0.3})
			task.delay(0.8,function() tw(winStroke,0.9,{Color=C.brd0,Transparency=0}) end)
		end)
	end

	local removeBlur=function() end; local KeyInput=nil

	local function setupKeySystem(afterPass)
		local KS=cfg.KeySystem
		if not KS or type(KS)~="table" then afterPass(); return end
		local KS_TITLE=KS.Title or "Key Required"; local KS_SUB=KS.Subtitle or "Enter your key to continue."
		local KS_HOLDER=KS.Placeholder or "Paste key here..."; local KS_URL=KS.GetKeyUrl; local KS_VALIDATE=KS.OnValidate
		local CW,CH=420,196
		local ksGui=new("ScreenGui",{Name="ArtemisKeySystem",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Global,DisplayOrder=1001,IgnoreGuiInset=true},game.CoreGui)
		local blur=Instance.new("BlurEffect"); blur.Size=0; blur.Parent=game:GetService("Lighting"); tw(blur,0.32,{Size=20})
		removeBlur=function() tw(blur,0.22,{Size=0}); task.delay(0.25,function() blur:Destroy() end) end
		local backdrop=new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=10},ksGui)
		local cardSh=new("Frame",{Size=UDim2.new(0,CW,0,CH),Position=UDim2.new(0.5,-CW/2,0.5,-CH/2),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=11},ksGui)
		mkShadow(cardSh,Color3.new(0,0,0),0.25,11)
		local card=new("Frame",{Size=UDim2.new(0,CW,0,CH),Position=UDim2.new(0.5,-CW/2,0.56,-CH/2),BackgroundColor3=C.bg2,BackgroundTransparency=1,BorderSizePixel=0,ZIndex=12},ksGui)
		corner(R.card,card); new("UIScale",{Scale=getgenv().Scale or 1},card)
		local cardStroke=outline(C.brd0,1,card); mkGlowLine(card,ACCENT,0.55,14)
		local closeBtn2=new("TextButton",{Size=UDim2.new(0,18,0,18),Position=UDim2.new(1,-14,0,10),AnchorPoint=Vector2.new(1,0),BackgroundColor3=C.bg3,Text="×",TextColor3=C.textLo,Font=Enum.Font.GothamBold,TextSize=13,BorderSizePixel=0,ZIndex=15},card)
		corner(R.elem,closeBtn2); outline(C.brd0,1,closeBtn2)
		closeBtn2.MouseEnter:Connect(function() tw(closeBtn2,0.15,{BackgroundColor3=BASE.red,TextColor3=BASE.white}) end)
		closeBtn2.MouseLeave:Connect(function() tw(closeBtn2,0.2,{BackgroundColor3=C.bg3,TextColor3=C.textLo}) end)
		closeBtn2.MouseButton1Click:Connect(function() removeBlur(); tw(card,0.22,{BackgroundTransparency=1}); tw(backdrop,0.25,{BackgroundTransparency=1}); task.delay(0.26,function() ksGui:Destroy() end) end)
		local dot2=new("Frame",{Size=UDim2.new(0,5,0,5),Position=UDim2.new(0,16,0,14),BackgroundColor3=ACCENT,BorderSizePixel=0,ZIndex=14},card); corner(3,dot2)
		new("TextLabel",{Size=UDim2.new(1,-40,0,14),Position=UDim2.new(0,26,0,9),BackgroundTransparency=1,Text=KS_TITLE,TextColor3=C.textHi,Font=Enum.Font.GothamBold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=14},card)
		local kDiv=new("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,0,34),BackgroundColor3=C.brd0,BorderSizePixel=0,ZIndex=13},card)
		new("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.06,0),NumberSequenceKeypoint.new(0.94,0),NumberSequenceKeypoint.new(1,1)})},kDiv)
		local body2=new("Frame",{Size=UDim2.new(1,-32,1,-44),Position=UDim2.new(0,16,0,44),BackgroundTransparency=1,ZIndex=13},card)
		new("TextLabel",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,Text=KS_SUB,TextColor3=C.textLo,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,ZIndex=13},body2)
		local inputWrap=new("Frame",{Size=UDim2.new(1,0,0,36),Position=UDim2.new(0,0,0,34),BackgroundColor3=C.bg3,BorderSizePixel=0,ZIndex=13},body2)
		corner(R.elem,inputWrap); local inputStroke=outline(C.brd1,1,inputWrap)
		local inputBox=new("TextBox",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",PlaceholderText=KS_HOLDER,TextColor3=C.textHi,PlaceholderColor3=C.textLo,Font=Enum.Font.GothamSemibold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,BorderSizePixel=0,ZIndex=14},inputWrap)
		inset(0,0,12,12,inputBox)
		inputBox.Focused:Connect(function() tw(inputStroke,0.15,{Color=ACCENT,Thickness=1.5}); tw(inputWrap,0.15,{BackgroundColor3=C.acDim}) end)
		inputBox.FocusLost:Connect(function() tw(inputStroke,0.2,{Color=C.brd1,Thickness=1}); tw(inputWrap,0.2,{BackgroundColor3=C.bg3}) end)
		KeyInput={Get=function() return inputBox.Text end}
		local statusLbl=new("TextLabel",{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,0,80),BackgroundTransparency=1,Text="",TextColor3=BASE.red,Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=13},body2)
		local btnY=98
		if KS_URL then
			local gkb=new("TextButton",{Size=UDim2.new(0.48,0,0,32),Position=UDim2.new(0,0,0,btnY),BackgroundColor3=C.bg3,Text="Get Key  →",TextColor3=C.textMid,Font=Enum.Font.GothamSemibold,TextSize=11,BorderSizePixel=0,ZIndex=13},body2)
			corner(R.elem,gkb); outline(C.brd1,1,gkb)
			gkb.MouseEnter:Connect(function() tw(gkb,0.15,{BackgroundColor3=C.bg4,TextColor3=C.acLight}) end)
			gkb.MouseLeave:Connect(function() tw(gkb,0.2,{BackgroundColor3=C.bg3,TextColor3=C.textMid}) end)
			gkb.MouseButton1Click:Connect(function() pcall(function() game:GetService("GuiService"):OpenBrowserWindow(KS_URL) end) end)
		end
		local valX=KS_URL and UDim2.new(0.52,0,0,btnY) or UDim2.new(0,0,0,btnY)
		local valW=KS_URL and UDim2.new(0.48,0,0,32) or UDim2.new(1,0,0,32)
		local validateBtn=new("TextButton",{Size=valW,Position=valX,BackgroundColor3=C.acDim,Text="Validate",TextColor3=ACCENT,Font=Enum.Font.GothamBold,TextSize=11,BorderSizePixel=0,ZIndex=13},body2)
		corner(R.elem,validateBtn); local valStroke=outline(ACCENT,1,validateBtn)
		validateBtn.MouseEnter:Connect(function() tw(validateBtn,0.15,{BackgroundColor3=C.acDim,TextColor3=C.acLight}) end)
		validateBtn.MouseLeave:Connect(function() tw(validateBtn,0.2,{BackgroundColor3=C.acDim,TextColor3=ACCENT}) end)
		draggable(card,card,{cardSh})
		local validating=false
		local function shakeCard()
			local o=card.Position; local os=cardSh.Position
			for _,dx in ipairs({8,-8,6,-6,4,-4,2,-2}) do
				card.Position=UDim2.new(o.X.Scale,o.X.Offset+dx,o.Y.Scale,o.Y.Offset)
				cardSh.Position=UDim2.new(os.X.Scale,os.X.Offset+dx,os.Y.Scale,os.Y.Offset)
				task.wait(0.025)
			end
			card.Position=o; cardSh.Position=os
		end
		validateBtn.MouseButton1Click:Connect(function()
			if validating then return end
			validating=true; validateBtn.Text="Checking..."; tw(validateBtn,0.15,{BackgroundColor3=C.bg4,TextColor3=C.textLo})
			local passed=false
			if KS_VALIDATE then local ok,r=pcall(KS_VALIDATE,KeyInput); passed=ok and r==true end
			if passed then
				statusLbl.Text=""; validateBtn.Text="✓  Accepted"
				tw(validateBtn,0.2,{BackgroundColor3=Color3.fromRGB(15,58,32),TextColor3=Color3.fromRGB(60,195,100)})
				tw(valStroke,0.2,{Color=Color3.fromRGB(40,160,75)}); tw(cardStroke,0.25,{Color=Color3.fromRGB(40,160,75)})
				task.wait(0.65); removeBlur(); tw(card,0.28,{BackgroundTransparency=1}); tw(backdrop,0.32,{BackgroundTransparency=1})
				task.wait(0.32); ksGui:Destroy(); afterPass()
			else
				task.spawn(shakeCard)
				tw(validateBtn,0.15,{BackgroundColor3=Color3.fromRGB(48,12,12),TextColor3=BASE.red})
				tw(valStroke,0.15,{Color=BASE.red}); tw(cardStroke,0.15,{Color=BASE.red})
				tw(inputStroke,0.15,{Color=BASE.red}); tw(inputWrap,0.15,{BackgroundColor3=Color3.fromRGB(32,10,10)})
				statusLbl.Text="Invalid key — please try again."
				task.wait(1.2); validateBtn.Text="Validate"
				tw(validateBtn,0.28,{BackgroundColor3=C.acDim,TextColor3=ACCENT}); tw(valStroke,0.28,{Color=ACCENT})
				tw(cardStroke,0.28,{Color=C.brd0}); tw(inputStroke,0.28,{Color=C.brd1}); tw(inputWrap,0.28,{BackgroundColor3=C.bg3})
				validating=false
			end
		end)
		tw(backdrop,0.32,{BackgroundTransparency=0.45})
		twBack(card,0.38,{BackgroundTransparency=0,Position=UDim2.new(0.5,-CW/2,0.5,-CH/2)})
		twBack(cardSh,0.38,{Position=UDim2.new(0.5,-CW/2,0.5,-CH/2)})
		task.delay(0.26,function() task.defer(function() inputBox:CaptureFocus() end) end)
	end

	if LOAD_ANIM==1 then
		local loaderGui=new("ScreenGui",{Name="ArtemisLoader",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Global,DisplayOrder=1000,IgnoreGuiInset=true},game.CoreGui)
		local loader=new("Frame",{Name="Loader",Size=UDim2.new(1,0,1,0),BackgroundColor3=C.bg0,BorderSizePixel=0,ZIndex=500},loaderGui)
		local topBar=new("Frame",{Size=UDim2.new(0,0,0,2),Position=UDim2.new(0,0,0,0),BackgroundColor3=ACCENT,BorderSizePixel=0,ZIndex=504},loader)
		local center=new("Frame",{Size=UDim2.new(0,320,0,110),Position=UDim2.new(0.5,-160,0.5,-55),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=501},loader)
		local ldot=new("Frame",{Size=UDim2.new(0,0,0,0),Position=UDim2.new(0.5,0,0,0),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=ACCENT,BorderSizePixel=0,ZIndex=503},center); corner(99,ldot)
		local lTitle=new("TextLabel",{Size=UDim2.new(1,0,0,36),Position=UDim2.new(0,0,0,18),BackgroundTransparency=1,Text=TITLE,TextColor3=C.textHi,Font=Enum.Font.GothamBold,TextSize=30,TextXAlignment=Enum.TextXAlignment.Center,TextTransparency=1,ZIndex=502},center)
		local lLine=new("Frame",{Size=UDim2.new(0,0,0,2),Position=UDim2.new(0.5,0,0,58),AnchorPoint=Vector2.new(0.5,0),BackgroundColor3=ACCENT,BorderSizePixel=0,ZIndex=503},center); corner(1,lLine)
		local lSub=new("TextLabel",{Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,0,0,68),BackgroundTransparency=1,Text=SUB,TextColor3=C.textMid,Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Center,TextTransparency=1,ZIndex=502},center)
		local progTrack=new("Frame",{Size=UDim2.new(0,200,0,3),Position=UDim2.new(0.5,-100,1,-18),BackgroundColor3=C.bg3,BorderSizePixel=0,ZIndex=502},loader); corner(2,progTrack)
		local progFill=new("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=ACCENT,BorderSizePixel=0,ZIndex=503},progTrack); corner(2,progFill)
		local watermark=new("TextLabel",{Size=UDim2.new(0,80,0,16),Position=UDim2.new(1,-96,1,-24),BackgroundTransparency=1,Text="ArtemisUI",TextColor3=C.textLo,Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Right,TextTransparency=1,ZIndex=502},loader)
		local stopOrbit
		task.spawn(function()
			task.wait(0.05); twQuint(topBar,0.55,{Size=UDim2.new(1,0,0,2)}); task.wait(0.2)
			twBack(ldot,0.4,{Size=UDim2.new(0,7,0,7),Position=UDim2.new(0.5,0,0,6)})
			stopOrbit=spawnOrbit(center,0,6,15,ACCENT,6)
			task.wait(0.22)
			lTitle.Position=UDim2.new(0,0,0,26); twBack(lTitle,0.5,{TextTransparency=0,Position=UDim2.new(0,0,0,18)}); task.wait(0.18)
			twQuint(lLine,0.5,{Size=UDim2.new(0,200,0,2)}); task.wait(0.15)
			tw(lSub,0.45,{TextTransparency=0}); task.wait(0.12)
			tw(watermark,0.5,{TextTransparency=0.45}); task.wait(0.2)
			twQuint(progFill,1.4,{Size=UDim2.new(1,0,1,0)}); task.wait(1.55)
			if stopOrbit then stopOrbit() end
			tw(loader,0.48,{BackgroundTransparency=1}); tw(lTitle,0.3,{TextTransparency=1}); tw(lSub,0.3,{TextTransparency=1})
			tw(lLine,0.25,{BackgroundTransparency=1}); tw(topBar,0.3,{BackgroundTransparency=1})
			tw(progFill,0.25,{BackgroundTransparency=1}); tw(progTrack,0.25,{BackgroundTransparency=1})
			tw(watermark,0.3,{TextTransparency=1}); tw(ldot,0.25,{BackgroundTransparency=1})
			task.wait(0.48); loaderGui:Destroy(); setupKeySystem(revealMainWindow)
		end)
	elseif LOAD_ANIM==2 then
		local loader=new("Frame",{Name="Loader",Size=UDim2.new(0,WIN_W,0,WIN_H),Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2),BackgroundColor3=C.bg0,BorderSizePixel=0,ClipsDescendants=true,ZIndex=500},gui)
		corner(R.win,loader); outline(ACCENT,1,loader); new("UIScale",{Scale=getgenv().Scale or 1},loader)
		local topBar=new("Frame",{Size=UDim2.new(0,0,0,2),Position=UDim2.new(0,0,0,0),BackgroundColor3=ACCENT,BorderSizePixel=0,ZIndex=504},loader)
		local center=new("Frame",{Size=UDim2.new(0,320,0,110),Position=UDim2.new(0.5,-160,0.5,-55),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=501},loader)
		local ldot=new("Frame",{Size=UDim2.new(0,0,0,0),Position=UDim2.new(0.5,0,0,0),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=ACCENT,BorderSizePixel=0,ZIndex=503},center); corner(99,ldot)
		local lTitle=new("TextLabel",{Size=UDim2.new(1,0,0,36),Position=UDim2.new(0,0,0,18),BackgroundTransparency=1,Text=TITLE,TextColor3=C.textHi,Font=Enum.Font.GothamBold,TextSize=28,TextXAlignment=Enum.TextXAlignment.Center,TextTransparency=1,ZIndex=502},center)
		local lLine=new("Frame",{Size=UDim2.new(0,0,0,2),Position=UDim2.new(0.5,0,0,58),AnchorPoint=Vector2.new(0.5,0),BackgroundColor3=ACCENT,BorderSizePixel=0,ZIndex=503},center); corner(1,lLine)
		local lSub=new("TextLabel",{Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,0,0,68),BackgroundTransparency=1,Text=SUB,TextColor3=C.textMid,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Center,TextTransparency=1,ZIndex=502},center)
		local progTrack=new("Frame",{Size=UDim2.new(0,180,0,3),Position=UDim2.new(0.5,-90,1,-20),BackgroundColor3=C.bg3,BorderSizePixel=0,ZIndex=502},loader); corner(2,progTrack)
		local progFill=new("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=ACCENT,BorderSizePixel=0,ZIndex=503},progTrack); corner(2,progFill)
		local watermark=new("TextLabel",{Size=UDim2.new(0,80,0,16),Position=UDim2.new(1,-12,1,-18),AnchorPoint=Vector2.new(1,1),BackgroundTransparency=1,Text="ArtemisUI",TextColor3=C.textLo,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Right,TextTransparency=1,ZIndex=502},loader)
		loader.Size=UDim2.new(0,0,0,0); loader.Position=UDim2.new(0.5,0,0.5,0)
		twBack(loader,0.44,{Size=UDim2.new(0,WIN_W,0,WIN_H),Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2)})
		local stopOrbit
		task.spawn(function()
			task.wait(0.52); twQuint(topBar,0.45,{Size=UDim2.new(1,0,0,2)}); task.wait(0.18)
			twBack(ldot,0.35,{Size=UDim2.new(0,7,0,7),Position=UDim2.new(0.5,0,0,6)})
			stopOrbit=spawnOrbit(center,0,6,15,ACCENT,6)
			task.wait(0.2)
			lTitle.Position=UDim2.new(0,0,0,26); twBack(lTitle,0.4,{TextTransparency=0,Position=UDim2.new(0,0,0,18)}); task.wait(0.15)
			twQuint(lLine,0.4,{Size=UDim2.new(0,180,0,2)}); task.wait(0.12)
			tw(lSub,0.35,{TextTransparency=0}); task.wait(0.1)
			tw(watermark,0.4,{TextTransparency=0.45}); task.wait(0.18)
			twQuint(progFill,1.2,{Size=UDim2.new(1,0,1,0)}); task.wait(1.4)
			if stopOrbit then stopOrbit() end
			tw(lTitle,0.22,{TextTransparency=1}); tw(lSub,0.22,{TextTransparency=1})
			tw(lLine,0.2,{BackgroundTransparency=1}); tw(ldot,0.2,{BackgroundTransparency=1})
			tw(topBar,0.22,{BackgroundTransparency=1}); tw(progFill,0.2,{BackgroundTransparency=1})
			tw(progTrack,0.2,{BackgroundTransparency=1}); tw(watermark,0.22,{TextTransparency=1})
			task.wait(0.24); local md=0.42; fadeGuiTreeOut(loader,md); task.wait(md+0.04)
			loader:Destroy(); setupKeySystem(revealMainWindow)
		end)
	else
		setupKeySystem(revealMainWindow)
	end

	local topbar=new("Frame",{Name="Topbar",Size=UDim2.new(1,0,0,TOPBAR_H),BackgroundColor3=C.bg1,BorderSizePixel=0,ZIndex=6},win)
	corner(R.win,topbar); regTh(topbar,"BackgroundColor3","bg1")
	new("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=C.brd0,BackgroundTransparency=0.5,BorderSizePixel=0,ZIndex=7},topbar)

	local titleRow=new("Frame",{Size=UDim2.new(0,360,1,0),BackgroundTransparency=1,ZIndex=7},topbar)
	inset(0,0,16,0,titleRow)
	new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,9),SortOrder=Enum.SortOrder.LayoutOrder},titleRow)

	local pulsing=true
	do
		local dot=new("Frame",{Size=UDim2.new(0,6,0,6),BackgroundColor3=ACCENT,BorderSizePixel=0,ZIndex=8,LayoutOrder=0},titleRow)
		corner(3,dot); regAc(dot,"BackgroundColor3")
		local dotShadow=new("Frame",{Size=UDim2.new(0,6,0,6),Position=UDim2.new(0,1,0,1),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.6,BorderSizePixel=0,ZIndex=7},dot)
		corner(3,dotShadow)
		task.spawn(function()
			while pulsing do
				tw(dotShadow,1.5,{BackgroundTransparency=0.85},Enum.EasingStyle.Sine); task.wait(1.5)
				tw(dotShadow,1.5,{BackgroundTransparency=0.35},Enum.EasingStyle.Sine); task.wait(1.5)
			end
		end)
	end

	if cfg.Icon then
		local winIc=new("ImageLabel",{Size=UDim2.new(0,14,0,14),BackgroundTransparency=1,ImageColor3=C.textHi,ZIndex=8,LayoutOrder=1},titleRow)
		task.spawn(function()
			local dl=tick()+6; while not Icons and tick()<dl do task.wait(0.1) end
			local asset=getIcon(cfg.Icon)
			if asset and winIc.Parent then winIc.Image="rbxassetid://"..asset.id; winIc.ImageRectSize=asset.imageRectSize; winIc.ImageRectOffset=asset.imageRectOffset end
		end)
	end

	new("TextLabel",{Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,BackgroundTransparency=1,Text=TITLE,TextColor3=C.textHi,Font=Enum.Font.GothamBold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=8,LayoutOrder=2},titleRow)
	if SUB~="" then
		new("TextLabel",{Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,BackgroundTransparency=1,Text="·  "..SUB,TextColor3=C.textLo,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=8,LayoutOrder=3},titleRow)
	end

	local function mkCtrl(xOff,glyph,isSearch)
		local glowCol=glyph=="×" and BASE.red or ACCENT
		local plate=new("Frame",{Size=UDim2.new(0,22,0,22),Position=UDim2.new(1,xOff,0.5,-11),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=7},topbar)
		local b=new("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundColor3=C.bg3,BorderSizePixel=0,ZIndex=9,AutoButtonColor=false,Text=""},plate)
		corner(R.elem,b); local bStr=outline(C.brd0,1,b); bStr.Transparency=0.45
		if isSearch then
			local ic=mkIcon(b,"search",12,C.textLo,10); ic.AnchorPoint=Vector2.new(0.5,0.5); ic.Position=UDim2.new(0.5,0,0.5,0); ic.Size=UDim2.new(0,12,0,12)
			b.MouseEnter:Connect(function() tw(ic,0.15,{ImageColor3=ACCENT}); tw(bStr,0.15,{Color=ACCENT,Transparency=0.05}) end)
			b.MouseLeave:Connect(function() tw(ic,0.2,{ImageColor3=C.textLo}); tw(bStr,0.2,{Color=C.brd0,Transparency=0.45}) end)
		else
			local lbl=new("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=glyph,TextColor3=C.textLo,Font=Enum.Font.GothamBold,TextSize=13,ZIndex=10},b)
			b.MouseEnter:Connect(function() tw(lbl,0.15,{TextColor3=BASE.white}); tw(bStr,0.15,{Color=glowCol,Transparency=0.05}) end)
			b.MouseLeave:Connect(function() tw(lbl,0.2,{TextColor3=C.textLo}); tw(bStr,0.2,{Color=C.brd0,Transparency=0.45}) end)
		end
		return b
	end

	local closeBtn=mkCtrl(-34,"×"); local minBtn=mkCtrl(-62,"−"); local settingsBtn=mkCtrl(-90,"",false); local searchBtn=mkCtrl(-118,"",true)
	do
		local gearImg=mkIcon(settingsBtn,"settings",12,C.textLo,10); gearImg.AnchorPoint=Vector2.new(0.5,0.5); gearImg.Position=UDim2.new(0.5,0,0.5,0); gearImg.Size=UDim2.new(0,12,0,12)
		local gearStr=settingsBtn:FindFirstChildWhichIsA("UIStroke")
		settingsBtn.MouseEnter:Connect(function() tw(gearImg,0.15,{ImageColor3=ACCENT}); if gearStr then tw(gearStr,0.15,{Color=ACCENT,Transparency=0.05}) end end)
		settingsBtn.MouseLeave:Connect(function() tw(gearImg,0.2,{ImageColor3=C.textLo}); if gearStr then tw(gearStr,0.2,{Color=C.brd0,Transparency=0.45}) end end)
	end
	local customTopbarCount=0

	local tabbar=new("Frame",{Name="Tabbar",BackgroundColor3=C.bg1,BorderSizePixel=0,ZIndex=5},win)
	corner(R.win,tabbar); regTh(tabbar,"BackgroundColor3","bg1")

	local tabIndicator=new("Frame",{BackgroundColor3=ACCENT,BorderSizePixel=0,ZIndex=8},tabbar)
	corner(1,tabIndicator); regAc(tabIndicator,"BackgroundColor3")

	local tabHairline=new("Frame",{BackgroundColor3=C.brd0,BackgroundTransparency=0.5,BorderSizePixel=0,ZIndex=6},tabbar)
	local tabHairGrad=new("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.08,0),NumberSequenceKeypoint.new(0.92,0),NumberSequenceKeypoint.new(1,1)})},tabHairline)
	regTh(tabHairline,"BackgroundColor3","brd0")

	local tabScroll=new("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=0,ZIndex=6},tabbar)

	local contentBg, scroll, sideProfile, topProfile

	local function relayoutTabbar()
		if TAB_SIDE=="left" then
			tabbar.ClipsDescendants=true
			tw(tabbar,0.3,{Size=UDim2.new(0,RAIL_MIN,1,-TOPBAR_H),Position=UDim2.new(0,0,0,TOPBAR_H)},Enum.EasingStyle.Quint)
			tabIndicator.Size=UDim2.new(0,2,0,20); tabIndicator.Position=UDim2.new(0,0,0,10)
			tabHairline.Size=UDim2.new(0,1,1,0); tabHairline.Position=UDim2.new(1,-1,0,0); tabHairGrad.Rotation=90
			local ol=tabScroll:FindFirstChildWhichIsA("UIListLayout"); if ol then ol:Destroy() end
			local op=tabScroll:FindFirstChildWhichIsA("UIPadding"); if op then op:Destroy() end
			tabScroll.Size=UDim2.new(1,0,1,-(8+PROFILE_H)); tabScroll.Position=UDim2.new(0,0,0,4)
			tabScroll.ScrollingDirection=Enum.ScrollingDirection.Y; tabScroll.CanvasSize=UDim2.new(0,0,0,0); tabScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
			new("UIListLayout",{Padding=UDim.new(0,2),FillDirection=Enum.FillDirection.Vertical,HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder},tabScroll)
			inset(6,6,6,6,tabScroll)
		else
			tabbar.ClipsDescendants=false
			tw(tabbar,0.3,{Size=UDim2.new(1,0,0,TABBAR_H),Position=UDim2.new(0,0,0,TOPBAR_H)},Enum.EasingStyle.Quint)
			tabIndicator.Size=UDim2.new(0,20,0,2); tabIndicator.Position=UDim2.new(0,10,1,-1)
			tabHairline.Size=UDim2.new(1,0,0,1); tabHairline.Position=UDim2.new(0,0,1,-1); tabHairGrad.Rotation=0
			local ol=tabScroll:FindFirstChildWhichIsA("UIListLayout"); if ol then ol:Destroy() end
			local op=tabScroll:FindFirstChildWhichIsA("UIPadding"); if op then op:Destroy() end
			tabScroll.Size=UDim2.new(1,-8,1,0); tabScroll.Position=UDim2.new(0,4,0,0)
			tabScroll.ScrollingDirection=Enum.ScrollingDirection.X; tabScroll.CanvasSize=UDim2.new(0,0,1,0); tabScroll.AutomaticCanvasSize=Enum.AutomaticSize.X
			new("UIListLayout",{Padding=UDim.new(0,2),FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder},tabScroll)
			inset(0,0,2,2,tabScroll)
		end
		if sideProfile then sideProfile.Visible=TAB_SIDE=="left" end
		if topProfile then topProfile.Visible=TAB_SIDE=="top" end
		railRows={}
		for _,btn in pairs(tabBtns) do
			local ol=btn:FindFirstChildWhichIsA("UIListLayout"); if ol then ol:Destroy() end
			local op=btn:FindFirstChildWhichIsA("UIPadding"); if op then op:Destroy() end
			local ic=btn:FindFirstChild("Icon")
			local lbl=btn:FindFirstChild("Lbl")
			if TAB_SIDE=="left" then
				btn.Size=UDim2.new(1,0,0,32); btn.AutomaticSize=Enum.AutomaticSize.None
				new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},btn)
				if ic then ic.AnchorPoint=Vector2.new(0,0); ic.Position=railOpen and UDim2.new(0,14,0.5,-6) or UDim2.new(0.5,-6,0.5,-6) end
				if lbl then
					lbl.Size=UDim2.new(1,-40,1,0); lbl.Position=UDim2.new(0,32,0,0); lbl.AutomaticSize=Enum.AutomaticSize.None
					lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.TextTruncate=Enum.TextTruncate.AtEnd
					lbl.TextTransparency=railOpen and 0 or 1
				end
				table.insert(railRows,{icon=ic,lbl=lbl})
			else
				btn.Size=UDim2.new(0,0,0,26); btn.AutomaticSize=Enum.AutomaticSize.X
				new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},btn)
				if ic then ic.AnchorPoint=Vector2.new(0,0) end
				if lbl then
					lbl.Size=UDim2.new(0,0,1,0); lbl.AutomaticSize=Enum.AutomaticSize.X
					lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.TextTruncate=Enum.TextTruncate.None
					lbl.TextTransparency=0
				end
			end
			inset(0,0,12,12,btn)
		end
		BAR_H=TAB_SIDE=="top" and TABBAR_H or 0; BAR_W=TAB_SIDE=="left" and RAIL_MIN or 0
		CONTENT_H=WIN_H-TOPBAR_H-BAR_H
		tw(contentBg,0.3,{Size=UDim2.new(1,-BAR_W,0,CONTENT_H),Position=UDim2.new(0,BAR_W,0,TOPBAR_H+BAR_H)},Enum.EasingStyle.Quint)
		tw(scroll,0.3,{Size=UDim2.new(1,-BAR_W,0,CONTENT_H),Position=UDim2.new(0,BAR_W,0,TOPBAR_H+BAR_H)},Enum.EasingStyle.Quint)
		if activeTab then activateTab(activeTab) end
	end

	local function setRailExpanded(open)
		railOpen=open
		for _,row in ipairs(railRows) do
			if row.icon then tw(row.icon,0.28,{Position=open and UDim2.new(0,14,0.5,-6) or UDim2.new(0.5,-6,0.5,-6)},Enum.EasingStyle.Quint) end
			tw(row.lbl,open and 0.22 or 0.12,{TextTransparency=open and 0 or 1})
		end
		if applyProfileLayout then applyProfileLayout(open) end
	end

	do
		local function expandRail()
			if TAB_SIDE~="left" or railOpen then return end
			setRailExpanded(true)
			twBack(tabbar,0.32,{Size=UDim2.new(0,RAIL_MAX,1,-TOPBAR_H)})
			twBack(contentBg,0.32,{Size=UDim2.new(1,-RAIL_MAX,0,CONTENT_H),Position=UDim2.new(0,RAIL_MAX,0,TOPBAR_H)})
			twBack(scroll,0.32,{Size=UDim2.new(1,-RAIL_MAX,0,CONTENT_H),Position=UDim2.new(0,RAIL_MAX,0,TOPBAR_H)})
		end
		local function collapseRail()
			if TAB_SIDE~="left" or not railOpen then return end
			setRailExpanded(false)
			tw(tabbar,0.24,{Size=UDim2.new(0,RAIL_MIN,1,-TOPBAR_H)},Enum.EasingStyle.Quint)
			tw(contentBg,0.24,{Size=UDim2.new(1,-RAIL_MIN,0,CONTENT_H),Position=UDim2.new(0,RAIL_MIN,0,TOPBAR_H)},Enum.EasingStyle.Quint)
			tw(scroll,0.24,{Size=UDim2.new(1,-RAIL_MIN,0,CONTENT_H),Position=UDim2.new(0,RAIL_MIN,0,TOPBAR_H)},Enum.EasingStyle.Quint)
		end
		tabbar.MouseEnter:Connect(expandRail)
		tabbar.MouseLeave:Connect(collapseRail)
		tabbar.MouseEnter:Connect(function() if TAB_SIDE=="left" then twHover(tabHairline,0.2,{BackgroundTransparency=0.1}) end end)
		tabbar.MouseLeave:Connect(function() if TAB_SIDE=="left" then twHover(tabHairline,0.25,{BackgroundTransparency=0.5}) end end)
	end

	contentBg=new("Frame",{Size=UDim2.new(1,-BAR_W,0,CONTENT_H),Position=UDim2.new(0,BAR_W,0,TOPBAR_H+BAR_H),BackgroundColor3=C.bg0,BorderSizePixel=0,ZIndex=1},win)
	corner(R.win,contentBg)
	regTh(contentBg,"BackgroundColor3","bg0")
	local capTL=new("Frame",{Size=UDim2.new(0,R.win,0,R.win),Position=UDim2.new(0,0,0,0),BackgroundColor3=C.bg0,BorderSizePixel=0,ZIndex=1},contentBg)
	local capTR=new("Frame",{Size=UDim2.new(0,R.win,0,R.win),Position=UDim2.new(1,-R.win,0,0),BackgroundColor3=C.bg0,BorderSizePixel=0,ZIndex=1},contentBg)
	regTh(capTL,"BackgroundColor3","bg0"); regTh(capTR,"BackgroundColor3","bg0")

	scroll=new("ScrollingFrame",{Name="Scroll",Size=UDim2.new(1,-BAR_W,0,CONTENT_H),Position=UDim2.new(0,BAR_W,0,TOPBAR_H+BAR_H),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.brd1,ScrollBarImageTransparency=0.25,ScrollingDirection=Enum.ScrollingDirection.Y,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ClipsDescendants=true,ZIndex=2},win)
	vstack(14,scroll); inset(18,18,18,18,scroll)
	regTh(scroll,"ScrollBarImageColor3","brd1")

	do
		sideProfile=new("Frame",{Name="Profile",Size=UDim2.new(1,0,0,PROFILE_H),AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=6},tabbar)
		local profDiv=new("Frame",{Size=UDim2.new(1,-12,0,1),Position=UDim2.new(0,6,0,0),BackgroundColor3=C.brd0,BackgroundTransparency=0.55,BorderSizePixel=0,ZIndex=6},sideProfile)
		regTh(profDiv,"BackgroundColor3","brd0")
		local avatarImg=new("ImageLabel",{Size=UDim2.new(0,26,0,26),Position=UDim2.new(0.5,-13,0,16),BackgroundColor3=C.bg3,BorderSizePixel=0,Image=avatarThumb(lp.UserId,150,150),ZIndex=7},sideProfile)
		corner(13,avatarImg); regTh(avatarImg,"BackgroundColor3","bg3")
		local avatarStr=outline(C.brd1,1,avatarImg); regTh(avatarStr,"Color","brd1")
		local profName=new("TextLabel",{Name="Name",Size=UDim2.new(1,-8,0,12),Position=UDim2.new(0,4,0,36),BackgroundTransparency=1,TextTransparency=1,Text=PROFILE_NAME,TextColor3=C.textHi,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=7},sideProfile)
		regTh(profName,"TextColor3","textHi")
		local profSub=nil
		if PROFILE_SUB~="" then
			profSub=new("TextLabel",{Name="Sub",Size=UDim2.new(1,-8,0,10),Position=UDim2.new(0,4,0,48),BackgroundTransparency=1,TextTransparency=1,Text=PROFILE_SUB,TextColor3=C.textMid,Font=Enum.Font.Gotham,TextSize=8,TextXAlignment=Enum.TextXAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=7},sideProfile)
			regTh(profSub,"TextColor3","textMid")
		end
		applyProfileLayout=function(open)
			if open then
				tw(avatarImg,0.26,{Size=UDim2.new(0,30,0,30),Position=UDim2.new(0,12,0,10)},Enum.EasingStyle.Quint)
				profName.TextXAlignment=Enum.TextXAlignment.Left
				tw(profName,0.26,{Size=UDim2.new(1,-54,0,13),Position=UDim2.new(0,50,0,profSub and 14 or 20),TextTransparency=0},Enum.EasingStyle.Quint)
				if profSub then profSub.TextXAlignment=Enum.TextXAlignment.Left; tw(profSub,0.26,{Size=UDim2.new(1,-54,0,11),Position=UDim2.new(0,50,0,29),TextTransparency=0},Enum.EasingStyle.Quint) end
			else
				tw(avatarImg,0.22,{Size=UDim2.new(0,26,0,26),Position=UDim2.new(0.5,-13,0,16)},Enum.EasingStyle.Quint)
				profName.TextXAlignment=Enum.TextXAlignment.Center
				tw(profName,0.22,{Size=UDim2.new(1,-8,0,12),Position=UDim2.new(0,4,0,36),TextTransparency=1},Enum.EasingStyle.Quint)
				if profSub then profSub.TextXAlignment=Enum.TextXAlignment.Center; tw(profSub,0.22,{Size=UDim2.new(1,-8,0,10),Position=UDim2.new(0,4,0,48),TextTransparency=1},Enum.EasingStyle.Quint) end
			end
		end

		topProfile=new("Frame",{Name="Profile",Size=UDim2.new(0,150,0,30),Position=UDim2.new(1,-278,0.5,-15),BackgroundTransparency=1,BorderSizePixel=0,Visible=false,ZIndex=7},topbar)
		local topAvatar=new("ImageLabel",{Size=UDim2.new(0,26,0,26),Position=UDim2.new(0,0,0.5,-13),BackgroundColor3=C.bg3,BorderSizePixel=0,Image=avatarThumb(lp.UserId,150,150),ZIndex=8},topProfile)
		corner(13,topAvatar); regTh(topAvatar,"BackgroundColor3","bg3")
		local topAvatarStr=outline(C.brd1,1,topAvatar); regTh(topAvatarStr,"Color","brd1")
		local topName=new("TextLabel",{Size=UDim2.new(1,-34,0,13),Position=UDim2.new(0,34,0.5,PROFILE_SUB~="" and -14 or -6),BackgroundTransparency=1,TextTransparency=1,Text=PROFILE_NAME,TextColor3=C.textHi,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=8},topProfile)
		regTh(topName,"TextColor3","textHi")
		local topSub=nil
		if PROFILE_SUB~="" then
			topSub=new("TextLabel",{Size=UDim2.new(1,-34,0,11),Position=UDim2.new(0,34,0.5,2),BackgroundTransparency=1,TextTransparency=1,Text=PROFILE_SUB,TextColor3=C.textMid,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=8},topProfile)
			regTh(topSub,"TextColor3","textMid")
		end
		topProfile.MouseEnter:Connect(function()
			twHover(topName,0.16,{TextTransparency=0})
			if topSub then twHover(topSub,0.16,{TextTransparency=0}) end
		end)
		topProfile.MouseLeave:Connect(function()
			twHover(topName,0.2,{TextTransparency=1})
			if topSub then twHover(topSub,0.2,{TextTransparency=1}) end
		end)
	end

	relayoutTabbar()

	local searchRegistry={}

	local function applySearchFilter(query)
		query=string.lower(string.match(query,"^%s*(.-)%s*$"))
		if query=="" then
			for _,entry in ipairs(searchRegistry) do if entry.row then entry.row.Visible=true end end
			return
		end
		local jumpTo=nil
		for _,entry in ipairs(searchRegistry) do
			local match=string.find(string.lower(entry.label),query,1,true)~=nil
			if entry.row then entry.row.Visible=match end
			if match and not jumpTo then jumpTo=entry.tabName end
		end
		if jumpTo and jumpTo~=activeTab then activateTab(jumpTo) end
	end

	local searchPop=new("Frame",{Name="SearchPop",Size=UDim2.new(0,236,0,38),Position=UDim2.new(1,-118,0,TOPBAR_H+6),AnchorPoint=Vector2.new(1,0),BackgroundColor3=C.bg2,BorderSizePixel=0,ClipsDescendants=true,Visible=false,ZIndex=60},win)
	corner(R.elem,searchPop); local searchPopStr=outline(C.brd1,1,searchPop); regTh(searchPop,"BackgroundColor3","bg2"); regTh(searchPopStr,"Color","brd1")
	regAc(mkGlowLine(searchPop,ACCENT,0.55,62),"BackgroundColor3")
	local searchBox=new("TextBox",{Size=UDim2.new(1,-24,1,0),Position=UDim2.new(0,12,0,0),BackgroundTransparency=1,Text="",PlaceholderText="Search and jump...",TextColor3=C.textHi,PlaceholderColor3=C.textLo,Font=Enum.Font.GothamSemibold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,BorderSizePixel=0,ZIndex=61},searchPop)
	local searchOpen=false
	local function openSearch()
		searchOpen=true; searchPop.Visible=true; searchPop.Size=UDim2.new(0,0,0,38)
		twBack(searchPop,0.26,{Size=UDim2.new(0,236,0,38)}); task.defer(function() searchBox:CaptureFocus() end)
	end
	local function closeSearch()
		searchOpen=false; tw(searchPop,0.18,{Size=UDim2.new(0,0,0,38)})
		task.delay(0.18,function() if not searchOpen then searchPop.Visible=false end end)
		searchBox.Text=""; applySearchFilter("")
	end
	searchBtn.MouseButton1Click:Connect(function() if searchOpen then closeSearch() else openSearch() end end)
	searchBox:GetPropertyChangedSignal("Text"):Connect(function() applySearchFilter(searchBox.Text) end)
	UserInputService.InputBegan:Connect(function(i,gp)
		if gp then return end; if searchOpen and i.KeyCode==Enum.KeyCode.Escape then closeSearch() end
	end)

	local function applyThemeByName(nm)
		local t,resolved=resolveTheme(nm)
		if not t then return end
		for k,v in pairs(t) do BASE[k]=v; C[k]=v end
		applyTheme()
		if not FLAGS["__accent"] and THEME_ACCENTS[resolved] then ApplyAccent(THEME_ACCENTS[resolved]) end
		FLAGS["__theme"]=resolved; saveConfig(CONFIG_FILE,FLAGS)
	end

	local settingsPop=new("Frame",{Name="SettingsPop",Size=UDim2.new(0,224,0,178),Position=UDim2.new(1,-90,0,TOPBAR_H+6),AnchorPoint=Vector2.new(1,0),BackgroundColor3=C.bg2,BorderSizePixel=0,ClipsDescendants=true,Visible=false,ZIndex=60},win)
	corner(R.card,settingsPop); local settingsPopStr=outline(C.brd1,1,settingsPop); regTh(settingsPop,"BackgroundColor3","bg2"); regTh(settingsPopStr,"Color","brd1")
	regAc(mkGlowLine(settingsPop,ACCENT,0.55,62),"BackgroundColor3")
	inset(14,14,14,14,settingsPop); vstack(12,settingsPop)

	local function settingsRow(label)
		local row=new("Frame",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,ZIndex=61},settingsPop)
		new("TextLabel",{Size=UDim2.new(0.42,0,1,0),BackgroundTransparency=1,Text=label,TextColor3=C.textLo,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=61},row)
		regTh(row:FindFirstChildWhichIsA("TextLabel"),"TextColor3","textLo")
		local ctrl=new("Frame",{Size=UDim2.new(0.58,0,1,0),Position=UDim2.new(0.42,0,0,0),BackgroundTransparency=1,ZIndex=61},row)
		new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Center,HorizontalAlignment=Enum.HorizontalAlignment.Right,Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},ctrl)
		return ctrl
	end

	local themeNames=(function() local out={}; for k in pairs(THEMES) do table.insert(out,k) end; table.sort(out); return out end)()
	local themeIdx=1
	for i,nm in ipairs(themeNames) do if nm==(FLAGS["__theme"] or "Valence") then themeIdx=i end end
	local themeCtrl=settingsRow("Theme")
	local themePrev=new("TextButton",{Size=UDim2.new(0,18,0,18),BackgroundColor3=C.bg4,Text="‹",TextColor3=C.textLo,Font=Enum.Font.GothamBold,TextSize=12,BorderSizePixel=0,ZIndex=62,LayoutOrder=1},themeCtrl)
	corner(5,themePrev); outline(C.brd0,1,themePrev)
	local themeLbl=new("TextLabel",{Size=UDim2.new(0,66,1,0),BackgroundTransparency=1,Text=themeNames[themeIdx] or "Valence",TextColor3=ACCENT,Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=62,LayoutOrder=2},themeCtrl)
	regAc(themeLbl,"TextColor3")
	local themeNext=new("TextButton",{Size=UDim2.new(0,18,0,18),BackgroundColor3=C.bg4,Text="›",TextColor3=C.textLo,Font=Enum.Font.GothamBold,TextSize=12,BorderSizePixel=0,ZIndex=62,LayoutOrder=3},themeCtrl)
	corner(5,themeNext); outline(C.brd0,1,themeNext)
	local function cycleTheme(dir)
		themeIdx=((themeIdx-1+dir)%#themeNames)+1
		themeLbl.Text=themeNames[themeIdx]; applyThemeByName(themeNames[themeIdx])
	end
	themePrev.MouseButton1Click:Connect(function() cycleTheme(-1) end)
	themeNext.MouseButton1Click:Connect(function() cycleTheme(1) end)

	local kbCtrl=settingsRow("Toggle Key")
	local kbPill=new("TextButton",{Size=UDim2.new(0,66,0,18),BackgroundColor3=C.bg4,Text=toggleKey and tostring(toggleKey):gsub("Enum%.KeyCode%.","") or "Unbound",TextColor3=ACCENT,Font=Enum.Font.GothamBold,TextSize=10,BorderSizePixel=0,ZIndex=62},kbCtrl)
	corner(5,kbPill); outline(C.brd0,1,kbPill); regAc(kbPill,"TextColor3")
	local kbBinding=false
	kbPill.MouseButton1Click:Connect(function() kbBinding=true; kbPill.Text="..." end)
	UserInputService.InputBegan:Connect(function(i,gp)
		if not kbBinding then return end
		if i.UserInputType==Enum.UserInputType.Keyboard and i.KeyCode~=Enum.KeyCode.Unknown then
			kbBinding=false; toggleKey=i.KeyCode
			kbPill.Text=tostring(toggleKey):gsub("Enum%.KeyCode%.",""); FLAGS["__togglekey"]=kbPill.Text; saveConfig(CONFIG_FILE,FLAGS)
		end
	end)

	local sideCtrl=settingsRow("Sidebar")
	local sideTrack=new("Frame",{Size=UDim2.new(0,38,0,18),BackgroundColor3=TAB_SIDE=="left" and ACCENT or C.bg4,BorderSizePixel=0,ZIndex=62},sideCtrl)
	corner(9,sideTrack); local sideStr=outline(TAB_SIDE=="left" and ACCENT or C.brd1,1,sideTrack)
	local sideKnob=new("Frame",{Size=UDim2.new(0,12,0,12),Position=UDim2.new(0,TAB_SIDE=="left" and 23 or 3,0.5,-6),BackgroundColor3=C.white,BorderSizePixel=0,ZIndex=63},sideTrack)
	corner(6,sideKnob)
	local sideHit=new("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",BorderSizePixel=0,ZIndex=64},sideTrack)
	sideHit.MouseButton1Click:Connect(function()
		TAB_SIDE=TAB_SIDE=="left" and "top" or "left"
		tw(sideTrack,0.2,{BackgroundColor3=TAB_SIDE=="left" and ACCENT or C.bg4}); tw(sideStr,0.2,{Color=TAB_SIDE=="left" and ACCENT or C.brd1})
		TweenService:Create(sideKnob,TweenInfo.new(0.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(0,TAB_SIDE=="left" and 23 or 3,0.5,-6)}):Play()
		FLAGS["__tabside"]=TAB_SIDE; saveConfig(CONFIG_FILE,FLAGS)
		relayoutTabbar()
	end)

	local function listSavedConfigs()
		local out={}
		if listfiles then
			local ok,files=pcall(listfiles,"ArtemisUI")
			if ok and files then
				for _,path in ipairs(files) do
					local nm=path:match("([^/\\]+)%.json$")
					if nm then table.insert(out,nm) end
				end
			end
		end
		table.sort(out)
		return out
	end

	local cfgCtrl=settingsRow("Config")
	local cfgNames=listSavedConfigs(); local cfgIdx=1
	local cfgLbl=new("TextLabel",{Size=UDim2.new(0,66,1,0),BackgroundTransparency=1,Text=cfgNames[1] or "none",TextColor3=ACCENT,Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=62,LayoutOrder=1},cfgCtrl)
	regAc(cfgLbl,"TextColor3")
	local cfgImport=new("TextButton",{Size=UDim2.new(0,18,0,18),BackgroundColor3=C.bg4,Text="↓",TextColor3=C.textLo,Font=Enum.Font.GothamBold,TextSize=11,BorderSizePixel=0,ZIndex=62,LayoutOrder=2},cfgCtrl)
	corner(5,cfgImport); outline(C.brd0,1,cfgImport)
	local function refreshCfgNames()
		cfgNames=listSavedConfigs()
		if #cfgNames==0 then cfgIdx=1; cfgLbl.Text="none"; return end
		cfgIdx=math.clamp(cfgIdx,1,#cfgNames); cfgLbl.Text=cfgNames[cfgIdx]
	end
	cfgCtrl.MouseEnter:Connect(refreshCfgNames)
	local cfgPrev=new("TextButton",{Size=UDim2.new(0,18,0,18),BackgroundColor3=C.bg4,Text="‹",TextColor3=C.textLo,Font=Enum.Font.GothamBold,TextSize=12,BorderSizePixel=0,ZIndex=62,LayoutOrder=0},cfgCtrl)
	corner(5,cfgPrev); outline(C.brd0,1,cfgPrev)
	cfgPrev.MouseButton1Click:Connect(function()
		if #cfgNames==0 then return end
		cfgIdx=((cfgIdx-2)%#cfgNames)+1; cfgLbl.Text=cfgNames[cfgIdx]
	end)
	cfgImport.MouseButton1Click:Connect(function()
		local nm=cfgNames[cfgIdx]; if not nm then return end
		loadConfig(nm,FLAGS)
		for flag,handler in pairs(flagHandlers) do if FLAGS[flag]~=nil then handler(FLAGS[flag]) end end
		twHover(cfgImport,0.15,{BackgroundColor3=ACCENT}); task.delay(0.15,function() twHover(cfgImport,0.2,{BackgroundColor3=C.bg4}) end)
	end)

	local settingsOpen=false
	local function openSettings()
		settingsOpen=true; settingsPop.Visible=true; settingsPop.Size=UDim2.new(0,224,0,0)
		twBack(settingsPop,0.28,{Size=UDim2.new(0,224,0,178)})
	end
	local function closeSettings()
		settingsOpen=false; tw(settingsPop,0.2,{Size=UDim2.new(0,224,0,0)})
		task.delay(0.2,function() if not settingsOpen then settingsPop.Visible=false end end)
	end
	settingsBtn.MouseButton1Click:Connect(function() if settingsOpen then closeSettings() else openSettings() end end)

	local function pointInside(pos,frame)
		local a=frame.AbsolutePosition; local s=frame.AbsoluteSize
		return pos.X>=a.X and pos.X<=a.X+s.X and pos.Y>=a.Y and pos.Y<=a.Y+s.Y
	end

	UserInputService.InputBegan:Connect(function(i,gp)
		if i.UserInputType~=Enum.UserInputType.MouseButton1 and i.UserInputType~=Enum.UserInputType.Touch then return end
		if gp then return end
		local mp=UserInputService:GetMouseLocation()
		if searchOpen and not pointInside(mp,searchPop) and not pointInside(mp,searchBtn) then closeSearch() end
		if settingsOpen and not pointInside(mp,settingsPop) and not pointInside(mp,settingsBtn) then closeSettings() end
	end)

	moveTabIndicator = function(name)
		local btn=tabBtns[name]; if not btn or not btn.Parent then return end
		task.defer(function()
			if not btn.Parent then return end
			while btn.AbsoluteSize.X==0 or tabbar.AbsoluteSize.X==0 do task.wait(); if not btn.Parent then return end end
			local sc=uiScale.Scale
			if TAB_SIDE=="left" then
				local relY=(btn.AbsolutePosition.Y-tabbar.AbsolutePosition.Y)/sc
				local h=btn.AbsoluteSize.Y/sc
				tw(tabIndicator,0.3,{Position=UDim2.new(0,0,0,relY),Size=UDim2.new(0,2,0,h)},Enum.EasingStyle.Quint)
			else
				local relX=(btn.AbsolutePosition.X-tabbar.AbsolutePosition.X)/sc
				local w=btn.AbsoluteSize.X/sc
				tw(tabIndicator,0.3,{Position=UDim2.new(0,relX,1,-1),Size=UDim2.new(0,w,0,2)},Enum.EasingStyle.Quint)
			end
		end)
	end

	local function staggerSections(pane)
		local idx=0
		local function run(container)
			if not container then return end
			for _,child in ipairs(container:GetChildren()) do
				if child:IsA("Frame") and child.Name:find("_Wrap") then
					idx=idx+1; child.BackgroundTransparency=1; child.Position=UDim2.new(0,-8,0,0)
					local delay=(idx-1)*0.055
					task.delay(delay,function() if child.Parent then tw(child,0.3,{Position=UDim2.new(0,0,0,0)},Enum.EasingStyle.Quint) end end)
				end
			end
		end
		run(pane:FindFirstChild("ColL")); run(pane:FindFirstChild("ColR"))
	end

	activateTab = function(name)
		for n,pane in pairs(tabs) do
			pane.Visible=(n==name)
			if n==name then pane.Position=UDim2.new(0,0,0,0); task.spawn(function() task.wait(0.02); staggerSections(pane) end) end
		end
		for n,btn in pairs(tabBtns) do
			local lbl=btn:FindFirstChild("Lbl"); local ic=btn:FindFirstChild("Icon")
			if n==name then
				tw(btn,0.22,{BackgroundColor3=C.bg3,BackgroundTransparency=0})
				if lbl then tw(lbl,0.18,{TextColor3=C.textHi}) end; if ic then tw(ic,0.18,{ImageColor3=C.textHi}) end
				local s=btn:FindFirstChildWhichIsA("UIStroke"); if s then s:Destroy() end
				outline(ACCENT,1.2,btn)
			else
				tw(btn,0.18,{BackgroundTransparency=1})
				if lbl then tw(lbl,0.16,{TextColor3=C.textLo}) end; if ic then tw(ic,0.16,{ImageColor3=C.textLo}) end
				local s=btn:FindFirstChildWhichIsA("UIStroke"); if s then s:Destroy() end
			end
		end
		activeTab=name; moveTabIndicator(name)
	end

	local winVisible=true

	local fabHolder=new("Frame",{Name="FABHolder",Size=UDim2.new(0,54,0,54),Position=UDim2.new(0,-80,0.5,-27),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=500,Visible=false},gui)
	local fabCustomPos = nil
	local fabDefaultPos = UDim2.new(0, 18, 0.5, -27)
	mkShadow(fabHolder,Color3.new(0,0,0),0.45,499)
	local fab=new("TextButton",{Name="FAB",Size=UDim2.new(1,0,1,0),BackgroundColor3=C.bg2,BorderSizePixel=0,Text="",ZIndex=501,AutoButtonColor=false},fabHolder)
	corner(16,fab); regTh(fab,"BackgroundColor3","bg2")
	local fabStr=outline(ACCENT,1.5,fab); fabStr.Transparency=0.25; regAc(fabStr,"Color")
	local fabImg=mkIcon(fab,"eye",22,C.textHi,502)
	fabImg.AnchorPoint=Vector2.new(0.5,0.5); fabImg.Position=UDim2.new(0.5,0,0.5,0); fabImg.Size=UDim2.new(0,22,0,22)

	local MobileBtn=new("TextButton",{Name="MobileBtn",Size=UDim2.new(0,48,0,48),Position=UDim2.new(0,8,0.5,-24),BackgroundColor3=C.bg2,BorderSizePixel=0,Text="",ZIndex=501,AutoButtonColor=false,Visible=false},gui)
	corner(14,MobileBtn)
	local MobileBtnStr=outline(ACCENT,1.5,MobileBtn); MobileBtnStr.Transparency=0.25; regAc(MobileBtnStr,"Color")
	local mobImg=mkIcon(MobileBtn,"layout-panel-left",20,C.textHi,502)
	mobImg.AnchorPoint=Vector2.new(0.5,0.5); mobImg.Position=UDim2.new(0.5,0,0.5,0); mobImg.Size=UDim2.new(0,20,0,20)
	mkShadow(MobileBtn,Color3.new(0,0,0),0.45,500)
	local MobileDragging=false; local MobileDragStart=nil; local MobilePosStart=nil
	MobileBtn.InputBegan:Connect(function(i)
		if i.UserInputType~=Enum.UserInputType.Touch and i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
		MobileDragging=false; MobileDragStart=i.Position; MobilePosStart=MobileBtn.Position
	end)
	MobileBtn.InputEnded:Connect(function(i)
		if i.UserInputType~=Enum.UserInputType.Touch and i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
		if not MobileDragging then showWindow(); MobileBtn.Visible=false end
		MobileDragging=false; MobileDragStart=nil; MobilePosStart=nil
	end)
	UserInputService.InputChanged:Connect(function(i)
		if not MobileDragStart or not MobileBtn.Visible then return end
		if i.UserInputType~=Enum.UserInputType.MouseMovement and i.UserInputType~=Enum.UserInputType.Touch then return end
		local Delta=i.Position-MobileDragStart
		if math.abs(Delta.X)>6 or math.abs(Delta.Y)>6 then MobileDragging=true end
		if MobileDragging and MobilePosStart then
			MobileBtn.Position=UDim2.new(0,math.clamp(MobilePosStart.X.Offset+Delta.X,0,gui.AbsoluteSize.X-48),0,math.clamp(MobilePosStart.Y.Offset+Delta.Y,0,gui.AbsoluteSize.Y-48))
		end
	end)
	MobileBtn.MouseEnter:Connect(function() twHover(MobileBtn,0.14,{BackgroundColor3=C.bg3}); twHover(MobileBtnStr,0.14,{Transparency=0}) end)
	MobileBtn.MouseLeave:Connect(function() twHover(MobileBtn,0.2,{BackgroundColor3=C.bg2}); twHover(MobileBtnStr,0.2,{Transparency=0.25}) end)

	local fabDragging=false; local fabDragStart=nil; local fabPosStart=nil; local fabInputType=nil

	fab.InputBegan:Connect(function(i)
		if i.UserInputType~=Enum.UserInputType.MouseButton1 and i.UserInputType~=Enum.UserInputType.Touch then return end
		fabDragging=false; fabDragStart=i.Position; fabPosStart=fabHolder.Position; fabInputType=i.UserInputType
	end)
	fab.InputEnded:Connect(function(i)
		if i.UserInputType~=fabInputType then return end
		if not fabDragging then
			twBack(fabHolder,0.22,{Position=UDim2.new(0,-80,0.5,-27)})
			task.delay(0.2,function() fabHolder.Visible=false end)
			showWindow()
		else
			fabCustomPos = fabHolder.Position
		end
		fabDragging=false; fabDragStart=nil; fabPosStart=nil
	end)
	UserInputService.InputChanged:Connect(function(i)
		if not fabDragStart or not fabHolder.Visible then return end
		if i.UserInputType~=Enum.UserInputType.MouseMovement and i.UserInputType~=Enum.UserInputType.Touch then return end
		local delta=i.Position-fabDragStart
		if math.abs(delta.X)>5 or math.abs(delta.Y)>5 then fabDragging=true end
		if fabDragging then 
			fabHolder.Position=UDim2.new(fabPosStart.X.Scale,fabPosStart.X.Offset+delta.X,fabPosStart.Y.Scale,fabPosStart.Y.Offset+delta.Y)
			fabCustomPos = fabHolder.Position
		end
	end)
	fab.MouseEnter:Connect(function() twHover(fab,0.14,{BackgroundColor3=C.bg3}); twHover(fabStr,0.14,{Transparency=0}); twHover(fabImg,0.14,{ImageColor3=ACCENT}) end)
	fab.MouseLeave:Connect(function() twHover(fab,0.2,{BackgroundColor3=C.bg2}); twHover(fabStr,0.2,{Transparency=0.25}); twHover(fabImg,0.2,{ImageColor3=C.textHi}) end)

		local function showFAB()
		if not UserInputService.TouchEnabled then return end
		fabDragging=false; fabDragStart=nil
		local targetPos = fabCustomPos or fabDefaultPos
		fabHolder.Position = UDim2.new(0,-80,0.5,-27)
		fabHolder.Visible = true
		twBack(fabHolder,0.4,{Position = targetPos})
	end

	local function hideFAB()
		tw(fabHolder,0.22,{Position=UDim2.new(0,-80,0.5,-27)},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
		task.delay(0.23,function() fabHolder.Visible=false end)
	end

	local function hideWindow()
		winVisible=false; savedWinPos=win.Position; savedShPos=shHolder.Position
		if FADE_TOGGLE and fadeOverlay then
			fadeGuiTreeOut(win,0.18); tw(fadeOverlay,0.18,{BackgroundTransparency=0})
			task.delay(0.2,function()
				win.Visible=false; shHolder.Visible=false; win.Size=FULL_SIZE; win.Position=savedWinPos
				shHolder.Size=FULL_SIZE; shHolder.Position=savedShPos; fadeOverlay.BackgroundTransparency=1
				for _,d in ipairs(win:GetDescendants()) do
					if d:IsA("UIStroke") then d.Transparency=0
					elseif d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then d.TextTransparency=0
					elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then d.ImageTransparency=0
					elseif d:IsA("Frame") then d.BackgroundTransparency=d==win and 0 or (d.BackgroundTransparency==1 and 1 or 0) end
				end
				win.Visible=false; shHolder.Visible=false; win.Size=FULL_SIZE; win.Position=savedWinPos
				shHolder.Size=FULL_SIZE; shHolder.Position=savedShPos; showFAB()
			end)
		else
			local cx=savedWinPos.X.Scale; local cxo=savedWinPos.X.Offset+WIN_W/2
			local cy=savedWinPos.Y.Scale; local cyo=savedWinPos.Y.Offset+WIN_H/2
			tw(win,0.28,{Size=UDim2.new(0,0,0,0),Position=UDim2.new(cx,cxo,cy,cyo)})
			tw(shHolder,0.28,{Size=UDim2.new(0,0,0,0),Position=UDim2.new(cx,cxo,cy,cyo)})
			task.delay(0.3,function()
				win.Visible=false; shHolder.Visible=false; win.Size=FULL_SIZE; win.Position=savedWinPos
				shHolder.Size=FULL_SIZE; shHolder.Position=savedShPos; showFAB()
			end)
		end
	end

	function showWindow()
		winVisible=true; if fabHolder.Visible then hideFAB() end
		MobileBtn.Visible=false
		local cx=savedWinPos.X.Scale; local cxo=savedWinPos.X.Offset+WIN_W/2
		local cy=savedWinPos.Y.Scale; local cyo=savedWinPos.Y.Offset+WIN_H/2
		if FADE_TOGGLE and fadeOverlay then
			win.Size=FULL_SIZE; win.Position=savedWinPos; shHolder.Size=FULL_SIZE; shHolder.Position=savedShPos
			win.Visible=true; shHolder.Visible=true; win.BackgroundTransparency=1; fadeOverlay.BackgroundTransparency=0
			tw(fadeOverlay,0.28,{BackgroundTransparency=1}); tw(win,0.28,{BackgroundTransparency=0})
			for _,d in ipairs(win:GetDescendants()) do
				if d:IsA("UIStroke") then tw(d,0.28,{Transparency=0})
				elseif d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then tw(d,0.28,{TextTransparency=0})
				elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then tw(d,0.28,{ImageTransparency=0}) end
			end
		else
			win.Size=UDim2.new(0,0,0,0); win.Position=UDim2.new(cx,cxo,cy,cyo)
			shHolder.Size=UDim2.new(0,0,0,0); shHolder.Position=UDim2.new(cx,cxo,cy,cyo)
			win.Visible=true; shHolder.Visible=true
			local targetScale=getgenv().Scale or 1; uiScale.Scale=targetScale*0.9
			twBack(win,0.4,{Size=FULL_SIZE,Position=savedWinPos}); twBack(shHolder,0.4,{Size=FULL_SIZE,Position=savedShPos})
			twBack(uiScale,0.4,{Scale=targetScale}); tw(winStroke,0.5,{Color=ACCENT,Transparency=0.3})
			task.delay(0.7,function() tw(winStroke,0.8,{Color=C.brd0,Transparency=0}) end)
		end
	end

	closeBtn.MouseButton1Click:Connect(function() hideWindow() end)
	local isMin=false
	minBtn.MouseButton1Click:Connect(function()
		isMin=not isMin
		if isMin then local ms=UDim2.new(0,WIN_W,0,TOPBAR_H+BAR_H); tw(win,0.28,{Size=ms},Enum.EasingStyle.Quint); tw(shHolder,0.28,{Size=ms},Enum.EasingStyle.Quint)
		else twBack(win,0.38,{Size=FULL_SIZE}); twBack(shHolder,0.38,{Size=FULL_SIZE}) end
	end)

	if UserInputService.TouchEnabled then
		local DragOverlay = new("TextButton", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = "",
			BorderSizePixel = 0,
			ZIndex = 3,
		}, win)
		draggable(DragOverlay, win, {shHolder})
	end

	draggable(topbar, win, {shHolder})
	draggable(tabbar, win, {shHolder})

	local WinObj={Flags=FLAGS}

	function WinObj:Save() saveConfig(CONFIG_FILE,FLAGS) end
	function WinObj:LoadedFlags() return FLAGS end
	function WinObj:LoadConfig(fileName)
		if not fileName then return end
		loadConfig(fileName,FLAGS)
		for flag,handler in pairs(flagHandlers) do if FLAGS[flag]~=nil then handler(FLAGS[flag]) end end
	end
	function WinObj:SetToggleKey(key) toggleKey=key end
	function WinObj:SetShadow(on)
		shadowOn=on and true or false
		tw(shadowImg,0.18,{ImageTransparency=shadowOn and 0.5 or 1})
	end

	function WinObj:SetAccent(colorOrRainbow)
		if rainbowConn then rainbowConn:Disconnect(); rainbowConn=nil end
		if colorOrRainbow=="rainbow" then
			rainbowConn=RunService.Heartbeat:Connect(function()
				ApplyAccent(Color3.fromHSV((tick()*0.1)%1, 0.85, 1))
			end)
		else
			ApplyAccent(colorOrRainbow)
			FLAGS["__accent"]={colorOrRainbow.R,colorOrRainbow.G,colorOrRainbow.B}
			saveConfig(CONFIG_FILE,FLAGS)
		end
	end

	function WinObj:SetTheme(name)
		local t, resolved = resolveTheme(name)
		if not t then warn("[ArtemisUI] unknown theme: "..tostring(name)); return end
		for k,v in pairs(t) do BASE[k]=v; C[k]=v end
		applyTheme()
		if not FLAGS["__accent"] and THEME_ACCENTS[resolved] then ApplyAccent(THEME_ACCENTS[resolved]) end
		FLAGS["__theme"]=resolved; saveConfig(CONFIG_FILE,FLAGS)
	end

	function WinObj:GetThemes()
		local out={}; for k in pairs(THEMES) do table.insert(out,k) end; table.sort(out); return out
	end

	function WinObj:TopbarButton(glyph,cb,opts)
		opts=opts or {}
		if customTopbarCount>=5 then warn("[ArtemisUI] topbar button cap reached (5)"); return nil end
		customTopbarCount=customTopbarCount+1
		local xOff=-118-(28*customTopbarCount)
		local btn=mkCtrl(xOff, opts.Icon and "" or glyph, false)
		if opts.Icon then
			local ic=mkIcon(btn,glyph,12,C.textLo,10); ic.AnchorPoint=Vector2.new(0.5,0.5); ic.Position=UDim2.new(0.5,0,0.5,0); ic.Size=UDim2.new(0,12,0,12)
			btn.MouseEnter:Connect(function() tw(ic,0.15,{ImageColor3=ACCENT}) end)
			btn.MouseLeave:Connect(function() tw(ic,0.2,{ImageColor3=C.textLo}) end)
		end
		btn.MouseButton1Click:Connect(function() if cb then safeCall(cb) end end)
		return btn
	end

	UserInputService.InputBegan:Connect(function(i,gp)
		if gp then return end
		if toggleKey and i.KeyCode==toggleKey then
			if winVisible then hideWindow() else showWindow() end
		end
	end)

	function WinObj:Tab(name)
		local tabIcon,tabLabel,tabLib=parseLabel(name); local displayName=tabIcon and tabLabel or name
		local btn
		if TAB_SIDE=="left" then
			btn=new("TextButton",{Name=name.."_Tab",Size=UDim2.new(1,0,0,32),BackgroundColor3=C.bg3,BackgroundTransparency=1,Text="",BorderSizePixel=0,ClipsDescendants=true,ZIndex=6,AutoButtonColor=false},tabScroll)
			corner(R.elem,btn); tabBtns[name]=btn
		else
			btn=new("TextButton",{Name=name.."_Tab",Size=UDim2.new(0,0,0,26),AutomaticSize=Enum.AutomaticSize.X,BackgroundColor3=C.bg3,BackgroundTransparency=1,Text="",BorderSizePixel=0,ZIndex=6,AutoButtonColor=false},tabScroll)
			corner(R.elem,btn); tabBtns[name]=btn
			new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},btn)
			inset(0,0,12,12,btn)
		end
		local ic
		if tabIcon then
			ic=mkIcon(btn,tabIcon,12,C.textLo,7,tabLib); ic.Name="Icon"; ic.LayoutOrder=0; ic.Size=UDim2.new(0,12,0,12)
			if TAB_SIDE=="left" then ic.AnchorPoint=Vector2.new(0,0); ic.Position=railOpen and UDim2.new(0,14,0.5,-6) or UDim2.new(0.5,-6,0.5,-6) end
		end
		local lbl
		if TAB_SIDE=="left" then
			lbl=new("TextLabel",{Name="Lbl",Size=UDim2.new(1,-40,1,0),Position=UDim2.new(0,32,0,0),BackgroundTransparency=1,Text=displayName,TextColor3=C.textLo,TextTransparency=railOpen and 0 or 1,Font=Enum.Font.GothamSemibold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=7},btn)
			table.insert(railRows,{icon=ic,lbl=lbl})
		else
			lbl=new("TextLabel",{Name="Lbl",Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,BackgroundTransparency=1,Text=displayName,TextColor3=C.textLo,Font=Enum.Font.GothamSemibold,TextSize=11,ZIndex=7,LayoutOrder=1},btn)
		end
		btn.MouseButton1Click:Connect(function() activateTab(name) end)
		btn.MouseEnter:Connect(function()
			if activeTab~=name then twHover(btn,0.15,{BackgroundTransparency=0.84,BackgroundColor3=C.bg4}); twHover(lbl,0.15,{TextColor3=C.textMid}); if ic then twHover(ic,0.15,{ImageColor3=C.textMid}) end end
		end)
		btn.MouseLeave:Connect(function()
			if activeTab~=name then twHover(btn,0.2,{BackgroundTransparency=1}); twHover(lbl,0.2,{TextColor3=C.textLo}); if ic then twHover(ic,0.2,{ImageColor3=C.textLo}) end end
		end)
		local pane=new("Frame",{Name=name.."_Pane",Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,BorderSizePixel=0,Visible=false,ZIndex=2},scroll)
		new("UIListLayout",{Padding=UDim.new(0,16),FillDirection=Enum.FillDirection.Horizontal,SortOrder=Enum.SortOrder.LayoutOrder,VerticalAlignment=Enum.VerticalAlignment.Top},pane)
		local colL=new("Frame",{Name="ColL",Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=1},pane)
		vstack(16,colL)
		local colR=new("Frame",{Name="ColR",Size=UDim2.new(0,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=2,Visible=false},pane)
		vstack(16,colR)
		local splitActive=false
		local function ensureSplit()
			if splitActive then return end
			splitActive=true; colL.Size=UDim2.new(0.5,-8,0,0); colR.Size=UDim2.new(0.5,-8,0,0); colR.Visible=true
		end
		local autoRight=false
		tabs[name]=pane
		if activeTab==nil then activateTab(name) end

		local TabObj={}

		function TabObj:Section(secName, column)
			local side=type(column)=="string" and column:lower() or nil
			local target
			if side=="right" then
				ensureSplit(); target=colR
			elseif side=="left" then
				target=colL
			else
				if autoRight then ensureSplit(); target=colR else target=colL end
				autoRight=not autoRight
			end
			local wrap=new("Frame",{Name=secName.."_Wrap",Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,BorderSizePixel=0},target)
			vstack(0,wrap)
			local secIcon,secLabel,secLib=parseLabel(secName)
			local hRow=new("Frame",{Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=0},wrap)
			local vBar=new("Frame",{Size=UDim2.new(0,2,0,11),Position=UDim2.new(0,0,0.5,-5.5),BackgroundColor3=ACCENT,BackgroundTransparency=0.25,BorderSizePixel=0,ZIndex=3},hRow)
			corner(1,vBar); regAc(vBar,"BackgroundColor3")
			if secIcon then
				local sic=mkIcon(hRow,secIcon,10,C.textLo,3,secLib); sic.Position=UDim2.new(0,9,0.5,-5)
				new("TextLabel",{Size=UDim2.new(1,-24,1,0),Position=UDim2.new(0,22,0,0),BackgroundTransparency=1,Text=string.upper(secLabel),TextColor3=C.textLo,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3},hRow)
			else
				new("TextLabel",{Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,9,0,0),BackgroundTransparency=1,Text=string.upper(secName),TextColor3=C.textLo,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3},hRow)
			end
			local body=new("Frame",{Name="Body",Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=C.bg2,BorderSizePixel=0,LayoutOrder=1,ClipsDescendants=false},wrap)
			corner(R.card,body); local bodyStr=outline(C.brd1,1.2,body); bodyStr.Transparency=0.3
			regTh(body,"BackgroundColor3","bg2"); regTh(bodyStr,"Color","brd1")
			local hiLine=new("Frame",{Size=UDim2.new(1,-2,0,1),Position=UDim2.new(0,1,0,1),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0.94,BorderSizePixel=0,ZIndex=4,LayoutOrder=-201},body)
			local topLine=new("Frame",{Size=UDim2.new(1,-2,0,2),Position=UDim2.new(0,1,0,0),BackgroundColor3=ACCENT,BackgroundTransparency=0.35,BorderSizePixel=0,ZIndex=5,LayoutOrder=-200},body)
			corner(1,topLine)
			new("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.08,0),NumberSequenceKeypoint.new(0.92,0),NumberSequenceKeypoint.new(1,1)})},topLine)
			regAc(topLine,"BackgroundColor3")
			body.MouseEnter:Connect(function() twHover(bodyStr,0.2,{Color=ACCENT,Transparency=0.05}) end)
			body.MouseLeave:Connect(function() twHover(bodyStr,0.3,{Color=C.brd1,Transparency=0.3}) end)
			vstack(0,body)
			local function spacer(lo) new("Frame",{Size=UDim2.new(1,0,0,7),BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=lo},body) end
			spacer(1)
			local rowN=0
			local function div()
				if rowN==0 then return end
				local d=new("Frame",{Size=UDim2.new(1,-16,0,1),BackgroundColor3=C.brd0,BackgroundTransparency=0.6,BorderSizePixel=0,LayoutOrder=rowN*100+50},body)
				regTh(d,"BackgroundColor3","brd0")
				inset(0,0,8,8,d)
			end
			local function mkRow(h)
				rowN=rowN+1
				local r=new("Frame",{Name="R"..rowN,Size=UDim2.new(1,0,0,h),BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true,LayoutOrder=rowN*100})
				corner(R.elem,r); inset(0,0,14,16,r); return r
			end

			local SecObj={}

			local function mkBindPill(parent,pos,flagKey,defaultKey,onTrigger)
				local pill=new("TextButton",{Size=UDim2.new(0,26,0,20),Position=pos,BackgroundColor3=C.bg4,Text="",BorderSizePixel=0,ZIndex=7},parent)
				corner(6,pill); local pillStr=outline(C.brd1,1,pill)
				regTh(pill,"BackgroundColor3","bg4"); regTh(pillStr,"Color","brd1")
				local keyData=keyDataFromDefault(defaultKey)
				if flagKey and FLAGS[flagKey] then keyData=keyDataFromDefault(FLAGS[flagKey]) or keyData end
				local ic=mkIcon(pill,"key-round",11,C.textLo,8); ic.AnchorPoint=Vector2.new(0.5,0.5); ic.Position=UDim2.new(0.5,0,0.5,0); ic.Size=UDim2.new(0,11,0,11)
				local kbLbl=new("TextLabel",{Size=UDim2.new(1,-4,1,0),BackgroundTransparency=1,Text="",TextColor3=ACCENT,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd,Visible=false,ZIndex=8},pill)
				regAc(kbLbl,"TextColor3")
				local clearX=new("TextButton",{Size=UDim2.new(0,11,0,11),AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,4,0,-4),BackgroundColor3=C.bg2,Text="×",TextColor3=C.textLo,Font=Enum.Font.GothamBold,TextSize=9,BorderSizePixel=0,Visible=false,ZIndex=9},pill)
				corner(5,clearX); local clearXStr=outline(C.brd0,1,clearX); regTh(clearX,"BackgroundColor3","bg2"); regTh(clearXStr,"Color","brd0")
				clearX.MouseEnter:Connect(function() twHover(clearX,0.12,{BackgroundColor3=BASE.red,TextColor3=BASE.white}) end)
				clearX.MouseLeave:Connect(function() twHover(clearX,0.16,{BackgroundColor3=C.bg2,TextColor3=C.textLo}) end)
				local binding=false; local armedAt=0
				local function refresh()
					if keyData then ic.Visible=false; kbLbl.Visible=true; kbLbl.Text=resolveKeyDisplay(keyData); kbLbl.TextColor3=ACCENT; clearX.Visible=true
					else ic.Visible=true; kbLbl.Visible=false; ic.ImageColor3=C.textLo; clearX.Visible=false end
				end
				refresh()
				pill.MouseEnter:Connect(function() twHover(pill,0.14,{BackgroundColor3=C.acDim}); if not keyData then twHover(ic,0.14,{ImageColor3=ACCENT}) end end)
				pill.MouseLeave:Connect(function() if not binding then twHover(pill,0.2,{BackgroundColor3=C.bg4}); if not keyData then twHover(ic,0.2,{ImageColor3=C.textLo}) end end end)
				local function cancelBind() binding=false; pillStr.Color=C.brd1; refresh() end
				pill.MouseButton1Click:Connect(function()
					if binding then return end
					binding=true; armedAt=os.clock(); pillStr.Color=ACCENT; pillStr.Transparency=0
					ic.Visible=false; kbLbl.Visible=true; kbLbl.TextColor3=C.textHi; kbLbl.Text="..."; clearX.Visible=false
				end)
				clearX.MouseButton1Click:Connect(function()
					if binding then cancelBind() end
					keyData=nil; refresh()
					if flagKey then FLAGS[flagKey]=nil; saveConfig(CONFIG_FILE,FLAGS) end
				end)
				pill.MouseButton2Click:Connect(function()
					if binding then cancelBind(); return end
					keyData=nil; refresh()
					if flagKey then FLAGS[flagKey]=nil; saveConfig(CONFIG_FILE,FLAGS) end
				end)
				UserInputService.InputBegan:Connect(function(i,gp)
					if binding then
						if os.clock()-armedAt<0.15 then return end
						if i.UserInputType==Enum.UserInputType.Keyboard and i.KeyCode==Enum.KeyCode.Escape then cancelBind(); return end
						local name2,isMouse=nil,false
						if i.UserInputType==Enum.UserInputType.Keyboard and i.KeyCode~=Enum.KeyCode.Unknown then name2=tostring(i.KeyCode):gsub("Enum%.KeyCode%.","")
						elseif MB_NAMES[i.UserInputType] then name2=MB_NAMES[i.UserInputType]; isMouse=true end
						if name2 then
							binding=false; keyData=isMouse and {mouse=true,inputType=i.UserInputType,name=name2} or {mouse=false,keyCode=i.KeyCode,name=name2}
							pillStr.Color=C.brd1; refresh()
							if flagKey then FLAGS[flagKey]=name2; saveConfig(CONFIG_FILE,FLAGS) end
						end
					elseif keyData and pill.Parent and not gp then
						local triggered=false
						if keyData.mouse then if i.UserInputType==keyData.inputType then triggered=true end
						else if i.UserInputType==Enum.UserInputType.Keyboard and i.KeyCode==keyData.keyCode then triggered=true end end
						if triggered and onTrigger then onTrigger() end
					end
				end)
				return pill
			end

			function SecObj:Button(text,cb,opts)
				opts=opts or {}
				local btnIcon,btnLabel,btnLib=parseLabel(text); local displayLabel=btnIcon and btnLabel or text
				div(); local r=mkRow(40); r.Parent=body
				local PILL_W=28
				local kbW=opts.Keybindable and 32 or 0
				local bg=new("Frame",{Size=UDim2.new(1,30,1,0),Position=UDim2.new(0,-14,0,0),BackgroundColor3=C.bg3,BackgroundTransparency=1,BorderSizePixel=0,ZIndex=3},r)
				corner(R.elem,bg); local bgStr=outline(C.brd1,1,bg); bgStr.Transparency=1
				local hit=new("TextButton",{Size=UDim2.new(1,30,1,0),Position=UDim2.new(0,-14,0,0),BackgroundTransparency=1,Text="",BorderSizePixel=0,ZIndex=6},r)
				corner(R.elem,hit)
				if btnIcon then local bic=mkIcon(r,btnIcon,13,C.textMid,4,btnLib); bic.Name="Icon"; bic.Position=UDim2.new(0,4,0.5,-6) end
				local lbl2=new("TextLabel",{Name="L",Size=UDim2.new(1,-(PILL_W+12+kbW+(btnIcon and 20 or 0)),1,0),Position=UDim2.new(0,btnIcon and 22 or 4,0,0),BackgroundTransparency=1,Text=displayLabel,TextColor3=C.textMid,Font=Enum.Font.GothamSemibold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=4},r)
				local pill=new("Frame",{Size=UDim2.new(0,PILL_W,0,22),Position=UDim2.new(1,-PILL_W,0.5,-11),BackgroundColor3=C.bg4,BorderSizePixel=0,ZIndex=5},r)
				corner(R.elem,pill); outline(C.brd0,1,pill)
				new("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="›",TextColor3=C.textLo,Font=Enum.Font.GothamBold,TextSize=14,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=6},pill)
				if opts.Keybindable then mkBindPill(r,UDim2.new(1,-(PILL_W+38),0.5,-10),opts.Flag and opts.Flag.."_kb" or nil,opts.Bind,function() if cb then safeCall(cb) end end) end
				hit.MouseEnter:Connect(function()
					twHover(bg,0.14,{BackgroundTransparency=0.72,BackgroundColor3=C.bg3}); twHover(bgStr,0.14,{Transparency=0,Color=C.brd1})
					twHover(lbl2,0.14,{TextColor3=C.textHi}); if r:FindFirstChild("Icon") then twHover(r.Icon,0.14,{ImageColor3=C.textHi}) end
					twHover(pill,0.14,{BackgroundColor3=C.acDim})
					local ps=pill:FindFirstChildWhichIsA("UIStroke"); if ps then twHover(ps,0.14,{Color=ACCENT,Transparency=0}) end
					local pl=pill:FindFirstChildWhichIsA("TextLabel"); if pl then twHover(pl,0.14,{TextColor3=ACCENT}) end
				end)
				hit.MouseLeave:Connect(function()
					twHover(bg,0.2,{BackgroundTransparency=1}); twHover(bgStr,0.2,{Transparency=1})
					twHover(lbl2,0.2,{TextColor3=C.textMid}); if r:FindFirstChild("Icon") then twHover(r.Icon,0.2,{ImageColor3=C.textMid}) end
					twHover(pill,0.2,{BackgroundColor3=C.bg4})
					local ps=pill:FindFirstChildWhichIsA("UIStroke"); if ps then twHover(ps,0.2,{Color=C.brd0,Transparency=0}) end
					local pl=pill:FindFirstChildWhichIsA("TextLabel"); if pl then twHover(pl,0.2,{TextColor3=C.textLo}) end
				end)
				hit.MouseButton1Down:Connect(function() ripple(hit,ACCENT,1.8); twHover(bg,0.08,{BackgroundColor3=C.acDim,BackgroundTransparency=0.62}); twHover(bgStr,0.08,{Color=ACCENT,Transparency=0}) end)
				hit.MouseButton1Up:Connect(function()
					twHover(bg,0.35,{BackgroundColor3=C.bg3,BackgroundTransparency=1}); twHover(bgStr,0.35,{Transparency=1})
					if cb then
						local ok,err=safeCall(cb)
						if not ok then
							local orig=lbl2.Text
							twHover(bg,0.15,{BackgroundColor3=BASE.red,BackgroundTransparency=0.52}); twHover(bgStr,0.15,{Color=BASE.red,Transparency=0})
							lbl2.Text="Error"
							task.delay(1.2,function() twHover(bg,0.35,{BackgroundTransparency=1}); twHover(bgStr,0.35,{Transparency=1}); lbl2.Text=orig end)
						end
					end
				end)
				table.insert(searchRegistry,{label=displayLabel,kind="button",cb=cb,row=r,tabName=name})
			end

			function SecObj:Toggle(text,default,cb,opts)
				opts=opts or {}
				local togIcon,togLabel,togLib=parseLabel(text); local displayLabel=togIcon and togLabel or text
				div(); local r=mkRow(40); r.Parent=body
				local on=default==true
				if togIcon then local tImg=mkIcon(r,togIcon,14,C.textMid,4,togLib); tImg.Position=UDim2.new(0,0,0.5,-7) end
				new("TextLabel",{Name="L",Size=UDim2.new(1,-92,1,0),Position=UDim2.new(0,togIcon and 18 or 0,0,0),BackgroundTransparency=1,Text=displayLabel,TextColor3=C.textMid,Font=Enum.Font.GothamSemibold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=4},r)
				local track=new("Frame",{Size=UDim2.new(0,38,0,20),Position=UDim2.new(1,-38,0.5,-10),BackgroundColor3=on and ACCENT or C.bg4,BorderSizePixel=0,ClipsDescendants=false,ZIndex=4},r)
				corner(R.toggle,track); local tStr=outline(on and ACCENT or C.brd1,1,track)
				local knob=new("Frame",{Size=UDim2.new(0,14,0,14),Position=UDim2.new(0,on and 21 or 3,0.5,-7),BackgroundColor3=C.white,BorderSizePixel=0,ZIndex=5},track)
				corner(R.knob,knob)
				regAcIf(track,"BackgroundColor3",function() return on end)
				regAcIf(tStr,"Color",function() return on end)
				regTh(track,"BackgroundColor3","bg4",function() return not on end)
				regTh(tStr,"Color","brd1",function() return not on end)
				regTh(knob,"BackgroundColor3","white")
				local click=new("TextButton",{Size=UDim2.new(1,30,1,0),Position=UDim2.new(0,-14,0,0),BackgroundTransparency=1,Text="",BorderSizePixel=0,ZIndex=6},r)
				local function setT(v,skipSave)
					if on==v then return end; on=v
					twHover(track,0.22,{BackgroundColor3=on and ACCENT or C.bg4}); twHover(tStr,0.22,{Color=on and ACCENT or C.brd1})
					TweenService:Create(knob,TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(0,on and 21 or 3,0.5,-7)}):Play()
					if opts.Flag and not skipSave then FLAGS[opts.Flag]=on; saveConfig(CONFIG_FILE,FLAGS) end
					if cb then task.spawn(cb,on) end
				end
				mkBindPill(r,UDim2.new(1,-70,0.5,-10),opts.Flag and opts.Flag.."_kb" or nil,opts.Bind,function() setT(not on) end)
				if opts.Flag then
					flagHandlers[opts.Flag]=function(value) if type(value)=="boolean" and value~=on then setT(value,true) end end
					if FLAGS[opts.Flag]~=nil then
						local saved=FLAGS[opts.Flag]
						if saved~=on then on=saved; track.BackgroundColor3=on and ACCENT or C.bg4; tStr.Color=on and ACCENT or C.brd1; knob.Position=UDim2.new(0,on and 21 or 3,0.5,-7); if cb then task.spawn(cb,on) end end
					end
				end
				click.MouseEnter:Connect(function() twHover(r,0.14,{BackgroundColor3=C.bg4,BackgroundTransparency=0.88}) end)
				click.MouseLeave:Connect(function() twHover(r,0.2,{BackgroundTransparency=1}) end)
				click.MouseButton1Click:Connect(function() setT(not on) end)
				table.insert(searchRegistry,{label=displayLabel,kind="toggle",cb=function() setT(not on) end,row=r,tabName=name})
				return {Set=function(_,v) setT(v) end, Get=function() return on end, Toggle=function() setT(not on) end}
			end

			function SecObj:Slider(text,minV,maxV,defV,cb,opts)
				opts=opts or {}
				local slIcon,slLabel,slLib=parseLabel(text); local displayLabel=slIcon and slLabel or text
				local increment=opts.Increment or 1
				div(); local r=mkRow(54); r.Parent=body
				local topR=new("Frame",{Size=UDim2.new(1,0,0,18),Position=UDim2.new(0,0,0,8),BackgroundTransparency=1,ZIndex=4},r)
				if slIcon then local slImg=mkIcon(topR,slIcon,13,C.textMid,4,slLib); slImg.Position=UDim2.new(0,0,0.5,-6) end
				new("TextLabel",{Size=UDim2.new(1,-62,1,0),Position=UDim2.new(0,slIcon and 18 or 0,0,0),BackgroundTransparency=1,Text=displayLabel,TextColor3=C.textMid,Font=Enum.Font.GothamSemibold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=4},topR)
				local valPill=new("Frame",{Size=UDim2.new(0,54,0,20),Position=UDim2.new(1,-54,0.5,-10),BackgroundColor3=C.acDim,BorderSizePixel=0,ZIndex=4},topR)
				corner(R.elem,valPill)
				local valPillStr=outline(ACCENT,1,valPill); regAc(valPillStr,"Color")
				regAc(valPill,"BackgroundColor3","dim")
				local valLbl=new("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=tostring(defV or minV),TextColor3=ACCENT,Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=5},valPill)
				regAc(valLbl,"TextColor3")
				local trackWrap=new("Frame",{Size=UDim2.new(1,0,0,18),Position=UDim2.new(0,0,1,-20),BackgroundTransparency=1,ZIndex=3},r)
				local track=new("Frame",{Name="Track",Size=UDim2.new(1,0,0,5),Position=UDim2.new(0,0,0.5,-2),BackgroundColor3=C.bg4,BorderSizePixel=0,ClipsDescendants=false,ZIndex=4},trackWrap)
				corner(R.track,track); local trackStr=outline(C.brd0,1,track)
				regTh(track,"BackgroundColor3","bg4"); regTh(trackStr,"Color","brd0")
				local curV=defV or minV
				if opts.Flag and FLAGS[opts.Flag]~=nil then curV=math.clamp(FLAGS[opts.Flag],minV,maxV) end
				local iR=math.clamp((curV-minV)/(maxV-minV),0,1)
				local fill=new("Frame",{Size=UDim2.new(iR,0,1,0),BackgroundColor3=ACCENT,BorderSizePixel=0,ClipsDescendants=false,ZIndex=5},track)
				corner(R.track,fill); regAc(fill,"BackgroundColor3")
				new("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.new(1,1,1))}),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.35),NumberSequenceKeypoint.new(1,0)})},fill)
				local knob=new("Frame",{Name="Knob",Size=UDim2.new(0,14,0,14),Position=UDim2.new(iR,-7,0.5,-7),BackgroundColor3=C.white,BorderSizePixel=0,ClipsDescendants=false,ZIndex=6},track)
				corner(R.knob,knob)
				regTh(knob,"BackgroundColor3","white")
				local knobStr=outline(ACCENT,1.5,knob); regAc(knobStr,"Color")
				valLbl.Text=tostring(curV)
				local sliding=false
				local function upd(ax)
					local ta=track.AbsolutePosition.X; local ts=track.AbsoluteSize.X; if ts==0 then return end
					local ra=math.clamp((ax-ta)/ts,0,1)
					curV=math.clamp(math.round((ra*(maxV-minV)+minV)/increment)*increment,minV,maxV)
					local r2=(curV-minV)/(maxV-minV)
					fill.Size=UDim2.new(r2,0,1,0); knob.Position=UDim2.new(r2,-7,0.5,-7); valLbl.Text=tostring(curV)
					if opts.Flag then FLAGS[opts.Flag]=curV; saveConfig(CONFIG_FILE,FLAGS) end
					if cb then task.spawn(cb,curV) end
				end
				track.InputBegan:Connect(function(i)
					if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
					sliding=true; upd(i.Position.X)
					TweenService:Create(knob,TweenInfo.new(0.14,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,17,0,17),Position=UDim2.new((curV-minV)/(maxV-minV),-8.5,0.5,-8.5)}):Play()
					tw(track:FindFirstChildWhichIsA("UIStroke"),0.15,{Color=ACCENT,Transparency=0})
				end)
				local sliderLoop=RunService.RenderStepped:Connect(function() if sliding then upd(UserInputService:GetMouseLocation().X) end end)
				UserInputService.InputEnded:Connect(function(i)
					if sliding and i.UserInputType==Enum.UserInputType.MouseButton1 then
						sliding=false; local r2=(curV-minV)/(maxV-minV)
						TweenService:Create(knob,TweenInfo.new(0.18,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,14,0,14),Position=UDim2.new(r2,-7,0.5,-7)}):Play()
						tw(track:FindFirstChildWhichIsA("UIStroke"),0.22,{Color=C.brd0,Transparency=0})
					end
				end)
				r.AncestryChanged:Connect(function() if not r.Parent then sliderLoop:Disconnect() end end)
				if opts.Flag then
					flagHandlers[opts.Flag]=function(value)
						if type(value)=="number" then
							local v=math.clamp(value,minV,maxV)
							if v~=curV then curV=v; local r2=(curV-minV)/(maxV-minV); fill.Size=UDim2.new(r2,0,1,0); knob.Position=UDim2.new(r2,-7,0.5,-7); valLbl.Text=tostring(curV); if cb then task.spawn(cb,curV) end end
						end
					end
				end
				table.insert(searchRegistry,{label=displayLabel,kind="slider",cb=nil,row=r,tabName=name})
				return {
					Get=function() return curV end,
					Set=function(_,v)
						curV=math.clamp(v,minV,maxV); local r2=(curV-minV)/(maxV-minV)
						fill.Size=UDim2.new(r2,0,1,0); knob.Position=UDim2.new(r2,-7,0.5,-7); valLbl.Text=tostring(curV)
						if opts.Flag then FLAGS[opts.Flag]=curV; saveConfig(CONFIG_FILE,FLAGS) end
						if cb then task.spawn(cb,curV) end
					end
				}
			end

			function SecObj:ColorPicker(text,default,cb,opts)
				opts=opts or {}
				local cpIcon,cpLabel,cpLib=parseLabel(text); local displayLabel=cpIcon and cpLabel or text
				div(); local r=mkRow(40); r.Parent=body
				local currentColor=default or Color3.fromRGB(255,100,100)
				local h,s,v=Color3.toHSV(currentColor)
				if cpIcon then local cic=mkIcon(r,cpIcon,14,C.textMid,4,cpLib); cic.Position=UDim2.new(0,0,0.5,-7) end
				new("TextLabel",{Size=UDim2.new(1,-46,1,0),Position=UDim2.new(0,cpIcon and 18 or 0,0,0),BackgroundTransparency=1,Text=displayLabel,TextColor3=C.textMid,Font=Enum.Font.GothamSemibold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=4},r)
				local swatch=new("Frame",{Size=UDim2.new(0,34,0,22),Position=UDim2.new(1,-34,0.5,-11),BackgroundColor3=currentColor,BorderSizePixel=0,ZIndex=4},r)
				corner(6,swatch); outline(C.brd1,1,swatch)
				local PANEL_W=192; local PANEL_H=174; local open=false
				local panel=new("Frame",{Name="CPPanel",Size=UDim2.new(0,PANEL_W,0,0),BackgroundColor3=C.bg2,BorderSizePixel=0,ClipsDescendants=true,ZIndex=300,Visible=false},win)
				corner(10,panel); outline(C.brd1,1,panel)
				regAc(mkGlowLine(panel,ACCENT,0.6,302),"BackgroundColor3")
				vstack(8,panel); inset(8,8,8,8,panel)
				local svBase=new("Frame",{Size=UDim2.new(1,0,0,100),BackgroundColor3=Color3.fromHSV(h,1,1),BorderSizePixel=0,ClipsDescendants=false,ZIndex=302},panel); corner(5,svBase)
				local satLayer=new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=303},svBase)
				new("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}),Rotation=0},satLayer)
				local valLayer=new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=304},svBase)
				new("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}),Rotation=90},valLayer)
				local svCursor=new("Frame",{Size=UDim2.new(0,12,0,12),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(s,0,1-v,0),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=305},svBase)
				corner(99,svCursor); outline(Color3.new(0,0,0),1.5,svCursor)
				local hueTrack=new("Frame",{Size=UDim2.new(1,0,0,14),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ClipsDescendants=false,ZIndex=302},panel); corner(4,hueTrack)
				new("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromHSV(0,1,1)),ColorSequenceKeypoint.new(1/6,Color3.fromHSV(1/6,1,1)),ColorSequenceKeypoint.new(2/6,Color3.fromHSV(2/6,1,1)),ColorSequenceKeypoint.new(3/6,Color3.fromHSV(3/6,1,1)),ColorSequenceKeypoint.new(4/6,Color3.fromHSV(4/6,1,1)),ColorSequenceKeypoint.new(5/6,Color3.fromHSV(5/6,1,1)),ColorSequenceKeypoint.new(1,Color3.fromHSV(0,1,1))})},hueTrack)
				local hueCursor=new("Frame",{Size=UDim2.new(0,10,1,6),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(h,0,0.5,0),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=303},hueTrack)
				corner(3,hueCursor); outline(Color3.new(0,0,0),1.5,hueCursor)
				local hexRow=new("Frame",{Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=302},panel)
				local hexWrap=new("Frame",{Size=UDim2.new(1,-34,1,0),BackgroundColor3=C.bg3,BorderSizePixel=0,ZIndex=303},hexRow)
				corner(R.elem,hexWrap); outline(C.brd1,1,hexWrap)
				new("TextLabel",{Size=UDim2.new(0,20,1,0),BackgroundTransparency=1,Text="#",TextColor3=C.textLo,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=304},hexWrap)
				local hexBox=new("TextBox",{Size=UDim2.new(1,-20,1,0),Position=UDim2.new(0,20,0,0),BackgroundTransparency=1,Text=colorToHex(currentColor),TextColor3=C.textHi,Font=Enum.Font.GothamSemibold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,BorderSizePixel=0,ZIndex=304},hexWrap)
				inset(0,0,0,4,hexBox)
				local cpPreview=new("Frame",{Size=UDim2.new(0,26,1,0),Position=UDim2.new(1,-26,0,0),BackgroundColor3=currentColor,BorderSizePixel=0,ZIndex=303},hexRow)
				corner(R.elem,cpPreview); outline(C.brd1,1,cpPreview)
				local function getScale() local sc=win:FindFirstChildWhichIsA("UIScale",true); return sc and sc.Scale or 1 end
				local function updatePanelPos()
					local sc=getScale(); local abs=swatch.AbsolutePosition; local sz=swatch.AbsoluteSize
					local winAbs=win.AbsolutePosition; local winSz=win.AbsoluteSize
					local relX=(abs.X-winAbs.X)/sc; local relY=(abs.Y-winAbs.Y)/sc
					local xOff=math.clamp(relX+sz.X/sc-PANEL_W,4,winSz.X/sc-PANEL_W-4)
					local openDown=(relY+sz.Y/sc+PANEL_H+6)<=winSz.Y/sc
					panel.Position=UDim2.new(0,xOff,0,openDown and (relY+sz.Y/sc+4) or (relY-PANEL_H-4))
				end
				local function updateColor()
					currentColor=Color3.fromHSV(h,s,v); swatch.BackgroundColor3=currentColor; cpPreview.BackgroundColor3=currentColor
					svBase.BackgroundColor3=Color3.fromHSV(h,1,1); svCursor.Position=UDim2.new(s,0,1-v,0); hueCursor.Position=UDim2.new(h,0,0.5,0)
					hexBox.Text=colorToHex(currentColor)
					if opts.Flag then FLAGS[opts.Flag]={currentColor.R,currentColor.G,currentColor.B}; saveConfig(CONFIG_FILE,FLAGS) end
					if cb then task.spawn(cb,currentColor) end
				end
				local function closePanel() open=false; tw(panel,0.18,{Size=UDim2.new(0,PANEL_W,0,0)}); task.delay(0.18,function() panel.Visible=false end) end
				local function openPanel() open=true; updatePanelPos(); panel.Visible=true; panel.Size=UDim2.new(0,PANEL_W,0,0); twBack(panel,0.25,{Size=UDim2.new(0,PANEL_W,0,PANEL_H)}) end
				local svDragging=false
				local svHit=new("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",BorderSizePixel=0,ZIndex=306},svBase)
				svHit.InputBegan:Connect(function(i)
					if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end; svDragging=true
					local abs=svBase.AbsolutePosition; local sz=svBase.AbsoluteSize
					s=math.clamp((i.Position.X-abs.X)/sz.X,0,1); v=math.clamp(1-(i.Position.Y-abs.Y)/sz.Y,0,1); updateColor()
				end)
				local svLoop=RunService.RenderStepped:Connect(function()
					if svDragging then
						local mp=UserInputService:GetMouseLocation(); local abs=svBase.AbsolutePosition; local sz=svBase.AbsoluteSize
						s=math.clamp((mp.X-abs.X)/sz.X,0,1); v=math.clamp(1-(mp.Y-abs.Y)/sz.Y,0,1); updateColor()
					end
				end)
				local hueDragging=false
				local hueHit=new("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",BorderSizePixel=0,ZIndex=304},hueTrack)
				hueHit.InputBegan:Connect(function(i)
					if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end; hueDragging=true
					local abs=hueTrack.AbsolutePosition; local sz=hueTrack.AbsoluteSize
					h=math.clamp((i.Position.X-abs.X)/sz.X,0,1); updateColor()
				end)
				local hueLoop=RunService.RenderStepped:Connect(function()
					if hueDragging then
						local mp=UserInputService:GetMouseLocation(); local abs=hueTrack.AbsolutePosition; local sz=hueTrack.AbsoluteSize
						h=math.clamp((mp.X-abs.X)/sz.X,0,1); updateColor()
					end
				end)
				UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then svDragging=false; hueDragging=false end end)
				panel.AncestryChanged:Connect(function() if not panel.Parent then svLoop:Disconnect(); hueLoop:Disconnect() end end)
				hexBox.FocusLost:Connect(function()
					local c=hexToColor(hexBox.Text)
					if c then
						currentColor=c; h,s,v=Color3.toHSV(c); swatch.BackgroundColor3=c; cpPreview.BackgroundColor3=c
						svBase.BackgroundColor3=Color3.fromHSV(h,1,1); svCursor.Position=UDim2.new(s,0,1-v,0); hueCursor.Position=UDim2.new(h,0,0.5,0)
						if opts.Flag then FLAGS[opts.Flag]={c.R,c.G,c.B}; saveConfig(CONFIG_FILE,FLAGS) end
						if cb then task.spawn(cb,c) end
					else hexBox.Text=colorToHex(currentColor) end
				end)
				local swatchHit=new("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",BorderSizePixel=0,ZIndex=5},r)
				swatchHit.MouseButton1Click:Connect(function() if open then closePanel() else openPanel() end end)
				swatchHit.MouseEnter:Connect(function() twHover(r,0.14,{BackgroundColor3=C.bg4,BackgroundTransparency=0.9}) end)
				swatchHit.MouseLeave:Connect(function() twHover(r,0.2,{BackgroundTransparency=1}) end)
				win:GetPropertyChangedSignal("Position"):Connect(function() if open then updatePanelPos() end end)
				scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function() if open then updatePanelPos() end end)
				UserInputService.InputBegan:Connect(function(i,gp)
					if gp then return end
					if open and i.UserInputType==Enum.UserInputType.MouseButton1 then
						local mp=UserInputService:GetMouseLocation()
						local pa=panel.AbsolutePosition; local ps=panel.AbsoluteSize; local ra=r.AbsolutePosition; local rs=r.AbsoluteSize
						if not(mp.X>=pa.X and mp.X<=pa.X+ps.X and mp.Y>=pa.Y and mp.Y<=pa.Y+ps.Y) and not(mp.X>=ra.X and mp.X<=ra.X+rs.X and mp.Y>=ra.Y and mp.Y<=ra.Y+rs.Y) then closePanel() end
					end
				end)
				if opts.Flag then
					if FLAGS[opts.Flag] and type(FLAGS[opts.Flag])=="table" then
						local t=FLAGS[opts.Flag]; if t[1] and t[2] and t[3] then currentColor=Color3.new(t[1],t[2],t[3]); h,s,v=Color3.toHSV(currentColor); swatch.BackgroundColor3=currentColor end
					end
					flagHandlers[opts.Flag]=function(value)
						if type(value)=="table" and value[1] and value[2] and value[3] then
							currentColor=Color3.new(value[1],value[2],value[3]); h,s,v=Color3.toHSV(currentColor)
							swatch.BackgroundColor3=currentColor; cpPreview.BackgroundColor3=currentColor; svBase.BackgroundColor3=Color3.fromHSV(h,1,1)
							svCursor.Position=UDim2.new(s,0,1-v,0); hueCursor.Position=UDim2.new(h,0,0.5,0); hexBox.Text=colorToHex(currentColor)
							if cb then task.spawn(cb,currentColor) end
						end
					end
				end
				table.insert(searchRegistry,{label=displayLabel,kind="colorpicker",cb=nil,row=r,tabName=name})
				return {
					Get=function() return currentColor end,
					Set=function(_,c)
						currentColor=c; h,s,v=Color3.toHSV(c); swatch.BackgroundColor3=c; cpPreview.BackgroundColor3=c
						svBase.BackgroundColor3=Color3.fromHSV(h,1,1); svCursor.Position=UDim2.new(s,0,1-v,0); hueCursor.Position=UDim2.new(h,0,0.5,0)
						hexBox.Text=colorToHex(c)
						if opts.Flag then FLAGS[opts.Flag]={c.R,c.G,c.B}; saveConfig(CONFIG_FILE,FLAGS) end
						if cb then task.spawn(cb,c) end
					end
				}
			end

			function SecObj:Dropdown(text,options,cb,opts)
				opts=opts or {}; div(); rowN=rowN+1
				local sel=options[1] or ""; local ddOpen=false; local filtered={table.unpack(options)}
				if opts.Flag and FLAGS[opts.Flag]~=nil then sel=FLAGS[opts.Flag] end
				local OPTION_H=30; local MAX_LIST_H=152; local CLOSED_H=38; local SEARCH_H=32
				local container=new("Frame",{Name="DD"..rowN,Size=UDim2.new(1,0,0,CLOSED_H),BackgroundColor3=C.bg2,BackgroundTransparency=0,BorderSizePixel=0,ClipsDescendants=true,LayoutOrder=rowN*100,ZIndex=3},body)
				corner(R.elem,container); local contStr=outline(C.brd0,1,container)
				local header=new("Frame",{Size=UDim2.new(1,0,0,CLOSED_H),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=4},container)
				inset(0,0,14,14,header)
				new("TextLabel",{Size=UDim2.new(0.55,0,1,0),BackgroundTransparency=1,Text=text,TextColor3=C.textMid,Font=Enum.Font.GothamSemibold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5},header)
				local rightWrap=new("Frame",{Size=UDim2.new(0.45,0,1,0),Position=UDim2.new(0.55,0,0,0),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=5},header)
				local selLbl=new("TextLabel",{Size=UDim2.new(1,-20,1,0),BackgroundTransparency=1,Text=sel,TextColor3=ACCENT,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Right,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=6},rightWrap)
				regAc(selLbl,"TextColor3")
				local chev=new("TextLabel",{Size=UDim2.new(0,16,1,0),Position=UDim2.new(1,-16,0,0),BackgroundTransparency=1,Text="▼",TextColor3=C.textLo,Font=Enum.Font.GothamBold,TextSize=9,ZIndex=6},rightWrap)
				local divLine=new("Frame",{Size=UDim2.new(1,-20,0,1),Position=UDim2.new(0,10,0,CLOSED_H),BackgroundColor3=C.brd0,BackgroundTransparency=0.45,BorderSizePixel=0,ZIndex=4,Visible=false},container)
				local searchWrap=new("Frame",{Size=UDim2.new(1,0,0,SEARCH_H),Position=UDim2.new(0,0,0,CLOSED_H+1),BackgroundColor3=C.bg3,BackgroundTransparency=0,BorderSizePixel=0,ZIndex=5},container)
				inset(0,0,10,10,searchWrap)
				local searchIconImg=mkIcon(searchWrap,"search",12,C.textLo,6)
				searchIconImg.AnchorPoint=Vector2.new(0,0.5); searchIconImg.Position=UDim2.new(0,0,0.5,0); searchIconImg.Size=UDim2.new(0,12,0,12)
				local searchInput=new("TextBox",{Size=UDim2.new(1,-20,1,0),Position=UDim2.new(0,20,0,0),BackgroundTransparency=1,Text="",PlaceholderText="Search...",TextColor3=C.textHi,PlaceholderColor3=C.textLo,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,BorderSizePixel=0,ZIndex=6},searchWrap)
				local searchDivLine=new("Frame",{Size=UDim2.new(1,-20,0,1),Position=UDim2.new(0,10,0,CLOSED_H+SEARCH_H+1),BackgroundColor3=C.brd0,BackgroundTransparency=0.6,BorderSizePixel=0,ZIndex=4,Visible=false},container)
				local listScroll=new("ScrollingFrame",{Size=UDim2.new(1,0,1,-(CLOSED_H+SEARCH_H+2)),Position=UDim2.new(0,0,0,CLOSED_H+SEARCH_H+2),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=ACCENT,ScrollBarImageTransparency=0.45,ScrollingDirection=Enum.ScrollingDirection.Y,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=5},container)
				regAc(listScroll,"ScrollBarImageColor3")
				vstack(2,listScroll); inset(4,4,8,8,listScroll)
				local function computeListH(list) return math.min(#list*(OPTION_H+2)+8,MAX_LIST_H) end
				local function applyOptionStates()
					for _,b in ipairs(listScroll:GetChildren()) do
						if b:IsA("TextButton") then
							local lbl=b:FindFirstChildWhichIsA("TextLabel"); local match=lbl and lbl.Text==sel
							b.BackgroundColor3=match and C.acDim or C.bg3; b.BackgroundTransparency=match and 0 or 1
							if lbl then lbl.TextColor3=match and ACCENT or C.textMid end
							local s2=b:FindFirstChildWhichIsA("UIStroke"); if s2 then s2.Color=match and ACCENT or C.brd0; s2.Thickness=match and 1 or 0 end
						end
					end
				end
				local function buildOptions(list)
					for _,ch in ipairs(listScroll:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
					for _,opt in ipairs(list) do
						local isSel=opt==sel
						local ob=new("TextButton",{Size=UDim2.new(1,0,0,OPTION_H),BackgroundColor3=isSel and C.acDim or C.bg3,BackgroundTransparency=isSel and 0 or 1,Text="",BorderSizePixel=0,AutoButtonColor=false,ZIndex=6},listScroll)
						corner(6,ob); local obStr=outline(isSel and ACCENT or C.brd0,isSel and 1 or 0,ob)
						local obLbl=new("TextLabel",{Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,12,0,0),BackgroundTransparency=1,Text=opt,TextColor3=isSel and ACCENT or C.textMid,Font=Enum.Font.GothamSemibold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7},ob)
						ob.MouseEnter:Connect(function() if opt~=sel then twHover(ob,0.1,{BackgroundTransparency=0.75,BackgroundColor3=C.bg4}); twHover(obLbl,0.1,{TextColor3=C.textHi}) end end)
						ob.MouseLeave:Connect(function() if opt~=sel then twHover(ob,0.16,{BackgroundTransparency=1}); twHover(obLbl,0.16,{TextColor3=C.textMid}) end end)
						ob.MouseButton1Click:Connect(function()
							sel=opt; selLbl.Text=sel
							if opts.Flag then FLAGS[opts.Flag]=sel; saveConfig(CONFIG_FILE,FLAGS) end
							applyOptionStates(); if cb then task.spawn(cb,sel) end
							searchInput.Text=""; filtered={table.unpack(options)}; buildOptions(filtered)
							ddOpen=false; tw(container,0.28,{Size=UDim2.new(1,0,0,CLOSED_H)}); tw(chev,0.2,{Rotation=0}); tw(contStr,0.22,{Color=C.brd0})
							task.delay(0.25,function() if not ddOpen then divLine.Visible=false; searchDivLine.Visible=false end end)
						end)
					end
				end
				local function filterOptions(query)
					query=string.lower(string.match(query,"^%s*(.-)%s*$"))
					if query=="" then filtered={table.unpack(options)} else filtered={}; for _,opt in ipairs(options) do if string.find(string.lower(opt),query,1,true) then table.insert(filtered,opt) end end end
					buildOptions(filtered)
					if ddOpen then tw(container,0.18,{Size=UDim2.new(1,0,0,CLOSED_H+SEARCH_H+2+computeListH(filtered))},Enum.EasingStyle.Quint) end
				end
				local function closeDD()
					ddOpen=false; tw(container,0.28,{Size=UDim2.new(1,0,0,CLOSED_H)}); tw(chev,0.2,{Rotation=0}); tw(contStr,0.22,{Color=C.brd0})
					task.delay(0.25,function() if not ddOpen then divLine.Visible=false; searchDivLine.Visible=false end end)
				end
				local function openDD()
					ddOpen=true; searchInput.Text=""; filtered={table.unpack(options)}; buildOptions(filtered)
					divLine.Visible=true; searchDivLine.Visible=true
					twBack(container,0.3,{Size=UDim2.new(1,0,0,CLOSED_H+SEARCH_H+2+computeListH(filtered))})
					tw(chev,0.2,{Rotation=180}); tw(contStr,0.2,{Color=ACCENT})
					task.delay(0.18,function() if ddOpen then task.defer(function() searchInput:CaptureFocus() end) end end)
				end
				searchInput:GetPropertyChangedSignal("Text"):Connect(function() filterOptions(searchInput.Text) end)
				searchInput.Focused:Connect(function() twHover(searchIconImg,0.15,{ImageColor3=ACCENT}) end)
				searchInput.FocusLost:Connect(function() twHover(searchIconImg,0.2,{ImageColor3=C.textLo}) end)
				buildOptions(options)
				local hit=new("TextButton",{Size=UDim2.new(1,0,0,CLOSED_H),BackgroundTransparency=1,Text="",BorderSizePixel=0,ZIndex=7},container)
				hit.MouseButton1Click:Connect(function() if ddOpen then closeDD() else openDD() end end)
				hit.MouseEnter:Connect(function() if not ddOpen then twHover(container,0.14,{BackgroundColor3=C.bg3}) end end)
				hit.MouseLeave:Connect(function() if not ddOpen then twHover(container,0.2,{BackgroundColor3=C.bg2}) end end)
				if opts.Flag then flagHandlers[opts.Flag]=function(value) if type(value)=="string" then sel=value; selLbl.Text=value; applyOptionStates() end end end
				table.insert(searchRegistry,{label=text,kind="dropdown",cb=nil,row=container,tabName=name})
				return {
					Get=function() return sel end,
					Set=function(_,v) sel=v; selLbl.Text=v; if opts.Flag then FLAGS[opts.Flag]=v; saveConfig(CONFIG_FILE,FLAGS) end; applyOptionStates() end,
					Update=function(_,newOptions) options=newOptions; filtered={table.unpack(newOptions)}; sel=newOptions[1] or ""; selLbl.Text=sel; buildOptions(filtered) end
				}
			end

			function SecObj:MultiDropdown(text, options, defaults, cb, opts)
				opts = opts or {}
				local ddIcon, ddLabel, ddLib = parseLabel(text)
				local displayLabel = ddIcon and ddLabel or text
				div(); rowN = rowN + 1

				local selected = {}
				if defaults and type(defaults) == "table" then
					for _, v in ipairs(defaults) do selected[v] = true end
				end

				if opts.Flag and FLAGS[opts.Flag] ~= nil and type(FLAGS[opts.Flag]) == "table" then
					selected = {}
					for _, v in ipairs(FLAGS[opts.Flag]) do selected[v] = true end
				end

				local ddOpen = false
				local filtered = { table.unpack(options) }

				local OPTION_H   = 30
				local MAX_LIST_H = 152
				local CLOSED_H   = 38
				local SEARCH_H   = 32

				local function getSelected()
					local out = {}
					for _, opt in ipairs(options) do
						if selected[opt] then table.insert(out, opt) end
					end
					return out
				end

				local function saveAndFire()
					local out = getSelected()
					if opts.Flag then
						FLAGS[opts.Flag] = out
						saveConfig(CONFIG_FILE, FLAGS)
					end
					if cb then task.spawn(cb, out) end
				end

				local function buildLabel()
					local out = getSelected()
					if #out == 0 then return "None"
					elseif #out == 1 then return out[1]
					elseif #out == #options then return "All"
					else return #out .. " selected" end
				end

				local container = new("Frame", {
					Name = "MDD" .. rowN,
					Size = UDim2.new(1, 0, 0, CLOSED_H),
					BackgroundColor3 = C.bg2,
					BackgroundTransparency = 0,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					LayoutOrder = rowN * 100,
					ZIndex = 3
				}, body)
				corner(R.elem, container)
				local contStr = outline(C.brd0, 1, container)

				local header = new("Frame", {
					Size = UDim2.new(1, 0, 0, CLOSED_H),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 4
				}, container)
				inset(0, 0, 14, 14, header)

				if ddIcon then
					local dic = mkIcon(header, ddIcon, 13, C.textMid, 5, ddLib)
					dic.Position = UDim2.new(0, 0, 0.5, -6)
				end

				new("TextLabel", {
					Size = UDim2.new(0.5, 0, 1, 0),
					Position = UDim2.new(0, ddIcon and 18 or 0, 0, 0),
					BackgroundTransparency = 1,
					Text = displayLabel,
					TextColor3 = C.textMid,
					Font = Enum.Font.GothamSemibold,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 5
				}, header)

				local rightWrap = new("Frame", {
					Size = UDim2.new(0.5, 0, 1, 0),
					Position = UDim2.new(0.5, 0, 0, 0),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 5
				}, header)

				local selLbl = new("TextLabel", {
					Size = UDim2.new(1, -20, 1, 0),
					BackgroundTransparency = 1,
					Text = buildLabel(),
					TextColor3 = ACCENT,
					Font = Enum.Font.GothamBold,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Right,
					TextTruncate = Enum.TextTruncate.AtEnd,
					ZIndex = 6
				}, rightWrap)
				regAc(selLbl, "TextColor3")

				local chev = new("TextLabel", {
					Size = UDim2.new(0, 16, 1, 0),
					Position = UDim2.new(1, -16, 0, 0),
					BackgroundTransparency = 1,
					Text = "▼",
					TextColor3 = C.textLo,
					Font = Enum.Font.GothamBold,
					TextSize = 9,
					ZIndex = 6
				}, rightWrap)

				local divLine = new("Frame", {
					Size = UDim2.new(1, -20, 0, 1),
					Position = UDim2.new(0, 10, 0, CLOSED_H),
					BackgroundColor3 = C.brd0,
					BackgroundTransparency = 0.45,
					BorderSizePixel = 0,
					ZIndex = 4,
					Visible = false
				}, container)

				local searchWrap = new("Frame", {
					Size = UDim2.new(1, 0, 0, SEARCH_H),
					Position = UDim2.new(0, 0, 0, CLOSED_H + 1),
					BackgroundColor3 = C.bg3,
					BackgroundTransparency = 0,
					BorderSizePixel = 0,
					ZIndex = 5
				}, container)
				inset(0, 0, 10, 10, searchWrap)

				local searchIconImg = mkIcon(searchWrap, "search", 12, C.textLo, 6)
				searchIconImg.AnchorPoint = Vector2.new(0, 0.5)
				searchIconImg.Position = UDim2.new(0, 0, 0.5, 0)
				searchIconImg.Size = UDim2.new(0, 12, 0, 12)

				local searchInput = new("TextBox", {
					Size = UDim2.new(1, -20, 1, 0),
					Position = UDim2.new(0, 20, 0, 0),
					BackgroundTransparency = 1,
					Text = "",
					PlaceholderText = "Search...",
					TextColor3 = C.textHi,
					PlaceholderColor3 = C.textLo,
					Font = Enum.Font.Gotham,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					ClearTextOnFocus = false,
					BorderSizePixel = 0,
					ZIndex = 6
				}, searchWrap)

				local searchDivLine = new("Frame", {
					Size = UDim2.new(1, -20, 0, 1),
					Position = UDim2.new(0, 10, 0, CLOSED_H + SEARCH_H + 1),
					BackgroundColor3 = C.brd0,
					BackgroundTransparency = 0.6,
					BorderSizePixel = 0,
					ZIndex = 4,
					Visible = false
				}, container)

				local listScroll = new("ScrollingFrame", {
					Size = UDim2.new(1, 0, 1, -(CLOSED_H + SEARCH_H + 2)),
					Position = UDim2.new(0, 0, 0, CLOSED_H + SEARCH_H + 2),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ScrollBarThickness = 3,
					ScrollBarImageColor3 = ACCENT,
					ScrollBarImageTransparency = 0.45,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					CanvasSize = UDim2.new(0, 0, 0, 0),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ZIndex = 5
				}, container)
				regAc(listScroll, "ScrollBarImageColor3")
				vstack(2, listScroll)
				inset(4, 4, 8, 8, listScroll)

				local function computeListH(list)
					return math.min(#list * (OPTION_H + 2) + 8, MAX_LIST_H)
				end

				local optionButtons = {}

				local function refreshOptionVisual(opt)
					local btn = optionButtons[opt]
					if not btn or not btn.Parent then return end
					local isSel = selected[opt] == true
					local lbl = btn:FindFirstChildWhichIsA("TextLabel")
					local chk = btn:FindFirstChild("Checkmark")
					local str = btn:FindFirstChildWhichIsA("UIStroke")
					twHover(btn, 0.14, { BackgroundColor3 = isSel and C.acDim or C.bg3, BackgroundTransparency = isSel and 0 or 1 })
					if lbl then twHover(lbl, 0.14, { TextColor3 = isSel and ACCENT or C.textMid }) end
					if chk then twHover(chk, 0.14, { BackgroundColor3 = isSel and ACCENT or C.bg4, BackgroundTransparency = isSel and 0 or 0.1 }) end
					if str then str.Color = isSel and ACCENT or C.brd0; str.Thickness = isSel and 1 or 0 end
				end

				local function buildOptions(list)
					for _, ch in ipairs(listScroll:GetChildren()) do
						if ch:IsA("TextButton") then ch:Destroy() end
					end
					optionButtons = {}

					for _, opt in ipairs(list) do
						local isSel = selected[opt] == true
						local ob = new("TextButton", {
							Size = UDim2.new(1, 0, 0, OPTION_H),
							BackgroundColor3 = isSel and C.acDim or C.bg3,
							BackgroundTransparency = isSel and 0 or 1,
							Text = "",
							BorderSizePixel = 0,
							AutoButtonColor = false,
							ZIndex = 6
						}, listScroll)
						corner(6, ob)
						local obStr = outline(isSel and ACCENT or C.brd0, isSel and 1 or 0, ob)

						local chk = new("Frame", {
							Name = "Checkmark",
							Size = UDim2.new(0, 14, 0, 14),
							Position = UDim2.new(0, 8, 0.5, -7),
							BackgroundColor3 = isSel and ACCENT or C.bg4,
							BackgroundTransparency = isSel and 0 or 0.1,
							BorderSizePixel = 0,
							ZIndex = 7
						}, ob)
						corner(4, chk)
						outline(isSel and ACCENT or C.brd1, 1, chk)

						local checkMark = new("TextLabel", {
							Size = UDim2.new(1, 0, 1, 0),
							BackgroundTransparency = 1,
							Text = "✓",
							TextColor3 = C.bg0,
							Font = Enum.Font.GothamBold,
							TextSize = 9,
							TextXAlignment = Enum.TextXAlignment.Center,
							ZIndex = 8,
							Visible = isSel
						}, chk)

						new("TextLabel", {
							Size = UDim2.new(1, -36, 1, 0),
							Position = UDim2.new(0, 30, 0, 0),
							BackgroundTransparency = 1,
							Text = opt,
							TextColor3 = isSel and ACCENT or C.textMid,
							Font = Enum.Font.GothamSemibold,
							TextSize = 11,
							TextXAlignment = Enum.TextXAlignment.Left,
							ZIndex = 7
						}, ob)

						optionButtons[opt] = ob

						ob.MouseEnter:Connect(function()
							if not selected[opt] then
								twHover(ob, 0.1, { BackgroundTransparency = 0.75, BackgroundColor3 = C.bg4 })
								local lbl = ob:FindFirstChildWhichIsA("TextLabel")
								if lbl then twHover(lbl, 0.1, { TextColor3 = C.textHi }) end
							end
						end)
						ob.MouseLeave:Connect(function()
							if not selected[opt] then
								twHover(ob, 0.16, { BackgroundTransparency = 1 })
								local lbl = ob:FindFirstChildWhichIsA("TextLabel")
								if lbl then twHover(lbl, 0.16, { TextColor3 = C.textMid }) end
							end
						end)
						ob.MouseButton1Click:Connect(function()
							selected[opt] = not selected[opt] or nil
							checkMark.Visible = selected[opt] == true
							refreshOptionVisual(opt)
							selLbl.Text = buildLabel()
							saveAndFire()
						end)
					end
				end

				local function filterOptions(query)
					query = string.lower(string.match(query, "^%s*(.-)%s*$"))
					if query == "" then
						filtered = { table.unpack(options) }
					else
						filtered = {}
						for _, opt in ipairs(options) do
							if string.find(string.lower(opt), query, 1, true) then
								table.insert(filtered, opt)
							end
						end
					end
					buildOptions(filtered)
					if ddOpen then
						tw(container, 0.18, { Size = UDim2.new(1, 0, 0, CLOSED_H + SEARCH_H + 2 + computeListH(filtered)) }, Enum.EasingStyle.Quint)
					end
				end

				local function closeDD()
					ddOpen = false
					tw(container, 0.28, { Size = UDim2.new(1, 0, 0, CLOSED_H) })
					tw(chev, 0.2, { Rotation = 0 })
					tw(contStr, 0.22, { Color = C.brd0 })
					task.delay(0.25, function()
						if not ddOpen then divLine.Visible = false; searchDivLine.Visible = false end
					end)
				end

				local function openDD()
					ddOpen = true
					searchInput.Text = ""
					filtered = { table.unpack(options) }
					buildOptions(filtered)
					divLine.Visible = true
					searchDivLine.Visible = true
					twBack(container, 0.3, { Size = UDim2.new(1, 0, 0, CLOSED_H + SEARCH_H + 2 + computeListH(filtered)) })
					tw(chev, 0.2, { Rotation = 180 })
					tw(contStr, 0.2, { Color = ACCENT })
					task.delay(0.18, function()
						if ddOpen then task.defer(function() searchInput:CaptureFocus() end) end
					end)
				end

				searchInput:GetPropertyChangedSignal("Text"):Connect(function() filterOptions(searchInput.Text) end)
				searchInput.Focused:Connect(function() twHover(searchIconImg, 0.15, { ImageColor3 = ACCENT }) end)
				searchInput.FocusLost:Connect(function() twHover(searchIconImg, 0.2, { ImageColor3 = C.textLo }) end)

				buildOptions(options)

				local hit = new("TextButton", {
					Size = UDim2.new(1, 0, 0, CLOSED_H),
					BackgroundTransparency = 1,
					Text = "",
					BorderSizePixel = 0,
					ZIndex = 7
				}, container)
				hit.MouseButton1Click:Connect(function() if ddOpen then closeDD() else openDD() end end)
				hit.MouseEnter:Connect(function() if not ddOpen then twHover(container, 0.14, { BackgroundColor3 = C.bg3 }) end end)
				hit.MouseLeave:Connect(function() if not ddOpen then twHover(container, 0.2, { BackgroundColor3 = C.bg2 }) end end)

				if opts.Flag then
					flagHandlers[opts.Flag] = function(value)
						if type(value) == "table" then
							selected = {}
							for _, v in ipairs(value) do selected[v] = true end
							selLbl.Text = buildLabel()
							buildOptions(filtered)
						end
					end
				end

				table.insert(searchRegistry, { label = displayLabel, kind = "multidropdown", cb = nil, row = container, tabName = name })

				return {
					Get = function() return getSelected() end,
					Set = function(_, values)
						selected = {}
						if type(values) == "table" then
							for _, v in ipairs(values) do selected[v] = true end
						end
						selLbl.Text = buildLabel()
						buildOptions(filtered)
						if opts.Flag then FLAGS[opts.Flag] = getSelected(); saveConfig(CONFIG_FILE, FLAGS) end
						if cb then task.spawn(cb, getSelected()) end
					end,
					SetOptions = function(_, newOptions)
						options = newOptions
						filtered = { table.unpack(newOptions) }
						selected = {}
						selLbl.Text = buildLabel()
						buildOptions(filtered)
					end,
					GetSelected = function() return getSelected() end,
					Clear = function()
						selected = {}
						selLbl.Text = buildLabel()
						buildOptions(filtered)
						if opts.Flag then FLAGS[opts.Flag] = {}; saveConfig(CONFIG_FILE, FLAGS) end
						if cb then task.spawn(cb, {}) end
					end
				}
			end

			function SecObj:Input(text,placeholder,cb)
				div(); local r=mkRow(54); r.Parent=body
				new("TextLabel",{Name="L",Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,0,4),BackgroundTransparency=1,Text=string.upper(text),TextColor3=C.acMid,Font=Enum.Font.GothamBold,TextSize=8,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=4},r)
				local boxWrap=new("Frame",{Size=UDim2.new(1,0,0,28),Position=UDim2.new(0,0,0,21),BackgroundColor3=C.bg4,BorderSizePixel=0,ZIndex=4},r)
				corner(R.elem,boxWrap); local bStr=outline(C.brd0,1,boxWrap)
				local box=new("TextBox",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",PlaceholderText=placeholder or "",TextColor3=C.textHi,PlaceholderColor3=C.textLo,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,BorderSizePixel=0,ClearTextOnFocus=false,ZIndex=5},boxWrap)
				inset(0,0,10,10,box)
				box.Focused:Connect(function() tw(bStr,0.15,{Color=ACCENT,Thickness=1.5}); tw(boxWrap,0.15,{BackgroundColor3=C.acDim}) end)
				box.FocusLost:Connect(function(enter) tw(bStr,0.2,{Color=C.brd0,Thickness=1}); tw(boxWrap,0.2,{BackgroundColor3=C.bg4}); if cb then task.spawn(cb,box.Text,enter) end end)
				table.insert(searchRegistry,{label=text,kind="input",cb=nil,row=r,tabName=name})
				return {Get=function() return box.Text end, Set=function(_,v) box.Text=v end}
			end

			function SecObj:Keybind(text,default,cb)
				local kbIcon,kbLabel,kbLib=parseLabel(text); local displayLabel=kbIcon and kbLabel or text
				div(); local r=mkRow(40); r.Parent=body
				local binding=false; local armedAt=0; local keyData=keyDataFromDefault(default)
				if kbIcon then local kImg=mkIcon(r,kbIcon,14,C.textMid,4,kbLib); kImg.Position=UDim2.new(0,0,0.5,-7) end
				new("TextLabel",{Name="L",Size=UDim2.new(1,-90,1,0),Position=UDim2.new(0,kbIcon and 18 or 0,0,0),BackgroundTransparency=1,Text=displayLabel,TextColor3=C.textMid,Font=Enum.Font.GothamSemibold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=4},r)
				local keyPill=new("TextButton",{Size=UDim2.new(0,56,0,24),Position=UDim2.new(1,-56,0.5,-12),BackgroundColor3=C.bg4,Text=resolveKeyDisplay(keyData),TextColor3=ACCENT,Font=Enum.Font.GothamBold,TextSize=10,BorderSizePixel=0,ZIndex=4},r)
				corner(R.elem,keyPill); outline(C.brd1,1,keyPill); regAc(keyPill,"TextColor3")
				local clearBtn=new("TextButton",{Size=UDim2.new(0,18,0,18),Position=UDim2.new(1,-82,0.5,-9),BackgroundColor3=C.bg4,Text="×",TextColor3=C.textLo,Font=Enum.Font.GothamBold,TextSize=11,BorderSizePixel=0,ZIndex=4},r)
				corner(R.elem,clearBtn); outline(C.brd0,1,clearBtn)
				clearBtn.MouseEnter:Connect(function() tw(clearBtn,0.15,{BackgroundColor3=BASE.red,TextColor3=BASE.white}) end)
				clearBtn.MouseLeave:Connect(function() tw(clearBtn,0.2,{BackgroundColor3=C.bg4,TextColor3=C.textLo}) end)
				local function cancelBind()
					binding=false; keyPill.Text=resolveKeyDisplay(keyData); twHover(keyPill,0.2,{BackgroundColor3=C.bg4,TextColor3=ACCENT})
				end
				clearBtn.MouseButton1Click:Connect(function()
					if binding then cancelBind() end
					keyData=nil; keyPill.Text=resolveKeyDisplay(nil)
				end)
				keyPill.MouseButton1Click:Connect(function()
					if binding then return end
					binding=true; armedAt=os.clock(); keyPill.Text="..."; twHover(keyPill,0.15,{BackgroundColor3=C.acDim,TextColor3=C.textHi})
				end)
				keyPill.MouseButton2Click:Connect(function()
					if binding then cancelBind(); return end
					keyData=nil; keyPill.Text=resolveKeyDisplay(nil); twHover(keyPill,0.2,{BackgroundColor3=C.bg4,TextColor3=ACCENT})
				end)
				UserInputService.InputBegan:Connect(function(i,gp)
					if binding then
						if os.clock()-armedAt<0.15 then return end
						if i.UserInputType==Enum.UserInputType.Keyboard and i.KeyCode==Enum.KeyCode.Escape then cancelBind(); return end
						local name2,isMouse=nil,false
						if i.UserInputType==Enum.UserInputType.Keyboard and i.KeyCode~=Enum.KeyCode.Unknown then name2=tostring(i.KeyCode):gsub("Enum%.KeyCode%.","")
						elseif MB_NAMES[i.UserInputType] then name2=MB_NAMES[i.UserInputType]; isMouse=true end
						if name2 then
							binding=false; keyData=isMouse and {mouse=true,inputType=i.UserInputType,name=name2} or {mouse=false,keyCode=i.KeyCode,name=name2}
							keyPill.Text=name2; twHover(keyPill,0.22,{BackgroundColor3=C.bg4,TextColor3=ACCENT})
						end
					elseif keyData and not gp then
						local triggered=false
						if keyData.mouse then if i.UserInputType==keyData.inputType then triggered=true end
						else if i.UserInputType==Enum.UserInputType.Keyboard and i.KeyCode==keyData.keyCode then triggered=true end end
						if triggered and cb then task.spawn(cb,keyData) end
					end
				end)
				table.insert(searchRegistry,{label=displayLabel,kind="keybind",cb=nil,row=r,tabName=name})
				return {
					Get=function() return keyData end,
					Set=function(_,v)
						keyData=v==nil and nil or (keyDataFromDefault(v) or keyDataFromDefault(default))
						keyPill.Text=resolveKeyDisplay(keyData)
					end
				}
			end

			function SecObj:Paragraph(header,bodyTxt)
				div(); rowN=rowN+1
				local pw=new("Frame",{Name="P"..rowN,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=rowN*100},body)
				inset(10,10,14,14,pw); vstack(5,pw)
				local headerLbl=nil
				if header and header~="" then headerLbl=new("TextLabel",{Size=UDim2.new(1,0,0,15),BackgroundTransparency=1,Text=header,TextColor3=C.textMid,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=0,ZIndex=4},pw) end
				local bodyLbl=new("TextLabel",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Text=bodyTxt or "",TextColor3=C.textLo,Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=1,ZIndex=4},pw)
				table.insert(searchRegistry,{label=header and header or (bodyTxt or ""),kind="paragraph",cb=nil,row=pw,tabName=name})
				return {
					Update=function(_,nh,nb)
						if headerLbl then headerLbl.Text=nh or "" elseif nh and nh~="" then headerLbl=new("TextLabel",{Size=UDim2.new(1,0,0,15),BackgroundTransparency=1,Text=nh,TextColor3=C.textMid,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=0,ZIndex=4},pw) end
						bodyLbl.Text=nb or ""
					end,
					SetHeader=function(_,v) if headerLbl then headerLbl.Text=v end end,
					SetBody=function(_,v) bodyLbl.Text=v end
				}
			end

			function SecObj:Separator()
				rowN=rowN+1
				local sep=new("Frame",{Name="Sep"..rowN,Size=UDim2.new(1,0,0,1),BackgroundColor3=C.brd0,BackgroundTransparency=0.52,BorderSizePixel=0,LayoutOrder=rowN*100,Parent=body})
				inset(0,0,8,8,sep)
			end

			return SecObj
		end

		return TabObj
	end

	function WinObj:Destroy()
		pulsing=false
		if rainbowConn then rainbowConn:Disconnect(); rainbowConn=nil end
		tw(uiScale,0.22,{Scale=(getgenv().Scale or 1)*0.88})
		tw(win,0.28,{Size=UDim2.new(0,0,0,0),Position=UDim2.new(0.5,0,0.5,0)})
		tw(shHolder,0.28,{Size=UDim2.new(0,0,0,0),Position=UDim2.new(0.5,0,0.5,0)})
		task.delay(0.3,function() gui:Destroy() end)
	end

	local notifStack={}; local NW=310; local NH=90; local NG=10; local NM=20
	local function nY(idx) return NM+(idx-1)*(NH+NG) end
	local function nPos(idx,side,overrideX)
		local xScale=side=="left" and 0 or 1; local defaultX=side=="left" and NM or -NM
		return UDim2.new(xScale,overrideX or defaultX,1,-(nY(idx)+NH))
	end

	function WinObj:Notify(title,body,duration,side)
		local ValenceUI = loadstring(game:HttpGet("https://cdn.valencea.xyz/Modules/ValenceUI.lua"))()
		ValenceUI.Notify({
			Title    = title,
			Body     = body,
			Duration = duration,
			Side     = side
		})
	end

	return WinObj
end

return ArtemisUI