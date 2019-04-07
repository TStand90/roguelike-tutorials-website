---
title: "Part 9 - Ranged Scrolls and Targeting"
date: 2019-03-30T09:34:01-07:00
draft: false
---

Adding health potions was a big step, but we won't stop there. Let's
continue adding a few items, this time with a focus on offense. We'll
add a few scrolls, which will give the player a one-time ranged attack.
This gives the player a lot more tactical options to work with, and is
definitely something you'll want to expand upon in your own game.

Let's start simple, with a spell that just hits the closest enemy. We'll
create a scroll of lightning, which automatically targets an enemy
nearby the player. Start by adding the function to `item_functions.py`:

```diff
def heal(*args, **kwargs):
    ...

+def cast_lightning(*args, **kwargs):
+   caster = args[0]
+   entities = kwargs.get('entities')
+   fov_map = kwargs.get('fov_map')
+   damage = kwargs.get('damage')
+   maximum_range = kwargs.get('maximum_range')
+
+   results = []
+
+   target = None
+   closest_distance = maximum_range + 1
+
+   for entity in entities:
+       if entity.fighter and entity != caster and libtcod.map_is_in_fov(fov_map, entity.x, entity.y):
+           distance = caster.distance_to(entity)
+
+           if distance < closest_distance:
+               target = entity
+               closest_distance = distance
+
+   if target:
+       results.append({'consumed': True, 'target': target, 'message': Message('A lighting bolt strikes the {0} with a loud thunder! The damage is {1}'.format(target.name, damage))})
+       results.extend(target.fighter.take_damage(damage))
+   else:
+       results.append({'consumed': False, 'target': None, 'message': Message('No enemy is close enough to strike.', libtcod.red)})
+
+   return results
```

Now let's add a chance for this scroll to drop on the map. Most of the
items will still be health potions, but we'll sprinkle in a few
lightning scrolls as well. In `game_map.py`:

```diff
            ...
            if not any([entity for entity in entities if entity.x == x and entity.y == y]):
+               item_chance = randint(0, 100)
+
+               if item_chance < 70:
                    item_component = Item(use_function=heal, amount=4)
                    item = Entity(x, y, '!', libtcod.violet, 'Healing Potion', render_order=RenderOrder.ITEM,
                                  item=item_component)
+               else:
+                   item_component = Item(use_function=cast_lightning, damage=20, maximum_range=5)
+                   item = Entity(x, y, '#', libtcod.yellow, 'Lightning Scroll', render_order=RenderOrder.ITEM,
+                                 item=item_component)
```

Be sure to import `cast_lightning` at the top of the file.

```py3
...
from entity import Entity

from item_functions import cast_lightning, heal

from map_objects.rectangle import Rect
...
```

Lastly, we'll need to adjust our "use" call in `engine.py`, since our
lightning spell is expecting more keyword arguments than we're currently
passing.

```diff
            ...
            if game_state == GameStates.SHOW_INVENTORY:
-               player_turn_results.extend(player.inventory.use(item))
+               player_turn_results.extend(player.inventory.use(item, entities=entities, fov_map=fov_map))
            elif game_state == GameStates.DROP_INVENTORY:
                player_turn_results.extend(player.inventory.drop_item(item))
```

Run the project now, and you should have a working lightning scroll.
That was pretty easy\!

*\*Tip: For testing, you may want to increase the maximum amount of
items per room.*

Needless to say, the spell would be much more usable if we were allowed
to select the target. While we won't change the lightning spell, we
should have another type of spell that allows targeting. Let's focus on
creating a fireball spell, which will not only ask for a target, but
also hit multiple enemies in a set radius.

We'll work backwards in this case, by starting with the end result (the
"fireball" spell) and modifying everything else to make this work.
Here's the fireball spell, which should go in `item_functions.py`:

```diff
...
def cast_lightning(*args, **kwargs):
    ...

+def cast_fireball(*args, **kwargs):
+   entities = kwargs.get('entities')
+   fov_map = kwargs.get('fov_map')
+   damage = kwargs.get('damage')
+   radius = kwargs.get('radius')
+   target_x = kwargs.get('target_x')
+   target_y = kwargs.get('target_y')
+
+   results = []
+
+   if not libtcod.map_is_in_fov(fov_map, target_x, target_y):
+       results.append({'consumed': False, 'message': Message('You cannot target a tile outside your field of view.', libtcod.yellow)})
+       return results
+
+   results.append({'consumed': True, 'message': Message('The fireball explodes, burning everything within {0} tiles!'.format(radius), libtcod.orange)})
+
+   for entity in entities:
+       if entity.distance(target_x, target_y) <= radius and entity.fighter:
+           results.append({'message': Message('The {0} gets burned for {1} hit points.'.format(entity.name, damage), libtcod.orange)})
+           results.extend(entity.fighter.take_damage(damage))
+
+   return results
```

