# Règles des Systèmes IA — The Witness Box
**Version 1.0 — MVP**
**Ce document définit le comportement de tout système non-humain dans le jeu.**

---

## 1. Portée

Ce document couvre :
- Les **NPCs Témoins** (Dossier Froid — mode Solo)
- L'**algorithme de détection des contradictions**
- Les **règles de remplacement de joueurs déconnectés** (Phase 2, spécifications incluses)
- Les **principes généraux** qui s'appliquent à toute décision algorithmique du jeu

Il ne couvre **pas** :
- L'IA générative externe (pas utilisée dans ce jeu)
- Le filtrage de texte (géré par Roblox TextChatService natif)

---

## 2. Principes Généraux des Systèmes IA

### 2.1 L'IA ne triche jamais
Aucun système NPC n'accède à des informations que les joueurs humains n'ont pas. Si un NPC joue le rôle de Juré, il "voit" uniquement les déclarations publiques — pas les rôles cachés, pas la vérité officielle.

### 2.2 L'IA échoue de façon crédible
Un NPC doit pouvoir se tromper. Un NPC infaillible brise l'immersion et enlève de la valeur aux victoires des joueurs humains. Les systèmes NPC intègrent intentionnellement des marges d'erreur.

### 2.3 L'IA reste lisible
Le comportement d'un NPC doit être observable et compréhensible par un joueur attentif. Pas de décisions opaques. Un joueur expérimenté doit pouvoir identifier un NPC avec un taux de succès raisonnable (pas parfait).

### 2.4 L'IA ne remplace pas le design
Si une mécanique ne fonctionne qu'avec des NPCs parfaits, la mécanique est mal conçue. Corriger la mécanique, pas l'IA.

---

## 3. NPCs Témoins — Mode Dossier Froid

### 3.1 Rôle
Les NPCs Témoins sont les "adversaires" du joueur en mode Solo. Ils jouent le rôle de témoins honnêtes ou menteurs dans des scénarios scriptés. Le joueur joue le Juré.

### 3.2 Structure d'un NPC Témoin

```luau
type NPCWitness = {
    Name: string,              -- Nom fictif
    Role: "Honest" | "Liar",
    PersonalityType: PersonalityType,
    Declarations: { Declaration },  -- Scriptées dans le scénario
    ResponseTime: NumberRange, -- Variation du délai de "réponse"
}

type PersonalityType =
    "Methodical"  -- Répond vite, déclarations précises
  | "Nervous"     -- Répond lentement (>15s), trop de détails
  | "Evasive"     -- Répond dans les dernières secondes
  | "Confident"   -- Répond vite même quand menteur
```

### 3.3 Comportement selon la Personnalité

#### Methodical (Méthodique)
- Temps de réponse simulé : 5-10 secondes
- Déclarations : complètes, tous les champs remplis
- Comportement menteur : temps identique — ne donne pas de signal visuel
- Difficulté : Élevée (pour les scénarios Complexes)

#### Nervous (Nerveux)
- Temps de réponse simulé : 18-23 secondes
- Déclarations : parfois un champ manquant
- Comportement menteur : temps plus long encore (20-24s)
- Comportement honnête : temps long aussi — le nerveux innocent déclenche de faux signaux
- Difficulté : Moyenne (crée des faux positifs intentionnels)

#### Evasive (Évasif)
- Temps de réponse simulé : 20-24 secondes (toujours dans les dernières secondes)
- Déclarations : champs remplis avec des valeurs vagues ("quelque part", "un moment")
- Ce NPC est toujours suspect — mais n'est pas forcément le menteur
- Difficulté : Élevée (crée des biais de suspicion)

#### Confident (Assuré)
- Temps de réponse simulé : 3-7 secondes
- Déclarations : complètes, formulées avec assurance
- Comportement menteur identique à comportement honnête — aucun signal visuel
- Difficulté : Très élevée (pour scénarios Complexes uniquement)

### 3.4 Simulation du Temps de Réponse

