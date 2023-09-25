; extensions [ rngs ] ; For Negative Binomial and Beta distributions https://github.com/NetLogo/NetLogo/wiki/Extensions#random-number-generators-1

globals [ ; Time everywear
  n_workplaces_communal_land
  commodities_pending_demand
  exchange_value
]

;; WORKERS
turtles-own [ age resources status ]

;; CAPITAL
patches-own [
  capital
  working_hours work_intensity work_productivity; nigth turns?
  variable_capital constant_capital
  commodities
  production_cost
  n_workers n_workplaces max_n_workplaces
  surplus exploitation_rate profit_rate; derived var
  wage_hour
  ; TODO: means_of_production
]

to defaults
  ;; WORKERS
  set life_cost 1
  set max_age 65
  set min_working_age 6
  set min_reproductive_age 18
  set max_reproductive_age 65

  set workers_t0 5

  ;; CAPITAL
  set wage 1.8

  ;; MARKET
  set commodities_demand 2000000
end


to setup
  clear-all

  set exchange_value 1
  set n_workplaces_communal_land 20

  ask patches with [ pycor = 0 ] [ ; wage labour
    set capital 1 + random 500
    set commodities 0.01
    set working_hours 12
    set work_productivity 1
    set wage_hour life_cost * wage / working_hours
    set variable_capital 1
    set constant_capital 1
    set surplus 0
    set exploitation_rate 0
    set profit_rate 0
    set pcolor scale-color brown capital 0 10 ^ 9 ; max pycor

    set n_workplaces count turtles-here
    set max_n_workplaces 2 ^ pycor
  ]

   ask patches with [ pycor > 0 ] [ ; communal land
    set capital 0
    set commodities -1
    set n_workplaces n_workplaces_communal_land
    set working_hours 8
    set work_productivity 1
    set wage_hour life_cost * 2 / working_hours
    set exploitation_rate 0
    set pcolor scale-color brown capital 0 10 ^ 9 ; max pycor

    set n_workplaces n_workplaces_communal_land
  ]

  create-turtles workers_t0 * count patches [
    set age random 50
    set resources ( random 5 ) + 1
    set status "employed"
    set color red
    set shape "face neutral"

    move-to one-of patches ; every patch is independent (stochastic component of the patch production) and the populations are isolated

    if commodities = -1 [
      set status "autonomous"
      set color green
      set shape "face happy"
    ]

    if age < min_working_age [
      set status "child"
      ;set color yellow
      hide-turtle
      set resources resources + min_working_age - age
    ]

  ]


;  updateGlobalState
;  updatePlots

  reset-ticks
end


to go
  ask patches with [ capital > 0 or commodities > 0] [
    set n_workers 0
    set commodities 0
    set production_cost 0
    set wage_hour life_cost * wage / working_hours ; TODO f(x) punt crític entre 1.7 i 1.8 en que les empreses deixen de ser viables
    set n_workplaces min list (floor capital * wage_hour * working_hours) max_n_workplaces
    if n_workplaces < 0 [
     set n_workplaces 0
    ]
    set pcolor scale-color brown ln (capital + 1) 0 max [ ln (capital + 1) ] of patches ; max pycor

    ; Parameterize environmental mortality with mean and sd
    ;let alpha
    ;let beta
;    set mortalityEnv ifelse-value (stochasticEnv) [ rngs:rnd-beta streamEnv alpha beta ] [ 0 ]
  ]

  ask patches with [ commodities = -1] [
    set n_workers 0
    set wage_hour life_cost * wage / working_hours
  ]

  ask turtles with [age >= min_working_age and (status = "employed" or status = "autonomous") ] [ work ]
  ask turtles with [age >= min_working_age and status = "unemployed"] [ work ]

  ask patches with [ capital > 0 ] [ produce_commodities ]

  set commodities_pending_demand commodities_demand
  let total_commodities max list sum [ commodities ] of patches with [ commodities > 0 ] 1
  ;set exchange_value commodities_demand / sum [ commodities ] of patches ; TODO
  set exchange_value 2 * sum [ commodities * production_cost / total_commodities ] of patches with [ commodities > 0 ]; 2 * mean social_production_cost wighted by the production of commodities

  foreach sort-on [ production_cost ] patches with [ commodities > 0 ] [
    the-patch -> ask the-patch [ realize_capital ]
  ]
  ask patches with [ capital > 0 and pycor < 9] [ develop_means_of_production ]

  ask turtles [ live ]
  ask turtles with [
    age > min_reproductive_age and age < max_reproductive_age and
    resources > min_working_age - 2 + random 4
  ] [
    reproduce
  ]


  if not any? turtles [ stop ]

