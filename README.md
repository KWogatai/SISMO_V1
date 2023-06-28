# SISMO
Slime Mold Simulation (adapted for Energy Networks)

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
