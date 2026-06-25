--!strict
-- Écran de vote final : Coupable ou Innocent.
-- Aucune validation côté client — le vote est envoyé au serveur,
-- qui ignore les votes invalides (mauvaise phase, double vote, etc.).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Net = require(Shared.Net)
local RemoteNames = require(Shared.RemoteNames)

local UIUtils = require(script.Parent.UIUtils)

local VerdictScreen = {}

local gui: ScreenGui? = nil
local guiltyBtn: TextButton? = nil
local innocentBtn: TextButton? = nil
local confirmLabel: TextLabel? = nil
local hasVoted = false

local function fireServer(eventName: string, payload: { [string]: any })
	Net.getEvent(eventName):FireServer(payload)
end

local function lockButtons()
	if guiltyBtn then
		guiltyBtn.Active = false
		TweenService:Create(guiltyBtn, TweenInfo.new(0.2), { BackgroundTransparency = 0.6 }):Play()
	end
	if innocentBtn then
		innocentBtn.Active = false
		TweenService:Create(innocentBtn, TweenInfo.new(0.2), { BackgroundTransparency = 0.6 }):Play()
	end
end

local function onVote(vote: string)
	if hasVoted then
		return
	end
	hasVoted = true

	fireServer(RemoteNames.VoteCast, { Vote = vote })
	lockButtons()

	if confirmLabel then
		confirmLabel.Text = "Vote enregistré : " .. (vote == "Guilty" and "COUPABLE" or "INNOCENT")
		confirmLabel.TextColor3 = vote == "Guilty" and UIUtils.Color.Crimson or UIUtils.Color.Success
		confirmLabel.Visible = true
	end
end

function VerdictScreen.setup()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

	local screen = Instance.new("ScreenGui")
	screen.Name = "VerdictScreenGui"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 40
	screen.Enabled = false
	screen.Parent = playerGui
	gui = screen

	-- Fond foncé plein écran
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(6, 6, 14)
	bg.BackgroundTransparency = 0.3
	bg.BorderSizePixel = 0
	bg.Parent = screen

	-- Panneau central
	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0, 480, 0, 260)
	panel.Position = UDim2.new(0.5, -240, 0.5, -130)
	panel.BackgroundColor3 = Color3.fromRGB(14, 14, 26)
	panel.BorderSizePixel = 0
	panel.Parent = screen
	UIUtils.round(panel, 16)
	UIUtils.stroke(panel, UIUtils.Color.Gold, 2)

	-- Titre
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -24, 0, 40)
	title.Position = UDim2.new(0, 12, 0, 16)
	title.BackgroundTransparency = 1
	title.Text = "QUI MENTAIT ?"
	title.TextColor3 = UIUtils.Color.Gold
	title.Font = UIUtils.Font.Title
	title.TextSize = 22
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = panel

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, -24, 0, 24)
	subtitle.Position = UDim2.new(0, 12, 0, 54)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Rendez votre verdict avant la fin du décompte."
	subtitle.TextColor3 = UIUtils.Color.Muted
	subtitle.Font = UIUtils.Font.Body
	subtitle.TextSize = 13
	subtitle.TextXAlignment = Enum.TextXAlignment.Center
	subtitle.Parent = panel

	-- Bouton Coupable
	local guilty = Instance.new("TextButton")
	guilty.Size = UDim2.new(0.44, 0, 0, 64)
	guilty.Position = UDim2.new(0.04, 0, 0, 96)
	guilty.BackgroundColor3 = UIUtils.Color.Crimson
	guilty.BorderSizePixel = 0
	guilty.Text = "COUPABLE"
	guilty.TextColor3 = UIUtils.Color.White
	guilty.Font = UIUtils.Font.Title
	guilty.TextSize = 18
	guilty.AutoButtonColor = false
	guilty.Parent = panel
	UIUtils.round(guilty, 12)
	guiltyBtn = guilty

	-- Bouton Innocent
	local innocent = Instance.new("TextButton")
	innocent.Size = UDim2.new(0.44, 0, 0, 64)
	innocent.Position = UDim2.new(0.52, 0, 0, 96)
	innocent.BackgroundColor3 = UIUtils.Color.Success
	innocent.BorderSizePixel = 0
	innocent.Text = "INNOCENT"
	innocent.TextColor3 = UIUtils.Color.White
	innocent.Font = UIUtils.Font.Title
	innocent.TextSize = 18
	innocent.AutoButtonColor = false
	innocent.Parent = panel
	UIUtils.round(innocent, 12)
	innocentBtn = innocent

	-- Confirmation après vote
	local confirm = Instance.new("TextLabel")
	confirm.Size = UDim2.new(1, -24, 0, 36)
	confirm.Position = UDim2.new(0, 12, 0, 176)
	confirm.BackgroundTransparency = 1
	confirm.Text = ""
	confirm.TextColor3 = UIUtils.Color.White
	confirm.Font = UIUtils.Font.Title
	confirm.TextSize = 16
	confirm.TextXAlignment = Enum.TextXAlignment.Center
	confirm.Visible = false
	confirm.Parent = panel
	confirmLabel = confirm

	guilty.MouseButton1Click:Connect(function()
		onVote("Guilty")
	end)

	innocent.MouseButton1Click:Connect(function()
		onVote("Innocent")
	end)
end

function VerdictScreen.show()
	if gui then
		gui.Enabled = true
		hasVoted = false

		if guiltyBtn then
			guiltyBtn.Active = true
			guiltyBtn.BackgroundTransparency = 0
		end
		if innocentBtn then
			innocentBtn.Active = true
			innocentBtn.BackgroundTransparency = 0
		end
		if confirmLabel then
			confirmLabel.Visible = false
			confirmLabel.Text = ""
		end
	end
end

function VerdictScreen.hide()
	if gui then
		gui.Enabled = false
	end
end

-- Affiche le verdict révélé par le serveur (résultat collectif)
function VerdictScreen.showResult(verdict: string, guiltyCount: number)
	if not gui then
		return
	end
	gui.Enabled = true

	if guiltyBtn then
		guiltyBtn.Active = false
	end
	if innocentBtn then
		innocentBtn.Active = false
	end

	if confirmLabel then
		local resultText = verdict == "Guilty"
				and string.format("VERDICT : COUPABLE (%d vote(s))", guiltyCount)
			or string.format("VERDICT : INNOCENT (%d vote(s))", guiltyCount)
		confirmLabel.Text = resultText
		confirmLabel.TextColor3 = verdict == "Guilty" and UIUtils.Color.Crimson or UIUtils.Color.Success
		confirmLabel.Visible = true
	end
end

return VerdictScreen
