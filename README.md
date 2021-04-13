# genote.sh

Script pour visualiser les notes d'évaluations de l'Université de Sherbrooke disponibles sur [Genote](https://www.usherbrooke.ca/genote) depuis le terminal.

Pour l'instant, ce script est relativement simple puisqu'il ne permet que de visualiser les notes de la session courante. Si un cours n'a pas de notes disponibles pour le moment, il n'apparait pas dans le choix.

Le code n'est pas très propre pour le moment car il a été fait rapidement sans trop réfléchir. Votre contribution serait très appréciée afin de l'optimiser/le rendre moins dégueux. :P

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
PASSWORD="monmotdepasseinpossibleatrouver"
```

## Usage
Pour voir un menu interractif pour sélectionner un seul cours:
```
./genote.sh
```

Pour voir les notes de tous les cours sans menu interractif:
```
./genote.sh all
```

## Contributions
Si vous avez des améliorations à proposer, envoyez une *pull request* et il me fera plaisir de l'intégrer au dépôt.

## Remerciements
Le code de l'authentification au CAS de l'Université de Sherbrooke est tiré (et modifié légèrement) de [cas-get.sh](https://gist.github.com/gkazior/4cf7e4c38fbcbc310267) de [Grzegorz Kazior](https://gist.github.com/gkazior).
