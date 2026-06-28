--!strict
-- Écran de résumé post-partie : vérité officielle, déclaration du témoin,
-- verdict du joueur, récompense, bouton Rejouer.
-- Affiché pour tous les rôles à la phase PostVerdict.
-- Le bouton Rejouer masque l'écran — le serveur gère le redémarrage automatique.

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local UIUtils = require(script.Parent.UIUtils)

local SummaryScreen = {}

local gui: ScreenGui? = nil
local _bg: Frame? = nil
local caseTitleLabel: TextLabel? = nil
local truthContainer: ScrollingFrame? = nil
local witnessDeclLabel: TextLabel? = nil
local witnessStatusLabel: TextLabel? = nil
local playerVerdictLabel: TextLabel? = nil
local correctLabel: TextLabel? = nil
local rewardLabel: TextLabel? = nil
local twistLabel: TextLabel? = nil
local mainPanel: Frame? = nil

function SummaryScreen.setup()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

	local screen = Instance.new("ScreenGui")
	screen.Name = "SummaryScreenGui"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 50
	screen.Enabled = false
	screen.Parent = playerGui
	gui = screen

	-- Fond assombri
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(5, 5, 14)
	bg.BackgroundTransparency = 0.2
	bg.BorderSizePixel = 0
	bg.Parent = screen
	_bg = bg

	-- Panneau principal
	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0, 620, 0, 500)
	panel.Position = UDim2.new(0.5, -310, 0.5, -250)
	panel.BackgroundColor3 = Color3.fromRGB(12, 12, 24)
	panel.BorderSizePixel = 0
	panel.Parent = screen
	UIUtils.round(panel, 16)
	UIUtils.stroke(panel, UIUtils.Color.Gold, 2)
	UIUtils.responsivePanel(panel, 620)
	UIUtils.panelGradient(panel)
	mainPanel = panel

	-- En-tête
	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, -24, 0, 24)
	header.Position = UDim2.new(0, 12, 0, 12)
	header.BackgroundTransparency = 1
	header.Text = "RÉSUMÉ DE LA PARTIE"
	header.TextColor3 = UIUtils.Color.Gold
	header.Font = UIUtils.Font.Title
	header.TextSize = 12
	header.TextXAlignment = Enum.TextXAlignment.Center
	header.Parent = panel

	local caseLbl = Instance.new("TextLabel")
	caseLbl.Size = UDim2.new(1, -24, 0, 26)
	caseLbl.Position = UDim2.new(0, 12, 0, 36)
	caseLbl.BackgroundTransparency = 1
	caseLbl.Text = ""
	caseLbl.TextColor3 = UIUtils.Color.Ivory
	caseLbl.Font = UIUtils.Font.Title
	caseLbl.TextSize = 17
	caseLbl.TextXAlignment = Enum.TextXAlignment.Center
	caseLbl.Parent = panel
	caseTitleLabel = caseLbl

	-- Séparateur 1
	local sep1 = Instance.new("Frame")
	sep1.Size = UDim2.new(1, -24, 0, 1)
	sep1.Position = UDim2.new(0, 12, 0, 68)
	sep1.BackgroundColor3 = UIUtils.Color.Gold
	sep1.BackgroundTransparency = 0.55
	sep1.BorderSizePixel = 0
	sep1.Parent = panel

	-- Section Vérité officielle
	local truthHeader = Instance.new("TextLabel")
	truthHeader.Size = UDim2.new(1, -24, 0, 16)
	truthHeader.Position = UDim2.new(0, 12, 0, 76)
	truthHeader.BackgroundTransparency = 1
	truthHeader.Text = "VÉRITÉ OFFICIELLE"
	truthHeader.TextColor3 = UIUtils.Color.Gold
	truthHeader.Font = UIUtils.Font.Title
	truthHeader.TextSize = 11
	truthHeader.TextXAlignment = Enum.TextXAlignment.Left
	truthHeader.Parent = panel

	local tContainer = Instance.new("ScrollingFrame")
	tContainer.Name = "TruthRows"
	tContainer.Size = UDim2.new(1, -24, 0, 100)
	tContainer.Position = UDim2.new(0, 12, 0, 94)
	tContainer.BackgroundTransparency = 1
	tContainer.BorderSizePixel = 0
	tContainer.ScrollBarThickness = 4
	tContainer.ScrollBarImageColor3 = UIUtils.Color.Gold
	tContainer.ScrollingDirection = Enum.ScrollingDirection.Y
	tContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	tContainer.Parent = panel
	local tLayout = Instance.new("UIListLayout")
	tLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tLayout.Padding = UDim.new(0, 4)
	tLayout.Parent = tContainer
	-- Adapte le canvas au contenu réel
	tLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		tContainer.CanvasSize = UDim2.new(0, 0, 0, tLayout.AbsoluteContentSize.Y + 4)
	end)
	truthContainer = tContainer

	-- Séparateur 2
	local sep2 = Instance.new("Frame")
	sep2.Size = UDim2.new(1, -24, 0, 1)
	sep2.Position = UDim2.new(0, 12, 0, 198)
	sep2.BackgroundColor3 = UIUtils.Color.Charcoal
	sep2.BorderSizePixel = 0
	sep2.Parent = panel

	-- Section Déclaration du témoin
	local wHeader = Instance.new("TextLabel")
	wHeader.Size = UDim2.new(1, -24, 0, 16)
	wHeader.Position = UDim2.new(0, 12, 0, 206)
	wHeader.BackgroundTransparency = 1
	wHeader.Text = "DÉCLARATION DU TÉMOIN"
	wHeader.TextColor3 = UIUtils.Color.Gold
	wHeader.Font = UIUtils.Font.Title
	wHeader.TextSize = 11
	wHeader.TextXAlignment = Enum.TextXAlignment.Left
	wHeader.Parent = panel

	local wDeclLbl = Instance.new("TextLabel")
	wDeclLbl.Size = UDim2.new(0.65, 0, 0, 26)
	wDeclLbl.Position = UDim2.new(0, 12, 0, 224)
	wDeclLbl.BackgroundTransparency = 1
	wDeclLbl.Text = "—"
	wDeclLbl.TextColor3 = UIUtils.Color.Ivory
	wDeclLbl.Font = UIUtils.Font.Title
	wDeclLbl.TextSize = 14
	wDeclLbl.TextXAlignment = Enum.TextXAlignment.Left
	wDeclLbl.Parent = panel
	witnessDeclLabel = wDeclLbl

	local wStatusLbl = Instance.new("TextLabel")
	wStatusLbl.Size = UDim2.new(0.34, 0, 0, 26)
	wStatusLbl.Position = UDim2.new(0.65, 0, 0, 224)
	wStatusLbl.BackgroundTransparency = 1
	wStatusLbl.Text = ""
	wStatusLbl.Font = UIUtils.Font.Title
	wStatusLbl.TextSize = 14
	wStatusLbl.TextXAlignment = Enum.TextXAlignment.Right
	wStatusLbl.Parent = panel
	witnessStatusLabel = wStatusLbl

	-- Séparateur 3
	local sep3 = Instance.new("Frame")
	sep3.Size = UDim2.new(1, -24, 0, 1)
	sep3.Position = UDim2.new(0, 12, 0, 262)
	sep3.BackgroundColor3 = UIUtils.Color.Charcoal
	sep3.BorderSizePixel = 0
	sep3.Parent = panel

	-- Section Verdict du joueur
	local pvLbl = Instance.new("TextLabel")
	pvLbl.Size = UDim2.new(1, -24, 0, 30)
	pvLbl.Position = UDim2.new(0, 12, 0, 270)
	pvLbl.BackgroundTransparency = 1
	pvLbl.Text = ""
	pvLbl.TextColor3 = UIUtils.Color.Ivory
	pvLbl.Font = UIUtils.Font.Title
	pvLbl.TextSize = 16
	pvLbl.TextXAlignment = Enum.TextXAlignment.Left
	pvLbl.Parent = panel
	playerVerdictLabel = pvLbl

	local corrLbl = Instance.new("TextLabel")
	corrLbl.Size = UDim2.new(0.6, 0, 0, 26)
	corrLbl.Position = UDim2.new(0, 12, 0, 304)
	corrLbl.BackgroundTransparency = 1
	corrLbl.Text = ""
	corrLbl.Font = UIUtils.Font.Title
	corrLbl.TextSize = 15
	corrLbl.TextXAlignment = Enum.TextXAlignment.Left
	corrLbl.Parent = panel
	correctLabel = corrLbl

	local rewLbl = Instance.new("TextLabel")
	rewLbl.Size = UDim2.new(0.38, 0, 0, 26)
	rewLbl.Position = UDim2.new(0.61, 0, 0, 304)
	rewLbl.BackgroundTransparency = 1
	rewLbl.Text = ""
	rewLbl.TextColor3 = UIUtils.Color.Gold
	rewLbl.Font = UIUtils.Font.Title
	rewLbl.TextSize = 18
	rewLbl.TextXAlignment = Enum.TextXAlignment.Right
	rewLbl.Parent = panel
	rewardLabel = rewLbl

	-- Séparateur final
	local sep4 = Instance.new("Frame")
	sep4.Size = UDim2.new(1, -24, 0, 1)
	sep4.Position = UDim2.new(0, 12, 0, 342)
	sep4.BackgroundColor3 = UIUtils.Color.Gold
	sep4.BackgroundTransparency = 0.55
	sep4.BorderSizePixel = 0
	sep4.Parent = panel

	-- Twist narratif (révélé en PostVerdict)
	local twistLbl = Instance.new("TextLabel")
	twistLbl.Size = UDim2.new(1, -32, 0, 36)
	twistLbl.Position = UDim2.new(0, 16, 0, 350)
	twistLbl.BackgroundTransparency = 1
	twistLbl.Text = ""
	twistLbl.TextColor3 = UIUtils.Color.Muted
	twistLbl.Font = UIUtils.Font.Body
	twistLbl.TextSize = 12
	twistLbl.TextXAlignment = Enum.TextXAlignment.Center
	twistLbl.TextWrapped = true
	twistLbl.Visible = false
	twistLbl.Parent = panel
	twistLabel = twistLbl

	-- Bouton Rejouer
	local replayBtn = Instance.new("TextButton")
	replayBtn.Size = UDim2.new(0.55, 0, 0, 54)
	replayBtn.Position = UDim2.new(0.225, 0, 0, 396)
	replayBtn.BackgroundColor3 = UIUtils.Color.Navy
	replayBtn.BorderSizePixel = 0
	replayBtn.Text = "REJOUER"
	replayBtn.TextColor3 = UIUtils.Color.White
	replayBtn.Font = UIUtils.Font.Title
	replayBtn.TextSize = 18
	replayBtn.AutoButtonColor = false
	replayBtn.Parent = panel
	UIUtils.round(replayBtn, 12)
	UIUtils.stroke(replayBtn, UIUtils.Color.Gold, 1)
	UIUtils.buttonGradient(replayBtn)

	replayBtn.MouseButton1Click:Connect(function()
		SummaryScreen.hide()
	end)
	UIUtils.hoverButton(replayBtn)
