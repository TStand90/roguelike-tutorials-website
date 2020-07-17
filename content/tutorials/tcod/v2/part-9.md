---
title: "Part 9 - Ranged Scrolls and Targeting"
date: 2020-07-14
draft: true
---

Adding health potions was a big step, but we won't stop there. Let's continue adding a few items, this time with a focus on offense. We'll add a few scrolls, which will give the player a one-time ranged attack. This gives the player a lot more tactical options to work with, and is definitely something you'll want to expand upon in your own game.

Before we get to that, let's start by adding the colors we'll need for this chapter:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
white = (0xFF, 0xFF, 0xFF)
black = (0x0, 0x0, 0x0)
+red = (0xFF, 0x0, 0x0)

player_atk = (0xE0, 0xE0, 0xE0)
enemy_atk = (0xFF, 0xC0, 0xC0)
+needs_target = (0x3F, 0xFF, 0xFF)
+status_effect_applied = (0x3F, 0xFF, 0x3F)

player_die = (0xFF, 0x30, 0x30)
enemy_die = (0xFF, 0xA0, 0x30)

invalid = (0xFF, 0xFF, 0x00)
impossible = (0x80, 0x80, 0x80)
error = (0xFF, 0x40, 0x40)

welcome_text = (0x20, 0xA0, 0xFF)
health_recovered = (0x0, 0xFF, 0x0)

bar_text = white
bar_filled = (0x0, 0x60, 0x0)
bar_empty = (0x40, 0x10, 0x10)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>white = (0xFF, 0xFF, 0xFF)
black = (0x0, 0x0, 0x0)
<span class="new-text">red = (0xFF, 0x0, 0x0)</span>

player_atk = (0xE0, 0xE0, 0xE0)
enemy_atk = (0xFF, 0xC0, 0xC0)
<span class="new-text">needs_target = (0x3F, 0xFF, 0xFF)
status_effect_applied = (0x3F, 0xFF, 0x3F)</span>

player_die = (0xFF, 0x30, 0x30)
enemy_die = (0xFF, 0xA0, 0x30)

invalid = (0xFF, 0xFF, 0x00)
impossible = (0x80, 0x80, 0x80)
error = (0xFF, 0x40, 0x40)

welcome_text = (0x20, 0xA0, 0xFF)
health_recovered = (0x0, 0xFF, 0x0)

bar_text = white
bar_filled = (0x0, 0x60, 0x0)
bar_empty = (0x40, 0x10, 0x10)</pre>
{{</ original-tab >}}
{{</ codetab >}}

Let's start simple, with a spell that just hits the closest enemy. We'll create a scroll of lightning, which automatically targets an enemy nearby the player.

First thing we need is a way to get the closest entity to the entity casting the spell. Let's add a `distance` function to `Entity`, which will give us the distance to an arbitrary point. Open `entity.py` and add the following function:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from __future__ import annotations

import copy
+import math
from typing import Optional, Tuple, Type, TypeVar, TYPE_CHECKING, Union
...

    ...
    def place(self, x: int, y: int, gamemap: Optional[GameMap] = None) -> None:
        ...

+   def distance(self, x: int, y: int) -> float:
+       """
+       Return the distance between the current entity and the given (x, y) coordinate.
+       """
+       return math.sqrt((x - self.x) ** 2 + (y - self.y) ** 2)

    def move(self, dx: int, dy: int) -> None:
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from __future__ import annotations

import copy
<span class="new-text">import math</span>
from typing import Optional, Tuple, Type, TypeVar, TYPE_CHECKING, Union
...

    ...
    def place(self, x: int, y: int, gamemap: Optional[GameMap] = None) -> None:
        ...

    <span class="new-text">def distance(self, x: int, y: int) -> float:
        """
        Return the distance between the current entity and the given (x, y) coordinate.
        """
        return math.sqrt((x - self.x) ** 2 + (y - self.y) ** 2)</span>

    def move(self, dx: int, dy: int) -> None:
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

