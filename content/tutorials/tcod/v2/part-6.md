---
title: "Part 6 - Doing (and taking) some damage"
date: 2020-07-07
draft: false
---

## Check your TCOD installation

Before proceeding any further, you'll want to upgrade to TCOD version 11.15, if you don't already have it. This version of TCOD was released *during* the tutorial event, so if you're following along on a weekly basis, you probably *don't* have this version installed!

## Refactoring previous code

After parts 1-5 for this tutorial were written, we decided to change a few things around, to hopefully make the codebase a bit cleaner and easier to extend in the future. Unfortunately, this means that code written in previous parts now has to be modified.

I would go back and edit the tutorial text and Github branches to reflect these changes, except for two things:

1. I don't have time at the moment. Writing the sections that get published every week is taking all of my time as it is.
2. It wouldn't be fair to those who are following this tutorial on a weekly basis.

Someday, when the event is over, the previous parts will be rewritten, and all will be well. But until then, there's several changes that need to be made before proceeding with Part 6.

I won't explain all of the changes (again, time is a limiting factor), but here's the basic ideas:

* Event handlers will have the `handle_events` method instead of `Engine`.
* The game map will have a reference to `Engine`, and entities will have a reference to the map.
* Actions will be initialized with the entity doing the action
* Because of the above points, Actions will have a reference to the `Engine`, through `Entity`->`GameMap`->`Engine`

Make the changes to each file, and when you're finished, verify the project works as it did before.

`input_handlers.py`

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
+from __future__ import annotations

-from typing import Optional
+from typing import Optional, TYPE_CHECKING

import tcod.event

from actions import Action, BumpAction, EscapeAction

+if TYPE_CHECKING:
+   from engine import Engine


class EventHandler(tcod.event.EventDispatch[Action]):
+   def __init__(self, engine: Engine):
+       self.engine = engine

+   def handle_events(self) -> None:
+       for event in tcod.event.wait():
+           action = self.dispatch(event)

+           if action is None:
+               continue

+           action.perform()

+           self.engine.handle_enemy_turns()
+           self.engine.update_fov()  # Update the FOV before the players next action.


    def ev_quit(self, event: tcod.event.Quit) -> Optional[Action]:
        ...
    
    def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[Action]:
        action: Optional[Action] = None

        key = event.sym

+       player = self.engine.player

        if key == tcod.event.K_UP:
-           action = BumpAction(dx=0, dy=-1)
+           action = BumpAction(player, dx=0, dy=-1)
        elif key == tcod.event.K_DOWN:
-           action = BumpAction(dx=0, dy=1)
+           action = BumpAction(player, dx=0, dy=1)
        elif key == tcod.event.K_LEFT:
-           action = BumpAction(dx=-1, dy=0)
+           action = BumpAction(player, dx=-1, dy=0)
        elif key == tcod.event.K_RIGHT:
-           action = BumpAction(dx=1, dy=0)
+           action = BumpAction(player, dx=1, dy=0)

        elif key == tcod.event.K_ESCAPE:
-           action = EscapeAction()
+           action = EscapeAction(player)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre><span class="new-text">from __future__ import annotations</span>

<span class="crossed-out-text">from typing import Optional</span>
<span class="new-text">from typing import Optional, TYPE_CHECKING</span>

import tcod.event

from actions import Action, BumpAction, EscapeAction

<span class="new-text">if TYPE_CHECKING:
    from engine import Engine</span>


class EventHandler(tcod.event.EventDispatch[Action]):
    <span class="new-text">def __init__(self, engine: Engine):
        self.engine = engine

    def handle_events(self) -> None:
        for event in tcod.event.wait():
            action = self.dispatch(event)

            if action is None:
                continue

            action.perform()

            self.engine.handle_enemy_turns()
            self.engine.update_fov()  # Update the FOV before the players next action.</span>


    def ev_quit(self, event: tcod.event.Quit) -> Optional[Action]:
        ...
    
    def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[Action]:
        action: Optional[Action] = None

        key = event.sym

        <span class="new-text">player = self.engine.player</span>

        if key == tcod.event.K_UP:
            <span class="crossed-out-text">action = BumpAction(dx=0, dy=-1)</span>
            <span class="new-text">action = BumpAction(player, dx=0, dy=-1)</span>
        elif key == tcod.event.K_DOWN:
            <span class="crossed-out-text">action = BumpAction(dx=0, dy=1)</span>
            <span class="new-text">action = BumpAction(player, dx=0, dy=1)</span>
        elif key == tcod.event.K_LEFT:
            <span class="crossed-out-text">action = BumpAction(dx=-1, dy=0)</span>
            <span class="new-text">action = BumpAction(player, dx=-1, dy=0)</span>
        elif key == tcod.event.K_RIGHT:
            <span class="crossed-out-text">action = BumpAction(dx=1, dy=0)</span>
            <span class="new-text">action = BumpAction(player, dx=1, dy=0)</span>

        elif key == tcod.event.K_ESCAPE:
            <span class="crossed-out-text">action = EscapeAction()</span>
            <span class="new-text">action = EscapeAction(player)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

`actions.py`

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from __future__ import annotations

+from typing import Optional, Tuple, TYPE_CHECKING
-from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from engine import Engine
    from entity import Entity


class Action:
+   def __init__(self, entity: Entity) -> None:
+       super().__init__()
+       self.entity = entity

+   @property
+   def engine(self) -> Engine:
+       """Return the engine this action belongs to."""
+       return self.entity.gamemap.engine

+   def perform(self) -> None:
-   def perform(self, engine: Engine, entity: Entity) -> None:
        """Perform this action with the objects needed to determine its scope.

+       `self.engine` is the scope this action is being performed in.
-       `engine` is the scope this action is being performed in.

+       `self.entity` is the object performing the action.
-       `entity` is the object performing the action.

        This method must be overridden by Action subclasses.
        """
        raise NotImplementedError()


class EscapeAction(Action):
+   def perform(self) -> None:
-   def perform(self, engine: Engine, entity: Entity) -> None:
        raise SystemExit()



class ActionWithDirection(Action):
+   def __init__(self, entity: Entity, dx: int, dy: int):
+       super().__init__(entity)
-   def __init__(self, dx: int, dy: int):
-       super().__init__()

        self.dx = dx
        self.dy = dy

+   @property
+   def dest_xy(self) -> Tuple[int, int]:
+       """Returns this actions destination."""
+       return self.entity.x + self.dx, self.entity.y + self.dy

+   @property
+   def blocking_entity(self) -> Optional[Entity]:
+       """Return the blocking entity at this actions destination.."""
+       return self.engine.game_map.get_blocking_entity_at_location(*self.dest_xy)

+   def perform(self) -> None:
-   def perform(self, engine: Engine, entity: Entity) -> None:
        raise NotImplementedError()


class MeleeAction(ActionWithDirection):
+   def perform(self) -> None:
+       target = self.blocking_entity
-   def perform(self, engine: Engine, entity: Entity) -> None:
-       dest_x = entity.x + self.dx
-       dest_y = entity.y + self.dy
-       target = engine.game_map.get_blocking_entity_at_location(dest_x, dest_y)
        if not target:
            return  # No entity to attack.

        print(f"You kick the {target.name}, much to its annoyance!")


class MovementAction(ActionWithDirection):
+   def perform(self) -> None:
+       dest_x, dest_y = self.dest_xy
-   def perform(self, engine: Engine, entity: Entity) -> None:
-       dest_x = entity.x + self.dx
-       dest_y = entity.y + self.dy
 
+       if not self.engine.game_map.in_bounds(dest_x, dest_y):
-       if not engine.game_map.in_bounds(dest_x, dest_y):
            return  # Destination is out of bounds.
+       if not self.engine.game_map.tiles["walkable"][dest_x, dest_y]:
-       if not engine.game_map.tiles["walkable"][dest_x, dest_y]:
            return  # Destination is blocked by a tile.
+       if self.engine.game_map.get_blocking_entity_at_location(dest_x, dest_y):
-       if engine.game_map.get_blocking_entity_at_location(dest_x, dest_y):
            return  # Destination is blocked by an entity.
 
+       self.entity.move(self.dx, self.dy)
-       entity.move(self.dx, self.dy)


class BumpAction(ActionWithDirection):
+   def perform(self) -> None:
+       if self.blocking_entity:
+           return MeleeAction(self.entity, self.dx, self.dy).perform()
-   def perform(self, engine: Engine, entity: Entity) -> None:
-       dest_x = entity.x + self.dx
-       dest_y = entity.y + self.dy

-       if engine.game_map.get_blocking_entity_at_location(dest_x, dest_y):
-           return MeleeAction(self.dx, self.dy).perform(engine, entity)
 
        else:
+           return MovementAction(self.entity, self.dx, self.dy).perform()
-           return MovementAction(self.dx, self.dy).perform(engine, entity)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from __future__ import annotations

<span class="new-text">from typing import Optional, Tuple, TYPE_CHECKING</span>
<span class="crossed-out-text">from typing import TYPE_CHECKING</span>

if TYPE_CHECKING:
    from engine import Engine
    from entity import Entity


class Action:
    <span class="new-text">def __init__(self, entity: Entity) -> None:
        super().__init__()
        self.entity = entity

    @property
    def engine(self) -> Engine:
        """Return the engine this action belongs to."""
        return self.entity.gamemap.engine

    def perform(self) -> None:</span>
    <span class="crossed-out-text">def perform(self, engine: Engine, entity: Entity) -> None:</span>
        """Perform this action with the objects needed to determine its scope.

        <span class="new-text">`self.engine` is the scope this action is being performed in.</span>
        <span class="crossed-out-text">`engine` is the scope this action is being performed in.</span>

        <span class="new-text">`self.entity` is the object performing the action.</span>
        <span class="crossed-out-text">`entity` is the object performing the action.</span>

        This method must be overridden by Action subclasses.
        """
        raise NotImplementedError()


