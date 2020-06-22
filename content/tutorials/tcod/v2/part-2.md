---
title: "Part 2"
date: 2020-06-15T10:20:13-07:00
draft: true
---

Now that we can move our little '@' symbol around, we need to give it
something to move around *in*. But before that, let's stop for a moment
and think about the player object itself.

Right now, we just represent the player with the '@' symbol, and its x
and y coordinates. Shouldn't we tie those things together in an object,
along with some other data and functions that pertain to it?

Let's create a generic class to represent not just the player, but just
about *everything* in our game world. Enemies, items, and whatever other
foreign entities we can dream of will be part of this class, which we'll
call `Entity`.

Create a new file, and call it `entity.py`. In that file, put the
following class:

{{< highlight py3 >}}
from typing import Tuple


class Entity:
    """
    A generic object to represent players, enemies, items, etc.
    """
    def __init__(self, x: int, y: int, char: str, color: Tuple[int, int, int]):
        self.x = x
        self.y = y
        self.char = char
        self.color = color

    def move(self, dx: int, dy: int):
        # Move the entity by a given amount
        self.x += dx
        self.y += dy
{{</ highlight >}}

The initializer (`__init__`) takes four arguments: `x`, `y`, `char`, and `color`.
* `x` and `y` are pretty self explanatory: They represent the Entity's "x" and "y" coordinates on the map.
* `char` is the character we'll use to represent the entity. Our player will be an "@" symbol, whereas something like a Troll (coming in a later chapter) can be the letter "T".
* `color` is the color we'll use when drawing the Entity. We define `color` as a Tuple of three integers, representing the entity's RGB values.

The other method is `move`, which takes `dx` and `dy` as arguments, and uses them to modify the Entity's position. This should look familiar to what we did in the last chapter.

Let's put our fancy new class into action\! Modify the first part of
`main.py` to look like this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
#!/usr/bin/env python3
import tcod

from actions import EscapeAction, MovementAction
+from entity import Entity
from input_handlers import EventHandler


def main() -> None:
    screen_width = 80
    screen_height = 50

-   player_x = int(screen_width / 2)
-   player_y = int(screen_height / 2)

+   player = Entity(int(screen_width / 2), int(screen_height / 2), "@", (255, 255, 255))
+   npc = Entity(int(screen_width / 2 - 5), int(screen_height / 2), "@", (255, 255, 0))
+   entities = [npc, player]

    tileset = tcod.tileset.load_tilesheet(
        "dejavu10x10_gs_tc.png", 32, 8, tcod.tileset.CHARMAP_TCOD
    )
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>#!/usr/bin/env python3
import tcod

from actions import EscapeAction, MovementAction
<span class="new-text">from entity import Entity</span>
from input_handlers import EventHandler


def main() -> None:
    screen_width = 80
    screen_height = 50

    <span class="crossed-out-text">player_x = int(screen_width / 2)</span>
    <span class="crossed-out-text">player_y = int(screen_height / 2)</span>

    <span class="new-text">player = Entity(int(screen_width / 2), int(screen_height / 2), "@", (255, 255, 255))
    npc = Entity(int(screen_width / 2 - 5), int(screen_height / 2), "@", (255, 255, 0))
    entities = [npc, player]</span>
    
    tileset = tcod.tileset.load_tilesheet(
        "dejavu10x10_gs_tc.png", 32, 8, tcod.tileset.CHARMAP_TCOD
    )
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

We're importing the `Entity` class into `main.py`, and using it to
initialize the player and a new NPC. We store these two in a list, that
will eventually hold all our entities on the map.

Also modify the part where we handle movement so that the Entity class
handles the actual movement.


