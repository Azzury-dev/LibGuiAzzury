--[[
	GUI Library (style "navigateur")

	local Library = loadstring(readfile("gui_library.lua"))()
	local Window  = Library:CreateWindow({
		Title = "Butter", Icon = "6035145364",       -- Icon optionnel (pastille de la fenêtre)
		Theme = "Default",                           -- preset de départ
		Url = "https://github.com/Butter",           -- texte de la barre d'adresse (optionnel)
		ToggleKey = Enum.KeyCode.RightShift,
		Home = true,                                 -- page d'accueil avec grille d'onglets (défaut: true)
	})
	local Tab     = Window:Tab("Player", "6034287594")   -- l'icône sert pour la grille de l'accueil
	local Section = Tab:Section("Movement", true)

	Section:Label(text)                                          -> {SetText}
	Section:Button(text, callback)
	Section:Toggle(text, flag, default, callback)                -> {Set, Get}
	Section:Slider(text, flag, default, min, max, precise, cb)   -> {Set, Get}
	Section:Textbox(text, flag, default, callback)               -> {Set, Get}
	Section:Keybind(text, default, callback)                     -> {Set, Get}
	Section:Dropdown(text, flag, options, callback)              -> {Set, Get, SetOptions, AddOption, RemoveOption}
	Tab:ThemeSection(title)                                      -> section avec le sélecteur de thème

	Navigation : clique une icône de l'accueil pour ouvrir un onglet, clique la barre d'adresse pour revenir.
	Window:SetStatus("Idle")   Window:Home()   Tab:Open()   Window:Destroy()

	Thèmes : Library:SetTheme("Rose")   Library:RegisterTheme(name, {Accent = Color3...})   Library.Themes
	Notifs : Library:Notify(title, content, duration, "info"|"success"|"warn"|"error")
	Config : Library:SaveConfig(name) / Library:LoadConfig(name)     Library:Destroy()

	Les callbacks ne sont appelés que lors d'un changement (pas à l'initialisation) :
	lis Library.Flags[flag] pour la valeur de départ. Set(valeur, true) change sans appeler le callback.
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local GUI_NAME = "RevampLibraryUI"

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

local Library = {
	Flags = {},
	Options = {},
	CurrentTheme = "Default",
	Theme = {},
	Themes = {
		Default = {
			Background = rgb(28, 28, 32), Surface = rgb(36, 36, 41), Card = rgb(43, 43, 49),
			Element = rgb(52, 52, 59), Hover = rgb(64, 64, 73), Input = rgb(24, 24, 28),
			Accent = rgb(124, 178, 240), Text = rgb(236, 236, 242), SubText = rgb(148, 148, 160), Stroke = rgb(56, 56, 64),
		},
		Midnight = {
			Background = rgb(12, 13, 24), Surface = rgb(18, 20, 36), Card = rgb(25, 28, 48),
			Element = rgb(34, 38, 64), Hover = rgb(46, 51, 84), Input = rgb(9, 10, 18),
			Accent = rgb(140, 120, 255), Text = rgb(232, 234, 250), SubText = rgb(135, 140, 175), Stroke = rgb(40, 44, 72),
		},
		Rose = {
			Background = rgb(30, 22, 27), Surface = rgb(39, 28, 35), Card = rgb(48, 35, 43),
			Element = rgb(60, 44, 54), Hover = rgb(76, 56, 68), Input = rgb(24, 17, 21),
			Accent = rgb(255, 110, 150), Text = rgb(248, 236, 241), SubText = rgb(170, 145, 157), Stroke = rgb(70, 52, 62),
		},
		Emerald = {
			Background = rgb(18, 26, 23), Surface = rgb(23, 34, 30), Card = rgb(29, 43, 38),
			Element = rgb(38, 56, 49), Hover = rgb(49, 72, 63), Input = rgb(14, 20, 18),
			Accent = rgb(80, 220, 150), Text = rgb(232, 248, 240), SubText = rgb(140, 170, 155), Stroke = rgb(44, 66, 58),
		},
		Sunset = {
			Background = rgb(30, 24, 22), Surface = rgb(40, 31, 28), Card = rgb(50, 39, 35),
			Element = rgb(63, 49, 44), Hover = rgb(80, 63, 56), Input = rgb(24, 19, 17),
			Accent = rgb(255, 150, 70), Text = rgb(250, 240, 232), SubText = rgb(175, 155, 142), Stroke = rgb(72, 56, 50),
		},
		Ocean = {
			Background = rgb(16, 26, 32), Surface = rgb(21, 35, 43), Card = rgb(27, 45, 55),
			Element = rgb(36, 60, 73), Hover = rgb(47, 78, 95), Input = rgb(12, 20, 25),
			Accent = rgb(70, 200, 220), Text = rgb(230, 246, 250), SubText = rgb(135, 168, 180), Stroke = rgb(40, 66, 78),
		},
		Dracula = {
			Background = rgb(33, 34, 44), Surface = rgb(40, 42, 54), Card = rgb(48, 50, 64),
			Element = rgb(58, 60, 78), Hover = rgb(72, 75, 96), Input = rgb(27, 28, 37),
			Accent = rgb(189, 147, 249), Text = rgb(248, 248, 242), SubText = rgb(150, 155, 185), Stroke = rgb(68, 71, 90),
		},
		Mono = {
			Background = rgb(20, 20, 20), Surface = rgb(28, 28, 28), Card = rgb(36, 36, 36),
			Element = rgb(46, 46, 46), Hover = rgb(60, 60, 60), Input = rgb(14, 14, 14),
			Accent = rgb(235, 235, 235), Text = rgb(240, 240, 240), SubText = rgb(140, 140, 140), Stroke = rgb(56, 56, 56),
		},
		Light = {
			Background = rgb(236, 238, 243), Surface = rgb(246, 247, 250), Card = rgb(255, 255, 255),
			Element = rgb(238, 240, 246), Hover = rgb(224, 228, 238), Input = rgb(228, 231, 239),
			Accent = rgb(60, 110, 235), Text = rgb(28, 30, 38), SubText = rgb(105, 110, 125), Stroke = rgb(214, 218, 228),
		},
	},
}

local Theme = Library.Theme
for k, v in pairs(Library.Themes.Default) do Theme[k] = v end

local NOTIFY_COLORS = {
	success = rgb(80, 200, 120),
	warn = rgb(240, 180, 60),
	error = rgb(235, 80, 80),
}

local noop = function() end
local Y = Enum.AutomaticSize.Y
local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_MED = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local connections = {}
local windows = {}
local registry = {} -- [instance] = {Propriété = "CléDeThème" | function}
local gui, notifyHolder
local notifyOrder = 0

-- ## Helpers ## --

local function resolve(spec)
	if type(spec) == "function" then return spec() end
	return Theme[spec]
end

-- new(class, props, children) ; props.Theme = {Prop = "CléDeThème" | fonction} lie la propriété au thème
local function new(class, props, children)
	local inst = Instance.new(class)
	local parent, themed
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		elseif k == "Theme" then
			themed = v
		else
			inst[k] = v
		end
	end
	if themed then
		registry[inst] = themed
		for prop, spec in pairs(themed) do inst[prop] = resolve(spec) end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	inst.Parent = parent
	return inst
end

local function refresh(inst)
	local themed = registry[inst]
	if themed then
		for prop, spec in pairs(themed) do inst[prop] = resolve(spec) end
	end
end

local function applyTheme()
	for inst, themed in pairs(registry) do
		if not (gui and inst:IsDescendantOf(gui)) then
			registry[inst] = nil
		else
			local goal = {}
			for prop, spec in pairs(themed) do goal[prop] = resolve(spec) end
			TweenService:Create(inst, TWEEN_MED, goal):Play()
		end
	end
end

local function tween(obj, info, props)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function corner(r)
	return new("UICorner", {CornerRadius = UDim.new(0, r)})
end

local function stroke(key, thickness)
	return new("UIStroke", {
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Theme = {Color = key or "Stroke"},
	})
end

local function padding(top, right, bottom, left)
	return new("UIPadding", {
		PaddingTop = UDim.new(0, top), PaddingRight = UDim.new(0, right),
		PaddingBottom = UDim.new(0, bottom), PaddingLeft = UDim.new(0, left),
	})
end

local function list(gap)
	return new("UIListLayout", {Padding = UDim.new(0, gap or 0), SortOrder = Enum.SortOrder.LayoutOrder})
end

-- props.Color = clé de thème (ou fonction) pour la couleur du texte
local function label(props)
	props.BackgroundTransparency = 1
	props.Font = props.Font or Enum.Font.GothamMedium
	props.TextSize = props.TextSize or 14
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	props.Theme = {TextColor3 = props.Color or "Text"}
	props.Color = nil
	return new("TextLabel", props)
end

local function connect(signal, fn, bucket)
	local c = signal:Connect(fn)
	table.insert(bucket or connections, c)
	return c
end

local function hover(button, base, over)
	button.MouseEnter:Connect(function() tween(button, TWEEN_FAST, {BackgroundColor3 = resolve(over)}) end)
	button.MouseLeave:Connect(function() tween(button, TWEEN_FAST, {BackgroundColor3 = resolve(base)}) end)
end

local function isPointer(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

local function asImage(icon)
	if not icon then return nil end
	icon = tostring(icon)
	if icon:find("rbxasset") or icon:find("http") then return icon end
	return "rbxassetid://" .. icon
end

local function fmt(v)
	return tostring(math.floor(v * 100 + 0.5) / 100)
end

local function row(parent, height)
	return new("Frame", {
		Size = UDim2.new(1, 0, 0, height or 36),
		Theme = {BackgroundColor3 = "Element"},
		Parent = parent,
	}, {corner(6)})
end

-- petite loupe dessinée en UI (pas besoin d'asset)
local function searchIcon(parent)
	local holder = new("Frame", {
		Size = UDim2.fromOffset(14, 14), Position = UDim2.new(0, 11, 0.5, -7), BackgroundTransparency = 1, Parent = parent,
	})
	new("Frame", {Size = UDim2.fromOffset(9, 9), BackgroundTransparency = 1, Parent = holder}, {
		corner(5), new("UIStroke", {Thickness = 1.5, Theme = {Color = "Accent"}}),
	})
	new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(11, 11), Size = UDim2.fromOffset(5, 2),
		Rotation = 45, BorderSizePixel = 0, Theme = {BackgroundColor3 = "Accent"}, Parent = holder,
	})
	return holder
end

-- ## GUI host ## --

local function mount(screenGui)
	if syn and syn.protect_gui then pcall(syn.protect_gui, screenGui) end
	local getters = {
		function() return gethui and gethui() end,
		function() return CoreGui end,
		function() return Players.LocalPlayer:WaitForChild("PlayerGui", 5) end,
	}
	for _, get in ipairs(getters) do
		local ok, host = pcall(get)
		if ok and host then
			local old = host:FindFirstChild(GUI_NAME)
			if old then old:Destroy() end
			if pcall(function() screenGui.Parent = host end) and screenGui.Parent == host then
				return true
			end
		end
	end
	return false
end

local function ensureGui()
	if gui and gui.Parent then return gui end
	gui = new("ScreenGui", {
		Name = GUI_NAME,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		DisplayOrder = 999,
	})
	mount(gui)

	-- colonne de notifications en haut à droite : les nouvelles s'empilent vers le bas
	notifyHolder = new("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 16),
		Size = UDim2.new(0, 300, 1, -32),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}),
	})
	return gui
