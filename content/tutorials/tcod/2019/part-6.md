---
title: "Part 6 - Doing (and taking) some damage"
date: 2019-03-30T09:33:50-07:00
draft: false
aliases: /tutorials/tcod/part-6
---

The last part of this tutorial set us up for combat, so now it's time to
actually implement it.

In order to make "killable" Entities, rather than attaching hit points
to each Entity we create, we'll create a **component**, called
`Fighter`, which will hold information related to combat, like HP, max
HP, attack, and defense. If an Entity can fight, it will have this
component attached to it, and if not, it won't. This way of doing things
is called **composition**, and it's an alternative to your typical
inheritance-based programming model.

Create a new Python package (a folder with an empty \_\_init\_\_.py
file), called `components`. In there, put a new file called
`fighter.py`, and put the following code in it:

{{< highlight py3 >}}
class Fighter:
    def __init__(self, hp, defense, power):
        self.max_hp = hp
        self.hp = hp
        self.defense = defense
        self.power = power
{{</ highlight >}}

These variables should look familiar to anyone who's played an RPG
before. HP represents the entity's health, defense blocks damage, and
power is the entity's attack strength. Perhaps the game you have in mind
has a more complex combat model, but we'll keep it simple here.

Another component we'll need is one to define the enemy AI. Some
entities (enemies) will have AI, whereas others (player, items) will
not. We'll set up our game loop to allow any entity with an AI
component, regardless of what it is, to take a turn, and all others
won't get to.

Create a file in `components` called `ai.py`, and put the following
class in it:

{{< highlight py3 >}}
class BasicMonster:
    def take_turn(self):
        print('The ' + self.owner.name + ' wonders when it will get to move.')
{{</ highlight >}}

We've defined a basic method called `take_turn`, which we'll call in our
game loop in a minute. It's just a placeholder for now, but by the end
of this chapter, the `take_turn` function will actually move the entity
around.

With our classes in place, we'll turn our attention to the `Entity`
class once more. We need to pass the components through the constructor,
like we do for everything else. Modify the `__init__` function in
`Entity` to look like this:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
class Entity:
-   def __init__(self, x, y, char, color, name, blocks=False):
+   def __init__(self, x, y, char, color, name, blocks=False, fighter=None, ai=None):
        self.x = x
        self.y = y
        self.char = char
        self.color = color
        self.name = name
        self.blocks = blocks
+       self.fighter = fighter
+       self.ai = ai
+
+       if self.fighter:
+           self.fighter.owner = self
+
+       if self.ai:
+           self.ai.owner = self
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class Entity:
    <span class="crossed-out-text">def __init__(self, x, y, char, color, name, blocks=False):</span>
    <span class="new-text">def __init__(self, x, y, char, color, name, blocks=False, fighter=None, ai=None):</span>
        self.x = x
        self.y = y
        self.char = char
        self.color = color
        self.name = name
        self.blocks = blocks
        <span class="new-text">self.fighter = fighter
        self.ai = ai

        if self.fighter:
            self.fighter.owner = self

        if self.ai:
            self.ai.owner = self</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

So the `fighter` and `ai` components are optional, so entities that
don't need them won't need to do anything.

Why do we need to set the owner of the component to self? There will be
a few instances where we'll want to access the Entity from within the
component. In our previous bit of code for the `BasicMonster`, we gained
access to the entity's "name" simply by referencing the "owner". We just
have to be sure we set the owner upon initializing the entity.

Now we'll need to add our new components to all the entities we've
created so far. Let's start with the easiest one: the player. The player
doesn't actually need AI (because we're controlling the player object
directly), but it does need the `Fighter` component.

First, import the `Fighter` component into `engine.py`:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
import tcod as libtcod

+from components.fighter import Fighter
from entity import Entity, get_blocking_entities_at_location
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>import tcod as libtcod

<span class="new-text">from components.fighter import Fighter</span>
from entity import Entity, get_blocking_entities_at_location</pre>
{{</ original-tab >}}
{{</ codetab >}}

Then, create the component and add it to the player Entity.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
+   fighter_component = Fighter(hp=30, defense=2, power=5)
-   player = Entity(0, 0, '@', libtcod.white, 'Player', blocks=True)
+   player = Entity(0, 0, '@', libtcod.white, 'Player', blocks=True, fighter=fighter_component)
    entities = [player]
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
        <pre>
    <span class="new-text">fighter_component = Fighter(hp=30, defense=2, power=5)</span>
    <span class="crossed-out-text">player = Entity(0, 0, '@', libtcod.white, 'Player', blocks=True)</span>
    <span class="new-text">player = Entity(0, 0, '@', libtcod.white, 'Player', blocks=True, fighter=fighter_component)</span>
    entities = [player]
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

And now for our monsters. We'll need both the Fighter and BasicMonster
components for them.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
                if randint(0, 100) < 80:
+                   fighter_component = Fighter(hp=10, defense=0, power=3)
+                   ai_component = BasicMonster()

-                   monster = Entity(x, y, 'o', libtcod.desaturated_green, 'Orc', blocks=True)
+                   monster = Entity(x, y, 'o', libtcod.desaturated_green, 'Orc', blocks=True,
+                                    fighter=fighter_component, ai=ai_component)
                else:
+                   fighter_component = Fighter(hp=16, defense=1, power=4)
+                   ai_component = BasicMonster()

