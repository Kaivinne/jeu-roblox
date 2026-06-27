--!strict
-- Écran de vote (phase Verdict) et révélation de la vérité (phase PostVerdict).
-- Deux états : vote actif et résultat + révélation.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Net = require(Shared.Net)
local RemoteNames = require(Shared.RemoteNames)

local UIUtils = require(script.Parent.UIUtils)

local VerdictScreen = {}

local gui: ScreenGui? = nil
local _bg: Frame? = nil

-- Panneau de vote (Verdict)
local votingPanel: Frame? = nil
local guiltyBtn: TextButton? = nil
local innocentBtn: TextButton? = nil
local confirmLabel: TextLabel? = nil
local hasVoted = false
local lastVote: string = ""
local voteCastCallback: (() -> ())? = nil

-- Panneau de résultat (PostVerdict)
local resultPanel: Frame? = nil
local verdictResultLabel: TextLabel? = nil
local caseRevealTitle: TextLabel? = nil
local truthContainer: Frame? = nil
local liarStatusLabel: TextLabel? = nil

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
	lastVote = vote

	-- Pulse visuel sur le bouton voté
	local btn = if vote == "Guilty" then guiltyBtn else innocentBtn
	if btn then
		local b = btn
		local origSize = b.Size
		TweenService
			:Create(b, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(origSize.X.Scale, origSize.X.Offset, origSize.Y.Scale, origSize.Y.Offset + 8),
			})
			:Play()
		task.delay(0.25, function()
			TweenService:Create(b, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { Size = origSize }):Play()
		end)
	end

	fireServer(RemoteNames.VoteCast, { Vote = vote })
	lockButtons()

	if voteCastCallback ~= nil then
		voteCastCallback()
	end

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

	-- ── Fond commun ──────────────────────────────────────────────────────────
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(6, 6, 14)
	bg.BackgroundTransparency = 0.3
	bg.BorderSizePixel = 0
	bg.Parent = screen
	_bg = bg

	-- ── Panneau de VOTE ───────────────────────────────────────────────────────
	local vPanel = Instance.new("Frame")
	vPanel.Name = "VotingPanel"
	vPanel.Size = UDim2.new(0, 480, 0, 260)
	vPanel.Position = UDim2.new(0.5, -240, 0.5, -130)
	vPanel.BackgroundColor3 = Color3.fromRGB(14, 14, 26)
	vPanel.BorderSizePixel = 0
	vPanel.Parent = screen
	UIUtils.round(vPanel, 16)
	UIUtils.stroke(vPanel, UIUtils.Color.Gold, 2)
	UIUtils.responsivePanel(vPanel, 480)
	votingPanel = vPanel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -24, 0, 40)
	title.Position = UDim2.new(0, 12, 0, 16)
	title.BackgroundTransparency = 1
	title.Text = "QUI MENTAIT ?"
	title.TextColor3 = UIUtils.Color.Gold
	title.Font = UIUtils.Font.Title
	title.TextSize = 22
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = vPanel

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, -24, 0, 24)
	subtitle.Position = UDim2.new(0, 12, 0, 54)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Rendez votre verdict avant la fin du décompte."
	subtitle.TextColor3 = UIUtils.Color.Muted
	subtitle.Font = UIUtils.Font.Body
	subtitle.TextSize = 13
	subtitle.TextXAlignment = Enum.TextXAlignment.Center
	subtitle.Parent = vPanel

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
	guilty.Parent = vPanel
	UIUtils.round(guilty, 12)
	guiltyBtn = guilty

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
	innocent.Parent = vPanel
	UIUtils.round(innocent, 12)
	innocentBtn = innocent

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
	confirm.Parent = vPanel
	confirmLabel = confirm

	guilty.MouseButton1Click:Connect(function()
		onVote("Guilty")
	end)
	innocent.MouseButton1Click:Connect(function()
		onVote("Innocent")
	end)
	-- Pas de hoverButton ici : lockButtons() tweene BackgroundTransparency à 0.6
	-- après le vote, ce qui entre en conflit avec la valeur base=0 capturée par hover.

	-- ── Panneau de RÉSULTAT ───────────────────────────────────────────────────
	local rPanel = Instance.new("Frame")
	rPanel.Name = "ResultPanel"
	rPanel.Size = UDim2.new(0, 520, 0, 390)
	rPanel.Position = UDim2.new(0.5, -260, 0.5, -195)
	rPanel.BackgroundColor3 = Color3.fromRGB(14, 14, 26)
	rPanel.BorderSizePixel = 0
	rPanel.Visible = false
	rPanel.Parent = screen
	UIUtils.round(rPanel, 16)
	UIUtils.stroke(rPanel, UIUtils.Color.Gold, 2)
	UIUtils.responsivePanel(rPanel, 520)
	resultPanel = rPanel

	local vResultLabel = Instance.new("TextLabel")
	vResultLabel.Size = UDim2.new(1, -24, 0, 54)
	vResultLabel.Position = UDim2.new(0, 12, 0, 14)
	vResultLabel.BackgroundTransparency = 1
	vResultLabel.Text = ""
	vResultLabel.Font = UIUtils.Font.Title
	vResultLabel.TextSize = 26
	vResultLabel.TextXAlignment = Enum.TextXAlignment.Center
	vResultLabel.Parent = rPanel
	verdictResultLabel = vResultLabel

	local sep = Instance.new("Frame")
	sep.Size = UDim2.new(1, -24, 0, 1)
	sep.Position = UDim2.new(0, 12, 0, 76)
	sep.BackgroundColor3 = UIUtils.Color.Gold
	sep.BackgroundTransparency = 0.5
	sep.BorderSizePixel = 0
	sep.Parent = rPanel

	local caseTitleLabel = Instance.new("TextLabel")
	caseTitleLabel.Size = UDim2.new(1, -24, 0, 28)
	caseTitleLabel.Position = UDim2.new(0, 12, 0, 86)
	caseTitleLabel.BackgroundTransparency = 1
	caseTitleLabel.Text = "LA VÉRITÉ"
	caseTitleLabel.TextColor3 = UIUtils.Color.Gold
	caseTitleLabel.Font = UIUtils.Font.Title
	caseTitleLabel.TextSize = 13
	caseTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	caseTitleLabel.Parent = rPanel
	caseRevealTitle = caseTitleLabel

	-- Conteneur des lignes de vérité
	local tContainer = Instance.new("Frame")
	tContainer.Name = "TruthContainer"
	tContainer.Size = UDim2.new(1, -24, 0, 140)
	tContainer.Position = UDim2.new(0, 12, 0, 118)
	tContainer.BackgroundTransparency = 1
	tContainer.Parent = rPanel
	truthContainer = tContainer

	local tLayout = Instance.new("UIListLayout")
	tLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tLayout.Padding = UDim.new(0, 4)
	tLayout.Parent = tContainer

	local sep2 = Instance.new("Frame")
	sep2.Size = UDim2.new(1, -24, 0, 1)
	sep2.Position = UDim2.new(0, 12, 0, 270)
	sep2.BackgroundColor3 = UIUtils.Color.Charcoal
	sep2.BorderSizePixel = 0
	sep2.Parent = rPanel

	local liarStatus = Instance.new("TextLabel")
	liarStatus.Size = UDim2.new(1, -24, 0, 90)
	liarStatus.Position = UDim2.new(0, 12, 0, 280)
	liarStatus.BackgroundTransparency = 1
	liarStatus.Text = ""
	liarStatus.Font = UIUtils.Font.Body
	liarStatus.TextSize = 14
	liarStatus.TextXAlignment = Enum.TextXAlignment.Center
	liarStatus.TextWrapped = true
	liarStatus.Parent = rPanel
	liarStatusLabel = liarStatus