end

-- ## Thèmes ## --

function Library:RegisterTheme(name, colors)
	local base = self.Themes.Default
	local theme = {}
	for k, v in pairs(base) do theme[k] = colors[k] or v end
	self.Themes[name] = theme
end

function Library:SetTheme(nameOrColors)
	local colors = nameOrColors
	if type(nameOrColors) == "string" then
		colors = self.Themes[nameOrColors]
		if not colors then return false end
		self.CurrentTheme = nameOrColors
	else
		self.CurrentTheme = "Custom"
	end
	for k, v in pairs(colors) do Theme[k] = v end
	if gui then applyTheme() end
	return true
end

function Library:GetThemeNames()
	local names = {}
	for name in pairs(self.Themes) do table.insert(names, name) end
	table.sort(names)
	return names
end

-- ## Notifications ## --

function Library:Notify(title, content, duration, kind)
	if type(title) == "table" then
		local o = title
		title, content, duration, kind = o.Title, o.Content, o.Duration, o.Type
	end
	ensureGui()
	duration = duration or 4
	notifyOrder += 1
	local accent = NOTIFY_COLORS[kind] or Theme.Accent
	local OFFSET = UDim2.new(0, 60, 0, 0)

	local wrapper = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Y, BackgroundTransparency = 1,
		LayoutOrder = notifyOrder, Parent = notifyHolder,
	})
	local cardStroke = new("UIStroke", {Color = Theme.Stroke, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
	local card = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Y, Position = OFFSET,
		BackgroundColor3 = Theme.Card, BackgroundTransparency = 1, Parent = wrapper,
	}, {corner(8), cardStroke})
	local content_ = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Y, BackgroundTransparency = 1, Parent = card,
	}, {padding(10, 12, 14, 16), list(2)})
	local bar = new("Frame", {
		Size = UDim2.new(0, 3, 1, -16), Position = UDim2.new(0, 6, 0, 8),
		BackgroundColor3 = accent, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = card,
	}, {corner(2)})
	local timer = new("Frame", {
		Size = UDim2.new(1, -24, 0, 2), Position = UDim2.new(0, 12, 1, -6),
		BackgroundColor3 = accent, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = card,
	}, {corner(1)})
	local titleLabel = new("TextLabel", {
		Text = tostring(title or "Notification"), Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, TextTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 1, Parent = content_,
	})
	local body = new("TextLabel", {
		Text = tostring(content or ""), Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, BackgroundTransparency = 1, TextTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Y, LayoutOrder = 2, Parent = content_,
	})
	local click = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Parent = card})

	local function fade(to)
		tween(card, TWEEN_MED, {BackgroundTransparency = to})
		tween(cardStroke, TWEEN_MED, {Transparency = to})
		tween(bar, TWEEN_MED, {BackgroundTransparency = to})
		tween(timer, TWEEN_MED, {BackgroundTransparency = to == 0 and 0.35 or 1})
		tween(titleLabel, TWEEN_MED, {TextTransparency = to})
		tween(body, TWEEN_MED, {TextTransparency = to})
	end

	local closed = false
	local function dismiss()
		if closed then return end
		closed = true
		fade(1)
		tween(card, TWEEN_MED, {Position = OFFSET})
		task.wait(0.25)
		if not wrapper.Parent then return end
		-- referme la place occupée pour que les notifications du dessous remontent en douceur
		wrapper.AutomaticSize = Enum.AutomaticSize.None
		wrapper.Size = UDim2.new(1, 0, 0, wrapper.AbsoluteSize.Y)
		wrapper.ClipsDescendants = true
		tween(wrapper, TWEEN_FAST, {Size = UDim2.new(1, 0, 0, 0)}).Completed:Wait()
		wrapper:Destroy()
	end

	fade(0)
	tween(card, TWEEN_MED, {Position = UDim2.new(0, 0, 0, 0)})
	tween(timer, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)})
	click.MouseButton1Click:Connect(function() task.spawn(dismiss) end)
	task.delay(duration, dismiss)
