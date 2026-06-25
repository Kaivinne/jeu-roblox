# Plan de Production — The Witness Box
**Version 1.0 — Solo Dev + Claude Code**
**Horizon : 6 mois jusqu'au lancement**

---

## 1. Réalité de la Production Solo

Un développeur solo assisté par IA peut produire un jeu Roblox complet et de qualité. Les contraintes à accepter dès le départ :

- **La portée est fixe.** Ce qui est hors-scope MVP ne rentre pas avant le lancement, quelle que soit la tentation.
- **Le polish prend autant de temps que le développement.** Prévoir 30% du temps total pour les corrections, ajustements, et tests.
- **Le contenu (scénarios) est un risque de production.** 15 scénarios à rédiger est un travail d'écriture non-trivial.
- **Les interruptions existent.** Le planning intègre des buffers — ne pas les sacrifier en premier.

---

## 2. Rythme de Travail

### Semaine Type

| Jour | Focus | Durée estimée |
|---|---|---|
| Lundi | Développement (backend / services) | 2-4h |
| Mardi | Développement (UI / client) | 2-4h |
| Mercredi | Contenu (scénarios, textes) | 1-2h |
| Jeudi | Tests + corrections | 1-3h |
| Vendredi | Review, commit, documentation | 1h |
| Weekend | Buffer ou avance (optionnel) | — |

**Règle :** Ne pas coder et designer simultanément le même système. Finir un système avant de passer au suivant.

---

## 3. Workflow Quotidien

```
1. Lire les tâches du jour (PRODUCTION_PLAN ou liste perso)
2. Coder avec Claude Code en contexte
3. Lint + Format avant chaque commit (selene + stylua)
4. Commit avec message descriptif
5. Push GitHub (fin de journée)
6. Mettre à jour le statut des tâches
```

### Convention de Commit
```
feat: [système] description courte
fix: [système] description courte
content: [scénario/cosmétique] description
refactor: [système] description
docs: mise à jour documentation
```

Exemples :
```
feat: [GameService] machine à états phases de jeu
fix: [TimerService] timer qui ne s'arrête pas sur disconnect
content: [scenarios] ajout scénarios S01-S05 (faciles)
```

---

## 4. Workflow avec Claude Code

Claude Code est utilisé comme **pair programmer senior**, pas comme générateur de code aveugle.

### Bonnes pratiques établies

**Avant de coder un système :**
- Expliquer l'objectif et les contraintes à Claude
- Demander une revue de l'approche avant l'implémentation
- Valider la compatibilité avec `TECH_ARCHITECTURE.md`

**Pendant le développement :**
- Sessions de 1 à 2 heures maximum par focus
- Tester chaque fonction en Studio avant de passer à la suivante
- Utiliser Selene pour attraper les erreurs avant de tester

**Après chaque session :**
- Commit du code fonctionnel uniquement
- Documenter les décisions non évidentes (commentaire court dans le code)
- Mettre à jour le document correspondant si un changement de spec survient

### Ce que Claude Code ne fait pas
- Il ne remplace pas les tests en Studio
- Il ne valide pas l'expérience joueur — les playtests sont humains
- Il ne connaît pas l'état exact de Roblox Studio en temps réel

---

## 5. Gestion du Contenu (Scénarios)

Les scénarios sont le principal risque de production. Voici la stratégie pour les livrer.

### Structure de Rédaction (template)

```
SCÉNARIO — [ID] [Titre]
Difficulté : Simple / Standard / Complexe
Durée estimée : Court (5min) / Standard (8min) / Long (10min)

CONTEXTE (50 mots max) :
[Situation de départ, neutre, sans révélation]

VÉRITÉ OFFICIELLE :
- Fait 1 : [...]
- Fait 2 : [...]
- Fait 3 : [...]
- Fait 4 : [...]
- Fait 5 : [...]

VERSION ALTÉRÉE (Menteur) :
- Fait 1 : [identique]
- Fait 2 : [MODIFIÉ → ...]
- Fait 3 : [identique]
- Fait 4 : [MODIFIÉ → ...]
- Fait 5 : [identique]

QUESTIONS DISPONIBLES (pour l'Avocat) :
1. [...]
2. [...]
3. [...]
(10 questions minimum)

CONTRADICTIONS ATTENDUES :
- Champ [Heure] : vérité "18h" vs version altérée "21h"
- Champ [Lieu] : vérité "bibliothèque" vs "parc"
```

### Planning de Rédaction

