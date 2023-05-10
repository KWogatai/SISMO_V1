;;hatch prob: 0.15, nutrient value: 10

__includes["math_functions.nls" "setup.nls" "network-creation.nls" "a-star.nls"]
;; 6 breeds needed in total, 3 for slime mold (plasmodia, pseudopodia, tubes), 1 for food source and 2 for A* algorithm ( networkpoints, searchers)
breed [ plasmodia plasmodium ]
breed [ pseudopodia pseudopodium ]
;; The tubes are used to indicate the shortest path between the center and the feed source
breed [ tubes tube ]
;; foods represent the foodsources
breed [ foods food ]
;; the networkpoints and searchers are used for the a*algorithm
breed [ networkpoints networkpoint ]
breed [ searchers searcher ]

globals [
  ;; to control the form of the visible chemical field
  scale-factor
  ;; sets the probability for pseudopodia to hatch a new pseudopodium
  hatch-probability
  ;; 08.09.2022
  plasmodium-position
  debug-counter
]

pseudopodia-own[
  ;; stores the path in a list of lists with x y coordinates
  path-list
]

foods-own [
  ;; each food source should have an amount of nutrients
  nutrient-value
  ;; the chemical level describes the radius of the food source in which the pseudopodia can perceive the food
  chemical-level
  ;; for the visibility of the chemical field
  intensity
]

tubes-own [
  ;; stores the path in a list of lists with x y coordinates
  path-list
]

searchers-own [
  memory               ; Stores the path from the start node to here
  cost                 ; Stores the real cost from the start
  total-expected-cost  ; Stores the total exepcted cost from Start to the Goal that is being computed
  localization         ; The searchers position
  active?              ; is the searcher active? That is, we have reached the node, but we must consider it because its neighbors have not been explored
]

patches-own
[
  light-level ;; represents the light energy from all light sources
]

;; setup, defines where to place which component of the simulation at the beginning and initialize the global variables
to setup
  print word "Start:" date-and-time
  print word "Initial Pseudopodia: " amount-pseudopodia
  print word "Hatch probability: " hatch-probability
  random-seed 4711
  ;; clear-all calls the clearing functions like clear-globals etc.
  clear-all
  ;; set global variables
  set hatch-probability 0.05
  set scale-factor 10
  ;; call make functions to create breeds
  make-plasmodia 0 0
  ;; create all foods with x y coordinates
  ;;Example Coordinates
  make-foods 5 6
  make-foods 1 2
  make-foods 4 3
  make-foods -1 2
  make-foods -9 0
  make-foods 3 -1
  make-foods 10 3
  make-foods -9 7
  make-foods 24 -8

   make-pseudopodia amount-pseudopodia 0 0
  ;; next line is responsible for the visibility of the chemical concentration in the air
  ask patches [ generate-field ]
  ;; Resets the tick counter to zero, sets up all plots, then updates all plots
  ;; 09.09.2022
  set plasmodium-position list 0 0
  reset-ticks
 ;; print date-and-time


end

