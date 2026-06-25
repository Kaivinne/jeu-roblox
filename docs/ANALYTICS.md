# Analytics — The Witness Box
**Version 1.0 — MVP**
**Objectif : Mesurer ce qui compte, ignorer le reste.**

---

## 1. Principe

Un dev solo ne peut pas surveiller 50 métriques. Ce document définit les **10 métriques critiques** à monitorer dès le premier jour, les événements à tracker dans le code, et la fréquence de revue adaptée à une production solo.

---

## 2. Les 10 Métriques Critiques

### M1 — Rétention J1
**Définition :** % de joueurs qui reviennent le lendemain de leur première session.
**Cible MVP :** > 35%
**Signal d'alarme :** < 20% → problème d'expérience de première partie
**Action si alerte :** Revoir l'onboarding, le format Duel, le premier Dossier Froid proposé.

### M2 — Rétention J7
**Définition :** % de joueurs toujours actifs 7 jours après leur première session.
**Cible MVP :** > 20%
**Signal d'alarme :** < 12% → problème de boucle de progression
**Action si alerte :** Revoir les récompenses Daily Login, la visibilité du rang et des Jetons.

### M3 — Rétention J30
**Définition :** % de joueurs toujours actifs 30 jours après leur première session.
**Cible MVP :** > 10%
**Signal d'alarme :** < 5% → problème de contenu long terme
**Action si alerte :** Accélérer le rythme de nouveaux scénarios, envisager la Phase 2.

### M4 — Durée de Session Moyenne
**Définition :** Durée moyenne d'une session par joueur actif.
**Cible MVP :** > 12 minutes
**Signal d'alarme :** < 8 minutes → joueurs qui ne complètent pas une partie entière
**Action si alerte :** Analyser le point de sortie exact (quelle phase déclenche la fuite ?).

### M5 — Parties par Session
**Définition :** Nombre moyen de parties jouées par session.
**Cible MVP :** > 2
**Signal d'alarme :** < 1.3 → le Mode Cascade ne fonctionne pas
**Action si alerte :** Revoir le timing du Mode Cascade, les écrans de transition.

### M6 — Taux de Complétion des Parties
**Définition :** % de parties lancées qui atteignent la phase VERDICT.
**Cible MVP :** > 75%
**Signal d'alarme :** < 60% → joueurs qui quittent mid-partie
**Action si alerte :** Identifier la phase avec le plus d'abandons (analytics détaillés).

### M7 — CCU (Concurrent Users)
**Définition :** Nombre de joueurs simultanés en temps réel.
**Cible 1 mois :** > 50 CCU
**Cible 3 mois :** > 200 CCU
**Impact :** Directement corrélé au classement Roblox Discover.

### M8 — Thumbs Up Rate
**Définition :** % de ratings positifs sur la page du jeu.
**Cible MVP :** > 80%
**Signal d'alarme :** < 70% → problème d'expérience générale ou de stabilité
**Action si alerte :** Lire les commentaires, chercher le pattern commun des reviews négatives.

### M9 — Taux de Conversion Économique
**Définition :** % de joueurs actifs qui ont effectué au moins un achat.
**Cible MVP :** > 3%
**Signal d'alarme :** < 1.5% → cosmétiques peu attractifs ou onboarding économique absent
**Action si alerte :** Revoir la visibilité des cosmétiques pendant la partie.

### M10 — Revenue per DAU
**Définition :** Robux gagnés divisé par le nombre de joueurs actifs ce jour-là.
**Cible MVP :** > 1.5 R/DAU/jour
**Signal d'alarme :** < 0.5 R/DAU → économie sous-performante
**Action si alerte :** Revoir les prix des passes, la présence du Pack Nouveau Venu.

---

## 3. Événements à Tracker (implémentation)

### 3.1 Événements de Session

```luau
-- À implémenter dans GameService / DataService

Analytics.track("session_start", {
    PlayerId = userId,
    Format = gameFormat,      -- "Solo", "Duel", "Mini", "Full"
    IsFirstSession = bool,
})

Analytics.track("session_end", {
    PlayerId = userId,
    Duration = seconds,
    GamesPlayed = count,
    LeftMidGame = bool,
})
```

### 3.2 Événements de Partie

```luau
Analytics.track("game_start", {
    GameId = uniqueId,
    Format = format,
    PlayerCount = count,
    ScenarioId = id,
})

Analytics.track("game_phase_reached", {
    GameId = uniqueId,
    Phase = phaseName,         -- tracker chaque phase pour trouver les abandons
    TimeInPreviousPhase = seconds,
})

Analytics.track("game_completed", {
    GameId = uniqueId,
    Format = format,
    Duration = seconds,
    Verdict = "Guilty" | "Innocent",
    VerdictCorrect = bool,
    LiarCaught = bool,
})

Analytics.track("game_abandoned", {
    GameId = uniqueId,
    Phase = currentPhase,      -- phase au moment de l'abandon
    TimeElapsed = seconds,
})
```

### 3.3 Événements de Gameplay

