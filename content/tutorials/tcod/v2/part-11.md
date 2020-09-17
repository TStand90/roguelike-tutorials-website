---
title: "Part 11 - Delving into the Dungeon"
date: 2020-07-21
draft: true
---

Our game isn't much of a "dungeon crawler" if there’s only one floor to our dungeon. In this chapter, we'll allow the player to go down a level, and we'll put a very basic leveling up system in place, to make the dive all the more rewarding.

Before diving into the code for this section, let's add the color we'll need this chapter, for when the player descends down a level in the dungeon. Open up `color.py` and add this line:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
...
enemy_atk = (0xFF, 0xC0, 0xC0)
needs_target = (0x3F, 0xFF, 0xFF)
status_effect_applied = (0x3F, 0xFF, 0x3F)
+descend = (0x9F, 0x3F, 0xFF)
 
player_die = (0xFF, 0x30, 0x30)
enemy_die = (0xFF, 0xA0, 0x30)
...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>...
enemy_atk = (0xFF, 0xC0, 0xC0)
needs_target = (0x3F, 0xFF, 0xFF)
status_effect_applied = (0x3F, 0xFF, 0x3F)
<span class="new-text">descend = (0x9F, 0x3F, 0xFF)</span>
 
player_die = (0xFF, 0x30, 0x30)
enemy_die = (0xFF, 0xA0, 0x30)
...</pre>
{{</ original-tab >}}
{{</ codetab >}}

We will use this color later on, when adding a message to the message log that the player went down one floor.

We'll also need a new tile type to represent the downward stairs in the dungeon. Typically, roguelikes represent this with the `>` character, and we'll do the same. Add the following to `tile_types.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
...
wall = new_tile(
    walkable=False,
    transparent=False,
    dark=(ord(" "), (255, 255, 255), (0, 0, 100)),
    light=(ord(" "), (255, 255, 255), (130, 110, 50)),
)
+down_stairs = new_tile(
+   walkable=True,
+   transparent=True,
+   dark=(ord(">"), (0, 0, 100), (50, 50, 150)),
+   light=(ord(">"), (255, 255, 255), (200, 180, 50)),
+)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>...
wall = new_tile(
    walkable=False,
    transparent=False,
    dark=(ord(" "), (255, 255, 255), (0, 0, 100)),
    light=(ord(" "), (255, 255, 255), (130, 110, 50)),
)
<span class="new-text">down_stairs = new_tile(
    walkable=True,
    transparent=True,
    dark=(ord(">"), (0, 0, 100), (50, 50, 150)),
    light=(ord(">"), (255, 255, 255), (200, 180, 50)),
)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

To keep track of where our downwards stairs are located on the map, we can add a new variable in out `__init__` function in the `GameMap` class. The variable needs some sort of default, so to start, we can set that up to be `(0, 0)` by default. Add the following line to `game_map.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class GameMap:
    def __init__(
        self, engine: Engine, width: int, height: int, entities: Iterable[Entity] = ()
    ):
        ...
        self.explored = np.full(
            (width, height), fill_value=False, order="F"
        )  # Tiles the player has seen before
 
+       self.downstairs_location = (0, 0)

    @property
    def gamemap(self) -> GameMap:
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class GameMap:
    def __init__(
        self, engine: Engine, width: int, height: int, entities: Iterable[Entity] = ()
    ):
        ...
        self.explored = np.full(
            (width, height), fill_value=False, order="F"
        )  # Tiles the player has seen before
 
        <span class="new-text">self.downstairs_location = (0, 0)</span>

    @property
    def gamemap(self) -> GameMap:
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Of course, `(0, 0)` won't be the actual location of the stairs. In order to actually place the downwards stairs, we'll need to edit our procedural dungeon generator to place the stairs at the proper place. We'll keep things simple and just place the stairs in the last room that our algorithm generates, by keeping track of the center coordinates of the last room we created. Modify `generate_dungeon` function in `procgen.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
    ...
    rooms: List[RectangularRoom] = []
 
+   center_of_last_room = (0, 0)

    for r in range(max_rooms):
        ...
            ...
            for x, y in tunnel_between(rooms[-1].center, new_room.center):
                dungeon.tiles[x, y] = tile_types.floor
 
+           center_of_last_room = new_room.center

        place_entities(new_room, dungeon, max_monsters_per_room, max_items_per_room)
 
+       dungeon.tiles[center_of_last_room] = tile_types.down_stairs
+       dungeon.downstairs_location = center_of_last_room

        # Finally, append the new room to the list.
        rooms.append(new_room)
    
    return dungeon
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>    ...
    rooms: List[RectangularRoom] = []
 
    <span class="new-text">center_of_last_room = (0, 0)</span>

    for r in range(max_rooms):
        ...
            ...
            for x, y in tunnel_between(rooms[-1].center, new_room.center):
                dungeon.tiles[x, y] = tile_types.floor
 
            <span class="new-text">center_of_last_room = new_room.center</span>

        place_entities(new_room, dungeon, max_monsters_per_room, max_items_per_room)
 
        <span class="new-text">dungeon.tiles[center_of_last_room] = tile_types.down_stairs
        dungeon.downstairs_location = center_of_last_room</span>

        # Finally, append the new room to the list.
        rooms.append(new_room)
    
    return dungeon</pre>
{{</ original-tab >}}
{{</ codetab >}}