to go
  ifelse any? foods with [ nutrient-value > 0 ]
  [
    ask foods[
      ;; There is a bug where food sources are created randomly and untraceable. This causes the pseudopodia to hang on this food source. Because it takes negative values and iterates forever. With this code this bug is fixed.
      if nutrient-value < 0 [ die ]
    ]
    ask pseudopodia
    [
      let foodsource one-of foods-here
      ifelse foodsource != nobody
      [
        let path-list-to-provide-to-tube path-list
        ask foodsource
        [
          if show-nutrient-value [set label nutrient-value]
          set nutrient-value nutrient-value - 1
          if nutrient-value = 0 [
            ;; create the network for the a star algorithm
            create-pseudopodia-network turtle-set turtles-on patch-ahead 0
            ;; get one pseudopodia on the foodsource to set the destination x,y coordinate for the a* algorithm
            let one-pseudopodia-here one-of pseudopodia-here
            ;;ask pseudopodia-here [print word "x:" xcor print word "y:" ycor ]
            ;; 08.09.2022 The plasmodium-position property shows the current position of the plasmodium.
            ;; After calculating the shortest path between start and destination, the plasmodium takes over the x and y coordinates of the end point.
            ;; In the next search, these coordinates are used as the start point.
            ;;print one-pseudopodia-here
            ;;print pseudopodia-here
            run-a-star item 0 plasmodium-position item 1 plasmodium-position ([xcor] of one-pseudopodia-here) ([ycor] of one-pseudopodia-here)
            set plasmodium-position list [xcor] of one-pseudopodia-here [ycor] of one-pseudopodia-here
            ask links [set color orange]
            die
            print word "End:" date-and-time
          ]
        ]
        ;; calculates a random float number between 0 an 1
        if random-float 1 <= hatch-probability
        [
          ;; create new child from pseudopodia, replace the zeros in the path-list to indicate, that it is a copy
          hatch-pseudopodia 1
          [
                     let new-path-list replace-zeros path-list
            set path-list new-path-list
          ]
        ]
      ]
      [
        ;; movment of the pseudopodia -> bounce of the wall, movement and sense chemotaxis from food
        bounce
        wiggle
        look-for-food
      ]
    ]
    ;; if the a * buildet a tube display it
    ask tubes[
      let i 0
      while [i < length path-list] ;;old version: path-list-1
      [
        let x-1 [xcor] of item i path-list
        let y-1 [ycor] of item i path-list
        setxy x-1 y-1
        let col [pcolor] of one-of neighbors
        set i i + 1
      ]

      die
    ]
    ask networkpoints [ die ]
    tick
  ]
  [
    ;;print date-and-time
    ;;print count pseudopodia
    print word "End: " date-and-time
    print word "End Pseudopodia: " count pseudopodia
    stop
  ]
end

to look-for-food
  ;; find chemotaxis in the area of a food source
  let foodsource one-of foods in-radius 5
  if (foodsource != nobody)
  [
    ;; if there is chemotaxis ahead move towards the center
    face foodsource
  ]
end

to wiggle
 ;; print "wiggeln"
  rt random 40
  lt random 40
  if not can-move? 1 [ rt 180 ]
  while [[pcolor] of patch-ahead 1 >= 50][rt (90 + (random (90 - 270)))]
  if pcolor >= 50 [rt (90 + (random (270 - 90)))]
  fd 1
  ;; create a new entry for the path list (with x and y coordinates and 0 because the step from this pseudopodia is new)
  let xycoordinate (list xcor ycor 0)
  set path-list insert-item (length path-list) path-list xycoordinate
 end