;  updateGlobalState

  if count turtles > 100000 [stop] ;(sum [ max_n_workplaces ] of patches) * 10 [ stop ] ;; STOP if population is too big

  tick
end


;; WORKERS
;;;;;;;;;;;

to live
  set age age + 1
  set resources resources - life_cost

  if age = min_working_age [
    set status "unemployed"
    ; already hide-turtle
    ;set color blue
    ;set shape "face sad"
  ]

  ;; Intrinsic mortality & starvation
  if age > max_age or resources <= 0 [ die ]


  ; set work_risk 1 - (1 - mortalityEnv) * (1 - fixMortality) ;; TODO

  ;; TODO: resources state-dependent mortality -> health dependent of resources via health care, housing conditions, food quality...
  ; set mortalityI 1 - (1 - mortalityI) * resources / maxStorage

  ; if random-float 1 < mortalityI [ die ]
end


to work
  ifelse n_workers < n_workplaces and random-float 1 > 0.1 [ ; probabilitat de perdre la feina
    set resources resources + wage_hour * working_hours
    show-turtle
    set n_workers n_workers + 1
    ifelse capital > 0 [
      set status "employed"
      set color red
      set shape "face sad"
    ][
      set status "autonomous"
      set color green
      set shape "face happy"
    ]
  ][
    set status "unemployed"
    hide-turtle
    ;set color blue
    ;set shape "face sad"

    let workplaces patches with [ n_workplaces > n_workers ]
    if any? workplaces [
      move-to one-of workplaces
    ]
  ]
  ;; resources evenly shared between individuals in the patch.
  ;; TODO: non linear functions
  ;; TODO: Alternative allocations based on age, stored resources...
;  let salary (t_open * production_open + t_cover * production_cover) / Np  ; aquisition = f(trait_forage, N, Δproduction_i)

end


to reproduce ;; TODO
  hatch 1 [
    set age 0
    set resources min_working_age + random 3
    set status "child"
    set color yellow
    hide-turtle
  ]

  set resources resources - min_working_age
end


;; CAPITAL
;;;;;;;;;;;

to produce_commodities
  ; TODO: adjustments by demand
  set variable_capital n_workers * wage_hour * working_hours
  set commodities n_workers * work_productivity * working_hours
  set constant_capital commodities * 0.02; TODO: f(commodities, cost_means_of_production, cost_raw_materials)
  if commodities > 0 [
    set production_cost (variable_capital + constant_capital) / commodities
  ]
  set capital max list 0 (capital - variable_capital - constant_capital )
end


to realize_capital
  ;; TODO: market and competence
  let sold_commodities min list commodities commodities_pending_demand
  let money sold_commodities * exchange_value
  set capital capital + money
  set commodities_pending_demand commodities_pending_demand - sold_commodities

  set surplus money - variable_capital ; TODO: Marx 1867. Capital Book 1 Part V Ch. 18 formulae I.
  set profit_rate surplus / (variable_capital + constant_capital)
  ifelse variable_capital = 0 [
    set exploitation_rate 0
  ] [
    set exploitation_rate surplus / variable_capital
  ]
end