What do we need to do to make this function work? The most obvious thing
is to pass the damage, radius, and target location. Damage and radius
are easy; we can do those when we create the item in `place_entities`.
The target is trickier, because we don't know that is until the player
selects a tile after using the item.

We're going to need another game state for targeting. When the player
selects a certain type of item, the game will ask him or her to select a
location before proceeding. The player then can left-click on a
location, or right-click to cancel, so we'll need a new set of input
handlers as well.

Start with the easy part: Add a new game state to `GameStates`:

```diff
class GameStates(Enum):
    PLAYERS_TURN = 1
    ENEMY_TURN = 2
    PLAYER_DEAD = 3
    SHOW_INVENTORY = 4
    DROP_INVENTORY = 5
+   TARGETING = 6
```

Now let's modify the input handlers. We'll add a function for the keys
while we're targeting, and also add a generalized mouse handler, to know
where the player clicks.

```diff
def handle_keys(key, game_state):
    if game_state == GameStates.PLAYERS_TURN:
        return handle_player_turn_keys(key)
    elif game_state == GameStates.PLAYER_DEAD:
        return handle_player_dead_keys(key)
+   elif game_state == GameStates.TARGETING:
+       return handle_targeting_keys(key)
    elif game_state in (GameStates.SHOW_INVENTORY, GameStates.DROP_INVENTORY):
        return handle_inventory_keys(key)
    ...


+def handle_targeting_keys(key):
+   if key.vk == libtcod.KEY_ESCAPE:
+       return {'exit': True}
+
+   return {}

def handle_player_dead_keys(key):
    ...


+def handle_mouse(mouse):
+   (x, y) = (mouse.cx, mouse.cy)
+
+   if mouse.lbutton_pressed:
+       return {'left_click': (x, y)}
+   elif mouse.rbutton_pressed:
+       return {'right_click': (x, y)}
+
+   return {}
```

If the player is in targeting mode, the only key we'll accept is Escape,
which cancels the targeting. The mouse handler doesn't take the game
state into account; it just tells the engine if the left or right mouse
button was clicked. The engine will have to decide what to do with that.
Modify `engine.py` to accept the mouse inputs:

```diff
        ...
        action = handle_keys(key, game_state)
+       mouse_action = handle_mouse(mouse)

        move = action.get('move')
        pickup = action.get('pickup')
        show_inventory = action.get('show_inventory')
        inventory_index = action.get('inventory_index')
        exit = action.get('exit')
        fullscreen = action.get('fullscreen')

+       left_click = mouse_action.get('left_click')
+       right_click = mouse_action.get('right_click')

        player_turn_results = []
```

Of course, we need to import `handle_mouse` into `engine.py`:

```py3
...
from game_states import GameStates
from input_handlers import handle_keys, handle_mouse
from map_objects.game_map import GameMap
...
```

So how do we even know what types of items need to select a target? We
can add an attribute to the `Item` component which will tell us. We
should also add a message, which will display when the user activates
the item, to inform the user that a target needs to be selected. Modify
the `__init__` function in `Item` like this:

```diff
class Item:
    def __init__(self, use_function=None, targeting=False, targeting_message=None, **kwargs):
        self.use_function = use_function
+       self.targeting = targeting
+       self.targeting_message = targeting_message
        self.function_kwargs = kwargs
```

Because we're setting the values of `targeting` and `targeting_message`
to `None` by default, we don't have to worry about changing the items
we've already made.

We'll need to change our `use` function in `Inventory` to take the
targeting variable into account. If the item needs a target, we should
return a result that tells the engine that, and not use the item. If
not, we proceed as before. Add a new "if" statement to `use`, and wrap
the previous code section in the "else" clause, like this:

```diff
    def use(self, item_entity, **kwargs):
        results = []

        item_component = item_entity.item

        if item_component.use_function is None:
            results.append({'message': Message('The {0} cannot be used'.format(item_entity.name), libtcod.yellow)})
        else:
+           if item_component.targeting and not (kwargs.get('target_x') or kwargs.get('target_y')):
+               results.append({'targeting': item_entity})
+           else:
                kwargs = {**item_component.function_kwargs, **kwargs}
                item_use_results = item_component.use_function(self.owner, **kwargs)

                for item_use_result in item_use_results:
                    if item_use_result.get('consumed'):
                        self.remove_item(item_entity)

                results.extend(item_use_results)

        return results
```

