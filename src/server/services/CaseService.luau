--!strict
-- Gère les affaires jouables.
-- Milestone 1.4 : 1 affaire hardcodée. Bibliothèque complète en Phase 2.
-- Module sans état : fonctions pures sur des données constantes.

local CaseService = {}

-- Données internes d'un champ (TruthIndex est server-only)
type CaseField = {
	Key: string,
	Label: string,
	Options: { string },
	TruthIndex: number, -- 1-based
}

-- Données internes d'une affaire
type CaseData = {
	Id: string,
	Title: string,
	Summary: string,
	Accusation: string,
	Fields: { CaseField },
	LiarHint: string, -- instruction pour le Menteur
}

local CASE_LIBRARY: { CaseData } = {
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
	},
}

-- Retourne l'affaire courante (toujours la première en 1.4)
function CaseService.getCase(): CaseData
	return CASE_LIBRARY[1]
end

-- Champs sans TruthIndex pour les clients
function CaseService.getClientFields(
	caseData: CaseData
): { { Key: string, Label: string, Options: { string } } }
	local fields: { { Key: string, Label: string, Options: { string } } } = {}
	for _, f in ipairs(caseData.Fields) do
		table.insert(fields, { Key = f.Key, Label = f.Label, Options = table.clone(f.Options) })
	end
	return fields
end

-- Guide de vérité : FieldKey → index (1-based)
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

-- Résumé lisible de la vérité ({ label, valeur })
function CaseService.getTruthText(caseData: CaseData): { { Key: string, Value: string } }
	local result: { { Key: string, Value: string } } = {}
	for _, f in ipairs(caseData.Fields) do
		table.insert(result, { Key = f.Label, Value = f.Options[f.TruthIndex] })
	end
	return result
end

-- Valeur lisible d'une déclaration ({ label, valeur })
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

return CaseService
