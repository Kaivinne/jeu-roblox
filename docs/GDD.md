# Game Design Document — The Witness Box
**Version 1.0 — MVP**
**Statut : Document Maître / Référence de Production**

---

## 1. Vue d'Ensemble

| Champ | Valeur |
|---|---|
| Titre | The Witness Box |
| Plateforme | Roblox (PC + Mobile) |
| Genre | Social Deduction / Courtroom Drama |
| Joueurs | 1 à 8 par session |
| Durée d'une partie | 3 à 10 minutes selon le format |
| Public cible | 13-24 ans |
| Pitch | Un procès fictif. Certains disent la vérité. Certains mentent. Le jury tranche. |

---

## 2. Concept Central

The Witness Box est un jeu de déduction sociale structuré autour de procès fictifs. Chaque session place des joueurs dans des rôles asymétriques : **Témoins** (honnêtes ou menteurs) et **Jurés** (détectives). La tension vient de l'incertitude — le jury ne sait jamais avec certitude qui ment.

### Proposition de valeur unique
- Aucun équivalent direct sur Roblox en 2026
- Le drama est **structurel**, pas accidentel
- Chaque partie génère une histoire racontable
- Contenu viral natif (clips TikTok) sans configuration supplémentaire

### Règle de design fondamentale
> L'argent achète ce que tu es, pas ce que tu peux faire. Un joueur gratuit et un joueur payant ont exactement les mêmes capacités mécaniques.

---

## 3. Rôles

### 3.1 Témoin Honnête
- Reçoit la **vérité officielle** de la partie (série de faits établis)
- Doit défendre cette vérité face aux questions
- Objectif : être cru par le jury
- Peut être nerveux par nature — les innocents se font parfois condamner

### 3.2 Témoin Menteur
- Reçoit une **version altérée** des faits (1 à 3 éléments faux)
- Doit maintenir une histoire cohérente avec sa version fausse
- Objectif : être acquitté par le jury
- Ne sait pas qui sont les autres menteurs en format Double Menteur (Phase 2)

### 3.3 Avocat de l'Accusation
- Pose les questions aux témoins depuis une liste contextuelle
- Objectif : faire émerger les incohérences
- Ne connaît pas la vérité officielle — il enquête comme le jury

### 3.4 Juré
- Analyse les déclarations, vote à la fin
- Dispose d'un Bouton d'Objection (usage unique par partie)
- Peut soumettre des réactions visuelles pendant les déclarations
- Objectif : rendre le bon verdict

---

## 4. Formats de Jeu

### 4.1 Dossier Froid — Solo
- 1 joueur joue le rôle du juré face à des témoignages scriptés
- Utilisé pendant la file d'attente ou quand aucun lobby n'est disponible
- Durée : 4-5 minutes
- Récompense : Jetons de Prétoire + progression de rang

### 4.2 Duel — 2 joueurs
- 1 Accusé vs 1 Détective
- 5 questions, vote final
- Durée : 3-4 minutes
- Format de cold start — évite les lobbies vides

### 4.3 Mini-Procès — 4 joueurs
- 1 Accusé, 1 Avocat de l'Accusation, 2 Jurés
- Format complet raccourci
- Durée : 5-6 minutes

### 4.4 Procès Complet — 6+ joueurs
- 1 Accusé, 1 Avocat de l'Accusation, 2-3 Témoins, 2-3 Jurés
- Format cible — expérience complète
- Durée : 8-10 minutes

### Sélection automatique du format
Le système détecte le nombre de joueurs disponibles et sélectionne le format optimal sans intervention manuelle. Le joueur ne voit jamais "format dégradé" — il voit "Procès Express" ou "Procès Complet".

---

## 5. Boucle de Jeu Principale

```
[Lobby / File Active]
        ↓
[Attribution des Rôles — Server Side]
        ↓
[Présentation du Scénario — Animée, 30 secondes]
        ↓
[Phase de Déclarations — Timer 25s/déclaration]
  → Témoin assemble sa déclaration (Template Contraint)
  → Jurés réagissent (fenêtre 8 secondes)
  → Tableau des Contradictions mis à jour automatiquement
        ↓
[Phase de Délibération — 45 secondes]
  → Jurés votent progressivement
  → Bouton Objection disponible (usage unique)
        ↓
[Sprint Final — 60 secondes]
  → Vote final, interface simplifiée
  → Compte à rebours visible de tous
        ↓
[Verdict + Révélation]
  → Qui mentait, quelles déclarations étaient fausses
  → Conférence de Presse générée (template partageable)
        ↓
[Post-Verdict — 60 secondes chat libre]
  → Seul moment de texte libre de la partie
  → Distribution des Jetons et points de rang
        ↓
[Mode Cascade — partie suivante automatique]
```

---

## 6. Système de Déclarations

### Template Contraint (Solution B)
Les déclarations sont construites par remplissage de blancs dans des phrases pré-construites. Pas de texte libre pendant la partie.

**Structure d'une déclaration :**
```
"J'étais [LIEU — 20 car. max] avec [PERSONNE — 20 car. max]
 à [HEURE] quand [ÉVÉNEMENT — 20 car. max]."
```