```luau
-- Le "délai" est purement cosmétique — la déclaration est déjà scriptée
-- On simule un comportement humain en retardant l'affichage

local function simulateResponseDelay(personality: PersonalityType): number
    local ranges = {
        Methodical = NumberRange.new(5, 10),
        Nervous    = NumberRange.new(18, 23),
        Evasive    = NumberRange.new(20, 24),
        Confident  = NumberRange.new(3, 7),
    }
    local range = ranges[personality]
    return math.random(range.Min, range.Max)
end
```

Le Portrait Vivant affiche l'état "Hésitant" ou "Nerveux" selon le délai simulé — exactement comme pour un joueur humain.

### 3.5 Variation des Déclarations

Chaque Dossier Froid dispose de 2 à 3 variantes de déclarations par NPC. Le système sélectionne une variante aléatoire à chaque partie. Objectif : les joueurs qui rejouent un dossier ne voient pas exactement les mêmes formulations.

```luau
-- Sélection de variante
local variantIndex = math.random(1, #npc.Declarations)
local declaration = npc.Declarations[variantIndex]
```

### 3.6 Ce que les NPCs ne font pas
- Ils ne réagissent pas dynamiquement aux autres déclarations (les déclarations sont scriptées)
- Ils n'adaptent pas leur stratégie selon les réactions du joueur
- Ils ne génèrent pas de texte procéduralement — toutes les déclarations sont pré-écrites

---

## 4. Algorithme de Détection des Contradictions

### 4.1 Ce que le système fait

Le système compare les déclarations soumises et émet une alerte quand deux déclarations se contredisent **directement** selon les règles définies dans le scénario.

### 4.2 Ce que le système ne fait pas

- Il ne déduit pas : "Si A était à X et B était à Y, alors C ment"
- Il n'interprète pas le sens des mots
- Il ne classe pas les suspects
- Il ne suggère pas de vote

### 4.3 Implémentation

```luau
-- Pour chaque nouvelle déclaration soumise :
function detectContradictions(
    newDeclaration: Declaration,
    allDeclarations: { Declaration },
    contradictionRules: { ScenarioContradictionRule }
): { ContradictionAlert }

    local alerts = {}

    for _, rule in ipairs(contradictionRules) do
        -- Vérifier si le champ concerné est rempli dans la nouvelle déclaration
        local newValue = newDeclaration.Fields[rule.Field]
        if not newValue or newValue == "" then continue end

        -- Chercher une déclaration précédente sur le même champ
        for _, prevDeclaration in ipairs(allDeclarations) do
            if prevDeclaration.PlayerId == newDeclaration.PlayerId then continue end
            local prevValue = prevDeclaration.Fields[rule.Field]
            if not prevValue or prevValue == "" then continue end

            -- Vérifier la contradiction selon la règle
            local isContradiction = checkRule(rule, newValue, prevValue)
            if isContradiction then
                table.insert(alerts, {
                    Field = rule.Field,
                    Declaration1 = prevDeclaration,
                    Declaration2 = newDeclaration,
                })
            end
        end
    end

    return alerts
end
```

### 4.4 Types de Règles de Contradiction

```luau
-- Règle de type "valeurs différentes sur un champ clé"
-- Ex: Heure mentionnée différente entre deux témoins sur le même événement
{ Field = "Heure", ConflictType = "DirectDifference" }

-- Règle de type "incompatibilité contextuelle définie dans le scénario"
-- Ex: "La bibliothèque était fermée après 18h" → tout témoin disant y être après 18h contredit les faits
{ Field = "Lieu", ConflictType = "ContextualIncompatibility", Context = "Bibliothèque après 18h" }

-- Règle de type "présence mutuelle exclusive"
-- Ex: A dit "j'étais seul", B dit "A était avec moi"
{ Field = "Personne", ConflictType = "MutualExclusion" }
```

### 4.5 Rate Limiting

Maximum 1 alerte de contradiction visible toutes les 5 secondes pour éviter le spam visuel. Si plusieurs contradictions sont détectées simultanément, elles sont mises en file et affichées successivement.