```luau
Analytics.track("declaration_submitted", {
    GameId = uniqueId,
    Role = role,
    TimeUsed = seconds,        -- Combien du timer de 25s a été utilisé
    FieldsFilled = count,      -- 1 à 4 champs remplis
})

Analytics.track("objection_used", {
    GameId = uniqueId,
    ObjectionType = type,
    Phase = "Declaration",
    Effective = bool,          -- A-t-elle changé des votes ?
})

Analytics.track("reaction_sent", {
    GameId = uniqueId,
    ReactionType = type,
    TargetWitnessRole = role,
})

Analytics.track("vote_cast", {
    GameId = uniqueId,
    Vote = "Guilty" | "Innocent",
    TimeBeforeExpiry = seconds, -- Combien de temps avant la fin du sprint
    WasCorrect = bool,          -- Calculé post-verdict
})

Analytics.track("contradiction_detected", {
    GameId = uniqueId,
    FieldType = field,
    InvolvedRoles = { role1, role2 },
})
```

### 3.4 Événements de Progression

```luau
Analytics.track("rank_up", {
    PlayerId = userId,
    NewRank = rank,
    DaysToReach = days,        -- Depuis la création du compte
})

Analytics.track("badge_earned", {
    PlayerId = userId,
    BadgeId = id,
    GamesPlayed = totalGames,  -- Combien de parties pour l'atteindre
})

Analytics.track("daily_login", {
    PlayerId = userId,
    Day = dayNumber,           -- Jour du cycle (1-7)
})
```

### 3.5 Événements Économiques

```luau
Analytics.track("purchase", {
    PlayerId = userId,
    ProductType = "GamePass" | "DevProduct",
    ProductId = id,
    Price = robux,
    DaysSinceFirstPlay = days,
    RankAtPurchase = rank,
})

Analytics.track("welcome_pack_shown", {
    PlayerId = userId,
    DaysSinceFirstPlay = days,
})

Analytics.track("welcome_pack_purchased", {
    PlayerId = userId,
    DaysSinceFirstPlay = days,
})
```

---

## 4. Implémentation Technique

### 4.1 Solution Recommandée au MVP

Roblox ne fournit pas d'analytics natif avancé. Options au MVP :

**Option A — AnalyticsService Roblox (natif, gratuit)**
Roblox fournit des métriques de base (DAU, rétention, revenus) dans le Developer Dashboard. Suffisant pour les M1 à M3 et M7 à M10. Pas de tracking d'événements custom.

**Option B — DataStore comme buffer analytics**
Logger les événements dans un DataStore dédié, agréger manuellement. Coût dev élevé, pas recommandé solo.

**Option C — Module analytics léger (recommandé)**
Utiliser un module Wally comme `sleitnick/analytics` ou créer un wrapper léger qui envoie des métriques à un endpoint externe simple (ex: Google Sheets via webhook). Implémentation en Phase 2.

**Décision MVP :** Utiliser uniquement le **Roblox Developer Dashboard** pour les métriques de base. Logger localement les événements critiques de partie dans le DataStore pour analyse manuelle si nécessaire. Intégration analytics complète en Phase 2.

### 4.2 Structure du Module Analytics (placeholder)

```luau
-- src/shared/Analytics.luau

local Analytics = {}

function Analytics.track(eventName: string, properties: { [string]: any })
    -- MVP : log silencieux (no-op)
    -- Phase 2 : envoi vers service externe
    if game:GetService("RunService"):IsStudio() then
        print("[Analytics]", eventName, properties)
    end
end

return Analytics
```

---

## 5. Dashboard de Suivi Manuel (Roblox Developer Dashboard)

### Métriques disponibles nativement

| Métrique | Onglet Roblox | Fréquence de revue |
|---|---|---|
| DAU / MAU | Engagement → Visits | Quotidienne |
| Rétention J1/J7/J30 | Engagement → Retention | Hebdomadaire |
| Session Duration | Engagement → Session Time | Hebdomadaire |
| CCU | Performance → Concurrent | Quotidienne |
| Thumbs Up Rate | Summary | Hebdomadaire |
| Revenue total | Monetization → Revenue | Hebdomadaire |
| Game Pass Sales | Monetization → Passes | Mensuelle |

### Rythme de Revue Recommandé (solo dev)

| Fréquence | Action |
|---|---|
| Quotidienne (5 min) | CCU, nouveaux reviews négatifs |
| Hebdomadaire (30 min) | Rétention J1/J7, durée de session, revenue |
| Mensuelle (1h) | Toutes les métriques, décision Phase 2 ou pivot |

---

## 6. Signaux de Pivot

Ces seuils, s'ils sont atteints après 4 semaines de lancement, déclenchent une revue stratégique :

| Signal | Seuil | Action |
|---|---|---|
| Rétention J7 | < 10% pendant 2 semaines | Revoir core loop — problème fondamental |
| Thumbs Up | < 65% | Chercher le problème UX avant tout marketing |
| Taux de complétion partie | < 50% | Audit de chaque phase, identifier le point de fuite |
| CCU max | < 10 après 1 mois | Revoir stratégie de lancement — pas de cold start résolu |
| Revenue/DAU | < 0.3 R après 2 mois | Revoir les cosmétiques et le Pack Bienvenue |