**Règles :**
- Champs filtrés en temps réel par `TextChatService`
- Si un champ est bloqué par le filtre, la déclaration reste valide sans ce champ
- Le menteur remplit les mêmes champs mais avec des données fausses
- Durée maximale de remplissage : **25 secondes** (timer visible)

### Réactions Post-Déclaration
Fenêtre de 8 secondes après chaque déclaration. Chaque juré peut appuyer sur une réaction :
- 👁 Suspicion
- ✓ Crédibilité
- ? Confusion
- ⚡ Contradiction détectée

Les réactions sont visibles de tous en temps réel sous l'avatar du juré. Elles n'influencent pas le verdict mécaniquement.

---

## 7. Tableau des Contradictions

Affiché en permanence en haut de l'écran. Représentation graphique (pictogrammes) des informations clés de chaque déclaration. Le système détecte automatiquement les contradictions directes entre déclarations et affiche une ligne rouge entre les deux éléments contradictoires.

**Contraintes :**
- Uniquement les contradictions directes et vérifiables (même champ, valeurs différentes)
- Pas de déduction croisée automatique — le raisonnement reste humain
- Mise à jour en temps réel

---

## 8. Système de Bouton d'Objection

- Disponible uniquement pour les Jurés
- Usage unique par partie
- Interrompt la déclaration en cours
- Le juré choisit parmi 3 objections pré-définies contextuellement
- Le témoin a 15 secondes pour répondre avec un bloc narratif
- Irréversible — impossible de "sauvegarder" son objection

---

## 9. Scénarios

### Structure d'un scénario
```
Titre: "L'Incident du Couloir"
Contexte: [Description de la situation, 50 mots max]
Vérité Officielle: [Série de 5 à 7 faits établis]
Version Altérée: [Vérité avec 1 à 3 faits modifiés]
Questions Disponibles: [Liste de 10 questions pour l'Avocat]
Tags: [Ambiance: Quotidien / Mystérieux / Absurde]
Durée estimée: [Court / Standard / Long]
```

### Bibliothèque MVP
Minimum 15 scénarios au lancement, couvrant 3 niveaux de complexité.
- 5 scénarios Simples (1 fait altéré)
- 7 scénarios Standards (2 faits altérés)
- 3 scénarios Complexes (3 faits altérés + rebondissement)

---

## 10. Progression

### Rang Unique (MVP)
8 paliers, une seule voie au lancement.

| Palier | Titre | XP requis |
|---|---|---|
| 1 | Stagiaire | 0 |
| 2 | Clerc | 500 |
| 3 | Avocat Stagiaire | 1 500 |
| 4 | Avocat | 3 500 |
| 5 | Avocat Confirmé | 7 000 |
| 6 | Maître | 13 000 |
| 7 | Grand Juge | 22 000 |
| 8 | Juge Suprême | 35 000 |

### Gains d'XP
| Action | XP |
|---|---|
| Finir une partie | 50 |
| Verdict correct (juré) | +75 |
| Acquitté en tant que menteur | +100 |
| Condamné en tant que menteur | +25 (tentative honorée) |
| Dossier Froid complété | +40 |
| Vote de respect reçu | +20 |

### Récompenses de Rang
Chaque palier débloque un cosmétique gratuit. Voir `ECONOMY.md`.

---

## 11. Identité Persistante (MVP)

### Dossier Personnel
Page de profil in-game contenant :
- Avatar + Rang actuel
- Deux barres de réputation : **Crédibilité** et **Perspicacité**
- 3 badges affichés (choix du joueur)
- 3 parties épinglées manuellement
- 3 statistiques (fixes au MVP)

### Réputation
**Crédibilité** : monte quand tes déclarations honnêtes sont crues. Descend quand tu te fais prendre en train de mentir.
**Perspicacité** : monte quand tu votes correctement en tant que juré. Descend quand tu te trompes.

### 5 Badges de Lancement
1. Le Mensonge Parfait — acquitté 10× de suite en tant que menteur
2. L'Acquitté à l'Unanimité — 0 vote coupable alors que tu mentais
3. Le Jury Infaillible — 20 verdicts corrects consécutifs
4. Le Bon Samaritain — vote de respect de tous les joueurs d'une partie
5. L'Affaire Mémorable — épingler manuellement une partie (débloqué à Rang 3)

---

## 12. Règles Anti Pay-to-Win

Aucune exception.
- Aucun avantage mécanique achetable
- Les Jetons de Prétoire (monnaie gratuite) s'accumulent uniquement via le gameplay
- Les Robux achètent uniquement des cosmétiques et du contenu solo
- Les joueurs premium ont le même temps d'objection, le même timer, les mêmes informations

---

## 13. Hors-Scope MVP

Les fonctionnalités suivantes sont explicitement hors du MVP v1.0 :

- NPCs comportementaux avancés
- Double Menteur
- Rivalités et Cabinets
- Saisons compétitives
- Rôle d'Avocat de la Défense
- Tableau de Bord Juré
- Déclaration Scellée
- Événements aléatoires (Juge Fantôme, Coupure de Courant, etc.)

Référence complète : `ROADMAP.md`
