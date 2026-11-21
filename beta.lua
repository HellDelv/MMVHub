--[[
	MMVHub — единый автономный скрипт: GUI + все гири в одном файле.
	Использование:
	  * Вставь этот код в LocalScript в StarterGui, ИЛИ
	  * выполни его на клиенте (телефон / executor) — нужен Players.LocalPlayer.
	Управление:
	  * X — открыть/закрыть окно
	  * Цифры 1–8 — выдать гир (когда окно открыто)
	  * Клик по кнопке — выдать гир
	Гири создаются самим скриптом, внутренние скрипты не нужны.
	Всё работает на клиенте (полёт, скорость, гравитация, стрельба, бомба).
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
while not player do task.wait() end
local playerGui = player:WaitForChild("PlayerGui")

-- Убираем старую копию, чтобы скрипт можно было запускать повторно
local oldGui = playerGui:FindFirstChild("MMVHub")
if oldGui then oldGui:Destroy() end

-- ============================== ДАННЫЕ ГИРОВ ==============================

local GEAR_DATA = {
	RainbowCarpet = {
		Text = "Rainbow Carpet",
		Size = Vector3.new(3, 0.5, 3.5),
		MeshId = 223079737, TextureId = 223080038,
		MeshScale = Vector3.new(1.125, 1.125, 1.125),
		Animations = { Sit = "rbxassetid://225279725", SitR15 = "rbxassetid://1239927101" },
	},
	GravityCoil = {
		Text = "Gravity Coil",
		Size = Vector3.new(1, 1.2, 2),
		MeshId = 16606212, TextureId = 16606141,
		MeshScale = Vector3.new(0.7, 0.7, 0.7),
		Sounds = { { Name = "CoilSound", Id = 177979632, Volume = 1 } },
	},
	SpeedCoil = {
		Text = "Speed Coil",
		Size = Vector3.new(1.3, 1.3, 2.4),
		MeshId = 16606212, TextureId = 99170547,
		MeshScale = Vector3.new(0.7, 0.7, 0.7),
		Sounds = { { Name = "CoilSound", Id = 99173388, Volume = 1 } },
	},
	SeaCrossbow = {
		Text = "Sea Crossbow",
		Size = Vector3.new(1, 1, 1),
		MeshId = 235107630, TextureId = 235107780,
		MeshScale = Vector3.new(1, 1, 1),
		Sounds = {
			{ Name = "Shot", Id = 99204505, Volume = 0.5 },
			{ Name = "Hit", Id = 58274204, Volume = 1 },
		},
		Animations = {
			Hold = "rbxassetid://220828820",
			Fire = "rbxassetid://220829805",
			Reload = "rbxassetid://220832011",
		},
	},
	FakeBomb = {
		Text = "Fake Bomb",
		Size = Vector3.new(1.65, 0.9, 1.3),
		MeshId = 104516854, TextureId = 116942354546539,
		MeshScale = Vector3.new(1.5, 1.5, 1.5),
		Sounds = {
			{ Name = "Beep", Id = 6042053626, Volume = 1 },
			{ Name = "Fuse", Id = 6042053626, Volume = 1 },
			{ Name = "Throw", Id = 6042053626, Volume = 1 },
			{ Name = "PleaseNo", Id = 6042053626, Volume = 1 },
		},
	},
}

-- Кнопки окна в исходном порядке (номера 1-8)
local BUTTON_ORDER = {
	"SeaCrossbow", "OldAnim", "RainbowCarpet", "GravityCoil",
	"SpeedCoil", "SpeedGlitch", "FakeBomb", "GunAnimDeleter",
}

local BUTTON_TEXT = {
	SeaCrossbow = "Sea Crossbow", OldAnim = "Old Animation",
	RainbowCarpet = "Rainbow Carpet", GravityCoil = "Gravity Coil",
	SpeedCoil = "Speed Coil", SpeedGlitch = "Speed Glitch",
	FakeBomb = "Fake Bomb", GunAnimDeleter = "Remove gun anim",
}

-- Точные позиции кнопок из оригинального GUI (ромб из кнопок)
local BUTTON_POSITIONS = {
	SeaCrossbow = UDim2.fromScale(0.409709, 0.046602),
	OldAnim = UDim2.fromScale(0.409709, 0.753398),
	RainbowCarpet = UDim2.fromScale(0.056311, 0.409709),
	GravityCoil = UDim2.fromScale(0.759223, 0.409709),
	SpeedCoil = UDim2.fromScale(0.650485, 0.165049),
	SpeedGlitch = UDim2.fromScale(0.650485, 0.658252),
	FakeBomb = UDim2.fromScale(0.163107, 0.165049),
	GunAnimDeleter = UDim2.fromScale(0.163107, 0.658252),
}

-- ============================== ПОСТРОЕНИЕ GUI ==============================

local gui = Instance.new("ScreenGui")
gui.Name = "MMVHub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local window = Instance.new("Frame")
window.Name = "MainWindow"
window.Size = UDim2.fromOffset(515, 515)
window.Position = UDim2.new(0.5, 0, 0.5, 0)
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.BackgroundTransparency = 1
window.Visible = false
window.Parent = gui

local windowScale = Instance.new("UIScale")
windowScale.Name = "WindowScale"
windowScale.Scale = 0
windowScale.Parent = window

-- Кнопки расположены ромбом, как в оригинальном GUI
local buttons = {}
do
	local size = 93
	for index, name in BUTTON_ORDER do
		local button = Instance.new("TextButton")
		button.Name = name
		button.Size = UDim2.fromOffset(size, size)
		button.Position = BUTTON_POSITIONS[name]
		button.AnchorPoint = Vector2.new(0, 0)
		button.BackgroundColor3 = Color3.new(1, 1, 1)
		button.Text = BUTTON_TEXT[name] or name
		button.TextColor3 = Color3.new(0, 0, 0)
		button.TextSize = 20
		button.Font = Enum.Font.FredokaOne
		button.TextWrapped = true
		button.AutoButtonColor = true
		button.Interactable = true
		button.Parent = window

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 100)
		corner.Parent = button

		local scale = Instance.new("UIScale")
		scale.Name = "ButtonScale"
		scale.Scale = 1
		scale.Parent = button

		-- номерной бейдж
		local badge = Instance.new("TextLabel")
		badge.Name = "NumberBadge"
		badge.Text = tostring(index)
		badge.Size = UDim2.fromOffset(20, 20)
		badge.Position = UDim2.fromOffset(4, 4)
		badge.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		badge.TextColor3 = Color3.fromRGB(255, 255, 255)
		badge.TextSize = 14
		badge.Font = Enum.Font.FredokaOne
		badge.BackgroundTransparency = 0.25
		badge.ZIndex = 5
		badge.Parent = button

		local badgeCorner = Instance.new("UICorner")
		badgeCorner.CornerRadius = UDim.new(1, 0)
		badgeCorner.Parent = badge

		buttons[index] = button
	end
end

-- ============================== АНИМАЦИИ ОКНА ==============================

local isOpen = false
local isAnimating = false

local function closeWindow()
	isOpen = false
	local tween = TweenService:Create(
		windowScale,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Scale = 0 }
	)
	tween:Play()
	tween.Completed:Wait()
	window.Visible = false
