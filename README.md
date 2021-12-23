# genote.sh

Script pour visualiser les notes d'évaluations de l'Université de Sherbrooke disponibles sur [Genote](https://www.usherbrooke.ca/genote) depuis le terminal.

Pour l'instant, on ne peut qu'afficher un cours à la fois avec un menu interractif, tout les cours de la dernière session ayant reçu des notes (session courante si il y a lieu) ou toutes les notes de toutes les sessions. Si un cours n'a pas de notes disponibles pour le moment, il n'apparait pas dans le choix.

UPDATE: Le script `gecote.sh` a été ajouté pour pouvoir obtenir les cotes (A+, A, A-, B+, etc...) depuis le terminal. Ses dépendances sont un sous ensemble de celles de `genote.sh`. Pour l'instant, il n'y a pas moyen de voir les notes dans plus d'un programme (si par exemple vous êtes inscrits à plusieurs programmes). Je ne l'ajouterai pas, mais son implémentation devrait être relativement simple pour quelqu'un qui désirerait le faire. 

NB: La sortie de ce script n'a pas de valeur officielle! En cas de disparité entre la sortie de ce script et la valeur contenue sur les instances officielles de l'Université, ces dernières ont préséance (naturellement...).

## Dépendances
Le script, encore une fois relativement simple, ne fais pas de vérifications à savoir si vous avez toutes les dépendances installées sur votre poste. C'est à vous de la faire manuellement.
```
cURL
gawk
sed
coreutils
fzf
pass
```

## Préparatifs
Le script utilise présentement `pass` pour lire les username/password, respectivement avec les commandes `pass add udes/username` `pass add udes/password`. Il y a plusieurs tutoriels en ligne qui montrent comment initialiser l'utilitaire `pass`, donc je ne le ferai pas ici.

NB: Il y a moyen de ne pas utiliser `pass` en hardcodant les valeurs en modifiant les lignes 
```bash
USERNAME=$(pass show udes/username)
PASSWORD=$(pass show udes/password)
```
par
```bash
USERNAME="cip@usherbrooke.ca"
PASSWORD="monmotdepasseimpossibleatrouver"
```

## Usage (genote.sh)
Pour voir un menu interractif pour sélectionner un seul cours:
```
./genote.sh
```

Pour voir les notes de tous les cours de la session courante/dernière session avec notes sans menu interractif:
```
./genote.sh last
```

Pour voir les notes de tous les cours de toutes les sessions avec notes sans menu interractif:
```
./genote.sh all
```

## Usage (gecote.sh)
Pour voir les cotes de la dernière session ayant des inscriptions:
```bash
./gecote.sh
```

Pour voir toutes les notes depuis le début de votre parcours dans ce programme:
```bash
./gecote.sh all
```

Pour voir les cotes d'il y a *n* sessions (ou n est un nombre entier entre 0 pour la session courante et le nombre de sessions que vous avez effectué):
```bash
./gecote.sh n
```

Si la note est confirmée par la direction, cela sera indiqué dans l'affichage.

## Contributions
Si vous avez des améliorations à proposer, envoyez une *pull request* et il me fera plaisir de l'intégrer au dépôt.

## Remerciements
Le code de l'authentification au CAS de l'Université de Sherbrooke est tiré (et modifié légèrement) de [cas-get.sh](https://gist.github.com/gkazior/4cf7e4c38fbcbc310267) de [Grzegorz Kazior](https://gist.github.com/gkazior).