Whichever room is generated last, we take its center and set the `downstairs_location` equal to those coordinates. We also replace whatever tile type with the `down_stairs`, so the player can clearly see the location.

To hold the information about the maps, including the size, the room variables (size and maximum number), along with the floor that the player is currently on, we can add a class to hold these variables, as well as generate new maps when the time comes. Open up `game_map.py` and add the following class:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class GameMap:
    ...


+class GameWorld:
+   """
+   Holds the settings for the GameMap, and generates new maps when moving down the stairs.
+   """

+   def __init__(
+       self,
+       *,
+       engine: Engine,
+       map_width: int,
+       map_height: int,
+       max_rooms: int,
+       room_min_size: int,
+       room_max_size: int,
+       max_monsters_per_room: int,
+       max_items_per_room: int,
+       current_floor: int = 0
+   ):
+       self.engine = engine

+       self.map_width = map_width
+       self.map_height = map_height

+       self.max_rooms = max_rooms

+       self.room_min_size = room_min_size
+       self.room_max_size = room_max_size

+       self.max_monsters_per_room = max_monsters_per_room
+       self.max_items_per_room = max_items_per_room

+       self.current_floor = current_floor

+   def generate_floor(self) -> None:
+       from procgen import generate_dungeon

+       self.current_floor += 1

+       self.engine.game_map = generate_dungeon(
+           max_rooms=self.max_rooms,
+           room_min_size=self.room_min_size,
+           room_max_size=self.room_max_size,
+           map_width=self.map_width,
+           map_height=self.map_height,
+           max_monsters_per_room=self.max_monsters_per_room,
+           max_items_per_room=self.max_items_per_room,
+           engine=self.engine,
+       )
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class GameMap:
    ...


<span class="new-text">class GameWorld:
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
        max_monsters_per_room: int,
        max_items_per_room: int,
        current_floor: int = 0
    ):
        self.engine = engine

        self.map_width = map_width
        self.map_height = map_height

        self.max_rooms = max_rooms

        self.room_min_size = room_min_size
        self.room_max_size = room_max_size

        self.max_monsters_per_room = max_monsters_per_room
        self.max_items_per_room = max_items_per_room

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
            max_monsters_per_room=self.max_monsters_per_room,
            max_items_per_room=self.max_items_per_room,
            engine=self.engine,
        )</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

The `generate_floor` method will create the new maps each time we go down a floor, using the variables that `GameWorld` stores. In this tutorial, we won't program in the ability to go back up a floor after going down one, but you could perhaps modify `GameWorld` to hold the previous maps.

In order to utilize the new `GameWorld` class, we'll need to add it to the `Engine`, like this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
... 
if TYPE_CHECKING:
    from entity import Actor
-   from game_map import GameMap
+   from game_map import GameMap, GameWorld
 
 
class Engine:
    game_map: GameMap
+   game_world: GameWorld
 
    def __init__(self, player: Actor):
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>... 
if TYPE_CHECKING:
    from entity import Actor
    <span class="crossed-out-text">from game_map import GameMap</span>
    <span class="new-text">from game_map import GameMap, GameWorld</span>
 
 
class Engine:
    game_map: GameMap
    <span class="new-text">game_world: GameWorld</span>
 
    def __init__(self, player: Actor):
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Pretty simple. To utilize the new `game_world` class attribute, edit `setup_game.py` like this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
import tcod
import color
from engine import Engine
import entity_factories
+from game_map import GameWorld
import input_handlers
-from procgen import generate_dungeon
... 
 
    ...
    engine = Engine(player=player)
 