{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
                if isinstance(action, MovementAction):
-                   player_x += action.dx
-                   player_y += action.dy
+                   player.move(dx=action.dx, dy=action.dy)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>                if isinstance(action, MovementAction):
                    <span class="crossed-out-text">player_x += action.dx</span>
                    <span class="crossed-out-text">player_y += action.dy</span>
                    <span class="new-text">player.move(dx=action.dx, dy=action.dy)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Lastly, update the drawing functions to use the new player object:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
        while True:
-           root_console.print(x=player_x, y=player_y, string="@")
+           root_console.print(x=player.x, y=player.y, string=player.char, fg=player.color)

            context.present(root_console)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>        while True:
            <span class="crossed-out-text">root_console.print(x=player_x, y=player_y, string="@")</span>
            <span class="new-text">root_console.print(x=player.x, y=player.y, string=player.char, fg=player.color)</span>

            context.present(root_console)</pre>
{{</ original-tab >}}
{{</ codetab >}}

If you run the project now, only the player gets drawn. We'll need to modify things to draw both entities, and eventually, draw the map we're going to create as well.

Before doing that, it's worth stopping and taking a moment to think about our overall design. Currently, our `main.py` file is responsible for:

* Setting up the initial variables, like screen size and the tileset.
* Creating the entities
* Drawing the screen and everything on it.
* Reacting to the player's input.

Soon, we're going to need to add a map as well. It's starting to become a bit much.

One thing we can do is pass of some of these responsibilities to another class, which will be responsible for "running" our game. The `main.py` file can still set things up and tell that new class what to do, but this design should help keep the `main.py` file from getting too large over time.

Let's create an `Engine` class, which will take the responsibilities of drawing the map and entities, as well as handling the player's input.


```py3
from typing import List, Iterable, Any

from tcod.context import Context
from tcod.console import Console

from actions import EscapeAction, MovementAction
from entity import Entity
from input_handlers import EventHandler


class Engine:
    def __init__(self, entities: List[Entity], event_handler: EventHandler, player: Entity):
        self.entities = entities
        self.event_handler = event_handler
        self.player = player

    def handle_events(self, events: Iterable[Any]) -> None:
        for event in events:
            action = self.event_handler.dispatch(event)

            if action is None:
                continue

            if isinstance(action, MovementAction):
                self.player.move(dx=action.dx, dy=action.dy)

            elif isinstance(action, EscapeAction):
                raise SystemExit()

    def render(self, console: Console, context: Context) -> None:
        for entity in self.entities:
            entity.render(console)

        context.present(console)

        console.clear()
```

// TODO: Explain the new Engine class


Notice that we've called `entity.render`, which we haven't yet written. Let's modify the `Entity` class to give it a `render` method.

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from typing import Tuple

+from tcod.console import Console


class Entity:
    """
    A generic object to represent players, enemies, items, etc.
    """
    def __init__(self, x: int, y: int, char: str, color: Tuple[int, int, int]):
        self.x = x
        self.y = y
        self.char = char
        self.color = color

    def move(self, dx: int, dy: int) -> None:
        # Move the entity by a given amount
        self.x += dx
        self.y += dy
    
+   def render(self, console: Console):
+       console.print(x=self.x, y=self.y, string=self.char, fg=self.color)

{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from typing import Tuple

<span class="new-text">from tcod.console import Console</span>


class Entity:
    """
    A generic object to represent players, enemies, items, etc.
    """
    def __init__(self, x: int, y: int, char: str, color: Tuple[int, int, int]):
        self.x = x
        self.y = y
        self.char = char
        self.color = color

    def move(self, dx: int, dy: int) -> None:
        # Move the entity by a given amount
        self.x += dx
        self.y += dy
    
    <span class="new-text">def render(self, console: Console):
        console.print(x=self.x, y=self.y, string=self.char, fg=self.color)</span>
</pre>
{{</ original-tab >}}
{{</ codetab >}}

To make use of our new `Engine` class, we'll need to modify `main.py` quite a bit.


{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
#!/usr/bin/env python3
import tcod

+from engine import Engine
from entity import Entity
from input_handlers import EventHandler


def main() -> None:
    screen_width = 80
    screen_height = 50

    tileset = tcod.tileset.load_tilesheet(
        "dejavu10x10_gs_tc.png", 32, 8, tcod.tileset.CHARMAP_TCOD
    )

    event_handler = EventHandler()

    player = Entity(int(screen_width / 2), int(screen_height / 2), "@", (255, 255, 255))
    npc = Entity(int(screen_width / 2 - 5), int(screen_height / 2), "@", (255, 255, 0))
    entities = [npc, player]

+   engine = Engine(entities=entities, event_handler=event_handler, player=player)

    with tcod.context.new_terminal(
        screen_width,
        screen_height,
        tileset=tileset,
        title="Yet Another Roguelike Tutorial",
        vsync=True,
    ) as context:
        root_console = tcod.Console(screen_width, screen_height, order="F")
        while True:
-           root_console.print(x=player_x, y=player_y, string="@")
+           engine.render(console=root_console, context=context)

+           events = tcod.event.wait()

+           engine.handle_events(events)
-           root_console.clear()

-           for event in tcod.event.wait():
-               action = event_handler.dispatch(event)

-               if action is None:
-                   continue

-               if isinstance(action, MovementAction):
-                   player_x += action.dx
-                   player_y += action.dy

-               elif isinstance(action, EscapeAction):
-                   raise SystemExit()


if __name__ == "__main__":
    main()
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>#!/usr/bin/env python3
import tcod

<span class="new-text">from engine import Engine</span>
from entity import Entity
from input_handlers import EventHandler


def main() -> None:
    screen_width = 80
    screen_height = 50

    tileset = tcod.tileset.load_tilesheet(
        "dejavu10x10_gs_tc.png", 32, 8, tcod.tileset.CHARMAP_TCOD
    )

    event_handler = EventHandler()

    player = Entity(int(screen_width / 2), int(screen_height / 2), "@", (255, 255, 255))
    npc = Entity(int(screen_width / 2 - 5), int(screen_height / 2), "@", (255, 255, 0))
    entities = [npc, player]

    <span class="new-text">engine = Engine(entities=entities, event_handler=event_handler, player=player)</span>

    with tcod.context.new_terminal(
        screen_width,
        screen_height,
        tileset=tileset,
        title="Yet Another Roguelike Tutorial",
        vsync=True,
    ) as context:
        root_console = tcod.Console(screen_width, screen_height, order="F")
        while True:
            <span class="crossed-out-text">root_console.print(x=player_x, y=player_y, string="@")</span>
            <span class="new-text">engine.render(console=root_console, context=context)</span>

            events = tcod.event.wait()

            <span class="new-text">engine.handle_events(events)</span>


if __name__ == "__main__":
    main()</pre>
{{</ original-tab >}}
{{</ codetab >}}

Because we've moved the rendering and event handling code to the `Engine` class, we no longer need it in `main.py`. All we need to do is create the `Engine` instance, pass the needed variables to it, and use the methods we wrote for it.

Our `main.py` file is looking a lot smaller and simpler, and we've rendered both the player and the NPC to the screen. To wrap up this chapter, we'll start writing our game's map, though generating a dungeon with it will be the focus of the next chapter.

We can represent the map with a new class, called `GameMap`. The map itself will be made up of tiles, which will contain certain data about if the tile is "walkable" (True if it's a floor, False if its a wall), "transparency" (again, True for floors, False for walls), and how to render the tile to the screen.


// TODO: Explain the tiles, numpy, etc.

```py3
from typing import Tuple

import numpy as np  # type: ignore

# Tile graphics structured type compatible with Console.tiles_rgb.
graphic_dt = np.dtype(
    [
        ("ch", np.int32),  # Unicode codepoint.
        ("fg", "3B"),  # 3 unsigned bytes, for RGB colors.
        ("bg", "3B"),
    ]
)

# Tile struct used for statically defined tile data.
tile_dt = np.dtype(
    [
        ("walkable", np.bool),  # True if this tile can be walked over.
        ("transparent", np.bool),  # True if this tile doesn't block FOV.
        ("dark", graphic_dt),  # Graphics for when this tile is not in FOV.
    ]
)


def new_tile(
    *,  # Enforce the use of keywords, so that parameter order doesn't matter.
    walkable: int,
    transparent: int,
    dark: Tuple[int, Tuple[int, int, int], Tuple[int, int, int]],
) -> np.ndarray:
    """Helper function for defining individual tile types """
    return np.array((walkable, transparent, dark), dtype=tile_dt)


floor = new_tile(
    walkable=True, transparent=True, dark=(ord(" "), (255, 255, 255), (50, 50, 150)),
)
wall = new_tile(
    walkable=False, transparent=False, dark=(ord(" "), (255, 255, 255), (0, 0, 100)),
)
```

// TODO: Explain the tiles code

Now let's use our newly created tiles by creating our map class. Create a file called `game_map.py` and fill it with the following:

```py3
import numpy as np  # type: ignore
from tcod.console import Console

import tile_types


class GameMap:
    def __init__(self, width: int, height: int):
        self.width, self.height = width, height
        self.tiles = np.full((width, height), fill_value=tile_types.floor, order="F")

        self.tiles[30:33, 22] = tile_types.wall

    def render(self, console: Console) -> None:
        console.tiles_rgb[0:self.width, 0:self.height] = self.tiles["dark"]
```

// TODO: Explain the GameMap class



// TODO: Explain the modifications to main.py here

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
#!/usr/bin/env python3
import tcod

from engine import Engine
from entity import Entity
+from game_map import GameMap
from input_handlers import EventHandler


def main() -> None:
    screen_width = 80
    screen_height = 50

+   map_width = 80
+   map_height = 45

    tileset = tcod.tileset.load_tilesheet(
        "dejavu10x10_gs_tc.png", 32, 8, tcod.tileset.CHARMAP_TCOD
    )

    event_handler = EventHandler()

    player = Entity(int(screen_width / 2), int(screen_height / 2), "@", (255, 255, 255))
    npc = Entity(int(screen_width / 2 - 5), int(screen_height / 2), "@", (255, 255, 0))
    entities = [npc, player]
    
+   game_map = GameMap(map_width, map_height)

-   engine = Engine(entities=entities, event_handler=event_handler, player=player)
+   engine = Engine(entities=entities, event_handler=event_handler, game_map=game_map, player=player)

    with tcod.context.new_terminal(
        screen_width,
        screen_height,
        tileset=tileset,
        title="Yet Another Roguelike Tutorial",
        vsync=True,
    ) as context:
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>#!/usr/bin/env python3
import tcod

from engine import Engine
from entity import Entity
from game_map import GameMap
from input_handlers import EventHandler


def main() -> None:
    screen_width = 80
    screen_height = 50

    map_width = 80
    map_height = 45

    tileset = tcod.tileset.load_tilesheet(
        "dejavu10x10_gs_tc.png", 32, 8, tcod.tileset.CHARMAP_TCOD
    )

    event_handler = EventHandler()

    player = Entity(int(screen_width / 2), int(screen_height / 2), "@", (255, 255, 255))
    npc = Entity(int(screen_width / 2 - 5), int(screen_height / 2), "@", (255, 255, 0))
    entities = [npc, player]
    
    game_map = GameMap

    engine = Engine(entities=entities, event_handler=event_handler, player=player)

    with tcod.context.new_terminal(
        screen_width,
        screen_height,
        tileset=tileset,
        title="Yet Another Roguelike Tutorial",
        vsync=True,
    ) as context:</pre>
{{</ original-tab >}}
{{</ codetab >}}



// TODO: Explain modifications to Engine class here

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from typing import List, Iterable, Any

from tcod.context import Context
from tcod.console import Console

from actions import EscapeAction, MovementAction
from entity import Entity
+from game_map import GameMap
from input_handlers import EventHandler


class Engine:
-   def __init__(self, entities: List[Entity], event_handler: EventHandler, player: Entity):
+   def __init__(self, entities: List[Entity], event_handler: EventHandler, game_map: GameMap, player: Entity):
        self.entities = entities
        self.event_handler = event_handler
+       self.game_map = game_map
        self.player = player

    def handle_events(self, events: Iterable[Any]) -> None:
        for event in events:
            action = self.event_handler.dispatch(event)

            if action is None:
                continue

            if isinstance(action, MovementAction):
-               self.player.move(dx=action.dx, dy=action.dy)
+               if self.game_map.tiles["walkable"][self.player.x + action.dx, self.player.y + action.dy]:
+                   self.player.move(dx=action.dx, dy=action.dy)

            elif isinstance(action, EscapeAction):
                raise SystemExit()

    def render(self, console: Console, context: Context) -> None:
+       self.game_map.render(console)

        for entity in self.entities:
            entity.render(console)

        context.present(console)

        console.clear()
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from typing import List, Iterable, Any

from tcod.context import Context
from tcod.console import Console

from actions import EscapeAction, MovementAction
from entity import Entity
<span class="new-text">from game_map import GameMap</span>
from input_handlers import EventHandler


class Engine:
   <span class="crossed-out-text">def __init__(self, entities: List[Entity], event_handler: EventHandler, player: Entity):</span>
   <span class="new-text">def __init__(self, entities: List[Entity], event_handler: EventHandler, game_map: GameMap, player: Entity):</span>
        self.entities = entities
        self.event_handler = event_handler
        <span class="new-text">self.game_map = game_map</span>
        self.player = player

    def handle_events(self, events: Iterable[Any]) -> None:
        for event in events:
            action = self.event_handler.dispatch(event)

            if action is None:
                continue

            if isinstance(action, MovementAction):
                <span class="crossed-out-text">self.player.move(dx=action.dx, dy=action.dy)</span>
                <span class="new-text">if self.game_map.tiles["walkable"][self.player.x + action.dx, self.player.y + action.dy]:
                    self.player.move(dx=action.dx, dy=action.dy)</span>

            elif isinstance(action, EscapeAction):
                raise SystemExit()

    def render(self, console: Console, context: Context) -> None:
        <span class="new-text">self.game_map.render(console)</span>

        for entity in self.entities:
            entity.render(console)

        context.present(console)

        console.clear()</pre>
{{</ original-tab >}}
{{</ codetab >}}



// TODO: Finish the tutorial!