With that, we can add the component that will handle shooting our lightning bolt. Add the following class to `consumable.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class HealingConsumable(Consumable):
    ...


+class LightningDamageConsumable(Consumable):
+   def __init__(self, damage: int, maximum_range: int):
+       self.damage = damage
+       self.maximum_range = maximum_range

+   def consume(self, consumer: Actor) -> None:
+       target = None
+       closest_distance = self.maximum_range + 1.0

+       for actor in self.engine.game_map.actors:
+           if (
+               actor.fighter
+               and actor != consumer
+               and self.parent.gamemap.visible[actor.x, actor.y]
+           ):
+               distance = consumer.distance(actor.x, actor.y)

+               if distance < closest_distance:
+                   target = actor
+                   closest_distance = distance

+       if target:
+           self.engine.message_log.add_message(
+               f"A lighting bolt strikes the {target.name} with a loud thunder, for {self.damage} damage!"
+           )
+           target.fighter.take_damage(self.damage)
+       else:
+           raise Impossible("No enemy is close enough to strike.")
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class HealingConsumable(Consumable):
    ...


<span class="new-text">class LightningDamageConsumable(Consumable):
    def __init__(self, damage: int, maximum_range: int):
        self.damage = damage
        self.maximum_range = maximum_range

    def activate(self, action: actions.ItemAction) -> None:
        consumer = action.entity
        target = None
        closest_distance = self.maximum_range + 1.0

        for actor in self.engine.game_map.actors:
            if actor is not consumer and self.parent.gamemap.visible[actor.x, actor.y]:
                distance = consumer.distance(actor.x, actor.y)

                if distance < closest_distance:
                    target = actor
                    closest_distance = distance

        if target:
            self.engine.message_log.add_message(
                f"A lighting bolt strikes the {target.name} with a loud thunder, for {self.damage} damage!"
            )
            target.fighter.take_damage(self.damage)
            self.consume()
        else:
            raise Impossible("No enemy is close enough to strike.")</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

The `__init__` function takes two arguments: `damage`, which dictates how powerful the lightning bolt will be, and `maximum_range`, which tells us how far it can reach.

Similar to `HealingConsumable`, this class has an `activate` function that describes what to do when the player tries using it. It loops through the actors in the current map, and if the actor is visible and within range, it chooses that actor as the one to strike. If a target was found, we strike the target, dealing the damage (using the `take_damage` function we defined last time, which ignores defense) and printing out a message. If no target was found, we give an error, and don't consume the scroll.

In order to use this, we'll need to actually place some lightning scrolls on the map. We can do that by adding the scroll to `entity_factories.py`, and then adjusting the `place_entities` function in `procgen.py`. Let's start with `entity_factories.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from components.ai import HostileEnemy
-from components.consumable import HealingConsumable
+from components import consumable
from components.fighter import Fighter
from components.inventory import Inventory
from entity import Actor, Item

...
health_potion = Item(
    char="!",
    color=(127, 0, 255),
    name="Health Potion",
-   consumable=HealingConsumable(amount=4),
+   consumable=consumable.HealingConsumable(amount=4),
)
+lightning_scroll = Item(
+   char="~",
+   color=(255, 255, 0),
+   name="Lightning Scroll",
+   consumable=consumable.LightningDamageConsumable(damage=20, maximum_range=5),
+)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from components.ai import HostileEnemy
<span class="crossed-out-text">from components.consumable import HealingConsumable</span>
<span class="new-text">from components import consumable</span>
from components.fighter import Fighter
from components.inventory import Inventory
from entity import Actor, Item

...
health_potion = Item(
    char="!",
    color=(127, 0, 255),
    name="Health Potion",
    <span class="crossed-out-text">consumable=HealingConsumable(amount=4),</span>
    <span class="new-text">consumable=consumable.HealingConsumable(amount=4),</span>
)
<span class="new-text">lightning_scroll = Item(
    char="~",
    color=(255, 255, 0),
    name="Lightning Scroll",
    consumable=consumable.LightningDamageConsumable(damage=20, maximum_range=5),
)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Notice that we also are importing `consumable` instead of the specific classes inside, which affects our declaration of `health_potion`. This will save us from having to add a new import every time we create a new consumable class.