end

local function openWindow()
	isOpen = true
	window.Visible = true
	windowScale.Scale = 0
	local tween = TweenService:Create(
		windowScale,
		TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }
	)
	tween:Play()
	tween.Completed:Wait()
end

local function toggleWindow()
	if isAnimating then return end
	isAnimating = true
	if isOpen then closeWindow() else openWindow() end
	isAnimating = false
end

-- Анимации кнопок: наведение и нажатие
for _, button in buttons do
	local scale = button:FindFirstChild("ButtonScale")
	local info = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local function tweenTo(value)
		TweenService:Create(scale, info, { Scale = value }):Play()
	end
	button.MouseEnter:Connect(function() tweenTo(1.08) end)
	button.MouseLeave:Connect(function() tweenTo(1) end)
	button.MouseButton1Down:Connect(function() tweenTo(0.92) end)
	button.MouseButton1Up:Connect(function() tweenTo(1.08) end)
	button.MouseButton1Click:Connect(function()
		if isOpen and not isAnimating then
			isAnimating = true
			giveGearDeferred(button.Name)
			closeWindow()
			isAnimating = false
		end
	end)
end

-- Клавиатура: X — окно, 1-8 — гир
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.X then
		toggleWindow()
		return
	end
	if isOpen and not isAnimating then
		local num = input.KeyCode.Value - string.byte("1")
		if num >= 0 and num < #buttons then
			local button = buttons[num + 1]
			if button then
				isAnimating = true
				giveGearDeferred(button.Name)
				closeWindow()
				isAnimating = false
			end
	end
	end
