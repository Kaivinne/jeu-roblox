# Systèmes de Gameplay — The Witness Box
**Version 1.0 — MVP**
**Document de référence technique pour l'implémentation**

---

## 1. Système de Matchmaking

### 1.1 Logique de Sélection du Format

```
Joueurs disponibles → Format sélectionné

1 joueur     → SOLO (Dossier Froid)
2 joueurs    → DUEL
3 joueurs    → MINI (1 NPC en remplacement OU attente 60s → DUEL si aucun arrivant)
4 joueurs    → MINI
5 joueurs    → FULL (1 NPC optionnel OU lancement à 5)
6+ joueurs   → FULL
```

Le système vérifie le nombre de joueurs dans la file toutes les **15 secondes**. Si le format peut monter (ex : 3 joueurs → 4 joueurs arrivent), la partie est relancée dans le nouveau format si elle n'a pas encore commencé (phase LOBBY uniquement).

### 1.2 Timeout de Lobby
- Attente maximale en lobby : **90 secondes**
- Si le seuil minimum n'est pas atteint après 90s → lancement forcé avec le format disponible (Solo ou Duel)
- Un message informe le joueur : "Lancement en Procès Express — nombre de joueurs insuffisant pour le format complet"

### 1.3 Mode Cascade
À la fin d'une partie, si le joueur ne quitte pas activement dans les 10 secondes, il est automatiquement placé dans la file pour la partie suivante. Les anciens joueurs sont prioritaires dans le lobby suivant (même groupe conservé si possible).

---

## 2. Système de Rôles

### 2.1 Attribution

```
Format DUEL (2 joueurs) :
  - 1 Accusé (menteur ou honnête, tiré au sort 50/50)
  - 1 Détective (juré)

Format MINI (4 joueurs) :
  - 1 Accusé
  - 1 Avocat de l'Accusation
  - 2 Jurés

Format FULL (6 joueurs) :
  - 1 Accusé (= le Menteur)
  - 1 Avocat de l'Accusation
  - 2 Témoins Honnêtes
  - 2 Jurés

Format FULL (7-8 joueurs) :
  - 1 Accusé
  - 1 Avocat de l'Accusation
  - 2-3 Témoins Honnêtes
  - 2-3 Jurés
```

### 2.2 Distribution de l'Information

Chaque joueur reçoit **uniquement** ce dont il a besoin :

| Rôle | Reçoit |
|---|---|
| Accusé (Menteur) | Version Altérée des faits (FireClient individuel) |
| Témoin Honnête | Vérité Officielle (FireClient individuel) |
| Avocat Accusation | Contexte général du scénario (pas de vérité) |
| Juré | Contexte général du scénario (pas de vérité) |

La Vérité Officielle et la Version Altérée ne quittent jamais le serveur autrement que via FireClient individuel. Jamais de broadcast.

### 2.3 Menteur Partiel
Le Menteur n'est pas obligé de mentir sur tout. Il reçoit une Version Altérée avec 1 à 3 faits modifiés. Sur le reste, sa version est identique à la Vérité. Il peut donc être partiellement honnête — c'est intentionnel et augmente la difficulté de détection.

---

## 3. Système de Déclarations

### 3.1 Structure d'une Déclaration

```luau
type Declaration = {
    PlayerId: number,
    Round: number,             -- Numéro de la déclaration (1er, 2ème tour...)
    Fields: {
        Lieu: string,          -- max 20 caractères
        Personne: string,      -- max 20 caractères
        Heure: string,         -- max 10 caractères
        Evenement: string,     -- max 30 caractères
    },
    SubmittedAt: number,       -- timestamp serveur
    TimeElapsed: number,       -- secondes utilisées (max 25)
}
```

### 3.2 Validation Serveur

À réception d'une déclaration :
1. Vérifier que le joueur est bien dans la phase DECLARATION
2. Vérifier que c'est bien son tour
3. Vérifier que le timer n'a pas expiré (timeElapsed ≤ 25)
4. Sanitiser chaque champ (longueur, caractères autorisés)
5. Stocker la déclaration en mémoire serveur (pas de DataStore)
6. Passer au joueur suivant

