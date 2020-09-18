---
title: "Part 12 - Increasing Difficulty"
date: 2020-07-28
draft: true
---

Despite the fact that we can go down floors now, the dungeon doesn't get progressively more difficult as the player descends. This is because the method in which we place monsters and items is the same on each floor. In this chapter, we'll adjust how we place things in the dungeon, so things get more difficult with each floor.

Currently, we pass `maximum_monsters` and `maximum_items` into the `place_entities` function, and this number does not change. To adjust the difficulty of our game, we can change these numbers based on the floor number. The way we'll accomplish this is by setting up a list of tuples, which will contain two integers: the floor number, and the number of items/monsters.

Add the following to `procgen.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
...
if TYPE_CHECKING:
    from engine import Engine


+max_items_by_floor = [
+   (1, 1),
+   (4, 2),
+]

+max_monsters_by_floor = [
+   (1, 2),
+   (4, 3),
+   (6, 5),
+]


class RectangularRoom:
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>...
if TYPE_CHECKING:
    from engine import Engine


<span class="new-text">max_items_by_floor = [
    (1, 1),
    (4, 2),
]

max_monsters_by_floor = [
    (1, 2),
    (4, 3),
    (6, 5),
]</span>


class RectangularRoom:
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

As mentioned, the first number in these tuples represents the floor number, and the second represents the maximum of either the items or the monsters.

You might be wondering why we've only supplied values for only certain floors. Rather than having to type out each floor number, we'll provide the floor numbers that have a different value, so that we can loop through the list and stop when we hit a floor number higher than the one we're on. For example, if we're on floor 3, we'll take the floor 1 entry for both items and monsters, and stop iteration when we reach the second item in the list, since floor 4 is higher than floor 3.

Let's write the function to take care of this. We'll call it `get_max_value_for_floor`, as we're getting the maximum value for either the items or monsters. It looks like this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
...
max_items_by_floor = [
    (1, 1),
    (4, 2),
]

max_monsters_by_floor = [
    (1, 2),
    (4, 3),
    (6, 5),
]


+def get_max_value_for_floor(
+   weighted_chances_by_floor: List[Tuple[int, int]], floor: int
+) -> int:
+   current_value = 0

+   for floor_minimum, value in weighted_chances_by_floor:
+       if floor_minimum > floor:
+           break
+       else:
+           current_value = value

+   return current_value


class RectangularRoom:
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>...
max_items_by_floor = [
    (1, 1),
    (4, 2),
]

max_monsters_by_floor = [
    (1, 2),
    (4, 3),
    (6, 5),
]


<span class="new-text">def get_max_value_for_floor(
    max_value_by_floor: List[Tuple[int, int]], floor: int
) -> int:
    current_value = 0

    for floor_minimum, value in max_value_by_floor:
        if floor_minimum > floor:
            break
        else:
            current_value = value

    return current_value</span>
    

class RectangularRoom:
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Using this function is quite simple: we simply remove the `maximum_monsters` and `maximum_items` parameters from the `place_entities` function, pass the `floor_number` instead, and use that to get our maximum values from the `get_max_value_for_floor` function.

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
-def place_entities(
-   room: RectangularRoom, dungeon: GameMap, maximum_monsters: int, maximum_items: int
-) -> None:
-   number_of_monsters = random.randint(0, maximum_monsters)
-   number_of_items = random.randint(0, maximum_items)
+def place_entities(room: RectangularRoom, dungeon: GameMap, floor_number: int,) -> None:
+   number_of_monsters = random.randint(
+       0, get_max_value_for_floor(max_monsters_by_floor, floor_number)
+   )
+   number_of_items = random.randint(
+       0, get_max_value_for_floor(max_items_by_floor, floor_number)
+   )
 
    for i in range(number_of_monsters):
        ...

...

def generate_dungeon(
    max_rooms: int,
    room_min_size: int,
    room_max_size: int,
    map_width: int,
    map_height: int,
-   max_monsters_per_room: int,
-   max_items_per_room: int,
    engine: Engine,
) -> GameMap:
    ...

            ...
            center_of_last_room = new_room.center
 
-       place_entities(new_room, dungeon, max_monsters_per_room, max_items_per_room)
+       place_entities(new_room, dungeon, engine.game_world.current_floor)
 
        dungeon.tiles[center_of_last_room] = tile_types.down_stairs
        dungeon.downstairs_location = center_of_last_room
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre><span class="crossed-out-text">def place_entities(</span>
    <span class="crossed-out-text">room: RectangularRoom, dungeon: GameMap, maximum_monsters: int, maximum_items: int</span>
<span class="crossed-out-text">) -> None:</span>
    <span class="crossed-out-text">number_of_monsters = random.randint(0, maximum_monsters)</span>
    <span class="crossed-out-text">number_of_items = random.randint(0, maximum_items)</span>
<span class="new-text">def place_entities(room: RectangularRoom, dungeon: GameMap, floor_number: int,) -> None:
    number_of_monsters = random.randint(
        0, get_max_value_for_floor(max_monsters_by_floor, floor_number)
    )
    number_of_items = random.randint(
        0, get_max_value_for_floor(max_items_by_floor, floor_number)
    )</span>
 
    for i in range(number_of_monsters):
        ...

...

def generate_dungeon(
    max_rooms: int,
    room_min_size: int,
    room_max_size: int,
    map_width: int,
    map_height: int,
    <span class="crossed-out-text">max_monsters_per_room: int,</span>
    <span class="crossed-out-text">max_items_per_room: int,</span>
    engine: Engine,
) -> GameMap:
    ...

            ...
            center_of_last_room = new_room.center
 
        <span class="crossed-out-text">place_entities(new_room, dungeon, max_monsters_per_room, max_items_per_room)</span>
        <span class="new-text">place_entities(new_room, dungeon, engine.game_world.current_floor)</span>
 
        dungeon.tiles[center_of_last_room] = tile_types.down_stairs
        dungeon.downstairs_location = center_of_last_room</pre>
{{</ original-tab >}}
{{</ codetab >}}

We can also remove `max_monsters_per_room` and `max_items_per_room` from `GameWorld`. Remove these lines from `game_map.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class GameWorld:
    """
    Holds the settings for the GameMap, and generates new maps when moving down the stairs.
    """

    def __init__(
        self,
        *,
        engine: Engine,
        map_width: int,
        map_height: int,
        max_rooms: int,
        room_min_size: int,
        room_max_size: int,
-       max_monsters_per_room: int,
-       max_items_per_room: int,
        current_floor: int = 0
    ):
        self.engine = engine

        self.map_width = map_width
        self.map_height = map_height

        self.max_rooms = max_rooms

        self.room_min_size = room_min_size
        self.room_max_size = room_max_size