-   engine.game_map = generate_dungeon(
+   engine.game_world = GameWorld(
+       engine=engine,
        max_rooms=max_rooms,
        room_min_size=room_min_size,
        room_max_size=room_max_size,
        map_width=map_width,
        map_height=map_height,
        max_monsters_per_room=max_monsters_per_room,
        max_items_per_room=max_items_per_room,
-       engine=engine,
    )

+   engine.game_world.generate_floor()
    engine.update_fov()
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>import tcod
import color
from engine import Engine
import entity_factories
<span class="new-text">from game_map import GameWorld</span>
import input_handlers
<span class="crossed-out-text">from procgen import generate_dungeon</span>
... 
 
    ...
    engine = Engine(player=player)
 
    <span class="crossed-out-text">engine.game_map = generate_dungeon(</span>
    <span class="new-text">engine.game_world = GameWorld(
        engine=engine,</span>
        max_rooms=max_rooms,
        room_min_size=room_min_size,
        room_max_size=room_max_size,
        map_width=map_width,
        map_height=map_height,
        max_monsters_per_room=max_monsters_per_room,
        max_items_per_room=max_items_per_room,
        <span class="crossed-out-text">engine=engine,</span>
    )

    <span class="new-text">engine.game_world.generate_floor()</span>
    engine.update_fov()
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Now, instead of calling `generate_dungeon` directly, we create a new `GameWorld` and allow it to call its `generate_floor` method. While this doesn't change anything for the first floor that's created, it will allows us to more easily create new floors on the fly.

In order to actually take the stairs, we'll need to add an action and a way for the player to trigger it. Adding the action is pretty simple. Add the following to `actions.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class WaitAction(Action):
    pass
 
 
+class TakeStairsAction(Action):
+   def perform(self) -> None:
+       """
+       Take the stairs, if any exist at the entity's location.
+       """
+       if (self.entity.x, self.entity.y) == self.engine.game_map.downstairs_location:
+           self.engine.game_world.generate_floor()
+           self.engine.message_log.add_message(
+               "You descend the staircase.", color.descend
+           )
+       else:
+           raise exceptions.Impossible("There are no stairs here.")


class ActionWithDirection(Action):
    def __init__(self, entity: Actor, dx: int, dy: int):
        super().__init__(entity)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class WaitAction(Action):
    pass
 
 
<span class="new-text">class TakeStairsAction(Action):
    def perform(self) -> None:
        """
        Take the stairs, if any exist at the entity's location.
        """
        if (self.entity.x, self.entity.y) == self.engine.game_map.downstairs_location:
            self.engine.game_world.generate_floor()
            self.engine.message_log.add_message(
                "You descend the staircase.", color.descend
            )
        else:
            raise exceptions.Impossible("There are no stairs here.")</span>


class ActionWithDirection(Action):
    def __init__(self, entity: Actor, dx: int, dy: int):
        super().__init__(entity)</pre>
{{</ original-tab >}}
{{</ codetab >}}

To call this action, the player should be able to press the `>` key. This can be accomplished by adding this to `input_handlers.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class MainGameEventHandler(EventHandler):
    def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[ActionOrHandler]:
        action: Optional[Action] = None
 
        key = event.sym
+       modifier = event.mod
 
        player = self.engine.player
 
+       if key == tcod.event.K_PERIOD and modifier & (
+           tcod.event.KMOD_LSHIFT | tcod.event.KMOD_RSHIFT
+       ):
+           return actions.TakeStairsAction(player)

        if key in MOVE_KEYS:
            dx, dy = MOVE_KEYS[key]
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class MainGameEventHandler(EventHandler):
    def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[ActionOrHandler]:
        action: Optional[Action] = None
 
        key = event.sym
        <span class="new-text">modifier = event.mod</span>
 
        player = self.engine.player
 
        <span class="new-text">if key == tcod.event.K_PERIOD and modifier & (
            tcod.event.KMOD_LSHIFT | tcod.event.KMOD_RSHIFT
        ):
            return actions.TakeStairsAction(player)</span>

        if key in MOVE_KEYS:
            dx, dy = MOVE_KEYS[key]</pre>
{{</ original-tab >}}
{{</ codetab >}}

`modifier` tells us if the player is holding a key like control, alt, or shift. In this case, we're checking if the user is holding shift while pressing the period key, which gives us the ">" key.

With that, the player can now descend the staircase to the next floor of the dungeon!

![Part 11 - Stairs](/images/part-11-stairs.png)
![Part 11 - Stairs Taken](/images/part-11-stairs-taken.png)

One little touch we can add before moving on to the next section is adding a way to see which floor the player is on. It's simple enough: We'll use the `current_floor` in `GameWorld` to know which floor we're on, and we'll modify our `render_functions.py` file to add a method to print this information out to the UI.

Add this function to `render_functions.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from __future__ import annotations
 
-from typing import TYPE_CHECKING
+from typing import Tuple, TYPE_CHECKING
 
import color
...

...
def render_bar(
    console: Console, current_value: int, maximum_value: int, total_width: int
) -> None:
    ...
 
 
+def render_dungeon_level(
+   console: Console, dungeon_level: int, location: Tuple[int, int]
+) -> None:
+   """
+   Render the level the player is currently on, at the given location.
+   """
+   x, y = location

+   console.print(x=x, y=y, string=f"Dungeon level: {dungeon_level}")


def render_names_at_mouse_location(
    console: Console, x: int, y: int, engine: Engine
) -> None:
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from __future__ import annotations
 
<span class="crossed-out-text">from typing import TYPE_CHECKING</span>
<span class="new-text">from typing import Tuple, TYPE_CHECKING</span>
 
import color
...

...
def render_bar(
    console: Console, current_value: int, maximum_value: int, total_width: int
) -> None:
    ...
 
 
<span class="new-text">def render_dungeon_level(
    console: Console, dungeon_level: int, location: Tuple[int, int]
) -> None:
    """
    Render the level the player is currently on, at the given location.
    """
    x, y = location

    console.print(x=x, y=y, string=f"Dungeon level: {dungeon_level}")</span>


def render_names_at_mouse_location(
    console: Console, x: int, y: int, engine: Engine
) -> None:
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

The `render_dungeon_level` function is fairly straightforward: Given a set of `(x, y)` coordinates as a Tuple, it prints to the console which dungeon level was passed to the function.

To call this function, we can edit the `Engine`'s `render` function, like so:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
... 
import exceptions
from message_log import MessageLog
-from render_functions import (
-   render_bar,
-   render_names_at_mouse_location,
-)
+import render_functions

if TYPE_CHECKING:
    ...


class Engine:
    ...

    def render(self, console: Console) -> None:
        self.game_map.render(console)

        self.message_log.render(console=console, x=21, y=45, width=40, height=5)
 
-       render_bar(
+       render_functions.render_bar(
            console=console,
            current_value=self.player.fighter.hp,
            maximum_value=self.player.fighter.max_hp,
            total_width=20,
        )
 
-       render_names_at_mouse_location(console=console, x=21, y=44, engine=self)
+       render_functions.render_dungeon_level(
+           console=console,
+           dungeon_level=self.game_world.current_floor,
+           location=(0, 47),
+       )

+       render_functions.render_names_at_mouse_location(
+           console=console, x=21, y=44, engine=self
+       )

    def save_as(self, filename: str) -> None:
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>... 
import exceptions
from message_log import MessageLog
<span class="crossed-out-text">from render_functions import (</span>
    <span class="crossed-out-text">render_bar,</span>
    <span class="crossed-out-text">render_names_at_mouse_location,</span>
<span class="crossed-out-text">)</span>
<span class="new-text">import render_functions</span>

if TYPE_CHECKING:
    ...


class Engine:
    ...

    def render(self, console: Console) -> None:
        self.game_map.render(console)

        self.message_log.render(console=console, x=21, y=45, width=40, height=5)
 
        <span class="crossed-out-text">render_bar(</span>
        <span class="new-text">render_functions.render_bar(</span>
            console=console,
            current_value=self.player.fighter.hp,
            maximum_value=self.player.fighter.max_hp,
            total_width=20,
        )
 
        <span class="crossed-out-text">render_names_at_mouse_location(console=console, x=21, y=44, engine=self)</span>
        <span class="new-text">render_functions.render_dungeon_level(
            console=console,
            dungeon_level=self.game_world.current_floor,
            location=(0, 47),
        )

        render_functions.render_names_at_mouse_location(
            console=console, x=21, y=44, engine=self
        )</span>
 
    def save_as(self, filename: str) -> None:
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Note that we're now importing `render_functions` instead of importing the functions it contains. After awhile, it makes sense to just import the entire module rather than a few functions here and there. Otherwise, the file can get a bit difficult to read.

The call to `render_dungeon_level` shouldn't be anything too surprising. We use `self.game_world.current_floor` as our `dungeon_level`, and the location of the printed string is below the health bar (feel free to move this somewhere else, if you like).

Try going down a few levels and make sure everything works as expected. If so, congratulations! Your dungeon now has multiple levels!

![Part 11 - Dungeon Level](/images/part-11-dungeon-level.png)

Speaking of "levels", many roguelikes (not all!) feature some sort of level-up system, where your character gains experience and gets stronger by fighting monsters. The rest of this chapter will be spent implementing one such system.

In order to allow the rogue to level up, we need to modify the actors in two ways:
1. The player needs to gain experience points, keeping track of the XP gained thus far, and know when it's time to level up.
2. The enemies need to give experience points when they are defeated.

There are several calculations we could use to compute how much XP a player needs to level up (or, theoretically, you could just hard code the values). Ours will be fairly simple: We'll start with a base number, and add the product of our player's current level and some other number, which will make it so each level up requires more XP than the last. For this tutorial, the "base" will be 200, and the "factor" will be 150 (so going to level 2 will take 350 XP, level 3 will take 500, and so on).

We can accomplish both of these goals by adding one component: `Level`. The `Level` component will hold all of the information that we need to accomplish these goals. Create a file called `level.py` in the `components` directory, and put the following contents in it:

```py3
from __future__ import annotations

from typing import TYPE_CHECKING

from components.base_component import BaseComponent

if TYPE_CHECKING:
    from entity import Actor


class Level(BaseComponent):
    parent: Actor

    def __init__(
        self,
        current_level: int = 1,
        current_xp: int = 0,
        level_up_base: int = 0,
        level_up_factor: int = 150,
        xp_given: int = 0,
    ):
        self.current_level = current_level
        self.current_xp = current_xp
        self.level_up_base = level_up_base
        self.level_up_factor = level_up_factor
        self.xp_given = xp_given

    @property
    def experience_to_next_level(self) -> int:
        return self.level_up_base + self.current_level * self.level_up_factor

    @property
    def requires_level_up(self) -> bool:
        return self.current_xp > self.experience_to_next_level

    def add_xp(self, xp: int) -> None:
        if xp == 0 or self.level_up_base == 0:
            return

        self.current_xp += xp

        self.engine.message_log.add_message(f"You gain {xp} experience points.")

        if self.requires_level_up:
            self.engine.message_log.add_message(
                f"You advance to level {self.current_level + 1}!"
            )

    def increase_level(self) -> None:
        self.current_xp -= self.experience_to_next_level

        self.current_level += 1

    def increase_max_hp(self, amount: int = 20) -> None:
        self.parent.fighter.max_hp += amount
        self.parent.fighter.hp += amount

        self.engine.message_log.add_message("Your health improves!")

        self.increase_level()

    def increase_power(self, amount: int = 1) -> None:
        self.parent.fighter.power += amount

        self.engine.message_log.add_message("You feel stronger!")

        self.increase_level()

    def increase_defense(self, amount: int = 1) -> None:
        self.parent.fighter.defense += amount

        self.engine.message_log.add_message("Your movements are getting swifter!")

        self.increase_level()
```

Let's go over what was just added.

```py3
class Level(BaseComponent):
    parent: Actor

    def __init__(
        self,
        current_level: int = 1,
        current_xp: int = 0,
        level_up_base: int = 0,
        level_up_factor: int = 150,
        xp_given: int = 0,
    ):
        self.current_level = current_level
        self.current_xp = current_xp
        self.level_up_base = level_up_base
        self.level_up_factor = level_up_factor
        self.xp_given = xp_given
```

The values in our `__init__` function break down like this:

* current_level: The current level of the Entity, defaults to 1.
* current_xp: The Entity's current experience points.
* level_up_base: The base number we decide for leveling up. We'll set this to 200 when creating the Player.
* level_up_factor: The number to multiply against the Entity's current level.
* xp_given: When the Entity dies, this is how much XP the Player will gain.

```py3
    @property
    def experience_to_next_level(self) -> int:
        return self.level_up_base + self.current_level * self.level_up_factor
```

This represents how much experience the player needs until hitting the next level. The formula is explained above. Again, feel free to tweak this formula in any way you see fit.

```py3
    @property
    def requires_level_up(self) -> bool:
        return self.current_xp > self.experience_to_next_level
```

We'll use this property to determine if the player needs to level up or not. If the `current_xp` is higher than the `experience_to_next_level` property, then the player levels up. If not, nothing happens.

```py3
    def add_xp(self, xp: int) -> None:
        if xp == 0 or self.level_up_base == 0:
            return

        self.current_xp += xp

        self.engine.message_log.add_message(f"You gain {xp} experience points.")

        if self.requires_level_up:
            self.engine.message_log.add_message(
                f"You advance to level {self.current_level + 1}!"
            )
```

This method adds experience points to the Entity's XP pool, as the name implies. If the value is 0, we just return, as there's nothing to do. Notice that we also return if the `level_up_base` is set to 0. Why? In this tutorial, the enemies don't gain XP, so we'll set their `level_up_base` to 0 so that there's no way they could ever gain experience. Perhaps in your game, monsters *will* gain XP, and you'll want to adjust this, but that's left up to you.

The rest of the method adds the xp, adds a message to the message log, and, if the Entity levels up, posts another message.

```py3
    def increase_level(self) -> None:
        self.current_xp -= self.experience_to_next_level

        self.current_level += 1
```

This method adds +1 to the `current_level`, while decreasing the `current_xp` by the `experience_to_next_level`. We do this because if we didn't it would always just take the `level_up_factor` amount to level up, which isn't what we want. If you wanted to keep track of the player's *cumulative* XP throughout the playthrough, you could skip decrementing the `current_xp` and instead adjust the `experience_to_next_level` formula accordingly.

Lastly, the functions `increase_max_hp`, `increase_power`, and `increase_defense` all do basically the same thing: they raise one of the Entity's attributes, add a message to the message log, then call `increase_level`.

To use this component, we need to add it to our `Actor` class. Make the following changes to the file `entity.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
if TYPE_CHECKING:
    from components.ai import BaseAI
    from components.consumable import Consumable
    from components.fighter import Fighter
    from components.inventory import Inventory
+   from components.level import Level
    from game_map import GameMap
 
T = TypeVar("T", bound="Entity")
...

class Actor(Entity):
    def __init__(
        self,
        *,
        x: int = 0,
        y: int = 0,
        char: str = "?",
        color: Tuple[int, int, int] = (255, 255, 255),
        name: str = "<Unnamed>",
        ai_cls: Type[BaseAI],
        fighter: Fighter,
        inventory: Inventory,
+       level: Level,
    ):
        super().__init__(
            x=x,
            y=y,
            char=char,
            color=color,
            name=name,
            blocks_movement=True,
            render_order=RenderOrder.ACTOR,
        )

        self.ai: Optional[BaseAI] = ai_cls(self)

        self.fighter = fighter
        self.fighter.parent = self

        self.inventory = inventory
        self.inventory.parent = self

+       self.level = level
+       self.level.parent = self

    @property
    def is_alive(self) -> bool:
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>if TYPE_CHECKING:
    from components.ai import BaseAI
    from components.consumable import Consumable
    from components.fighter import Fighter
    from components.inventory import Inventory
    <span class="new-text">from components.level import Level</span>
    from game_map import GameMap
 
T = TypeVar("T", bound="Entity")
...

class Actor(Entity):
    def __init__(
        self,
        *,
        x: int = 0,
        y: int = 0,
        char: str = "?",
        color: Tuple[int, int, int] = (255, 255, 255),
        name: str = "&lt;Unnamed&gt;",
        ai_cls: Type[BaseAI],
        fighter: Fighter,
        inventory: Inventory,
        <span class="new-text">level: Level,</span>
    ):
        super().__init__(
            x=x,
            y=y,
            char=char,
            color=color,
            name=name,
            blocks_movement=True,
            render_order=RenderOrder.ACTOR,
        )

        self.ai: Optional[BaseAI] = ai_cls(self)

        self.fighter = fighter
        self.fighter.parent = self

        self.inventory = inventory
        self.inventory.parent = self

        <span class="new-text">self.level = level
        self.level.parent = self</span>

    @property
    def is_alive(self) -> bool:
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Let's also modify our entities in `entity_factories.py` now:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from components.ai import HostileEnemy
from components import consumable
from components.fighter import Fighter
from components.inventory import Inventory
+from components.level import Level
from entity import Actor, Item


player = Actor(
    char="@",
    color=(255, 255, 255),
    name="Player",
    ai_cls=HostileEnemy,
    fighter=Fighter(hp=30, defense=2, power=5),
    inventory=Inventory(capacity=26),
+   level=Level(level_up_base=200),
)

orc = Actor(
    char="o",
    color=(63, 127, 63),
    name="Orc",
    ai_cls=HostileEnemy,
    fighter=Fighter(hp=10, defense=0, power=3),
    inventory=Inventory(capacity=0),
+   level=Level(xp_given=35),
)
troll = Actor(
    char="T",
    color=(0, 127, 0),
    name="Troll",
    ai_cls=HostileEnemy,
    fighter=Fighter(hp=16, defense=1, power=4),
    inventory=Inventory(capacity=0),
+   level=Level(xp_given=100),
)
...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from components.ai import HostileEnemy
from components import consumable
from components.fighter import Fighter
from components.inventory import Inventory
<span class="new-text">from components.level import Level</span>
from entity import Actor, Item


player = Actor(
    char="@",
    color=(255, 255, 255),
    name="Player",
    ai_cls=HostileEnemy,
    fighter=Fighter(hp=30, defense=2, power=5),
    inventory=Inventory(capacity=26),
    <span class="new-text">level=Level(level_up_base=200),</span>
)

orc = Actor(
    char="o",
    color=(63, 127, 63),
    name="Orc",
    ai_cls=HostileEnemy,
    fighter=Fighter(hp=10, defense=0, power=3),
    inventory=Inventory(capacity=0),
    <span class="new-text">level=Level(xp_given=35),</span>
)
troll = Actor(
    char="T",
    color=(0, 127, 0),
    name="Troll",
    ai_cls=HostileEnemy,
    fighter=Fighter(hp=16, defense=1, power=4),
    inventory=Inventory(capacity=0),
    <span class="new-text">level=Level(xp_given=100),</span>
)
...</pre>
{{</ original-tab >}}
{{</ codetab >}}

As mentioned, the `level_up_base` for the player is set to 200. Orcs give 35 XP, and Trolls give 100, since they're stronger. These values are completely arbitrary, so feel free to adjust them in any way you see fit.

When an enemy dies, we need to give the player XP. This is as simple as adding one line to the `Fighter` component, so open up `fighter.py` and add this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class Fighter(BaseComponent):
    def die(self) -> None:
        ...

        self.engine.message_log.add_message(death_message, death_message_color)
 
+       self.engine.player.level.add_xp(self.parent.level.xp_given)

    def heal(self, amount: int) -> int:
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class Fighter(BaseComponent):
    def die(self) -> None:
        ...

        self.engine.message_log.add_message(death_message, death_message_color)
 
        <span class="new-text">self.engine.player.level.add_xp(self.parent.level.xp_given)</span>

    def heal(self, amount: int) -> int:
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Now the player will gain XP for defeating enemies!

While the player does gain XP now, notice that we haven't actually _called_ the functions that increase the player's stats and levels the player up. We'll need a new interface to do this. The way it will work is that as soon as the player gets enough experience to level up, we'll display a message to the player, giving the player three choices on what stat to increase. When chosen, the appropriate function will be called, and the message will close.

Let's create a new event handler, called `LevelUpEventHandler`, that will do just that. Create the following class in `input_handlers.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class AskUserEventHandler(EventHandler):
    ...

+class LevelUpEventHandler(AskUserEventHandler):
+   TITLE = "Level Up"

+   def on_render(self, console: tcod.Console) -> None:
+       super().on_render(console)

+       if self.engine.player.x <= 30:
+           x = 40
+       else:
+           x = 0

+       console.draw_frame(
+           x=x,
+           y=0,
+           width=35,
+           height=8,
+           title=self.TITLE,
+           clear=True,
+           fg=(255, 255, 255),
+           bg=(0, 0, 0),
+       )

+       console.print(x=x + 1, y=1, string="Congratulations! You level up!")
+       console.print(x=x + 1, y=2, string="Select an attribute to increase.")

+       console.print(
+           x=x + 1,
+           y=4,
+           string=f"a) Constitution (+20 HP, from {self.engine.player.fighter.max_hp})",
+       )
+       console.print(
+           x=x + 1,
+           y=5,
+           string=f"b) Strength (+1 attack, from {self.engine.player.fighter.power})",
+       )
+       console.print(
+           x=x + 1,
+           y=6,
+           string=f"c) Agility (+1 defense, from {self.engine.player.fighter.defense})",
+       )

+   def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[ActionOrHandler]:
+       player = self.engine.player
+       key = event.sym
+       index = key - tcod.event.K_a

+       if 0 <= index <= 2:
+           if index == 0:
+               player.level.increase_max_hp()
+           elif index == 1:
+               player.level.increase_power()
+           else:
+               player.level.increase_defense()
+       else:
+           self.engine.message_log.add_message("Invalid entry.", color.invalid)

+           return None

+       return super().ev_keydown(event)

+   def ev_mousebuttondown(
+       self, event: tcod.event.MouseButtonDown
+   ) -> Optional[ActionOrHandler]:
+       """
+       Don't allow the player to click to exit the menu, like normal.
+       """
+       return None


class InventoryEventHandler(AskUserEventHandler):
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class AskUserEventHandler(EventHandler):
    ...

<span class="new-text">class LevelUpEventHandler(AskUserEventHandler):
    TITLE = "Level Up"

    def on_render(self, console: tcod.Console) -> None:
        super().on_render(console)

        if self.engine.player.x <= 30:
            x = 40
        else:
            x = 0

        console.draw_frame(
            x=x,
            y=0,
            width=35,
            height=8,
            title=self.TITLE,
            clear=True,
            fg=(255, 255, 255),
            bg=(0, 0, 0),
        )

        console.print(x=x + 1, y=1, string="Congratulations! You level up!")
        console.print(x=x + 1, y=2, string="Select an attribute to increase.")

        console.print(
            x=x + 1,
            y=4,
            string=f"a) Constitution (+20 HP, from {self.engine.player.fighter.max_hp})",
        )
        console.print(
            x=x + 1,
            y=5,
            string=f"b) Strength (+1 attack, from {self.engine.player.fighter.power})",
        )
        console.print(
            x=x + 1,
            y=6,
            string=f"c) Agility (+1 defense, from {self.engine.player.fighter.defense})",
        )

    def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[ActionOrHandler]:
        player = self.engine.player
        key = event.sym
        index = key - tcod.event.K_a

        if 0 <= index <= 2:
            if index == 0:
                player.level.increase_max_hp()
            elif index == 1:
                player.level.increase_power()
            else:
                player.level.increase_defense()
        else:
            self.engine.message_log.add_message("Invalid entry.", color.invalid)

            return None

        return super().ev_keydown(event)
        
    def ev_mousebuttondown(
        self, event: tcod.event.MouseButtonDown
    ) -> Optional[ActionOrHandler]:
        """
        Don't allow the player to click to exit the menu, like normal.
        """
        return None</span>


class InventoryEventHandler(AskUserEventHandler):
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

The idea here is very similar to `InventoryEventHandler` (it inherits from the same `AskUserEventHandler` class), but instead of having a variable number of options, it's set to three, one for each of the primary attributes. Furthermore, there's no way to exit this menu without selecting something. The user __must__ level up before continuing. (Notice, we had to override `ev_mousebutton` to prevent clicks from closing the menu.)

Using `LevelUpEventHandler` is actually quite simple: We can check when the player requires a level up at the same time when we check if the player is still alive. Edit the `handle_events` method of `EventHandler` like this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
            if not self.engine.player.is_alive:
                # The player was killed sometime during or after the action.
                return GameOverEventHandler(self.engine)
+           elif self.engine.player.level.requires_level_up:
+               return LevelUpEventHandler(self.engine)
            return MainGameEventHandler(self.engine)  # Return to the main handler.
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>            if not self.engine.player.is_alive:
                # The player was killed sometime during or after the action.
                return GameOverEventHandler(self.engine)
            <span class="new-text">elif self.engine.player.level.requires_level_up:
                return LevelUpEventHandler(self.engine)</span>
            return MainGameEventHandler(self.engine)  # Return to the main handler.</pre>
{{</ original-tab >}}
{{</ codetab >}}

Now, when the player gains the necessary number of experience points, the player will have the chance to level up!

![Part 11 - Level Up](/images/part-11-level-up.png)

Before finishing this chapter, there's one last quick thing we can do to improve the user experience: Add a "character information" screen, which displays the player's stats and current experience. It's actually quite simple. Add the following class to `input_handlers.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class AskUserEventHandler(EventHandler):
    ...

+class CharacterScreenEventHandler(AskUserEventHandler):
+   TITLE = "Character Information"

+   def on_render(self, console: tcod.Console) -> None:
+       super().on_render(console)

+       if self.engine.player.x <= 30:
+           x = 40
+       else:
+           x = 0

+       y = 0

+       width = len(self.TITLE) + 4

+       console.draw_frame(
+           x=x,
+           y=y,
+           width=width,
+           height=7,
+           title=self.TITLE,
+           clear=True,
+           fg=(255, 255, 255),
+           bg=(0, 0, 0),
+       )

+       console.print(
+           x=x + 1, y=y + 1, string=f"Level: {self.engine.player.level.current_level}"
+       )
+       console.print(
+           x=x + 1, y=y + 2, string=f"XP: {self.engine.player.level.current_xp}"
+       )
+       console.print(
+           x=x + 1,
+           y=y + 3,
+           string=f"XP for next Level: {self.engine.player.level.experience_to_next_level}",
+       )

+       console.print(
+           x=x + 1, y=y + 4, string=f"Attack: {self.engine.player.fighter.power}"
+       )
+       console.print(
+           x=x + 1, y=y + 5, string=f"Defense: {self.engine.player.fighter.defense}"
+       )

class LevelUpEventHandler(AskUserEventHandler):
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class AskUserEventHandler(EventHandler):
    ...

<span class="new-text">class CharacterScreenEventHandler(AskUserEventHandler):
    TITLE = "Character Information"

    def on_render(self, console: tcod.Console) -> None:
        super().on_render(console)

        if self.engine.player.x <= 30:
            x = 40
        else:
            x = 0

        y = 0

        width = len(self.TITLE) + 4

        console.draw_frame(
            x=x,
            y=y,
            width=width,
            height=7,
            title=self.TITLE,
            clear=True,
            fg=(255, 255, 255),
            bg=(0, 0, 0),
        )

        console.print(
            x=x + 1, y=y + 1, string=f"Level: {self.engine.player.level.current_level}"
        )
        console.print(
            x=x + 1, y=y + 2, string=f"XP: {self.engine.player.level.current_xp}"
        )
        console.print(
            x=x + 1,
            y=y + 3,
            string=f"XP for next Level: {self.engine.player.level.experience_to_next_level}",
        )

        console.print(
            x=x + 1, y=y + 4, string=f"Attack: {self.engine.player.fighter.power}"
        )
        console.print(
            x=x + 1, y=y + 5, string=f"Defense: {self.engine.player.fighter.defense}"
        )</span>

class LevelUpEventHandler(AskUserEventHandler):
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Similar to `LevelUpEventHandler`, `CharacterScreenEventHandler` shows information in a window, but there's no real "choices" to be made here. Any input will simply close the screen.

To open the screen, we'll have the player press the `c` key. Add the following to `MainGameEventHandler`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
        elif key == tcod.event.K_d:
            return InventoryDropHandler(self.engine)
+       elif key == tcod.event.K_c:
+           return CharacterScreenEventHandler(self.engine)
        elif key == tcod.event.K_SLASH:
            return LookHandler(self.engine)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>        elif key == tcod.event.K_d:
            return InventoryDropHandler(self.engine)
        <span class="new-text">elif key == tcod.event.K_c:
            return CharacterScreenEventHandler(self.engine)</span>
        elif key == tcod.event.K_SLASH:
            return LookHandler(self.engine)</pre>
{{</ original-tab >}}
{{</ codetab >}}

![Part 11 - Character Screen](/images/part-11-character-screen.png)

That's it for this chapter. We've added the ability to go down floors, and to level up. While the player can now "progress", the environment itself doesn't. The items that spawn on each floor are always the same, and the enemies don't get tougher as we go down floors. The next part will address that.

If you want to see the code so far in its entirety, [click here](https://github.com/TStand90/tcod_tutorial_v2/tree/part-11).

[Click here to move on to the next part of this tutorial.](/tutorials/tcod/v2/part-12)