-                   monster = Entity(x, y, 'T', libtcod.darker_green, 'Troll', blocks=True)
+                   monster = Entity(x, y, 'T', libtcod.darker_green, 'Troll', blocks=True, fighter=fighter_component,
+                                    ai=ai_component)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>
                if randint(0, 100) < 80:
                    <span class="new-text">fighter_component = Fighter(hp=10, defense=0, power=3)
                    ai_component = BasicMonster()</span>

                    <span class="crossed-out-text">monster = Entity(x, y, 'o', libtcod.desaturated_green, 'Orc', blocks=True)</span>
                    <span class="new-text">monster = Entity(x, y, 'o', libtcod.desaturated_green, 'Orc', blocks=True,
                                     fighter=fighter_component, ai=ai_component)</span>
                else:
                    <span class="new-text">fighter_component = Fighter(hp=16, defense=1, power=4)
                    ai_component = BasicMonster()</span>

                    <span class="crossed-out-text">monster = Entity(x, y, 'T', libtcod.darker_green, 'Troll', blocks=True)</span>
                    <span class="new-text">monster = Entity(x, y, 'T', libtcod.darker_green, 'Troll', blocks=True, fighter=fighter_component,
                                     ai=ai_component)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Remember to import the needed classes at the top.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
import tcod as libtcod
from random import randint

+from components.ai import BasicMonster
+from components.fighter import Fighter

from entity import Entity

from map_objects.rectangle import Rect
from map_objects.tile import Tile
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>import tcod as libtcod
from random import randint

<span class="new-text">from components.ai import BasicMonster
from components.fighter import Fighter</span>

from entity import Entity

from map_objects.rectangle import Rect
from map_objects.tile import Tile</pre>
{{</ original-tab >}}
{{</ codetab >}}

Now we can modify our monster's turn loop to use the `take_turn`
function.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
        ...
        if game_state == GameStates.ENEMY_TURN:
            for entity in entities:
-               if entity != player:
+               if entity.ai:
-                   print('The ' + entity.name + ' ponders the meaning of its existence.')
+                   entity.ai.take_turn()

            game_state = GameStates.PLAYERS_TURN
            ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>        ...
        if game_state == GameStates.ENEMY_TURN:
            for entity in entities:
                <span class="crossed-out-text">if entity != player:</span>
                <span class="new-text">if entity.ai:</span>
                    <span class="crossed-out-text">print('The ' + entity.name + ' ponders the meaning of its existence.')</span>
                    <span class="new-text">entity.ai.take_turn()</span>

            game_state = GameStates.PLAYERS_TURN
            ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Not a whole lot has changed yet (we're still printing something instead
of the monsters taking a real turn), but we're getting there. Notice
that rather than checking if the entity is not the player, we're
checking if the entity has an AI component. The player doesn't have an
AI component, so the loop will skip the player, but more importantly,
any items we implement later on won't get a "turn" either.

Now for our actual AI implementation. Our AI will be very simple
(stupidly so, really). If the enemy can "see" the player, it will move
towards the player, and if it is next to the player, it will attack. We
won't implement enemy FOV in this tutorial; instead, we'll just assume
that if you can see an enemy, it can see you too.

Let's put a basic movement function in place. Put the following code in
the `Entity` class.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
    def move(self, dx, dy):
        ...

+   def move_towards(self, target_x, target_y, game_map, entities):
+       dx = target_x - self.x
+       dy = target_y - self.y
+       distance = math.sqrt(dx ** 2 + dy ** 2)
+
+       dx = int(round(dx / distance))
+       dy = int(round(dy / distance))
+
+       if not (game_map.is_blocked(self.x + dx, self.y + dy) or
+                   get_blocking_entities_at_location(entities, self.x + dx, self.y + dy)):
+           self.move(dx, dy)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>    def move(self, dx, dy):
        ...

    <span class="new-text">def move_towards(self, target_x, target_y, game_map, entities):
        dx = target_x - self.x
        dy = target_y - self.y
        distance = math.sqrt(dx ** 2 + dy ** 2)

        dx = int(round(dx / distance))
        dy = int(round(dy / distance))

        if not (game_map.is_blocked(self.x + dx, self.y + dy) or
                    get_blocking_entities_at_location(entities, self.x + dx, self.y + dy)):
            self.move(dx, dy)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

We'll also need a function to get the distance between the Entity and
its target.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
    def move_towards(self, target_x, target_y, game_map, entities):
        ...

+   def distance_to(self, other):
+       dx = other.x - self.x
+       dy = other.y - self.y
+       return math.sqrt(dx ** 2 + dy ** 2)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>    def move_towards(self, target_x, target_y, game_map, entities):
        ...

    <span class="new-text">def distance_to(self, other):
        dx = other.x - self.x
        dy = other.y - self.y
        return math.sqrt(dx ** 2 + dy ** 2)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Both of these functions use the `math` module, so we'll need to import
that.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
+import math


class Entity:
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre><span class="new-text">import math</span>


class Entity:
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Now let's replace our placeholder `take_turn` function with one that
will actually move the Entity.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
import tcod as libtcod


class BasicMonster:
-   def take_turn(self):
+   def take_turn(self, target, fov_map, game_map, entities):
-       print('The ' + self.owner.name + ' wonders when it will get to move.')
+       monster = self.owner
+       if libtcod.map_is_in_fov(fov_map, monster.x, monster.y):
+
+           if monster.distance_to(target) >= 2:
+               monster.move_towards(target.x, target.y, game_map, entities)
+
+           elif target.fighter.hp > 0:
+               print('The {0} insults you! Your ego is damaged!'.format(monster.name))
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre><span class="new-text">import tcod as libtcod</span>