-       self.max_monsters_per_room = max_monsters_per_room
-       self.max_items_per_room = max_items_per_room

        self.current_floor = current_floor

    def generate_floor(self) -> None:
        from procgen import generate_dungeon

        self.current_floor += 1

        self.engine.game_map = generate_dungeon(
            max_rooms=self.max_rooms,
            room_min_size=self.room_min_size,
            room_max_size=self.room_max_size,
            map_width=self.map_width,
            map_height=self.map_height,
-           max_monsters_per_room=self.max_monsters_per_room,
-           max_items_per_room=self.max_items_per_room,
            engine=self.engine,
        )
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class GameWorld:
    """
    Holds the settings for the GameMap, and generates new maps when moving down the stairs.
    """

    def __init__(
        self,
        *,
        engine: Engine,
        map_width: int,
        map_height: int,
        max_rooms: int,
        room_min_size: int,
        room_max_size: int,
        <span class="crossed-out-text">max_monsters_per_room: int,</span>
        <span class="crossed-out-text">max_items_per_room: int,</span>
        current_floor: int = 0
    ):
        self.engine = engine

        self.map_width = map_width
        self.map_height = map_height

        self.max_rooms = max_rooms

        self.room_min_size = room_min_size
        self.room_max_size = room_max_size

        <span class="crossed-out-text">self.max_monsters_per_room = max_monsters_per_room</span>
        <span class="crossed-out-text">self.max_items_per_room = max_items_per_room</span>

        self.current_floor = current_floor

    def generate_floor(self) -> None:
        from procgen import generate_dungeon

        self.current_floor += 1

        self.engine.game_map = generate_dungeon(
            max_rooms=self.max_rooms,
            room_min_size=self.room_min_size,
            room_max_size=self.room_max_size,
            map_width=self.map_width,
            map_height=self.map_height,
            <span class="crossed-out-text">max_monsters_per_room=self.max_monsters_per_room,</span>
            <span class="crossed-out-text">max_items_per_room=self.max_items_per_room,</span>
            engine=self.engine,
        )</pre>
{{</ original-tab >}}
{{</ codetab >}}

