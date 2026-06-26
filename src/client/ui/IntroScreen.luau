--!strict
-- Écran de présentation de l'affaire au début de la phase Intro.
-- Affiche titre, résumé, accusation et objectif selon le rôle du joueur.
-- Disparaît automatiquement quand la phase Testimony commence.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local UIUtils = require(script.Parent.UIUtils)

local IntroScreen = {}

local gui: ScreenGui? = nil
local titleLabel: TextLabel? = nil
local summaryLabel: TextLabel? = nil
local accusationLabel: TextLabel? = nil
local objectiveLabel: TextLabel? = nil
local caseIdLabel: TextLabel? = nil

local ROLE_COLORS: { [string]: Color3 } = {
	HonestWitness = Color3.fromRGB(34, 139, 34),
	Liar = UIUtils.Color.Crimson,
	Prosecutor = UIUtils.Color.Navy,
	Defense = Color3.fromRGB(120, 80, 160),
	Juror = Color3.fromRGB(100, 100, 160),
}

function IntroScreen.setup()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

	local screen = Instance.new("ScreenGui")
	screen.Name = "IntroScreenGui"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 20
	screen.Enabled = false
	screen.Parent = playerGui
	gui = screen

	-- Fond foncé
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(6, 6, 14)
	bg.BackgroundTransparency = 0.18
	bg.BorderSizePixel = 0
	bg.Parent = screen

	-- Panneau principal
	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0, 560, 0, 370)
	panel.Position = UDim2.new(0.5, -280, 0.5, -185)
	panel.BackgroundColor3 = Color3.fromRGB(12, 12, 22)
	panel.BorderSizePixel = 0
	panel.Parent = screen
	UIUtils.round(panel, 16)
	UIUtils.stroke(panel, UIUtils.Color.Gold, 2)

	-- Badge dossier en haut
	local badge = Instance.new("Frame")
	badge.Size = UDim2.new(1, -24, 0, 28)
	badge.Position = UDim2.new(0, 12, 0, 12)
	badge.BackgroundColor3 = UIUtils.Color.Gold
	badge.BackgroundTransparency = 0.85
	badge.BorderSizePixel = 0
	badge.Parent = panel
	UIUtils.round(badge, 6)

	local badgeText = Instance.new("TextLabel")
	badgeText.Size = UDim2.new(1, -16, 1, 0)
	badgeText.Position = UDim2.new(0, 8, 0, 0)
	badgeText.BackgroundTransparency = 1
	badgeText.TextColor3 = UIUtils.Color.Gold
	badgeText.Font = UIUtils.Font.Title
	badgeText.TextSize = 12
	badgeText.TextXAlignment = Enum.TextXAlignment.Left
	badgeText.Parent = badge
	caseIdLabel = badgeText

	-- Séparateur doré
	local sep = Instance.new("Frame")
	sep.Size = UDim2.new(1, -24, 0, 1)
	sep.Position = UDim2.new(0, 12, 0, 46)
	sep.BackgroundColor3 = UIUtils.Color.Gold
	sep.BackgroundTransparency = 0.6
	sep.BorderSizePixel = 0
	sep.Parent = panel

	-- Titre de l'affaire
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -24, 0, 44)
	title.Position = UDim2.new(0, 12, 0, 52)
	title.BackgroundTransparency = 1
	title.Text = ""
	title.TextColor3 = UIUtils.Color.Ivory
	title.Font = UIUtils.Font.Title
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.TextWrapped = true
	title.Parent = panel
	titleLabel = title

	-- Résumé
	local summary = Instance.new("TextLabel")
	summary.Size = UDim2.new(1, -32, 0, 72)
	summary.Position = UDim2.new(0, 16, 0, 102)
	summary.BackgroundTransparency = 1
	summary.Text = ""
	summary.TextColor3 = UIUtils.Color.Muted
	summary.Font = UIUtils.Font.Body
	summary.TextSize = 13
	summary.TextXAlignment = Enum.TextXAlignment.Left
	summary.TextWrapped = true
	summary.Parent = panel
	summaryLabel = summary

	-- Séparateur secondaire
	local sep2 = Instance.new("Frame")
	sep2.Size = UDim2.new(1, -24, 0, 1)
	sep2.Position = UDim2.new(0, 12, 0, 182)
	sep2.BackgroundColor3 = UIUtils.Color.Charcoal
	sep2.BorderSizePixel = 0
	sep2.Parent = panel

	-- Accusation
	local accLabel = Instance.new("TextLabel")
	accLabel.Size = UDim2.new(0, 90, 0, 18)
	accLabel.Position = UDim2.new(0, 16, 0, 192)
	accLabel.BackgroundTransparency = 1
	accLabel.Text = "ACCUSATION"
	accLabel.TextColor3 = UIUtils.Color.Gold
	accLabel.Font = UIUtils.Font.Title
	accLabel.TextSize = 11
	accLabel.TextXAlignment = Enum.TextXAlignment.Left
	accLabel.Parent = panel

	local accusation = Instance.new("TextLabel")
	accusation.Size = UDim2.new(1, -32, 0, 50)
	accusation.Position = UDim2.new(0, 16, 0, 212)
	accusation.BackgroundTransparency = 1
	accusation.Text = ""
	accusation.TextColor3 = UIUtils.Color.Ivory
	accusation.Font = UIUtils.Font.Body
	accusation.TextSize = 14
	accusation.TextXAlignment = Enum.TextXAlignment.Left
	accusation.TextWrapped = true
	accusation.Parent = panel
	accusationLabel = accusation

	-- Objectif du joueur (coloré selon le rôle)
	local objFrame = Instance.new("Frame")
	objFrame.Size = UDim2.new(1, -24, 0, 52)
	objFrame.Position = UDim2.new(0, 12, 0, 306)
	objFrame.BackgroundColor3 = UIUtils.Color.Navy
	objFrame.BackgroundTransparency = 0.5
	objFrame.BorderSizePixel = 0
	objFrame.Parent = panel
	UIUtils.round(objFrame, 8)

	local objLabel = Instance.new("TextLabel")
	objLabel.Size = UDim2.new(1, -16, 1, 0)
	objLabel.Position = UDim2.new(0, 8, 0, 0)
	objLabel.BackgroundTransparency = 1
	objLabel.Text = ""
	objLabel.TextColor3 = UIUtils.Color.White
	objLabel.Font = UIUtils.Font.Title
	objLabel.TextSize = 14
	objLabel.TextXAlignment = Enum.TextXAlignment.Center
	objLabel.TextWrapped = true
	objLabel.Parent = objFrame
	objectiveLabel = objLabel
