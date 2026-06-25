# Économie du Jeu — The Witness Box
**Version 1.0 — MVP Simplifié**
**Principe : l'argent achète ce que tu es, pas ce que tu peux faire.**

---

## 1. Règle Fondamentale

Aucune mécanique achetable ne confère d'avantage en partie. Cette règle est absolue et ne souffre aucune exception. Toute fonctionnalité future envisagée doit être vérifiée contre cette règle avant d'être ajoutée à la roadmap.

---

## 2. Monnaies

### 2.1 Jetons de Prétoire (monnaie gratuite)
- Gagnés uniquement en jouant
- Non achetables directement contre des Robux
- Utilisés pour débloquer les cosmétiques du catalogue gratuit
- Pas de date d'expiration

**Gains :**

| Action | Jetons |
|---|---|
| Finir une partie (tout format) | +10 |
| Verdict correct en tant que juré | +15 |
| Être acquitté en tant que menteur | +20 |
| Vote de respect reçu | +5 par vote |
| Dossier Froid complété | +8 |
| Première partie du jour (daily login) | +25 |
| Série de 3 parties en Cascade | +30 |

**Solde de départ :** 50 Jetons (cadeau de bienvenue)

### 2.2 Robux (monnaie Roblox native)
- Utilisés pour les Game Passes, produits consommables, et cosmétiques premium
- Strictement séparés des Jetons — pas de conversion entre les deux
- Gérés par le système Roblox standard

---

## 3. Game Passes (achats permanents)

### Pass Procureur Général — 299 Robux *(MVP)*
**Contenu :**
- Tenue exclusive "Grand Procureur" + animation d'entrée en salle
- Animation de verdict avec effets visuels
- Cadre de Dossier doré
- Multiplicateur de Jetons ×1.5 (accélère uniquement les cosmétiques gratuits)
- Badge permanent "Procureur Général" sur le profil

**Ce qu'il ne donne pas :** aucun avantage mécanique, aucune information supplémentaire, même temps de déclaration.

### Pass Dossiers Classifiés — 199 Robux *(MVP)*
**Contenu :**
- Bibliothèque étendue de Dossiers Froids (×3 le catalogue gratuit, soit ~45 dossiers)
- Dossiers "Affaires Historiques" à complexité supérieure
- 1 nouveau dossier premium par semaine

**Portée :** mode Solo uniquement. Aucun effet sur les parties multijoueur.

**Note de production :** nécessite la création d'1 dossier/semaine. Prioriser un buffer de 8 dossiers au lancement pour tenir 2 mois sans pression.

### Pass Salle de Presse — 149 Robux *(MVP)*
**Contenu :**
- Conférence de Presse post-partie enrichie (citations de joueurs, détails supplémentaires)
- Historique des 20 dernières Conférences dans le Dossier
- Partage en un tap vers Roblox social

**Stratégie :** cible les créateurs de contenu. Chaque partage est une publicité organique.

---

## 4. Developer Products (achats consommables)

### Boost Jetons ×2 — 25 Robux *(MVP)*
Double les Jetons gagnés pendant les 3 prochaines parties.
Aucun effet sur le gameplay — uniquement sur la vitesse d'accumulation de cosmétiques gratuits.

### Jeton de Prestige — 50 Robux *(MVP)*
Transforme les animations de réaction du joueur en version dorée pendant une partie.
Purement cosmétique, consommé en fin de partie.

### Réouverture de Dossier — 30 Robux *(MVP)*
Rejoue un Dossier Froid déjà complété avec une variante des déclarations.
Applicable uniquement en mode Solo.

---

## 5. Offre de Bienvenue

### Pack Nouveau Venu — 99 Robux *(MVP)*
**Disponible uniquement les 7 premiers jours après la première connexion.**

**Contenu :**
- Tenue "Avocat Junior" exclusive (non disponible ailleurs, jamais)
- 200 Jetons de Prétoire bonus
- Badge "Première Affaire" permanent
- Boost Jetons ×2 pour 5 parties

**Objectif :** convertir les joueurs "accrochés" (qui ont atteint le Rang 2) dans leur fenêtre d'intérêt maximale.
**Taux de conversion cible :** 5-8% des joueurs atteignant le Rang 2.

---

## 6. Cosmétiques

### 6.1 Catalogue Gratuit (Jetons de Prétoire)