to develop_means_of_production
  ;let new_tech_cost 1000 * (pycor + 1)
  let new_tech_cost 7 ^ (pycor + 1)
  ;let new_tech_cost 8 ^ (pycor + 1)
  ;let new_tech_cost 10 ^ (pycor + 1)
  if capital > new_tech_cost * 2 and [capital] of patch pxcor (pycor + 1) = 0 [
    set capital capital - new_tech_cost * 1
    ask patch pxcor (pycor + 1) [ ; expand capital to a new production system (eg. new tech)
      set capital new_tech_cost * 2
      set work_productivity 2 ^ pycor
      set max_n_workplaces 2 ^ pycor
      set n_workplaces min list (floor capital * wage_hour * working_hours) max_n_workplaces
      set working_hours 12
      set pcolor scale-color brown ln (capital + 1) 0 max [ ln (capital + 1) ] of patches
    ]
  ]

  if production_cost > exchange_value [ ; non profitable
    let x pxcor
    let non_profitable_capital capital
    set capital 0
    set n_workplaces -1
    set n_workers 0
    set max_n_workplaces 0
    set commodities -1
    set pcolor red
    ask patches with [ pxcor = x and capital > 0 ] with-max [ pycor ] [
      set capital capital + non_profitable_capital
    ]
  ]
end


;; COMMUNAL means of production
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@#$#@#$#@
GRAPHICS-WINDOW
210
10
472
273
-1
-1
25.4
1
10
1
1
1
0
0
0
1
0
9
0
9
1
1
1
ticks
30.0

BUTTON
4
10
85
43
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
5
80
68
113
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
486
165
686
315
Age distribution
age
freq
0.0
10.0
0.0
10.0
true
false
"" "clear-plot\nset-plot-x-range min [age] of turtles max [age] of turtles + 1"
PENS
"default" 1.0 1 -16777216 true "" "histogram [age] of turtles"

PLOT
492
10
829
160
population
t
n
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"unemployed" 1.0 0 -13345367 true "" "plot count turtles with [ status = \"unemployed\" ]  "
"childs" 1.0 0 -1184463 true "" "plot count turtles with [ status = \"child\" ]  "
"employed" 1.0 0 -2674135 true "" "plot count turtles with [ status = \"employed\" ]"
"autonomous" 1.0 0 -10899396 true "" "plot count turtles with [ status = \"autonomous\" ]"

PLOT
690
164
890
314
worker's resource distribution
resources
freq
0.0
10.0
0.0
10.0
true
false
"" "clear-plot\nset-plot-x-range round min [resources] of turtles round max [resources] of turtles + 1"
PENS
"default" 1.0 1 -16777216 true "" "histogram [resources] of turtles"

PLOT
210
321
410
471
Capital distribution
ln capital
freq
0.0
0.1
0.0
2.0
true
false
"" "clear-plot\nset-plot-x-range round min [ln capital] of patches with [ capital > 0 ] round max [ ln capital ] of patches  with [ capital > 0 ] + 1\n;set-plot-y-range 0 10\nset-histogram-num-bars count patches / 10"
PENS
"default" 1.0 1 -16777216 true "" "histogram [ ln capital ] of patches with [ capital > 0 ]"

PLOT
6
321
206
471
Total capital
t
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot sum [ capital ] of patches"

PLOT
896
163
1096
313
Average worker state
age
resources
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"employed" 1.0 0 -2674135 true "" "let ages [age] of turtles with [ status = \"employed\"] \nlet res [resources] of turtles with [ status = \"employed\"]\nset ages lput 1 ages\nset res lput 1 res\nplotxy mean ages mean res"
"unemployed" 1.0 0 -13345367 true "" "let ages [age] of turtles with [ status = \"unemployed\"] \nlet res [resources] of turtles with [ status = \"unemployed\"]\nset ages lput 1 ages\nset res lput 1 res\nplotxy mean ages mean res"
"child" 1.0 0 -1184463 true "" "let ages [age] of turtles with [ status = \"child\"] \nlet res [resources] of turtles with [ status = \"child\"]\nset ages lput 1 ages\nset res lput 1 res\nplotxy mean ages mean res"
"autonomous" 1.0 0 -10899396 true "" "let ages [age] of turtles with [ status = \"autonomous\"] \nlet res [resources] of turtles with [ status = \"autonomous\"]\nset ages lput 1 ages\nset res lput 1 res\nplotxy mean ages mean res"