end)

-- ============================== СОЗДАНИЕ ГИРОВ ==============================

local function buildTool(name)
	local data = GEAR_DATA[name]
	if not data then return nil end

	local tool = Instance.new("Tool")
	tool.Name = name
	tool.CanBeDropped = true

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = data.Size
	handle.CanCollide = false
	handle.Parent = tool

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = "rbxassetid://" .. data.MeshId
	mesh.TextureId = "rbxassetid://" .. data.TextureId
	mesh.Scale = data.MeshScale
	mesh.Parent = handle

	for _, snd in data.Sounds or {} do
		local sound = Instance.new("Sound")
		sound.Name = snd.Name
		sound.SoundId = "rbxassetid://" .. snd.Id
		sound.Volume = snd.Volume or 1
		sound.Parent = handle
	end

	for animName, animId in data.Animations or {} do
		local anim = Instance.new("Animation")
		anim.Name = animName
		anim.AnimationId = animId
		anim.Parent = tool
	end

	return tool
end

-- Помощники для персонажа
local function getCharParts(tool)
	local char = tool.Parent
	if not char or not char:FindFirstChildOfClass("Humanoid") then return nil end
	return char, char:FindFirstChildOfClass("Humanoid"), char:FindFirstChild("HumanoidRootPart")
end

local function playAnim(tool, animName)
	local char = tool.Parent
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	local anim = tool:FindFirstChild(animName)
	if humanoid and anim then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then
			local track = animator:LoadAnimation(anim)
			track:Play()
			return track
		end
	end
	return nil
end

-- ============================== ПОВЕДЕНИЕ ГИРОВ ==============================

-- ---- Speed Coil: +16 к скорости ----
local function setupSpeedCoil(tool)
	local humanoid, oldSpeed
	tool.Equipped:Connect(function()
		local char = tool.Parent
		humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			oldSpeed = humanoid.WalkSpeed
			humanoid.WalkSpeed = oldSpeed + 16
		end
		local sound = tool.Handle:FindFirstChild("CoilSound")
		if sound then sound:Play() end
	end)
	tool.Unequipped:Connect(function()
		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = oldSpeed
		end
		humanoid = nil
	end)
end

-- ---- Gravity Coil: противодействие 75% гравитации ----
local function setupGravityCoil(tool)
	local force = Instance.new("BodyForce")
	force.Name = "GravityCoilEffect"
	force.Force = Vector3.zero
	local conns = {}

	tool.Equipped:Connect(function()
		local char = tool.Parent
		if not char then return end
		local function update()
			if not char.Parent then return end
			local totalMass = 0
			for _, part in char:GetDescendants() do
				if part:IsA("BasePart") then
					totalMass += part:GetMass()
				end
			end
			-- 9.81 * 20 (стадов на метр), компенсируем 75%
			force.Force = Vector3.new(0, totalMass * 196.2 * 0.75, 0)
		end
		update()
		table.insert(conns, char.DescendantAdded:Connect(update))
		table.insert(conns, char.DescendantRemoving:Connect(update))
		force.Parent = tool.Handle
	end)

	tool.Unequipped:Connect(function()
		force.Parent = nil
		for _, conn in conns do conn:Disconnect() end
		table.clear(conns)
	end)
end