| Cosmétique | Coût | Disponibilité |
|---|---|---|
| Tenue Clerc Standard (3 coloris) | 150 J | Permanent |
| Tenue Témoin Décontracté | 200 J | Permanent |
| Réaction "Doute" animée | 100 J | Permanent |
| Cadre de Dossier Bois | 80 J | Permanent |
| Animation Entrée "Pas Assuré" | 250 J | Permanent |
| Cadre Badge Bronze | 60 J | Permanent |
| Tenue Jurée Classique | 180 J | Permanent |
| Réaction "Approbation" | 120 J | Rotation mensuelle |

**Politique de rotation :** 2 items par mois entrent en rotation limitée (30 jours de disponibilité). Crée de la rareté temporelle sans paywall.

### 6.2 Catalogue Premium (Robux)

| Cosmétique | Prix | Phase |
|---|---|---|
| Tenue "Maître de Cour" | 180 R | MVP |
| Animation Entrée "Grand Juge" | 220 R | MVP |
| Réaction "Éclair Doré" | 120 R | MVP |
| Cadre Dossier Marbre | 150 R | MVP |
| Tenue "L'Ombre" | 200 R | MVP |
| Animation Verdict "Sentence" | 250 R | MVP |
| Pack Complet Lancement | 450 R | MVP |

### 6.3 Récompenses de Rang (gratuites, automatiques)

| Rang | Cosmétique débloqué |
|---|---|
| Clerc (2) | Tenue Clerc Alternative |
| Avocat Stagiaire (3) | Animation Entrée "Confiant" |
| Avocat (4) | Cadre Dossier Avocat |
| Avocat Confirmé (5) | Réaction "Objection" custom |
| Maître (6) | Tenue Maître (exclusive rang) |
| Grand Juge (7) | Animation Verdict "Justice" |
| Juge Suprême (8) | Badge permanent + cadre spécial |

---

## 7. Récompenses Daily Login

| Jour du cycle | Récompense |
|---|---|
| Jour 1 | +25 Jetons |
| Jour 2 | +30 Jetons |
| Jour 3 | Réaction "Approbation" (cosmétique) |
| Jour 4 | +40 Jetons |
| Jour 5 | +50 Jetons |
| Jour 6 | Cadre Dossier Argent |
| Jour 7 | Badge "Fidèle" + 100 Jetons |

Cycle de 7 jours, réinitialisé chaque semaine. **Pas de streak punitif** — manquer un jour ne réinitialise pas le cycle.

---

## 8. Projections de Revenus

### Taux de Conversion Cibles

| Produit | Conversion attendue |
|---|---|
| Pack Nouveau Venu | 5-8% des joueurs Rang 2+ |
| Pass Procureur Général | 2-3% des joueurs actifs mensuels |
| Pass Dossiers Classifiés | 1.5-2.5% des joueurs actifs mensuels |
| Pass Salle de Presse | 1-2% des joueurs actifs mensuels |
| Boost Jetons (Dev Product) | 20-30% des acheteurs, récurrent |

### Scénarios de Revenus Nets (après 30% Roblox + 30% développeur)

| DAU Stable | Robux Net/mois | Équivalent € |
|---|---|---|
| 500 | ~1 000 R | ~3 € |
| 5 000 | ~15 000 R | ~43 € |
| 20 000 | ~65 000 R | ~185 € |
| 50 000 | ~150 000 R | ~430 € |

**Note honnête :** Le seuil de viabilité financière est autour de 30 000-50 000 DAU. En dessous, le projet reste un projet passion. La croissance passe par la stratégie de contenu (TikTok/Shorts), pas par l'économie interne.

---

## 9. KPIs Économiques à Surveiller

| KPI | Cible | Fréquence de contrôle |
|---|---|---|
| Taux de conversion global | 3-5% | Hebdomadaire |
| ARPPU (revenu moyen/joueur payant) | 350-600 R/mois | Mensuel |
| Taux de rachat Dev Products | >20% des acheteurs | Mensuel |
| Ratio Jetons gagnés / dépensés | >0.7 (les joueurs dépensent ce qu'ils gagnent) | Hebdomadaire |
| Revenue per DAU | >2 R/jour | Hebdomadaire |

---

## 10. Ce Qui N'Existe Pas au MVP

Les fonctionnalités économiques suivantes sont explicitement **hors-scope MVP** :

- Pass de Saison (Phase 2)
- Offres Flash 48h (Phase 2)
- Pass Avocat de la Défense (Phase 2)
- Slot Dossier Épinglé supplémentaire (Phase 2)
- Cosmétiques saisonniers (Phase 2)
- Retour de Saison (Phase 3)