Si le timer expire sans soumission : déclaration vide automatiquement enregistrée.

### 3.3 Ordre des Déclarations

```
Tour 1 : Chaque témoin déclare une fois (ordre aléatoire)
Tour 2 (si format FULL) : L'Avocat peut demander une précision à un témoin spécifique
         → Le témoin ciblé déclare à nouveau sur le champ demandé uniquement
Tour 3 : Optionnel, déclenché si l'Avocat utilise son droit de rappel
```

---

## 4. Système de Détection des Contradictions

### 4.1 Algorithme

```luau
-- Pour chaque nouvelle déclaration soumise :
-- 1. Extraire les champs remplis
-- 2. Pour chaque champ rempli :
--    a. Chercher si ce champ a été mentionné dans une déclaration précédente
--    b. Si oui : comparer les valeurs selon les règles du scénario
--    c. Si contradiction directe → émettre ContradictionDetected

-- Règles de contradiction directes :
-- - Même joueur mentionne deux heures différentes entre deux déclarations
-- - Deux joueurs mentionnent le même lieu mais à des heures incompatibles
--   (selon les données du scénario : "La bibliothèque était fermée après 18h")
-- - Un joueur dit "j'étais seul" et un autre dit "il était avec moi"
```

### 4.2 Limites du Système

Le système ne fait **que** des comparaisons directes définies dans le scénario. Il ne déduit pas. Il n'analyse pas le sens. Il n'interprète pas les formulations. Tout raisonnement complexe reste humain.

### 4.3 Données du Scénario (structure)

```luau
type ScenarioContradictionRule = {
    Field: string,             -- "Heure", "Lieu", "Personne", "Evenement"
    TruthValue: string,        -- La valeur vraie
    AlteredValue: string,      -- La valeur fausse (dans la version menteur)
    ConflictCondition: string, -- "different_from_truth" | "incompatible_with"
}
```

---

## 5. Système de Vote

### 5.1 Vote de Verdict

- Chaque Juré dispose d'un vote : COUPABLE ou INNOCENT
- Le vote est soumis au serveur via RemoteEvent `VoteCast`
- Le serveur valide : est-ce un juré ? A-t-il déjà voté ? La phase est-elle correcte ?
- Le vote est **irréversible** une fois soumis (sauf mécanique de Retournement — Phase 2)
- Un vote non soumis à l'expiration du timer = ABSTENTION = compte comme INNOCENT

### 5.2 Calcul du Verdict

```
Verdict = COUPABLE si : votes_coupable > votes_innocent
Verdict = INNOCENT si : votes_innocent >= votes_coupable
```

En cas d'égalité parfaite : verdict INNOCENT (principe du doute raisonnable).

### 5.3 Vote Progressif (Délibération)
Pendant la phase de délibération, les jurés peuvent soumettre un **vote de sentiment** (curseur de crédibilité) pour chaque témoin entendu. Ces votes sont privés et n'influencent pas le verdict — ils servent au joueur pour suivre sa propre évolution. Affichés dans les statistiques post-partie.

---

## 6. Système d'Objection

### 6.1 Règles

- Disponible uniquement pendant la phase DECLARATION, pas pendant DELIBERATION
- Usage unique par juré par partie — impossible d'en avoir deux
- Timing : peut être activé pendant qu'un témoin déclare
- Effet : interrompt immédiatement la déclaration en cours, suspension du timer

### 6.2 Liste des Objections Disponibles

Générées contextuellement selon les déclarations déjà entendues. Au MVP : liste fixe de 3 options.

```
Option 1 : "Cette déclaration contredit ce que vous avez dit précédemment."
Option 2 : "Vous n'avez pas répondu à la question posée."
Option 3 : "Cette information est incompatible avec les faits établis."
```

### 6.3 Réponse du Témoin

Après l'objection, le témoin a 15 secondes pour répondre. Il utilise le même système de template contraint — un seul champ libre au lieu de 4 (la réponse à l'objection spécifique).

---

## 7. Système de Réactions

### 7.1 Règles

