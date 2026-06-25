# Architecture Technique — The Witness Box
**Version 1.0 — MVP**
**Environnement : Roblox / Luau / Rojo 7.4.4**

---

## 1. Principes Directeurs

- **Server-authoritative** : toute logique de jeu critique s'exécute sur le serveur. Le client ne valide rien.
- **Séparation stricte** : aucune logique serveur dans les scripts client, aucun accès DataStore côté client.
- **Mobile-first** : toutes les décisions d'architecture considèrent la latence mobile et les sessions courtes.
- **Résilience aux déconnexions** : une déconnexion mid-partie ne bloque jamais les autres joueurs.

---

## 2. Structure du Projet (Rojo)

```
TheInterview/
├── default.project.json
├── rokit.toml
├── wally.toml
├── selene.toml
├── stylua.toml
├── docs/
└── src/
    ├── client/
    │   ├── init.client.luau          -- Point d'entrée client
    │   ├── controllers/
    │   │   ├── UIController.luau     -- Gestion de l'UI
    │   │   ├── ReactionController.luau
    │   │   └── AudioController.luau
    │   └── components/
    │       ├── DeclarationBuilder.luau
    │       ├── VerdictScreen.luau
    │       ├── TimerDisplay.luau
    │       └── ContradictionBoard.luau
    ├── server/
    │   ├── init.server.luau          -- Point d'entrée serveur
    │   ├── services/
    │   │   ├── GameService.luau      -- Orchestrateur principal
    │   │   ├── RoleService.luau      -- Attribution des rôles
    │   │   ├── ScenarioService.luau  -- Gestion des scénarios
    │   │   ├── VoteService.luau      -- Système de vote
    │   │   ├── TimerService.luau     -- Timers serveur
    │   │   ├── DataService.luau      -- DataStore
    │   │   ├── MatchmakingService.luau
    │   │   └── RewardService.luau    -- XP, Jetons, Badges
    │   └── data/
    │       └── Scenarios/            -- Modules scénario
    └── shared/
        ├── GameConfig.luau           -- Configuration globale
        ├── Enums.luau                -- États, rôles, formats
        ├── Types.luau                -- Types Luau
        ├── Constants.luau            -- Constantes
        └── Util/
            ├── TableUtil.luau
            └── StringUtil.luau
```

---

## 3. Enums et Types Centraux

```luau
-- src/shared/Enums.luau

local Enums = {}

Enums.GameFormat = {
    SOLO = "Solo",
    DUEL = "Duel",
    MINI = "Mini",
    FULL = "Full",
}

Enums.Role = {
    HONEST_WITNESS = "HonestWitness",
    LIAR = "Liar",
    PROSECUTOR = "Prosecutor",
    JUROR = "Juror",
}

Enums.GamePhase = {
    LOBBY       = "Lobby",
    INTRO       = "Intro",
    DECLARATION = "Declaration",
    DELIBERATION = "Deliberation",
    SPRINT      = "Sprint",
    VERDICT     = "Verdict",
    POST_VERDICT = "PostVerdict",
}

Enums.VoteValue = {
    GUILTY   = "Guilty",
    INNOCENT = "Innocent",
    ABSTAIN  = "Abstain",
}

Enums.ReactionType = {
    SUSPICION    = "Suspicion",
    CREDIBILITY  = "Credibility",
    CONFUSION    = "Confusion",
    CONTRADICTION = "Contradiction",
}

return Enums
```

---

## 4. Architecture Client / Serveur

### 4.1 Responsabilités Serveur (src/server)

| Service | Responsabilité |
|---|---|
| `GameService` | Machine à états de la partie, orchestration des phases |
| `RoleService` | Attribution aléatoire des rôles, distribution des vérités |
| `ScenarioService` | Sélection et chargement des scénarios |
| `VoteService` | Réception, validation et comptage des votes |
| `TimerService` | Timers autoritaires (jamais côté client) |
| `MatchmakingService` | Détection du nombre de joueurs, sélection du format |
| `DataService` | Lecture/écriture DataStore, profils joueur |
| `RewardService` | Calcul et attribution des XP, Jetons, Badges |

### 4.2 Responsabilités Client (src/client)

