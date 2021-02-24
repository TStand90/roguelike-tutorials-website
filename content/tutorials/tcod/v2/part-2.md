---
title: "Part 2 - The generic Entity, the render functions, and the map"
date: 2020-06-23
draft: false
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

    def move(self, dx: int, dy: int) -> None:
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

    tileset = tcod.tileset.load_tilesheet(
        "dejavu10x10_gs_tc.png", 32, 8, tcod.tileset.CHARMAP_TCOD
    )

    event_handler = EventHandler()

+   player = Entity(int(screen_width / 2), int(screen_height / 2), "@", (255, 255, 255))
+   npc = Entity(int(screen_width / 2 - 5), int(screen_height / 2), "@", (255, 255, 0))
+   entities = {npc, player}

    with tcod.context.new_terminal(
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
    
    tileset = tcod.tileset.load_tilesheet(
        "dejavu10x10_gs_tc.png", 32, 8, tcod.tileset.CHARMAP_TCOD
    )

    event_handler = EventHandler()

    <span class="new-text">player = Entity(int(screen_width / 2), int(screen_height / 2), "@", (255, 255, 255))
    npc = Entity(int(screen_width / 2 - 5), int(screen_height / 2), "@", (255, 255, 0))
    entities = {npc, player}</span>

    with tcod.context.new_terminal(
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

We're importing the `Entity` class into `main.py`, and using it to
initialize the player and a new NPC. We store these two in a set, that
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

Let's create an `Engine` class, which will take the responsibilities of drawing the map and entities, as well as handling the player's input. Create a new file, and call it `engine.py`. In that file, put the following contents:


```py3
from typing import Set, Iterable, Any

from tcod.context import Context
from tcod.console import Console

from actions import EscapeAction, MovementAction
from entity import Entity
from input_handlers import EventHandler


class Engine:
    def __init__(self, entities: Set[Entity], event_handler: EventHandler, player: Entity):
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
            console.print(entity.x, entity.y, entity.char, fg=entity.color)

        context.present(console)

        console.clear()
```

Let's walk through the class a bit, to understand what we're trying to get at here.

```py3
class Engine:
    def __init__(self, entities: Set[Entity], event_handler: EventHandler, player: Entity):
        self.entities = entities
        self.event_handler = event_handler
        self.player = player
```

The `__init__` function takes three arguments:

* `entities` is a set (of entities), which behaves kind of like a list that enforces uniqueness. That is, we can't add an Entity to the set twice, whereas a list would allow that. In our case, having an entity in `entities` twice doesn't make sense.
* `event_handler` is the same `event_handler` that we used in `main.py`. It will handle our events.
* `player` is the player Entity. We have a separate reference to it outside of `entities` for ease of access. We'll need to access `player` a lot more than a random entity in `entities`.

```py3
    def handle_events(self, events: Iterable[Any]) -> None:
        for event in events:
            action = self.event_handler.dispatch(event)

            if action is None:
                continue

            if isinstance(action, MovementAction):
                self.player.move(dx=action.dx, dy=action.dy)

            elif isinstance(action, EscapeAction):
                raise SystemExit()
```

This should look familiar: It's almost identical to our event processing in `main.py`. We pass the `events` to it so it can iterate through them, and it uses `self.event_handler` to handle the events.

```py3
    def render(self, console: Console, context: Context) -> None:
        for entity in self.entities:
            console.print(entity.x, entity.y, entity.char, fg=entity.color)

        context.present(console)

        console.clear()
```

This handles drawing our screen. We iterate through the `self.entities` and print them to their proper locations, then present the context, and clear the console, like we did in `main.py`.

To make use of our new `Engine` class, we'll need to modify `main.py` quite a bit.

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
#!/usr/bin/env python3
import tcod

-from actions import EscapeAction, MovementAction
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
    entities = {npc, player}

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

<span class="crossed-out-text">from actions import EscapeAction, MovementAction</span>
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
    entities = {npc, player}

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

            <span class="new-text">events = tcod.event.wait()</span>

            <span class="new-text">engine.handle_events(events)</span>
            <span class="crossed-out-text">root_console.clear()</span>

            <span class="crossed-out-text">for event in tcod.event.wait():</span>
                <span class="crossed-out-text">action = event_handler.dispatch(event)</span>

                <span class="crossed-out-text">if action is None:</span>
                    <span class="crossed-out-text">continue</span>

                <span class="crossed-out-text">if isinstance(action, MovementAction):</span>
                    <span class="crossed-out-text">player_x += action.dx</span>
                    <span class="crossed-out-text">player_y += action.dy</span>

                <span class="crossed-out-text">elif isinstance(action, EscapeAction):</span>
                    <span class="crossed-out-text">raise SystemExit()</span>


if __name__ == "__main__":
    main()</pre>
{{</ original-tab >}}
{{</ codetab >}}

Because we've moved the rendering and event handling code to the `Engine` class, we no longer need it in `main.py`. All we need to do is create the `Engine` instance, pass the needed variables to it, and use the methods we wrote for it.

Run the project now, and your screen should look like this:

![Part 2 - Both Entities](/images/part-2-drawing-both-entities.png)

Our `main.py` file is looking a lot smaller and simpler, and we've rendered both the player and the NPC to the screen. With that, we'll want to move on to creating a map for our entity to move around in. We won't do the procedural dungeon generation in this chapter (that's next), but we'll at least get our class that will hold that map set up.

We can represent the map with a new class, called `GameMap`. The map itself will be made up of tiles, which will contain certain data about if the tile is "walkable" (True if it's a floor, False if its a wall), "transparency" (again, True for floors, False for walls), and how to render the tile to the screen.

We'll create the `tiles` first. Create a new file called `tile_types.py` and fill it with the following contents:

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

That's quite a lot to take in all at once. Let's go through it.

```py3
# Tile graphics structured type compatible with Console.tiles_rgb.
graphic_dt = np.dtype(
    [
        ("ch", np.int32),  # Unicode codepoint.
        ("fg", "3B"),  # 3 unsigned bytes, for RGB colors.
        ("bg", "3B"),
    ]
)
```

`dtype` creates a data type which Numpy can use, which behaves similarly to a `struct` in a language like C. Our data type is made up of three parts:

* `ch`: The character, represented in integer format. We'll translate it from the integer into Unicode.
* `fg`: The foreground color. "3B" means 3 unsigned bytes, which can be used for RGB color codes.
* `bg`: The background color. Similar to `fg`.

We take this new data type and use it in the next bit:

```py3
# Tile struct used for statically defined tile data.
tile_dt = np.dtype(
    [
        ("walkable", np.bool),  # True if this tile can be walked over.
        ("transparent", np.bool),  # True if this tile doesn't block FOV.
        ("dark", graphic_dt),  # Graphics for when this tile is not in FOV.
    ]
)
```

This is yet another `dtype`, which we'll use in the actual tile itself. It's also made up of three parts:

* `walkable`: A boolean that describes if the player can walk across this tile.
* `transparent`: A boolean that describes if this tile does or does not block the field of view. Not used in this chapter, but will be in chapter 4.
* `dark`: This uses our previously defined `dtype`, which holds the character to print, the foreground color, and the background color. Why is it called `dark`? Because later on, we'll want to differentiate between tiles that are and aren't in the field of view. `dark` will represent tiles that are not in the current field of view. Again, we'll cover that in part 4.

```py3
def new_tile(
    *,  # Enforce the use of keywords, so that parameter order doesn't matter.
    walkable: int,
    transparent: int,
    dark: Tuple[int, Tuple[int, int, int], Tuple[int, int, int]],
) -> np.ndarray:
    """Helper function for defining individual tile types """
    return np.array((walkable, transparent, dark), dtype=tile_dt)
```

This is a helper function, that we'll use in the next section to define our tile types. It takes the parameters `walkable`, `transparent`, and `dark`, which should look familiar, since they're the same data points we used in `tile_dt`. It creates a Numpy array of just the one `tile_dt` element, and returns it.

```py3
floor = new_tile(
    walkable=True, transparent=True, dark=(ord(" "), (255, 255, 255), (50, 50, 150)),
)
wall = new_tile(
    walkable=False, transparent=False, dark=(ord(" "), (255, 255, 255), (0, 0, 100)),
)
```

Finally, we arrive to our actual tile types. We've got two: `floor` and `wall`.

`floor` is both `walkable` and `transparent`. Its `dark` attribute consists of the space character (feel free to change this to something else, a lot of roguelikes use "#") and defines its foreground color as white (won't matter since it's an empty space) and a background color.

`wall` is neither `walkable` nor `transparent`, and its `dark` attribute differs from `floor` slightly in its background color.

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
    
    def in_bounds(self, x: int, y: int) -> bool:
        """Return True if x and y are inside of the bounds of this map."""
        return 0 <= x < self.width and 0 <= y < self.height

    def render(self, console: Console) -> None:
        console.tiles_rgb[0:self.width, 0:self.height] = self.tiles["dark"]
```

Let's break down `GameMap` a bit:

```py3
    def __init__(self, width: int, height: int):
        self.width, self.height = width, height
        self.tiles = np.full((width, height), fill_value=tile_types.floor, order="F")

        self.tiles[30:33, 22] = tile_types.wall
```

The initializer takes `width` and `height` integers and assigns them, in one line.

The `self.tiles` line might look a little strange if you're not used to Numpy. Basically, we create a 2D array, filled with the same values, which in this case, is the `tile_types.floor` that we created earlier. This will fill `self.tiles` with floor tiles.

`self.tiles[30:33, 22] = tile_types.wall` creates a small, three tile wide wall at the specified location. We won't normally hard-code walls like this, the wall is just for demonstration purposes. We'll remove it in the next part.

```py3
    def in_bounds(self, x: int, y: int) -> bool:
        """Return True if x and y are inside of the bounds of this map."""
        return 0 <= x < self.width and 0 <= y < self.height
```

As the docstring alludes to, this method returns `True` if the given x and y values are within the map's boundaries. We can use this to ensure the player doesn't move beyond the map, into the void.

```py3
    def render(self, console: Console) -> None:
        console.tiles_rgb[0:self.width, 0:self.height] = self.tiles["dark"]
```

Using the `Console` class's `tiles_rgb` method, we can quickly render the entire map. This method proves much faster than using the `console.print` method that we use for the individual entities.

With our `GameMap` class ready to go, let's modify `main.py` to make use of it. We'll also need to modify `Engine` to hold the map. Let's start with `main.py` though:

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
    entities = {npc, player}
    
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
<span class="new-text">from game_map import GameMap</span>
from input_handlers import EventHandler


def main() -> None:
    screen_width = 80
    screen_height = 50

    <span class="new-text">map_width = 80
    map_height = 45</span>

    tileset = tcod.tileset.load_tilesheet(
        "dejavu10x10_gs_tc.png", 32, 8, tcod.tileset.CHARMAP_TCOD
    )

    event_handler = EventHandler()

    player = Entity(int(screen_width / 2), int(screen_height / 2), "@", (255, 255, 255))
    npc = Entity(int(screen_width / 2 - 5), int(screen_height / 2), "@", (255, 255, 0))
    entities = {npc, player}
    
    <span class="new-text">game_map = GameMap(map_width, map_height)</span>

    <span class="crossed-out-text">engine = Engine(entities=entities, event_handler=event_handler, player=player)</span>
    <span class="new-text">engine = Engine(entities=entities, event_handler=event_handler, game_map=game_map, player=player)</span>

    with tcod.context.new_terminal(
        screen_width,
        screen_height,
        tileset=tileset,
        title="Yet Another Roguelike Tutorial",
        vsync=True,
    ) as context:</pre>
{{</ original-tab >}}
{{</ codetab >}}

We've added `map_width` and `map_height`, two integers, which we use in the `GameMap` class to describe its width and height. The `game_map` variable holds our initialized `GameMap`, and we then pass it into `engine`. The `Engine` class doesn't yet accept a `GameMap` in its `__init__` function, so let's fix that now.

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from typing import Set, Iterable, Any

from tcod.context import Context
from tcod.console import Console

from actions import EscapeAction, MovementAction
from entity import Entity
+from game_map import GameMap
from input_handlers import EventHandler


class Engine:
-   def __init__(self, entities: Set[Entity], event_handler: EventHandler, player: Entity):
+   def __init__(self, entities: Set[Entity], event_handler: EventHandler, game_map: GameMap, player: Entity):
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
            console.print(entity.x, entity.y, entity.char, fg=entity.color)

        context.present(console)

        console.clear()
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from typing import Set, Iterable, Any

from tcod.context import Context
from tcod.console import Console

from actions import EscapeAction, MovementAction
from entity import Entity
<span class="new-text">from game_map import GameMap</span>
from input_handlers import EventHandler


class Engine:
    <span class="crossed-out-text">def __init__(self, entities: Set[Entity], event_handler: EventHandler, player: Entity):</span>
    <span class="new-text">def __init__(self, entities: Set[Entity], event_handler: EventHandler, game_map: GameMap, player: Entity):</span>
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
            console.print(entity.x, entity.y, entity.char, fg=entity.color)

        context.present(console)

        console.clear()</pre>
{{</ original-tab >}}
{{</ codetab >}}

We've imported the `GameMap` class, and we're now passing an instance of it in the `Engine` class's initializer. From there, we utilize it in two ways:

* In `handle_events`, we use it to check if the tile is "walkable", and only then do we move the player.
* In `render`, we call the `GameMap`'s `render` method to draw it to the screen.

If you run the project now, it should look like this:

![Part 2 - Both Entities and Map](/images/part-2-entities-and-map.png)

The darker squares represent the wall, which, if you try to move your character through, should prove to be impenetrable.

Before we finish this up, there's one last improvement we can make, thanks to our new `Engine` class: We can expand our `Action` classes to do a bit more of the heavy lifting, rather than leaving it to the `Engine`. This is because we can pass the `Engine` to the `Action`, providing it with the context it needs to do what we want.

Here's what that looks like:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
+from __future__ import annotations

+from typing import TYPE_CHECKING

+if TYPE_CHECKING:
+   from engine import Engine
+   from entity import Entity


class Action:
-   pass
+   def perform(self, engine: Engine, entity: Entity) -> None:
+       """Perform this action with the objects needed to determine its scope.

+       `engine` is the scope this action is being performed in.

+       `entity` is the object performing the action.

+       This method must be overridden by Action subclasses.
+       """
+       raise NotImplementedError()


class EscapeAction(Action):
-   pass
+   def perform(self, engine: Engine, entity: Entity) -> None:
+       raise SystemExit()


class MovementAction(Action):
    def __init__(self, dx: int, dy: int):
        super().__init__()

        self.dx = dx
        self.dy = dy

+   def perform(self, engine: Engine, entity: Entity) -> None:
+       dest_x = entity.x + self.dx
+       dest_y = entity.y + self.dy

+       if not engine.game_map.in_bounds(dest_x, dest_y):
+           return  # Destination is out of bounds.
+       if not engine.game_map.tiles["walkable"][dest_x, dest_y]:
+           return  # Destination is blocked by a tile.

+       entity.move(self.dx, self.dy)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre><span class="new-text">from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from engine import Engine
    from entity import Entity</span>


class Action:
    <span class="crossed-out-text">pass</span>
    <span class="new-text">def perform(self, engine: Engine, entity: Entity) -> None:
        """Perform this action with the objects needed to determine its scope.

        `engine` is the scope this action is being performed in.

        `entity` is the object performing the action.

        This method must be overridden by Action subclasses.
        """
        raise NotImplementedError()</span>


class EscapeAction(Action):
    <span class="crossed-out-text">pass</span>
    <span class="new-text">def perform(self, engine: Engine, entity: Entity) -> None:
        raise SystemExit()</span>


class MovementAction(Action):
    def __init__(self, dx: int, dy: int):
        super().__init__()

        self.dx = dx
        self.dy = dy

    <span class="new-text">def perform(self, engine: Engine, entity: Entity) -> None:
        dest_x = entity.x + self.dx
        dest_y = entity.y + self.dy

        if not engine.game_map.in_bounds(dest_x, dest_y):
            return  # Destination is out of bounds.
        if not engine.game_map.tiles["walkable"][dest_x, dest_y]:
            return  # Destination is blocked by a tile.

        entity.move(self.dx, self.dy)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Now we're passing in the `Engine` and the `Entity` performing the action to each `Action` subclass. Each subclass needs to implement its own version of the `perform` method. In the case of `EscapeAction`, we're just raising `SystemExit`. In the case of `MovementAction`, we double check that the move is "in bounds" and on a "walkable" tile, and if either is true, we return without doing anything. If neither of those cases prove true, then we move the entity, as before.

So what does this new technique do for us? As it turns out, we can simplify the `Engine.handle_events` method like this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
...
-from actions import EscapeAction, MovementAction
from entity import Entity
from game_map import GameMap
from input_handlers import EventHandler


class Engine:
    ...

    def handle_events(self, events: Iterable[Any]) -> None:
        for event in events:
            action = self.event_handler.dispatch(event)

            if action is None:
                continue

+           action.perform(self, self.player)
-           if isinstance(action, MovementAction):
-               if self.game_map.tiles["walkable"][self.player.x + action.dx, self.player.y + action.dy]:
-                   self.player.move(dx=action.dx, dy=action.dy)

-           elif isinstance(action, EscapeAction):
-               raise SystemExit()
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>...
<span class="crossed-out-text">from actions import EscapeAction, MovementAction</span>
from entity import Entity
from game_map import GameMap
from input_handlers import EventHandler


class Engine:
    ...

    def handle_events(self, events: Iterable[Any]) -> None:
        for event in events:
            action = self.event_handler.dispatch(event)

            if action is None:
                continue

            <span class="new-text">action.perform(self, self.player)</span>
            <span class="crossed-out-text">if isinstance(action, MovementAction):</span>
                <span class="crossed-out-text">if self.game_map.tiles["walkable"][self.player.x + action.dx, self.player.y + action.dy]:</span>
                    <span class="crossed-out-text">self.player.move(dx=action.dx, dy=action.dy)</span>

            <span class="crossed-out-text">elif isinstance(action, EscapeAction):</span>
                <span class="crossed-out-text">raise SystemExit()</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Much simpler! Run the project again, and it should function the same as before.
    
With that, Part 2 is now complete! We've managed to lay the groundwork for generating dungeons and moving through them, which, as it happens, is what the next part is all about.

If you want to see the code so far in its entirety, [click
here](https://github.com/TStand90/tcod_tutorial_v2/tree/2020/part-2).

[Click here to move on to the next part of this
tutorial.](/tutorials/tcod/v2/part-3)