So basically, we check if the item has "targeting" set to True, and if
it does, whether or not we received the `target_x` and `target_y`
variables. If we didn't we can assume that the target has not yet been
selected, and the game state needs to switch to targeting. If it did, we
can use the item like normal.

Now let's modify the engine to handle this new result type. Note that
this result returns the item entity to the engine. That's because the
engine will need to "remember" which item was selected in the first
place. Therefore, we'll need a new variable right before the main game
loop to keep track of the targeting item that was selected.

```diff
    ...
    game_state = GameStates.PLAYERS_TURN
    previous_game_state = game_state

+   targeting_item = None

    while not libtcod.console_is_window_closed():
        ...
            message = player_turn_result.get('message')
            dead_entity = player_turn_result.get('dead')
            item_added = player_turn_result.get('item_added')
            item_consumed = player_turn_result.get('consumed')
            item_dropped = player_turn_result.get('item_dropped')
+           targeting = player_turn_result.get('targeting')
            ...

            if item_consumed:
                game_state = GameStates.ENEMY_TURN

+           if targeting:
+               previous_game_state = GameStates.PLAYERS_TURN
+               game_state = GameStates.TARGETING
+
+               targeting_item = targeting
+
+               message_log.add_message(targeting_item.item.targeting_message)
```

Now our game state will switch to targeting when we select an item from
the inventory that needs it. Note that we're doing something a little
strange with the previous game state; we're setting it to the player's
turn rather than the actual previous state. This is so that cancelling
the targeting will not reopen the inventory screen.

Let's now do something with the left and right clicks we added in
before. If the player left clicks while in targeting, we'll activate the
use function again, this time with the target variables. If the user
right clicks, we'll cancel the targeting. We can also add the cancel
targeting on Escape now.

```diff
        ...
        if inventory_index is not None and previous_game_state != GameStates.PLAYER_DEAD and inventory_index < len(
                player.inventory.items):
            ...

+       if game_state == GameStates.TARGETING:
+           if left_click:
+               target_x, target_y = left_click
+
+               item_use_results = player.inventory.use(targeting_item, entities=entities, fov_map=fov_map,
+                                                       target_x=target_x, target_y=target_y)
+               player_turn_results.extend(item_use_results)
+           elif right_click:
+               player_turn_results.append({'targeting_cancelled': True})

        if exit:
            if game_state in (GameStates.SHOW_INVENTORY, GameStates.DROP_INVENTORY):
                game_state = previous_game_state
+           elif game_state == GameStates.TARGETING:
+               player_turn_results.append({'targeting_cancelled': True})
            else:
                return True

        if fullscreen:
            ...
```

Add the following to make the target cancellation revert the game state:

```diff
            targeting = player_turn_result.get('targeting')
+           targeting_cancelled = player_turn_result.get('targeting_cancelled')

            if message:
                ...

+           if targeting_cancelled:
+               game_state = previous_game_state
+
+               message_log.add_message(Message('Targeting cancelled'))
```

Finally, let's add the fireball scroll to the map. Modify
`place_entities` like this:

```diff
                ...
                item_chance = randint(0, 100)

                if item_chance < 70:
                    item_component = Item(use_function=heal, amount=4)
                    item = Entity(x, y, '!', libtcod.violet, 'Healing Potion', render_order=RenderOrder.ITEM,
                                  item=item_component)
+               elif item_chance < 85:
+                   item_component = Item(use_function=cast_fireball, targeting=True, targeting_message=Message(
+                       'Left-click a target tile for the fireball, or right-click to cancel.', libtcod.light_cyan),
+                                         damage=12, radius=3)
+                   item = Entity(x, y, '#', libtcod.red, 'Fireball Scroll', render_order=RenderOrder.ITEM,
+                                 item=item_component)
                else:
                    item_component = Item(use_function=cast_lightning, damage=20, maximum_range=5)
                    item = Entity(x, y, '#', libtcod.yellow, 'Lightning Scroll', render_order=RenderOrder.ITEM,
                                  item=item_component)
```

You'll need to import both `cast_fireball` and `Message`:

```diff
...
from entity import Entity

+from game_messages import Message

from item_functions import cast_fireball, cast_lightning, heal

from map_objects.rectangle import Rect
...
```

One change we need to make for `cast_fireball` to work: We need a
`distance` function in `Entity`, to get the distance between the entity
and an arbitrary point.

```diff
    def move_towards(self, target_x, target_y, game_map, entities):
        ...

+   def distance(self, x, y):
+       return math.sqrt((x - self.x) ** 2 + (y - self.y) ** 2)

    def distance_to(self, other):
        ...
```

Run the project now, and you should have a functioning fireball spell\!
Be careful though, the player can get damaged by this spell if you cast
it too close to yourself\!

