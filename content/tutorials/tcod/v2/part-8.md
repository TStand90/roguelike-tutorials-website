---
title: "Part 8 - Items and Inventory"
date: 2020-07-14
draft: true
---

## Quick refactors

Once again, apologies to everyone reading this right now. After publishing the last two parts, there were once again a few refactors on code written in those parts, like at the beginning of part 6. Luckily, the changes are much less extensive this time.


`game_map.py`

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class GameMap:
    ...
    )  # Tiles the player has seen before
 
+   @property
+   def gamemap(self) -> GameMap:
+       return self

     @property
     def actors(self) -> Iterator[Actor]:
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class GameMap:
    ...
    )  # Tiles the player has seen before
 
    <span class="new-text">@property
    def gamemap(self) -> GameMap:
        return self</span>

     @property
     def actors(self) -> Iterator[Actor]:
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class Entity:
    """
    A generic object to represent players, enemies, items, etc.
    """

-   gamemap: GameMap
+   parent: GameMap

    def __init__(
        self,
-       gamemap: Optional[GameMap] = None,
+       parent: Optional[GameMap] = None,
        x: int = 0,
        y: int = 0,
        char: str = "?",
        color: Tuple[int, int, int] = (255, 255, 255),
        name: str = "<Unnamed>",
        blocks_movement: bool = False,
        render_order: RenderOrder = RenderOrder.CORPSE,
    ):
        self.x = x
        self.y = y
        self.char = char
        self.color = color
        self.name = name
        self.blocks_movement = blocks_movement
        self.render_order = render_order
-       if gamemap:
-           # If gamemap isn't provided now then it will be set later.
-           self.gamemap = gamemap
-           gamemap.entities.add(self)
+       if parent:
+           # If parent isn't provided now then it will be set later.
+           self.parent = parent
+           parent.entities.add(self)

+   @property
+   def gamemap(self) -> GameMap:
+       return self.parent.gamemap

    def spawn(self: T, gamemap: GameMap, x: int, y: int) -> T:
        """Spawn a copy of this instance at the given location."""
        clone = copy.deepcopy(self)
        clone.x = x
        clone.y = y
-       clone.gamemap = gamemap
+       clone.parent = gamemap
        gamemap.entities.add(clone)
        return clone
    
    def place(self, x: int, y: int, gamemap: Optional[GameMap] = None) -> None:
        """Place this entitiy at a new location.  Handles moving across GameMaps."""
        self.x = x
        self.y = y
        if gamemap:
-           if hasattr(self, "gamemap"):  # Possibly uninitialized.
-               self.gamemap.entities.remove(self)
-           self.gamemap = gamemap
+           if hasattr(self, "parent"):  # Possibly uninitialized.
+               if self.parent is self.gamemap:
+                   self.gamemap.entities.remove(self)
+           self.parent = gamemap
            gamemap.entities.add(self)

    def move(self, dx: int, dy: int) -> None:
        # Move the entity by a given amount
        self.x += dx
        self.y += dy


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
            render_order=RenderOrder.ACTOR,
        )

        self.ai: Optional[BaseAI] = ai_cls(self)

        self.fighter = fighter
-       self.fighter.entity = self
+       self.fighter.parent = self

    @property
    def is_alive(self) -> bool:
        """Returns True as long as this actor can perform actions."""
        return bool(self.ai)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class Entity:
    """
    A generic object to represent players, enemies, items, etc.
    """

    <span class="crossed-out-text">gamemap: GameMap</span>
    <span class="new-text">parent: GameMap</span>

    def __init__(
        self,
        <span class="crossed-out-text">gamemap: Optional[GameMap] = None,</span>
        <span class="new-text">parent: Optional[GameMap] = None,</span>
        x: int = 0,
        y: int = 0,
        char: str = "?",
        color: Tuple[int, int, int] = (255, 255, 255),
        name: str = "&lt;Unnamed&gt;",
        blocks_movement: bool = False,
        render_order: RenderOrder = RenderOrder.CORPSE,
    ):
        self.x = x
        self.y = y
        self.char = char
        self.color = color
        self.name = name
        self.blocks_movement = blocks_movement
        self.render_order = render_order
        <span class="crossed-out-text">if gamemap:</span>
            <span class="crossed-out-text"># If gamemap isn't provided now then it will be set later.</span>
            <span class="crossed-out-text">self.gamemap = gamemap</span>
            <span class="crossed-out-text">gamemap.entities.add(self)</span>
        <span class="new-text">if parent:
            # If parent isn't provided now then it will be set later.
            self.parent = parent
            parent.entities.add(self)

    @property
    def gamemap(self) -> GameMap:
        return self.parent.gamemap</span>

    def spawn(self: T, gamemap: GameMap, x: int, y: int) -> T:
        """Spawn a copy of this instance at the given location."""
        clone = copy.deepcopy(self)
        clone.x = x
        clone.y = y
        <span class="crossed-out-text">clone.gamemap = gamemap</span>
        <span class="new-text">clone.parent = gamemap</span>
        gamemap.entities.add(clone)
        return clone
    
    def place(self, x: int, y: int, gamemap: Optional[GameMap] = None) -> None:
        """Place this entitiy at a new location.  Handles moving across GameMaps."""
        self.x = x
        self.y = y
        if gamemap:
            <span class="crossed-out-text">if hasattr(self, "gamemap"):  # Possibly uninitialized.</span>
                <span class="crossed-out-text">self.gamemap.entities.remove(self)</span>
            <span class="crossed-out-text">self.gamemap = gamemap</span>
            <span class="new-text">if hasattr(self, "parent"):  # Possibly uninitialized.
                if self.parent is self.gamemap:
                    self.gamemap.entities.remove(self)
            self.parent = gamemap</span>
            gamemap.entities.add(self)
            
    def move(self, dx: int, dy: int) -> None:
        # Move the entity by a given amount
        self.x += dx
        self.y += dy


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
            render_order=RenderOrder.ACTOR,
        )

        self.ai: Optional[BaseAI] = ai_cls(self)

        self.fighter = fighter
        <span class="crossed-out-text">self.fighter.entity = self</span>
        <span class="new-text">self.fighter.parent = self</span>

    @property
    def is_alive(self) -> bool:
        """Returns True as long as this actor can perform actions."""
        return bool(self.ai)</pre>
{{</ original-tab >}}
{{</ codetab >}}

