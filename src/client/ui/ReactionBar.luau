--!strict
-- Barre de réactions : 4 boutons utilisables pendant la fenêtre de témoignage.
-- Visible uniquement pour les jurés et l'avocat pendant la phase Testimony.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Net = require(Shared.Net)
local RemoteNames = require(Shared.RemoteNames)

local UIUtils = require(script.Parent.UIUtils)

local ReactionBar = {}

local barFrame: Frame? = nil
local gui: ScreenGui? = nil
local cooldown = false

type ReactionDef = {
	id: string,
	label: string,
	color: Color3,
}

local REACTIONS: { ReactionDef } = {
	{ id = "Suspicion", label = "SUSPICION", color = Color3.fromRGB(180, 100, 20) },
	{ id = "Credibility", label = "CRÉDIBILITÉ", color = Color3.fromRGB(34, 120, 34) },
	{ id = "Confusion", label = "CONFUSION", color = Color3.fromRGB(80, 80, 160) },
	{ id = "Contradiction", label = "CONTRADICTION", color = UIUtils.Color.Crimson },
}

local COOLDOWN_SECONDS = 4

local function fireServer(eventName: string, payload: { [string]: any })
	Net.getEvent(eventName):FireServer(payload)
end

local function setButtonsTransparency(transparency: number)
	local frame = barFrame
	if not frame then
		return
	end
	for _, child in ipairs(frame:GetChildren()) do
		if child:IsA("TextButton") then
			TweenService:Create(child, TweenInfo.new(0.2), { BackgroundTransparency = transparency }):Play()
		end
	end
end

function ReactionBar.setup()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

	local screen = Instance.new("ScreenGui")
	screen.Name = "ReactionBarGui"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 20
	screen.Enabled = false
	screen.Parent = playerGui
	gui = screen

	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Size = UDim2.new(1, 0, 0, 72)
	bar.Position = UDim2.new(0, 0, 1, -72)
	bar.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
	bar.BackgroundTransparency = 0.1
	bar.BorderSizePixel = 0
	bar.Parent = screen
	barFrame = bar

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 10)
	layout.Parent = bar

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = bar

	for _, def in ipairs(REACTIONS) do
		local reactionId = def.id
		local reactionColor = def.color

		local btn = Instance.new("TextButton")
		btn.Name = reactionId
		btn.Size = UDim2.new(0.22, -10, 0, 52)
		btn.BackgroundColor3 = reactionColor
		btn.BorderSizePixel = 0
		btn.Text = def.label
		btn.TextColor3 = UIUtils.Color.White
		btn.Font = UIUtils.Font.Title
		btn.TextScaled = true
		btn.AutoButtonColor = false
		btn.Parent = bar
		UIUtils.round(btn, 10)

		btn.MouseButton1Click:Connect(function()
			if cooldown then
				return
			end
			cooldown = true

			-- Flash blanc de confirmation
			TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = UIUtils.Color.White }):Play()
			task.delay(0.15, function()
				TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = reactionColor }):Play()
			end)

			fireServer(RemoteNames.ReactionSent, { ReactionType = reactionId })
			setButtonsTransparency(0.55)

			task.delay(COOLDOWN_SECONDS, function()
				cooldown = false
				setButtonsTransparency(0)
			end)
		end)
	end
end

function ReactionBar.show()
	if gui then
		gui.Enabled = true
		cooldown = false
	end
end

function ReactionBar.hide()
	if gui then
		gui.Enabled = false
	end
end

return ReactionBar