Let's add one more spell for fun: confusion. This will involve modifying
the target's AI for a few turns, and setting it back to normal once the
spell ends.

We'll begin by adding the confused AI, to `ai.py`:

```diff
import tcod as libtcod

+from random import randint
+
+from game_messages import Message


class BasicMonster:
    ...


+class ConfusedMonster:
+   def __init__(self, previous_ai, number_of_turns=10):
+       self.previous_ai = previous_ai
+       self.number_of_turns = number_of_turns
+
+   def take_turn(self, target, fov_map, game_map, entities):
+       results = []
+
+       if self.number_of_turns > 0:
+           random_x = self.owner.x + randint(0, 2) - 1
+           random_y = self.owner.y + randint(0, 2) - 1
+
+           if random_x != self.owner.x and random_y != self.owner.y:
+               self.owner.move_towards(random_x, random_y, game_map, entities)
+
+           self.number_of_turns -= 1
+       else:
+           self.owner.ai = self.previous_ai
+           results.append({'message': Message('The {0} is no longer confused!'.format(self.owner.name), libtcod.red)})
+
+       return results
```

The class gets initialized with a number of turns that the entity is
confused for. It also keeps track of what the entity's actual AI is, so
that it can be switched back when the confusion wears off. For the
`take_turn` method, the entity moves randomly (or not at all), and one
turn gets taken off the timer. Once the timer hits 0, the entity is no
longer confused, and goes back to its previous AI.

Now for the confusion spell. Add the following to `item_functions.py`

```diff
def cast_fireball(*args, **kwargs):
    ...

+def cast_confuse(*args, **kwargs):
+   entities = kwargs.get('entities')
+   fov_map = kwargs.get('fov_map')
+   target_x = kwargs.get('target_x')
+   target_y = kwargs.get('target_y')
+
+   results = []
+
+   if not libtcod.map_is_in_fov(fov_map, target_x, target_y):
+       results.append({'consumed': False, 'message': Message('You cannot target a tile outside your field of view.', libtcod.yellow)})
+       return results
+
+   for entity in entities:
+       if entity.x == target_x and entity.y == target_y and entity.ai:
+           confused_ai = ConfusedMonster(entity.ai, 10)
+
+           confused_ai.owner = entity
+           entity.ai = confused_ai
+
+           results.append({'consumed': True, 'message': Message('The eyes of the {0} look vacant, as he starts to stumble around!'.format(entity.name), libtcod.light_green)})
+
+           break
+   else:
+       results.append({'consumed': False, 'message': Message('There is no targetable enemy at that location.', libtcod.yellow)})
+
+   return results
+
```

You'll need to import the `ConfusedMonster` class to the top of the
file:

```diff
import tcod as libtcod

+from components.ai import ConfusedMonster

from game_messages import Message
...
```

Finally, we'll put the scroll on the map. First, import the
`cast_confuse` function:

```py3
...
from game_messages import Message

from item_functions import cast_confuse, cast_fireball, cast_lightning, heal

from map_objects.rectangle import Rect
...
```

We'll also modify the chances of our scrolls, so that each one has a 10%
chance of spawning.

```diff
                if item_chance < 70:
                    item_component = Item(use_function=heal, amount=4)
                    item = Entity(x, y, '!', libtcod.violet, 'Healing Potion', render_order=RenderOrder.ITEM,
                                  item=item_component)
-               elif item_chance < 85:
+               elif item_chance < 80:
                    item_component = Item(use_function=cast_fireball, targeting=True, targeting_message=Message(
                        'Left-click a target tile for the fireball, or right-click to cancel.', libtcod.light_cyan),
                                          damage=12, radius=3)
                    item = Entity(x, y, '#', libtcod.red, 'Fireball Scroll', render_order=RenderOrder.ITEM,
                                  item=item_component)
+               elif item_chance < 90:
+                   item_component = Item(use_function=cast_confuse, targeting=True, targeting_message=Message(
+                       'Left-click an enemy to confuse it, or right-click to cancel.', libtcod.light_cyan))
+                   item = Entity(x, y, '#', libtcod.light_pink, 'Confusion Scroll', render_order=RenderOrder.ITEM,
+                                 item=item_component)
```

Run the project, and you should be able to cast confusion on enemies.
Enemies who are confused will waste their turns either moving randomly,
or staying in one spot.

That's all for today. We now have 3 different types of scrolls the
player can utilize against enemies. Feel free to try adding more scrolls
and spells as you see fit.

If you want to see the code so far in its entirety, [click
here](https://github.com/TStand90/roguelike_tutorial_revised/tree/part9).

[Click here to move on to the next part of this
tutorial.](/tutorials/tcod/part-10)