end

function VerdictScreen.show()
	if not gui then
		return
	end
	gui.Enabled = true
	hasVoted = false
	lastVote = ""

	-- Fond : fade-in depuis transparent
	if _bg then
		_bg.BackgroundTransparency = 1
		UIUtils.fadeBg(_bg, 0.30, 0.22)
	end

	if votingPanel then
		votingPanel.Visible = true
		UIUtils.animateIn(votingPanel, "bottom", 0.28)
	end
	if resultPanel then
		resultPanel.Visible = false
	end

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

function VerdictScreen.hide()
	if gui then
		gui.Enabled = false
	end
end

-- Affiche le verdict collectif (votes) — appelé à PostVerdict
function VerdictScreen.showResult(verdict: string, guiltyCount: number)
	if not gui then
		return
	end
	gui.Enabled = true

	if votingPanel then
		votingPanel.Visible = false
	end
	if resultPanel then
		resultPanel.Visible = true
		UIUtils.animateIn(resultPanel, "bottom", 0.32)
	end

	if verdictResultLabel then
		local isGuilty = verdict == "Guilty"
		verdictResultLabel.Text = isGuilty and string.format("COUPABLE  (%d vote(s))", guiltyCount)
			or string.format("INNOCENT  (%d vote(s))", guiltyCount)
		verdictResultLabel.TextColor3 = isGuilty and UIUtils.Color.Crimson or UIUtils.Color.Success
	end