- 4 réactions disponibles : Suspicion, Crédibilité, Confusion, Contradiction
- Fenêtre d'activation : 8 secondes après chaque déclaration complète
- Limite : 1 réaction par joueur par déclaration
- Les réactions sont visibles de tous en temps réel (sous l'avatar du juré)

### 7.2 Effet sur le Jeu

Les réactions sont **purement expressives**. Elles n'influencent pas le verdict, le rang, ou les statistiques directement. Leur valeur est sociale et narrative — elles communiquent sans texte.

### 7.3 Comptage pour Statistiques

Le serveur comptabilise le nombre de réactions ⚡ (Contradiction) envoyées sur chaque déclaration. Cette statistique est utilisée post-partie pour identifier "la déclaration la plus suspecte" affichée dans la Conférence de Presse.

---

## 8. Système de Dossiers Froids (Mode Solo)

### 8.1 Structure d'un Dossier Froid

```luau
type ColdCase = {
    Id: string,
    Title: string,
    Difficulty: "Easy" | "Medium" | "Hard",
    Context: string,           -- 50 mots max
    Declarations: {            -- 3 à 5 déclarations scriptées
        {
            WitnessName: string,
            IsLiar: boolean,
            Fields: Declaration.Fields,
        }
    },
    TruthAnswers: {            -- Les réponses correctes
        GuiltyWitness: string,
        FalseFields: { string },
    },
    TimeToComplete: number,    -- Estimation en secondes
}
```

### 8.2 Rotation des Dossiers

- Pool de 15 dossiers au lancement
- 3 dossiers disponibles simultanément, rotation toutes les 24h
- Les dossiers déjà complétés sont marqués (badge coché) mais restent accessibles
- Les dossiers du Pass "Dossiers Classifiés" (30 dossiers) sont disponibles en permanence

### 8.3 Évaluation de la Réponse

Le joueur sélectionne le témoin qu'il pense être le menteur. Réponse binaire (correct / incorrect). Pas de notation partielle au MVP.

---

## 9. Système de Récompenses

### 9.1 Attribution en Fin de Partie

```
Fin de partie (tous formats) :
  → XP de base : 50
  → Jetons de base : 10

Bonus Juré (verdict correct) :
  → XP : +75
  → Jetons : +15

Bonus Menteur acquitté :
  → XP : +100
  → Jetons : +20

Bonus Première partie du jour :
  → Jetons : +25

Bonus Cascade (3 parties consécutives) :
  → Jetons : +30

Vote de Respect reçu (par vote) :
  → XP : +20
  → Jetons : +5
```

### 9.2 Montée de Rang

À chaque seuil d'XP atteint, le système :
1. Met à jour le rang dans le profil (DataStore)
2. Envoie `RewardGranted` avec le nouveau rang
3. Déclenche l'animation de montée de rang côté client
4. Débloque automatiquement le cosmétique du palier

### 9.3 Vérification des Badges

À la fin de chaque partie, `RewardService` vérifie si de nouveaux badges ont été débloqués en comparant les stats du profil aux conditions de chaque badge. Les badges sont attribués une seule fois (idempotent).

---

## 10. Système de Réputation

### 10.1 Crédibilité

```
Crédibilité += 5 si : joueur Honnête + déclaration crue par majorité des jurés
Crédibilité -= 10 si : joueur Menteur + condamné
Crédibilité -= 3 si : joueur Honnête + non cru (sa déclaration suspecte)
Crédibilité += 3 si : joueur Menteur + acquitté (maîtrise du mensonge)

Plage : 0 à 100
Valeur initiale : 50
```

### 10.2 Perspicacité

```
Perspicacité += 8 si : vote correct (Juré identifie le bon coupable)
Perspicacité -= 5 si : vote incorrect
Perspicacité += 3 si : vote correct ET le joueur était en minorité (courage)

Plage : 0 à 100
Valeur initiale : 50
```

### 10.3 Affichage

Les deux valeurs sont affichées en barres dans le Dossier Personnel. Elles ne sont pas affichées pendant la partie (éviter le biais de réputation sur les votes).