Also remove the same variables from `setup_game.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
def new_game() -> Engine:
    """Return a brand new game session as an Engine instance."""
    map_width = 80
    map_height = 43

    room_max_size = 10
    room_min_size = 6
    max_rooms = 30

-   max_monsters_per_room = 2
-   max_items_per_room = 2

    player = copy.deepcopy(entity_factories.player)

    engine = Engine(player=player)

    engine.game_world = GameWorld(
        engine=engine,
        max_rooms=max_rooms,
        room_min_size=room_min_size,
        room_max_size=room_max_size,
        map_width=map_width,
        map_height=map_height,
-       max_monsters_per_room=max_monsters_per_room,
-       max_items_per_room=max_items_per_room,
    )

    engine.game_world.generate_floor()
    engine.update_fov()

    engine.message_log.add_message(
        "Hello and welcome, adventurer, to yet another dungeon!", color.welcome_text
    )
    return engine
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>def new_game() -> Engine:
    """Return a brand new game session as an Engine instance."""
    map_width = 80
    map_height = 43

    room_max_size = 10
    room_min_size = 6
    max_rooms = 30

    <span class="crossed-out-text">max_monsters_per_room = 2</span>
    <span class="crossed-out-text">max_items_per_room = 2</span>

    player = copy.deepcopy(entity_factories.player)

    engine = Engine(player=player)

    engine.game_world = GameWorld(
        engine=engine,
        max_rooms=max_rooms,
        room_min_size=room_min_size,
        room_max_size=room_max_size,
        map_width=map_width,
        map_height=map_height,
        <span class="crossed-out-text">max_monsters_per_room=max_monsters_per_room,</span>
        <span class="crossed-out-text">max_items_per_room=max_items_per_room,</span>
    )

    engine.game_world.generate_floor()
    engine.update_fov()

    engine.message_log.add_message(
        "Hello and welcome, adventurer, to yet another dungeon!", color.welcome_text
    )
    return engine</pre>
{{</ original-tab >}}
{{</ codetab >}}

Now we're adjusting the number of items and monsters based on the floor. The next step is to control which entities appear on which floor, instead of allowing any entity to appear on any floor. The first floor will only have health potions and orcs, and we'll gradually add different items and enemies as the player goes deeper into the dungeon.

We need a function that allows us to get these entities at random, based on a set of weights. We also need to define the weights themselves.

What are "weights" in this context? Basically, we could define all of the odds of generating a type of entity the way we have already, by getting a random number and comparing against a set of values, but that will quickly become cumbersome as we add more entities. Imagine wanting to add a new enemy type, but needing to adjust the values for dozens, or perhaps __hundreds__, of other entities.

Instead, we'll just give each entity a value, or a "weight", which we'll use to determine how common that entity should be. We'll use Python's `random.choices` function, which allows the user to pass a list of items and a set of weights. It returns a number of items that you specify, based on the weights you give it.

First, we need to define our weights for the entity types, along with the minimum floor that the item or monster will appear on. Add the following to `procgen.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from __future__ import annotations
 
import random
-from typing import Iterator, List, Tuple, TYPE_CHECKING
+from typing import Dict, Iterator, List, Tuple, TYPE_CHECKING
 
import tcod

import entity_factories
from game_map import GameMap
import tile_types
 
if TYPE_CHECKING:
    from engine import Engine
+   from entity import Entity


max_items_by_floor = [
    (1, 1),
    (4, 2),
]

max_monsters_by_floor = [
    (1, 2),
    (4, 3),
    (6, 5),
]

+item_chances: Dict[int, List[Tuple[Entity, int]]] = {
+   0: [(entity_factories.health_potion, 35)],
+   2: [(entity_factories.confusion_scroll, 10)],
+   4: [(entity_factories.lightning_scroll, 25)],
+   6: [(entity_factories.fireball_scroll, 25)],
+}

+enemy_chances: Dict[int, List[Tuple[Entity, int]]] = {
+   0: [(entity_factories.orc, 80)],
+   3: [(entity_factories.troll, 15)],
+   5: [(entity_factories.troll, 30)],
+   7: [(entity_factories.troll, 60)],
+}