end

-- Affiche l'écran de résumé avec toutes les données de la partie.
-- playerVote : "Guilty" | "Innocent" | "" (pas voté)
-- isCorrect  : nil si le joueur n'est pas Juré ou n'a pas voté
-- guiltyCount : nombre de votes COUPABLE
function SummaryScreen.show(
	caseTitle: string,
	truthSummary: { { Key: string, Value: string } },
	witnessDecl: { string },
	witnessLied: boolean,
	playerVote: string,
	isCorrect: boolean?,
	role: string,
	guiltyCount: number,
	twist: string,
	verdict: string
)
	if not gui then
		return
	end
	gui.Enabled = true

	-- Fond : fade-in depuis transparent
	if _bg then
		_bg.BackgroundTransparency = 1
		UIUtils.fadeBg(_bg, 0.20, 0.25)
	end
	-- Panneau : slide depuis le bas
	local p = mainPanel
	if p then
		UIUtils.animateIn(p, "bottom", 0.30)
	end

	if caseTitleLabel then
		caseTitleLabel.Text = caseTitle:upper()
	end

	-- Vérité officielle
	if truthContainer then
		for _, child in ipairs(truthContainer:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		for _, entry in ipairs(truthSummary) do
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, 0, 0, 26)
			row.BackgroundColor3 = Color3.fromRGB(18, 32, 18)
			row.BackgroundTransparency = 0.35
			row.BorderSizePixel = 0
			row.Parent = truthContainer
			UIUtils.round(row, 6)

			local kLbl = Instance.new("TextLabel")
			kLbl.Size = UDim2.new(0.52, 0, 1, 0)
			kLbl.Position = UDim2.new(0, 8, 0, 0)
			kLbl.BackgroundTransparency = 1
			kLbl.Text = entry.Key
			kLbl.TextColor3 = UIUtils.Color.Muted
			kLbl.Font = UIUtils.Font.Body
			kLbl.TextSize = 12
			kLbl.TextXAlignment = Enum.TextXAlignment.Left
			kLbl.Parent = row

			local vLbl = Instance.new("TextLabel")
			vLbl.Size = UDim2.new(0.47, -8, 1, 0)
			vLbl.Position = UDim2.new(0.52, 0, 0, 0)
			vLbl.BackgroundTransparency = 1
			vLbl.Text = entry.Value
			vLbl.TextColor3 = UIUtils.Color.Success
			vLbl.Font = UIUtils.Font.Title
			vLbl.TextSize = 13
			vLbl.TextXAlignment = Enum.TextXAlignment.Left
			vLbl.Parent = row
		end
	end

	-- Déclaration du témoin
	if witnessDeclLabel then
		witnessDeclLabel.Text = if #witnessDecl > 0
			then table.concat(witnessDecl, " · ")
			else "Le témoin n'a pas déclaré."
	end
	if witnessStatusLabel then
		if #witnessDecl > 0 then
			if witnessLied then
				witnessStatusLabel.Text = "MENSONGE"
				witnessStatusLabel.TextColor3 = UIUtils.Color.Crimson
			else
				witnessStatusLabel.Text = "VÉRITÉ"
				witnessStatusLabel.TextColor3 = UIUtils.Color.Success
			end
		else
			witnessStatusLabel.Text = ""
		end
	end

	-- Verdict du joueur (contenu adapté selon le rôle)
	if playerVerdictLabel then
		if role == "Juror" then
			if playerVote == "Guilty" then
				playerVerdictLabel.Text = "VOTRE VERDICT : COUPABLE"
				playerVerdictLabel.TextColor3 = UIUtils.Color.Crimson
			elseif playerVote == "Innocent" then
				playerVerdictLabel.Text = "VOTRE VERDICT : INNOCENT"
				playerVerdictLabel.TextColor3 = UIUtils.Color.Success
			else
				playerVerdictLabel.Text = "Vous n'avez pas voté — vote non comptabilisé."
				playerVerdictLabel.TextColor3 = UIUtils.Color.Muted
			end
		elseif role == "HonestWitness" then
			playerVerdictLabel.Text = "Vous avez témoigné honnêtement."
			playerVerdictLabel.TextColor3 = UIUtils.Color.Success
		elseif role == "Liar" then
			playerVerdictLabel.Text = "Vous étiez le Menteur."
			playerVerdictLabel.TextColor3 = UIUtils.Color.Crimson
		else
			local isGuilty = verdict == "Guilty"
			playerVerdictLabel.Text = if isGuilty
				then string.format("Verdict collectif : COUPABLE (%d vote(s))", guiltyCount)
				else string.format("Verdict collectif : INNOCENT (%d vote(s))", guiltyCount)
			playerVerdictLabel.TextColor3 = if isGuilty then UIUtils.Color.Crimson else UIUtils.Color.Success
		end
	end

	-- Correct/incorrect (Jurés uniquement)
	if correctLabel then
		if isCorrect == true then
			correctLabel.Text = "✓ Verdict correct !"
			correctLabel.TextColor3 = UIUtils.Color.Success
		elseif isCorrect == false then
			correctLabel.Text = "✗ Verdict incorrect."
			correctLabel.TextColor3 = UIUtils.Color.Crimson
		else
			correctLabel.Text = ""
		end
	end

	-- Vibration visuelle du panneau sur verdict incorrect.
	-- Délai = durée de animateIn (0.30s) pour ne pas lire la position décalée
	-- et ne pas entrer en conflit avec le tween d'entrée.
	if isCorrect == false then
		task.delay(0.32, function()
			local shakePanel = mainPanel
			if shakePanel == nil then
				return
			end
			local base = shakePanel.Position
			local xs = base.X.Scale
			local ox = base.X.Offset
			local ys = base.Y.Scale
			local oy = base.Y.Offset
			TweenService:Create(shakePanel, TweenInfo.new(0.07, Enum.EasingStyle.Sine), {
				Position = UDim2.new(xs, ox - 8, ys, oy),
			}):Play()
			task.delay(0.07, function()
				TweenService:Create(shakePanel, TweenInfo.new(0.07, Enum.EasingStyle.Sine), {
					Position = UDim2.new(xs, ox + 8, ys, oy),
				}):Play()
				task.delay(0.07, function()
					TweenService:Create(shakePanel, TweenInfo.new(0.09, Enum.EasingStyle.Sine), {
						Position = UDim2.new(xs, ox, ys, oy),
					}):Play()
				end)
			end)
		end)
	end

	-- Twist narratif
	if twistLabel then
		if twist ~= "" then
			twistLabel.Text = "« " .. twist .. " »"
			twistLabel.Visible = true
		else
			twistLabel.Text = ""
			twistLabel.Visible = false
		end
	end

	-- Récompense — affiche la valeur déjà reçue ou un placeholder en attente
	if rewardLabel then
		if rewardLabel.Text == "" then
			rewardLabel.Text = "…"
		end
	end
end

-- Met à jour le montant de Jetons (appelé quand RewardGranted arrive)
function SummaryScreen.setReward(jetons: number)
	if rewardLabel then
		rewardLabel.Text = string.format("+%d Jetons", jetons)
	end
end

function SummaryScreen.hide()
	local g = gui
	if not g then
		return
	end
	-- Remet le label à "" pour que le prochain show() sache qu'aucune récompense n'a encore été reçue
	if rewardLabel then
		rewardLabel.Text = ""
	end
	-- Slide vers le bas + fade du fond, puis masque
	if _bg then
		UIUtils.fadeBg(_bg, 1, 0.18)
	end
	local p = mainPanel
	if p then
		UIUtils.animateOut(p, function()
			g.Enabled = false
		end, 0.18)
	else
		g.Enabled = false
	end
end

return SummaryScreen
