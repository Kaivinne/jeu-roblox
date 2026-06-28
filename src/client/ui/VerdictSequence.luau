--!strict
-- Séquence dramatique déclenchée à VerdictRevealed (M3.4).
-- Durée totale ≈ 1.71 s — non-bloquante (task.spawn).
-- Client uniquement ; aucun impact serveur ni gameplay.

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local UIUtils = require(script.Parent.UIUtils)

local VerdictSequence = {}

-- ─── Timing (total ≈ 1.71 s) ─────────────────────────────────────────────────

local T_FADE_IN = 0.25 -- fond sombre apparaît
local T_WORD_IN = 0.20 -- "VERDICT" s'affiche
local T_GAP = 0.15 -- pause avant le résultat
local T_RESULT_IN = 0.28 -- "COUPABLE" / "INNOCENT" entre
local T_HOLD = 0.55 -- maintien lisible
local T_FADE_OUT = 0.28 -- tout disparaît

-- ─── Palette ──────────────────────────────────────────────────────────────────

local GUILTY_COLOR = Color3.fromRGB(178, 28, 28)
local INNOCENT_COLOR = Color3.fromRGB(212, 175, 55)

-- ─── Éléments UI (lazy-init, créés une seule fois par session) ────────────────

local _gui: ScreenGui? = nil
local _overlay: Frame? = nil
local _container: Frame? = nil
local _glowFrame: Frame? = nil
local _wordLabel: TextLabel? = nil
local _resultLabel: TextLabel? = nil
local _isPlaying = false

local function ensureGui()
	if _gui then
		return
	end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

	local gui = Instance.new("ScreenGui")
	gui.Name = "VerdictSequenceGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 150 -- au-dessus de tous les panneaux (< Toast 200)
	gui.Enabled = false
	gui.Parent = playerGui
	_gui = gui

	-- Fond sombre (ne bouge jamais — arrière-plan fixe)
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 1
	overlay.Parent = gui
	_overlay = overlay

	-- Conteneur principal : texte + glow — c'est lui qui shake pour COUPABLE
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.ZIndex = 2
	container.Parent = gui
	_container = container

	-- Halo doré plein-écran (INNOCENT uniquement — flash qui pulse puis disparaît)
	local glow = Instance.new("Frame")
	glow.Name = "Glow"
	glow.Size = UDim2.new(1, 0, 1, 0)
	glow.BackgroundColor3 = INNOCENT_COLOR
	glow.BackgroundTransparency = 1
	glow.BorderSizePixel = 0
	glow.ZIndex = 1
	glow.Parent = container
	_glowFrame = glow

	-- "VERDICT" — sobre, muted, positionné légèrement au-dessus du centre
	local wordLabel = Instance.new("TextLabel")
	wordLabel.Name = "WordLabel"
	wordLabel.Size = UDim2.new(1, 0, 0, 44)
	wordLabel.Position = UDim2.new(0, 0, 0.41, 0)
	wordLabel.BackgroundTransparency = 1
	wordLabel.Text = "VERDICT"
	wordLabel.TextColor3 = UIUtils.Color.Muted
	wordLabel.TextTransparency = 1
	wordLabel.Font = UIUtils.Font.Body
	wordLabel.TextSize = 20
	wordLabel.TextXAlignment = Enum.TextXAlignment.Center
	wordLabel.ZIndex = 2
	wordLabel.Parent = container
	_wordLabel = wordLabel

	-- "COUPABLE" / "INNOCENT" — grand, impactant, TextScaled pour mobile
	local resultLabel = Instance.new("TextLabel")
	resultLabel.Name = "ResultLabel"
	resultLabel.Size = UDim2.new(0.9, 0, 0, 88)
	resultLabel.Position = UDim2.new(0.05, 0, 0.47, 0)
	resultLabel.BackgroundTransparency = 1
	resultLabel.Text = ""
	resultLabel.TextTransparency = 1
	resultLabel.Font = UIUtils.Font.Title
	resultLabel.TextSize = 56
	resultLabel.TextScaled = true
	resultLabel.TextXAlignment = Enum.TextXAlignment.Center
	resultLabel.ZIndex = 3
	resultLabel.Parent = container
	_resultLabel = resultLabel
