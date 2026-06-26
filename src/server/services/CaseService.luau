--!strict
-- Catalogue des affaires jouables.
-- Milestone 2.0 : 3 affaires, sélection aléatoire.
-- Milestone 2.1 : Difficulty, Theme, Twist + anti-répétition (lastCaseId).

local CaseService = {}

-- ─── Types internes ────────────────────────────────────────────────────────────

type CaseField = {
	Key: string,
	Label: string,
	Options: { string },
	TruthIndex: number, -- 1-based
}

type CaseData = {
	Id: string,
	Title: string,
	Summary: string,
	Accusation: string,
	Fields: { CaseField },
	LiarHint: string,
	Difficulty: string, -- "Easy" | "Medium" | "Hard"
	Theme: string, -- ex: "Famille", "Cinéma", "Bureau"
	Twist: string, -- Phrase courte révélée en PostVerdict
}

-- ─── Catalogue ────────────────────────────────────────────────────────────────

local CASE_LIBRARY: { CaseData } = {
	-- ── Affaire 1 : Le Collier Disparu ────────────────────────────────────────
	{
		Id = "case_001",
		Title = "Le Collier Disparu",
		Summary = "Durant la réunion de famille des Moreau, un collier de famille a disparu du grenier. "
			.. "Quelqu'un n'était pas là où il le prétend.",
		Accusation = "L'accusé affirme avoir un alibi solide. "
			.. "Il prétend ne pas s'être approché du grenier ce jour-là.",
		Fields = {
			{
				Key = "Lieu",
				Label = "OÙ ÉTIEZ-VOUS ?",
				Options = { "Cuisine", "Salon", "Jardin", "Grenier", "Garage" },
				TruthIndex = 3, -- Jardin
			},
			{
				Key = "Personne",
				Label = "AVEC QUI ?",
				Options = { "Seul(e)", "Avec Sophie", "Avec Marc", "En groupe" },
				TruthIndex = 1, -- Seul(e)
			},
			{
				Key = "Heure",
				Label = "À QUELLE HEURE ?",
				Options = { "10h00", "12h00", "14h00", "16h00" },
				TruthIndex = 3, -- 14h00
			},
		},
		LiarHint = "Vrai alibi : Jardin · Seul(e) · 14h00\nMentez sur au moins un champ.",
		Difficulty = "Medium",
		Theme = "Famille",
		Twist = "Le collier a été retrouvé dans la doublure du manteau de l'accusé.",
	},

	-- ── Affaire 2 : Le Ticket Déchiré ────────────────────────────────────────
	{
		Id = "case_002",
		Title = "Le Ticket Déchiré",
		Summary = "Un ticket de cinéma déchiré a été retrouvé sur les lieux d'un incident. "
			.. "L'accusé affirme s'y trouver innocemment ce soir-là.",
		Accusation = "L'accusé prétend avoir assisté à une séance en toute légitimité. "
			.. "Les détails de sa version méritent vérification.",
		Fields = {
			{
				Key = "Film",
				Label = "QUEL FILM ?",
				Options = { "Mirage", "La Sentence", "Zone Grise", "Héritier Maudit" },
				TruthIndex = 2, -- La Sentence
			},
			{
				Key = "Séance",
				Label = "QUELLE SÉANCE ?",
				Options = { "14h30", "17h00", "19h30", "21h00" },
				TruthIndex = 3, -- 19h30
			},
			{
				Key = "Place",
				Label = "OÙ ÉTIEZ-VOUS ASSIS ?",
				Options = { "Devant gauche", "Milieu centre", "Fond droite", "Balcon" },
				TruthIndex = 2, -- Milieu centre
			},
		},
		LiarHint = "Vrai alibi : La Sentence · 19h30 · Milieu centre\nMentez sur au moins un champ.",
		Difficulty = "Easy",
		Theme = "Cinéma",
		Twist = "La caissière du soir se souvient d'avoir vendu deux tickets ce soir-là — pas un seul.",
	},

	-- ── Affaire 3 : La Clé Introuvable ───────────────────────────────────────
	{
		Id = "case_003",
		Title = "La Clé Introuvable",
		Summary = "Une clé de coffre-fort a disparu lors d'un transfert interne. "
			.. "L'accusé affirme avoir suivi la procédure à la lettre.",
		Accusation = "L'accusé prétend avoir remis la clé conformément aux règles. "
			.. "Son récit contient peut-être une faille.",
		Fields = {
			{
				Key = "Destinataire",
				Label = "REMIS À QUI ?",
				Options = { "Directeur", "Secrétaire", "Gardien", "Comptable" },
				TruthIndex = 1, -- Directeur
			},
			{
				Key = "Lieu",
				Label = "OÙ ?",
				Options = { "Bureau 204", "Hall d'entrée", "Parking", "Cafétéria" },
				TruthIndex = 1, -- Bureau 204
			},
			{
				Key = "Heure",
				Label = "À QUELLE HEURE ?",
				Options = { "9h00", "11h30", "14h00", "16h30" },
				TruthIndex = 2, -- 11h30
			},
		},
		LiarHint = "Vrai alibi : Directeur · Bureau 204 · 11h30\nMentez sur au moins un champ.",
		Difficulty = "Hard",
		Theme = "Bureau",
		Twist = "Les journaux de la serrure électronique indiquaient une heure d'accès différente de celle déclarée.",
	},
}

