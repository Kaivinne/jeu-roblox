# Testing Guide — The Witness Box

Version : M2.8  
Dernière mise à jour : 2026-06-27

Ce guide explique comment préparer l'environnement de test, lancer le jeu, surveiller les logs, et signaler un bug. Destiné aux testeurs internes.

---

## 1. Prérequis

| Outil | Version requise | Vérification |
|---|---|---|
| Roblox Studio | Dernière version stable | Lancez Studio → Help → About |
| Rojo | 7.4.4 (via Rokit) | `~/.rokit/bin/rojo --version` |
| Rokit | Dernière version | `rokit --version` |
| Git | Toute version récente | `git --version` |

Cloner le dépôt si ce n'est pas déjà fait :
```
git clone https://github.com/Kaivinne/jeu-roblox.git
cd jeu-roblox
```

---

## 2. Lancer Rojo

Rojo synchronise les fichiers `.luau` du dossier `src/` vers Roblox Studio en temps réel.

**Étape 1 — Démarrer le serveur Rojo**
```bash
cd TheInterview
~/.rokit/bin/rojo serve default.project.json
```

Vous devriez voir :
```
Rojo server listening on port 34872
```

**Étape 2 — Connecter Studio**

1. Ouvrir Roblox Studio
2. Ouvrir le plugin Rojo (barre de plugins)
3. Cliquer **Connect** (l'adresse par défaut `localhost:34872` est correcte)
4. Vérifier que les scripts apparaissent dans `ServerScriptService.Server` et `StarterPlayerScripts.Client`

**Étape 3 — Vérifier la synchronisation**

Modifier une ligne dans `src/client/init.client.luau` et sauvegarder. Le fichier dans Studio doit se mettre à jour instantanément.

> Rojo ne synchronise pas les assets Roblox (sons, images) — uniquement les scripts `.luau`.

---

## 3. Tester en Studio

### Mode solo (1 joueur simulé)

1. Cliquer **Play** (bouton ▶) dans Studio
2. La partie démarre automatiquement après 5 secondes (Studio auto-start)
3. Le joueur simulé est assigné Juror en Solo
4. Le NPC déclare entre 5 et 12 secondes après le début de Testimony

### Mode Duel (2 joueurs simulés)

1. Cliquer **Start Server** dans l'onglet Test
2. Cliquer **Start 1 Player** (ou **Start 2 Players** pour un vrai Duel)
3. Chaque client simulé s'ouvre dans une fenêtre séparée

> En mode « Start 2 Players », les deux fenêtres client reçoivent leurs rôles respectifs. Il est possible de vérifier que le Liar voit DeclarationBuilder et que le Juré voit ReactionBar.

### Mode multi (3–6 joueurs)

Utiliser **Start Server** → ajouter plusieurs clients via **Add Player** autant de fois que nécessaire. Chaque joueur s'ouvre dans une fenêtre Studio séparée.

---

## 4. Activer le DataStore en Studio

Par défaut, DataStoreService renvoie une erreur en Studio (mode offline). Pour tester la persistance réelle :

1. Dans Studio : **File → Game Settings → Security**
2. Activer **Enable Studio Access to API Services**
3. Sauvegarder et relancer la session de test

Logs confirmant que DataStore est actif :
```
[PlayerDataService] DataStore connecté : PlayerProfiles_v1
[PlayerDataService] Profil chargé pour <DisplayName> — Jetons: X | Rang: Y
```

> Sans cette option, le profil est chargé en mémoire uniquement (Jetons et cosmétiques ne persistent pas entre les sessions).

---

## 5. Tester avec plusieurs joueurs

### En Studio

Méthode la plus simple : **Start Server** + N clients simulés via l'onglet Test.

### En production (Roblox.com)

1. Publier le jeu (File → Publish to Roblox)
2. Définir le jeu en **Private** ou en accès restreint pendant les tests
3. Inviter les testeurs via un lien d'invitation
4. Surveiller les logs via la Developer Console in-game (`F9` ou menu Developer)

---

## 6. Logs à surveiller

### Logs serveur (Output Studio)

| Préfixe | Signification |
|---|---|
| `[Bootstrap]` | Initialisation des services |
| `[Net]` | Création des remotes |
| `[PlayerDataService]` | Chargement/sauvegarde des profils |
| `[MatchService]` | Transitions de phase, votes, déclarations |
| `[RoleService]` | Attribution des rôles |
| `[CaseService]` | Sélection d'affaire |
| `[RewardService]` | Distribution des récompenses |
| `[CosmeticService]` | Achats et équipements |
| `[Analytics]` | Événements de jeu (console uniquement) |

**Séquence normale d'un match Solo :**
```
[Bootstrap] The Witness Box — serveur prêt
[PlayerDataService] Profil chargé pour <nom>
[MatchService] Studio : démarrage forcé
[MatchService] Lobby → Matchmaking (10s | Solo | 1 joueur(s))
[RoleService] <nom> (UserId) → Juror
[CaseService] Affaire sélectionnée : Le Collier Disparu
[MatchService] Matchmaking → Intro (20s)
[MatchService] NPC déclare (Honnête|Menteur) : <valeurs>
[MatchService] Verdict: Guilty|Innocent (X coupable / Y innocent) — Témoin a menti: true|false
[RewardService] <nom> → +Xj (verdict: correct|incorrect) | Perspicacité: N | Rang: Y
```

**Logs d'erreur à signaler immédiatement :**
- Toute ligne commençant par `[ERROR]` ou `warn(`
- `DataStore indisponible` sans que l'API soit désactivée volontairement
- Crashes de script (rouge dans Output)
- Boucles infinies (Studio freeze)

### Logs client

Ouvrir la Developer Console (`F9`) → onglet **Client**.

Logs normaux :
```
[Client] The Witness Box v1.7 — UI prête
```

Erreurs à surveiller :
- `[Net] RemoteEvent 'X' introuvable` → remote non créé côté serveur
- `[Net] Remotes introuvable après 15s` → Bootstrap n'a pas tourné

---

## 7. Métriques à noter manuellement

Pour chaque session de test, noter ces valeurs dans la feuille de suivi :

| Métrique | Comment la mesurer |
|---|---|
| Durée effective par phase | Chronomètre pendant la session |
| Taux de verdicts corrects | Compter sur plusieurs parties |
| Nombre de déconnexions involontaires | Compter les sorties inattendues |
| Jetons moyens gagnés par partie | Lire ProfilePanel après chaque match |
| Nombre de bugs bloquants | Compter les tests `✗` de la checklist |
| Temps de chargement du profil | Temps entre connexion et premier ProfileUpdated (log) |
| Latence perçue achat/équipement | Temps entre clic ACHETER et mise à jour de l'UI |

---

## 8. Signaler un bug

### Informations obligatoires

1. **Titre court** : « [Phase] Description courte » — ex : `[Verdict] VerdictScreen ne s'ouvre pas`
2. **Étapes de reproduction** : numérotées, précises
3. **Comportement attendu** : ce qui devrait se passer
4. **Comportement observé** : ce qui se passe réellement
5. **Logs** : copier-coller la section Output Studio concernée
6. **Environnement** : Solo / Duel / Mini / Full, Studio / Production, PC / Mobile
7. **Fréquence** : toujours / parfois / une seule fois

### Où reporter

Ouvrir une issue sur GitHub :
```
https://github.com/Kaivinne/jeu-roblox/issues/new
```

Utiliser les labels :
- `bug` — comportement incorrect confirmé
- `ui` — problème d'affichage uniquement
- `server` — problème côté serveur (logs serveur requis)
- `datastore` — problème de persistance
- `blocker` — empêche de tester d'autres fonctionnalités

### Bugs non à reporter

- Comportements listés dans `KNOWN_LIMITATIONS.md` (sons placeholders, 3 affaires seulement, etc.)
- Problèmes de performance Roblox non liés au code du jeu
- Problèmes de Rojo lui-même (synchronisation, port)

---

## 9. Checklist avant chaque session de test

- [ ] `git pull` pour avoir la dernière version
- [ ] Rojo lancé et connecté à Studio
- [ ] API Services activés si test DataStore
- [ ] Output Studio visible et propre (pas de logs d'une ancienne session)
- [ ] `PLAYTEST_CHECKLIST.md` imprimé ou ouvert en parallèle
- [ ] Feuille de métriques prête

---

## 10. Raccourcis utiles en Studio

| Action | Raccourci |
|---|---|
| Démarrer en solo | F5 |
| Démarrer serveur + clients | Onglet Test → Start Server |
| Developer Console | F9 (en jeu) |
| Vider l'Output | Clic droit dans Output → Clear |
| Pause le serveur | Onglet Test → Pause |
| Arrêter la session | Shift+F5 ou bouton Stop |