PLOT
837
481
1037
631
Average profit rate
t
profit rate
0.0
0.1
0.0
0.1
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ";plotxy [ capital ] of patches [ variable_capital ] of patches\nplot mean [ profit_rate ] of patches with [ commodities > 0 ]\n"

PLOT
423
323
623
473
Dist. n workers per factory
ln n_workers
freq
0.0
1.0
0.0
2.0
true
false
"" "clear-plot\n;set-plot-x-range 0 ceiling max [ln (n_workers + 1)] of patches + 1\nset-plot-x-range round min [ln (n_workers + 1)] of patches with [commodities > 0] ceiling max [ln (n_workers + 1)] of patches  with [commodities > 0] + 1\nset-histogram-num-bars 10; count patches with [ capital > 0 ]"
PENS
"default" 1.0 1 -16777216 true "set-histogram-num-bars 10" "histogram [ln (n_workers + 1)] of patches with [ capital > 0 ]"

BUTTON
4
45
85
78
NIL
defaults
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
98
11
206
44
life_cost
life_cost
0.1
10
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
97
45
207
78
max_age
max_age
20
90
65.0
1
1
NIL
HORIZONTAL

SLIDER
5
115
206
148
min_working_age
min_working_age
6
18
10.0
1
1
NIL
HORIZONTAL

SLIDER
4
150
205
183
min_reproductive_age
min_reproductive_age
15
30
18.0
1
1
NIL
HORIZONTAL

SLIDER
5
186
203
219
max_reproductive_age
max_reproductive_age
35
65
65.0
1
1
NIL
HORIZONTAL

SLIDER
96
82
206
115
workers_t0
workers_t0
1
50
5.0
1
1
NIL
HORIZONTAL

SLIDER
5
267
177
300
wage
wage
0.5
2
1.8
.1
1
NIL
HORIZONTAL

PLOT
835
327
1035
477
Exploitation rate distribution
exploitation_rate
freq
0.0
10.0
0.0
2.0
true
false
"" "clear-plot\nset-plot-x-range round min [ exploitation_rate ] of patches with [ capital > 0 ] round max [ exploitation_rate ] of patches with [ capital > 0 ]+ 1\n;set-plot-y-range 0 10\nset-histogram-num-bars count patches / 10"
PENS
"exploitation_rate" 1.0 1 -16777216 true "" "histogram [ exploitation_rate ] of patches with [ commodities > 0 ]"

PLOT
421
481
621
631
ln exchange_value
t
ln exchange_value
0.0
10.0
0.0
0.1
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot ln (exchange_value); + 0.01)"

PLOT
212
480
412
630
Production cost distribution
production_cost
freq
0.0
0.1
0.0
2.0
true
false
"" "clear-plot\nset-plot-x-range precision (min [production_cost] of patches with [ commodities > 0 ]) 4 precision (max [production_cost] of patches with [ commodities > 0] + 0.0001) 4\nset-histogram-num-bars 10"
PENS
"default" 1.0 1 -16777216 true "" "histogram [ production_cost ] of patches with [ commodities > 0 ]"

SLIDER
5
224
202
257
commodities_demand
commodities_demand
1000
5000000
2000000.0
1000
1
NIL
HORIZONTAL

PLOT
4
477
204
627
Total production
t
commodities
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot sum [ commodities ] of patches with [ capital > 0]"

PLOT
629
480
829
630
Avg. Variable / Constant capital
t
var / const
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [ variable_capital / constant_capital ] of patches with [ commodities > 0]"