end

-- ─── Helpers ──────────────────────────────────────────────────────────────────

local function tw(obj: GuiObject, info: TweenInfo, props: { [string]: any })
	TweenService:Create(obj, info, props):Play()
end

-- Micro-shake du container : 6 déplacements aléatoires ± intensity pixels.
local function doShake(container: Frame, intensity: number)
	local rng = Random.new()
	for _ = 1, 6 do
		local dx = (rng:NextNumber() * 2 - 1) * intensity
		local dy = (rng:NextNumber() * 2 - 1) * intensity * 0.38
		TweenService:Create(container, TweenInfo.new(0.035, Enum.EasingStyle.Quad), {
			Position = UDim2.new(0, dx, 0, dy),
		}):Play()
		task.wait(0.04)
	end
	-- Retour au centre
	TweenService:Create(container, TweenInfo.new(0.07, Enum.EasingStyle.Quad), {
		Position = UDim2.new(0, 0, 0, 0),
	}):Play()
end

-- ─── API publique ─────────────────────────────────────────────────────────────

-- Joue la séquence de verdict puis appelle onComplete.
-- verdict : "Guilty" | "Innocent"
-- onComplete : appelé une fois la séquence terminée (affiche SummaryScreen)
function VerdictSequence.play(verdict: string, onComplete: () -> ())
	if _isPlaying then
		return
	end
	ensureGui()

	local gui = _gui :: ScreenGui
	local overlay = _overlay :: Frame
	local container = _container :: Frame
	local glow = _glowFrame :: Frame
	local wordLabel = _wordLabel :: TextLabel
	local resultLabel = _resultLabel :: TextLabel

	local isGuilty = verdict == "Guilty"

	-- ── Reset de l'état pour éviter tout artefact de séquence précédente ──────
	overlay.BackgroundTransparency = 1
	container.Position = UDim2.new(0, 0, 0, 0)
	glow.BackgroundTransparency = 1
	wordLabel.TextTransparency = 1
	resultLabel.TextTransparency = 1
	resultLabel.Text = if isGuilty then "COUPABLE" else "INNOCENT"
	resultLabel.TextColor3 = if isGuilty then GUILTY_COLOR else INNOCENT_COLOR

	gui.Enabled = true

	task.spawn(function()
		_isPlaying = true
		-- 1. Fond sombre
		tw(overlay, TweenInfo.new(T_FADE_IN, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.14,
		})
		task.wait(T_FADE_IN)

		-- 2. "VERDICT" sobre
		tw(wordLabel, TweenInfo.new(T_WORD_IN, Enum.EasingStyle.Quad), {
			TextTransparency = 0.25,
		})
		task.wait(T_WORD_IN + T_GAP)

		-- 3. Résultat + effet spécifique
		tw(resultLabel, TweenInfo.new(T_RESULT_IN, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			TextTransparency = 0,
		})

		if isGuilty then
			-- Shake court et brutal (impact visuel gavel)
			task.spawn(function()
				doShake(container, 9)
			end)
		else
			-- Flash doré : apparaît puis se dissipe (halo triomphant)
			tw(glow, TweenInfo.new(0.16, Enum.EasingStyle.Quad), {
				BackgroundTransparency = 0.72,
			})
			task.delay(0.22, function()
				tw(glow, TweenInfo.new(0.40, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					BackgroundTransparency = 1,
				})
			end)
		end

		task.wait(T_RESULT_IN + T_HOLD)

		-- 4. Tout disparaît proprement
		local fadeInfo = TweenInfo.new(T_FADE_OUT, Enum.EasingStyle.Quad)
		tw(overlay, fadeInfo, { BackgroundTransparency = 1 })
		tw(wordLabel, fadeInfo, { TextTransparency = 1 })
		tw(resultLabel, fadeInfo, { TextTransparency = 1 })
		task.wait(T_FADE_OUT)

		gui.Enabled = false
		_isPlaying = false
		onComplete()
	end)
end

return VerdictSequence