def get_max_value_for_floor(
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from __future__ import annotations
 
import random
<span class="crossed-out-text">from typing import Iterator, List, Tuple, TYPE_CHECKING</span>
<span class="new-text">from typing import Dict, Iterator, List, Tuple, TYPE_CHECKING</span>
 
import tcod

import entity_factories
from game_map import GameMap
import tile_types
 
if TYPE_CHECKING:
    from engine import Engine
    <span class="new-text">from entity import Entity</span>


max_items_by_floor = [
    (1, 1),
    (4, 2),
]

max_monsters_by_floor = [
    (1, 2),
    (4, 3),
    (6, 5),
]

<span class="new-text">item_chances: Dict[int, List[Tuple[Entity, int]]] = {
    0: [(entity_factories.health_potion, 35)],
    2: [(entity_factories.confusion_scroll, 10)],
    4: [(entity_factories.lightning_scroll, 25)],
    6: [(entity_factories.fireball_scroll, 25)],
}

enemy_chances: Dict[int, List[Tuple[Entity, int]]] = {
    0: [(entity_factories.orc, 80)],
    3: [(entity_factories.troll, 15)],
    5: [(entity_factories.troll, 30)],
    7: [(entity_factories.troll, 60)],
}</span>


def get_max_value_for_floor(
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

They keys in the dictionary represent the floor number, and the value is a list of tuples. The tuples contain an entity and the weights at which they'll be generated. Notice that Trolls get defined multiple times in `enemy_chances`, and their weights grow higher when the floor number increases. This will allow Trolls to be generated more frequently as the player dives into the dungeon, thus making the dungeon more dangerous with each passing floor.

Why a _list_ of tuples, though? While there isn't any examples here, we want it to be possible to define many entity types and weights for each floor. For example, imagine we added a new enemy type that appears on floor 5. We could put that as a tuple inside the list, alongside the Troll's tuple. We'll see an example of this in the next chapter, when we start adding equipment.

With our weights defined, we need a function to actually pick which entities we want to create. As mentioned, it will utilize `random.choices` from the Python standard library to choose the entities. Add this function to `procgen.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
def get_max_value_for_floor(
    weighted_chances_by_floor: List[Tuple[int, int]], floor: int
) -> int:
    ...


+def get_entities_at_random(
+   weighted_chances_by_floor: Dict[int, List[Tuple[Entity, int]]],
+   number_of_entities: int,
+   floor: int,
+) -> List[Entity]:
+   entity_weighted_chances = {}

+   for key, values in weighted_chances_by_floor.items():
+       if key > floor:
+           break
+       else:
+           for value in values:
+               entity = value[0]
+               weighted_chance = value[1]

+               entity_weighted_chances[entity] = weighted_chance

+   entities = list(entity_weighted_chances.keys())
+   entity_weighted_chance_values = list(entity_weighted_chances.values())

+   chosen_entities = random.choices(
+       entities, weights=entity_weighted_chance_values, k=number_of_entities
+   )

+   return chosen_entities


class RectangularRoom:
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>def get_max_value_for_floor(
    weighted_chances_by_floor: List[Tuple[int, int]], floor: int
) -> int:
    ...


<span class="new-text">def get_entities_at_random(
    weighted_chances_by_floor: Dict[int, List[Tuple[Entity, int]]],
    number_of_entities: int,
    floor: int,
) -> List[Entity]:
    entity_weighted_chances = {}

    for key, values in weighted_chances_by_floor.items():
        if key > floor:
            break
        else:
            for value in values:
                entity = value[0]
                weighted_chance = value[1]

                entity_weighted_chances[entity] = weighted_chance

    entities = list(entity_weighted_chances.keys())
    entity_weighted_chance_values = list(entity_weighted_chances.values())

    chosen_entities = random.choices(
        entities, weights=entity_weighted_chance_values, k=number_of_entities
    )

    return chosen_entities</span>


class RectangularRoom:
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

This function goes through they keys (floor numbers) and values (list of weighted entities), stopping when the key is higher than the given floor number. It sets up a dictionary of the weights for each entity, based on which floor the player is currently on. So if we were trying to get the weights for floor 6, `entity_weighted_chances` would look like this: `{ orc: 80, troll: 30 }`.

Then, we get both the keys and values in list format, so that they can be passed to `random.choices` (it accepts choices and weights as lists). `k` represents the number of items that `random.choices` should pick, so we can simply pass the number of entities we've decided to generate. Finally, we return the list of chosen entities.

Putting this function to use is quite simple. In fact, it will reduce the amount of code in our `place_entities` function quite nicely:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
def place_entities(room: RectangularRoom, dungeon: GameMap, floor_number: int,) -> None:
    number_of_monsters = random.randint(
        0, get_weight_for_floor(max_monsters_by_floor, floor_number)
    )
    number_of_items = random.randint(
        0, get_weight_for_floor(max_items_by_floor, floor_number)
    )
 
+   monsters: List[Entity] = get_entities_at_random(
+       enemy_chances, number_of_monsters, floor_number
+   )
+   items: List[Entity] = get_entities_at_random(
+       item_chances, number_of_items, floor_number
+   )

-   for i in range(number_of_monsters):
-       x = random.randint(room.x1 + 1, room.x2 - 1)
-       y = random.randint(room.y1 + 1, room.y2 - 1)
 
-       if not any(entity.x == x and entity.y == y for entity in dungeon.entities):
-           if random.random() < 0.8:
-               entity_factories.orc.spawn(dungeon, x, y)
-           else:
-               entity_factories.troll.spawn(dungeon, x, y)
 
-   for i in range(number_of_items):
+   for entity in monsters + items:
        x = random.randint(room.x1 + 1, room.x2 - 1)
        y = random.randint(room.y1 + 1, room.y2 - 1)
 
        if not any(entity.x == x and entity.y == y for entity in dungeon.entities):
-           item_chance = random.random()

-           if item_chance < 0.7:
-               entity_factories.health_potion.spawn(dungeon, x, y)
-           elif item_chance < 0.80:
-               entity_factories.fireball_scroll.spawn(dungeon, x, y)
-           elif item_chance < 0.90:
-               entity_factories.confusion_scroll.spawn(dungeon, x, y)
-           else:
-               entity_factories.lightning_scroll.spawn(dungeon, x, y)
+           entity.spawn(dungeon, x, y)

...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>def place_entities(room: RectangularRoom, dungeon: GameMap, floor_number: int,) -> None:
    number_of_monsters = random.randint(
        0, get_weight_for_floor(max_monsters_by_floor, floor_number)
    )
    number_of_items = random.randint(
        0, get_weight_for_floor(max_items_by_floor, floor_number)
    )

    <span class="new-text">monsters: List[Entity] = get_entities_at_random(
        enemy_chances, number_of_monsters, floor_number
    )
    items: List[Entity] = get_entities_at_random(
        item_chances, number_of_items, floor_number
    )</span>
 
    <span class="crossed-out-text">for i in range(number_of_monsters):</span>
        <span class="crossed-out-text">x = random.randint(room.x1 + 1, room.x2 - 1)</span>
        <span class="crossed-out-text">y = random.randint(room.y1 + 1, room.y2 - 1)</span>
 
        <span class="crossed-out-text">if not any(entity.x == x and entity.y == y for entity in dungeon.entities):</span>
            <span class="crossed-out-text">if random.random() < 0.8:</span>
                <span class="crossed-out-text">entity_factories.orc.spawn(dungeon, x, y)</span>
            <span class="crossed-out-text">else:</span>
                <span class="crossed-out-text">entity_factories.troll.spawn(dungeon, x, y)</span>

    <span class="crossed-out-text">for i in range(number_of_items):</span>
    <span class="new-text">for entity in monsters + items:</span>
        x = random.randint(room.x1 + 1, room.x2 - 1)
        y = random.randint(room.y1 + 1, room.y2 - 1)
 
        if not any(entity.x == x and entity.y == y for entity in dungeon.entities):
            <span class="crossed-out-text">item_chance = random.random()</span>

            <span class="crossed-out-text">if item_chance < 0.7:</span>
                <span class="crossed-out-text">entity_factories.health_potion.spawn(dungeon, x, y)</span>
            <span class="crossed-out-text">elif item_chance < 0.80:</span>
                <span class="crossed-out-text">entity_factories.fireball_scroll.spawn(dungeon, x, y)</span>
            <span class="crossed-out-text">elif item_chance < 0.90:</span>
                <span class="crossed-out-text">entity_factories.confusion_scroll.spawn(dungeon, x, y)</span>
            <span class="crossed-out-text">else:</span>
                <span class="crossed-out-text">entity_factories.lightning_scroll.spawn(dungeon, x, y)</span>
            <span class="new-text">entity.spawn(dungeon, x, y)</span>

...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Now `place_entities` is just getting the amount of monsters and items to generate, and leaving it up to `get_entities_at_random` to determine which ones to create.

With those changes, the dungeon will get progressively more difficult! You may want to tweak certain numbers, like the strength of the enemies or how much health you recover with potions, to get a more challenging experience (our game is still not _that_ difficult, if you increase your defense by just 1, Orcs are no longer a threat).

If you want to see the code so far in its entirety, [click here](https://github.com/TStand90/tcod_tutorial_v2/tree/part-12).

[Click here to move on to the next part of this tutorial.](/tutorials/tcod/v2/part-13)
