---
title: "Part 11 - Delving into the Dungeon"
date: 2020-07-21
draft: true
---

Our game isn’t much of a “dungeon crawler” if there’s only one floor to our dungeon. In this chapter, we’ll allow the player to go down a level, and we’ll put a very basic leveling up system in place, to make the dive all the more rewarding.

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


`fighter.py`

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class Fighter(BaseComponent):
    def die(self) -> None:
        ...

        self.engine.message_log.add_message(death_message, death_message_color)
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
        self.engine.message_log.add_message(death_message, death_message_color)
 
        <span class="new-text">self.engine.player.level.add_xp(self.parent.level.xp_given)</span>

    def heal(self, amount: int) -> int:
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}


`engine.py`

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
    from entity import Actor
-   from game_map import GameMap
+   from game_map import GameMap, GameWorld
 
 
class Engine:
    game_map: GameMap
+   game_world: GameWorld
 
    def __init__(self, player: Actor):
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
    from entity import Actor
    <span class="crossed-out-text">from game_map import GameMap</span>
    <span class="new-text">from game_map import GameMap, GameWorld</span>
 
 
class Engine:
    game_map: GameMap
    <span class="new-text">game_world: GameWorld</span>
 
    def __init__(self, player: Actor):
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


`entity.py`

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
if TYPE_CHECKING:
    from components.consumable import Consumable
    from components.fighter import Fighter
    from components.inventory import Inventory
+   from components.level import Level
    from game_map import GameMap
 
T = TypeVar("T", bound="Entity")
@@ -94,6 +95,7 @@ class Actor(Entity):
        ai_cls: Type[BaseAI],
        fighter: Fighter,
        inventory: Inventory,
+       level: Level,
    ):
        super().__init__(
            x=x,
@@ -113,6 +115,9 @@ class Actor(Entity):
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
<pre></pre>
{{</ original-tab >}}
{{</ codetab >}}


`entity_factories.py`


{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from components.ai import HostileEnemy
from components import consumable
from components.fighter import Fighter
from components.inventory import Inventory
+from components.level import Level
from entity import Actor, Item
 
 
@@ -12,6 +13,7 @@ player = Actor(
    ai_cls=HostileEnemy,
    fighter=Fighter(hp=30, defense=2, power=5),
    inventory=Inventory(capacity=26),
+   level=Level(level_up_base=200),
)
 
orc = Actor(
@@ -21,6 +23,7 @@ orc = Actor(
    ai_cls=HostileEnemy,
    fighter=Fighter(hp=10, defense=0, power=3),
    inventory=Inventory(capacity=0),
+   level=Level(xp_given=35),
)
troll = Actor(
    char="T",
@@ -29,6 +32,7 @@ troll = Actor(
    ai_cls=HostileEnemy,
    fighter=Fighter(hp=16, defense=1, power=4),
    inventory=Inventory(capacity=0),
+   level=Level(xp_given=100),
)
 
confusion_scroll = Item(
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre></pre>
{{</ original-tab >}}
{{</ codetab >}}

`input_handlers.py`


`procgen.py`

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


`render_functions.py`

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

`setup_game.py`

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
+from game_map import GameWorld
import input_handlers
-from procgen import generate_dungeon
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
