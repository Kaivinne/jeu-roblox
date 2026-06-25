# Direction Artistique — The Witness Box
**Version 1.0 — MVP**

---

## 1. Vision Artistique

The Witness Box est un **drame judiciaire stylisé**, pas un simulateur réaliste. L'esthétique doit évoquer le cinéma de cour des années 50-60 — sombre, tendu, avec des moments de lumière dramatique — réinterprété dans un langage visuel Roblox moderne.

**Référence mentale :** 12 Angry Men × Ace Attorney × Clue (le jeu de société)

**Ce que l'art doit communiquer immédiatement :**
1. Tension et gravité — ce qui se passe ici a des conséquences
2. Lisibilité — chaque information est visible en un coup d'œil, même sur mobile
3. Caractère mémorable — une thumbnail reconnaissable en 2 secondes sur Roblox Discover

---

## 2. Palette de Couleurs

### Couleurs Primaires

| Rôle | Couleur | Hex | Usage |
|---|---|---|---|
| Fond salle d'audience | Bois sombre | `#2C1810` | Murs, plancher |
| Accentuation principale | Or judiciaire | `#C9A84C` | Marteau, boiseries, titres |
| Fond UI | Ardoise | `#1A2332` | Panneaux, menus |
| Texte principal | Ivoire | `#F5F0E8` | Toute la typographie principale |

### Couleurs Fonctionnelles

| Usage | Couleur | Hex |
|---|---|---|
| Coupable / Danger | Rouge profond | `#8B1A1A` |
| Innocent / Safe | Vert bouteille | `#1A5C2E` |
| Neutre / En attente | Bleu nuit | `#1A2B4A` |
| Contradiction détectée | Éclair orange | `#FF6B1A` |
| Réaction Suspicion | Amber | `#D4860A` |
| Réaction Crédibilité | Vert clair | `#4CAF7D` |
| Timer critique (<10s) | Rouge pulsant | `#FF3333` |

### Couleurs de Rang

| Rang | Couleur titre |
|---|---|
| Stagiaire — Clerc | Gris `#8A8A8A` |
| Avocat Stagiaire — Avocat | Bronze `#CD7F32` |
| Avocat Confirmé — Maître | Argent `#C0C0C0` |
| Grand Juge — Juge Suprême | Or `#FFD700` |

---

## 3. Typographie

### Police Principale
**Nom Roblox :** GothamSSm (ou équivalent disponible dans Roblox)
- Titres : Bold, majuscules, tracking élargi
- Corps de texte : Regular, taille minimum 14pt sur mobile
- Déclarations des témoins : Italic Regular (effet "témoignage")

### Hiérarchie Typographique

| Niveau | Style | Taille |
|---|---|---|
| Titre de phase ("DÉLIBÉRATION") | Bold + majuscule + or | 28-36pt |
| Nom du témoin en cours | SemiBold + ivoire | 20-24pt |
| Texte de déclaration | Regular italic + ivoire | 16-18pt |
| Labels UI (timer, score) | Bold + couleur fonctionnelle | 14-16pt |
| Texte secondaire | Regular + gris clair | 12-14pt |

**Règle absolue :** Aucun texte en dessous de 12pt. Aucun texte blanc pur sur fond blanc. Toujours tester la lisibilité sur un écran de 5 pouces.

---

## 4. Salle d'Audience

### Espace de Jeu
La salle d'audience est le seul environnement du jeu au MVP. Elle doit être reconnaissable et mémorable.

**Structure :**
```
[Tribune du Juge — fond, surélevée]
         |
[Barre des Témoins — milieu gauche]  [Table de l'Accusation — milieu droit]
         |                                        |
              [Banc du Jury — premier plan]
```

**Matériaux :**
- Bois sombre ciré pour toutes les surfaces structurelles
- Tissu bordeaux pour les sièges
- Marbre gris pour le sol
- Éclairage dramatique : spot central sur la barre des témoins, ambiance tamisée sur le jury

**Ce qui ne doit PAS être dans la salle :**
- Décorations superflues (plantes, tableaux)
- Fenêtres (pas de contexte extérieur — hors-temps)
- Couleurs vives non fonctionnelles

### Éclairage
- Spot de lumière froide sur le témoin qui parle (highlight du focus)
- Ambiance chaude générale (ampoules période)
- Pendant le Sprint Final : éclairage général baisse de 30%, spot rouge pulsant sur le timer

---

## 5. Avatars et Personnages

### Style des Avatars
Les avatars Roblox standard sont utilisés. Le style artistique est appliqué via les cosmétiques et les animations — pas via des avatars custom qui imposeraient des contraintes d'équipement.