Now, for `procgen.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
    ...
    for i in range(number_of_items):
        x = random.randint(room.x1 + 1, room.x2 - 1)
        y = random.randint(room.y1 + 1, room.y2 - 1)

        if not any(entity.x == x and entity.y == y for entity in dungeon.entities):
-           entity_factories.health_potion.spawn(dungeon, x, y)
+           item_chance = random.random()

+           if item_chance < 0.7:
+               entity_factories.health_potion.spawn(dungeon, x, y)
+           else:
+               entity_factories.lightning_scroll.spawn(dungeon, x, y)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>    ...
    for i in range(number_of_items):
        x = random.randint(room.x1 + 1, room.x2 - 1)
        y = random.randint(room.y1 + 1, room.y2 - 1)

        if not any(entity.x == x and entity.y == y for entity in dungeon.entities):
            <span class="crossed-out-text">entity_factories.health_potion.spawn(dungeon, x, y)</span>
            <span class="new-text">item_chance = random.random()

            if item_chance < 0.7:
                entity_factories.health_potion.spawn(dungeon, x, y)
            else:
                entity_factories.lightning_scroll.spawn(dungeon, x, y)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Like with the monsters, we're getting a random number and deciding what to spawn based on a percentage chance. Most of our items will still be health potions, but we should have a chance of getting a lightning scroll instead now.

Run the project, and try picking up some lightning scrolls and zapping some trolls!

![Part 9 - Lightning Scrolls](/images/part-9-lightning-scrolls.png)

That one was a bit on the easy side. Let's try something a little more challenging, something that requires us to target an enemy (or an area) before shooting off the spell.

This will take a few steps, but one of the things we can do on the way to that goal is add a way for the player to "look around" the map using either the mouse or keyboard. We already kind of did this with the mouse in part 7, however, most roguelikes allow the user to play the game entirely with the keyboard.

Open up `input_handlers.py` and add the following contents:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class InventoryDropHandler(InventoryEventHandler):
    ...


+class SelectIndexHandler(AskUserEventHandler):
+   """Handles asking the user for an index on the map."""

+   def __init__(self, engine: Engine):
+       """Sets the cursor to the player when this handler is constructed."""
+       super().__init__(engine)
+       player = self.engine.player
+       engine.mouse_location = player.x, player.y

+   def on_render(self, console: tcod.Console) -> None:
+       """Highlight the tile under the cursor."""
+       super().on_render(console)
+       x, y = self.engine.mouse_location
+       console.tiles_rgb["bg"][x, y] = color.white
+       console.tiles_rgb["fg"][x, y] = color.black

+   def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[Action]:
+       """Check for key movement or confirmation keys."""
+       key = event.sym
+       if key in MOVE_KEYS:
+           modifier = 1  # Holding modifier keys will speed up key movement.
+           if event.mod & (tcod.event.KMOD_LSHIFT | tcod.event.KMOD_RSHIFT):
+               modifier *= 5
+           if event.mod & (tcod.event.KMOD_LCTRL | tcod.event.KMOD_RCTRL):
+               modifier *= 10
+           if event.mod & (tcod.event.KMOD_LALT | tcod.event.KMOD_RALT):
+               modifier *= 20

+           x, y = self.engine.mouse_location
+           dx, dy = MOVE_KEYS[key]
+           x += dx * modifier
+           y += dy * modifier
+           # Clamp the cursor index to the map size.
+           x = max(0, min(x, self.engine.game_map.width - 1))
+           y = max(0, min(y, self.engine.game_map.height - 1))
+           self.engine.mouse_location = x, y
+           return None
+       elif key in CONFIRM_KEYS:
+           return self.on_index_selected(*self.engine.mouse_location)
+       return super().ev_keydown(event)

+   def ev_mousebuttondown(self, event: tcod.event.MouseButtonDown) -> Optional[Action]:
+       """Left click confirms a selection."""
+       if self.engine.game_map.in_bounds(*event.tile):
+           if event.button == 1:
+               return self.on_index_selected(*event.tile)
+       return super().ev_mousebuttondown(event)

+   def on_index_selected(self, x: int, y: int) -> Optional[Action]:
+       """Called when an index is selected."""
+       raise NotImplementedError()


+class LookHandler(SelectIndexHandler):
+   """Lets the player look around using the keyboard."""

+   def on_index_selected(self, x: int, y: int) -> None:
+       """Return to main handler."""
+       self.engine.event_handler = MainGameEventHandler(self.engine)


class MainGameEventHandler(EventHandler):
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class InventoryDropHandler(InventoryEventHandler):
    ...


<span class="new-text">class SelectIndexHandler(AskUserEventHandler):
    """Handles asking the user for an index on the map."""

    def __init__(self, engine: Engine):
        """Sets the cursor to the player when this handler is constructed."""
        super().__init__(engine)
        player = self.engine.player
        engine.mouse_location = player.x, player.y

    def on_render(self, console: tcod.Console) -> None:
        """Highlight the tile under the cursor."""
        super().on_render(console)
        x, y = self.engine.mouse_location
        console.tiles_rgb["bg"][x, y] = color.white
        console.tiles_rgb["fg"][x, y] = color.black

    def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[Action]:
        """Check for key movement or confirmation keys."""
        key = event.sym
        if key in MOVE_KEYS:
            modifier = 1  # Holding modifier keys will speed up key movement.
            if event.mod & (tcod.event.KMOD_LSHIFT | tcod.event.KMOD_RSHIFT):
                modifier *= 5
            if event.mod & (tcod.event.KMOD_LCTRL | tcod.event.KMOD_RCTRL):
                modifier *= 10
            if event.mod & (tcod.event.KMOD_LALT | tcod.event.KMOD_RALT):
                modifier *= 20

            x, y = self.engine.mouse_location
            dx, dy = MOVE_KEYS[key]
            x += dx * modifier
            y += dy * modifier
            # Clamp the cursor index to the map size.
            x = max(0, min(x, self.engine.game_map.width - 1))
            y = max(0, min(y, self.engine.game_map.height - 1))
            self.engine.mouse_location = x, y
            return None
        elif key in CONFIRM_KEYS:
            return self.on_index_selected(*self.engine.mouse_location)
        return super().ev_keydown(event)

    def ev_mousebuttondown(self, event: tcod.event.MouseButtonDown) -> Optional[Action]:
        """Left click confirms a selection."""
        if self.engine.game_map.in_bounds(*event.tile):
            if event.button == 1:
                return self.on_index_selected(*event.tile)
        return super().ev_mousebuttondown(event)

    def on_index_selected(self, x: int, y: int) -> Optional[Action]:
        """Called when an index is selected."""
        raise NotImplementedError()


class LookHandler(SelectIndexHandler):
    """Lets the player look around using the keyboard."""

    def on_index_selected(self, x: int, y: int) -> None:
        """Return to main handler."""
        self.engine.event_handler = MainGameEventHandler(self.engine)</span>


class MainGameEventHandler(EventHandler):
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

TODO: Explain LookHandler and SelectIndexHandler

TODO: Fill this in, jumping ahead....

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from __future__ import annotations

+import random
-from typing import List, Tuple, TYPE_CHECKING
+from typing import List, Optional, Tuple, TYPE_CHECKING

import numpy as np  # type: ignore
import tcod

-from actions import Action, MeleeAction, MovementAction, WaitAction
+from actions import Action, BumpAction, MeleeAction, MovementAction, WaitAction

if TYPE_CHECKING:
    from entity import Actor


class BaseAI(Action):
    ...


+class ConfusedEnemy(BaseAI):
+   """
+   A confused enemy will stumble around aimlessly for a given number of turns, then revert back to its previous AI.
+   If an actor occupies a tile it is randomly moving into, it will attack.
+   """

+   def __init__(
+       self, entity: Actor, previous_ai: Optional[BaseAI], turns_remaining: int
+   ):
+       super().__init__(entity)

+       self.previous_ai = previous_ai
+       self.turns_remaining = turns_remaining

+   def perform(self) -> None:
+       # Revert the AI back to the original state if the effect has run its course.
+       if self.turns_remaining <= 0:
+           self.engine.message_log.add_message(
+               f"The {self.entity.name} is no longer confused."
+           )
+           self.entity.ai = self.previous_ai
+       else:
+           # Pick a random direction
+           direction_x, direction_y = random.choice(
+               [
+                   (-1, -1),  # Northwest
+                   (0, -1),  # North
+                   (1, -1),  # Northeast
+                   (-1, 0),  # West
+                   (1, 0),  # East
+                   (-1, 1),  # Southwest
+                   (0, 1),  # South
+                   (1, 1),  # Southeast
+               ]
+           )

+           self.turns_remaining -= 1

+           # The actor will either try to move or attack in the chosen random direction.
+           # Its possible the actor will just bump into the wall, wasting a turn.
+           return BumpAction(self.entity, direction_x, direction_y,).perform()
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from __future__ import annotations

<span class="new-text">import random</span>
<span class="crossed-out-text">from typing import List, Tuple, TYPE_CHECKING</span>
<span class="new-text">from typing import List, Optional, Tuple, TYPE_CHECKING</span>

import numpy as np  # type: ignore
import tcod

<span class="crossed-out-text">from actions import Action, MeleeAction, MovementAction, WaitAction</span>
<span class="new-text">from actions import Action, BumpAction, MeleeAction, MovementAction, WaitAction</span>

if TYPE_CHECKING:
    from entity import Actor


class BaseAI(Action):
    ...


<span class="new-text">class ConfusedEnemy(BaseAI):
    """
    A confused enemy will stumble around aimlessly for a given number of turns, then revert back to its previous AI.
    If an actor occupies a tile it is randomly moving into, it will attack.
    """

    def __init__(
        self, entity: Actor, previous_ai: Optional[BaseAI], turns_remaining: int
    ):
        super().__init__(entity)

        self.previous_ai = previous_ai
        self.turns_remaining = turns_remaining

    def perform(self) -> None:
        # Revert the AI back to the original state if the effect has run its course.
        if self.turns_remaining <= 0:
            self.engine.message_log.add_message(
                f"The {self.entity.name} is no longer confused."
            )
            self.entity.ai = self.previous_ai
        else:
            # Pick a random direction
            direction_x, direction_y = random.choice(
                [
                    (-1, -1),  # Northwest
                    (0, -1),  # North
                    (1, -1),  # Northeast
                    (-1, 0),  # West
                    (1, 0),  # East
                    (-1, 1),  # Southwest
                    (0, 1),  # South
                    (1, 1),  # Southeast
                ]
            )

            self.turns_remaining -= 1

            # The actor will either try to move or attack in the chosen random direction.
            # Its possible the actor will just bump into the wall, wasting a turn.
            return BumpAction(self.entity, direction_x, direction_y,).perform()</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

TODO: Explain ConfusedAI



{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from __future__ import annotations

-from typing import Optional, TYPE_CHECKING
+from typing import Callable, Optional, Tuple, TYPE_CHECKING

import tcod
...


class LookHandler(SelectIndexHandler):
    ...


+class SingleRangedAttackHandler(SelectIndexHandler):
+   """Handles targeting a single enemy. Only the enemy selected will be affected."""

+   def __init__(
+       self, engine: Engine, callback: Callable[[Tuple[int, int]], Optional[Action]]
+   ):
+       super().__init__(engine)

+       self.callback = callback

+   def on_index_selected(self, x: int, y: int) -> Optional[Action]:
+       return self.callback((x, y))


class MainGameEventHandler(EventHandler):
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from __future__ import annotations

<span class="crossed-out-text">from typing import Optional, TYPE_CHECKING</span>
<span class="new-text">from typing import Callable, Optional, Tuple, TYPE_CHECKING</span>

import tcod
...


class LookHandler(SelectIndexHandler):
    ...


<span class="new-text">class SingleRangedAttackHandler(SelectIndexHandler):
    """Handles targeting a single enemy. Only the enemy selected will be affected."""

    def __init__(
        self, engine: Engine, callback: Callable[[Tuple[int, int]], Optional[Action]]
    ):
        super().__init__(engine)

        self.callback = callback

    def on_index_selected(self, x: int, y: int) -> Optional[Action]:
        return self.callback((x, y))</span>


class MainGameEventHandler(EventHandler):
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

TODO: Explain SingleRangedAttackHandler

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
...
import color
+import components.ai
from components.base_component import BaseComponent
from exceptions import Impossible
+from input_handlers import SingleRangedAttackHandler

if TYPE_CHECKING:
    from entity import Actor, Item


class Consumable(BaseComponent):
    parent: Item

    def consume(self, consumer: Actor) -> None:
        raise NotImplementedError()


+class ConfusionConsumable(Consumable):
+   def __init__(self, number_of_turns: int):
+       self.number_of_turns = number_of_turns

+   def get_action(self, consumer: Actor) -> Optional[actions.Action]:
+       self.engine.message_log.add_message(
+           "Select a target location.", color.needs_target
+       )
+       self.engine.event_handler = SingleRangedAttackHandler(
+           self.engine,
+           callback=lambda xy: actions.ItemAction(consumer, self.parent, xy),
+       )
+       return None

+   def activate(self, action: actions.ItemAction) -> None:
+       consumer = action.entity
+       target = action.target_actor

+       if not self.engine.game_map.visible[action.target_xy]:
+           raise Impossible("You cannot target an area that you cannot see.")
+       if not target:
+           raise Impossible("You must select an enemy to target.")
+       if target is consumer:
+           raise Impossible("You cannot confuse yourself!")

+       self.engine.message_log.add_message(
+           f"The eyes of the {target.name} look vacant, as it starts to stumble around!",
+           color.status_effect_applied,
+       )
+       target.ai = components.ai.ConfusedEnemy(
+           entity=target, previous_ai=target.ai, turns_remaining=self.number_of_turns,
+       )
+       self.consume()


class HealingConsumable(Consumable):
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>...
import color
<span class="new-text">import components.ai</span>
from components.base_component import BaseComponent
from exceptions import Impossible
<span class="new-text">from input_handlers import SingleRangedAttackHandler</span>

if TYPE_CHECKING:
    from entity import Actor, Item


class Consumable(BaseComponent):
    parent: Item

    def consume(self, consumer: Actor) -> None:
        raise NotImplementedError()


<span class="new-text">class ConfusionConsumable(Consumable):
    def __init__(self, number_of_turns: int):
        self.number_of_turns = number_of_turns

    def get_action(self, consumer: Actor) -> Optional[actions.Action]:
        self.engine.message_log.add_message(
            "Select a target location.", color.needs_target
        )
        self.engine.event_handler = SingleRangedAttackHandler(
            self.engine,
            callback=lambda xy: actions.ItemAction(consumer, self.parent, xy),
        )
        return None

    def activate(self, action: actions.ItemAction) -> None:
        consumer = action.entity
        target = action.target_actor

        if not self.engine.game_map.visible[action.target_xy]:
            raise Impossible("You cannot target an area that you cannot see.")
        if not target:
            raise Impossible("You must select an enemy to target.")
        if target is consumer:
            raise Impossible("You cannot confuse yourself!")

        self.engine.message_log.add_message(
            f"The eyes of the {target.name} look vacant, as it starts to stumble around!",
            color.status_effect_applied,
        )
        target.ai = components.ai.ConfusedEnemy(
            entity=target, previous_ai=target.ai, turns_remaining=self.number_of_turns,
        )
        self.consume()</span>


class HealingConsumable(Consumable):
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

TODO: Explain ConfusionConsumable

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
troll = Actor(
    ...
)

+confusion_scroll = Item(
+   char="~",
+   color=(207, 63, 255),
+   name="Confusion Scroll",
+   consumable=consumable.ConfusionConsumable(number_of_turns=10),
+)
health_potion = Item(
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>troll = Actor(
    ...
)

<span class="new-text">confusion_scroll = Item(
    char="~",
    color=(207, 63, 255),
    name="Confusion Scroll",
    consumable=consumable.ConfusionConsumable(number_of_turns=10),
)</span>
health_potion = Item(
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Now that we can create confusion scrolls, let's add some to the map. Open up `procgen.py` and adjust the part that places items to look like this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
            ...
            if item_chance < 0.7:
                entity_factories.health_potion.spawn(dungeon, x, y)
+           elif item_chance < 0.9:
+               entity_factories.confusion_scroll.spawn(dungeon, x, y)
            else:
                entity_factories.lightning_scroll.spawn(dungeon, x, y)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>            ...
            if item_chance < 0.7:
                entity_factories.health_potion.spawn(dungeon, x, y)
            <span class="new-text">elif item_chance < 0.9:
                entity_factories.confusion_scroll.spawn(dungeon, x, y)</span>
            else:
                entity_factories.lightning_scroll.spawn(dungeon, x, y)</pre>
{{</ original-tab >}}
{{</ codetab >}}

Feel free to adjust these percentage values however you see fit. To test out your confusion scrolls, you might want to mess with the numbers here.

Run the project now, and cast some confusion on your enemies!

![Part 9 - Confusion Scrolls](/images/part-9-confusion-scrolls.png)

So we currently have two types of ranged spells to use: One that targets the nearest enemy automatically, and one that asks for a target. We'll finish this chapter by implementing a third type: One that asks for a target, but affects everything within a certain radius of that target. I'm talking, of course, about an exploding fireball spell!

TODO: Fill in here

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class SingleRangedAttackHandler(SelectIndexHandler):
    ...


+class AreaRangedAttackHandler(SelectIndexHandler):
+   """Handles targeting an area within a given radius. Any entity within the area will be affected."""

+   def __init__(
+       self,
+       engine: Engine,
+       radius: int,
+       callback: Callable[[Tuple[int, int]], Optional[Action]],
+   ):
+       super().__init__(engine)

+       self.radius = radius
+       self.callback = callback

+   def on_render(self, console: tcod.Console) -> None:
+       """Highlight the tile under the cursor."""
+       super().on_render(console)

+       x, y = self.engine.mouse_location

+       # Draw a rectangle around the targeted area, so the player can see the affected tiles.
+       console.draw_frame(
+           x=x - self.radius - 1,
+           y=y - self.radius - 1,
+           width=self.radius ** 2,
+           height=self.radius ** 2,
+           fg=color.red,
+           clear=False,
+       )

+   def on_index_selected(self, x: int, y: int) -> Optional[Action]:
+       return self.callback((x, y))


class MainGameEventHandler(EventHandler):
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class SingleRangedAttackHandler(SelectIndexHandler):
    ...


<span class="new-text">class AreaRangedAttackHandler(SelectIndexHandler):
    """Handles targeting an area within a given radius. Any entity within the area will be affected."""

    def __init__(
        self,
        engine: Engine,
        radius: int,
        callback: Callable[[Tuple[int, int]], Optional[Action]],
    ):
        super().__init__(engine)

        self.radius = radius
        self.callback = callback

    def on_render(self, console: tcod.Console) -> None:
        """Highlight the tile under the cursor."""
        super().on_render(console)

        x, y = self.engine.mouse_location

        # Draw a rectangle around the targeted area, so the player can see the affected tiles.
        console.draw_frame(
            x=x - self.radius - 1,
            y=y - self.radius - 1,
            width=self.radius ** 2,
            height=self.radius ** 2,
            fg=color.red,
            clear=False,
        )

    def on_index_selected(self, x: int, y: int) -> Optional[Action]:
        return self.callback((x, y))</span>


class MainGameEventHandler(EventHandler):
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

TODO: Explain AreaRangedAttackHandler



TODO: Fill in some stuff here....


{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
...
from exceptions import Impossible
-from input_handlers import SingleRangedAttackHandler
+from input_handlers import AreaRangedAttackHandler, SingleRangedAttackHandler

if TYPE_CHECKING:
    ...


class HealingConsumable(Consumable):
    ...


+class FireballDamageConsumable(Consumable):
+   def __init__(self, damage: int, radius: int):
+       self.damage = damage
+       self.radius = radius

+   def get_action(self, consumer: Actor) -> Optional[actions.Action]:
+       self.engine.message_log.add_message(
+           "Select a target location.", color.needs_target
+       )
+       self.engine.event_handler = AreaRangedAttackHandler(
+           self.engine,
+           radius=self.radius,
+           callback=lambda xy: actions.ItemAction(consumer, self.parent, xy),
+       )
+       return None

+   def activate(self, action: actions.ItemAction) -> None:
+       target_xy = action.target_xy

+       if not self.engine.game_map.visible[target_xy]:
+           raise Impossible("You cannot target an area that you cannot see.")

+       targets_hit = False
+       for actor in self.engine.game_map.actors:
+           if actor.distance(*target_xy) <= self.radius:
+               self.engine.message_log.add_message(
+                   f"The {actor.name} is engulfed in a fiery explosion, taking {self.damage} damage!"
+               )
+               actor.fighter.take_damage(self.damage)
+               targets_hit = True

+       if not targets_hit:
+           raise Impossible("There are no targets in the radius.")
+       self.consume()


class LightningDamageConsumable(Consumable):
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>...
from exceptions import Impossible
<span class="crossed-out-text">from input_handlers import SingleRangedAttackHandler</span>
<span class="new-text">from input_handlers import AreaRangedAttackHandler, SingleRangedAttackHandler</span>

if TYPE_CHECKING:
    ...


class HealingConsumable(Consumable):
    ...


<span class="new-text">class FireballDamageConsumable(Consumable):
    def __init__(self, damage: int, radius: int):
        self.damage = damage
        self.radius = radius

    def get_action(self, consumer: Actor) -> Optional[actions.Action]:
        self.engine.message_log.add_message(
            "Select a target location.", color.needs_target
        )
        self.engine.event_handler = AreaRangedAttackHandler(
            self.engine,
            radius=self.radius,
            callback=lambda xy: actions.ItemAction(consumer, self.parent, xy),
        )
        return None

    def activate(self, action: actions.ItemAction) -> None:
        target_xy = action.target_xy

        if not self.engine.game_map.visible[target_xy]:
            raise Impossible("You cannot target an area that you cannot see.")

        targets_hit = False
        for actor in self.engine.game_map.actors:
            if actor.distance(*target_xy) <= self.radius:
                self.engine.message_log.add_message(
                    f"The {actor.name} is engulfed in a fiery explosion, taking {self.damage} damage!"
                )
                actor.fighter.take_damage(self.damage)
                targets_hit = True

        if not targets_hit:
            raise Impossible("There are no targets in the radius.")
        self.consume()</span>


class LightningDamageConsumable(Consumable):
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Let's add the new fireball scroll to `entity_factories.py` so we can put it to use:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
confusion_scroll = Item(
    ...
)
+fireball_scroll = Item(
+   char="~",
+   color=(255, 0, 0),
+   name="Fireball Scroll",
+   consumable=consumable.FireballDamageConsumable(damage=12, radius=3),
+)
health_potion = Item(
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>confusion_scroll = Item(
    ...
)
<span class="new-text">fireball_scroll = Item(
    char="~",
    color=(255, 0, 0),
    name="Fireball Scroll",
    consumable=consumable.FireballDamageConsumable(damage=12, radius=3),
)</span>
health_potion = Item(
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Finally, let's add it to `procgen.py` so it will show up:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
            if item_chance < 0.7:
                entity_factories.health_potion.spawn(dungeon, x, y)
+           elif item_chance < 0.8:
+               entity_factories.fireball_scroll.spawn(dungeon, x, y)
            elif item_chance < 0.9:
                entity_factories.confusion_scroll.spawn(dungeon, x, y)
            else:
                entity_factories.lightning_scroll.spawn(dungeon, x, y)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>            if item_chance < 0.7:
                entity_factories.health_potion.spawn(dungeon, x, y)
            <span class="new-text">elif item_chance < 0.8:
                entity_factories.fireball_scroll.spawn(dungeon, x, y)</span>
            elif item_chance < 0.9:
                entity_factories.confusion_scroll.spawn(dungeon, x, y)
            else:
                entity_factories.lightning_scroll.spawn(dungeon, x, y)</pre>
{{</ original-tab >}}
{{</ codetab >}}




TODO: Finish the tutorial