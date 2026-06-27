# Playtest Checklist — The Witness Box

Version testée : M2.8  
Date : ___________  
Testeur(s) : ___________  
Environnement : Studio / Production (entourer)

---

## Instructions

Cocher chaque case au fur et à mesure. Noter un `✗` si le test échoue, avec une description courte dans la colonne Remarques. Toute case non testée doit être justifiée (ex. : « impossible à tester seul »).

---

## 1. Solo (1 joueur)

| # | Test | ✓/✗ | Remarques |
|---|---|---|---|
| 1.1 | Lancer Studio avec 1 joueur — la partie démarre automatiquement en 5s | | |
| 1.2 | Phase Matchmaking : rôle Juré assigné, toast affiché | | |
| 1.3 | Phase Intro : IntroScreen s'ouvre, affaire + objectif corrects | | |
| 1.4 | Phase Testimony : le NPC déclare automatiquement (entre 5–12 s) | | |
| 1.5 | Toast de déclaration NPC visible | | |
| 1.6 | Si le NPC ment : ContradictionDetected → flash rouge + toast | | |
| 1.7 | Phase Deliberation : timer HUD décompte, ReactionBar visible | | |
| 1.8 | Phase Verdict : VerdictScreen s'ouvre, boutons COUPABLE/INNOCENT actifs | | |
| 1.9 | Vote soumis → bouton verrouillé, son joué | | |
| 1.10 | Phase PostVerdict : SummaryScreen affiche vérité, déclaration NPC, verdict joueur | | |
| 1.11 | Récompense Jetons affichée dans SummaryScreen (+10 base, +15 si correct) | | |
| 1.12 | ProfilePanel mis à jour (Jetons, Perspicacité, Rang) | | |
| 1.13 | Bouton REJOUER masque SummaryScreen | | |
| 1.14 | Retour en Lobby → joueurs téléportés à la galerie | | |
| 1.15 | Deuxième partie démarre (affaire différente de la première si possible) | | |

---

## 2. Duel (2 joueurs)

| # | Test | ✓/✗ | Remarques |
|---|---|---|---|
| 2.1 | 2 joueurs connectés → partie démarre après délai Lobby | | |
| 2.2 | Rôles assignés : 1 Liar, 1 Juré — chaque joueur voit son propre rôle uniquement | | |
| 2.3 | Liar voit DeclarationBuilder avec indicateurs de vérité (✓ sur champ correct) | | |
| 2.4 | Liar peut soumettre une déclaration (tous champs ≠ vérité) | | |
| 2.5 | Juré voit ReactionBar pendant Testimony | | |
| 2.6 | Contradiction détectée côté serveur si Liar ment → flash rouge diffusé à tous | | |
| 2.7 | Juré vote COUPABLE et Liar a menti → verdict correct dans SummaryScreen | | |
| 2.8 | Juré vote INNOCENT et Liar a menti → verdict incorrect, vibration panneau | | |
| 2.9 | Liar voit SummaryScreen avec texte « Vous étiez le Menteur » | | |
| 2.10 | Récompenses distribuées correctement aux deux joueurs | | |
| 2.11 | ProfileUpdated reçu par les deux clients après PostVerdict | | |

---

## 3. Mini (3–4 joueurs)

| # | Test | ✓/✗ | Remarques |
|---|---|---|---|
| 3.1 | 3 joueurs → Format Mini sélectionné | | |
| 3.2 | Rôles : 1 Liar, 1 Prosecutor, 1 Juré (ou plus selon count) | | |
| 3.3 | Prosecutor voit ReactionBar (pas DeclarationBuilder) | | |
| 3.4 | Tous les joueurs reçoivent VerdictRevealed avec les bonnes données | | |
| 3.5 | SummaryScreen Prosecutor affiche verdict collectif avec bonne couleur (Guilty=rouge, Innocent=vert) | | |
| 3.6 | 4 joueurs → format Mini, rôles cohérents | | |

---

## 4. Full (5–6 joueurs)

| # | Test | ✓/✗ | Remarques |
|---|---|---|---|
| 4.1 | 5 joueurs → Format Full : 1 Liar, 1 Prosecutor, 1 Defense, 2 Jurés | | |
| 4.2 | 6 joueurs → 3 Jurés, verdict basé sur majorité | | |
| 4.3 | Égalité de votes (ex: 1-1) → verdict Innocent | | |
| 4.4 | Defense reçoit son rôle et voit ReactionBar | | |
| 4.5 | Tous les clients reçoivent le même VerdictRevealed | | |
| 4.6 | Récompenses distribuées à tous les joueurs connectés | | |

---

## 5. Mobile