-- ---- Rainbow Carpet: полёт ----
local function setupRainbowCarpet(tool)
	local handle = tool.Handle
	local flying = false
	local equipped = false
	local movers = {}
	local sitTrackRef = nil

	local GRIP_NORMAL = CFrame.new(-1.5, 0, 0, 0, 0, -1, -1, 8.9e-5, 0, 8.9e-5, 1, 0)
	local GRIP_FLYING = CFrame.new(-1.5, 0.5, -0.75, -1, 0, -9e-9, -9e-9, 8.1e-8, 1, 7.3e-16, 1, -8.1e-8)

	local CARPET_PIECES = {
		{ MeshId = 223079795, Angle = 160 },
		{ MeshId = 223079835, Angle = 100 },
		{ MeshId = 223079888, Angle = 100 },
		{ MeshId = 223079981, Angle = 160 },
	}
	local RAINBOW_COLORS = {
		Color3.new(1, 0, 0), Color3.new(1, 0.5, 0), Color3.new(1, 1, 0),
		Color3.new(0, 1, 0), Color3.new(0, 1, 1), Color3.new(0, 0, 1),
		Color3.new(0.5, 0, 1),
	}

	local function cleanUpCarpet()
		for _, child in tool:GetChildren() do
			if child:IsA("BasePart") and child ~= handle then
				child.Parent = nil
			end
		end
	end

	local function removeMovers()
		for _, mover in movers do
			if mover and mover.Parent then mover.Parent = nil end
		end
		table.clear(movers)
	end

	local function spawnRainbow(fromPos, toPos)
		local distance = (toPos - fromPos).Magnitude
		if distance < 1 then return end
		local length = distance + 3.5
		local model = Instance.new("Model")
		model.Name = "RainbowPart"
		local midCFrame = CFrame.lookAt((fromPos + (toPos - fromPos).Unit * (distance / 2)), toPos)
		for i, color in RAINBOW_COLORS do
			local part = Instance.new("Part")
			part.Name = "Part"
			part.Size = Vector3.new(0.5, 0.5, length)
			part.Color = color
			part.Material = Enum.Material.SmoothPlastic
			part.Anchored = true
			part.CanCollide = false
			part.CFrame = midCFrame * CFrame.new((0.5 * (i - 1)), 0, 0)
			part.Parent = model
		end
		Debris:AddItem(model, 1)
		model.Parent = workspace
	end

	local function stopFlight(char, humanoid, root)
		flying = false
		removeMovers()
		-- после снятия инструмента tool.Parent — уже Backpack, поэтому берём персонажа у игрока
		local character = player.Character
		if not (root and root.Parent) and character then
			root = character:FindFirstChild("HumanoidRootPart")
		end
		if not (humanoid and humanoid.Parent) and character then
			humanoid = character:FindFirstChildOfClass("Humanoid")
		end
		if root and root.Parent then
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = 16
			humanoid.PlatformStand = false
			humanoid.AutoRotate = true
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		end
		tool.Grip = GRIP_NORMAL
		if sitTrackRef then
			sitTrackRef:Stop()
			sitTrackRef = nil
		end
		cleanUpCarpet()
		handle.Transparency = 0
	end

	tool.Equipped:Connect(function()
		equipped = true
		tool.Grip = GRIP_NORMAL
	end)

	tool.Unequipped:Connect(function()
		equipped = false
		-- персонаж берём через player.Character — tool уже в Backpack
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if flying then
			stopFlight(character, humanoid, root)
		else
			cleanUpCarpet()
			handle.Transparency = 0
		end
	end)

	tool.Activated:Connect(function()
		if not tool.Enabled or flying then return end
		local char, humanoid, root = getCharParts(tool)
		if not char or not humanoid or not root then return end

		tool.Enabled = false
		flying = true
		handle.Transparency = 1
		cleanUpCarpet()

		-- собираем ковёр из 4 частей
		for i, piece in CARPET_PIECES do
			local carpetPart = Instance.new("Part")
			carpetPart.CanCollide = false
			carpetPart.Size = Vector3.new(3, 0.5, 6.5 / 4)
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.FileMesh
			mesh.MeshId = "rbxassetid://" .. piece.MeshId
			mesh.TextureId = "rbxassetid://223080038"
			mesh.Scale = Vector3.new(1.125, 1.125, 1.125)
			mesh.Parent = carpetPart
			local weld = Instance.new("Weld")
			weld.Part0 = handle
			weld.Part1 = carpetPart
			local xOffset = (i == 1 or i == 4) and -0.005 or 0
			local yOffset = -((handle.Size.Z / 2) - (carpetPart.Size.Z / 2))
				+ (carpetPart.Size.Z * (i - 1))
				+ ((i == 2 and 0.245) or (i == 3 and 0.04) or (i == 4 and 0.28) or 0)
			weld.C1 = CFrame.new(0, xOffset, yOffset)
			weld.Parent = carpetPart
			carpetPart.Parent = tool
		end

		-- анимация сидения
		local isR15 = humanoid.RigType == Enum.HumanoidRigType.R15
		sitTrackRef = playAnim(tool, isR15 and "SitR15" or "Sit")
		tool.Grip = GRIP_FLYING

		root.Anchored = true
		task.delay(0.2, function()
			if root.Parent then
				root.Anchored = false
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end
		end)

		local gyro = Instance.new("BodyGyro")
		gyro.Name = "FlightSpin"
		gyro.P = 10000
		gyro.MaxTorque = Vector3.new(1, 1, 1) * 1000000
		gyro.CFrame = root.CFrame
		gyro.Parent = root

		local power = Instance.new("BodyVelocity")
		power.Name = "FlightPower"
		power.Velocity = Vector3.zero
		power.MaxForce = Vector3.zero
		power.P = 1000
		power.Parent = root

		local hold = Instance.new("BodyPosition")
		hold.Name = "FlightHold"
		hold.P = 100000
		hold.MaxForce = Vector3.zero
		hold.Position = root.Position
		hold.Parent = root

		table.insert(movers, gyro)
		table.insert(movers, power)
		table.insert(movers, hold)

		humanoid.WalkSpeed = 0
		humanoid.PlatformStand = true
		humanoid.AutoRotate = false

		-- цикл полёта
		task.spawn(function()
			local lastPlace = nil
			while flying and equipped and root.Parent and humanoid.Parent and humanoid.Health > 0 do
				local camera = workspace.CurrentCamera
				local look = camera.CFrame.LookVector
				local flatLook = Vector3.new(look.X, 0, look.Z)
				if flatLook.Magnitude < 0.01 then
					flatLook = root.CFrame.LookVector
				end
				flatLook = flatLook.Unit
				-- персонаж полностью повторяет ориентацию камеры (включая наклон вверх/вниз)
				gyro.CFrame = camera.CFrame

				-- движение в пространстве камеры: наклон камеры вверх = полёт вверх
				local moveDir = humanoid.MoveDirection
				local push = Vector3.zero
				if moveDir.Magnitude > 0.01 then
					local flatCam = CFrame.lookAt(Vector3.zero, flatLook)
					local localMove = flatCam:VectorToObjectSpace(moveDir)
					local forward = -localMove.Z
					local side = localMove.X
					push = (look * forward + camera.CFrame.RightVector * side) * 60
				end

				if push.Magnitude < 1 then
					hold.MaxForce = Vector3.new(1, 1, 1) * 100000
					power.MaxForce = Vector3.zero
					hold.Position = root.Position
				else
					hold.MaxForce = Vector3.zero
					power.MaxForce = Vector3.new(1, 1, 1) * 100000
				end
				power.Velocity = push

				-- радужный след
				local currentPlace = handle.Position
				local flatSpeed = Vector3.new(
					root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z
				).Magnitude
				if lastPlace and flatSpeed > 10 then
					task.spawn(spawnRainbow, lastPlace, currentPlace)
					lastPlace = currentPlace
				elseif not lastPlace then
					lastPlace = currentPlace
				end

				task.wait(0.1)
		end
			if flying then
				stopFlight(char, humanoid, root)
		end
		end)

		task.delay(2, function()
			tool.Enabled = true
		end)
	end)
