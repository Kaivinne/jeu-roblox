# Known Limitations — The Witness Box

Version : M2.8  
Dernière mise à jour : 2026-06-27

Ce document liste honnêtement les limitations connues du jeu à ce stade du développement. Elles ne constituent pas des bugs — ce sont des fonctionnalités délibérément différées ou des contraintes de périmètre.

---

## 1. Lobby & Matchmaking

**Pas de vrai lobby visuel**
Le Lobby est une phase temporisée (60 s) sans interface dédiée. Les joueurs voient uniquement un toast « En attente de joueurs… » et le HUD. Il n'y a pas d'écran d'attente, de liste de joueurs, ni de bouton de démarrage manuel.

**Pas de matchmaking multi-serveur**
Chaque instance de serveur gère sa propre boucle indépendamment. Il n'y a pas de service centralisé (TeleportService, MessagingService) pour regrouper des joueurs de différents serveurs. Un serveur avec 1 joueur ne sera pas rejoint par un joueur d'un autre serveur.

**Seuil de démarrage Duel fixe**
La partie démarre dès que 2 joueurs sont présents, après le délai Lobby. Il n'y a pas de bouton « Démarrer maintenant » ni de vote de démarrage.

---

## 2. Contenu

**3 affaires seulement**
Le catalogue contient exactement 3 affaires (case_001, case_002, case_003). L'anti-répétition évite de rejouer la même affaire deux fois de suite, mais avec 3 affaires, les joueurs verront rapidement toutes les combinaisons.

**NPC témoin simplifié (mode Solo)**
Le NPC décide aléatoirement (50/50) de mentir ou non. Sa déclaration est construite mécaniquement à partir de l'affaire. Il n'y a pas de personnalité, de style verbal, ni de comportement adaptatif.

**Pas de HonestWitness humain en Duel**
En format Duel (2 joueurs), les rôles sont Liar + Juror. Il n'y a pas de HonestWitness humain — le NPC remplace ce rôle uniquement en Solo. En Duel, le Liar déclare seul.

---

## 3. Audio & Visuels

**Sons placeholders**
Tous les effets sonores utilisent des assets Roblox génériques (rbxassetid) disponibles publiquement. Ce ne sont pas des sons finaux. Le sound design complet est prévu en phase post-MVP.

**Pas de musique d'ambiance finale**
La musique d'ambiance est une boucle courte et générique. Il n'y a pas de compositions originales, ni de variations par phase ou par affaire.

**Pas de doublage**
Aucun dialogue n'est doublé. Tout le contenu textuel est en français écrit uniquement.

**Pas d'assets graphiques finaux**
Les personnages, décors et accessoires utilisent les assets Roblox par défaut. La salle d'audience est construite avec des primitives basiques. L'art direction finale (cf. `ART_DIRECTION.md`) n'est pas encore implémentée.

**Pas d'animations de personnages**
Les personnages restent statiques. Il n'y a pas d'animations d'entrée, de témoignage ou de verdict.

**Pas de VFX avancés**
Les effets visuels se limitent à des tweens CSS (flash rouge, vibration de panneau, pulse de bouton). Il n'y a pas de particules, de shaders, ni d'effets 3D.

---

## 4. Économie & Cosmétiques

**Pas de Robux**
La boutique accepte uniquement les Jetons (monnaie gratuite obtenue en jeu). Il n'y a pas de Developer Products, de Game Pass, ni de micro-transactions.

**5 cosmétiques uniquement**
Le catalogue cosmétique contient 5 items : 2 cadres de profil, 2 badges, 1 effet de verdict. Les badges et l'effet de verdict sont achetables mais n'ont pas encore d'effet visuel côté jeu (seul le cadre de profil est appliqué visuellement).

**Cadre de profil uniquement visible localement**
Le changement de couleur du cadre dans le ProfilePanel n'est visible que par le joueur lui-même. Il n'y a pas de système pour afficher le cadre d'un autre joueur.

**Pas de daily login, battle pass ni trading**
Aucun système de fidélisation ou d'échange entre joueurs n'est prévu dans la vertical slice actuelle.

---

## 5. Modération & Sécurité

**Pas de filtre de chat avancé**
Les noms de joueurs et DisplayNames proviennent directement de Roblox. Il n'y a pas de système de signalement in-game.

**Pas de vérification anti-cheat**
Le serveur valide toutes les actions critiques (vote, déclaration, achat), mais il n'y a pas de détection de bots, d'injecteurs de scripts, ni de limites de rate sur les remotes.

**Pas de session-lock avancé**
Un joueur peut rejoindre et quitter librement pendant une partie. Il n'y a pas de système empêchant de rejoindre en cours de partie (late-join = attente du prochain match uniquement).

---

## 6. Analytics & Monitoring

**Analytics console uniquement**
Les métriques sont loggées en console serveur (print/warn). Il n'y a pas de dashboard externe, ni d'export vers un service tiers.

**Pas d'alertes automatiques**
Aucun système ne notifie l'équipe en cas d'erreur serveur ou de pic d'abandon en cours de partie.

---

## 7. Divers

**DataStore sans retry robuste**
En cas d'échec DataStore (réseau instable), le profil est chargé en mémoire uniquement avec les valeurs par défaut. Il n'y a pas de retry exponentiel ni de queue d'écriture différée.

**Pas de leaderboard**
Il n'y a pas de classement global ni par serveur.

**Pas d'éditeur de scénario**
Les affaires sont définies en dur dans `CaseService.luau`. Il n'y a pas d'outil in-game pour créer ou modifier des affaires.
