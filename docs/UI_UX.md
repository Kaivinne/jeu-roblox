# UI/UX Design — The Witness Box
**Version 1.0 — MVP**
**Priorité : Mobile-first, puis adaptation PC**

---

## 1. Principes UX

1. **Zéro immobilité involontaire** : le joueur a toujours quelque chose à faire ou à regarder
2. **Une seule action primaire par écran** : vote, déclaration, ou réaction — jamais tout à la fois
3. **Tap targets minimum 44×44pt** sur mobile (standard Apple/Google)
4. **Toute information critique existe en visuel ET en texte** — jamais exclusivement dans l'un des deux
5. **Le clavier mobile n'apparaît que lors des champs de déclaration** — pas avant, pas pendant le vote

---

## 2. Flux de Navigation

```
[Écran Roblox]
      ↓
[Menu Principal]
      ├─ Jouer → [Matchmaking / File Active]
      ├─ Dossiers → [Mode Solo — Dossiers Froids]
      ├─ Mon Dossier → [Profil Joueur]
      └─ Boutique → [Catalogue Cosmétiques]
            ↓ (matchmaking trouvé)
      [Salle d'Audience]
            ├─ Phase Intro
            ├─ Phase Déclarations  ← boucle N fois
            ├─ Phase Délibération
            ├─ Sprint Final
            ├─ Verdict
            └─ Post-Verdict
                  ↓
      [Retour Menu OU Cascade (partie suivante)]
```

---

## 3. Écrans — Description Détaillée

---

### 3.1 Menu Principal

**Layout :**
- Fond : salle d'audience légèrement floue (profondeur de champ)
- Centre : Logo "THE WITNESS BOX" en or
- 4 boutons empilés verticalement (taille 200×60px mobile)
- En bas : rang actuel + barre XP (toujours visible)

**Règle :** Le bouton "Jouer" est toujours le premier, le plus grand, le plus contrasté. Pas d'ambiguïté sur l'action principale.

---

### 3.2 File d'Attente Active

Pendant la recherche de match, le joueur n'attend pas — il joue un Dossier Froid automatiquement chargé. La notification de match trouvé s'affiche en overlay sans interrompre brutalement.

**Overlay "Match Trouvé" :**
- Position : centre-haut de l'écran
- Contenu : "Procès en cours — 3 joueurs" + bouton "Rejoindre" (5 secondes pour accepter)
- Si refus ou timeout : retour à la file, Dossier Froid continue

---

### 3.3 Interface de Partie — HUD Principal

```
┌─────────────────────────────────────────┐
│ [Timer Phase]          [Tableau Contradiction] │
│                                          │
│         [Portrait du Témoin en cours]    │
│              [Déclaration en cours]      │
│                                          │
│ [Réactions Jurés]                        │
│                                          │
│         [Zone Action Joueur Actif]       │
└─────────────────────────────────────────┘
```

**Zone Action Joueur Actif** (varie selon le rôle et la phase) :
- Témoin en phase déclaration → DeclarationBuilder
- Juré en phase déclaration → 4 boutons de réaction
- Juré en délibération → Bouton Vote + Bouton Objection
- Avocat → Sélecteur de question

**Ce qui reste constant en toutes phases :**
- Timer (coin supérieur gauche)
- Tableau des Contradictions (barre supérieure)
- Indicateur de rang + Jetons (coin inférieur droit, mini)

---

### 3.4 Portrait Vivant du Témoin

