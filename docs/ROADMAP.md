# Roadmap — The Witness Box
**Version 1.0**
**Format : Phases et Milestones — Solo Dev + IA**

---

## Vue d'Ensemble

| Phase | Période | Objectif |
|---|---|---|
| Phase 0 — Pré-production | ✅ Terminé | Concept validé, documents produits |
| Phase 1 — MVP | Mois 1 à 6 | Jeu jouable et lancé |
| Phase 2 — Post-lancement | Mois 7 à 12 | Rétention long terme, profondeur sociale |
| Phase 3 — Scale | Mois 13+ | Contenu saisonnier, systèmes avancés |

---

## Phase 0 — Pré-production ✅

**Livrables complétés :**
- [x] Concept validé (The Witness Box)
- [x] Analyse concurrentielle
- [x] Analyse cold start
- [x] Analyse économique
- [x] Simplification MVP / Phase 2 / Coupures
- [x] GDD.md
- [x] TECH_ARCHITECTURE.md
- [x] ART_DIRECTION.md
- [x] UI_UX.md
- [x] GAMEPLAY_SYSTEMS.md
- [x] ECONOMY.md
- [x] ANALYTICS.md
- [x] ROADMAP.md
- [x] PRODUCTION_PLAN.md
- [x] AI_RULES.md
- [x] Setup environnement (Rokit, Rojo, Wally, Selene, StyLua)
- [x] Dépôt GitHub connecté

---

## Phase 1 — MVP (Mois 1 à 6)

### Milestone 1.1 — Core Architecture (Semaines 1-3)
**Objectif :** Le squelette technique tient debout.

- [ ] Services serveur créés et testés en isolation (GameService, RoleService, TimerService)
- [ ] RemoteEvents câblés (GamePhaseChanged, VoteCast, DeclarationSubmitted)
- [ ] Machine à états fonctionnelle (LOBBY → INTRO → DECLARATION → DELIBERATION → SPRINT → VERDICT → POST_VERDICT)
- [ ] DataStore profil joueur (lecture/écriture, session lock)
- [ ] Scénario de test hard-codé (1 scénario, pas de base de données)

**Critère de sortie :** Une partie complète peut être jouée en Studio avec 2 joueurs test, du début au verdict.

---

### Milestone 1.2 — Interface de Base (Semaines 4-6)
**Objectif :** Le joueur voit quelque chose.

- [ ] HUD principal (timer, tableau contradictions placeholder, portrait témoin)
- [ ] DeclarationBuilder (4 champs template contraint + validation)
- [ ] 4 boutons de réaction (Juré)
- [ ] Écran de verdict (texte + animation basique)
- [ ] Menu principal (Jouer, Dossier, Mon Profil, Boutique — placeholders)
- [ ] Compatibilité mobile testée (écran 5 pouces)

**Critère de sortie :** Un joueur externe peut jouer une partie sans aide.

---

### Milestone 1.3 — Cold Start & Formats (Semaines 7-9)
**Objectif :** Le jeu marche avec 1 à 6 joueurs.

- [ ] MatchmakingService (détection du nombre de joueurs, sélection du format)
- [ ] Format Solo (Dossier Froid) avec 5 dossiers de test
- [ ] Format Duel (2 joueurs)
- [ ] Format Mini (4 joueurs)
- [ ] Format Full (6 joueurs)
- [ ] Mode Cascade (enchaînement automatique)
- [ ] File d'Attente Active (Solo pendant l'attente)

**Critère de sortie :** Le jeu lance la bonne configuration quel que soit le nombre de joueurs.

---

### Milestone 1.4 — Progression & Économie (Semaines 10-12)
**Objectif :** Le joueur a une raison de revenir.

- [ ] Système de XP et de Rang (8 paliers)
- [ ] Jetons de Prétoire (gains et dépenses)
- [ ] Dossier Personnel (profil public)
- [ ] Réputation (Crédibilité + Perspicacité)
- [ ] Daily Login (7 jours)
- [ ] 5 badges implémentés
- [ ] Vote de Respect post-partie
- [ ] Catalogue cosmétiques (5 items gratuits minimum)