| Controller | Responsabilité |
|---|---|
| `UIController` | Affichage des phases, transitions d'écran |
| `ReactionController` | Envoi des réactions, affichage des réactions des autres |
| `AudioController` | Sons d'ambiance, effets sonores d'événements |
| `DeclarationBuilder` | Interface de construction de déclaration (template) |

### 4.3 Règle stricte
Le client ne prend **aucune décision de jeu**. Il envoie des intentions (vote, réaction, déclaration) et reçoit des états validés. Tout ce que le client calcule est à titre d'affichage uniquement.

---

## 5. RemoteEvents et RemoteFunctions

```
ReplicatedStorage/
└── Remotes/
    ├── Events/
    │   ├── GamePhaseChanged        -- Serveur → Client : nouvelle phase
    │   ├── DeclarationSubmitted    -- Client → Serveur : déclaration envoyée
    │   ├── ReactionSent            -- Client → Serveur : réaction d'un juré
    │   ├── VoteCast                -- Client → Serveur : vote soumis
    │   ├── ObjectionRaised         -- Client → Serveur : bouton objection
    │   ├── ContradictionDetected   -- Serveur → Client : mise à jour tableau
    │   ├── TimerUpdate             -- Serveur → Client : tick du timer
    │   ├── VerdictRevealed         -- Serveur → Client : résultat final
    │   └── RewardGranted           -- Serveur → Client : XP/Jetons reçus
    └── Functions/
        ├── GetPlayerProfile        -- Client → Serveur : récupère le profil
        └── GetCurrentScenario      -- Client → Serveur : infos scénario actuel
```

**Règle de sécurité :** Toute RemoteFunction valide les arguments serveur-side avant traitement. Les arguments malformés sont silencieusement ignorés, jamais propagés.

---

## 6. DataStore

### 6.1 Structure du Profil Joueur

```luau
-- Clé DataStore : "PlayerProfile_v1_" .. tostring(userId)

type PlayerProfile = {
    Version: number,          -- Schema version pour migrations futures
    XP: number,
    Rank: number,             -- 1-8
    Jetons: number,
    Credibility: number,      -- 0-100
    Perspicacity: number,     -- 0-100
    Stats: {
        TotalGames: number,
        GamesAsLiar: number,
        LiarWins: number,
        CorrectVerdicts: number,
        RespectReceived: number,
    },
    Badges: { string },       -- Liste des badge IDs obtenus
    PinnedGames: {            -- 3 parties épinglées max
        {
            ScenarioTitle: string,
            Outcome: string,
            Timestamp: number,
        }
    },
    Cosmetics: {
        Owned: { string },    -- IDs des cosmétiques possédés
        Equipped: {
            Outfit: string,
            Entry: string,
            Reaction: string,
            Frame: string,
        },
    },
    Economy: {
        PassOwned: { string },
        ProductHistory: { number }, -- Timestamps des achats Dev Product
    },
    CreatedAt: number,
    LastSeen: number,
}
```

### 6.2 Politique de Sauvegarde
- Sauvegarde déclenchée à la fin de chaque partie (pas en cours de partie)
- Sauvegarde déclenchée sur `Players.PlayerRemoving`
- Retry automatique x3 en cas d'échec DataStore
- Session Lock : un profil ne peut être ouvert que par un serveur à la fois

### 6.3 DataStore pour les Scénarios
Les scénarios sont des `ModuleScript` dans `src/server/data/Scenarios/` — pas dans le DataStore. Ils sont mis à jour via déploiement Rojo, pas dynamiquement.

---

## 7. Machine à États de la Partie (GameService)

```
LOBBY
  └─[Seuil joueurs atteint]→ INTRO
INTRO
  └─[30s écoulées]→ DECLARATION
DECLARATION
  └─[Tous déclarations soumises OU timer expiré]→ DELIBERATION
DELIBERATION
  └─[45s écoulées]→ SPRINT
SPRINT
  └─[60s écoulées OU tous votes soumis]→ VERDICT
VERDICT
  └─[Affichage 10s]→ POST_VERDICT
POST_VERDICT
  └─[60s écoulées]→ LOBBY (Mode Cascade) OU FIN
```

Les transitions sont déclenchées exclusivement par le serveur. Le client reçoit `GamePhaseChanged` et adapte son UI.