end

-- ---- Sea Crossbow: стрельба водяными стрелами ----
local function setupSeaCrossbow(tool)
	local handle = tool.Handle
	local mouse = player:GetMouse()
	local canFire = true
	local holdTrack = nil

	tool.Equipped:Connect(function()
		holdTrack = playAnim(tool, "Hold")
		mouse.Icon = "rbxasset://textures/GunCursor.png"
	end)

	tool.Unequipped:Connect(function()
		if holdTrack then holdTrack:Stop() holdTrack = nil end
		mouse.Icon = ""
	end)

	tool.Activated:Connect(function()
		if not canFire then return end
		local char, humanoid = getCharParts(tool)
		if not humanoid then return end

		canFire = false
		task.delay(1.33, function()
			canFire = true
			local mesh = handle:FindFirstChildOfClass("SpecialMesh")
			if mesh then mesh.MeshId = "rbxassetid://235107630" end
		end)

		playAnim(tool, "Fire")
		local mesh = handle:FindFirstChildOfClass("SpecialMesh")
		if mesh then mesh.MeshId = "rbxassetid://235107551" end
		task.delay(1 / 3, function()
			playAnim(tool, "Reload")
		end)

		local shot = handle:FindFirstChild("Shot")
		if shot then
			shot.Pitch = math.random(90, 110) / 100
			shot:Play()
		end

		-- стрела (движется лучкастом — попадание не проскочит)
		local target = mouse.Hit.Position
		local arrow = Instance.new("Part")
		arrow.Name = "Arrow"
		arrow.Transparency = 0.25
		arrow.Reflectance = 0.5
		arrow.Size = Vector3.new(0.2, 0.2, 2.5)
		arrow.TopSurface = Enum.SurfaceType.Smooth
		arrow.BottomSurface = Enum.SurfaceType.Smooth
		arrow.CanCollide = false
		arrow.Anchored = true

		local arrowMesh = Instance.new("SpecialMesh")
		arrowMesh.MeshType = Enum.MeshType.FileMesh
		arrowMesh.MeshId = "rbxassetid://235107348"
		arrowMesh.Parent = arrow

		arrow.CFrame = CFrame.new(handle.Position, target)
		arrow.Parent = workspace

		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = { char, arrow }

		local hitSound = handle:FindFirstChild("Hit")
		local velocity = arrow.CFrame.LookVector * 128
		local done = false

		local stepConn
		stepConn = RunService.Heartbeat:Connect(function(dt)
			if done or not arrow.Parent then
				stepConn:Disconnect()
				return
			end
			local step = velocity * dt
			local result = workspace:Raycast(arrow.Position, step, rayParams)
			arrow.CFrame = CFrame.new(arrow.Position + step)
			if result then
				done = true
				stepConn:Disconnect()

				-- водяной взрыв
				local pos = result.Position
				local radius = 8 + 4 * math.random(1, 3)
				local terrain = workspace.Terrain
				task.spawn(function()
					terrain:FillBall(pos, radius, Enum.Material.Water)
					task.wait(3)
					terrain:FillBall(pos, radius, Enum.Material.Air)
				end)

				if hitSound then
					local clone = hitSound:Clone()
					clone.Parent = arrow
					clone:Play()
				end

				arrow.Transparency = 1
				Debris:AddItem(arrow, 5)
			end
		end)
		Debris:AddItem(arrow, 10)
	end)