`base_component.py`

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from engine import Engine
    from entity import Entity
+   from game_map import GameMap
 
 
class BaseComponent:
-   entity: Entity  # Owning entity instance.
+   parent: Entity  # Owning entity instance.

+   @property
+   def gamemap(self) -> GameMap:
+       return self.parent.gamemap
 
    @property
    def engine(self) -> Engine:
-       return self.entity.gamemap.engine
+       return self.gamemap.engine
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from engine import Engine
    from entity import Entity
    <span class="new-text">from game_map import GameMap</span>
 
 
class BaseComponent:
    <span class="crossed-out-text">entity: Entity  # Owning entity instance.</span>
    <span class="new-text">parent: Entity  # Owning entity instance.

    @property
    def gamemap(self) -> GameMap:
        return self.parent.gamemap</span>
 
    @property
    def engine(self) -> Engine:
        <span class="crossed-out-text">return self.entity.gamemap.engine</span>
        <span class="new-text">return self.gamemap.engine</span></pre>
{{</ original-tab >}}
{{</ codetab >}}


{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class Fighter(BaseComponent):
-   entity: Actor
+   parent: Actor
 
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
-       if self._hp == 0 and self.entity.ai:
+       if self._hp == 0 and self.parent.ai:
            self.die()
 
    def die(self) -> None:
-       if self.engine.player is self.entity:
+       if self.engine.player is self.parent:
            death_message = "You died!"
            death_message_color = color.player_die
            self.engine.event_handler = GameOverEventHandler(self.engine)
        else:
-           death_message = f"{self.entity.name} is dead!"
+           death_message = f"{self.parent.name} is dead!"
            death_message_color = color.enemy_die
 
+       self.parent.char = "%"
+       self.parent.color = (191, 0, 0)
+       self.parent.blocks_movement = False
+       self.parent.ai = None
+       self.parent.name = f"remains of {self.parent.name}"
+       self.parent.render_order = RenderOrder.CORPSE
-       self.entity.char = "%"
-       self.entity.color = (191, 0, 0)
-       self.entity.blocks_movement = False
-       self.entity.ai = None
-       self.entity.name = f"remains of {self.entity.name}"
-       self.entity.render_order = RenderOrder.CORPSE
 
        self.engine.message_log.add_message(death_message, death_message_color)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class Fighter(BaseComponent):
    <span class="crossed-out-text">entity: Actor</span>
    <span class="new-text">parent: Actor</span>
 
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
        <span class="crossed-out-text">if self._hp == 0 and self.entity.ai:</span>
        <span class="new-text">if self._hp == 0 and self.parent.ai:</span>
            self.die()
 
    def die(self) -> None:
        <span class="crossed-out-text">if self.engine.player is self.entity:</span>
        <span class="new-text">if self.engine.player is self.parent:</span>
            death_message = "You died!"
            death_message_color = color.player_die
            self.engine.event_handler = GameOverEventHandler(self.engine)
        else:
            <span class="crossed-out-text">death_message = f"{self.entity.name} is dead!"</span>
            <span class="new-text">death_message = f"{self.parent.name} is dead!"</span>
            death_message_color = color.enemy_die
 
        <span class="new-text">self.parent.char = "%"
        self.parent.color = (191, 0, 0)
        self.parent.blocks_movement = False
        self.parent.ai = None
        self.parent.name = f"remains of {self.parent.name}"
        self.parent.render_order = RenderOrder.CORPSE</span>
        <span class="crossed-out-text">self.entity.char = "%"</span>
        <span class="crossed-out-text">self.entity.color = (191, 0, 0)</span>
        <span class="crossed-out-text">self.entity.blocks_movement = False</span>
        <span class="crossed-out-text">self.entity.ai = None</span>
        <span class="crossed-out-text">self.entity.name = f"remains of {self.entity.name}"</span>
        <span class="crossed-out-text">self.entity.render_order = RenderOrder.CORPSE</span>
 
        self.engine.message_log.add_message(death_message, death_message_color)</pre>
{{</ original-tab >}}
{{</ codetab >}}

TODO: Fill in other rewrites here.





















So far, our game has movement, dungeon exploring, combat, and AI (okay, we're stretching the meaning of "intelligence" in *artificial intelligence* to its limits, but bear with me here). Now it's time for another staple of the roguelike genre: items\! Why would our rogue venture into the dungeons of doom if not for some sweet loot, after all?

In this part of the tutorial, we'll acheive a few things: a working inventory, and a functioning healing potion. The next part will add more items that can be picked up, but for now, just the healing potion will suffice.

For this part, we'll need four more colors. Let's get adding those out of the way now. Open up `colors.py` and add these colors:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
white = (0xFF, 0xFF, 0xFF)
black = (0x0, 0x0, 0x0)

player_atk = (0xE0, 0xE0, 0xE0)
enemy_atk = (0xFF, 0xC0, 0xC0)

player_die = (0xFF, 0x30, 0x30)
enemy_die = (0xFF, 0xA0, 0x30)
 
+invalid = (0xFF, 0xFF, 0x00)
+impossible = (0x80, 0x80, 0x80)
+error = (0xFF, 0x40, 0x40)

welcome_text = (0x20, 0xA0, 0xFF)
+health_recovered = (0x0, 0xFF, 0x0)

bar_text = white
bar_filled = (0x0, 0x60, 0x0)
bar_empty = (0x40, 0x10, 0x10)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>white = (0xFF, 0xFF, 0xFF)
black = (0x0, 0x0, 0x0)

player_atk = (0xE0, 0xE0, 0xE0)
enemy_atk = (0xFF, 0xC0, 0xC0)

player_die = (0xFF, 0x30, 0x30)
enemy_die = (0xFF, 0xA0, 0x30)

<span class="new-text">invalid = (0xFF, 0xFF, 0x00)
impossible = (0x80, 0x80, 0x80)
error = (0xFF, 0x40, 0x40)</span>

welcome_text = (0x20, 0xA0, 0xFF)
<span class="new-text">health_recovered = (0x0, 0xFF, 0x0)</span>

bar_text = white
bar_filled = (0x0, 0x60, 0x0)
bar_empty = (0x40, 0x10, 0x10)</pre>
{{</ original-tab >}}
{{</ codetab >}}

These will become useful shortly.

TODO: Fill in this part.

TODO: Figure out what's going on here

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class Fighter:
    ...
+   def heal(self, amount: int) -> int:
+       if self.hp == self.max_hp:
+           return 0

+       new_hp_value = self.hp + amount

+       if new_hp_value > self.max_hp:
+           new_hp_value = self.max_hp

+       amount_recovered = new_hp_value - self.hp

+       self.hp = new_hp_value

+       return amount_recovered

+   def take_damage(self, amount: int) -> None:
+       self.hp -= amount
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class Fighter:
    ...
    <span class="new-text">def heal(self, amount: int) -> int:
        if self.hp == self.max_hp:
            return 0

        new_hp_value = self.hp + amount

        if new_hp_value > self.max_hp:
            new_hp_value = self.max_hp

        amount_recovered = new_hp_value - self.hp

        self.hp = new_hp_value

        return amount_recovered

    def take_damage(self, amount: int) -> None:
        self.hp -= amount</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

One thing we're going to need is a way to *not* consume an item or take a turn if something goes wrong during the process. For our health potion, think about what should happen if the player declares they want to use a health potion, but their health is already full. What should happen?

We could just consume the potion anyway, and have it go to waste, but if you've played a game that does that, you know how frustrating it can be, especially if the player clicked the health potion on accident. A better way would be to warn the user that they're trying to do something that makes no sense, and save the player from wasting both the potion and their turn.

But how can we acheive that? We'll discuss it a bit more later on, but the idea is that if we do something impossible, we should raise an exception. Which one? Well, we can define a custom exception, which can give us details on what happened. Create a new file called `exceptions.py` and put the following class into it:

```py3
class Impossible(Exception):
    """Exception raised when an action is impossible to be performed.

    The reason is given as the exception message.
    """
```

... And that's it! When we write `raise Impossible("An exception message")` in our program, the `Impossible` exception will be raised, with the given message.

So what do we do with the raised exception? 

TODO: Fill in the main changes to accomodate Impossible.

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
#!/usr/bin/env python3
import copy
+import traceback

import tcod

...

            context.present(root_console)
 
+           try:
+               for event in tcod.event.wait():
+                   context.convert_event(event)
+                   engine.event_handler.handle_events(event)
+           except Exception:  # Handle exceptions in game.
+               traceback.print_exc()  # Print error to stderr.
+               # Then print the error to the message log.
+               engine.message_log.add_message(traceback.format_exc(), color.error)
-           engine.event_handler.handle_events(context)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>#!/usr/bin/env python3
import copy
<span class="new-text">import traceback</span>

import tcod

...

            context.present(root_console)
 
            <span class="new-text">try:
                for event in tcod.event.wait():
                    context.convert_event(event)
                    engine.event_handler.handle_events(event)
            except Exception:  # Handle exceptions in game.
                traceback.print_exc()  # Print error to stderr.
                # Then print the error to the message log.
                engine.message_log.add_message(traceback.format_exc(), color.error)</span>
            <span class="crossed-out-text">engine.event_handler.handle_events(context)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

This is a generalized, catch all solution, which will print *all* exceptions to the message log, not just instances of `Impossible`. This can be helpful for debugging your game, or getting error reports from users.

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
import tcod

+import color
+import exceptions
-from actions import Action, BumpAction, EscapeAction, WaitAction


class EventHandler(tcod.event.EventDispatch[Action]):
    def __init__(self, engine: Engine):
        self.engine = engine
 
+   def handle_events(self, event: tcod.event.Event) -> None:
+       self.handle_action(self.dispatch(event))

+   def handle_action(self, action: Optional[Action]) -> bool:
+       """Handle actions returned from event methods.

+       Returns True if the action will advance a turn.
+       """
+       if action is None:
+           return False

+       try:
+           action.perform()
+       except exceptions.Impossible as exc:
+           self.engine.message_log.add_message(exc.args[0], color.impossible)
+           return False  # Skip enemy turn on exceptions.

+       self.engine.handle_enemy_turns()

+       self.engine.update_fov()
+       return True

-   def handle_events(self, context: tcod.context.Context) -> None:
-       for event in tcod.event.wait():
-           context.convert_event(event)
-           self.dispatch(event)


class MainGameEventHandler(EventHandler):
-   def handle_events(self, context: tcod.context.Context) -> None:
-       for event in tcod.event.wait():
-           context.convert_event(event)

-           action = self.dispatch(event)

-           if action is None:
-               continue

-           action.perform()

-           self.engine.handle_enemy_turns()

-           self.engine.update_fov()  # Update the FOV before the players next action.
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>import tcod

+import color
+import exceptions
from actions import Action, BumpAction, EscapeAction, WaitAction


class EventHandler(tcod.event.EventDispatch[Action]):
    def __init__(self, engine: Engine):
        self.engine = engine
 
    <span class="new-text">def handle_events(self, event: tcod.event.Event) -> None:
        self.handle_action(self.dispatch(event))

    def handle_action(self, action: Optional[Action]) -> bool:
        """Handle actions returned from event methods.

        Returns True if the action will advance a turn.
        """
        if action is None:
            return False

        try:
            action.perform()
        except exceptions.Impossible as exc:
            self.engine.message_log.add_message(exc.args[0], color.impossible)
            return False  # Skip enemy turn on exceptions.

        self.engine.handle_enemy_turns()

        self.engine.update_fov()
        return True</span>

    <span class="crossed-out-text">def handle_events(self, context: tcod.context.Context) -> None:</span>
        <span class="crossed-out-text">for event in tcod.event.wait():</span>
            <span class="crossed-out-text">context.convert_event(event)</span>
            <span class="crossed-out-text">self.dispatch(event)</span>


class MainGameEventHandler(EventHandler):
    <span class="crossed-out-text">def handle_events(self, context: tcod.context.Context) -> None:</span>
        <span class="crossed-out-text">for event in tcod.event.wait():</span>
            <span class="crossed-out-text">context.convert_event(event)</span>

            <span class="crossed-out-text">action = self.dispatch(event)</span>

            <span class="crossed-out-text">if action is None:</span>
                <span class="crossed-out-text">continue</span>

            <span class="crossed-out-text">action.perform()</span>

            <span class="crossed-out-text">self.engine.handle_enemy_turns()</span>

            <span class="crossed-out-text">self.engine.update_fov()  # Update the FOV before the players next action.</span></pre>
{{</ original-tab >}}
{{</ codetab >}}


TODO: Transition


{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
import color
+import exceptions

if TYPE_CHECKING:
    ...


class MeleeAction(ActionWithDirection):
    def perform(self) -> None:
        target = self.target_actor
        if not target:
-           return  # No entity to attack.
+           raise exceptions.Impossible("Nothing to attack.")

        ...

class MovementAction(ActionWithDirection):
    def perform(self) -> None:
        dest_x, dest_y = self.dest_xy

        if not self.engine.game_map.in_bounds(dest_x, dest_y):
+           # Destination is out of bounds.
+           raise exceptions.Impossible("That way is blocked.")
-           return  # Destination is out of bounds.
         if not self.engine.game_map.tiles["walkable"][dest_x, dest_y]:
+           # Destination is blocked by a tile.
+           raise exceptions.Impossible("That way is blocked.")
-           return  # Destination is blocked by a tile.
         if self.engine.game_map.get_blocking_entity_at_location(dest_x, dest_y):
+           # Destination is blocked by an entity.
+           raise exceptions.Impossible("That way is blocked.")
-           return  # Destination is blocked by an entity.
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>import color
<span class="new-text">import exceptions</span>

if TYPE_CHECKING:
    ...


class MeleeAction(ActionWithDirection):
    def perform(self) -> None:
        target = self.target_actor
        if not target:
            <span class="crossed-out-text">return  # No entity to attack.</span>
            <span class="new-text">raise exceptions.Impossible("Nothing to attack.")</span>

        ...

class MovementAction(ActionWithDirection):
    def perform(self) -> None:
        dest_x, dest_y = self.dest_xy

        if not self.engine.game_map.in_bounds(dest_x, dest_y):
            <span class="new-text"># Destination is out of bounds.
            raise exceptions.Impossible("That way is blocked.")</span>
            <span class="crossed-out-text">return  # Destination is out of bounds.</span>
         if not self.engine.game_map.tiles["walkable"][dest_x, dest_y]:
            <span class="new-text"># Destination is blocked by a tile.
            raise exceptions.Impossible("That way is blocked.")</span>
            <span class="crossed-out-text">return  # Destination is blocked by a tile.</span>
         if self.engine.game_map.get_blocking_entity_at_location(dest_x, dest_y):
            <span class="new-text"># Destination is blocked by an entity.
            raise exceptions.Impossible("That way is blocked.")</span>
            <span class="crossed-out-text">return  # Destination is blocked by an entity.</span></pre>
{{</ original-tab >}}
{{</ codetab >}}




So what about when the enemies try doing something impossible? You might want to know when that happens for debugging purposes, but during normal execution of our game, we can simply ignore it, and have the enemy skip their turn. To do this, modify `engine.py` like this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from tcod.map import compute_fov
 
+import exceptions
from input_handlers import MainGameEventHandler
from message_log import MessageLog

...

    def handle_enemy_turns(self) -> None:
        for entity in set(self.game_map.actors) - {self.player}:
            if entity.ai:
+               try:
+                   entity.ai.perform()
+               except exceptions.Impossible:
+                   pass  # Ignore impossible action exceptions from AI.
-               entity.ai.perform()
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from tcod.map import compute_fov
 
<span class="new-text">import exceptions</span>
from input_handlers import MainGameEventHandler
from message_log import MessageLog

...

    def handle_enemy_turns(self) -> None:
        for entity in set(self.game_map.actors) - {self.player}:
            if entity.ai:
                <span class="new-text">try:
                    entity.ai.perform()
                except exceptions.Impossible:
                    pass  # Ignore impossible action exceptions from AI.</span>
                <span class="crossed-out-text">entity.ai.perform()</span></pre>
{{</ original-tab >}}
{{</ codetab >}}



TODO: Fill in missing parts?

The way we'll implement our health potions will be similar to how we implemented enemies: We'll create a component that holds the functionality we want, and we'll create a subclass of `Entity` that holds the relevant component. From the `Consumable` component, we can create subclasses that implement the specific functionality we want for each item. In this case, it'll be a health potion, but in the next chapter, we'll be implementing other types of consumables, so we'll want to stay flexible.

In the `components` directory, create a file called `consumable.py` and fill it with the following contents:

```py3
from __future__ import annotations

from typing import TYPE_CHECKING

import color
from components.base_component import BaseComponent
from exceptions import Impossible

if TYPE_CHECKING:
    from entity import Actor, Item


class Consumable(BaseComponent):
    parent: Item

    def consume(self, consumer: Actor) -> None:
        raise NotImplementedError()


class HealingConsumable(Consumable):
    def __init__(self, amount: int):
        self.amount = amount

    def consume(self, consumer: Actor) -> None:
        amount_recovered = consumer.fighter.heal(self.amount)

        if amount_recovered > 0:
            self.engine.message_log.add_message(
                f"You consume the {self.parent.name}, and recover {amount_recovered} HP!",
                color.health_recovered,
            )
        else:
            raise Impossible(f"Your health is already full.")
```

The `Consumable` class knows its parent, and defines an abstract `consume` method... and that's about it. We'll leave the more interesting bits to `HealingConsumable`.

`HealingConsumable` is initialized with an `amount`, which is how much the user will be healed when using the item. The `consume` function calls `fighter.heal`, and logs a message to the message log, if the entity recovered health. If not (because the user had full health already), we return that `Impossible` exception we defined earlier. This will give us a message in the log that the player's health is already full, and it won't waste the health potion.

So what does this component get attached to? In order to create our health potions, we can create another subclass of `Entity`, which will represent non-actor items. Open up `entity.py` and add the following class:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from render_order import RenderOrder
 
if TYPE_CHECKING:
    from components.ai import BaseAI
+   from components.consumable import Consumable
    from components.fighter import Fighter
    from game_map import GameMap

...

    ...
    @property
    def is_alive(self) -> bool:
        """Returns True as long as this actor can perform actions."""
        return bool(self.ai)


+class Item(Entity):
+   def __init__(
+       self,
+       *,
+       x: int = 0,
+       y: int = 0,
+       char: str = "?",
+       color: Tuple[int, int, int] = (255, 255, 255),
+       name: str = "<Unnamed>",
+       consumable: Consumable,
+   ):
+       super().__init__(
+           x=x,
+           y=y,
+           char=char,
+           color=color,
+           name=name,
+           blocks_movement=False,
+           render_order=RenderOrder.ITEM,
+       )

+       self.consumable = consumable
+       self.consumable.parent = self
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from render_order import RenderOrder
 
if TYPE_CHECKING:
    from components.ai import BaseAI
    <span class="new-text">from components.consumable import Consumable</span>
    from components.fighter import Fighter
    from game_map import GameMap

...

    ...
    @property
    def is_alive(self) -> bool:
        """Returns True as long as this actor can perform actions."""
        return bool(self.ai)


<span class="new-text">class Item(Entity):
    def __init__(
        self,
        *,
        x: int = 0,
        y: int = 0,
        char: str = "?",
        color: Tuple[int, int, int] = (255, 255, 255),
        name: str = "&lt;Unnamed&gt;",
        consumable: Consumable,
    ):
        super().__init__(
            x=x,
            y=y,
            char=char,
            color=color,
            name=name,
            blocks_movement=False,
            render_order=RenderOrder.ITEM,
        )

        self.consumable = consumable
        self.consumable.parent = self</pre>
{{</ original-tab >}}
{{</ codetab >}}

`Item` isn't too different from `Actor`, except instead of implementing `fighter` and `ai`, it does `consumable`. When we create an item, we'll assign the `consumable`, which will determine what actually happens when the item gets used.

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from components.ai import HostileEnemy
+from components.consumable import HealingConsumable
from components.fighter import Fighter
-from entity import Actor
+from entity import Actor, Item


player = Actor(
    char="@",
    color=(255, 255, 255),
    name="Player",
    ai_cls=HostileEnemy,
    fighter=Fighter(hp=30, defense=2, power=5),
)

orc = Actor(
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
)

+health_potion = Item(
+   char="!",
+   color=(127, 0, 255),
+   name="Health Potion",
+   consumable=HealingConsumable(amount=4),
+)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from components.ai import HostileEnemy
<span class="new-text">from components.consumable import HealingConsumable</span>
from components.fighter import Fighter
<span class="crossed-out-text">from entity import Actor</span>
<span class="new-text">from entity import Actor, Item</span>

player = Actor(
    char="@",
    color=(255, 255, 255),
    name="Player",
    ai_cls=HostileEnemy,
    fighter=Fighter(hp=30, defense=2, power=5),
)

orc = Actor(
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
)

<span class="new-text">health_potion = Item(
   char="!",
   color=(127, 0, 255),
   name="Health Potion",
   consumable=HealingConsumable(amount=4),
)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

We're defining a new entity type, called `health_potion` (no surprises there), and utilizing the `Item` and `HealingConsumable` classes we just wrote. The health potion will recover 4 HP of the user's health. Feel free to adjust that value however you see fit.

Alright, we're now ready to put some health potions in the dungeon. As you may have already guessed, we'll need to adjust the `generate_dungeon` and `place_entities` functions in `procgen.py` to actually put the potions in. Edit `procgen.py` like this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
def place_entities(
-   room: RectangularRoom, dungeon: GameMap, maximum_monsters: int,
+   room: RectangularRoom, dungeon: GameMap, maximum_monsters: int, maximum_items: int,
) -> None:
    number_of_monsters = random.randint(0, maximum_monsters)
+   number_of_items = random.randint(0, maximum_items)

    for i in range(number_of_monsters):
        x = random.randint(room.x1 + 1, room.x2 - 1)
        y = random.randint(room.y1 + 1, room.y2 - 1)

        if not any(entity.x == x and entity.y == y for entity in dungeon.entities):
            if random.random() < 0.8:
                entity_factories.orc.spawn(dungeon, x, y)
            else:
                entity_factories.troll.spawn(dungeon, x, y)
+   for i in range(number_of_items):
+       x = random.randint(room.x1 + 1, room.x2 - 1)
+       y = random.randint(room.y1 + 1, room.y2 - 1)

+       if not any(entity.x == x and entity.y == y for entity in dungeon.entities):
+           entity_factories.health_potion.spawn(dungeon, x, y)


def tunnel_between(
    ...


def generate_dungeon(
    map_width: int,
    map_height: int,
    max_monsters_per_room: int,
+   max_items_per_room: int,
    engine: Engine,
) -> GameMap:
    """Generate a new dungeon map."""
    ...

        ...
-       place_entities(new_room, dungeon, max_monsters_per_room)
+       place_entities(new_room, dungeon, max_monsters_per_room, max_items_per_room)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>def place_entities(
    <span class="crossed-out-text">room: RectangularRoom, dungeon: GameMap, maximum_monsters: int,</span>
    <span class="new-text">room: RectangularRoom, dungeon: GameMap, maximum_monsters: int, maximum_items: int,</span>
) -> None:
    number_of_monsters = random.randint(0, maximum_monsters)
    <span class="new-text">number_of_items = random.randint(0, maximum_items)</span>

    for i in range(number_of_monsters):
        x = random.randint(room.x1 + 1, room.x2 - 1)
        y = random.randint(room.y1 + 1, room.y2 - 1)

        if not any(entity.x == x and entity.y == y for entity in dungeon.entities):
            if random.random() < 0.8:
                entity_factories.orc.spawn(dungeon, x, y)
            else:
                entity_factories.troll.spawn(dungeon, x, y)
    <span class="new-text">for i in range(number_of_items):
        x = random.randint(room.x1 + 1, room.x2 - 1)
        y = random.randint(room.y1 + 1, room.y2 - 1)

        if not any(entity.x == x and entity.y == y for entity in dungeon.entities):
            entity_factories.health_potion.spawn(dungeon, x, y)</span>


def tunnel_between(
    ...


def generate_dungeon(
    map_width: int,
    map_height: int,
    max_monsters_per_room: int,
    <span class="new-text">max_items_per_room: int,</span>
    engine: Engine,
) -> GameMap:
    """Generate a new dungeon map."""
    ...

        ...
        <span class="crossed-out-text">place_entities(new_room, dungeon, max_monsters_per_room)</span>
        <span class="new-text">place_entities(new_room, dungeon, max_monsters_per_room, max_items_per_room)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

TODO: Double check everything til now

Run the project now, and you should see a few health potions laying around. Success! Well, not really...

Those potions don't do our rogue any good right now, because we can't pick them up! We need to add the items to an inventory before we can start chugging them.

To implement the inventory, we can create a new component, called `Inventory`. Create a new file in the `components` directory, called `inventory.py`, and add this class:

```py3
from __future__ import annotations

from typing import List, TYPE_CHECKING

from components.base_component import BaseComponent

if TYPE_CHECKING:
    from entity import Actor, Item


class Inventory(BaseComponent):
    parent: Actor

    def __init__(self, capacity: int):
        self.capacity = capacity
        self.items: List[Item] = []

    def drop(self, item: Item) -> None:
        """
        Removes an item from the inventory and restores it to the game map, at the player's current location.
        """
        self.items.remove(item)
        item.place(self.parent.x, self.parent.y, self.gamemap)

        self.engine.message_log.add_message(f"You dropped the {item.name}.")
```

The `Inventory` class belongs to an `Actor`, and its initialized with a `capacity`, which is the maximum number of items that can be held, and the `items` list, which will actually hold the items. The `drop` method, as the name implies, will be called when the player decides to drop something out of the inventory, back onto the ground.

Let's add this new component to our `Actor` class. Open up `entity.py` and modify `Actor` like this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
...
if TYPE_CHECKING:
    from components.ai import BaseAI
    from components.consumable import Consumable
    from components.fighter import Fighter
+   from components.inventory import Inventory
    from game_map import GameMap

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
+       inventory: Inventory,        
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

+       self.inventory = inventory
+       self.inventory.parent = self
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>...
if TYPE_CHECKING:
    from components.ai import BaseAI
    from components.consumable import Consumable
    from components.fighter import Fighter
    <span class="new-text">from components.inventory import Inventory</span>
    from game_map import GameMap

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
        <span class="new-text">inventory: Inventory,</span>
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

        <span class="new-text">self.inventory = inventory
        self.inventory.parent = self</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Now, each actor will have their own inventory. Our tutorial won't implement monster inventories (they won't pick up, hold, or use items), but hopefully this setup gives you a good starting place to implement it yourself, if you so choose.

We'll need to update `entity_factories.py` to take the new component into account:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from components.ai import HostileEnemy
from components.consumable import HealingConsumable
from components.fighter import Fighter
+from components.inventory import Inventory
from entity import Actor, Item

player = Actor(
    char="@",
    color=(255, 255, 255),
    name="Player",
    ai_cls=HostileEnemy,
    fighter=Fighter(hp=30, defense=2, power=5),
+   inventory=Inventory(capacity=26),
)

orc = Actor(
    char="o",
    color=(63, 127, 63),
    name="Orc",
    ai_cls=HostileEnemy,
    fighter=Fighter(hp=10, defense=0, power=3),
+   inventory=Inventory(capacity=0),
)
troll = Actor(
    char="T",
    color=(0, 127, 0),
    name="Troll",
    ai_cls=HostileEnemy,
    fighter=Fighter(hp=16, defense=1, power=4),
+   inventory=Inventory(capacity=0),
)

health_potion = Item(
    char="!",
    color=(127, 0, 255),
    name="Health Potion",
    consumable=HealingConsumable(amount=4),
)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from components.ai import HostileEnemy
from components.consumable import HealingConsumable
from components.fighter import Fighter
<span class="new-text">from components.inventory import Inventory</span>
from entity import Actor, Item

player = Actor(
    char="@",
    color=(255, 255, 255),
    name="Player",
    ai_cls=HostileEnemy,
    fighter=Fighter(hp=30, defense=2, power=5),
    <span class="new-text">inventory=Inventory(capacity=26),</span>
)

orc = Actor(
    char="o",
    color=(63, 127, 63),
    name="Orc",
    ai_cls=HostileEnemy,
    fighter=Fighter(hp=10, defense=0, power=3),
    <span class="new-text">inventory=Inventory(capacity=0),</span>
)
troll = Actor(
    char="T",
    color=(0, 127, 0),
    name="Troll",
    ai_cls=HostileEnemy,
    fighter=Fighter(hp=16, defense=1, power=4),
    <span class="new-text">inventory=Inventory(capacity=0),</span>
)

health_potion = Item(
    char="!",
    color=(127, 0, 255),
    name="Health Potion",
    consumable=HealingConsumable(amount=4),
)</pre>
{{</ original-tab >}}
{{</ codetab >}}

We're setting the player's inventory to 26, because when we implement the menu system, each letter in the (English) alphabet will correspond to one item slot. You can expand the inventory if you want, though you'll need to come up with an alternative menu system to accomodate having more choices.

TODO: Fill in here?

In order to actually pick up an item of the floor, we'll require the rogue to move onto the same tile and press a key. Then, a `PickupAction` will be called, which will handle picking up the item and adding it to the inventory.

Open up `actions.py` and define `PickupAction` like this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
+class PickupAction(Action):
+   """Pickup an item and add it to the inventory, if there is room for it."""

+   def __init__(self, entity: Actor):
+       super().__init__(entity)

+   def perform(self) -> None:
+       actor_location_x = self.entity.x
+       actor_location_y = self.entity.y
+       inventory = self.entity.inventory

+       for item in self.engine.game_map.items:
+           if actor_location_x == item.x and actor_location_y == item.y:
+               if len(inventory.items) >= inventory.capacity:
+                   raise Impossible("Your inventory is full.")

+               self.engine.game_map.entities.remove(item)
+               item.parent = self.entity.inventory
+               inventory.items.append(item)

+               self.engine.message_log.add_message(f"You picked up the {item.name}!")
+               return

+       raise Impossible("There is nothing here to pick up.")


class EscapeAction(Action):
    def perform(self) -> None:
        raise SystemExit()
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre><span class="new-text">class PickupAction(Action):
    """Pickup an item and add it to the inventory, if there is room for it."""

    def __init__(self, entity: Actor):
        super().__init__(entity)

    def perform(self) -> None:
        actor_location_x = self.entity.x
        actor_location_y = self.entity.y
        inventory = self.entity.inventory

        for item in self.engine.game_map.items:
            if actor_location_x == item.x and actor_location_y == item.y:
                if len(inventory.items) >= inventory.capacity:
                    raise Impossible("Your inventory is full.")

                self.engine.game_map.entities.remove(item)
                item.parent = self.entity.inventory
                inventory.items.append(item)

                self.engine.message_log.add_message(f"You picked up the {item.name}!")
                return

        raise Impossible("There is nothing here to pick up.")</span>


class EscapeAction(Action):
    def perform(self) -> None:
        raise SystemExit()</pre>
{{</ original-tab >}}
{{</ codetab >}}

TODO: Explain PickupAction in detail

Let's add our new action to the event handler. Open up `input_handlers.py` and edit the key checking section of `MainGameEventHandler` to add the key for picking up items:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
        ...
        elif key == tcod.event.K_v:
            self.engine.event_handler = HistoryViewer(self.engine)
 
+       elif key == tcod.event.K_g:
+           action = PickupAction(player)

        # No valid key was pressed
        return action
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>        ...
        elif key == tcod.event.K_v:
            self.engine.event_handler = HistoryViewer(self.engine)
 
        <span class="new-text">elif key == tcod.event.K_g:
            action = PickupAction(player)</span>

        # No valid key was pressed
        return action</pre>
{{</ original-tab >}}
{{</ codetab >}}

Simple enough, if the player presses the "g" key ("g" for "get"), we call the `PickupAction`.

TODO: Verify up to this point.

Now that the player can pick up items, we'll need to create our inventory menu, where the player can see what items are in the inventory, and select which one to use.

TODO: Finish the tutorial.