**Position :** Moitié gauche de l'écran, hauteur pleine sur mobile portrait / 60% hauteur sur paysage
**Taille minimale :** 150×150px sur les plus petits écrans supportés
**Contenu :**
- Avatar Roblox du témoin (gros plan, cadrage épaules-tête)
- Fond neutre gradienté (salle d'audience flou)
- Nom du témoin + rôle apparent (Témoin 1, Témoin 2, etc.) — jamais le vrai rôle

**États visuels :**
- Calme : animation idle légère
- Hésitant : déclenché à 15s du timer
- Nerveux : déclenché à 20s du timer

---

### 3.5 DeclarationBuilder (Interface de Saisie)

Affiché uniquement quand c'est le tour du joueur de déclarer.

**Layout Mobile (portrait) :**
```
┌────────────────────────────────┐
│ "J'étais [          ] avec    │
│ [          ] à [     ] quand  │
│ [                    ]."      │
│                                │
│  ████████████████████████████  │
│  [         Valider            ]│
└────────────────────────────────┘
```

**Comportement :**
- Tap sur un champ → clavier mobile s'ouvre
- Validation automatique si timer expire (état actuel envoyé)
- Champ actif mis en surbrillance gold
- Compteur de caractères restants sous chaque champ
- Bouton "Valider" devient actif uniquement si au moins 2 champs sont remplis

**Timer :**
- Cercle de progression qui entoure le bouton Valider
- Change de couleur : vert → orange (10s) → rouge (5s)
- Pulsation à <5s

---

### 3.6 Tableau des Contradictions

**Position :** Barre horizontale en haut de l'écran, hauteur fixe 48px
**Contenu :** Pictogrammes des informations clés de chaque déclaration, organisés par témoin
**Contradiction détectée :** Ligne rouge animée entre les deux pictogrammes contradictoires + vibration haptique (mobile)

**Tap sur un pictogramme :** Ouvre une popup avec le texte exact de la déclaration correspondante. Se ferme en tap outside.

---

### 3.7 Boutons de Réaction (Phase Déclaration — Jurés)

**Position :** Rangée horizontale en bas de l'écran
**Taille :** 4 boutons de 80×80px chacun, espacement 12px
**Fenêtre d'activation :** 8 secondes après la fin d'une déclaration

```
[👁 Suspicion] [✓ Crédibilité] [? Confusion] [⚡ Contradiction]
```

**Règle :** Le texte label est toujours présent sous l'icône. Pas d'icône seule.
**Feedback :** Vibration haptique + animation de pulse sur le bouton pressé.
**Limite :** 1 réaction par déclaration par joueur. Après envoi, les boutons grisent.

---

### 3.8 Bouton d'Objection

**Position :** Coin inférieur gauche, toujours visible pour les jurés mais grisé hors phase délibération
**Taille :** 100×100px (grand — action irréversible)
**Couleur active :** Rouge profond avec bordure or pulsante
**Badge :** Indicateur "1 disponible" / "Utilisé" permanent

**Flux d'activation :**
1. Tap sur Objection → Popup de confirmation (2s pour annuler)
2. Sélection de l'objection dans une liste de 3 options
3. Envoi au serveur → Interruption de la déclaration en cours
4. Affichage de la réponse du témoin

---

### 3.9 Phase de Délibération et Sprint Final

**Délibération (45s) :**
- Sablier central animé visible de tous
- Vote progressif : curseur de crédibilité par témoin (glisser)
- Ces votes intermédiaires restent privés

**Sprint Final (60s) :**
- Éclairage général baisse
- Timer central en grand
- Deux boutons plein écran : ■ COUPABLE (rouge) et ■ INNOCENT (vert bouteille)
- Taille minimum des boutons : 160×80px (mobile)

---

### 3.10 Écran de Verdict

**Séquence :**
1. Fondu au noir 0.5s
2. Texte COUPABLE ou INNOCENT en très grand (animation slide-in)
3. Sous-texte : "X était le menteur" avec nom du joueur
4. Après 3s : liste des déclarations vraies vs fausses
5. Après 5s : Conférence de Presse générée (partageable)
6. Après 10s : Distribution des récompenses (XP + Jetons animés)
7. Chat libre déverrouillé pour 60s

---

### 3.11 Profil Joueur (Mon Dossier)

**Layout :**
```
┌──────────────────────────────────┐
│ [Avatar]  [Nom + Rang]           │
│           [Barre XP]             │
│──────────────────────────────────│
│ Crédibilité [██████░░] 72        │
│ Perspicacité [████░░░░] 58       │
│──────────────────────────────────│
│ [Badge 1] [Badge 2] [Badge 3]    │
│──────────────────────────────────│
│ Parties épinglées (max 3)        │
│ ► L'Incident du Couloir — Gagné  │
│──────────────────────────────────│
│ Stats : 47 parties · 23 victoires│
└──────────────────────────────────┘
```

---

## 4. Règles Mobile Spécifiques

### Orientation
Le jeu fonctionne en **paysage forcé** (Landscape Locked). L'UI est conçue pour cette orientation. Ne pas tenter de supporter le portrait — l'interface de salle d'audience est incompatible.

### Zones de Sécurité
Respecter les zones de sécurité des appareils modernes (notch, barre de navigation). Aucun élément interactif dans les 20px des bords.

### Taille des Éléments Interactifs
| Élément | Taille minimum |
|---|---|
| Bouton principal | 200×60px |
| Bouton secondaire | 120×48px |
| Bouton de réaction | 80×80px |
| Bouton d'objection | 100×100px |
| Champ de texte | hauteur 48px minimum |
| Pictogramme tap | 44×44px |

### Performance UI
- Pas d'animations complexes simultanées sur mobile bas de gamme
- Les effets visuels lourds (éclair de contradiction) sont optionnels et désactivables dans les Settings
- Toutes les transitions UI < 300ms

---

## 5. Accessibilité

- Contraste couleur minimum WCAG AA sur tous les textes
- Jamais d'information transmise uniquement par la couleur (toujours doublée d'un label ou icône)
- Taille de texte configurable (S / M / L) dans les Settings — **Phase 2**
- Mode daltonisme (remplace rouge/vert par des icônes distinctes) — **Phase 2**

---

## 6. Écrans Hors-Scope MVP

Les écrans suivants sont identifiés mais non développés au MVP :

- Tableau de classement des Cabinets
- Interface de défi Inter-Cabinet
- Gestion des Rivalités
- Historique de saison
- Éditeur de profil avancé (nom de scène, spécialisation)