end

-- Révèle la vérité de l'affaire et le comportement du Menteur
-- truthSummary : { { Key: string, Value: string } }
-- liarDeclaration : { string } — ce que le Menteur a déclaré
function VerdictScreen.showTruth(
	caseTitle: string,
	truthSummary: { { Key: string, Value: string } },
	liarUserId: number,
	liarLied: boolean,
	liarDeclaration: { string }
)
	if caseRevealTitle then
		caseRevealTitle.Text = "LA VÉRITÉ — " .. caseTitle:upper()
	end

	-- Reconstruire les lignes de vérité
	if truthContainer then
		for _, child in ipairs(truthContainer:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		for _, entry in ipairs(truthSummary) do
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, 0, 0, 30)
			row.BackgroundColor3 = Color3.fromRGB(20, 30, 20)
			row.BackgroundTransparency = 0.4
			row.BorderSizePixel = 0
			row.Parent = truthContainer
			UIUtils.round(row, 6)

			local keyLbl = Instance.new("TextLabel")
			keyLbl.Size = UDim2.new(0.45, 0, 1, 0)
			keyLbl.Position = UDim2.new(0, 8, 0, 0)
			keyLbl.BackgroundTransparency = 1
			keyLbl.Text = entry.Key
			keyLbl.TextColor3 = UIUtils.Color.Muted
			keyLbl.Font = UIUtils.Font.Body
			keyLbl.TextSize = 12
			keyLbl.TextXAlignment = Enum.TextXAlignment.Left
			keyLbl.Parent = row

			local valLbl = Instance.new("TextLabel")
			valLbl.Size = UDim2.new(0.55, -8, 1, 0)
			valLbl.Position = UDim2.new(0.45, 0, 0, 0)
			valLbl.BackgroundTransparency = 1
			valLbl.Text = entry.Value
			valLbl.TextColor3 = UIUtils.Color.Success
			valLbl.Font = UIUtils.Font.Title
			valLbl.TextSize = 13
			valLbl.TextXAlignment = Enum.TextXAlignment.Left
			valLbl.Parent = row
		end
	end

	if liarStatusLabel then
		if liarUserId == 0 then
			liarStatusLabel.Text = "Aucun Menteur identifié dans cette partie."
			liarStatusLabel.TextColor3 = UIUtils.Color.Muted
		elseif liarLied then
			local declText = #liarDeclaration > 0 and table.concat(liarDeclaration, " · ") or "—"
			liarStatusLabel.Text = "Le Menteur a bien menti.\nIl a déclaré : " .. declText
			liarStatusLabel.TextColor3 = UIUtils.Color.Crimson
		else
			liarStatusLabel.Text = "Le Menteur a dit la vérité — ou n'a pas déclaré."
			liarStatusLabel.TextColor3 = UIUtils.Color.Gold
		end
	end
end

-- Retourne le dernier vote du joueur ("Guilty", "Innocent", ou "" si pas encore voté)
function VerdictScreen.getLastVote(): string
	return lastVote
end

-- Enregistre un callback appelé immédiatement après qu'un vote soit soumis.
function VerdictScreen.setOnVoteCast(cb: () -> ())
	voteCastCallback = cb
end

return VerdictScreen