end

-- ---- Fake Bomb: бросок бомбы + невидимая платформа под ногами (двойной прыжок) ----
local function setupFakeBomb(tool)
	local handle = tool.Handle
	local mouse = player:GetMouse()
	local canThrow = true

	-- мигающий индикатор и дым на ручке (клонируются вместе с бомбой)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(3, 0, 3, 0)
	local lightImage = Instance.new("ImageLabel")
	lightImage.Name = "LightImage"
	lightImage.BackgroundTransparency = 1
	lightImage.BorderSizePixel = 0
	lightImage.Size = UDim2.new(1, 0, 1, 0)
	lightImage.Image = "rbxassetid://104564194"
	lightImage.Visible = false
	lightImage.Parent = billboard
	billboard.Parent = handle

	local smoke = Instance.new("Smoke")
	smoke.Name = "Smoke"
	smoke.Enabled = false
	smoke.Size = 0.1
	smoke.Color = Color3.fromRGB(128, 128, 128)
	smoke.Parent = handle

	local function makeConfetti(position)
		local confetti = Instance.new("Part")
		confetti.Name = "Effect"
		confetti.Size = Vector3.zero
		confetti.CanCollide = false
		confetti.Transparency = 1
		confetti.CFrame = CFrame.new(position)
		confetti.AssemblyLinearVelocity = Vector3.new(
			math.random() - 0.5, math.random(), math.random() - 0.5
		).Unit * 20

		local billboard = Instance.new("BillboardGui")
		billboard.Adornee = confetti
		billboard.Size = UDim2.new(7, 0, 4, 0)
		local image = Instance.new("ImageLabel")
		image.BackgroundTransparency = 1
		image.BorderSizePixel = 0
		image.Size = UDim2.new(1, 0, 1, 0)
		image.Image = "rbxassetid://104606998"
		image.Parent = billboard
		billboard.Parent = confetti

		local float = Instance.new("BodyForce")
		float.Force = Vector3.new(0, confetti:GetMass() * 196.2, 0)
		float.Parent = confetti

		Debris:AddItem(confetti, 7 + math.random())
		confetti.Parent = workspace
	end

	local function fuseBomb(bomb)
		task.spawn(function()
			local beep = bomb:FindFirstChild("Beep")
			local fuse = bomb:FindFirstChild("Fuse")
			local pleaseNo = bomb:FindFirstChild("PleaseNo")
			local bombSmoke = bomb:FindFirstChild("Smoke")
			local bombGui = bomb:FindFirstChild("BillboardGui")
			local lightImg = bombGui and bombGui:FindFirstChild("LightImage")

			-- писк с ускоряющимся интервалом + мигание индикатора
			local timer = 4
			local startTime = tick()
			while true do
				local percent = (tick() - startTime) / timer
				if percent > 1 then break end
				if beep then beep:Play() end
				if lightImg then lightImg.Visible = true end
				task.wait(0.1)
				if lightImg then lightImg.Visible = false end
				task.wait(math.max(0.05, (1 - percent) * 1))
			end

			task.wait(0.5)
				if bombSmoke then bombSmoke.Enabled = true end
			task.wait(0.5)
				if fuse then fuse:Play() end
				if lightImg then lightImg.Visible = false end
				if pleaseNo then pleaseNo:Play() end

			-- конфетти!
				for _ = 1, 7 do
					makeConfetti(bomb.Position)
				end
				task.wait(0.5)
				if bombSmoke then bombSmoke.Enabled = false end
				task.wait(2.5)
				bomb.Parent = nil
			end)
	end

	tool.Activated:Connect(function()
		if not canThrow then return end
		local char, humanoid, root = getCharParts(tool)
		if not humanoid or not root then return end

		canThrow = false
		handle.Transparency = 1

		-- невидимая платформа под ногами (двойной прыжок)
		local pad = Instance.new("Part")
		pad.Name = "JumpPad"
		pad.Size = Vector3.new(6, 1, 6)
		pad.CFrame = CFrame.new(root.Position - Vector3.new(0, 3.5, 0))
		pad.Anchored = true
		pad.CanCollide = true
		pad.Transparency = 1
		pad.Parent = workspace
		task.delay(1, function()
			pad.Parent = nil
		end)

		-- бросок бомбы в точку курсора
		local bomb = handle:Clone()
		bomb.Name = "FakeBombProjectile"
		bomb.CanCollide = true
		bomb.Transparency = 0

		local throwSound = bomb:FindFirstChild("Throw")
		if throwSound then throwSound:Play() end

		local target = mouse.Hit.Position
		local direction = (target - root.Position)
		if direction.Magnitude > 0 then direction = direction.Unit end
		bomb.CFrame = CFrame.new(root.Position, root.Position + direction) * CFrame.new(0, 0, -5)
		bomb.AssemblyLinearVelocity = direction * 50 + Vector3.new(0, 20, 0)

		-- приклеивается к другим персонажам при касании
		local attached = false
		bomb.Touched:Connect(function(hit)
			if attached then return end
			if hit.Name == "Handle" or hit.Name == "Effect" or hit.Name == "JumpPad" then return end
			local otherChar = hit.Parent
			local otherHum = otherChar and otherChar:FindFirstChildOfClass("Humanoid")
			if otherHum and otherHum.Health > 0 and otherChar ~= char then
				local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
				if otherRoot then
					attached = true
					local weld = Instance.new("Weld")
					weld.Part0 = otherRoot
					weld.Part1 = bomb
					weld.C0 = CFrame.new(0, 0, 0.8) * CFrame.Angles(math.pi / 2, 3.5, 0)
					weld.Parent = bomb
				end
			end
		end)

		bomb.Parent = workspace
		Debris:AddItem(bomb, 14)
		fuseBomb(bomb)

		task.delay(0.1, function()
			handle.Transparency = 0
			canThrow = true
		end)
	end)
end

local GEAR_SETUPS = {
	SpeedCoil = setupSpeedCoil,
	GravityCoil = setupGravityCoil,
	RainbowCarpet = setupRainbowCarpet,
	SeaCrossbow = setupSeaCrossbow,
	FakeBomb = setupFakeBomb,
}

-- ============================== ВЫДАЧА ГИРОВ ==============================

-- declare ahead: кнопки вызывают выдачу до определения ниже
function giveGearDeferred(buttonName)
	local name = buttonName
	if not GEAR_DATA[name] then return end
	local backpack = player:FindFirstChild("Backpack")
	local char = player.Character
	if not backpack then return end
	if backpack:FindFirstChild(name) then return end
	if char and char:FindFirstChild(name) then return end

	local tool = buildTool(name)
	if not tool then return end
	local setup = GEAR_SETUPS[name]
	if setup then setup(tool) end
	tool.Parent = backpack
end

print("[MMVHub] Готов! X — открыть окно, 1-8 или клик — выдать гир.")
