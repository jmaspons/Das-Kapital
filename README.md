# Das Kapital

![sreenshot of the netlogo model](screenshot-netlogo_v0.png)

## QUÈ ÉS?

Model que representa els processos descrits a
«[El capital. Crítica de l'economia política](https://www.marxists.org/catala/marx/capital/me23_000.htm)»
(Karl Marx 1867, 1885, 1894).

## COM FUNCIONA

Cada cel·la representa mitjans de producció i els treballadors es representen amb individus que es poden moure entre
cel·les. Al principi, les cel·les són terres comunals en què els individus subsisteixen a partir del valor generat pel
seu propi treball sense intermediaris. A la fila inferior, els mitjans de producció estan controlats per capital i hi ha
treball assalariat que produeix mercaderies. A mesura que es reprodueix el capital i es va acumulant, aquest pot
expandir-se a la cel·la immediatament superior. El nombre de treballadors assalariats que poden treballar-hi i la
productivitat de les hores de treball augmenten exponencialment a mesura que el capital s'expandeix cap a les files
superiors, representant el desenvolupament tecnològic dels mitjans de producció.

### Treballadors

A cada cicle els treballadors gasten els recursos necessaris per viure («life_cost»). Els treballadors poden trobar-se
en diferents estat. Si treballen en terres comunals són autònoms i guanyen el doble de recursos dels necessaris per
sobreviure, fet que els permet reproduir-se. Si fan treball assalariat o són autònoms, reben un salari/recursos
equivalent a «wage * life_cost». Cada cel·la té un nombre màxim de treballadors que depèn del nivell de desenvolupament
dels mitjans de producció i del capital disponible per comprar la força de treball. Els treballadors que no
aconsegueixen feina es troben a l'atur i sobreviuen dels estalvis que puguin tenir. Si tenen menys anys que l'edat
mínima per treballar («min_working_age»), són nens que no treballen i subsisteixen a partir dels recursos que els han
traspassat la família en nàixer. Els treballadors que es queden sense recursos en acabar un cicle, moren.

### Capital

A cada cicle el capital produeix una quantitat de mercaderies determinades pel nombre de treballadors que pot contractar
depenent del capital disponible, la productivitat del sistema de producció. El preu de les mercaderies és dues vegades
el valor socialment necessari (la mitjana del cost de producció ponderat per la quantitat de mercaderies produïdes per
de cada unitat de producció) per produir una unitat.

En cas que la producció de mercaderies superi la demanda, només es realitza el capital de les mercaderies de les cel·les
amb el cost de producció més baix fins a cobrir tota la demanda (<https://ca.wikipedia.org/wiki/Efecte_Mateu>).

El color de les cel·les indica el capital acumulat, amb colors més clars com més capital hi ha i negre si és 0.

## COM USAR-LO

(how to use the model, including a description of each of the items in the Interface tab)

## COSES A FIXAR-SE

El capital augmenta i es desenvolupa. Quan els nous sistemes de producció augmenten la productivitat, baixa el valor de
canvi de les mercaderies. Els modes de producció menys eficients no poden produir a un cost per sota del valor de canvi
i s'abandonen (cel·les en vermell). En el moment que la producció total supera la demanda, les empreses menys
productives es descapitalitzen i no tenen capital per contractar treballadors fent que s'aturi la producció. La
simulació sol estabilitzar-se en un monopoli d'una o varies empresa al nivell de màxim de productivitat, en funció de la
demanda de mercaderies.

## COSES A PROVAR

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

https://en.wikipedia.org/wiki/Internal_contradictions_of_capital_accumulation  
https://en.wikipedia.org/wiki/Hyperinflation  
https://en.wikipedia.org/wiki/Capital_accumulation  

## ESTENENT EL MODEL

Afegir diferents tipus de mercaderies, cadenes de producció de mercaderies, sindicats, impostos, recursos naturals
finits que condicionen el valor de mercat del capital constant, demanda de mercaderies en funció de la població total,
sistema financer, comerç internacional, imperialisme...

# Requisits i execució del model
Per veure i córrer el model cal instal·lar [NetLogo](https://ccl.northwestern.edu/netlogo/download.shtml) i obrir el
[fitxer](exec/Das_Kapital.nlogo).

A dalt hi ha la pestanya `Info` amb una mica de descripció del model, i `Code` on hi ha el codi. Per córrer el model
només cal pitjar `setup` i `go`.