| Semaine | Scénarios à produire | Priorité |
|---|---|---|
| Semaine 5 | S01-S03 (Simples) | Test du système |
| Semaine 8 | S04-S07 (Standards) | Remplir le pool |
| Semaine 11 | S08-S10 (Standards) + S11 (Complexe) | Couverture |
| Semaine 14 | S12-S15 (mix) + Dossiers Froids 1-8 | Lancement |
| Semaine 17 | Dossiers Froids 9-13 (buffer premium) | Post-lancement |

---

## 6. Gestion des Risques

| Risque | Probabilité | Impact | Mitigation |
|---|---|---|---|
| Retard technique (système plus complexe que prévu) | Haute | Moyen | Buffer de 2 semaines intégré dans le planning |
| Manque de scénarios au lancement | Moyenne | Élevé | Rédiger les scénarios en parallèle du dev, pas après |
| Bug critique découvert en playtest | Moyenne | Élevé | 3 semaines de polish dédiées (Milestone 1.7) |
| Filtre Roblox bloque des déclarations légitimes | Haute | Moyen | Tester le filtrage tôt (Milestone 1.2), listes de mots autorisés |
| Underperformance au lancement (CCU < 10) | Moyenne | Élevé | Plan de lancement TikTok préparé avant le lancement |
| Burnout solo dev | Moyenne | Élevé | Rythme durable, weekends non obligatoires |

---

## 7. Tests et Validation

### 7.1 Tests Techniques (continus)

- **Lint :** `selene src/` avant chaque commit
- **Format :** `stylua src/` avant chaque commit
- **Studio test :** chaque nouvelle feature testée en jeu avant push

### 7.2 Playtests Humains

| Milestone | Type | Participants |
|---|---|---|
| 1.2 (UI de base) | Playtest interne | 2-3 personnes de confiance |
| 1.4 (progression) | Playtest fermé | 5-8 personnes |
| 1.6 (économie) | Playtest économique | 3-5 personnes, vérifier les achats |
| 1.7 (pre-lancement) | Playtest public limité | 10-20 personnes non impliquées |

**Questions à poser à chaque playtest :**
1. As-tu compris ton rôle sans aide ?
2. À quel moment as-tu failli arrêter ?
3. As-tu eu envie de rejouer immédiatement après ?
4. Qu'est-ce que tu raconterais à un ami sur cette partie ?

### 7.3 Tests de Charge

Avant le lancement, simuler 20 joueurs simultanés (maximum recommandé par serveur) avec des profils variés (Premium, non-Premium, nouveaux joueurs, joueurs avancés).

---

## 8. Plan de Lancement

### 1 mois avant le lancement
- [ ] Page Roblox complète (description, screenshots, vidéo)
- [ ] Thumbnail finalisée et testée à 60×60px
- [ ] 3 clips TikTok / YouTube Shorts tournés (moments de gameplay réels)
- [ ] Compte TikTok / YouTube créé et 1er post publié

### 1 semaine avant le lancement
- [ ] Dernier playtest complet
- [ ] Tous les bugs critiques résolus
- [ ] DataStore en production (pas en mode Studio)
- [ ] Game Passes activés et testés
- [ ] Analytics Roblox vérifiés

### Jour du Lancement
- [ ] Publier le jeu (status Public)
- [ ] Publier le clip TikTok de lancement
- [ ] Monitorer les reviews en temps réel (première heure)
- [ ] Être disponible pour des corrections urgentes ce jour-là

### Semaine 1 post-lancement
- [ ] Correction de bugs remontés par les joueurs (< 24h pour les critiques)
- [ ] Monitorer J1 retention en priorité
- [ ] Publier 2ème clip TikTok
- [ ] Répondre aux reviews et commentaires

---

## 9. Outils de Gestion

| Besoin | Outil |
|---|---|
| Suivi des tâches | Fichier `TODO.md` dans le repo (simple et toujours à portée) |
| Versioning | Git + GitHub (déjà configuré) |
| Documentation | Dossier `docs/` dans le repo |
| Communication IA | Claude Code en session |
| Tests | Roblox Studio |
| Lint/Format | Selene + StyLua via Rokit |

---

## 10. Définition de "Terminé"

Une tâche est **terminée** quand :
1. Le code est écrit et lint sans erreur
2. La feature est testée en Studio (pas seulement en imaginé)
3. Le code est commité et pushé
4. La tâche est barrée dans le plan

Une feature est **prête pour le lancement** quand :
1. Elle a été testée par un humain extérieur
2. Elle ne casse aucune autre feature existante
3. Elle fonctionne sur mobile (testé sur un vrai appareil ou émulateur)
