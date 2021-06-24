---
title: "Part 5 - Placing Enemies and kicking them (harmlessly)"
date: 2020-06-29
draft: false
---

What good is a dungeon with no monsters to bash? This chapter will focus on placing the enemies throughout the dungeon, and setting them up to be attacked (the actual attacking part we'll save for next time).

When we're building our dungeon, we'll need to place the enemies in the rooms. In order to do that, we will need to make a change to the way `entities` are stored in our game. Currently, they're saved in the `Engine` class. However, for the sake of placing enemies in the dungeon, and when we get to the part where we move between dungeon floors, it will be better to store them in the `GameMap` class. That way, the map has access to the entities directly, and we can preserve which entities are on which floors fairly easily.

Start by modifying `GameMap`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
+from __future__ import annotations

+from typing import Iterable, TYPE_CHECKING

import numpy as np  # type: ignore
from tcod.console import Console

import tile_types

+if TYPE_CHECKING:
+   from entity import Entity


class GameMap:
-   def __init__(self, width: int, height: int):
+   def __init__(self, width: int, height: int, entities: Iterable[Entity] = ()):
        self.width, self.height = width, height
+       self.entities = set(entities)
        self.tiles = np.full((width, height), fill_value=tile_types.wall, order="F")
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre><span class="new-text">from __future__ import annotations

from typing import Iterable, TYPE_CHECKING</span>

import numpy as np  # type: ignore
from tcod.console import Console

import tile_types

<span class="new-text">if TYPE_CHECKING:
    from entity import Entity</span>


class GameMap:
    <span class="crossed-out-text">def __init__(self, width: int, height: int):</span>
    <span class="new-text">def __init__(self, width: int, height: int, entities: Iterable[Entity] = ()):</span>
        self.width, self.height = width, height
        <span class="new-text">self.entities = set(entities)</span>
        self.tiles = np.full((width, height), fill_value=tile_types.wall, order="F")</pre>
{{</ original-tab >}}
{{</ codetab >}}

Then, let's modify `Engine` to remove the `entities` from it:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
-from typing import Set, Iterable, Any
+from typing import Iterable, Any


class Engine:
-   def __init__(self, entities: Set[Entity], event_handler: EventHandler, game_map: GameMap, player: Entity):
+   def __init__(self, event_handler: EventHandler, game_map: GameMap, player: Entity):
-       self.entities = entities
        self.event_handler = event_handler
        self.game_map = game_map
        self.player = player
        self.update_fov()
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre><span class="crossed-out-text">from typing import Set, Iterable, Any</span>
<span class="new-text">from typing import Iterable, Any</span>


class Engine:
    <span class="crossed-out-text">def __init__(self, entities: Set[Entity], event_handler: EventHandler, game_map: GameMap, player: Entity):</span>
    <span class="new-text">def __init__(self, event_handler: EventHandler, game_map: GameMap, player: Entity):</span>
        <span class="crossed-out-text">self.entities = entities</span>
        self.event_handler = event_handler
        self.game_map = game_map
        self.player = player
        self.update_fov()</pre>
{{</ original-tab >}}
{{</ codetab >}}

Because we've modified the definition of `Engine.__init__`, we need to modify `main.py` where we create our `game_map` variable. We might as well remove that `npc` as well, since we won't be needing it anymore.

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
    ...
    player = Entity(int(screen_width / 2), int(screen_height / 2), "@", (255, 255, 255))
-   npc = Entity(int(screen_width / 2 - 5), int(screen_height / 2), "@", (255, 255, 0))
-   entities = {npc, player}

    game_map = generate_dungeon(
        max_rooms=max_rooms,
        room_min_size=room_min_size,
        room_max_size=room_max_size,
        map_width=map_width,
        map_height=map_height,
        player=player,
    )

-   engine = Engine(entities=entities, event_handler=event_handler, game_map=game_map, player=player)
+   engine = Engine(event_handler=event_handler, game_map=game_map, player=player)

    with tcod.context.new_terminal(
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>    ...
    player = Entity(int(screen_width / 2), int(screen_height / 2), "@", (255, 255, 255))
    <span class="crossed-out-text">npc = Entity(int(screen_width / 2 - 5), int(screen_height / 2), "@", (255, 255, 0))</span>
    <span class="crossed-out-text">entities = {npc, player}</span>

    game_map = generate_dungeon(
        max_rooms=max_rooms,
        room_min_size=room_min_size,
        room_max_size=room_max_size,
        map_width=map_width,
        map_height=map_height,
        player=player,
    )

    <span class="crossed-out-text">engine = Engine(entities=entities, event_handler=event_handler, game_map=game_map, player=player)</span>
    <span class="new-text">engine = Engine(event_handler=event_handler, game_map=game_map, player=player)</span>

    with tcod.context.new_terminal(
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

We can remove the part in `Engine.render` that loops through the entities and renders the ones that are visible. That part will also be handled by the `GameMap` from now on.

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class Engine:
    ...

    def render(self, console: Console, context: Context) -> None:
        self.game_map.render(console)

-       for entity in self.entities:
-           # Only print entities that are in the FOV
-           if self.game_map.visible[entity.x, entity.y]:
-               console.print(entity.x, entity.y, entity.char, fg=entity.color)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class Engine:
    ...

    def render(self, console: Console, context: Context) -> None:
        self.game_map.render(console)

        <span class="crossed-out-text">for entity in self.entities:</span>
            <span class="crossed-out-text"># Only print entities that are in the FOV</span>
            <span class="crossed-out-text">if self.game_map.visible[entity.x, entity.y]:</span>
                <span class="crossed-out-text">console.print(entity.x, entity.y, entity.char, fg=entity.color)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

We can move this block into `GameMap.render`, though take note that the line that checks for visibility has a slight change: it goes from:

`if self.game_map.visible[entity.x, entity.y]:`

To:

`if self.visible[entity.x, entity.y]:`.

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class GameMap:
    ...

    def render(self, console: Console) -> None:
        """
        Renders the map.

        If a tile is in the "visible" array, then draw it with the "light" colors.
        If it isn't, but it's in the "explored" array, then draw it with the "dark" colors.
        Otherwise, the default is "SHROUD".
        """
        console.tiles_rgb[0:self.width, 0:self.height] = np.select(
            condlist=[self.visible, self.explored],
            choicelist=[self.tiles["light"], self.tiles["dark"]],
            default=tile_types.SHROUD
        )

+       for entity in self.entities:
+           # Only print entities that are in the FOV
+           if self.visible[entity.x, entity.y]:
+               console.print(x=entity.x, y=entity.y, string=entity.char, fg=entity.color)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class GameMap:
    ...

    def render(self, console: Console) -> None:
        """
        Renders the map.

        If a tile is in the "visible" array, then draw it with the "light" colors.
        If it isn't, but it's in the "explored" array, then draw it with the "dark" colors.
        Otherwise, the default is "SHROUD".
        """
        console.tiles_rgb[0:self.width, 0:self.height] = np.select(
            condlist=[self.visible, self.explored],
            choicelist=[self.tiles["light"], self.tiles["dark"]],
            default=tile_types.SHROUD
        )

        <span class="new-text">for entity in self.entities:
            # Only print entities that are in the FOV
            if self.visible[entity.x, entity.y]:
                console.print(x=entity.x, y=entity.y, string=entity.char, fg=entity.color)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Finally, we need to alter the part in `generate_dungeon` that creates the instance of `GameMap`, so that the `player` is passed into the `entities` argument.

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
def generate_dungeon(
    max_rooms: int,
    room_min_size: int,
    room_max_size: int,
    map_width: int,
    map_height: int,
    player: Entity,
) -> GameMap:
    """Generate a new dungeon map."""
-   dungeon = GameMap(map_width, map_height)
+   dungeon = GameMap(map_width, map_height, entities=[player])

    rooms: List[RectangularRoom] = []
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>def generate_dungeon(
    max_rooms: int,
    room_min_size: int,
    room_max_size: int,
    map_width: int,
    map_height: int,
    player: Entity,
) -> GameMap:
    """Generate a new dungeon map."""
    <span class="crossed-out-text">dungeon = GameMap(map_width, map_height)</span>
    <span class="new-text">dungeon = GameMap(map_width, map_height, entities=[player])</span>

    rooms: List[RectangularRoom] = []
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

If you run the project now, things should look the same as before, minus the NPC that we had earlier for testing.

Now, moving on to actually placing monsters in our dungeon. Our logic will be simple enough: For each room that's created in our dungeon, we'll place a random number of enemies, between 0 and a maximum (2 for now). We'll make it so that there's an 80% chance of spawning an Orc (a weaker enemy) and a 20% chance of it being a Troll (a stronger enemy).

In order to specify the maximum number of monsters that can be spawned into a room, let's create a new variable, `max_monsters_per_room`, and place it in `main.py`. We'll also modify our call to `generate_dungeon` to pass this new variable in.

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
    ...
    max_rooms = 30
    
+   max_monsters_per_room = 2

    tileset = tcod.tileset.load_tilesheet(
        "dejavu10x10_gs_tc.png", 32, 8, tcod.tileset.CHARMAP_TCOD
    )

    event_handler = EventHandler()

    player = Entity(int(screen_width / 2), int(screen_height / 2), "@", (255, 255, 255))

    game_map = generate_dungeon(
        max_rooms=max_rooms,
        room_min_size=room_min_size,
        room_max_size=room_max_size,
        map_width=map_width,
        map_height=map_height,
+       max_monsters_per_room=max_monsters_per_room,
        player=player
    )

    engine = Engine(event_handler=event_handler, game_map=game_map, player=player)
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>    ...
    max_rooms = 30
    
    <span class="new-text">max_monsters_per_room = 2</span>

    tileset = tcod.tileset.load_tilesheet(
        "dejavu10x10_gs_tc.png", 32, 8, tcod.tileset.CHARMAP_TCOD
    )

    event_handler = EventHandler()

    player = Entity(int(screen_width / 2), int(screen_height / 2), "@", (255, 255, 255))

    game_map = generate_dungeon(
        max_rooms=max_rooms,
        room_min_size=room_min_size,
        room_max_size=room_max_size,
        map_width=map_width,
        map_height=map_height,
        <span class="new-text">max_monsters_per_room=max_monsters_per_room,</span>
        player=player
    )

    engine = Engine(event_handler=event_handler, game_map=game_map, player=player)
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Pretty straightforward. Now we'll need to modify the definition of `generate_dungeon` to take this new variable, like this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
def generate_dungeon(
    max_rooms: int,
    room_min_size: int,
    room_max_size: int,
    map_width: int,
    map_height: int,
+   max_monsters_per_room: int,
    player: Entity,
) -> GameMap:
    """Generate a new dungeon map."""
    dungeon = GameMap(map_width, map_height, entities=[player])
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>def generate_dungeon(
    max_rooms: int,
    room_min_size: int,
    room_max_size: int,
    map_width: int,
    map_height: int,
    <span class="new-text">max_monsters_per_room: int,</span>
    player: Entity,
) -> GameMap:
    """Generate a new dungeon map."""
    dungeon = GameMap(map_width, map_height, entities=[player])</pre>
{{</ original-tab >}}
{{</ codetab >}}

Easy enough, but now how do we actually place the enemies?

After we've created our room, we'll want to call a function to put the entities in their places. Let's call the function `place_entities`, and it will take three arguments: The `RectangularRoom` that we've created, the `dungeon` so that it can add the entities to it (remember that `dungeon` is an instance of `GameMap`, which now holds entities), and the `max_monsters_per_room`, so that we know how many monsters to make.

While we haven't written the function yet, let's place our call to it in `generate_dungeon`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
            ...
                dungeon.tiles[x, y] = tile_types.floor

+       place_entities(new_room, dungeon, max_monsters_per_room)

        # Finally, append the new room to the list.
        rooms.append(new_room)
    
    return dungeon
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>            ...
                dungeon.tiles[x, y] = tile_types.floor

        <span class="new-text">place_entities(new_room, dungeon, max_monsters_per_room)</span>

        # Finally, append the new room to the list.
        rooms.append(new_room)
    
    return dungeon</pre>
{{</ original-tab >}}
{{</ codetab >}}

Now, let's write the `place_entities` function so that this actually works.

Our first version of `place_entities` won't actually place the entities. Why not? Because we'll need to do a few other things to make spawning the entities here work. However, we can at least fill in most of the function, and skip over the part that actually creates the entities for the moment.

Create the function like this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class RectangularRoom:
    ...


+def place_entities(
+   room: RectangularRoom, dungeon: GameMap, maximum_monsters: int,
+) -> None:
+   number_of_monsters = random.randint(0, maximum_monsters)

+   for i in range(number_of_monsters):
+       x = random.randint(room.x1 + 1, room.x2 - 1)
+       y = random.randint(room.y1 + 1, room.y2 - 1)

+       if not any(entity.x == x and entity.y == y for entity in dungeon.entities):
+           if random.random() < 0.8:
+               pass  # TODO: Place an Orc here
+           else:
+               pass  # TODO: Place a Troll here


def tunnel_between(
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class RectangularRoom:
    ...


<span class="new-text">def place_entities(
    room: RectangularRoom, dungeon: GameMap, maximum_monsters: int,
) -> None:
    number_of_monsters = random.randint(0, maximum_monsters)

    for i in range(number_of_monsters):
        x = random.randint(room.x1 + 1, room.x2 - 1)
        y = random.randint(room.y1 + 1, room.y2 - 1)

        if not any(entity.x == x and entity.y == y for entity in dungeon.entities):
            if random.random() < 0.8:
                pass  # TODO: Place an Orc here
            else:
                pass  # TODO: Place a Troll here</span>


def tunnel_between(
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}


The first line in the function takes a random number between 0 and the provided maximum (2, in this case). From there, it iterates from 0 to the number.

We select a random `x` and `y` to place the entity, and do a quick check to make sure there's no other entities in that location before dropping the enemy there. This is to ensure we don't get stacks of enemies.

As described earlier, there should be an 80% chance of there being an Orc, and 20% chance for a Troll. For now, we're using `pass` to skip over actually putting them down, because that requires a bit more work first.

There's a few ways we could go about creating the new entities. Assuming that every Orc and Troll we spawn will always have the same attributes as their brethren, we can create initial instances of `orc` and `troll`, then copy those every time we want to create a new one.

Why not just create the entities right here in the function? We could (the 1st version of this tutorial does, in fact), but that's a bit of a pain to go back and edit. Imagine if you had 100 enemies in your game at some point in the future. Would you rather search for those entity definitions in one file that *only* exists to define entities, or try finding it in the file that generates our dungeon? Not to mention, what happens if you want to create a new dungeon generator? Are you going to copy over the entity definitions and have them defined in two places?

Let's modify `Entity` to prepare for this new copying method. Modify `entity.py` like this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
+from __future__ import annotations

+import copy
-from typing import Tuple
+from typing import Tuple, TypeVar, TYPE_CHECKING

+if TYPE_CHECKING:
+   from game_map import GameMap

+T = TypeVar("T", bound="Entity")


class Entity:
    """
    A generic object to represent players, enemies, items, etc.
    """
-   def __init__(self, x: int, y: int, char: str, color: Tuple[int, int, int]):
+   def __init__(
+       self,
+       x: int = 0,
+       y: int = 0,
+       char: str = "?",
+       color: Tuple[int, int, int] = (255, 255, 255),
+       name: str = "<Unnamed>",
+       blocks_movement: bool = False,
+   ):
        self.x = x
        self.y = y
        self.char = char
        self.color = color
+       self.name = name
+       self.blocks_movement = blocks_movement

+   def spawn(self: T, gamemap: GameMap, x: int, y: int) -> T:
+       """Spawn a copy of this instance at the given location."""
+       clone = copy.deepcopy(self)
+       clone.x = x
+       clone.y = y
+       gamemap.entities.add(clone)
+       return clone

    def move(self, dx: int, dy: int) -> None:
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre><span class="new-text">from __future__ import annotations

import copy</span>
<span class="crossed-out-text">from typing import Tuple</span>
<span class="new-text">from typing import Tuple, TypeVar, TYPE_CHECKING

if TYPE_CHECKING:
    from game_map import GameMap

T = TypeVar("T", bound="Entity")</span>


class Entity:
    """
    A generic object to represent players, enemies, items, etc.
    """
    <span class="crossed-out-text">def __init__(self, x: int, y: int, char: str, color: Tuple[int, int, int]):</span>
    <span class="new-text">def __init__(
        self,
        x: int = 0,
        y: int = 0,
        char: str = "?",
        color: Tuple[int, int, int] = (255, 255, 255),
        name: str = "&lt;Unnamed&gt;",
        blocks_movement: bool = False,
    ):</span>
        self.x = x
        self.y = y
        self.char = char
        self.color = color
        <span class="new-text">self.name = name
        self.blocks_movement = blocks_movement</span>
    
    <span class="new-text">def spawn(self: T, gamemap: GameMap, x: int, y: int) -> T:
        """Spawn a copy of this instance at the given location."""
        clone = copy.deepcopy(self)
        clone.x = x
        clone.y = y
        gamemap.entities.add(clone)
        return clone</span>

    def move(self, dx: int, dy: int) -> None:
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

We've added two new attributes to `Entity`: `name` and `blocks_movement`. `name` is straightforward: it's what the Entity is called. `blocks_movement` describes whether or not this `Entity` can be moved over or not. Enemies will have `blocks_movement` set to `True`, while in the future, things like consumable items and equipment will be set to `False`.

Notice that we've also provided defaults for each of the attributes in the `__init__` function as well, whereas we were not before. This is because we'll soon not need to pass `x` and `y` during the initialization. More on that in a second.

The more complex section is the `spawn` method. It takes the `GameMap` instance, along with `x` and `y` for locations. It then creates a `clone` of the instance of `Entity`, and assigns the `x` and `y` variables to it (this is why we don't need `x` and `y` in the initializer anymore, they're set here). It then adds the entity to the `gamemap`'s entities, and returns the `clone`.

This new `spawn` method will probably make a lot more sense by putting it to use. To do that, let's create a new file, called `entity_factories.py`, and fill it with the following contents:

```py3
from entity import Entity

player = Entity(char="@", color=(255, 255, 255), name="Player", blocks_movement=True)

orc = Entity(char="o", color=(63, 127, 63), name="Orc", blocks_movement=True)
troll = Entity(char="T", color=(0, 127, 0), name="Troll", blocks_movement=True)
```

This is where we're defining our entities. `player` should look familiar, and `orc` and `troll` are not all that different, besides their characters and colors.

These are the instances we'll be cloning to create our new entities. Using these, we can at last fill in our `place_entities` function back in `procgen.py`.

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
...
import tcod

+import entity_factories
from game_map import GameMap
...

        ...
            if random.random() < 0.8:
-               pass  # TODO: Place an Orc here
+               entity_factories.orc.spawn(dungeon, x, y)
            else:
-               pass  # TODO: Place a Troll here
+               entity_factories.troll.spawn(dungeon, x, y)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>
...
import tcod

<span class="new-text">import entity_factories</span>
from game_map import GameMap
...

        ...
            if random.random() < 0.8:
                <span class="crossed-out-text">pass  # TODO: Place an Orc here</span>
                <span class="new-text">entity_factories.orc.spawn(dungeon, x, y)</span>
            else:
                <span class="crossed-out-text">pass  # TODO: Place a Troll here</span>
                <span class="new-text">entity_factories.troll.spawn(dungeon, x, y)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Let's also modify the way we create the `player`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
#!/usr/bin/env python3
+import copy

import tcod

from engine import Engine
-from entity import Entity
+import entity_factories
from input_handlers import EventHandler
from procgen import generate_dungeon
...

    ...
    event_handler = EventHandler()

-   player = Entity(int(screen_width / 2), int(screen_height / 2), "@", (255, 255, 255))
+   player = copy.deepcopy(entity_factories.player)

    game_map = generate_dungeon(
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>#!/usr/bin/env python3
<span class="new-text">import copy</span>

import tcod

from engine import Engine
<span class="crossed-out-text">from entity import Entity</span>
<span class="new-text">import entity_factories</span>
from input_handlers import EventHandler
from procgen import generate_dungeon
...

    ...
    event_handler = EventHandler()

    <span class="crossed-out-text">player = Entity(int(screen_width / 2), int(screen_height / 2), "@", (255, 255, 255))</span>
    <span class="new-text">player = copy.deepcopy(entity_factories.player)</span>

    game_map = generate_dungeon(
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

*Note: We can't use `player.spawn` here, because `spawn` requires the `GameMap`, which isn't created until after we create the player.*

With that, your dungeon should now be populated with enemies.

![Font File](/images/part-5-monsters.png)

They're... not exactly intimidating, are they? In fact, they don't really do much of anything right now. But that's okay, we'll work on that.

The first step towards making our monsters scarier is making them stand their ground... literally! The player can currently walk over (or under) the enemies by simply moving into the same space. Let's fix that, and ensure that when the player tries to move towards an enemy, we attack instead.

To begin, we need to determine if the space the player is trying to move into has an Entity in it. Not just any Entity, however: we'll check if the Entity has "blocks_movement" set to `True`. If it does, our player can't move there, and tries to attack instead.

Add the following to the map:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from __future__ import annotations

-from typing import Iterable, TYPE_CHECKING
+from typing import Iterable, Optional, TYPE_CHECKING

import numpy as np  # type: ignore
from tcod.console import Console

import tile_types

if TYPE_CHECKING:
    from entity import Entity


class GameMap:
    def __init__(self, width: int, height: int, entities: Iterable[Entity] = ()):
        self.width, self.height = width, height
        self.entities = set(entities)
        self.tiles = np.full((width, height), fill_value=tile_types.wall, order="F")

        self.visible = np.full((width, height), fill_value=False, order="F")  # Tiles the player can currently see
        self.explored = np.full((width, height), fill_value=False, order="F")  # Tiles the player has seen before

+   def get_blocking_entity_at_location(self, location_x: int, location_y: int) -> Optional[Entity]:
+       for entity in self.entities:
+           if entity.blocks_movement and entity.x == location_x and entity.y == location_y:
+               return entity

+       return None

    def in_bounds(self, x: int, y: int) -> bool:
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from __future__ import annotations

<span class="crossed-out-text">from typing import Iterable, TYPE_CHECKING</span>
<span class="new-text">from typing import Iterable, Optional, TYPE_CHECKING</span>

import numpy as np  # type: ignore
from tcod.console import Console

import tile_types

if TYPE_CHECKING:
    from entity import Entity


class GameMap:
    def __init__(self, width: int, height: int, entities: Iterable[Entity] = ()):
        self.width, self.height = width, height
        self.entities = set(entities)
        self.tiles = np.full((width, height), fill_value=tile_types.wall, order="F")

        self.visible = np.full((width, height), fill_value=False, order="F")  # Tiles the player can currently see
        self.explored = np.full((width, height), fill_value=False, order="F")  # Tiles the player has seen before

    <span class="new-text">def get_blocking_entity_at_location(self, location_x: int, location_y: int) -> Optional[Entity]:
        for entity in self.entities:
            if entity.blocks_movement and entity.x == location_x and entity.y == location_y:
                return entity

        return None</span>

    def in_bounds(self, x: int, y: int) -> bool:
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

This new function iterates through all the `entities`, and if one is found that both blocks movement and occupies the given `location_x` and `location_y` coordinates, it returns that Entity. Otherwise, we return `None` instead.

Where can we check if a tile is occupied or not? And what do we do if it is?

One way to handle all this is to modify our "actions" a bit. Our current `MovementAction` doesn't take into account what occupies the tile we're moving into. That's fine, it doesn't necessarily need to, but there probably should be an action that does. What if we created an `Action` subclass that could tell what was in the tile, and call either `MovementAction` if it was empty, or some other "attack" action if it wasn't?

Let's do a few things. We'll start by defining a new class, called `ActionWithDirection`, which will actually become the new superclass for `MovementAction`. This new class will take the initializer from `MovementAction`, but won't implement its own `perform` method. It looks like this:


{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
...
class EscapeAction(Action):
    def perform(self, engine: Engine, entity: Entity) -> None:
        raise SystemExit()


+class ActionWithDirection(Action):
+   def __init__(self, dx: int, dy: int):
+       super().__init__()

+       self.dx = dx
+       self.dy = dy
    
+   def perform(self, engine: Engine, entity: Entity) -> None:
+       raise NotImplementedError()


-class MovementAction(Action):
+class MovementAction(ActionWithDirection):
-   def __init__(self, dx: int, dy: int):
-       super().__init__()

-       self.dx = dx
-       self.dy = dy

    def perform(self, engine: Engine, entity: Entity) -> None:
        dest_x = entity.x + self.dx
        dest_y = entity.y + self.dy

        if not engine.game_map.in_bounds(dest_x, dest_y):
            return  # Destination is out of bounds.
        if not engine.game_map.tiles["walkable"][dest_x, dest_y]:
            return  # Destination is blocked by a tile.
+       if engine.game_map.get_blocking_entity_at_location(dest_x, dest_y):
+           return  # Destination is blocked by an entity.

        entity.move(self.dx, self.dy)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>...
class EscapeAction(Action):
    def perform(self, engine: Engine, entity: Entity) -> None:
        raise SystemExit()


<span class="new-text">class ActionWithDirection(Action):
    def __init__(self, dx: int, dy: int):
        super().__init__()

        self.dx = dx
        self.dy = dy
    
    def perform(self, engine: Engine, entity: Entity) -> None:
        raise NotImplementedError()</span>


<span class="crossed-out-text">class MovementAction(Action):</span>
<span class="new-text">class MovementAction(ActionWithDirection):</span>
    <span class="crossed-out-text">def __init__(self, dx: int, dy: int):</span>
        <span class="crossed-out-text">super().__init__()</span>

        <span class="crossed-out-text">self.dx = dx</span>
        <span class="crossed-out-text">self.dy = dy</span>

    def perform(self, engine: Engine, entity: Entity) -> None:
        dest_x = entity.x + self.dx
        dest_y = entity.y + self.dy

        if not engine.game_map.in_bounds(dest_x, dest_y):
            return  # Destination is out of bounds.
        if not engine.game_map.tiles["walkable"][dest_x, dest_y]:
            return  # Destination is blocked by a tile.
        <span class="new-text">if engine.game_map.get_blocking_entity_at_location(dest_x, dest_y):
            return  # Destination is blocked by an entity.</span>

        entity.move(self.dx, self.dy)</pre>
{{</ original-tab >}}
{{</ codetab >}}

Notice that we've added an extra check in `MovementAction` to ensure we're not moving into a space with a blocking entity. Theoretically, this bit of code won't ever trigger, but it's nice to have it there as a safeguard.

But wait, `MovementAction` still doesn't do anything differently. So what's the point? Well, now we can use the new `ActionWithDirection` class to define two more subclasses, which will do what we want.

The first one will be the action we use to actually attack. It looks like this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class ActionWithDirection(Action):
    def __init__(self, dx: int, dy: int):
        super().__init__()

        self.dx = dx
        self.dy = dy
    
    def perform(self, engine: Engine, entity: Entity) -> None:
        raise NotImplementedError()


+class MeleeAction(ActionWithDirection):
+   def perform(self, engine: Engine, entity: Entity) -> None:
+       dest_x = entity.x + self.dx
+       dest_y = entity.y + self.dy
+       target = engine.game_map.get_blocking_entity_at_location(dest_x, dest_y)
+       if not target:
+           return  # No entity to attack.

+       print(f"You kick the {target.name}, much to its annoyance!")


class MovementAction(ActionWithDirection):
    def perform(self, engine: Engine, entity: Entity) -> None:
        dest_x = entity.x + self.dx
        dest_y = entity.y + self.dy

        if not engine.game_map.in_bounds(dest_x, dest_y):
            return  # Destination is out of bounds.
        if not engine.game_map.tiles["walkable"][dest_x, dest_y]:
            return  # Destination is blocked by a tile.
        if engine.game_map.get_blocking_entity_at_location(dest_x, dest_y)
            return  # Destination is blocked by an entity.

        entity.move(self.dx, self.dy)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class ActionWithDirection(Action):
    def __init__(self, dx: int, dy: int):
        super().__init__()

        self.dx = dx
        self.dy = dy
    
    def perform(self, engine: Engine, entity: Entity) -> None:
        raise NotImplementedError()


<span class="new-text">class MeleeAction(ActionWithDirection):
    def perform(self, engine: Engine, entity: Entity) -> None:
        dest_x = entity.x + self.dx
        dest_y = entity.y + self.dy
        target = engine.game_map.get_blocking_entity_at_location(dest_x, dest_y)
        if not target:
            return  # No entity to attack.

        print(f"You kick the {target.name}, much to its annoyance!")</span>


class MovementAction(ActionWithDirection):
    def perform(self, engine: Engine, entity: Entity) -> None:
        dest_x = entity.x + self.dx
        dest_y = entity.y + self.dy

        if not engine.game_map.in_bounds(dest_x, dest_y):
            return  # Destination is out of bounds.
        if not engine.game_map.tiles["walkable"][dest_x, dest_y]:
            return  # Destination is blocked by a tile.
        if engine.game_map.get_blocking_entity_at_location(dest_x, dest_y):
            return  # Destination is blocked by an entity.

        entity.move(self.dx, self.dy)</pre>
{{</ original-tab >}}
{{</ codetab >}}

Just like `MovementAction`, `MeleeAction` inherits from `ActionWithDirection`. The `perform` method it implements is what we'll use to attack... eventually. Right now, we're just printing out a little message. The actual attacking will have to wait until the next part (this one is getting long as it is).

Still, we're not actually *using* `MeleeAction` anywhere, yet. Let's add one more class, which is what will make the determination on whether our player is moving or attacking:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class MovementAction(ActionWithDirection):
    def perform(self, engine: Engine, entity: Entity) -> None:
        dest_x = entity.x + self.dx
        dest_y = entity.y + self.dy

        if not engine.game_map.in_bounds(dest_x, dest_y):
            return  # Destination is out of bounds.
        if not engine.game_map.tiles["walkable"][dest_x, dest_y]:
            return  # Destination is blocked by a tile.
        if engine.game_map.get_blocking_entity_at_location(dest_x, dest_y):
            return  # Destination is blocked by an entity.

        entity.move(self.dx, self.dy)


+class BumpAction(ActionWithDirection):
+   def perform(self, engine: Engine, entity: Entity) -> None:
+       dest_x = entity.x + self.dx
+       dest_y = entity.y + self.dy

+       if engine.game_map.get_blocking_entity_at_location(dest_x, dest_y):
+           return MeleeAction(self.dx, self.dy).perform(engine, entity)

+       else:
+           return MovementAction(self.dx, self.dy).perform(engine, entity)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class MovementAction(ActionWithDirection):
    def perform(self, engine: Engine, entity: Entity) -> None:
        dest_x = entity.x + self.dx
        dest_y = entity.y + self.dy

        if not engine.game_map.in_bounds(dest_x, dest_y):
            return  # Destination is out of bounds.
        if not engine.game_map.tiles["walkable"][dest_x, dest_y]:
            return  # Destination is blocked by a tile.
        if engine.game_map.get_blocking_entity_at_location(dest_x, dest_y):
            return  # Destination is blocked by an entity.

        entity.move(self.dx, self.dy)


<span class="new-text">class BumpAction(ActionWithDirection):
    def perform(self, engine: Engine, entity: Entity) -> None:
        dest_x = entity.x + self.dx
        dest_y = entity.y + self.dy

        if engine.game_map.get_blocking_entity_at_location(dest_x, dest_y):
            return MeleeAction(self.dx, self.dy).perform(engine, entity)

        else:
            return MovementAction(self.dx, self.dy).perform(engine, entity)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

This class also inherits from `ActionWithDirection`, but its `perform` method doesn't actually perform anything, except deciding which class, between `MeleeAction` and `MovementAction` to return. Those classes are what are actually doing the work. `BumpAction` just determines which one is appropriate to call, based on whether there is a blocking entity at the given destination or not. Notice we're using the function we defined earlier in our map to decide if there's a valid target or not.

Now that our new actions are in place, we need to modify our `input_handlers.py` file to use `BumpAction` instead of `MovementAction`. It's a pretty simple change:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from typing import Optional

import tcod.event

-from actions import Action, EscapeAction, MovementAction
+from actions import Action, BumpAction, EscapeAction


class EventHandler(tcod.event.EventDispatch[Action]):
    def ev_quit(self, event: tcod.event.Quit) -> Optional[Action]:
        raise SystemExit()

    def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[Action]:
        action: Optional[Action] = None

        key = event.sym

        if key == tcod.event.K_UP:
-           action = MovementAction(dx=0, dy=-1)
+           action = BumpAction(dx=0, dy=-1)
        elif key == tcod.event.K_DOWN:
-           action = MovementAction(dx=0, dy=1)
+           action = BumpAction(dx=0, dy=1)
        elif key == tcod.event.K_LEFT:
-           action = MovementAction(dx=-1, dy=0)
+           action = BumpAction(dx=-1, dy=0)
        elif key == tcod.event.K_RIGHT:
-           action = MovementAction(dx=1, dy=0)
+           action = BumpAction(dx=1, dy=0)

        elif key == tcod.event.K_ESCAPE:
            action = EscapeAction()

        # No valid key was pressed
        return action
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from typing import Optional

import tcod.event

<span class="crossed-out-text">from actions import Action, EscapeAction, MovementAction</span>
<span class="new-text">from actions import Action, BumpAction, EscapeAction</span>


class EventHandler(tcod.event.EventDispatch[Action]):
    def ev_quit(self, event: tcod.event.Quit) -> Optional[Action]:
        raise SystemExit()

    def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[Action]:
        action: Optional[Action] = None

        key = event.sym

        if key == tcod.event.K_UP:
            <span class="crossed-out-text">action = MovementAction(dx=0, dy=-1)</span>
            <span class="new-text">action = BumpAction(dx=0, dy=-1)</span>
        elif key == tcod.event.K_DOWN:
            <span class="crossed-out-text">action = MovementAction(dx=0, dy=1)</span>
            <span class="new-text">action = BumpAction(dx=0, dy=1)</span>
        elif key == tcod.event.K_LEFT:
            <span class="crossed-out-text">action = MovementAction(dx=-1, dy=0)</span>
            <span class="new-text">action = BumpAction(dx=-1, dy=0)</span>
        elif key == tcod.event.K_RIGHT:
            <span class="crossed-out-text">action = MovementAction(dx=1, dy=0)</span>
            <span class="new-text">action = BumpAction(dx=1, dy=0)</span>

        elif key == tcod.event.K_ESCAPE:
            action = EscapeAction()

        # No valid key was pressed
        return action</pre>
{{</ original-tab >}}
{{</ codetab >}}

Run the project now. At this point, you shouldn't be able to move over the enemies, and you should get a message in the terminal, indicating that you're attacking the enemy (albeit not for any damage).

Before we wrap this part up, let's set ourselves up to allow for enemy turns as well. They won't actually be doing anything at the moment, we'll just get a message in the terminal that indicates something is happening.

Add these small modifications to `engine.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class Engine:
    def __init__(self, event_handler: EventHandler, game_map: GameMap, player: Entity):
        self.event_handler = event_handler
        self.game_map = game_map
        self.player = player
        self.update_fov()

+   def handle_enemy_turns(self) -> None:
+       for entity in self.game_map.entities - {self.player}:
+           print(f'The {entity.name} wonders when it will get to take a real turn.')

    def handle_events(self, events: Iterable[Any]) -> None:
        for event in events:
            action = self.event_handler.dispatch(event)

            if action is None:
                continue

            action.perform(self, self.player)
+           self.handle_enemy_turns()
            self.update_fov()  # Update the FOV before the players next action.
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class Engine:
    def __init__(self, event_handler: EventHandler, game_map: GameMap, player: Entity):
        self.event_handler = event_handler
        self.game_map = game_map
        self.player = player
        self.update_fov()

    <span class="new-text">def handle_enemy_turns(self) -> None:
        for entity in self.game_map.entities - {self.player}:
            print(f'The {entity.name} wonders when it will get to take a real turn.')</span>

    def handle_events(self, events: Iterable[Any]) -> None:
        for event in events:
            action = self.event_handler.dispatch(event)

            if action is None:
                continue

            action.perform(self, self.player)
            <span class="new-text">self.handle_enemy_turns()</span>
            self.update_fov()  # Update the FOV before the players next action.</pre>
{{</ original-tab >}}
{{</ codetab >}}

The `handle_enemy_turns` function loops through each entity (minus the player) and prints out a message for them. In the next part, we'll replace this with some code that will allow those entities to take real turns.

We call `handle_enemy_turns` right after `action.perform`, so that the enemies move right after the player. Other roguelike games have more complex timing mechanisms for when entities take their turns, but our tutorial will stick with probably the simplest method of all: the player moves, then all the enemies move.

That's all for this chapter. Next time, we'll look at moving the enemies around on their turns, and doing some real damage to both the enemies and the player.

If you want to see the code so far in its entirety, [click
here](https://github.com/TStand90/tcod_tutorial_v2/tree/2020/part-5).

[Click here to move on to the next part of this
tutorial.](/tutorials/tcod/v2/part-6)
