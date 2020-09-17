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


def place_entities(
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


def place_entities(
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

def place_entities(
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
    weighted_chances_by_floor: List[Tuple[int, int]], floor: int
) -> int:
    current_value = 0

    for floor_minimum, value in weighted_chances_by_floor:
        if floor_minimum > floor:
            break
        else:
            current_value = value

    return current_value</span>
    
def place_entities(
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
    ...

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
    ...

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

`procgen.py`

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


+max_items_by_floor = [
+   (1, 1),
+   (4, 2),
+]

+max_monsters_by_floor = [
+   (1, 2),
+   (4, 3),
+   (6, 5),
+]

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


+def get_weight_for_floor(
+   weighted_chances_by_floor: List[Tuple[int, int]], floor: int
+) -> int:
+   current_value = 0

+   for floor_minimum, value in weighted_chances_by_floor:
+       if floor_minimum > floor:
+           break
+       else:
+           current_value = value

+   return current_value


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
 
... 

-def place_entities(
-   room: RectangularRoom, dungeon: GameMap, maximum_monsters: int, maximum_items: int
-) -> None:
-   number_of_monsters = random.randint(0, maximum_monsters)
-   number_of_items = random.randint(0, maximum_items)
+def place_entities(room: RectangularRoom, dungeon: GameMap, floor_number: int,) -> None:
+   number_of_monsters = random.randint(
+       0, get_weight_for_floor(max_monsters_by_floor, floor_number)
+   )
+   number_of_items = random.randint(
+       0, get_weight_for_floor(max_items_by_floor, floor_number)
+   )
 
-   for i in range(number_of_monsters):
-       x = random.randint(room.x1 + 1, room.x2 - 1)
-       y = random.randint(room.y1 + 1, room.y2 - 1)
+   monsters: List[Entity] = get_entities_at_random(
+       enemy_chances, number_of_monsters, floor_number
+   )
+   items: List[Entity] = get_entities_at_random(
+       item_chances, number_of_items, floor_number
+   )
 
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


<span class="new-text">max_items_by_floor = [
    (1, 1),
    (4, 2),
]</span>

<span class="new-text">max_monsters_by_floor = [
    (1, 2),
    (4, 3),
    (6, 5),
]</span>

<span class="new-text">item_chances: Dict[int, List[Tuple[Entity, int]]] = {
    0: [(entity_factories.health_potion, 35)],
    2: [(entity_factories.confusion_scroll, 10)],
    4: [(entity_factories.lightning_scroll, 25)],
    6: [(entity_factories.fireball_scroll, 25)],
}</span>

<span class="new-text">enemy_chances: Dict[int, List[Tuple[Entity, int]]] = {
    0: [(entity_factories.orc, 80)],
    3: [(entity_factories.troll, 15)],
    5: [(entity_factories.troll, 30)],
    7: [(entity_factories.troll, 60)],
}</span>


<span class="new-text">def get_weight_for_floor(
    weighted_chances_by_floor: List[Tuple[int, int]], floor: int
) -> int:
    current_value = 0

    for floor_minimum, value in weighted_chances_by_floor:
        if floor_minimum > floor:
            break
        else:
            current_value = value

    return current_value</span>


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
 
... 

<span class="crossed-out-text">def place_entities(</span>
    <span class="crossed-out-text">room: RectangularRoom, dungeon: GameMap, maximum_monsters: int, maximum_items: int</span>
<span class="crossed-out-text">) -> None:</span>
    <span class="crossed-out-text">number_of_monsters = random.randint(0, maximum_monsters)</span>
    <span class="crossed-out-text">number_of_items = random.randint(0, maximum_items)</span>
<span class="new-text">def place_entities(room: RectangularRoom, dungeon: GameMap, floor_number: int,) -> None:
    number_of_monsters = random.randint(
        0, get_weight_for_floor(max_monsters_by_floor, floor_number)
    )
    number_of_items = random.randint(
        0, get_weight_for_floor(max_items_by_floor, floor_number)
    )</span>
 
    <span class="crossed-out-text">for i in range(number_of_monsters):</span>
        <span class="crossed-out-text">x = random.randint(room.x1 + 1, room.x2 - 1)</span>
        <span class="crossed-out-text">y = random.randint(room.y1 + 1, room.y2 - 1)</span>
    <span class="new-text">monsters: List[Entity] = get_entities_at_random(
        enemy_chances, number_of_monsters, floor_number
    )
    items: List[Entity] = get_entities_at_random(
        item_chances, number_of_items, floor_number
    )</span>
 
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