end

-- ## Config ## --

function Library:SaveConfig(name)
	local data = {}
	for flag, value in pairs(self.Flags) do
		local t = type(value)
		if t == "boolean" or t == "number" or t == "string" then data[flag] = value end
	end
	return pcall(function() writefile((name or "config") .. ".json", HttpService:JSONEncode(data)) end)
end

function Library:LoadConfig(name)
	local ok, data = pcall(function()
		return HttpService:JSONDecode(readfile((name or "config") .. ".json"))
	end)
	if not ok or type(data) ~= "table" then return false end
	for flag, value in pairs(data) do
		local option = self.Options[flag]
		if option then option.Set(value) end
	end
	return true
end

function Library:Destroy()
	for _, w in ipairs(windows) do w:Destroy() end
	for _, c in ipairs(connections) do c:Disconnect() end
	table.clear(connections)
	table.clear(windows)
	table.clear(registry)
	table.clear(self.Flags)
	table.clear(self.Options)
	if gui then gui:Destroy() end
	gui, notifyHolder = nil, nil
end

-- ## Window ## --

function Library:CreateWindow(opts)
	if type(opts) == "string" then opts = {Title = opts} end
	opts = opts or {}
	if opts.Theme then self:SetTheme(opts.Theme) end
	ensureGui()

	local title = tostring(opts.Title or "Window")
	local width, height = (opts.Size and opts.Size.X) or 600, (opts.Size and opts.Size.Y) or 400
	local baseUrl = opts.Url or ("https://github.com/" .. (title:gsub("%s+", "-")))
	local TOP_H, BAR_H, STATUS_H = 30, 30, 18

	local window = {ToggleKey = opts.ToggleKey or Enum.KeyCode.RightShift}
	local ownConnections = {}
	local alive = true
	local minimized = false
	local current, homeEntry, homeGrid
	local statusText = "Idle"

	local main = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width, height),
		ClipsDescendants = true,
		Theme = {BackgroundColor3 = "Background"},
		Parent = gui,
	}, {corner(12), stroke()})
	local scale = new("UIScale", {Parent = main})

	local function updateScale()
		local vp = gui.AbsoluteSize
		if vp.X == 0 or vp.Y == 0 then return end
		scale.Scale = math.min(1, vp.X / (width + 24), vp.Y / (height + 24))
	end
	updateScale()
	connect(gui:GetPropertyChangedSignal("AbsoluteSize"), updateScale, ownConnections)

	-- Ligne du haut : pastille de la fenêtre + boutons
	local topbar = new("Frame", {
		Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, TOP_H), BackgroundTransparency = 1, Parent = main,
	})
	local pill = new("TextButton", {
		Size = UDim2.new(0, 150, 1, 0), AutoButtonColor = false, Text = "",
		Theme = {BackgroundColor3 = function() return current == homeEntry and Theme.Element or Theme.Card end},
		Parent = topbar,
	}, {corner(8)})
	local pillImage = asImage(opts.Icon)
	if pillImage then
		new("ImageLabel", {
			Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, 10, 0.5, -8), BackgroundTransparency = 1,
			Image = pillImage, Theme = {ImageColor3 = "Text"}, Parent = pill,
		})
	else
		new("Frame", {
			Size = UDim2.fromOffset(10, 10), Position = UDim2.new(0, 12, 0.5, -5),
			Theme = {BackgroundColor3 = "Accent"}, Parent = pill,
		}, {corner(5)})
	end
	label({
		Text = title, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(34, 0), Size = UDim2.new(1, -42, 1, 0), Parent = pill,
	})

	local function topButton(text, offset, hoverColor)
		local btn = new("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, offset, 0.5, 0), Size = UDim2.fromOffset(26, 26),
			BackgroundTransparency = 1, AutoButtonColor = false, Text = text, Font = Enum.Font.GothamBold, TextSize = 16,
			Theme = {TextColor3 = "SubText", BackgroundColor3 = "Hover"}, Parent = topbar,
		}, {corner(6)})
		btn.MouseEnter:Connect(function()
			if hoverColor then btn.BackgroundColor3 = hoverColor end
			tween(btn, TWEEN_FAST, {BackgroundTransparency = 0, TextColor3 = Theme.Text})
		end)
		btn.MouseLeave:Connect(function()
			tween(btn, TWEEN_FAST, {BackgroundTransparency = 1, TextColor3 = Theme.SubText})
		end)
		return btn
	end
	local closeBtn = topButton("x", 0, rgb(220, 70, 70))
	local minBtn = topButton("-", -30, nil)

	-- Barre des onglets ouverts (à droite de la pastille)
	local PILL_W = 150
	local tabsStrip = new("ScrollingFrame", {
		Position = UDim2.fromOffset(PILL_W + 8, 0), Size = UDim2.new(1, -(PILL_W + 8 + 64), 1, 0),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.X,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X, Parent = topbar,
	}, {new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})})

	-- Barre d'adresse (cliquer = retour à l'accueil)
	local address = new("TextButton", {
		Position = UDim2.fromOffset(8, 8 + TOP_H + 8), Size = UDim2.new(1, -16, 0, BAR_H),
		AutoButtonColor = false, Text = "", Theme = {BackgroundColor3 = "Input"}, Parent = main,
	}, {corner(8), stroke()})
	local searchHolder = searchIcon(address)
	local backLabel = label({
		Text = "<", Font = Enum.Font.GothamBold, TextSize = 16, Color = "Accent", TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.new(0, 8, 0, 0), Size = UDim2.fromOffset(20, BAR_H), Visible = false, Parent = address,
	})
	local urlLabel = label({
		Text = baseUrl .. "/home", TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(34, 0), Size = UDim2.new(1, -44, 1, 0), Parent = address,
	})

	-- Zone de contenu
	local panelTop = 8 + TOP_H + 8 + BAR_H + 8
	local panel = new("Frame", {
		Position = UDim2.fromOffset(8, panelTop), Size = UDim2.new(1, -16, 1, -(panelTop + STATUS_H + 10)),
		ClipsDescendants = true, Theme = {BackgroundColor3 = "Surface"}, Parent = main,
	}, {corner(10), stroke()})

	-- Barre de statut
	local statusBar = new("Frame", {
		Position = UDim2.new(0, 14, 1, -(STATUS_H + 6)), Size = UDim2.new(1, -28, 0, STATUS_H),
		BackgroundTransparency = 1, Parent = main,
	}, {new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder})})
	label({
		Text = "Status", TextSize = 12, Color = "Accent", Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 1, Parent = statusBar,
	})
	local statusValue = label({
		Text = " | " .. statusText, TextSize = 12, Color = "SubText", Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 2, Parent = statusBar,
	})

	function window:SetStatus(text)
		statusText = tostring(text)
		statusValue.Text = " | " .. statusText
	end

	-- Dragging (souris + tactile) depuis la ligne du haut
	local dragInput, dragStart, startPos
	local function beginDrag(input)
		if not isPointer(input) then return end
		dragInput, dragStart, startPos = input, input.Position, main.Position
		local ender
		ender = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				if dragInput == input then dragInput = nil end
				ender:Disconnect()
			end
		end)
	end
	topbar.InputBegan:Connect(beginDrag)
	tabsStrip.InputBegan:Connect(beginDrag)
	connect(UserInputService.InputChanged, function(input)
		if not dragInput or not isMove(input) then return end
		local d = (input.Position - dragStart) / scale.Scale
		main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end, ownConnections)

	-- Visibilité / minimisation / fermeture
	connect(UserInputService.InputBegan, function(input, processed)
		if not processed and input.KeyCode == window.ToggleKey then main.Visible = not main.Visible end
	end, ownConnections)

	local collapsedHeight = 8 + TOP_H + 8
	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		if minimized then
			tween(main, TWEEN_MED, {Size = UDim2.fromOffset(width, collapsedHeight)})
		else
			tween(main, TWEEN_MED, {Size = UDim2.fromOffset(width, height)})
		end
	end)

	function window:Destroy()
		alive = false
		for _, c in ipairs(ownConnections) do c:Disconnect() end
		table.clear(ownConnections)
		main:Destroy()
	end
	closeBtn.MouseButton1Click:Connect(function() window:Destroy() end)

	function window:SetToggleKey(key)
		self.ToggleKey = key
	end

	-- ## Navigation ## --

	local entries = {} -- onglets créés ; entry.chip existe tant que l'onglet est ouvert

	local function show(entry)
		if current then current.page.Visible = false end
		current = entry
		entry.page.Visible = true
		urlLabel.Text = baseUrl .. "/" .. entry.path
		local onHome = entry == homeEntry
		searchHolder.Visible = onHome
		backLabel.Visible = not onHome
		-- met à jour les couleurs de la pastille et des onglets (actif / inactif)
		refresh(pill)
		for _, e in ipairs(entries) do
			if e.chip then
				refresh(e.chip)
				refresh(e.chipLabel)
			end
		end
	end

	function window:Home()
		if homeEntry then show(homeEntry) end
	end

	function window:GetOpenTabs()
		local names = {}
		for _, e in ipairs(entries) do
			if e.chip then table.insert(names, e.name) end
		end
		return names
	end
	address.MouseButton1Click:Connect(function() window:Home() end)
	pill.MouseButton1Click:Connect(function() window:Home() end)

	local chipOrder = 0
	local closable = opts.Home ~= false -- sans accueil, impossible de rouvrir un onglet fermé

	local function closeTab(entry)
		if not entry.chip then return end
		registry[entry.chip] = nil
		registry[entry.chipLabel] = nil
		entry.chip:Destroy()
		entry.chip, entry.chipLabel = nil, nil
		if current ~= entry then return end
		entry.page.Visible = false
		current = nil
		-- retourne à l'accueil, sinon au dernier onglet encore ouvert
		if homeEntry then
			show(homeEntry)
			return
		end
		for i = #entries, 1, -1 do
			if entries[i].chip then
				show(entries[i])
				return
			end
		end
	end

	-- Ouvre l'onglet : si déjà ouvert, on y va simplement (jamais de doublon)
	local function openTab(entry, silent)
		if not entry.chip then
			chipOrder += 1
			local chip = new("TextButton", {
				Size = UDim2.new(0, 116, 0, TOP_H), AutoButtonColor = false, Text = "", LayoutOrder = chipOrder,
				Theme = {BackgroundColor3 = function() return current == entry and Theme.Element or Theme.Card end},
				Parent = tabsStrip,
			}, {corner(8)})
			entry.chip = chip
			entry.chipLabel = label({
				Text = entry.name, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd,
				Color = function() return current == entry and Theme.Text or Theme.SubText end,
				Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, closable and -34 or -16, 1, 0), Parent = chip,
			})
			if closable then
				local x = new("TextButton", {
					AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(18, 18),
					BackgroundTransparency = 1, Text = "x", Font = Enum.Font.GothamBold, TextSize = 12,
					Theme = {TextColor3 = "SubText"}, Parent = chip,
				}, {corner(5)})
				x.MouseButton1Click:Connect(function() closeTab(entry) end)
			end
			chip.MouseEnter:Connect(function()
				if current ~= entry then tween(chip, TWEEN_FAST, {BackgroundColor3 = Theme.Hover}) end
			end)
			chip.MouseLeave:Connect(function() tween(chip, TWEEN_FAST, {BackgroundColor3 = resolve(registry[chip].BackgroundColor3)}) end)
			chip.MouseButton1Click:Connect(function() show(entry) end)
		end
		if not silent then show(entry) end
	end

	local function newPage()
		return new("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
			CanvasSize = UDim2.new(), AutomaticCanvasSize = Y, Visible = false,
			Theme = {ScrollBarImageColor3 = "Stroke"}, Parent = panel,
		}, {padding(12, 12, 12, 12), list(10)})
	end

	-- Page d'accueil : carte de bienvenue + grille des onglets
	if opts.Home ~= false then
		homeEntry = {page = newPage(), path = "home"}
		local lp = Players.LocalPlayer
		local displayName = lp and lp.DisplayName or "Player"
		local userName = lp and lp.Name or "player"

		local welcome = new("Frame", {
			Size = UDim2.new(1, 0, 0, 100), LayoutOrder = 1, Theme = {BackgroundColor3 = "Card"}, Parent = homeEntry.page,
		}, {corner(10)})
		local avatar = new("ImageLabel", {
			Position = UDim2.fromOffset(16, 18), Size = UDim2.fromOffset(64, 64), BackgroundTransparency = 0,
			Theme = {BackgroundColor3 = "Element"}, Parent = welcome,
		}, {corner(32)})
		label({
			Text = "Welcome, <b>" .. displayName .. "</b>", RichText = true, TextSize = 26, Font = Enum.Font.Gotham,
			Color = "Accent", TextTruncate = Enum.TextTruncate.AtEnd,
			Position = UDim2.fromOffset(94, 12), Size = UDim2.new(1, -106, 0, 34), Parent = welcome,
		})
		label({
			Text = "@" .. userName, TextSize = 13, Color = "Accent", TextTransparency = 0.2,
			Position = UDim2.fromOffset(94, 46), Size = UDim2.new(1, -106, 0, 18), Parent = welcome,
		})
		local clock = label({
			Text = os.date("%H:%M"), TextSize = 13, Color = "SubText",
			Position = UDim2.fromOffset(94, 66), Size = UDim2.new(1, -106, 0, 18), Parent = welcome,
		})
		task.spawn(function()
			while alive do
				clock.Text = os.date("%H:%M")
				task.wait(5)
			end
		end)
		if lp then
			task.spawn(function()
				local ok, img = pcall(function()
					return Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
				end)
				if ok and alive then avatar.Image = img end
			end)
		end

		homeGrid = new("Frame", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Y, BackgroundTransparency = 1, LayoutOrder = 2, Parent = homeEntry.page,
		}, {
			new("UIGridLayout", {
				CellSize = UDim2.fromOffset(54, 54), CellPadding = UDim2.fromOffset(10, 10),
				HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			padding(6, 0, 0, 0),
		})
		show(homeEntry)
	end

	local function addTile(entry, name, image)
		local tile = new("TextButton", {
			AutoButtonColor = false, Text = "", Theme = {BackgroundColor3 = "Element"}, Parent = homeGrid,
		}, {corner(8)})
		if image then
			new("ImageLabel", {
				Size = UDim2.fromOffset(26, 26), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
				BackgroundTransparency = 1, Image = image, Theme = {ImageColor3 = "Text"}, Parent = tile,
			})
		else
			label({
				Text = name:sub(1, 1):upper(), Font = Enum.Font.GothamBold, TextSize = 22,
				TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = tile,
			})
		end
		hover(tile, "Element", "Hover")
		tile.MouseEnter:Connect(function() statusValue.Text = " | Open " .. name end)
		tile.MouseLeave:Connect(function() statusValue.Text = " | " .. statusText end)
		tile.MouseButton1Click:Connect(function() openTab(entry) end)
	end

	-- ## Tabs ## --

	function window:Tab(name, icon)
		local tab = {}
		local entry = {page = newPage(), name = name, path = (name:lower():gsub("%s+", "-"))}
		tab.page = entry.page
		table.insert(entries, entry)

		function tab:Open() openTab(entry) end
		function tab:Close() closeTab(entry) end
		function tab:IsOpen() return entry.chip ~= nil end

		if homeGrid then
			addTile(entry, name, asImage(icon))
		else
			-- sans accueil : chaque onglet est ouvert d'office, le premier est affiché
			openTab(entry, current ~= nil)
		end

		-- ## Sections ## --

		function tab:Section(sectionTitle, open)
			local section = {}
			local opened = open ~= false

			local frame = new("Frame", {
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Y, Theme = {BackgroundColor3 = "Card"}, Parent = entry.page,
			}, {corner(8), list(0)})
			local header = new("TextButton", {
				Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Text = "", LayoutOrder = 1, Parent = frame,
			})
			label({
				Text = sectionTitle, Font = Enum.Font.GothamBold, TextSize = 14,
				Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -40, 1, 0), Parent = header,
			})
			local arrow = label({
				Text = opened and "v" or ">", Color = "SubText", Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Center,
				Position = UDim2.new(1, -30, 0, 0), Size = UDim2.fromOffset(20, 34), Parent = header,
			})
			local content = new("Frame", {
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Y, BackgroundTransparency = 1,
				Visible = opened, LayoutOrder = 2, Parent = frame,
			}, {padding(0, 8, 8, 8), list(6)})

			header.MouseButton1Click:Connect(function()
				opened = not opened
				content.Visible = opened
				arrow.Text = opened and "v" or ">"
			end)

			function section:Label(text)
				local obj = {}
				local l = label({
					Text = text, Color = "SubText", TextSize = 13, TextWrapped = true,
					Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Y, Parent = content,
				})
				new("UIPadding", {PaddingLeft = UDim.new(0, 4), Parent = l})
				function obj.SetText(t) l.Text = tostring(t) end
				obj.Instance = l
				return obj
			end

			function section:Button(text, callback)
				callback = callback or noop
				local btn = new("TextButton", {
					Size = UDim2.new(1, 0, 0, 36), AutoButtonColor = false, Text = text,
					Font = Enum.Font.GothamMedium, TextSize = 14,
					Theme = {BackgroundColor3 = "Element", TextColor3 = "Text"}, Parent = content,
				}, {corner(6)})
				hover(btn, "Element", "Hover")
				btn.MouseButton1Click:Connect(function()
					btn.BackgroundColor3 = Theme.Accent
					tween(btn, TWEEN_MED, {BackgroundColor3 = Theme.Hover})
					task.spawn(callback)
				end)
				return btn
			end

			function section:Toggle(text, flag, default, callback)
				callback = callback or noop
				local state = default == true
				local obj = {}
				local function trackColor() return state and Theme.Accent or Theme.Input end
				local function knobColor() return state and Theme.Background or Theme.SubText end
				local function knobPos() return state and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) end

				local r = row(content)
				label({Text = text, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -70, 1, 0), Parent = r})
				local track = new("Frame", {
					AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(38, 20),
					Theme = {BackgroundColor3 = trackColor}, Parent = r,
				}, {corner(10)})
				local knob = new("Frame", {
					AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(14, 14), Position = knobPos(),
					Theme = {BackgroundColor3 = knobColor}, Parent = track,
				}, {corner(7)})
				local click = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Parent = r})

				function obj.Set(value, silent)
					value = value == true
					if value == state then return end
					state = value
					Library.Flags[flag] = state
					tween(track, TWEEN_FAST, {BackgroundColor3 = trackColor()})
					tween(knob, TWEEN_FAST, {BackgroundColor3 = knobColor(), Position = knobPos()})
					if not silent then task.spawn(callback, state) end
				end
				function obj.Get() return state end

				Library.Flags[flag] = state
				Library.Options[flag] = obj
				click.MouseButton1Click:Connect(function() obj.Set(not state) end)
				return obj
			end

			function section:Slider(text, flag, default, min, max, precise, callback)
				callback = callback or noop
				min, max = min or 0, max or 100
				local step = precise and 0.1 or 1
				local value = math.clamp(default or min, min, max)
				local obj = {}

				local r = row(content, 54)
				label({Text = text, Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -90, 0, 22), Parent = r})
				local box = new("TextBox", {
					AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 5), Size = UDim2.fromOffset(60, 20),
					Text = fmt(value), Font = Enum.Font.Gotham, TextSize = 13, ClearTextOnFocus = false,
					Theme = {BackgroundColor3 = "Input", TextColor3 = "Text"}, Parent = r,
				}, {corner(5)})
				local hit = new("Frame", {
					Position = UDim2.new(0, 12, 0, 30), Size = UDim2.new(1, -24, 0, 18), BackgroundTransparency = 1, Parent = r,
				})
				local track = new("Frame", {
					AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 6),
					Theme = {BackgroundColor3 = "Input"}, Parent = hit,
				}, {corner(3)})
				local fill = new("Frame", {
					Size = UDim2.fromScale((value - min) / (max - min), 1), Theme = {BackgroundColor3 = "Accent"}, Parent = track,
				}, {corner(3)})

				function obj.Set(v, silent)
					v = math.clamp(math.floor(v / step + 0.5) * step, min, max)
					box.Text = fmt(v)
					fill.Size = UDim2.fromScale((v - min) / (max - min), 1)
					if v == value then return end
					value = v
					Library.Flags[flag] = v
					if not silent then task.spawn(callback, v) end
				end
				function obj.Get() return value end

				local function fromInput(input)
					local alpha = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
					obj.Set(min + (max - min) * alpha)
				end
				hit.InputBegan:Connect(function(input)
					if not isPointer(input) then return end
					fromInput(input)
					local move = UserInputService.InputChanged:Connect(function(i)
						if isMove(i) then fromInput(i) end
					end)
					local ender
					ender = input.Changed:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then
							move:Disconnect()
							ender:Disconnect()
						end
					end)
				end)
				box.FocusLost:Connect(function()
					local n = tonumber(box.Text)
					if n then obj.Set(n) else box.Text = fmt(value) end
				end)

				Library.Flags[flag] = value
				Library.Options[flag] = obj
				return obj
			end

			function section:Textbox(text, flag, default, callback)
				callback = callback or noop
				default = tostring(default or "")
				local value = default
				local obj = {}

				local r = row(content)
				label({Text = text, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.5, -12, 1, 0), Parent = r})
				local box = new("TextBox", {
					AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0.5, -16, 0, 24),
					Text = default, PlaceholderText = "...", Font = Enum.Font.Gotham, TextSize = 13, ClearTextOnFocus = false,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Theme = {BackgroundColor3 = "Input", TextColor3 = "Text", PlaceholderColor3 = "SubText"}, Parent = r,
				}, {corner(5)})

				function obj.Set(v)
					value = tostring(v)
					box.Text = value
					Library.Flags[flag] = value
				end
				function obj.Get() return value end

				box.FocusLost:Connect(function()
					value = box.Text
					Library.Flags[flag] = value
					task.spawn(callback, value)
				end)

				Library.Flags[flag] = value
				Library.Options[flag] = obj
				return obj
			end

			function section:Keybind(text, default, callback)
				callback = callback or noop
				local key = type(default) == "string" and Enum.KeyCode[default] or default
				local listening = false
				local obj = {}

				local r = row(content)
				label({Text = text, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -120, 1, 0), Parent = r})
				local btn = new("TextButton", {
					AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(90, 24),
					AutoButtonColor = false, Font = Enum.Font.Gotham, TextSize = 13, Text = key and key.Name or "None",
					Theme = {BackgroundColor3 = "Input", TextColor3 = "Text"}, Parent = r,
				}, {corner(5)})

				function obj.Set(k)
					key = type(k) == "string" and Enum.KeyCode[k] or k
					btn.Text = key and key.Name or "None"
				end
				function obj.Get() return key end

				btn.MouseButton1Click:Connect(function()
					listening = true
					btn.Text = "..."
				end)
				connect(UserInputService.InputBegan, function(input, processed)
					if listening then
						if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
						listening = false
						if input.KeyCode ~= Enum.KeyCode.Escape then key = input.KeyCode end
						btn.Text = key and key.Name or "None"
						return
					end
					if not processed and key and input.KeyCode == key then task.spawn(callback, key.Name) end
				end, ownConnections)

				return obj
			end

			function section:Dropdown(text, flag, options, callback)
				callback = callback or noop
				local selected
				local obj = {}
				local optionButtons = {}
				local opened = false

				local wrapper = new("Frame", {
					Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Y, BackgroundTransparency = 1, Parent = content,
				}, {list(4)})
				local header = new("TextButton", {
					Size = UDim2.new(1, 0, 0, 36), AutoButtonColor = false, Text = "", LayoutOrder = 1,
					Theme = {BackgroundColor3 = "Element"}, Parent = wrapper,
				}, {corner(6)})
				hover(header, "Element", "Hover")
				label({Text = text, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.5, -12, 1, 0), Parent = header})
				local valueLabel = label({
					Text = "-", Color = "SubText", TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.5, -32, 1, 0), Parent = header,
				})
				local sign = label({
					Text = "+", Color = "SubText", Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center,
					Position = UDim2.new(1, -28, 0, 0), Size = UDim2.fromOffset(20, 36), Parent = header,
				})

				local panelFrame = new("Frame", {
					Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Y, Visible = false, LayoutOrder = 2,
					Theme = {BackgroundColor3 = "Input"}, Parent = wrapper,
				}, {corner(6), padding(6, 6, 6, 6), list(4)})
				local search = new("TextBox", {
					Size = UDim2.new(1, 0, 0, 26), Text = "", PlaceholderText = "Rechercher...", Font = Enum.Font.Gotham,
					TextSize = 13, ClearTextOnFocus = false, LayoutOrder = 1,
					Theme = {BackgroundColor3 = "Element", TextColor3 = "Text", PlaceholderColor3 = "SubText"}, Parent = panelFrame,
				}, {corner(5), padding(0, 8, 0, 8)})
				local scroll = new("ScrollingFrame", {
					Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
					CanvasSize = UDim2.new(), AutomaticCanvasSize = Y, LayoutOrder = 2, Parent = panelFrame,
				})
				local optList = list(2)
				optList.Parent = scroll
				optList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
					scroll.Size = UDim2.new(1, 0, 0, math.min(optList.AbsoluteContentSize.Y, 130))
				end)

				local function setOpen(v)
					opened = v
					panelFrame.Visible = v
					sign.Text = v and "-" or "+"
					if v then search.Text = "" end
				end
				header.MouseButton1Click:Connect(function() setOpen(not opened) end)

				search:GetPropertyChangedSignal("Text"):Connect(function()
					local q = search.Text:lower()
					for optName, b in pairs(optionButtons) do
						b.Visible = q == "" or optName:lower():find(q, 1, true) ~= nil
					end
				end)

				local function paint()
					for _, b in pairs(optionButtons) do refresh(b) end
				end

				function obj.Set(name, silent)
					if name ~= nil then name = tostring(name) end
					if name ~= nil and not optionButtons[name] then return end
					if name == selected then return end
					selected = name
					valueLabel.Text = name or "-"
					Library.Flags[flag] = name
					paint()
					if name ~= nil and not silent then task.spawn(callback, name) end
				end
				function obj.Get() return selected end

				function obj.AddOption(name)
					name = tostring(name)
					if optionButtons[name] then return end
					local b = new("TextButton", {
						Size = UDim2.new(1, 0, 0, 26), AutoButtonColor = false, Text = name, Font = Enum.Font.Gotham, TextSize = 13,
						Theme = {
							BackgroundColor3 = "Element",
							TextColor3 = function() return name == selected and Theme.Accent or Theme.Text end,
						},
						Parent = scroll,
					}, {corner(5)})
					hover(b, "Element", "Hover")
					b.MouseButton1Click:Connect(function()
						obj.Set(name)
						setOpen(false)
					end)
					optionButtons[name] = b
				end
				function obj.RemoveOption(name)
					name = tostring(name)
					local b = optionButtons[name]
					if not b then return end
					registry[b] = nil
					b:Destroy()
					optionButtons[name] = nil
					if selected == name then
						selected = nil
						valueLabel.Text = "-"
						Library.Flags[flag] = nil
					end
				end
				function obj.SetOptions(newOptions)
					for name in pairs(optionButtons) do obj.RemoveOption(name) end
					for _, name in ipairs(newOptions or {}) do obj.AddOption(name) end
				end

				obj.SetOptions(options)
				Library.Options[flag] = obj
				return obj
			end

			-- alias minuscules (compatibilité ancienne API)
			section.label, section.button, section.toggle = section.Label, section.Button, section.Toggle
			section.slider, section.textbox = section.Slider, section.Textbox
			section.keybind, section.dropdown = section.Keybind, section.Dropdown
			return section
		end
		tab.section = tab.Section

		-- Section prête à l'emploi pour choisir le thème
		function tab:ThemeSection(sectionTitle)
			local section = tab:Section(sectionTitle or "Theme", true)
			local dropdown = section:Dropdown("Preset", "__theme", Library:GetThemeNames(), function(themeName)
				Library:SetTheme(themeName)
			end)
			dropdown.Set(Library.CurrentTheme, true)
			return section, dropdown
		end

		return tab
	end
	window.tab = window.Tab

	table.insert(windows, window)
	return window
end

-- compatibilité : library:new("Titre")
function Library.new(self, name)
	return Library.CreateWindow(self, name)
end

return Library