**Critère de sortie :** Un joueur de retour après 3 jours voit sa progression et ses récompenses.

---

### Milestone 1.5 — Contenu & Scénarios (Semaines 13-17)
**Objectif :** Assez de contenu pour que le jeu ne s'épuise pas en 2 heures.

- [ ] 15 scénarios complets (5 Simples, 7 Standards, 3 Complexes)
- [ ] 5 Dossiers Froids gratuits
- [ ] 8 Dossiers Froids premium (buffer Pass Dossiers Classifiés)
- [ ] Système de rotation des Dossiers Froids (3 disponibles, rotation 24h)
- [ ] Conférence de Presse post-partie (template basique + partage)

**Critère de sortie :** Un joueur peut jouer 2h sans voir deux fois le même scénario.

---

### Milestone 1.6 — Économie Live (Semaines 18-20)
**Objectif :** Les achats fonctionnent.

- [ ] 3 Game Passes implémentés (Procureur Général, Dossiers Classifiés, Salle de Presse)
- [ ] 3 Developer Products (Boost Jetons, Jeton Prestige, Réouverture Dossier)
- [ ] Pack Nouveau Venu (timer 7 jours)
- [ ] Catalogue cosmétiques premium (8 items minimum)
- [ ] Cosmétiques de rang (débloqués automatiquement)
- [ ] Tests de paiement complets en environnement Roblox

**Critère de sortie :** Un achat peut être effectué et ses effets sont visibles immédiatement.

---

### Milestone 1.7 — Polish & Lancement (Semaines 21-26)
**Objectif :** Le jeu est prêt à être vu.

- [ ] Direction artistique salle d'audience complète
- [ ] Animations Portrait Vivant (3 états)
- [ ] Effets visuels (Éclair Contradiction, Sprint Final, Verdict)
- [ ] Système audio (ambiance + effets sonores)
- [ ] Thumbnail et icône finalisées
- [ ] Tests de charge (20 joueurs simultanés)
- [ ] Anti-cheat vérifié (rôles non exposés, votes server-side)
- [ ] Playtests externes (minimum 10 personnes non impliquées dans le projet)
- [ ] Corrections post-playtests
- [ ] **Lancement Public**

**Critère de sortie :** Thumbs Up Rate > 70% lors des playtests.

---

## Phase 2 — Post-Lancement (Mois 7 à 12)

*À planifier en détail après les métriques du premier mois.*

### Priorité Haute (Mois 7-8)
- Système de remplacement de joueurs déconnectés (NPC automatique)
- Amélioration du Tableau des Contradictions (interactions)
- Nouveaux scénarios (cadence : 2/mois)
- Analytics complets (module de tracking événements)
- Corrections de bugs et équilibrage basé sur les données

### Priorité Moyenne (Mois 9-10)
- Double Menteur (format optionnel en FULL)
- Voie de Carrière Enquête (2ème voie de rang)
- Rivalités Naturelles (après 5 affrontements)
- Déclaration Scellée (mécanique additionnelle)
- Pass Avocat de la Défense

### Priorité Basse (Mois 11-12)
- Première Saison Compétitive (si base > 5 000 DAU)
- Cabinets d'Avocats (si base > 3 000 joueurs actifs)
- Vote de Question Ciblée (jurés influencent l'Avocat)
- Tableau de Bord Juré personnel

---

## Phase 3 — Scale (Mois 13+)

*Déclenché uniquement si les métriques Phase 2 sont atteintes.*

- Contenu saisonnier complet (Pass de Saison, cosmétiques exclusifs)
- Défis Inter-Cabinets
- Troisième voie de carrière (L'Ombre)
- Événements spéciaux (scénarios limités dans le temps)
- Collaborations thématiques

---

## Indicateurs de Passage de Phase

### Phase 1 → Phase 2
- Thumbs Up > 75%
- J7 Retention > 18%
- CCU stable > 30
- 0 bug critique en suspens

### Phase 2 → Phase 3
- DAU stable > 10 000
- J30 Retention > 10%
- Revenue/DAU > 2 R
- Communauté active (Discord ou équivalent)