---

## 8. Système de Timer

**Principe :** Les timers vivent sur le serveur. Le client reçoit des ticks réguliers pour l'affichage, mais ne prend aucune décision basée sur son propre timer local.

```luau
-- TimerService : envoie un tick toutes les secondes
-- Le client affiche le temps reçu, pas son propre calcul
-- À expiration, le serveur déclenche la transition de phase
```

**Timers MVP :**
| Phase | Durée | Comportement à expiration |
|---|---|---|
| Déclaration par témoin | 25s | Déclaration vide soumise automatiquement |
| Délibération | 45s | Votes non soumis = Abstention |
| Sprint Final | 60s | Clôture du vote |
| Post-Verdict chat | 60s | Retour au lobby |

---

## 9. Attribution des Rôles (RoleService)

```luau
-- Processus d'attribution :
-- 1. Récupérer la liste des joueurs dans la session
-- 2. Déterminer le format (MatchmakingService)
-- 3. Shuffler la liste (math.random avec seed serveur)
-- 4. Assigner les rôles selon le format
-- 5. Envoyer à chaque joueur UNIQUEMENT son rôle (pas ceux des autres)
-- 6. Envoyer la vérité officielle aux honnêtes, la version altérée au menteur

-- SÉCURITÉ : Les rôles ne sont JAMAIS envoyés en broadcast.
-- Chaque joueur reçoit uniquement sa propre information via un FireClient individuel.
```

---

## 10. Détection des Contradictions (ScenarioService)

Le système compare les déclarations soumises aux données de vérité du scénario. Il ne déduit pas — il vérifie des correspondances exactes de champs.

```luau
-- Logique de détection :
-- Pour chaque déclaration soumise :
--   Pour chaque champ rempli (lieu, personne, heure, événement) :
--     Si ce champ a déjà été mentionné par un autre témoin :
--       Si les valeurs sont incompatibles selon le scénario :
--         Émettre ContradictionDetected avec les deux déclarations en référence
```

**Limites intentionnelles :**
- Pas de déduction croisée complexe (ex: "Si A dit X et B dit Y, alors C est suspect")
- Uniquement les contradictions directes entre champs identiques
- Le raisonnement reste humain

---

## 11. Anti-Cheat et Sécurité

| Vecteur | Mesure |
|---|---|
| Lecture des rôles via l'inspecteur | Rôles jamais stockés dans `ReplicatedStorage`. Uniquement en mémoire serveur. |
| Vote multiple | `VoteService` ignore les votes après qu'un vote soit enregistré pour ce joueur |
| Soumission de déclarations après timer | Serveur ignore les déclarations reçues après l'expiration du timer de sa phase |
| Spam de réactions | Rate limit : 1 réaction par phase de déclaration par joueur |
| Manipulation du DataStore | Tout DataStore write passe par `DataService` avec validation de type et plage de valeurs |

---

## 12. Performance et Contraintes

| Contrainte | Cible |
|---|---|
| Joueurs max par serveur Roblox | 20 (laisser de la marge par rapport au max 100) |
| Instances de parties simultanées | Gérées par le MatchmakingService via TeleportService |
| Ping mobile cible | <200ms pour les interactions critiques (vote, objection) |
| Taille des RemoteEvents | Aucun envoi d'objet > 50KB |
| DataStore calls par minute | < 60 (limite Roblox) |

---

## 13. Dépendances Externes (Wally)

Au MVP, aucune dépendance Wally obligatoire. Le projet est auto-suffisant. Les bibliothèques suivantes peuvent être ajoutées si nécessaire :

```toml
# wally.toml — dépendances optionnelles Phase 2
# Promise = "evaera/promise@4.0.0"   -- Gestion async propre
# Signal = "sleitnick/signal@1.5.0"  -- Events internes typés
```

---

## 14. Outils de Développement

| Outil | Version | Usage |
|---|---|---|
| Rojo | 7.4.4 | Sync Studio ↔ VSCode |
| Wally | 0.3.2 | Gestion dépendances |
| Selene | 0.27.1 | Lint Luau |
| StyLua | 2.0.2 | Formatage automatique |

Tous gérés via `rokit.toml`. Installation : `rokit install` depuis la racine du projet.