class EscapeAction(Action):
    <span class="new-text">def perform(self) -> None:</span>
    <span class="crossed-out-text">def perform(self, engine: Engine, entity: Entity) -> None:</span>
        raise SystemExit()



class ActionWithDirection(Action):
    <span class="new-text">def __init__(self, entity: Entity, dx: int, dy: int):
        super().__init__(entity)</span>
    <span class="crossed-out-text">def __init__(self, dx: int, dy: int):</span>
        <span class="crossed-out-text">super().__init__()</span>

        self.dx = dx
        self.dy = dy

    <span class="new-text">@property
    def dest_xy(self) -> Tuple[int, int]:
        """Returns this actions destination."""
        return self.entity.x + self.dx, self.entity.y + self.dy

    @property
    def blocking_entity(self) -> Optional[Entity]:
        """Return the blocking entity at this actions destination.."""
        return self.engine.game_map.get_blocking_entity_at_location(*self.dest_xy)

    def perform(self) -> None:</span>
    <span class="crossed-out-text">def perform(self, engine: Engine, entity: Entity) -> None:</span>
        raise NotImplementedError()


class MeleeAction(ActionWithDirection):
    <span class="new-text">def perform(self) -> None:
        target = self.blocking_entity</span>
    <span class="crossed-out-text">def perform(self, engine: Engine, entity: Entity) -> None:</span>
        <span class="crossed-out-text">dest_x = entity.x + self.dx</span>
        <span class="crossed-out-text">dest_y = entity.y + self.dy</span>
        <span class="crossed-out-text">target = engine.game_map.get_blocking_entity_at_location(dest_x, dest_y)</span>
        if not target:
            return  # No entity to attack.

        print(f"You kick the {target.name}, much to its annoyance!")


class MovementAction(ActionWithDirection):
    <span class="new-text">def perform(self) -> None:
        dest_x, dest_y = self.dest_xy</span>
    <span class="crossed-out-text">def perform(self, engine: Engine, entity: Entity) -> None:</span>
        <span class="crossed-out-text">dest_x = entity.x + self.dx</span>
        <span class="crossed-out-text">dest_y = entity.y + self.dy</span>
 
        <span class="new-text">if not self.engine.game_map.in_bounds(dest_x, dest_y):</span>
        <span class="crossed-out-text">if not engine.game_map.in_bounds(dest_x, dest_y):</span>
            return  # Destination is out of bounds.
        <span class="new-text">if not self.engine.game_map.tiles["walkable"][dest_x, dest_y]:</span>
        <span class="crossed-out-text">if not engine.game_map.tiles["walkable"][dest_x, dest_y]:</span>
            return  # Destination is blocked by a tile.
        <span class="new-text">if self.engine.game_map.get_blocking_entity_at_location(dest_x, dest_y):</span>
        <span class="crossed-out-text">if engine.game_map.get_blocking_entity_at_location(dest_x, dest_y):</span>
            return  # Destination is blocked by an entity.
 
        <span class="new-text">self.entity.move(self.dx, self.dy)</span>
        <span class="crossed-out-text">entity.move(self.dx, self.dy)</span>


class BumpAction(ActionWithDirection):
    <span class="new-text">def perform(self) -> None:
        if self.blocking_entity:
            return MeleeAction(self.entity, self.dx, self.dy).perform()</span>
    <span class="crossed-out-text">def perform(self, engine: Engine, entity: Entity) -> None:</span>
        <span class="crossed-out-text">dest_x = entity.x + self.dx</span>
        <span class="crossed-out-text">dest_y = entity.y + self.dy</span>

        <span class="crossed-out-text">if engine.game_map.get_blocking_entity_at_location(dest_x, dest_y):</span>
            <span class="crossed-out-text">return MeleeAction(self.dx, self.dy).perform(engine, entity)</span>
 
        else:
            <span class="new-text">return MovementAction(self.entity, self.dx, self.dy).perform()</span>
            <span class="crossed-out-text">return MovementAction(self.dx, self.dy).perform(engine, entity)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

`game_map.py`

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from __future__ import annotations

from typing import Iterable, Optional, TYPE_CHECKING
 
import numpy as np  # type: ignore
from tcod.console import Console
 
import tile_types
 
if TYPE_CHECKING:
+   from engine import Engine
    from entity import Entity


class GameMap:
-   def __init__(self, width: int, height: int, entities: Iterable[Entity] = ()):
+   def __init__(
+       self, engine: Engine, width: int, height: int, entities: Iterable[Entity] = ()
+   ):
+       self.engine = engine
        self.width, self.height = width, height
        self.entities = set(entities)
        self.tiles = np.full((width, height), fill_value=tile_types.wall, order="F")
 
-       self.visible = np.full((width, height), fill_value=False, order="F")  # Tiles the player can currently see
+       self.visible = np.full(
+           (width, height), fill_value=False, order="F"
+       )  # Tiles the player can currently see
-       self.explored = np.full((width, height), fill_value=False, order="F")  # Tiles the player has seen before
+       self.explored = np.full(
+           (width, height), fill_value=False, order="F"
+       )  # Tiles the player has seen before
 
-   def get_blocking_entity_at_location(self, location_x: int, location_y: int) -> Optional[Entity]:
+   def get_blocking_entity_at_location(
+       self, location_x: int, location_y: int,
+   ) -> Optional[Entity]:
        for entity in self.entities:
-           if entity.blocks_movement and entity.x == location_x and entity.y == location_y:
+           if (
+               entity.blocks_movement
+               and entity.x == location_x
+               and entity.y == location_y
+           ):
                return entity
 
        return None

    def in_bounds(self, x: int, y: int) -> bool:
        """Return True if x and y are inside of the bounds of this map."""
        return 0 <= x < self.width and 0 <= y < self.height

    def render(self, console: Console) -> None:
        """
        Renders the map.

        If a tile is in the "visible" array, then draw it with the "light" colors.
        If it isn't, but it's in the "explored" array, then draw it with the "dark" colors.
        Otherwise, the default is "SHROUD".
        """