---

## 5. NPCs de Remplacement — Joueurs Déconnectés (Phase 2)

*Spécifications pour implémentation future.*

### 5.1 Déclenchement
Si un joueur se déconnecte pendant une partie (phase DECLARATION, DELIBERATION ou SPRINT), le système attend **15 secondes** avant d'activer un NPC de remplacement.

### 5.2 Comportement du NPC de Remplacement

**Si le joueur déconnecté était un Témoin :**
- Le NPC soumet une déclaration neutre pour les tours restants : "Je n'ai rien à ajouter."
- Cette déclaration n'est pas scriptée — elle est toujours identique et neutre
- Les jurés peuvent interpréter le silence comme un signal

**Si le joueur déconnecté était un Juré :**
- Le NPC vote INNOCENT par défaut (principe du doute raisonnable)
- Ce vote par défaut est visible dans les statistiques post-partie

**Si le joueur déconnecté était l'Avocat de l'Accusation :**
- Le système pose la prochaine question de la liste automatiquement
- Le NPC n'interagit pas dynamiquement

### 5.3 Indication Visuelle
L'avatar du joueur déconnecté affiche une icône de déconnexion. Les autres joueurs savent qu'il s'agit d'un remplaçant. L'ambiguïté humain/NPC n'est **pas** maintenue pour les déconnexions — uniquement pour les NPCs prévus dès le début (Dossier Froid).

---

## 6. Algorithme de Sélection des Scénarios

### 6.1 Règles de Sélection

```luau
function selectScenario(
    playerCount: number,
    format: GameFormat,
    recentScenarios: { string }  -- IDs des 5 derniers scénarios joués sur ce serveur
): Scenario

    -- 1. Filtrer par format compatible
    local compatible = filterByFormat(allScenarios, format)

    -- 2. Exclure les scénarios récents (anti-répétition)
    local fresh = excludeRecent(compatible, recentScenarios)

    -- 3. Si aucun scénario frais disponible : utiliser tout le pool
    if #fresh == 0 then fresh = compatible end

    -- 4. Sélection aléatoire pondérée par difficulté
    -- Format Solo/Duel : préférer Simple
    -- Format Mini : préférer Standard
    -- Format Full : mix Standard/Complexe
    return weightedRandom(fresh, format)
end
```

### 6.2 Anti-Répétition
Les 5 derniers scénarios joués sur un serveur sont mémorisés en mémoire (pas en DataStore). À chaque nouvelle partie, le système évite de sélectionner ces scénarios. Si le pool est épuisé (toutes les scénarios récemment joués), l'anti-répétition est ignorée.

---

## 7. Règles sur les Données et la Vie Privée

### 7.1 Données des Déclarations
Les textes saisis par les joueurs dans les champs de déclaration ne sont **jamais** stockés en DataStore. Ils vivent uniquement en mémoire serveur pendant la durée de la partie et sont supprimés à la fin.

Exception : la Conférence de Presse contient des fragments de déclarations. Ces fragments sont générés côté serveur à partir des déclarations en mémoire, puis envoyés au client pour affichage et partage. Ils ne sont pas persistés côté serveur.

### 7.2 Données des Votes
Les votes individuels ne sont pas stockés. Seul le résultat agrégé (verdict + comptage) est conservé pour les statistiques du profil.

### 7.3 Données des Rôles
Les attributions de rôles ne sont jamais logguées en dehors de la session serveur. Aucun historique "qui était le menteur dans quelle partie" n'est conservé.

---

## 8. Comportements Interdits

Les systèmes IA de ce jeu ne doivent **jamais** :

- Accéder à des informations non disponibles aux joueurs humains équivalents
- Modifier rétroactivement des votes ou des déclarations
- Envoyer des données de rôle en broadcast (uniquement FireClient individuel)
- Générer du texte libre non filtré (toutes les déclarations NPC sont pré-écrites)
- Influencer le verdict de façon opaque ou non documentée
- Prendre des décisions basées sur le profil économique du joueur (payant vs gratuit)