to bounce
  ;; bounce off left and right walls
  if abs pxcor >= max-pxcor - 1
  [
    ;; if "at the end of the world" face towards center and move one forward
    face patch 0 0
    ;; move one forward otherwise it will get stuck at the edge of the world
    fd 1
  ]
  ;; bounce off top and bottom walls
  if abs pycor >= max-pycor - 2
  [
    ;; if "at the end of the world" face towards center and move one forward
    face patch 0 0
    ;; move one forward otherwise it will get stuck at the edge of the world
    fd 1
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
1748
649
-1
-1
30.0
1
15
1
1
1
0
1
1
1
-25
25
-10
10
1
1
1
ticks
15.0

BUTTON
17
17
81
50
Setup
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
119
17
182
50
Go
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

SLIDER
16
71
188
104
amount-pseudopodia
amount-pseudopodia
1
50
3.0
1
1
NIL
HORIZONTAL

SLIDER
15
123
187
156
amount-foodsources
amount-foodsources
1
10
2.0
1
1
NIL
HORIZONTAL

SWITCH
14
169
191
202
show-nutrient-value
show-nutrient-value
1
1
-1000

SWITCH
12
215
190
248
show-network
show-network
1
1
-1000

SWITCH
11
262
189
295
show-intersection-points
show-intersection-points
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

SISMO (SImulation of Slime MOlds) simulates spreading during foraging by the slime mold of the species Physarum polycephalum.

## HOW IT WORKS

The plasmodium, along with the desired number of pseudopods and food sources, are distributed in specific coordinates on a map. The pseudopods then spread out to look for food sources. If a food source is found and the nutrients are used up, new pseudopodia may be attached with a certain probability. As long as there are still food sources available, the slime mold will keep searching for them. The thicker yellow tubes in the map represent the shortest paths between the food sources and the plasmodium. In nature, the slime mold uses distinct veins to transport food. The A* algorithm is used to determine the shortest path.


## HOW TO USE IT

Click the SETUP button to set up the pseudopodium (the yellow blob), the foodsources and the selected number of initial pseudopodia. Click the GO button to start the simulation. The movements of the pseudopoida are represented by yellow lines.
The AMOUNT-PSEUDOPODIA slider sets the number of initial pseudopodia.
The slider AMOUNT-FOODSOURCES sets the number of food sources. This slider is not needed, when the the number and coordinates of the food sources is given in the "Code" section.
The SHOW-NUTRIENT-VALUE switch determines whether the number of nutrients from the food sources should be displayed or not.
The switch SHOW-NETWORK determines whether the created network (blue dots), which is needed for the A* algorithm, should be displayed or not.
The switch SHOW-INTERSECTION-POINTS determines whether the calculated intersection points (red crosses at the intersections of the pseudopodia) should be displayed or not.


## THINGS TO NOTICE

The duration of the simulation can vary greatly depending on the number of food sources and the number of pseudopodia selected. A higher number of pseudopodia and food sources leads accordingly to a longer simulation duration. Also, a higher hatch-probability (adjustable in the "Code" section) leads to a higher number of pseudopods in the map over time. The speed should be set slower to make the spread of the slime mold more vivid.

In the Command Center, the start and end date and time are displayed for each simulation, the number of pseudopods set inital, the hatch probability of the pseudopods, and the number of pseudopods at the end of the simulation. For a better visibility, the Command Center should be cleared after each simulation using the "Clear" button. 

## THINGS TO TRY

Change the number of pseudopodia and food sources. Display Nutrient values to see how quickly the pseudopodia consume them. Furthermore, the network points can be displayed. If this is the case, then one can see how the network is constructed for the A* algorithm. Furthermore the found intersection points can be displayed.

## EXTENDING THE MODEL

Since the simulation takes quite a long time, one could consider improving the performance. Also, the calculations of the intersections could be outsourced to Python, for example, and the calculations could be run in parallel there. Furthermore, one could let the pseudopodia disappear over the time. Since slime molds also do this in nature. Only the important thick veins remain the longest.

## NETLOGO FEATURES

create-link-with is used to create the links at the intersection points. one-of is used to check if there is already an existing network point at the current coordinates, so that more network points are not created unnecessarily. one-of is used when the nutrients of the foodsource are exhausted to determine the end point for the A* algorithm.

## RELATED MODELS

The A* algorithm used in this model is based on the A* algorithm programmed by Fernando Sancho Caparrini in Netlogo and is adapted for the SISMO: http://www.cs.us.es/~fsancho/ https://github.com/fsancho/IA/blob/542a152c7920ec8606656b6c9a46cd4545fc2175/11.%20Machine%20Learning/Self%20Organizing%20Maps/Nav%20Robot/Geom%20A-star.nls


## CREDITS AND REFERENCES

Fernando Sancho Caparrini - “A General A* Solver in NetLogo” http://www.cs.us.es/~fsancho/?e=131

## COPYRIGHT AND LICENSE

Copyright 2022 Emir Sinanovic & Kristina Wogatai.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

This model was developed at the university Klagenfurt in a collaboration between Emir Sinanovic and Kristina Wogatai in the course of the connected master theses "Simulation and Mobility Planning
with Slime Molds" and "SISMO (SImulation of Slime MOlds):  A Slime Mold Based Algorithm and its Application in Traffic Management". 

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

cloud
false
0
Circle -7500403 true true 13 118 94
Circle -7500403 true true 86 101 127
Circle -7500403 true true 51 51 108
Circle -7500403 true true 118 43 95
Circle -7500403 true true 158 68 134

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

petals
false
0
Circle -7500403 true true 117 12 66
Circle -7500403 true true 116 221 67
Circle -7500403 true true 41 41 67
Circle -7500403 true true 11 116 67
Circle -7500403 true true 41 191 67
Circle -7500403 true true 191 191 67
Circle -7500403 true true 221 116 67
Circle -7500403 true true 191 41 67
Circle -7500403 true true 60 60 180

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
NetLogo 6.2.2
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