-       console.tiles_rgb[0:self.width, 0:self.height] = np.select(
+       console.tiles_rgb[0 : self.width, 0 : self.height] = np.select(
            condlist=[self.visible, self.explored],
            choicelist=[self.tiles["light"], self.tiles["dark"]],
-           default=tile_types.SHROUD
+           default=tile_types.SHROUD,
        )
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from __future__ import annotations

from typing import Iterable, Optional, TYPE_CHECKING
 
import numpy as np  # type: ignore
from tcod.console import Console
 
import tile_types
 
if TYPE_CHECKING:
    <span class="new-text">from engine import Engine</span>
    from entity import Entity


class GameMap:
    <span class="crossed-out-text">def __init__(self, width: int, height: int, entities: Iterable[Entity] = ()):</span>
    <span class="new-text">def __init__(
        self, engine: Engine, width: int, height: int, entities: Iterable[Entity] = ()
    ):
        self.engine = engine</span>
        self.width, self.height = width, height
        self.entities = set(entities)
        self.tiles = np.full((width, height), fill_value=tile_types.wall, order="F")
 
        <span class="crossed-out-text">self.visible = np.full((width, height), fill_value=False, order="F")  # Tiles the player can currently see</span>
        <span class="new-text">self.visible = np.full(
            (width, height), fill_value=False, order="F"
        )  # Tiles the player can currently see</span>
        <span class="crossed-out-text">self.explored = np.full((width, height), fill_value=False, order="F")  # Tiles the player has seen before</span>
        <span class="new-text">self.explored = np.full(
            (width, height), fill_value=False, order="F"
        )  # Tiles the player has seen before</span>
 
    <span class="crossed-out-text">def get_blocking_entity_at_location(self, location_x: int, location_y: int) -> Optional[Entity]:</span>
    <span class="new-text">def get_blocking_entity_at_location(
        self, location_x: int, location_y: int,
    ) -> Optional[Entity]:</span>
        for entity in self.entities:
            <span class="crossed-out-text">if entity.blocks_movement and entity.x == location_x and entity.y == location_y:</span>
            <span class="new-text">if (
                entity.blocks_movement
                and entity.x == location_x
                and entity.y == location_y
            ):</span>
                return entity
 
        return None

    def in_bounds(self, x: int, y: int) -> bool:
        """Return True if x and y are inside of the bounds of this map."""
        return 0 <= x < self.width and 0 <= y < self.height

    def render(self, console: Console) -> None:
        """
        Renders the map.

        If a tile is in the "visible" array, then draw it with the "light" colors.
        If it isn't, but it's in the "explored" array, then draw it with the "dark" colors.
        Otherwise, the default is "SHROUD".
        """
        <span class="crossed-out-text">console.tiles_rgb[0:self.width, 0:self.height] = np.select(</span>
        <span class="new-text">console.tiles_rgb[0 : self.width, 0 : self.height] = np.select(</span>
            condlist=[self.visible, self.explored],
            choicelist=[self.tiles["light"], self.tiles["dark"]],
            <span class="crossed-out-text">default=tile_types.SHROUD</span>
            <span class="new-text">default=tile_types.SHROUD,</span>
        )</pre>
{{</ original-tab >}}
{{</ codetab >}}

`main.py`

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
#!/usr/bin/env python3
import copy

import tcod
 
from engine import Engine
import entity_factories
-from input_handlers import EventHandler
from procgen import generate_dungeon

    ...
+   player = copy.deepcopy(entity_factories.player)
-   event_handler = EventHandler()
 
+   engine = Engine(player=player)
-   player = copy.deepcopy(entity_factories.player)
 
+   engine.game_map = generate_dungeon(
-   game_map = generate_dungeon(
        max_rooms=max_rooms,
        room_min_size=room_min_size,
        room_max_size=room_max_size,
        map_width=map_width,
        map_height=map_height,
        max_monsters_per_room=max_monsters_per_room,
+       engine=engine,
-       player=player,
    )
+   engine.update_fov()

-   engine = Engine(event_handler=event_handler, game_map=game_map, player=player)
 
    with tcod.context.new_terminal(
        ...
        while True:
            engine.render(console=root_console, context=context)
 
+           engine.event_handler.handle_events()
-           events = tcod.event.wait()

-           engine.handle_events(events)


if __name__ == "__main__":
    main()

{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>#!/usr/bin/env python3
import copy

import tcod
 
from engine import Engine
import entity_factories
<span class="crossed-out-text">from input_handlers import EventHandler</span>
from procgen import generate_dungeon

    ...
    <span class="new-text">player = copy.deepcopy(entity_factories.player)</span>
    <span class="crossed-out-text">event_handler = EventHandler()</span>
 
    <span class="new-text">engine = Engine(player=player)</span>
    <span class="crossed-out-text">player = copy.deepcopy(entity_factories.player)</span>
 
    <span class="new-text">engine.game_map = generate_dungeon(</span>
    <span class="crossed-out-text">game_map = generate_dungeon(</span>
        max_rooms=max_rooms,
        room_min_size=room_min_size,
        room_max_size=room_max_size,
        map_width=map_width,
        map_height=map_height,
        max_monsters_per_room=max_monsters_per_room,
        <span class="new-text">engine=engine,</span>
        <span class="crossed-out-text">player=player,</span>
    )
    <span class="new-text">engine.update_fov()</span>

    <span class="crossed-out-text">engine = Engine(event_handler=event_handler, game_map=game_map, player=player)</span>
 
    with tcod.context.new_terminal(
        ...
        while True:
            engine.render(console=root_console, context=context)
 
            <span class="new-text">engine.event_handler.handle_events()</span>
            <span class="crossed-out-text">events = tcod.event.wait()</span>

            <span class="crossed-out-text">engine.handle_events(events)</span>


if __name__ == "__main__":
    main()</pre>
{{</ original-tab >}}
{{</ codetab >}}

`entity.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from __future__ import annotations

import copy
-from typing import Tuple, TypeVar, TYPE_CHECKING
+from typing import Optional, Tuple, TypeVar, TYPE_CHECKING

if TYPE_CHECKING:
    from game_map import GameMap

T = TypeVar("T", bound="Entity")


class Entity:
    """
    A generic object to represent players, enemies, items, etc.
    """
 
+   gamemap: GameMap

    def __init__(
        self,
+       gamemap: Optional[GameMap] = None,
        x: int = 0,
        y: int = 0,
        char: str = "?",
        color: Tuple[int, int, int] = (255, 255, 255),
        name: str = "<Unnamed>",
        blocks_movement: bool = False,
    ):
        self.x = x
        self.y = y
        self.char = char
        self.color = color
        self.name = name
        self.blocks_movement = blocks_movement
+       if gamemap:
+           # If gamemap isn't provided now then it will be set later.
+           self.gamemap = gamemap
+           gamemap.entities.add(self)
 
    def spawn(self: T, gamemap: GameMap, x: int, y: int) -> T:
        """Spawn a copy of this instance at the given location."""
        clone = copy.deepcopy(self)
        clone.x = x
        clone.y = y
+       clone.gamemap = gamemap
        gamemap.entities.add(clone)
        return clone
    
+   def place(self, x: int, y: int, gamemap: Optional[GameMap] = None) -> None:
+       """Place this entity at a new location.  Handles moving across GameMaps."""
+       self.x = x
+       self.y = y
+       if gamemap:
+           if hasattr(self, "gamemap"):  # Possibly uninitialized.
+               self.gamemap.entities.remove(self)
+           self.gamemap = gamemap
+           gamemap.entities.add(self)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from __future__ import annotations

import copy
<span class="crossed-out-text">from typing import Tuple, TypeVar, TYPE_CHECKING</span>
<span class="new-text">from typing import Optional, Tuple, TypeVar, TYPE_CHECKING</span>

if TYPE_CHECKING:
    from game_map import GameMap

T = TypeVar("T", bound="Entity")


class Entity:
    """
    A generic object to represent players, enemies, items, etc.
    """
 
    <span class="new-text">gamemap: GameMap</span>

    def __init__(
        self,
        <span class="new-text">gamemap: Optional[GameMap] = None,</span>
        x: int = 0,
        y: int = 0,
        char: str = "?",
        color: Tuple[int, int, int] = (255, 255, 255),
        name: str = "&lt;Unnamed&gt;",
        blocks_movement: bool = False,
    ):
        self.x = x
        self.y = y
        self.char = char
        self.color = color
        self.name = name
        self.blocks_movement = blocks_movement
        <span class="new-text">if gamemap:
            # If gamemap isn't provided now then it will be set later.
            self.gamemap = gamemap
            gamemap.entities.add(self)</span>
 
    def spawn(self: T, gamemap: GameMap, x: int, y: int) -> T:
        """Spawn a copy of this instance at the given location."""
        clone = copy.deepcopy(self)
        clone.x = x
        clone.y = y
        <span class="new-text">clone.gamemap = gamemap</span>
        gamemap.entities.add(clone)
        return clone
    
    <span class="new-text">def place(self, x: int, y: int, gamemap: Optional[GameMap] = None) -> None:
        """Place this entity at a new location.  Handles moving across GameMaps."""
        self.x = x
        self.y = y
        if gamemap:
            if hasattr(self, "gamemap"):  # Possibly uninitialized.
                self.gamemap.entities.remove(self)
            self.gamemap = gamemap
            gamemap.entities.add(self)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

`procgen.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
import tile_types
 
 
if TYPE_CHECKING:
+   from engine import Engine
-   from entity import Entity

...
def generate_dungeon(
    max_rooms: int,
    room_min_size: int,
    room_max_size: int,
    map_width: int,
    map_height: int,
    max_monsters_per_room: int,
+   engine: Engine,
-   player: Entity,
) -> GameMap:
    """Generate a new dungeon map."""
+   player = engine.player
+   dungeon = GameMap(engine, map_width, map_height, entities=[player])
-   dungeon = GameMap(map_width, map_height, entities=[player])
 
    rooms: List[RectangularRoom] = []
    ...
 
        ...
        if len(rooms) == 0:
            # The first room, where the player starts.
+           player.place(*new_room.center, dungeon)
-           player.x, player.y = new_room.center
        else:  # All rooms after the first.
            ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>import tile_types
 
 
if TYPE_CHECKING:
    <span class="new-text">from engine import Engine</span>
    <span class="crossed-out-text">from entity import Entity</span>

...
def generate_dungeon(
    max_rooms: int,
    room_min_size: int,
    room_max_size: int,
    map_width: int,
    map_height: int,
    max_monsters_per_room: int,
    <span class="new-text">engine: Engine,</span>
    <span class="crossed-out-text">player: Entity,</span>
) -> GameMap:
    """Generate a new dungeon map."""
    <span class="new-text">player = engine.player</span>
    <span class="new-text">dungeon = GameMap(engine, map_width, map_height, entities=[player])</span>
    <span class="crossed-out-text">dungeon = GameMap(map_width, map_height, entities=[player])</span>
 
    rooms: List[RectangularRoom] = []
    ...
 
        ...
        if len(rooms) == 0:
            # The first room, where the player starts.
            <span class="new-text">player.place(*new_room.center, dungeon)</span>
            <span class="crossed-out-text">player.x, player.y = new_room.center</span>
        else:  # All rooms after the first.
            ...</pre>
{{</ original-tab >}}
{{</ codetab >}}


`engine.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
+from __future__ import annotations

+from typing import TYPE_CHECKING
-from typing import Iterable, Any
 
from tcod.context import Context
from tcod.console import Console
from tcod.map import compute_fov

-from entity import Entity
-from game_map import GameMap
from input_handlers import EventHandler
 
+if TYPE_CHECKING:
+   from entity import Entity
+   from game_map import GameMap
 
 
class Engine:
+   game_map: GameMap
 
+   def __init__(self, player: Entity):
+       self.event_handler: EventHandler = EventHandler(self)
+       self.player = player
-   def __init__(self, event_handler: EventHandler, game_map: GameMap, player: Entity):
-       self.event_handler = event_handler
-       self.game_map = game_map
-       self.player = player
-       self.update_fov()
 
    def handle_enemy_turns(self) -> None:
        for entity in self.game_map.entities - {self.player}:
            print(f'The {entity.name} wonders when it will get to take a real turn.')

-   def handle_events(self, events: Iterable[Any]) -> None:
-       for event in events:
-           action = self.event_handler.dispatch(event)

-           if action is None:
-               continue

-           action.perform(self, self.player)
-           self.handle_enemy_turns()
-           self.update_fov()  # Update the FOV before the players next action.
 
    def update_fov(self) -> None:
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre><span class="new-text">from __future__ import annotations</span>

<span class="new-text">from typing import TYPE_CHECKING</span>
<span class="crossed-out-text">from typing import Iterable, Any</span>
 
from tcod.context import Context
from tcod.console import Console
from tcod.map import compute_fov

<span class="crossed-out-text">from entity import Entity</span>
<span class="crossed-out-text">from game_map import GameMap</span>
from input_handlers import EventHandler
 
<span class="new-text">if TYPE_CHECKING:
    from entity import Entity
    from game_map import GameMap</span>
 
 
class Engine:
    <span class="new-text">game_map: GameMap</span>
 
    <span class="new-text">def __init__(self, player: Entity):
        self.event_handler: EventHandler = EventHandler(self)
        self.player = player</span>
    <span class="crossed-out-text">def __init__(self, event_handler: EventHandler, game_map: GameMap, player: Entity):</span>
        <span class="crossed-out-text">self.event_handler = event_handler</span>
        <span class="crossed-out-text">self.game_map = game_map</span>
        <span class="crossed-out-text">self.player = player</span>
        <span class="crossed-out-text">self.update_fov()</span>
 
    def handle_enemy_turns(self) -> None:
        for entity in self.game_map.entities - {self.player}:
            print(f'The {entity.name} wonders when it will get to take a real turn.')

    <span class="crossed-out-text">def handle_events(self, events: Iterable[Any]) -> None:</span>
        <span class="crossed-out-text">for event in events:</span>
            <span class="crossed-out-text">action = self.event_handler.dispatch(event)</span>

            <span class="crossed-out-text">if action is None:</span>
                <span class="crossed-out-text">continue</span>

            <span class="crossed-out-text">action.perform(self, self.player)</span>
            <span class="crossed-out-text">self.handle_enemy_turns()</span>
            <span class="crossed-out-text">self.update_fov()  # Update the FOV before the players next action.</span>
 
    def update_fov(self) -> None:
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

## Onwards to Part 6

The last part of this tutorial set us up for combat, so now it's time to actually implement it.

In order to make "killable" Entities, rather than attaching hit points to each Entity we create, we'll create a **component**, called `Fighter`, which will hold information related to combat, like HP, max HP, attack, and defense. If an Entity can fight, it will have this component attached to it, and if not, it won't. This way of doing things is called **composition**, and it's an alternative to your typical inheritance-based programming model. (This tutorial uses both composition *and* inheritance).

Create a new Python package (a folder with an empty \_\_init\_\_.py file), called `components`. In that new directory, add two new files, one called `base_component.py`, and another called `fighter.py`. The `Fighter` class in `fighter.py` will inherit from the class we put in `base_component.py`, so let's start with that one:

```py3
from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from engine import Engine
    from entity import Entity


class BaseComponent:
    entity: Entity  # Owning entity instance.

    @property
    def engine(self) -> Engine:
        return self.entity.gamemap.engine
```


With that, let's now open up `fighter.py` and put the following into it:

```py3
from components.base_component import BaseComponent


class Fighter(BaseComponent):
    def __init__(self, hp: int, defense: int, power: int):
        self.max_hp = hp
        self._hp = hp
        self.defense = defense
        self.power = power

    @property
    def hp(self) -> int:
        return self._hp

    @hp.setter
    def hp(self, value: int) -> None:
        self._hp = max(0, min(value, self.max_hp))
```

We import and inherit from `BaseComponent`, which gives us access to the parent entity and the engine, which will be useful later on.

The `__init__` function takes a few arguments. `hp` represents the entity's hit points. `defense` is how much taken damage will be reduced. `power` is the entity's raw attack power.

What's with the `hp` property? We define both a getter and setter, which will allow the class to access `hp` like a normal variable. The getter (the one with the `@property` thing above the method) doesn't do anything special: it just returns the HP. The `setter` (`@hp.setter`) is where things get more interesting.

By defining HP this way, we can modify the value as it's set within the method. This line:

```py3
        self._hp = max(0, min(value, self.max_hp))
```

Means that `_hp` (which we access through `hp`) will never be set to less than 0, but also won't ever go higher than the `max_hp` attribute.

So that's our `Fighter` component. It won't do us much good at the moment, because the entities in our game still don't move or do much of anything (besides the player, anyway). To give some life to our entities, we can add another component, which, when attached to our entities, will allow them to take turns and move around.

Create a file in the `components` directory called `ai.py`, and put the following contents into it:

```py3
from __future__ import annotations

from typing import List, Tuple

import numpy as np  # type: ignore
import tcod

from actions import Action
from components.base_component import BaseComponent


class BaseAI(Action, BaseComponent):
    def perform(self) -> None:
        raise NotImplementedError()

    def get_path_to(self, dest_x: int, dest_y: int) -> List[Tuple[int, int]]:
        """Compute and return a path to the target position.

        If there is no valid path then returns an empty list.
        """
        # Copy the walkable array.
        cost = np.array(self.entity.gamemap.tiles["walkable"], dtype=np.int8)

        for entity in self.entity.gamemap.entities:
            # Check that an enitiy blocks movement and the cost isn't zero (blocking.)
            if entity.blocks_movement and cost[entity.x, entity.y]:
                # Add to the cost of a blocked position.
                # A lower number means more enemies will crowd behind each other in
                # hallways.  A higher number means enemies will take longer paths in
                # order to surround the player.
                cost[entity.x, entity.y] += 10

        # Create a graph from the cost array and pass that graph to a new pathfinder.
        graph = tcod.path.SimpleGraph(cost=cost, cardinal=2, diagonal=3)
        pathfinder = tcod.path.Pathfinder(graph)

        pathfinder.add_root((self.entity.x, self.entity.y))  # Start position.

        # Compute the path to the destination and remove the starting point.
        path: List[List[int]] = pathfinder.path_to((dest_x, dest_y))[1:].tolist()

        # Convert from List[List[int]] to List[Tuple[int, int]].
        return [(index[0], index[1]) for index in path]
```

`BaseAI` doesn't implement a `perform` method, since the entities which will be using AI to act will have to have an AI class that inherits from this one.

`get_path_to` uses the "walkable" tiles in our map, along with some TCOD pathfinding tools to get the path from the `BaseAI`'s parent entity to whatever their target might be. In the case of this tutorial, the target will always be the player, though you could theoretically write a monster that cares more about food or treasure than attacking the player.

The pathfinder first builds an array of `cost`, which is how "costly" (time consuming) it will take to get to the target. If a piece of terrain takes longer to traverse, its cost will be higher. In the case of our simple game, all parts of the map have the same cost, but what this cost array allows us to do is take other entities into account.

How? Well, if an entity exists at a spot on the map, we increase the cost of moving there to "10". What this does is encourages the entity to move around the entity that's blocking them from their target. Higher values will cause the entity to take a longer path around; shorter values will cause groups to gather into crowds, since they don't want to move around.

More information about TCOD's pathfinding can be [found here](https://python-tcod.readthedocs.io/en/latest/tcod/path.html).

To make use of our new `Fighter` and `AI` components, we could attach them directly onto the `Entity` class. However, it might be useful to differentiate between entities that can act, and those that can't. Right now, our game only consists of acting entities, but soon enough, we'll be adding things like consumable items and, eventually, equipment, which won't be able to take turns or take damage.

One way to handle this is to create a new subclass of `Entity`, called `Actor`, and give it all the same attributes as `Entity`, plus the `ai` and `fighter` components it will need. Modify `entity.py` like this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from __future__ import annotations

import copy
-from typing import Tuple, TypeVar, TYPE_CHECKING
+from typing import Optional, Tuple, Type, TypeVar, TYPE_CHECKING


if TYPE_CHECKING:
+   from components.ai import BaseAI
+   from components.fighter import Fighter
    from game_map import GameMap

T = TypeVar("T", bound="Entity")


class Entity:
    ...


+class Actor(Entity):
+   def __init__(
+       self,
+       *,
+       x: int = 0,
+       y: int = 0,
+       char: str = "?",
+       color: Tuple[int, int, int] = (255, 255, 255),
+       name: str = "<Unnamed>",
+       ai_cls: Type[BaseAI],
+       fighter: Fighter
+   ):
+       super().__init__(
+           x=x,
+           y=y,
+           char=char,
+           color=color,
+           name=name,
+           blocks_movement=True,
+       )

+       self.ai: Optional[BaseAI] = ai_cls(self)

+       self.fighter = fighter
+       self.fighter.entity = self

+   @property
+   def is_alive(self) -> bool:
+       """Returns True as long as this actor can perform actions."""
+       return bool(self.ai)

{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from __future__ import annotations

import copy
<span class="crossed-out-text">from typing import Tuple, TypeVar, TYPE_CHECKING</span>
<span class="new-text">from typing import Optional, Tuple, Type, TypeVar, TYPE_CHECKING</span>


if TYPE_CHECKING:
    <span class="new-text">from components.ai import BaseAI
    from components.fighter import Fighter</span>
    from game_map import GameMap

T = TypeVar("T", bound="Entity")


class Entity:
    ...


<span class="new-text">class Actor(Entity):
    def __init__(
        self,
        *,
        x: int = 0,
        y: int = 0,
        char: str = "?",
        color: Tuple[int, int, int] = (255, 255, 255),
        name: str = "&lt;Unnamed&gt;",
        ai_cls: Type[BaseAI],
        fighter: Fighter
    ):
        super().__init__(
            x=x,
            y=y,
            char=char,
            color=color,
            name=name,
            blocks_movement=True,
        )

        self.ai: Optional[BaseAI] = ai_cls(self)

        self.fighter = fighter
        self.fighter.entity = self

    @property
    def is_alive(self) -> bool:
        """Returns True as long as this actor can perform actions."""
        return bool(self.ai)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

The first thing our `Actor` class does in its `__init__()` function is call its superclass's `__init__()`, which in this case, is the `Entity` class. We're passing `blocks_movement` as `True` every time, because we can assume that all the "actors" will block movement.

Besides calling the `Entity.__init__()`, we also set the two components for the `Actor` class: `ai` and `fighter`. The idea is that each actor will need two things to function: the ability to move around and make decisions, and the ability to take (and receive) damage.

This new `Actor` class isn't quite enough to get our enemies up and moving around, but we're getting there. We actually need to revisit `ai.py`, and add a new class there to handle hostile enemies. Enter the following changes in `ai.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from __future__ import annotations

-from typing import List, Tuple
+from typing import List, Tuple, TYPE_CHECKING

import numpy as np  # type: ignore
import tcod

-from actions import Action
+from actions import Action, MeleeAction, MovementAction, WaitAction
from components.base_component import BaseComponent

+if TYPE_CHECKING:
+   from entity import Actor


class BaseAI(Action, BaseComponent):
+   entity: Actor

    def perform(self) -> None:
        ...


+class HostileEnemy(BaseAI):
+   def __init__(self, entity: Actor):
+       super().__init__(entity)
+       self.path: List[Tuple[int, int]] = []

+   def perform(self) -> None:
+       target = self.engine.player
+       dx = target.x - self.entity.x
+       dy = target.y - self.entity.y
+       distance = max(abs(dx), abs(dy))  # Chebyshev distance.

+       if self.engine.game_map.visible[self.entity.x, self.entity.y]:
+           if distance <= 1:
+               return MeleeAction(self.entity, dx, dy).perform()

+           self.path = self.get_path_to(target.x, target.y)

+       if self.path:
+           dest_x, dest_y = self.path.pop(0)
+           return MovementAction(
+               self.entity, dest_x - self.entity.x, dest_y - self.entity.y,
+           ).perform()

+       return WaitAction(self.entity).perform()
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from __future__ import annotations

<span class="crossed-out-text">from typing import List, Tuple</span>
<span class="new-text">from typing import List, Tuple, TYPE_CHECKING</span>

import numpy as np  # type: ignore
import tcod

<span class="crossed-out-text">from actions import Action</span>
<span class="new-text">from actions import Action, MeleeAction, MovementAction, WaitAction</span>
from components.base_component import BaseComponent

<span class="new-text">if TYPE_CHECKING:
    from entity import Actor</span>


class BaseAI(Action, BaseComponent):
    <span class="new-text">entity: Actor</span>

    def perform(self) -> None:
        ...


<span class="new-text">class HostileEnemy(BaseAI):
    def __init__(self, entity: Actor):
        super().__init__(entity)
        self.path: List[Tuple[int, int]] = []

    def perform(self) -> None:
        target = self.engine.player
        dx = target.x - self.entity.x
        dy = target.y - self.entity.y
        distance = max(abs(dx), abs(dy))  # Chebyshev distance.

        if self.engine.game_map.visible[self.entity.x, self.entity.y]:
            if distance <= 1:
                return MeleeAction(self.entity, dx, dy).perform()

            self.path = self.get_path_to(target.x, target.y)

        if self.path:
            dest_x, dest_y = self.path.pop(0)
            return MovementAction(
                self.entity, dest_x - self.entity.x, dest_y - self.entity.y,
            ).perform()

        return WaitAction(self.entity).perform()</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

`HostileEnemy` is the AI class we'll use for our enemies. It defines the `perform` method, which does the following:

* If the entity is not in the player's vision, simply wait.
* If the player is right next to the entity (`distance <= 1`), attack the player.
* If the player can see the entity, but the entity is too far away to attack, then move towards the player.

The last line actually calls an action that we haven't defined yet: `WaitAction`. This action will be used when the player or an enemy decides to wait where they are rather than taking a turn.

Implement `WaitAction` by opening `actions.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class EscapeAction(Action):
    ...


+class WaitAction(Action):
+   def perform(self) -> None:
+       pass


class ActionWithDirection(Action):
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class EscapeAction(Action):
    ...


<span class="new-text">class WaitAction(Action):
    def perform(self) -> None:
        pass</span>


class ActionWithDirection(Action):
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

As you can see, `WaitAction` does... well, nothing. And that's what we want it to do, as it represents an actor saying "I'll do nothing this turn."

With all that in place, we'll need to refactor our `entity_factories.py` file to make use of the new `Actor` class, as well as its components. Modify `entity_factories.py` to look like this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
+from components.ai import HostileEnemy
+from components.fighter import Fighter
+from entity import Actor
-from entity import Entity
 
+player = Actor(
+   char="@",
+   color=(255, 255, 255),
+   name="Player",
+   ai_cls=HostileEnemy,
+   fighter=Fighter(hp=30, defense=2, power=5),
+)
-player = Entity(char="@", color=(255, 255, 255), name="Player", blocks_movement=True)
 
+orc = Actor(
+   char="o",
+   color=(63, 127, 63),
+   name="Orc",
+   ai_cls=HostileEnemy,
+   fighter=Fighter(hp=10, defense=0, power=3),
+)
+troll = Actor(
+   char="T",
+   color=(0, 127, 0),
+   name="Troll",
+   ai_cls=HostileEnemy,
+   fighter=Fighter(hp=16, defense=1, power=4),
+)
-orc = Entity(char="o", color=(63, 127, 63), name="Orc", blocks_movement=True)
-troll = Entity(char="T", color=(0, 127, 0), name="Troll", blocks_movement=True)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre><span class="new-text">from components.ai import HostileEnemy
from components.fighter import Fighter
from entity import Actor</span>
<span class="crossed-out-text">from entity import Entity</span>
 
<span class="new-text">player = Actor(
    char="@",
    color=(255, 255, 255),
    name="Player",
    ai_cls=HostileEnemy,
    fighter=Fighter(hp=30, defense=2, power=5),
)</span>
<span class="crossed-out-text">player = Entity(char="@", color=(255, 255, 255), name="Player", blocks_movement=True)</span>
 
<span class="new-text">orc = Actor(
    char="o",
    color=(63, 127, 63),
    name="Orc",
    ai_cls=HostileEnemy,
    fighter=Fighter(hp=10, defense=0, power=3),
)
troll = Actor(
    char="T",
    color=(0, 127, 0),
    name="Troll",
    ai_cls=HostileEnemy,
    fighter=Fighter(hp=16, defense=1, power=4),
)</span>
<span class="crossed-out-text">orc = Entity(char="o", color=(63, 127, 63), name="Orc", blocks_movement=True)</span>
<span class="crossed-out-text">troll = Entity(char="T", color=(0, 127, 0), name="Troll", blocks_movement=True)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

We've changed each entity to make use of the `Actor` class, and used the `HostileEnemy` AI class for the Orc and the Troll types, while using the `BaseAI` for our player. Also, we defined the `Fighter` component for each, giving a few different values to make the Trolls stronger than the Orcs. Feel free to modify these values to your liking.

How do enemies actually take their turns, though? It's actually pretty simple: rather than printing the message we were before, we just check if the entity has an AI, and if it does, we call the `perform` method from that AI component. Modify `engine.py` to do this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
    def handle_enemy_turns(self) -> None:
+       for entity in set(self.game_map.actors) - {self.player}:
+           if entity.ai:
+               entity.ai.perform()
-       for entity in self.game_map.entities - {self.player}:
-           print(f'The {entity.name} wonders when it will get to take a real turn.')
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>    def handle_enemy_turns(self) -> None:
        <span class="new-text">for entity in set(self.game_map.actors) - {self.player}:
            if entity.ai:
                entity.ai.perform()</span>
        <span class="crossed-out-text">for entity in self.game_map.entities - {self.player}:</span>
            <span class="crossed-out-text">print(f'The {entity.name} wonders when it will get to take a real turn.')</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

But wait, `game_map.actors` isn't defined. What should it do, though? Same thing as `game_map.entities`, except it should return only the `Actor` entities.

Let's add this method to `GameMap`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from __future__ import annotations

-from typing import Iterable, Optional, TYPE_CHECKING
+from typing import Iterable, Iterator, Optional, TYPE_CHECKING

import numpy as np  # type: ignore
from tcod.console import Console

+from entity import Actor
import tile_types

if TYPE_CHECKING:
    from engine import Engine
    from entity import Entity

class GameMap:
    def __init__(
        ...
    
+   @property
+   def actors(self) -> Iterator[Actor]:
+       """Iterate over this maps living actors."""
+       yield from (
+           entity
+           for entity in self.entities
+           if isinstance(entity, Actor) and entity.is_alive
+       )
    
    def get_blocking_entity_at_location(
        ...
    
+   def get_actor_at_location(self, x: int, y: int) -> Optional[Actor]:
+       for actor in self.actors:
+           if actor.x == x and actor.y == y:
+               return actor

+       return None
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from __future__ import annotations

<span class="crossed-out-text">from typing import Iterable, Optional, TYPE_CHECKING</span>
<span class="new-text">from typing import Iterable, Iterator, Optional, TYPE_CHECKING</span>

import numpy as np  # type: ignore
from tcod.console import Console

<span class="new-text">from entity import Actor</span>
import tile_types

if TYPE_CHECKING:
    from engine import Engine
    from entity import Entity

class GameMap:
    def __init__(
        ...
    
    <span class="new-text">@property
    def actors(self) -> Iterator[Actor]:
        """Iterate over this maps living actors."""
        yield from (
            entity
            for entity in self.entities
            if isinstance(entity, Actor) and entity.is_alive
        )</span>
    
    def get_blocking_entity_at_location(
        ...
    
    <span class="new-text">def get_actor_at_location(self, x: int, y: int) -> Optional[Actor]:
        for actor in self.actors:
            if actor.x == x and actor.y == y:
                return actor

        return None</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Our `actors` property will return all the `Actor` entities in the map, but only those that are currently "alive".

We've also went ahead and added a `get_actor_at_location`, which, as the name implies, acts similarly to `get_blocking_entity_at_location`, but returns only an `Actor`. This will come in handy later on.

Run the project now, and the enemies should chase you around! They can't really attack just yet, but we're getting there.

![Part 6 - The Chase](/images/part-6-chase.png)

One thing you might have noticed is that we're letting our enemies move and attack in diagonal directions, but our player can only move in the four cardinal directions (up, down, left, right). We can fix that by adjusting `input_handlers.py`. While we're at it, we might want to define a more flexible way of defining the movement keys rather than the `if...elif` structure we've used so far. While that does work, it gets a bit clunky after more than just a few options. We can fix this by modifying `input_handlers.py` like this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from __future__ import annotations

from typing import Optional, TYPE_CHECKING

import tcod.event

-from actions import Action, BumpAction, EscapeAction
+from actions import Action, BumpAction, EscapeAction, WaitAction

if TYPE_CHECKING:
    from engine import Engine


+MOVE_KEYS = {
+   # Arrow keys.
+   tcod.event.K_UP: (0, -1),
+   tcod.event.K_DOWN: (0, 1),
+   tcod.event.K_LEFT: (-1, 0),
+   tcod.event.K_RIGHT: (1, 0),
+   tcod.event.K_HOME: (-1, -1),
+   tcod.event.K_END: (-1, 1),
+   tcod.event.K_PAGEUP: (1, -1),
+   tcod.event.K_PAGEDOWN: (1, 1),
+   # Numpad keys.
+   tcod.event.K_KP_1: (-1, 1),
+   tcod.event.K_KP_2: (0, 1),
+   tcod.event.K_KP_3: (1, 1),
+   tcod.event.K_KP_4: (-1, 0),
+   tcod.event.K_KP_6: (1, 0),
+   tcod.event.K_KP_7: (-1, -1),
+   tcod.event.K_KP_8: (0, -1),
+   tcod.event.K_KP_9: (1, -1),
+   # Vi keys.
+   tcod.event.K_h: (-1, 0),
+   tcod.event.K_j: (0, 1),
+   tcod.event.K_k: (0, -1),
+   tcod.event.K_l: (1, 0),
+   tcod.event.K_y: (-1, -1),
+   tcod.event.K_u: (1, -1),
+   tcod.event.K_b: (-1, 1),
+   tcod.event.K_n: (1, 1),
+}

+WAIT_KEYS = {
+   tcod.event.K_PERIOD,
+   tcod.event.K_KP_5,
+   tcod.event.K_CLEAR,
+}


        ...

-       if key == tcod.event.K_UP:
-           action = BumpAction(dx=0, dy=-1)
-       elif key == tcod.event.K_DOWN:
-           action = BumpAction(dx=0, dy=1)
-       elif key == tcod.event.K_LEFT:
-           action = BumpAction(dx=-1, dy=0)
-       elif key == tcod.event.K_RIGHT:
-           action = BumpAction(dx=1, dy=0)
+       if key in MOVE_KEYS:
+           dx, dy = MOVE_KEYS[key]
+           action = BumpAction(player, dx, dy)
+       elif key in WAIT_KEYS:
+           action = WaitAction(player)

        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from __future__ import annotations

from typing import Optional, TYPE_CHECKING

import tcod.event

<span class="crossed-out-text">from actions import Action, BumpAction, EscapeAction</span>
<span class="new-text">from actions import Action, BumpAction, EscapeAction, WaitAction</span>

if TYPE_CHECKING:
    from engine import Engine


<span class="new-text">MOVE_KEYS = {
    # Arrow keys.
    tcod.event.K_UP: (0, -1),
    tcod.event.K_DOWN: (0, 1),
    tcod.event.K_LEFT: (-1, 0),
    tcod.event.K_RIGHT: (1, 0),
    tcod.event.K_HOME: (-1, -1),
    tcod.event.K_END: (-1, 1),
    tcod.event.K_PAGEUP: (1, -1),
    tcod.event.K_PAGEDOWN: (1, 1),
    # Numpad keys.
    tcod.event.K_KP_1: (-1, 1),
    tcod.event.K_KP_2: (0, 1),
    tcod.event.K_KP_3: (1, 1),
    tcod.event.K_KP_4: (-1, 0),
    tcod.event.K_KP_6: (1, 0),
    tcod.event.K_KP_7: (-1, -1),
    tcod.event.K_KP_8: (0, -1),
    tcod.event.K_KP_9: (1, -1),
    # Vi keys.
    tcod.event.K_h: (-1, 0),
    tcod.event.K_j: (0, 1),
    tcod.event.K_k: (0, -1),
    tcod.event.K_l: (1, 0),
    tcod.event.K_y: (-1, -1),
    tcod.event.K_u: (1, -1),
    tcod.event.K_b: (-1, 1),
    tcod.event.K_n: (1, 1),
}

WAIT_KEYS = {
    tcod.event.K_PERIOD,
    tcod.event.K_KP_5,
    tcod.event.K_CLEAR,
}</span>


        ...

        <span class="crossed-out-text">if key == tcod.event.K_UP:</span>
            <span class="crossed-out-text">action = BumpAction(player, dx=0, dy=-1)</span>
        <span class="crossed-out-text">elif key == tcod.event.K_DOWN:</span>
            <span class="crossed-out-text">action = BumpAction(player, dx=0, dy=1)</span>
        <span class="crossed-out-text">elif key == tcod.event.K_LEFT:</span>
            <span class="crossed-out-text">action = BumpAction(player, dx=-1, dy=0)</span>
        <span class="crossed-out-text">elif key == tcod.event.K_RIGHT:</span>
            <span class="crossed-out-text">action = BumpAction(player, dx=1, dy=0)</span>
        <span class="new-text">if key in MOVE_KEYS:
            dx, dy = MOVE_KEYS[key]
            action = BumpAction(player, dx, dy)
        elif key in WAIT_KEYS:
            action = WaitAction(player)</span>

        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

The `MOVE_KEYS` dictionary holds various different possibilities for movement. Some roguelikes utilize the numpad for movement, some use "Vi Keys." Ours will actually use both for the time being. Feel free to change the key scheme if you're not a fan of it.

Where we used to do `if...elif` statements for each direction, we can now just check if the key was part of `MOVE_KEYS`, and if it was, we return the `dx` and `dy` values from the dictionary. This is a lot simpler and cleaner than our previous format.

So now that our enemies can chase us down, it's time to make them do some real damage.

Open up `actions.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from __future__ import annotations

from typing import Optional, Tuple, TYPE_CHECKING

if TYPE_CHECKING:
    from engine import Engine
-   from entity import Entity
+   from entity import Actor, Entity


class Action:
-   def __init__(self, entity: Entity) -> None:
+   def __init__(self, entity: Actor) -> None:
        super().__init__()
        self.entity = entity

    ...


class ActionWithDirection(Action):
-   def __init__(self, entity: Entity, dx: int, dy: int):
+   def __init__(self, entity: Actor, dx: int, dy: int):
        super().__init__(entity)

        self.dx = dx
        self.dy = dy
    
    @property
    def dest_xy(self) -> Tuple[int, int]:
        """Returns this actions destination."""
        return self.entity.x + self.dx, self.entity.y + self.dy

    @property
    def blocking_entity(self) -> Optional[Entity]:
        """Return the blocking entity at this actions destination.."""
        return self.engine.game_map.get_blocking_entity_at_location(*self.dest_xy)
    
+   @property
+   def target_actor(self) -> Optional[Actor]:
+       """Return the actor at this actions destination."""
+       return self.engine.game_map.get_actor_at_location(*self.dest_xy)

    def perform(self) -> None:
        raise NotImplementedError()


class MeleeAction(ActionWithDirection):
    def perform(self) -> None:
+       target = self.target_actor
-       target = self.blocking_entity
        if not target:
            return  # No entity to attack.
 
+       damage = self.entity.fighter.power - target.fighter.defense

+       attack_desc = f"{self.entity.name.capitalize()} attacks {target.name}"
+       if damage > 0:
+           print(f"{attack_desc} for {damage} hit points.")
+           target.fighter.hp -= damage
+       else:
+           print(f"{attack_desc} but does no damage.")
-       print(f"You kick the {target.name}, much to its annoyance!")


class MovementAction(ActionWithDirection):
    ...


class BumpAction(ActionWithDirection):
    def perform(self) -> None:
-       if self.blocking_entity:
+       if self.target_actor:
            return MeleeAction(self.entity, self.dx, self.dy).perform()

        else:
            return MovementAction(self.entity, self.dx, self.dy).perform()
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from __future__ import annotations

from typing import Optional, Tuple, TYPE_CHECKING

if TYPE_CHECKING:
    from engine import Engine
    <span class="crossed-out-text">from entity import Entity</span>
    <span class="new-text">from entity import Actor, Entity</span>


class Action:
    <span class="crossed-out-text">def __init__(self, entity: Entity) -> None:</span>
    <span class="new-text">def __init__(self, entity: Actor) -> None:</span>
        super().__init__()
        self.entity = entity

    ...


class ActionWithDirection(Action):
    <span class="crossed-out-text">def __init__(self, entity: Entity, dx: int, dy: int):</span>
    <span class="new-text">def __init__(self, entity: Actor, dx: int, dy: int):</span>
        super().__init__(entity)

        self.dx = dx
        self.dy = dy
    
    @property
    def dest_xy(self) -> Tuple[int, int]:
        """Returns this actions destination."""
        return self.entity.x + self.dx, self.entity.y + self.dy

    @property
    def blocking_entity(self) -> Optional[Entity]:
        """Return the blocking entity at this actions destination.."""
        return self.engine.game_map.get_blocking_entity_at_location(*self.dest_xy)
    
    <span class="new-text">@property
    def target_actor(self) -> Optional[Actor]:
        """Return the actor at this actions destination."""
        return self.engine.game_map.get_actor_at_location(*self.dest_xy)</span>

    def perform(self) -> None:
        raise NotImplementedError()


class MeleeAction(ActionWithDirection):
    def perform(self) -> None:
        <span class="new-text">target = self.target_actor</span>
        <span class="crossed-out-text">target = self.blocking_entity</span>
        if not target:
            return  # No entity to attack.
 
        <span class="new-text">damage = self.entity.fighter.power - target.fighter.defense

        attack_desc = f"{self.entity.name.capitalize()} attacks {target.name}"
        if damage > 0:
            print(f"{attack_desc} for {damage} hit points.")
            target.fighter.hp -= damage
        else:
            print(f"{attack_desc} but does no damage.")</span>
        <span class="crossed-out-text">print(f"You kick the {target.name}, much to its annoyance!")</span>


class MovementAction(ActionWithDirection):
    ...


class BumpAction(ActionWithDirection):
    def perform(self) -> None:
        <span class="crossed-out-text">if self.blocking_entity:</span>
        <span class="new-text">if self.target_actor:</span>
            return MeleeAction(self.entity, self.dx, self.dy).perform()

        else:
            return MovementAction(self.entity, self.dx, self.dy).perform()</pre>
{{</ original-tab >}}
{{</ codetab >}}

We're replacing the type hint for `entity` in `Action` and `ActionWithDirection` with `Actor` instead of `Entity`, since only `Actor`s should be taking actions.

We've also added the `target_actor` property to `ActionWithDirection`, which will give us the `Actor` at the destination we're moving to, if there is one. We utilize that property instead of `blocking_entity` in both `BumpAction` and `MeleeAction`.

Lastly, we modify `MeleeAction` to actually do an attack, instead of just printing a message. We calculate the damage (attacker's power minus defender's defense), and assign a description to the attack, based on whether any damage was done or not. If the damage is greater than 0, we subtract it from the defender's HP.

If you run the project now, you'll see the print statements indicating that the player and the enemies are doing damage to each other. But since neither side can actually die, combat doesn't feel all that high stakes just yet.

What do we do when an Entity reaches 0 HP or lower? Well, it should drop dead, obviously! But what should our *code* do to make this happen? To handle this, we can refer back to our `Fighter` component.

Remember when we created a setter for `hp`? It will come in handy right now, as we can utilize it to automatically "kill" the actor when their HP drops to zero. Add the following to `fighter.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
+from __future__ import annotations

+from typing import TYPE_CHECKING

from components.base_component import BaseComponent

+if TYPE_CHECKING:
+   from entity import Actor


class Fighter(BaseComponent):
+   entity: Actor

    def __init__(self, hp: int, defense: int, power: int):
        self.max_hp = hp
        self._hp = hp
        self.defense = defense
        self.power = power

    @property
    def hp(self) -> int:
        return self._hp

    @hp.setter
    def hp(self, value: int) -> None:
        self._hp = max(0, min(value, self.max_hp))
+       if self._hp == 0 and self.entity.ai:
+           self.die()

+   def die(self) -> None:
+       if self.engine.player is self.entity:
+           death_message = "You died!"
+       else:
+           death_message = f"{self.entity.name} is dead!"

+       self.entity.char = "%"
+       self.entity.color = (191, 0, 0)
+       self.entity.blocks_movement = False
+       self.entity.ai = None
+       self.entity.name = f"remains of {self.entity.name}"

+       print(death_message)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre><span class="new-text">from __future__ import annotations

from typing import TYPE_CHECKING</span>

from components.base_component import BaseComponent

<span class="new-text">if TYPE_CHECKING:
    from entity import Actor</span>


class Fighter(BaseComponent):
    <span class="new-text">entity: Actor</span>

    def __init__(self, hp: int, defense: int, power: int):
        self.max_hp = hp
        self._hp = hp
        self.defense = defense
        self.power = power

    @property
    def hp(self) -> int:
        return self._hp

    @hp.setter
    def hp(self, value: int) -> None:
        self._hp = max(0, min(value, self.max_hp))
        <span class="new-text">if self._hp == 0 and self.entity.ai:
            self.die()

    def die(self) -> None:
        if self.engine.player is self.entity:
            death_message = "You died!"
        else:
            death_message = f"{self.entity.name} is dead!"

        self.entity.char = "%"
        self.entity.color = (191, 0, 0)
        self.entity.blocks_movement = False
        self.entity.ai = None
        self.entity.name = f"remains of {self.entity.name}"

        print(death_message)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

When the actor dies, we use the `die` method to do several things:

* Print out a message, indicating the death of the entity
* Set the entity's character to "%" (most roguelikes use this for corpses)
* Set its color to red (for a bloody, gory mess)
* Set `blocks_movement` to `False`, so that the entities can walk over the corpse
* Remove the AI from the entity, so it'll be marked as dead and won't take any more turns.
* Change the name to "remains of {entity name}"

Run the project now, and enjoy slaughtering some Orcs and Trolls!

![Part 6 - Killing Enemies](/images/part-6-killing-enemies.png)

As satisfying as it would be to end here, our work is not quite done. If you play the game a bit, you'll notice two problems.

The first is that, sometimes, corpses actually cover up entities.

![Part 6 - Player under a Corpse](/images/part-6-player-under-corpse.png)

*The player is currently under the corpse in the screenshot.*

This not only makes no sense, since the entities should be walking *over* the corpses, but it can confuse the player rather easily.

The other issue is much more severe. Try playing the game and letting yourself die on purpose.

![Part 6 - Dead Player](/images/part-6-dead-player.png)

The player does indeed turn into a corpse, but... you can still move around, and even attack enemies! This is because the game doesn't really "end" at the moment when the player dies. The only thing that changes is that the player's AI component is set to `None`, but that isn't actually what controls the player, the `EventHandler` class does that.

Let's focus on the first issue first. Solving it is actually pretty easy. What we'll do is assign a value to each `Entity`, and this value will represent which order the entities should be rendered in. Lower values will be rendered first, and higher values will be rendered after. Therefore, if we assign a low value to a corpse, it will get drawn before an entity. If two things are on the same tile, whatever gets drawn last will be what the player sees.

To create the render values we'll need, create a new file, called `render_order.py`, and put the following class in it:

```py3
from enum import auto, Enum


class RenderOrder(Enum):
    CORPSE = auto()
    ITEM = auto()
    ACTOR = auto()
```

*Note: You'll need Python 3.6 or higher for the `auto` function to work.*

`RenderOrder` is an `Enum`. An "Enum" is a set of named values that won't change, so it's perfect for things like this. `auto` assigns incrementing integer values automatically, so we don't need to retype them if we add more values later on.

To use this new Enum, let's edit `entity.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from __future__ import annotations

import copy
from typing import Optional, Tuple, Type, TypeVar, TYPE_CHECKING

+from render_order import RenderOrder

if TYPE_CHECKING:
    from components.ai import BaseAI
    from components.fighter import Fighter
    from game_map import GameMap

T = TypeVar("T", bound="Entity")


class Entity:
    """
    A generic object to represent players, enemies, items, etc.
    """

    gamemap: GameMap

    def __init__(
        self,
        gamemap: Optional[GameMap] = None,
        x: int = 0,
        y: int = 0,
        char: str = "?",
        color: Tuple[int, int, int] = (255, 255, 255),
        name: str = "<Unnamed>",
        blocks_movement: bool = False,
+       render_order: RenderOrder = RenderOrder.CORPSE,
    ):
        self.x = x
        self.y = y
        self.char = char
        self.color = color
        self.name = name
        self.blocks_movement = blocks_movement
+       self.render_order = render_order
        if gamemap:
            # If gamemap isn't provided now then it will be set later.
            self.gamemap = gamemap
            gamemap.entities.add(self)
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
        fighter: Fighter
    ):
        super().__init__(
            x=x,
            y=y,
            char=char,
            color=color,
            name=name,
            blocks_movement=True,
+           render_order=RenderOrder.ACTOR,
        )
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from __future__ import annotations

import copy
from typing import Optional, Tuple, Type, TypeVar, TYPE_CHECKING

<span class="new-text">from render_order import RenderOrder</span>

if TYPE_CHECKING:
    from components.ai import BaseAI
    from components.fighter import Fighter
    from game_map import GameMap

T = TypeVar("T", bound="Entity")


class Entity:
    """
    A generic object to represent players, enemies, items, etc.
    """

    gamemap: GameMap

    def __init__(
        self,
        gamemap: Optional[GameMap] = None,
        x: int = 0,
        y: int = 0,
        char: str = "?",
        color: Tuple[int, int, int] = (255, 255, 255),
        name: str = "&lt;Unnamed&gt;",
        blocks_movement: bool = False,
        <span class="new-text">render_order: RenderOrder = RenderOrder.CORPSE,</span>
    ):
        self.x = x
        self.y = y
        self.char = char
        self.color = color
        self.name = name
        self.blocks_movement = blocks_movement
        <span class="new-text">self.render_order = render_order</span>
        if gamemap:
            # If gamemap isn't provided now then it will be set later.
            self.gamemap = gamemap
            gamemap.entities.add(self)
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
        fighter: Fighter
    ):
        super().__init__(
            x=x,
            y=y,
            char=char,
            color=color,
            name=name,
            blocks_movement=True,
            <span class="new-text">render_order=RenderOrder.ACTOR,</span>
        )</pre>
{{</ original-tab >}}
{{</ codetab >}}

We're now passing the render order to the `Entity` class, with a default of `CORPSE`. Notice that we don't pass it to `Actor`, and instead, assume that the actor's default will be the `ACTOR` value.

In order to actually take advantage of the rendering order, we'll need to modify the part of `GameMap` that renders the entities to the screen. Modify the `render` method in `GameMap` like this:
{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
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

+       entities_sorted_for_rendering = sorted(
+           self.entities, key=lambda x: x.render_order.value
+       )

-       for entity in self.entities:
+       for entity in entities_sorted_for_rendering:
            if self.visible[entity.x, entity.y]:
-               console.print(x=entity.x, y=entity.y, string=entity.char, fg=entity.color)
+               console.print(
+                   x=entity.x, y=entity.y, string=entity.char, fg=entity.color
+               )

{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>    ...
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

        <span class="new-text">entities_sorted_for_rendering = sorted(
            self.entities, key=lambda x: x.render_order.value
        )</span>

        <span class="crossed-out-text">for entity in self.entities:</span>
        <span class="new-text">for entity in entities_sorted_for_rendering:</span>
            if self.visible[entity.x, entity.y]:
                <span class="crossed-out-text">console.print(x=entity.x, y=entity.y, string=entity.char, fg=entity.color)</span>
                <span class="new-text">console.print(
                    x=entity.x, y=entity.y, string=entity.char, fg=entity.color
                )</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

The `sorted` function takes two arguments: The collection to sort, and the function used to sort it. By using `key` in `sorted`, we're defining a custom way to sort the `self.entities`, which in this case, we're using a `lambda` function (basically, a function that's limited to one line that we don't need to write a formal definition for). The lambda function itself tells `sorted` to sort by the value of `render_order`. Since the `RenderOrder` enum defines its order from 1 (Corpse, lowest) to 3 (Actor, highest), corpses should be sent to the front of the sorted list. That way, when rendering, they'll get drawn first, so if there's something else on top of them, they'll get overwritten, and we'll just see the `Actor` instead of the corpse.

Last thing we need to do is rewrite the `render_order` of an entity when it dies. Go back to the `Fighter` class and add the following:


{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from __future__ import annotations

from typing import TYPE_CHECKING

from components.base_component import BaseComponent
+from render_order import RenderOrder

if TYPE_CHECKING:
    from entity import Actor


class Fighter(BaseComponent):
    ...
        ...
        self.entity.ai = None
        self.entity.name = f"remains of {self.entity.name}"
+       self.entity.render_order = RenderOrder.CORPSE

        print(death_message)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from __future__ import annotations

from typing import TYPE_CHECKING

from components.base_component import BaseComponent
<span class="new-text">from render_order import RenderOrder</span>

if TYPE_CHECKING:
    from entity import Actor


class Fighter(BaseComponent):
    ...
        ...
        self.entity.ai = None
        self.entity.name = f"remains of {self.entity.name}"
        <span class="new-text">self.entity.render_order = RenderOrder.CORPSE</span>

        print(death_message)</pre>
{{</ original-tab >}}
{{</ codetab >}}

Run the project now, and the corpse ordering issue should be resolved.

Now, onto the more important issue: solving the player's death.

One thing that would be helpful right now is being able to see the player's HP. Otherwise, the player will just kinda drop dead after a while, and it'll be difficult for the player to know how close they are to death's door.

Add the following line to the `render` function in the `Engine` class:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
if TYPE_CHECKING:
-   from entity import Entity
+   from entity import Actor
    from game_map import GameMap


class Engine:
    game_map: GameMap

-   def __init__(self, player: Entity):
+   def __init__(self, player: Actor):
        ...

    def render(self, console: Console, context: Context) -> None:
        self.game_map.render(console)
 
+       console.print(
+           x=1,
+           y=47,
+           string=f"HP: {self.player.fighter.hp}/{self.player.fighter.max_hp}",
+       )

        context.present(console)

        console.clear()
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>if TYPE_CHECKING:
    <span class="crossed-out-text">from entity import Entity</span>
    <span class="new-text">from entity import Actor</span>
    from game_map import GameMap


class Engine:
    game_map: GameMap

    <span class="crossed-out-text">def __init__(self, player: Entity):</span>
    <span class="new-text">def __init__(self, player: Actor):</span>
        ...
    
    def render(self, console: Console, context: Context) -> None:
        self.game_map.render(console)
 
        <span class="new-text">console.print(
            x=1,
            y=47,
            string=f"HP: {self.player.fighter.hp}/{self.player.fighter.max_hp}",
        )</span>

        context.present(console)

        console.clear()</pre>
{{</ original-tab >}}
{{</ codetab >}}

Pretty simple. We're printing the player's HP current health over maximum health below the map. It's not the most attractive looking health display, that's for sure, but it should suffice for now. A better looking way to show the character's health is coming shortly anyway, in the next chapter.

Notice that we also updated the type hint for the `player` argument in the Engine's `__init__` function.

The health indicator is great and all, but our player is still animated after death. There's a few ways to handle this, but the way we'll go with is swapping out the `EventHandler` class. Why? Because what we want to do right now is disallow the player from moving around after dying. An easy way to do that is to stop reacting to the movement keypresses. By switching to a different `EventHandler`, we can do just that.

What we'll want to do is actually modify our existing `EventHandler` to be a base class, and inherit from it in two new classes: `MainGameEventHandler`, and `GameOverEventHandler`. `MainGameEventHandler` will actually do what our current implementation of `EventHandler` does, and `GameOverEventHandler` will handle things when the main character meets his or her untimely demise.

Open up `input_handlers.py` and make the following adjustments:


{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class EventHandler(tcod.event.EventDispatch[Action]):
    def __init__(self, engine: Engine):
        self.engine = engine
    
+   def handle_events(self) -> None:
+       raise NotImplementedError()

+   def ev_quit(self, event: tcod.event.Quit) -> Optional[Action]:
+       raise SystemExit()


+class MainGameEventHandler(EventHandler):
    def handle_events(self) -> None:
        for event in tcod.event.wait():
            action = self.dispatch(event)

            if action is None:
                continue

            action.perform()

            self.engine.handle_enemy_turns()
            self.engine.update_fov()  # Update the FOV before the players next action.

-   def ev_quit(self, event: tcod.event.Quit) -> Optional[Action]:
-       raise SystemExit()

    def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[Action]:
        action: Optional[Action] = None

        key = event.sym

        player = self.engine.player

        if key in MOVE_KEYS:
            dx, dy = MOVE_KEYS[key]
            action = BumpAction(player, dx, dy)
        elif key in WAIT_KEYS:
            action = WaitAction(player)

        elif key == tcod.event.K_ESCAPE:
            action = EscapeAction(player)

        # No valid key was pressed
        return action


+class GameOverEventHandler(EventHandler):
+   def handle_events(self) -> None:
+       for event in tcod.event.wait():
+           action = self.dispatch(event)

+           if action is None:
+               continue

+           action.perform()

+   def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[Action]:
+       action: Optional[Action] = None

+       key = event.sym

+       if key == tcod.event.K_ESCAPE:
+           action = EscapeAction(self.engine.player)

+       # No valid key was pressed
+       return action
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class EventHandler(tcod.event.EventDispatch[Action]):
    def __init__(self, engine: Engine):
        self.engine = engine
    
    <span class="new-text">def handle_events(self) -> None:
        raise NotImplementedError()

    def ev_quit(self, event: tcod.event.Quit) -> Optional[Action]:
        raise SystemExit()</span>


<span class="new-text">class MainGameEventHandler(EventHandler):</span>
    def handle_events(self) -> None:
        for event in tcod.event.wait():
            action = self.dispatch(event)

            if action is None:
                continue

            action.perform()

            self.engine.handle_enemy_turns()
            self.engine.update_fov()  # Update the FOV before the players next action.

    <span class="crossed-out-text">def ev_quit(self, event: tcod.event.Quit) -> Optional[Action]:</span>
        <span class="crossed-out-text">raise SystemExit()</span>

    def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[Action]:
        action: Optional[Action] = None

        key = event.sym

        player = self.engine.player

        if key in MOVE_KEYS:
            dx, dy = MOVE_KEYS[key]
            action = BumpAction(player, dx, dy)
        elif key in WAIT_KEYS:
            action = WaitAction(player)

        elif key == tcod.event.K_ESCAPE:
            action = EscapeAction(player)

        # No valid key was pressed
        return action


<span class="new-text">class GameOverEventHandler(EventHandler):
    def handle_events(self) -> None:
        for event in tcod.event.wait():
            action = self.dispatch(event)

            if action is None:
                continue

            action.perform()

    def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[Action]:
        action: Optional[Action] = None

        key = event.sym

        if key == tcod.event.K_ESCAPE:
            action = EscapeAction(self.engine.player)

        # No valid key was pressed
        return action</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

`EventHandler` is not the base class for our other two classes.

`MainGameEventHandler` is almost identical to our original `EventHandler` class, except that it doesn't need to implement `ev_quit`, as `EventHandler` takes care of that just fine.

`GameOverEventHandler` is what's really new here. It doesn't look terribly different from `MainGameEventHandler`, except for a few key differences.

* After performing its actions, it doesn't call the enemy turns nor update the FOV.
* It also doesn't respond to the movement keys, just `Esc`, so the player can still exit the game.

Because we're replacing our old implementation of `EventHandler` with `MainGameEventHandler`, we'll need to adjust `engine.py` to use `MainGameEventHandler`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from tcod.map import compute_fov

-from input_handlers import EventHandler
+from input_handlers import MainGameEventHandler

if TYPE_CHECKING:
    from entity import Actor
    from game_map import GameMap
+   from input_handlers import EventHandler


class Engine:
    game_map: GameMap

    def __init__(self, player: Actor):
-       self.event_handler: EventHandler = EventHandler(self)
+       self.event_handler: EventHandler = MainGameEventHandler(self)
        self.player = player
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from tcod.map import compute_fov

<span class="crossed-out-text">from input_handlers import EventHandler</span>
<span class="new-text">from input_handlers import MainGameEventHandler</span>

if TYPE_CHECKING:
    from entity import Actor
    from game_map import GameMap
    <span class="new-text">from input_handlers import EventHandler</span>


class Engine:
    game_map: GameMap

    def __init__(self, player: Actor):
        <span class="crossed-out-text">self.event_handler: EventHandler = EventHandler(self)</span>
        <span class="new-text">self.event_handler: EventHandler = MainGameEventHandler(self)</span>
        self.player = player</pre>
{{</ original-tab >}}
{{</ codetab >}}

Lastly, we can use the `GameOverEventHandler` in `fighter.py` to ensure the player cannot move after death:


{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from __future__ import annotations

from typing import TYPE_CHECKING

from components.base_component import BaseComponent
+from input_handlers import GameOverEventHandler
from render_order import RenderOrder

if TYPE_CHECKING:
    from entity import Actor


class Fighter(BaseComponent):
    ...

    def die(self) -> None:
        if self.engine.player is self.entity:
            death_message = "You died!"
+           self.engine.event_handler = GameOverEventHandler(self.engine)
        else:
            death_message = f"{self.entity.name} is dead!"
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from __future__ import annotations

from typing import TYPE_CHECKING

from components.base_component import BaseComponent
<span class="new-text">from input_handlers import GameOverEventHandler</span>
from render_order import RenderOrder

if TYPE_CHECKING:
    from entity import Actor


class Fighter(BaseComponent):
    ...

    def die(self) -> None:
        if self.engine.player is self.entity:
            death_message = "You died!"
            <span class="new-text">self.engine.event_handler = GameOverEventHandler(self.engine)</span>
        else:
            death_message = f"{self.entity.name} is dead!"</pre>
{{</ original-tab >}}
{{</ codetab >}}

And with that last change, the main character should die, for real this time! You'll be unable to move or attack, but you can still exit the game as normal.

If you want to see the code so far in its entirety, [click
here](https://github.com/TStand90/tcod_tutorial_v2/tree/2020/part-6).

[Click here to move on to the next part of this
tutorial.](/tutorials/tcod/v2/part-7)