class BasicMonster:
    <span class="crossed-out-text">def take_turn(self):</span>
    <span class="new-text">def take_turn(self, target, fov_map, game_map, entities):</span>
        <span class="crossed-out-text">print('The ' + self.owner.name + ' wonders when it will get to move.')</span>
        <span class="new-text">monster = self.owner
        if libtcod.map_is_in_fov(fov_map, monster.x, monster.y):

            if monster.distance_to(target) >= 2:
                monster.move_towards(target.x, target.y, game_map, entities)

            elif target.fighter.hp > 0:
                print('The {0} insults you! Your ego is damaged!'.format(monster.name))</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

We'll also need to update the call to `take_turn` in `engine.py`

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
-                   entity.ai.take_turn()
+                   entity.ai.take_turn(player, fov_map, game_map, entities)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>                    <span class="crossed-out-text">entity.ai.take_turn()</span>
                    <span class="new-text">entity.ai.take_turn(player, fov_map, game_map, entities)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Now our enemies will give chase, and, if they catch up, hurl insults at
our poor player\!

If you run the project, you may notice something strange about our mean
spirited monsters: They can insult you from a diagonal position, but the
player and the monsters can only move in the cardinal directions (north,
east, south, west). If the enemies were actually attacking us right now,
they'd have an unfair advantage. While this could make for interesting
gameplay, we'll fix that here to allow for 8 directional attacking and
movement for all Entities.

For the player, that's easy enough; we just need to update `handle_keys`
to allow us to move diagonally. Modify the movement part of that
function like so:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
def handle_keys(key):
+   key_char = chr(key.c)

-   if key.vk == libtcod.KEY_UP:
+   if key.vk == libtcod.KEY_UP or key_char == 'k':
        return {'move': (0, -1)}
-  elif key.vk == libtcod.KEY_DOWN:
+   elif key.vk == libtcod.KEY_DOWN or key_char == 'j':
        return {'move': (0, 1)}
-   elif key.vk == libtcod.KEY_LEFT:
+   elif key.vk == libtcod.KEY_LEFT or key_char == 'h':
        return {'move': (-1, 0)}
-   elif key.vk == libtcod.KEY_RIGHT:
+   elif key.vk == libtcod.KEY_RIGHT or key_char == 'l':
        return {'move': (1, 0)}
+   elif key_char == 'y':
+       return {'move': (-1, -1)}
+   elif key_char == 'u':
+       return {'move': (1, -1)}
+   elif key_char == 'b':
+       return {'move': (-1, 1)}
+   elif key_char == 'n':
+       return {'move': (1, 1)}

    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>def handle_keys(key):
    <span class="new-text">key_char = chr(key.c)</span>

    if key.vk == libtcod.KEY_UP<span class="new-text"> or key_char == 'k'</span>:
        return {'move': (0, -1)}
    elif key.vk == libtcod.KEY_DOWN<span class="new-text"> or key_char == 'j'</span>:
        return {'move': (0, 1)}
    elif key.vk == libtcod.KEY_LEFT<span class="new-text"> or key_char == 'h'</span>:
        return {'move': (-1, 0)}
    elif key.vk == libtcod.KEY_RIGHT<span class="new-text"> or key_char == 'l'</span>:
        return {'move': (1, 0)}
    <span class="new-text">elif key_char == 'y':
        return {'move': (-1, -1)}
    elif key_char == 'u':
        return {'move': (1, -1)}
    elif key_char == 'b':
        return {'move': (-1, 1)}
    elif key_char == 'n':
        return {'move': (1, 1)}</span>

    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

The first line is just getting the 'character' that we pressed on the
keyboard. This will be handy in other spots as well, when we check for
inventory and pickup commands.

For diagonal movement, we've implemented the "vim keys" for movement,
while also retaining the arrow keys for cardinal directions. Vim keys
allow you to move diagonally without the help of a numpad. A lot of
older roguelikes do 8 directions through the numpad, but personally, I
play all my roguelikes on a laptop, which doesn't have one, so the Vim
keys are useful.