### Tenues de Base (gratuites)
- **Témoin Standard** : chemise blanche + pantalon gris + cravate simple
- **Juré Standard** : veste sombre + badge juré sur la poitrine
- **Avocat Standard** : costume noir + porte-documents

### Tenues Premium (exemples)
- **Grand Procureur** : costume trois pièces noir avec revers or, animation de veste au vent
- **L'Ombre** : entièrement en noir mat, tenue asymétrique, aucun détail brillant

### Animations Clés

| Animation | Déclencheur | Description |
|---|---|---|
| Portrait Vivant — Calme | Par défaut | Léger balancement, respiration |
| Portrait Vivant — Hésitant | Temps de réponse > 15s | Regard qui dévie, main au col |
| Portrait Vivant — Nerveux | Temps de réponse > 20s | Transpiration animée, micro-tremblements |
| Entrée en Salle (standard) | Début de partie | Marche assurée vers le siège |
| Entrée en Salle (premium) | Pass acheté | Variantes dramatiques personnalisées |
| Verdict Animé (standard) | Fin de partie | Marteau tombant, simple |
| Verdict Animé (premium) | Pass acheté | Effets visuels supplémentaires |

**Règle :** Les 3 états du Portrait Vivant sont des variantes d'animation subtiles — pas des transformations visuelles choquantes. L'ambiguïté est intentionnelle.

---

## 6. Interface Visuelle (Art)

La direction artistique de l'UI est traitée en détail dans `UI_UX.md`. Les règles artistiques applicables à l'UI :

- Panneaux UI : fond ardoise `#1A2332` avec bordure or `#C9A84C` (1-2px)
- Boutons actifs : or `#C9A84C` avec texte sombre
- Boutons inactifs : gris `#3A3A3A` avec texte grisé
- Effets de survol (PC) : légère surbrillance gold
- Aucune ombre portée excessive — design plat avec accents gold

---

## 7. Effets Visuels

### Éclair de Contradiction
- Durée : 1.5 secondes
- Animation : éclair orange part du premier élément contradictoire et percute le second
- Son associé : court impact électrique
- Fréquence max : 1 toutes les 5 secondes (pas de spam)

### Flash du Sprint Final
- Progressif : la salle devient 30% plus sombre sur 5 secondes
- Spot rouge sur le timer central
- Pulsation du timer synchronisée avec un son de tension croissante

### Révélation du Verdict
- Fondu au noir 0.5s
- Titre du verdict en très grand (COUPABLE / INNOCENT) en couleur fonctionnelle
- Sous-titre avec les noms des menteurs
- Durée d'affichage : 4 secondes avant le déploiement de la Conférence de Presse

---

## 8. Son et Musique

### Ambiance
- Musique d'ambiance : jazz lent et discret pendant les déclarations
- Pas de musique pendant la délibération (silence intentionnel = tension)
- Montée progressive pendant le Sprint Final

### Effets Sonores Clés

| Événement | Son |
|---|---|
| Soumission d'une déclaration | Tampon de document |
| Réaction Contradiction | Impact court, grave |
| Bouton Objection activé | Coup de marteau dramatique |
| Timer < 10 secondes | Ticking d'horloge |
| Verdict Coupable | Accord mineur profond |
| Verdict Innocent | Accord majeur léger |
| Vote de Respect reçu | Carillon bref |

### Règle Mobile
Tous les sons ont un équivalent visuel. Le jeu est entièrement jouable en silencieux (60% des sessions mobiles Roblox).

---

## 9. Thumbnail et Découverte Roblox

### Composition de la Thumbnail
- Fond : salle d'audience dramatique, éclairage spot
- Premier plan : avatar avec tenue "Grand Procureur" + marteau
- Texte : "THE WITNESS BOX" en grand + sous-titre court ("Qui ment ?")
- Couleurs dominantes : noir profond + or
- Aucun visage souriant — expression neutre et tendue

### Objectif CTR
La thumbnail doit être identifiable à 60x60px (taille miniature Roblox Discover). Tester systématiquement à cette taille avant validation.

### Icône du Jeu
- Marteau de juge sur fond or
- Simple, iconique, lisible à toutes tailles
- Pas de personnage — l'objet suffit

---

## 10. Ce Qu'il Ne Faut Pas Faire

- ❌ Couleurs vives non justifiées (rouge vif, jaune criard)
- ❌ Effets de particules excessifs pendant les déclarations
- ❌ Polices stylisées illisibles
- ❌ UI surchargée d'informations simultanées
- ❌ Animations de personnages cartoonesques ou comiques (sauf cosmétiques premium optionnels)
- ❌ Musique forte pendant les phases de lecture
- ❌ Fond blanc ou très clair dans l'UI (fatigue visuelle mobile)