PLOT
628
324
828
474
Surplus distribution
surplus
freq
0.0
10.0
0.0
2.0
true
false
"" "clear-plot\n;set-plot-x-range 0 round max [ surplus ] of patches with [ commodities > 0 ] + 1\nset-plot-x-range round min [ surplus ] of patches with [ commodities > 0 ] round max [ surplus ] of patches with [ commodities > 0 ] + 1\n;set-plot-y-range 0 10\nset-histogram-num-bars count patches / 10"
PENS
"default" 1.0 1 -16777216 true "" "histogram [surplus] of patches with [commodities > 0]"

PLOT
1043
481
1234
633
Profit rate distribution
profit rate
freq
0.0
10.0
0.0
2.0
true
false
"" "clear-plot\nset-plot-x-range round min [ profit_rate ] of patches with [ commodities > 0 ] round max [ profit_rate ] of patches with [ commodities > 0 ] + 1\n;set-plot-y-range 0 10\nset-histogram-num-bars count patches / 10"
PENS
"default" 1.0 1 -16777216 true "" "histogram [ profit_rate ] of patches with [ commodities > 1 ]"

@#$#@#$#@
## WHAT IS IT?

Model representing the processes described in "Capital. A Critique of Political Economy" (Karl Marx 1867, 1885, 1894).

## HOW IT WORKS

Each cell represents means of production  and the workers are represented by individuals that can move among cells. In
the beginning, the cells are communal lands in which individuals subsist with the value generated by their own labor
without intermediaries. In the bottom row, the means of production are controlled by capital and there is wage labor
that produces commodities. As capital is reproduced and accumulated, it can expand into the cell immediately above. The
number of wage workers who can work there and the productivity of labor hours increase exponentially as capital expands
into the upper ranks, representing the technological development of the means of production.

### Workers

In each cycle, workers spend the resources needed to live ("life_cost"). Workers can be in different states. If they
work on communal land they are autonomous and earn twice the resources needed to survive, which allows them to
reproduce. If they are employed, they receive a salary/resources equivalent to "wage * life_cost". Each cell has a
maximum number of workers that depends on the level of development of the means of production and the capital available
to purchase the labor force. Workers who can't find work are unemployed and survive on whatever savings they may have.
If they are younger than the minimum working age ("min_working_age"), they are children who do not work and subsist on
the resources passed down to them by the family at birth. Workers who run out of resources at the end of a cycle die.

### Capital

In each cycle, capital produces a quantity of goods determined by the number of workers it can hire depending on the
available capital, and the productivity of the production system. The price of commodities is twice the socially
necessary value (the average cost of production weighted by the quantity of commodities produced for each unit of
production) to produce one unit.

In the event that the production of goods exceeds the demand, only the capital of the goods of the cells with the lowest production cost is realized until all the demand is covered (https://en.wikipedia.org/wiki/Matthew_effect).

The color of the cells indicates the accumulated capital. The lighter the color, the more accumulated money, and black
color indicates 0 money.

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)
TODO

## THINGS TO NOTICE

Capital increases and develops. When new production systems increase productivity, the exchange value of commodities
falls. The less efficient modes of production cannot produce at a cost below exchange value and are abandoned (red
cells). When total production exceeds demand, less productive cells are decapitalized and have no capital to hire
workers, causing production to stop. The simulation usually stabilizes in a monopoly of one or several companies at the
maximum level of productivity, depending on the demanded amount for commodities.

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

https://en.wikipedia.org/wiki/Internal_contradictions_of_capital_accumulation
https://en.wikipedia.org/wiki/Hyperinflation
https://en.wikipedia.org/wiki/Capital_accumulation

## EXTENDING THE MODEL

Add different types of commodities, commodities' production chains, trade unions, taxes, finite natural resources that
condition the market value of constant capital, demand for commodities based on total population, financial system,
international trade, imperialism...

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

Desenvolupat a https://github.com/jmaspons/Das-Kapital
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