Getting the enemies to move in eight directions is going to be a bit
more complicated. For that, we'll want to use a pathfinding algorithm
known as A-star. I'm simply going to be copying the code from the
[Roguebasin
extra](http://www.roguebasin.com/index.php?title=Complete_Roguelike_Tutorial,_using_Python%2Blibtcod,_extras#A.2A_Pathfinding)
for our purposes. I won't go into detail explaining how this works, but
if you want to know more about the details of the algorithm, [click
here](https://en.wikipedia.org/wiki/A*_search_algorithm).

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
    def move_towards(self, target_x, target_y, game_map, entities):
    ...

+   def move_astar(self, target, entities, game_map):
+       # Create a FOV map that has the dimensions of the map
+       fov = libtcod.map_new(game_map.width, game_map.height)
+
+       # Scan the current map each turn and set all the walls as unwalkable
+       for y1 in range(game_map.height):
+           for x1 in range(game_map.width):
+               libtcod.map_set_properties(fov, x1, y1, not game_map.tiles[x1][y1].block_sight,
+                                          not game_map.tiles[x1][y1].blocked)
+
+       # Scan all the objects to see if there are objects that must be navigated around
+       # Check also that the object isn't self or the target (so that the start and the end points are free)
+       # The AI class handles the situation if self is next to the target so it will not use this A* function anyway
+       for entity in entities:
+           if entity.blocks and entity != self and entity != target:
+               # Set the tile as a wall so it must be navigated around
+               libtcod.map_set_properties(fov, entity.x, entity.y, True, False)
+
+       # Allocate a A* path
+       # The 1.41 is the normal diagonal cost of moving, it can be set as 0.0 if diagonal moves are prohibited
+       my_path = libtcod.path_new_using_map(fov, 1.41)
+
+       # Compute the path between self's coordinates and the target's coordinates
+       libtcod.path_compute(my_path, self.x, self.y, target.x, target.y)
+
+       # Check if the path exists, and in this case, also the path is shorter than 25 tiles
+       # The path size matters if you want the monster to use alternative longer paths (for example through other rooms) if for example the player is in a corridor
+       # It makes sense to keep path size relatively low to keep the monsters from running around the map if there's an alternative path really far away
+       if not libtcod.path_is_empty(my_path) and libtcod.path_size(my_path) < 25:
+           # Find the next coordinates in the computed full path
+           x, y = libtcod.path_walk(my_path, True)
+           if x or y:
+               # Set self's coordinates to the next path tile
+               self.x = x
+               self.y = y
+       else:
+           # Keep the old move function as a backup so that if there are no paths (for example another monster blocks a corridor)
+           # it will still try to move towards the player (closer to the corridor opening)
+           self.move_towards(target.x, target.y, game_map, entities)
+
+           # Delete the path to free memory
+       libtcod.path_delete(my_path)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>    def move_towards(self, target_x, target_y, game_map, entities):
    ...

    <span class="new-text">def move_astar(self, target, entities, game_map):
        # Create a FOV map that has the dimensions of the map
        fov = libtcod.map_new(game_map.width, game_map.height)

        # Scan the current map each turn and set all the walls as unwalkable
        for y1 in range(game_map.height):
            for x1 in range(game_map.width):
                libtcod.map_set_properties(fov, x1, y1, not game_map.tiles[x1][y1].block_sight,
                                           not game_map.tiles[x1][y1].blocked)

        # Scan all the objects to see if there are objects that must be navigated around
        # Check also that the object isn't self or the target (so that the start and the end points are free)
        # The AI class handles the situation if self is next to the target so it will not use this A* function anyway
        for entity in entities:
            if entity.blocks and entity != self and entity != target:
                # Set the tile as a wall so it must be navigated around
                libtcod.map_set_properties(fov, entity.x, entity.y, True, False)

        # Allocate a A* path
        # The 1.41 is the normal diagonal cost of moving, it can be set as 0.0 if diagonal moves are prohibited
        my_path = libtcod.path_new_using_map(fov, 1.41)

        # Compute the path between self's coordinates and the target's coordinates
        libtcod.path_compute(my_path, self.x, self.y, target.x, target.y)

        # Check if the path exists, and in this case, also the path is shorter than 25 tiles
        # The path size matters if you want the monster to use alternative longer paths (for example through other rooms) if for example the player is in a corridor
        # It makes sense to keep path size relatively low to keep the monsters from running around the map if there's an alternative path really far away
        if not libtcod.path_is_empty(my_path) and libtcod.path_size(my_path) < 25:
            # Find the next coordinates in the computed full path
            x, y = libtcod.path_walk(my_path, True)
            if x or y:
                # Set self's coordinates to the next path tile
                self.x = x
                self.y = y
        else:
            # Keep the old move function as a backup so that if there are no paths (for example another monster blocks a corridor)
            # it will still try to move towards the player (closer to the corridor opening)
            self.move_towards(target.x, target.y, game_map, entities)

            # Delete the path to free memory
        libtcod.path_delete(my_path)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

For this to work, we'll need to import `libtcod` into `entity.py`:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
+import tcod as libtcod

import math
...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre><span class="new-text">import tcod as libtcod</span>

import math
...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Note that if for whatever reason the algorithm doesn't find a path, it
will revert back to our previous movement function, so we still need
that.

Modify the `take_turn` function in `BasicMonster` to take advantage of
this new function.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
            ...
            if monster.distance_to(target) >= 2:
+               monster.move_astar(target, entities, game_map)
-               monster.move_towards(target.x, target.y, game_map, entities)
            ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>            ...
            if monster.distance_to(target) >= 2:
                <span class="new-text">monster.move_astar(target, entities, game_map)</span>
                <span style="color: red; text-decoration: line-through;">monster.move_towards(target.x, target.y, game_map, entities)</span>
            ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Now both the player and enemies can move in diagonals. With that taken
care of, it's time to implement an actual combat system. Let's start by
adding a method to `Fighter` that allows the entity to take damage.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
class Fighter:
    def __init__(self, hp, defense, power):
        ...

+   def take_damage(self, amount):
+       self.hp -= amount
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class Fighter:
    def __init__(self, hp, defense, power):
        ...

    <span class="new-text">def take_damage(self, amount):
        self.hp -= amount</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Simple enough. Now for the attack function (also in `Fighter`):

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
    ...

+   def attack(self, target):
+       damage = self.power - target.fighter.defense
+
+       if damage > 0:
+           target.fighter.take_damage(damage)
+           print('{0} attacks {1} for {2} hit points.'.format(self.owner.name.capitalize(), target.name, str(damage)))
+       else:
+           print('{0} attacks {1} but does no damage.'.format(self.owner.name.capitalize(), target.name))
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>    ...

    <span class="new-text">def attack(self, target):
        damage = self.power - target.fighter.defense

        if damage > 0:
            target.fighter.take_damage(damage)
            print('{0} attacks {1} for {2} hit points.'.format(self.owner.name.capitalize(), target.name, str(damage)))
        else:
            print('{0} attacks {1} but does no damage.'.format(self.owner.name.capitalize(), target.name))</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

There's nothing too complex about this system. We're taking the
attacker's power and subtracting the defender's defense, and getting our
damage dealt. If the damage is above zero, then the target takes damage.

We can finally replace our placeholders from earlier\! Modify the
player's placeholder in `engine.py`:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
                if target:
-                   print('You kick the ' + target.name + ' in the shins, much to its annoyance!')
+                   player.fighter.attack(target)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>                if target:
                    <span class="crossed-out-text">print('You kick the ' + target.name + ' in the shins, much to its annoyance!')</span>
                    <span class="new-text">player.fighter.attack(target)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

... And for the enemy placeholder in `BasicMonster`

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
            ...
            elif target.fighter.hp > 0:
-               print('The {0} insults you! Your ego is damaged!'.format(monster.name))
+               monster.fighter.attack(target)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>            ...
            elif target.fighter.hp > 0:
                <span class="crossed-out-text">print('The {0} insults you! Your ego is damaged!'.format(monster.name))</span>
                <span class="new-text">monster.fighter.attack(target)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Now we can attack enemies, and they can attack us\!

As exciting as this all is, we have to take a step back for a moment and
think about a design question. Right now, we're printing our messages to
the console, but in the next chapter we'll move that to a more formal
message log. Also, later in this chapter, we need to alter the game
state when the player is killed in action. Do functions like `attack`
and `take_damage` really need to receive the message log or game state
as arguments? And should they be directly manipulating those things in
the first place?

There's a lot of different ways to handle this. For this tutorial, we'll
implement a `results` list for functions like this, which will be
returned to the `engine.py` file, and be handled there. We're already
doing something similar in `handle_keys`; that function just returns the
results of the key press, it doesn't actually *move* the player.

Let's modify the `take_damage` and `attack` functions to return an array
of results, rather than print anything.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
    def take_damage(self, amount):
+       results = []

        self.hp -= amount

+       if self.hp <= 0:
+           results.append({'dead': self.owner})
+
+       return results

    def attack(self, target):
+       results = []

        damage = self.power - target.fighter.defense

        if damage > 0:
-           target.fighter.take_damage(damage)
-           print('{0} attacks {1} for {2} hit points.'.format(self.owner.name.capitalize(), target.name, str(damage)))
+           results.append({'message': '{0} attacks {1} for {2} hit points.'.format(
+               self.owner.name.capitalize(), target.name, str(damage))})
+           results.extend(target.fighter.take_damage(damage))
        else:
-           print('{0} attacks {1} but does no damage.'.format(self.owner.name.capitalize(), target.name))
+           results.append({'message': '{0} attacks {1} but does no damage.'.format(
+               self.owner.name.capitalize(), target.name)})
+
+       return results
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>
    def take_damage(self, amount):
        <span class="new-text">results = []</span>

        self.hp -= amount

        <span class="new-text">if self.hp <= 0:
            results.append({'dead': self.owner})

        return results</span>

    def attack(self, target):
        <span class="new-text">results = []</span>

        damage = self.power - target.fighter.defense

        if damage > 0:
            <span style="color: red; text-decoration: line-through;">target.fighter.take_damage(damage)</span>
            <span style="color: red; text-decoration: line-through;">print('{0} attacks {1} for {2} hit points.'.format(self.owner.name.capitalize(), target.name, str(damage)))</span>
            <span class="new-text">results.append({'message': '{0} attacks {1} for {2} hit points.'.format(
                self.owner.name.capitalize(), target.name, str(damage))})
            results.extend(target.fighter.take_damage(damage))</span>
        else:
            <span style="color: red; text-decoration: line-through;">print('{0} attacks {1} but does no damage.'.format(self.owner.name.capitalize(), target.name))</span>
            <span class="new-text">results.append({'message': '{0} attacks {1} but does no damage.'.format(
                self.owner.name.capitalize(), target.name)})

        return results</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Let's break it down a little. In `take_damage`, we add a dictionary to
`results` if the entity happens to die after taking damage. The results
list is returned regardless (it may be empty).

In `attack`, we're again setting a list called `results`, and we add our
message to it regardless of damage was taken or not. Notice that in the
`if` block, we're using `extend` to add the results of `take_damage` to
our current `results` list.

The `extend` function is similar to `append`, but it keeps our list
flat, so we don't get something like `[{'message': 'something'},
[{'message': 'something else'}]]`. Instead, we would get: `[{'message':
'something'}, {'message': 'something else'}]`. That will make looping
through our results much simpler.

Let's extend this logic to the `take_turn` function in `BasicMonster`.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
class BasicMonster:
    def take_turn(self, target, fov_map, game_map, entities):
+       results = []

        monster = self.owner
        if libtcod.map_is_in_fov(fov_map, monster.x, monster.y):

            if monster.distance_to(target) >= 2:
                monster.move_astar(target, entities, game_map)

            elif target.fighter.hp > 0:
-               monster.fighter.attack(target)
+               attack_results = monster.fighter.attack(target)
+               results.extend(attack_results)
+
+       return results
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class BasicMonster:
    def take_turn(self, target, fov_map, game_map, entities):
        <span class="new-text">results = []</span>

        monster = self.owner
        if libtcod.map_is_in_fov(fov_map, monster.x, monster.y):

            if monster.distance_to(target) >= 2:
                monster.move_astar(target, entities, game_map)

            elif target.fighter.hp > 0:
                <span class="crossed-out-text">monster.fighter.attack(target)</span>
                <span class="new-text">attack_results = monster.fighter.attack(target)
                results.extend(attack_results)

        return results</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

So what do we actually *do* with this `results` list? Lets modify
`engine.py` to react to the results of our attacks.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
        ...
        fullscreen = action.get('fullscreen')

+       player_turn_results = []

        if move and game_state == GameStates.PLAYERS_TURN:
            dx, dy = move
            destination_x = player.x + dx
            destination_y = player.y + dy

            if not game_map.is_blocked(destination_x, destination_y):
                target = get_blocking_entities_at_location(entities, destination_x, destination_y)

                if target:
-                   player.fighter.attack(target)
+                   attack_results = player.fighter.attack(target)
+                   player_turn_results.extend(attack_results)
                else:
                    player.move(dx, dy)

                    fov_recompute = True

                game_state = GameStates.ENEMY_TURN

        if exit:
            return True

        if fullscreen:
            libtcod.console_set_fullscreen(not libtcod.console_is_fullscreen())

+       for player_turn_result in player_turn_results:
+           message = player_turn_result.get('message')
+           dead_entity = player_turn_result.get('dead')
+
+           if message:
+               print(message)
+
+           if dead_entity:
+               pass # We'll do something here momentarily

        if game_state == GameStates.ENEMY_TURN:
            for entity in entities:
                if entity.ai:
-                   entity.ai.take_turn(player, fov_map, game_map, entities)
+                   enemy_turn_results = entity.ai.take_turn(player, fov_map, game_map, entities)
+
+                   for enemy_turn_result in enemy_turn_results:
+                       message = enemy_turn_result.get('message')
+                       dead_entity = enemy_turn_result.get('dead')
+
+                       if message:
+                           print(message)
+
+                       if dead_entity:
+                           pass
+
+           else:
                game_state = GameStates.PLAYERS_TURN
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>        ...
        fullscreen = action.get('fullscreen')

        <span class="new-text">player_turn_results = []</span>

        if move and game_state == GameStates.PLAYERS_TURN:
            dx, dy = move
            destination_x = player.x + dx
            destination_y = player.y + dy

            if not game_map.is_blocked(destination_x, destination_y):
                target = get_blocking_entities_at_location(entities, destination_x, destination_y)

                if target:
                    <span style="color: red; text-decoration: line-through;">player.fighter.attack(target)</span>
                    <span class="new-text">attack_results = player.fighter.attack(target)
                    player_turn_results.extend(attack_results)</span>
                else:
                    player.move(dx, dy)

                    fov_recompute = True

                game_state = GameStates.ENEMY_TURN

        if exit:
            return True

        if fullscreen:
            libtcod.console_set_fullscreen(not libtcod.console_is_fullscreen())

        <span class="new-text">for player_turn_result in player_turn_results:
            message = player_turn_result.get('message')
            dead_entity = player_turn_result.get('dead')

            if message:
                print(message)

            if dead_entity:
                pass # We'll do something here momentarily</span>

        if game_state == GameStates.ENEMY_TURN:
            for entity in entities:
                if entity.ai:
                    <span class="crossed-out-text">entity.ai.take_turn(player, fov_map, game_map, entities)</span>
                    <span class="new-text">enemy_turn_results = entity.ai.take_turn(player, fov_map, game_map, entities)

                    for enemy_turn_result in enemy_turn_results:
                        message = enemy_turn_result.get('message')
                        dead_entity = enemy_turn_result.get('dead')

                        if message:
                            print(message)

                        if dead_entity:
                            pass

            else:</span>
                <span style="color: blue">game_state = GameStates.PLAYERS_TURN</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

*\* Note: There's that for-else statement again. There's no `break`
statement yet, so the 'else' will always happen, but we'll add it in
just a minute.*

Not that much has changed yet, but now we've set ourselves up to handle
the death of the player and the other entities. Let's implement that
now. Create a new python file called `death_functions.py` and put the
following two functions in it:

{{< highlight py3 >}}
import tcod as libtcod

from game_states import GameStates


def kill_player(player):
    player.char = '%'
    player.color = libtcod.dark_red

    return 'You died!', GameStates.PLAYER_DEAD


def kill_monster(monster):
    death_message = '{0} is dead!'.format(monster.name.capitalize())

    monster.char = '%'
    monster.color = libtcod.dark_red
    monster.blocks = False
    monster.fighter = None
    monster.ai = None
    monster.name = 'remains of ' + monster.name

    return death_message
{{</ highlight >}}

These two functions will handle the death of the player and monsters.
They're different because obviously the death of a monster isn't *that*
big a deal (we'll be killing quite a few of them), but the death of the
player is a *very* big deal (this is a roguelike after all\!).

Modify `engine.py` to use these two functions. Replace the `pass`
section like this:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
            ...
            if dead_entity:
-               pass
+               if dead_entity == player:
+                   message, game_state = kill_player(dead_entity)
+               else:
+                   message = kill_monster(dead_entity)
+
+               print(message)

        if game_state == GameStates.ENEMY_TURN:
            for entity in entities:
                if entity.ai:
                    enemy_turn_results = entity.ai.take_turn(player, fov_map, game_map, entities)

                    for enemy_turn_result in enemy_turn_results:
                        message = enemy_turn_result.get('message')
                        dead_entity = enemy_turn_result.get('dead')

                        if message:
                            print(message)

                        if dead_entity:
-                           pass
+                           if dead_entity == player:
+                               message, game_state = kill_player(dead_entity)
+                           else:
+                               message = kill_monster(dead_entity)
+
+                           print(message)
+
+                           if game_state == GameStates.PLAYER_DEAD:
+                               break
+
+                   if game_state == GameStates.PLAYER_DEAD:
+                       break
            else:
                game_state = GameStates.PLAYERS_TURN
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>            ...
            if dead_entity:
                <span style="color: red; text-decoration: line-through;">pass</span>
                <span class="new-text">if dead_entity == player:
                    message, game_state = kill_player(dead_entity)
                else:
                    message = kill_monster(dead_entity)

                print(message)</span>

        if game_state == GameStates.ENEMY_TURN:
            for entity in entities:
                if entity.ai:
                    enemy_turn_results = entity.ai.take_turn(player, fov_map, game_map, entities)

                    for enemy_turn_result in enemy_turn_results:
                        message = enemy_turn_result.get('message')
                        dead_entity = enemy_turn_result.get('dead')

                        if message:
                            print(message)

                        if dead_entity:
                            <span style="color: red; text-decoration: line-through;">pass</span>
                            <span class="new-text">if dead_entity == player:
                                message, game_state = kill_player(dead_entity)
                            else:
                                message = kill_monster(dead_entity)

                            print(message)

                            if game_state == GameStates.PLAYER_DEAD:
                                break

                    if game_state == GameStates.PLAYER_DEAD:
                        break</span>
            else:
                game_state = GameStates.PLAYERS_TURN</pre>
{{</ original-tab >}}
{{</ codetab >}}

*\*Note: There's the break statements that will skip over the 'else' in
our 'for-else'. Why do this? Because if the player is dead, we don't
want to set the game state back to the player's turn when all the
enemies are done moving. That, and there's no reason to continue with
the loop; the game is over.*

Remember to import the killing functions at the top of `engine.py`:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
...
from components.fighter import Fighter
+from death_functions import kill_monster, kill_player
from entity import Entity, get_blocking_entities_at_location
...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>...
from components.fighter import Fighter
<span class="new-text">from death_functions import kill_monster, kill_player</span>
from entity import Entity, get_blocking_entities_at_location
...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Also, we need to add the `PLAYER_DEAD` value to `GameStates`:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
class GameStates(Enum):
    PLAYERS_TURN = 1
    ENEMY_TURN = 2
+   PLAYER_DEAD = 3
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class GameStates(Enum):
    PLAYERS_TURN = 1
    ENEMY_TURN = 2
    <span class="new-text">PLAYER_DEAD = 3</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Run the project now. Entities will now drop dead when hitting 0 HP,
including the player\! When the player dies, you won't be able to move,
but you can still exit the game. At long last, we have a real combat
system in place\!

It's been a long chapter already, but let's clean things up just a
little bit. Right now, we're clueless as to how much HP the player has
remaining before death. Rather than having the user keep track of the
math in their head, we can add a little health bar by putting the
following code at the end of `render_all`, right before the blit
statement (note that the player needs to be passed to `render_all`
    now).

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
-def render_all(con, entities, game_map, fov_map, fov_recompute, screen_width, screen_height, colors):
+def render_all(con, entities, player, game_map, fov_map, fov_recompute, screen_width, screen_height, colors):
    ...
    for entity in entities:
        draw_entity(con, entity, fov_map)

+   libtcod.console_set_default_foreground(con, libtcod.white)
+   libtcod.console_print_ex(con, 1, screen_height - 2, libtcod.BKGND_NONE, libtcod.LEFT,
+                        'HP: {0:02}/{1:02}'.format(player.fighter.hp, player.fighter.max_hp))

    libtcod.console_blit(con, 0, 0, screen_width, screen_height, 0, 0, 0)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre><span class="crossed-out-text">def render_all(con, entities, game_map, fov_map, fov_recompute, screen_width, screen_height, colors):</span>
<span class="new-text">def render_all(con, entities, player, game_map, fov_map, fov_recompute, screen_width, screen_height, colors):</span>
    ...
    for entity in entities:
        draw_entity(con, entity, fov_map)

    <span class="new-text">libtcod.console_set_default_foreground(con, libtcod.white)
    libtcod.console_print_ex(con, 1, screen_height - 2, libtcod.BKGND_NONE, libtcod.LEFT,
                         'HP: {0:02}/{1:02}'.format(player.fighter.hp, player.fighter.max_hp))</span>

    libtcod.console_blit(con, 0, 0, screen_width, screen_height, 0, 0, 0)</pre>
{{</ original-tab >}}
{{</ codetab >}}

Update the call to `render_all` in
    `engine.py`:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
-render_all(con, entities, game_map, fov_map, fov_recompute, screen_width, screen_height, colors)
+render_all(con, entities, player, game_map, fov_map, fov_recompute, screen_width, screen_height, colors)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre><span class="crossed-out-text">render_all(con, entities, game_map, fov_map, fov_recompute, screen_width, screen_height, colors)</span>
<span class="new-text">render_all(con, entities, player, game_map, fov_map, fov_recompute, screen_width, screen_height, colors)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

One thing you probably noticed by now is that the enemy corpses will
"cover up" the player if we move onto them. This obviously isn't
desired; acting entities should always appear above corpses, items, and
other things in the dungeon. To solve this, let's add an Enum to the
Entities, that describes the render order in which they should be drawn.
Lower priority items will be drawn first, to ensure they never appear
above the Entities.

Add the following to `render_functions.py`:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
import tcod as libtcod

+from enum import Enum
+
+
+class RenderOrder(Enum):
+   CORPSE = 1
+   ITEM = 2
+   ACTOR = 3


def render_all(con, entities, player, game_map, fov_map, fov_recompute, screen_width, screen_height, colors):
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>import tcod as libtcod

<span class="new-text">from enum import Enum


class RenderOrder(Enum):
    CORPSE = 1
    ITEM = 2
    ACTOR = 3</span>


def render_all(con, entities, player, game_map, fov_map, fov_recompute, screen_width, screen_height, colors):
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Now modify the `__init__` function in `Entity` to take this into
account.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
import tcod as libtcod
import math

+from render_functions import RenderOrder


class Entity:
    """
    A generic object to represent players, enemies, items, etc.
    """
-   def __init__(self, x, y, char, color, name, blocks=False, fighter=None, ai=None):
+   def __init__(self, x, y, char, color, name, blocks=False, render_order=RenderOrder.CORPSE, fighter=None, ai=None):
        self.x = x
        self.y = y
        self.char = char
        self.color = color
        self.name = name
        self.blocks = blocks
+       self.render_order = render_order
        self.fighter = fighter
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>import tcod as libtcod
import math

<span class="new-text">from render_functions import RenderOrder</span>


class Entity:
    """
    A generic object to represent players, enemies, items, etc.
    """
    def __init__(self, x, y, char, color, name, blocks=False, <span class="new-text">render_order=RenderOrder.CORPSE,</span> fighter=None, ai=None):
        self.x = x
        self.y = y
        self.char = char
        self.color = color
        self.name = name
        self.blocks = blocks
        <span class="new-text">self.render_order = render_order</span>
        self.fighter = fighter
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Now modify our Entity initializations, starting with
    `engine.py`:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
-player = Entity(0, 0, '@', libtcod.white, 'Player', blocks=True, fighter=fighter_component)
+player = Entity(0, 0, '@', libtcod.white, 'Player', blocks=True, render_order=RenderOrder.ACTOR, fighter=fighter_component)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>player = Entity(0, 0, '@', libtcod.white, 'Player', blocks=True, <span class="new-text">render_order=RenderOrder.ACTOR,</span> fighter=fighter_component)</pre>
{{</ original-tab >}}
{{</ codetab >}}

... And don't leave out the import:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
-from render_functions import clear_all, render_all
+from render_functions import clear_all, render_all, RenderOrder
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from render_functions import clear_all, render_all<span class="new-text">, RenderOrder</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Now for the monsters, in `game_map.py`:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
                if randint(0, 100) < 80:
                    fighter_component = Fighter(hp=10, defense=0, power=3)
                    ai_component = BasicMonster()

-                   monster = Entity(x, y, 'o', libtcod.desaturated_green, 'Orc', blocks=True,
-                                    fighter=fighter_component, ai=ai_component)
+                   monster = Entity(x, y, 'o', libtcod.desaturated_green, 'Orc', blocks=True,
+                                    render_order=RenderOrder.ACTOR, fighter=fighter_component, ai=ai_component)
                else:
                    fighter_component = Fighter(hp=16, defense=1, power=4)
                    ai_component = BasicMonster()

-                   monster = Entity(x, y, 'T', libtcod.darker_green, 'Troll', blocks=True, fighter=fighter_component,
-                                    ai=ai_component)
+                   monster = Entity(x, y, 'T', libtcod.darker_green, 'Troll', blocks=True, fighter=fighter_component,
+                                    render_order=RenderOrder.ACTOR, ai=ai_component)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>                if randint(0, 100) < 80:
                    fighter_component = Fighter(hp=10, defense=0, power=3)
                    ai_component = BasicMonster()

                    <span class="crossed-out-text">monster = Entity(x, y, 'o', libtcod.desaturated_green, 'Orc', blocks=True,</span>
                                     <span class="crossed-out-text">fighter=fighter_component, ai=ai_component)</span>
                    <span class="new-text">monster = Entity(x, y, 'o', libtcod.desaturated_green, 'Orc', blocks=True,
                                     render_order=RenderOrder.ACTOR, fighter=fighter_component, ai=ai_component)</span>
                else:
                    fighter_component = Fighter(hp=16, defense=1, power=4)
                    ai_component = BasicMonster()

                    <span class="crossed-out-text">monster = Entity(x, y, 'T', libtcod.darker_green, 'Troll', blocks=True, fighter=fighter_component,</span>
                                     <span class="crossed-out-text">ai=ai_component)</span>
                    <span class="new-text">monster = Entity(x, y, 'T', libtcod.darker_green, 'Troll', blocks=True, fighter=fighter_component,
                                     render_order=RenderOrder.ACTOR, ai=ai_component)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

... And the import:

{{< highlight py3 >}}
from render_functions import RenderOrder
{{</ highlight >}}

We'll also need to change the Entity's `render_order` when they die.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
    monster.ai = None
    monster.name = 'remains of ' + monster.name
+   monster.render_order = RenderOrder.CORPSE
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
    <pre>    monster.ai = None
    monster.name = 'remains of ' + monster.name
    <span class="new-text">monster.render_order = RenderOrder.CORPSE</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

And, you guessed it, make sure you import:

{{< highlight py3 >}}
from render_functions import RenderOrder
{{</ highlight >}}

*\* Note: We're not changing the `render_order` on the player when it
dies; we actually **want** that corpse on top so we'll see it. It's more
dramatic that way\!*

Now let's implement the part in `render_all` that will actually take
this new variable into account.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
    if fov_recompute:
        ...

+   entities_in_render_order = sorted(entities, key=lambda x: x.render_order.value)

-   for entity in entities:
+   for entity in entities_in_render_order:
        draw_entity(con, entity, fov_map)
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>    if fov_recompute:
        ...

    <span class="new-text">entities_in_render_order = sorted(entities, key=lambda x: x.render_order.value)</span>

    <span class="crossed-out-text">for entity in entities:</span>
    <span class="new-text">for entity in entities_in_render_order:</span>
        draw_entity(con, entity, fov_map)
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Now the corpses will be drawn first, then the items (when we put them
in), then the entities. This ensures we will see what's most important
first.

And we're done\! That was quite the chapter, but you survived\! Run the
project and see how long you can last in the now-deadly Dungeons of
Doom\! With an actual combat system, we've taken a pretty massive step
towards having a real roguelike game on our hands.

If you want to see the code so far in its entirety, [click
here](https://github.com/TStand90/roguelike_tutorial_revised/tree/part6).

[Click here to move on to the next part of this
tutorial.](/tutorials/tcod/2019/part-7)

<script src="/js/codetabs.js"></script>