-- ─── État courant ──────────────────────────────────────────────────────────────

local selectedCase: CaseData = CASE_LIBRARY[1]
local lastCaseId: string = "" -- Anti-répétition : id du dernier match

-- ─── API publique ─────────────────────────────────────────────────────────────

-- Sélectionne une affaire aléatoire pour le prochain match.
-- Évite de répéter la même affaire deux fois de suite si le catalogue le permet.
function CaseService.selectForMatch(): string
	local pool: { CaseData } = {}
	if #CASE_LIBRARY > 1 then
		for _, c in ipairs(CASE_LIBRARY) do
			if c.Id ~= lastCaseId then
				table.insert(pool, c)
			end
		end
	else
		pool = CASE_LIBRARY
	end

	local idx = math.random(1, #pool)
	selectedCase = pool[idx]
	lastCaseId = selectedCase.Id

	print(
		string.format(
			"[CaseService] Affaire sélectionnée : %s (%s | %s | %s)",
			selectedCase.Title,
			selectedCase.Id,
			selectedCase.Difficulty,
			selectedCase.Theme
		)
	)
	return selectedCase.Id
end

-- Retourne l'affaire active pour le match courant.
function CaseService.getCase(): CaseData
	return selectedCase
end

-- Champs sans TruthIndex pour les clients (server-only filtré ici)
function CaseService.getClientFields(
	caseData: CaseData
): { { Key: string, Label: string, Options: { string } } }
	local fields: { { Key: string, Label: string, Options: { string } } } = {}
	for _, f in ipairs(caseData.Fields) do
		table.insert(fields, { Key = f.Key, Label = f.Label, Options = table.clone(f.Options) })
	end
	return fields
end

-- Guide de vérité FieldKey → index (envoyé aux témoins pour l'interface)
function CaseService.getTruthGuide(caseData: CaseData): { [string]: number }
	local guide: { [string]: number } = {}
	for _, f in ipairs(caseData.Fields) do
		guide[f.Key] = f.TruthIndex
	end
	return guide
end

-- Retourne les clés des champs contradictoires (déclaré ≠ vrai)
function CaseService.findContradictions(
	caseData: CaseData,
	fieldSelections: { [string]: number }
): { string }
	local contradictions: { string } = {}
	for _, f in ipairs(caseData.Fields) do
		local declared = fieldSelections[f.Key]
		if declared ~= nil and declared ~= f.TruthIndex then
			table.insert(contradictions, f.Key)
		end
	end
	return contradictions
end

-- Résumé lisible de la vérité officielle ({ Label, Valeur })
function CaseService.getTruthText(caseData: CaseData): { { Key: string, Value: string } }
	local result: { { Key: string, Value: string } } = {}
	for _, f in ipairs(caseData.Fields) do
		table.insert(result, { Key = f.Label, Value = f.Options[f.TruthIndex] })
	end
	return result
end

-- Valeurs lisibles d'une déclaration ({ valeur par champ, dans l'ordre })
function CaseService.getDeclarationText(
	caseData: CaseData,
	fieldSelections: { [string]: number }
): { string }
	local values: { string } = {}
	for _, f in ipairs(caseData.Fields) do
		local idx = fieldSelections[f.Key]
		if idx and f.Options[idx] then
			table.insert(values, f.Options[idx])
		else
			table.insert(values, "?")
		end
	end
	return values
end

-- Construit une déclaration NPC pour le mode Solo selon l'affaire active.
-- Si shouldLie, ment sur un champ aléatoire (index ≠ TruthIndex, wrap circulaire).
function CaseService.buildNpcDeclaration(shouldLie: boolean): { [string]: number }
	local decl: { [string]: number } = {}
	for _, f in ipairs(selectedCase.Fields) do
		decl[f.Key] = f.TruthIndex
	end
	if shouldLie then
		local fields = selectedCase.Fields
		local lieField = fields[math.random(1, #fields)]
		decl[lieField.Key] = (lieField.TruthIndex % #lieField.Options) + 1
	end
	return decl
end

return CaseService