| # | Test | ✓/✗ | Remarques |
|---|---|---|---|
| 5.1 | HUD visible et lisible sur écran 375 × 667 (iPhone SE) | | |
| 5.2 | ProfilePanel non tronqué en bas à gauche | | |
| 5.3 | Bouton BOUTIQUE accessible (tap) | | |
| 5.4 | IntroScreen centré et lisible | | |
| 5.5 | DeclarationBuilder : boutons < et > ≥ 44 px, activables au tap | | |
| 5.6 | ReactionBar : boutons utilisables au tap | | |
| 5.7 | VerdictScreen : boutons COUPABLE/INNOCENT cliquables | | |
| 5.8 | SummaryScreen : vérité officielle scrollable si nécessaire | | |
| 5.9 | ShopScreen : liste des items scrollable, boutons accessibles | | |
| 5.10 | Toast : position correcte (sous le HUD, pas derrière) | | |
| 5.11 | Aucun texte tronqué sur les boutons ReactionBar | | |

---

## 6. PC

| # | Test | ✓/✗ | Remarques |
|---|---|---|---|
| 6.1 | HUD centré, timer et infos lisibles | | |
| 6.2 | Tous les panneaux centrés et proportionnés | | |
| 6.3 | Bouton BOUTIQUE cliquable à la souris | | |
| 6.4 | DeclarationBuilder : navigation < > fluide | | |
| 6.5 | Aucun chevauchement de ScreenGui inattendu | | |
| 6.6 | SummaryScreen pas tronqué sur résolution 1920 × 1080 | | |

---

## 7. Boutique (cosmétiques)

| # | Test | ✓/✗ | Remarques |
|---|---|---|---|
| 7.1 | Clic BOUTIQUE → ShopScreen s'ouvre avec 5 items | | |
| 7.2 | Jetons affichés correctement dans le header | | |
| 7.3 | Acheter un item avec Jetons suffisants → toast succès, item passe à « ÉQUIPER » | | |
| 7.4 | Tenter d'acheter sans Jetons → toast erreur, aucune déduction | | |
| 7.5 | Double achat du même item → refusé par le serveur | | |
| 7.6 | Équiper un cadre → ProfilePanel change de couleur (bronze/argent) | | |
| 7.7 | Équiper un deuxième cadre → remplace le premier | | |
| 7.8 | Fermer la boutique → ShopScreen masqué | | |
| 7.9 | Rouvrir la boutique → état cohérent (items possédés marqués) | | |
| 7.10 | Rejouer une partie → cadre toujours équipé après PostVerdict | | |

---

## 8. DataStore & Persistence

| # | Test | ✓/✗ | Remarques |
|---|---|---|---|
| 8.1 | Jouer une partie, gagner des Jetons → quitter → rejoindre → Jetons persistés | | |
| 8.2 | Acheter un cosmétique → quitter → rejoindre → item toujours possédé | | |
| 8.3 | Équiper un cadre → quitter → rejoindre → cadre toujours équipé au login | | |
| 8.4 | Rang recalculé correctement après plusieurs verdicts corrects | | |
| 8.5 | Profil ancien (avant M2.7, sans cosmétiques) chargé sans erreur | | |

---

## 9. Déconnexion en cours de partie

| # | Test | ✓/✗ | Remarques |
|---|---|---|---|
| 9.1 | Joueur quitte pendant Testimony → autres joueurs peuvent continuer | | |
| 9.2 | Dernier joueur quitte pendant Testimony → serveur reset à Lobby | | |
| 9.3 | Juré quitte avant de voter → vote non comptabilisé, verdict quand même calculé | | |
| 9.4 | Liar quitte avant de déclarer → pas de crash, SummaryScreen gère « déclaration vide » | | |
| 9.5 | Joueur quitte pendant PostVerdict → récompenses distribuées aux joueurs restants uniquement | | |
| 9.6 | Joueur rejoint pendant une partie active → attend le prochain match sans erreur | | |

---

## 10. Verdict sans vote

| # | Test | ✓/✗ | Remarques |
|---|---|---|---|
| 10.1 | Timer Verdict expire sans vote du Juré → ActionRejected reçu | | |
| 10.2 | Vote non comptabilisé → verdict calculé sur les votes reçus uniquement | | |
| 10.3 | SummaryScreen affiche « Vous n'avez pas voté » pour le Juré absent | | |
| 10.4 | Aucun crash si 0 votes (ex: tous les Jurés déconnectés) | | |

---

## 11. UI petite résolution

| # | Test | ✓/✗ | Remarques |
|---|---|---|---|
| 11.1 | 768 × 432 : HUD lisible, ProfilePanel non coupé | | |
| 11.2 | 768 × 432 : ShopScreen scrollable, boutons activables | | |
| 11.3 | 768 × 432 : SummaryScreen pas de chevauchement | | |
| 11.4 | 375 × 667 (mobile portrait) : tous les panneaux < 90 % de largeur | | |
| 11.5 | Aucun texte en dehors des limites de son conteneur | | |

---

## Résumé de session

| Métrique | Valeur |
|---|---|
| Total tests | 66 |
| Réussis | / 66 |
| Échoués | |
| Non testés | |
| Bloquants | |

Bugs à reporter : (lister ici, puis ouvrir une issue GitHub)

Signature testeur : _________________________  Date : ___________