end

function IntroScreen.show(
	caseId: string,
	title: string,
	summary: string,
	accusation: string,
	roleObjective: string,
	role: string
)
	if not gui then
		return
	end

	if caseIdLabel then
		caseIdLabel.Text = "DOSSIER  " .. caseId:upper()
	end
	if titleLabel then
		titleLabel.Text = title:upper()
	end
	if summaryLabel then
		summaryLabel.Text = summary
	end
	if accusationLabel then
		accusationLabel.Text = accusation
	end
	if objectiveLabel then
		objectiveLabel.Text = "VOTRE OBJECTIF\n" .. roleObjective
		objectiveLabel.TextColor3 = ROLE_COLORS[role] or UIUtils.Color.White

		-- Colorer le fond de l'objectif selon le rôle
		local objFrame = objectiveLabel.Parent
		if objFrame and objFrame:IsA("Frame") then
			local roleColor = ROLE_COLORS[role] or UIUtils.Color.Navy
			objFrame.BackgroundColor3 = roleColor
		end
	end

	gui.Enabled = true

	-- Légère animation d'entrée
	if gui.Parent then
		local panel = gui:FindFirstChildWhichIsA("Frame", true)
		if panel and panel:IsA("Frame") then
			panel.Position = UDim2.new(0.5, -280, 0.6, -185)
			TweenService
				:Create(panel, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = UDim2.new(0.5, -280, 0.5, -185),
				})
				:Play()
		end
	end
end

function IntroScreen.hide()
	if gui then
		gui.Enabled = false
	end
end

return IntroScreen
