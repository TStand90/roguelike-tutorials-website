---
title: "Part 13 - Gearing up"
date: 2019-03-30T09:34:10-07:00
draft: false
aliases: /tutorials/tcod/part-13
---
For the final part of our tutorial series, we'll take a look at
implementing some equipment. Equipment is a subtype of items that the
player can equip for some stat boosts. Obviously it can get more
complicated than that, depending on the game, but I'll leave it up to
you to implement that depending on your needs. For this tutorial,
equipping a weapon will increase attack power, and equipping a shield
will increase defense.

You might've already guessed at this point, but we'll need a new
component that tells us which items are equippable, and what the effects
of equipping them are. This component we'll call `Equippable`, and we'll
put it in a file called `equippable.py`, which, of course, lives in the
`components` directory.

{{< highlight py3 >}}
class Equippable:
    def __init__(self, slot, power_bonus=0, defense_bonus=0, max_hp_bonus=0):
        self.slot = slot
        self.power_bonus = power_bonus
        self.defense_bonus = defense_bonus
        self.max_hp_bonus = max_hp_bonus
{{</ highlight >}}

`power_bonus`, `defense_bonus`, and `max_hp_bonus` will be the bonuses
that the player gets from equipping a certain item. A weapon will give a
power bonus, and a shield will give a defense bonus. We won't add
anything with an HP bonus in this tutorial, but you could use this for
something like armor or a ring that increases health.

But what about `slot`? That describes what the equipment piece gets
equipped to. The player will have two different equipment slots
available: the main hand (for weapons) and off hand (for shields). We'll
implement that as an `enum`. Create a file called `equipment_slots.py`
in the base directory, and add the following to it:

{{< highlight py3 >}}
from enum import Enum


class EquipmentSlots(Enum):
    MAIN_HAND = 1
    OFF_HAND = 2
{{</ highlight >}}

You can extend this as much as you want, to give the player slots for
things like head, body, legs, or fingers for rings.

Now we have what we need in place for items to become "equippable", but
what do they become equipped to? For that, we'll need another component,
which we'll call `Equipment`. Put the following in a new file, in the
`components` folder, called `equipment.py`:

{{< highlight py3 >}}
from equipment_slots import EquipmentSlots


class Equipment:
    def __init__(self, main_hand=None, off_hand=None):
        self.main_hand = main_hand
        self.off_hand = off_hand

    @property
    def max_hp_bonus(self):
        bonus = 0

        if self.main_hand and self.main_hand.equippable:
            bonus += self.main_hand.equippable.max_hp_bonus

        if self.off_hand and self.off_hand.equippable:
            bonus += self.off_hand.equippable.max_hp_bonus

        return bonus

    @property
    def power_bonus(self):
        bonus = 0

        if self.main_hand and self.main_hand.equippable:
            bonus += self.main_hand.equippable.power_bonus

        if self.off_hand and self.off_hand.equippable:
            bonus += self.off_hand.equippable.power_bonus

        return bonus

    @property
    def defense_bonus(self):
        bonus = 0

        if self.main_hand and self.main_hand.equippable:
            bonus += self.main_hand.equippable.defense_bonus

        if self.off_hand and self.off_hand.equippable:
            bonus += self.off_hand.equippable.defense_bonus

        return bonus

    def toggle_equip(self, equippable_entity):
        results = []

        slot = equippable_entity.equippable.slot

        if slot == EquipmentSlots.MAIN_HAND:
            if self.main_hand == equippable_entity:
                self.main_hand = None
                results.append({'dequipped': equippable_entity})
            else:
                if self.main_hand:
                    results.append({'dequipped': self.main_hand})

                self.main_hand = equippable_entity
                results.append({'equipped': equippable_entity})
        elif slot == EquipmentSlots.OFF_HAND:
            if self.off_hand == equippable_entity:
                self.off_hand = None
                results.append({'dequipped': equippable_entity})
            else:
                if self.off_hand:
                    results.append({'dequipped': self.off_hand})

                self.off_hand = equippable_entity
                results.append({'equipped': equippable_entity})

        return results
{{</ highlight >}}

That's a lot of code all at once, so let's break things down a bit.

The two variables `main_hand` and `off_hand` will hold the entities that
we're equipping. If they are set to `None`, then that means nothing is
equipped to that slot.

The three properties all do essentially the same thing: they sum up the
"bonuses" from both the main hand and off hand equipment, and return the
value. Since we're using properties, these values can be accessed like a
regular variable, which will come in handy soon enough. If the player
has equipment in both the main hand and off hand that increases attack,
for instance, then we'll get the bonus the same either way.

`toggle_equip` is what we'll call when we're either equipping or
dequipping an item. If the item was not previously equipped, we equip
it, removing any previously equipped item. If it's equipped already,
we'll assume the player meant to remove it, and just dequip it. We
return the results of this operation similarly to how we've done with
other functions, which the `engine` will process.

Like the other components we've created, we'll need to add these new
ones to the `Entity` class.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
import tcod as libtcod

import math

+from components.item import Item

from render_functions import RenderOrder


class Entity:
    def __init__(self, x, y, char, color, name, blocks=False, render_order=RenderOrder.CORPSE, fighter=None, ai=None,
-                item=None, inventory=None, stairs=None, level=None):
+                item=None, inventory=None, stairs=None, level=None, equipment=None, equippable=None):
        self.x = x
        self.y = y
        self.char = char
        self.color = color
        self.name = name
        self.blocks = blocks
        self.render_order = render_order
        self.fighter = fighter
        self.ai = ai
        self.item = item
        self.inventory = inventory
        self.stairs = stairs
        self.level = level
+       self.equipment = equipment
+       self.equippable = equippable

        if self.fighter:
            self.fighter.owner = self

        if self.ai:
            self.ai.owner = self

        if self.item:
            self.item.owner = self

        if self.inventory:
            self.inventory.owner = self

        if self.stairs:
            self.stairs.owner = self

        if self.level:
            self.level.owner = self

+       if self.equipment:
+           self.equipment.owner = self
+
+       if self.equippable:
+           self.equippable.owner = self
+
+           if not self.item:
+               item = Item()
+               self.item = item
+               self.item.owner = self

    def move(self, dx, dy):
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>import tcod as libtcod

import math

<span class="new-text">from components.item import Item</span>

from render_functions import RenderOrder


class Entity:
    def __init__(self, x, y, char, color, name, blocks=False, render_order=RenderOrder.CORPSE, fighter=None, ai=None,
                 item=None, inventory=None, stairs=None, level=None<span class="new-text">, equipment=None, equippable=None</span>):
        self.x = x
        self.y = y
        self.char = char
        self.color = color
        self.name = name
        self.blocks = blocks
        self.render_order = render_order
        self.fighter = fighter
        self.ai = ai
        self.item = item
        self.inventory = inventory
        self.stairs = stairs
        self.level = level
        <span class="new-text">self.equipment = equipment
        self.equippable = equippable</span>

        if self.fighter:
            self.fighter.owner = self

        if self.ai:
            self.ai.owner = self

        if self.item:
            self.item.owner = self

        if self.inventory:
            self.inventory.owner = self

        if self.stairs:
            self.stairs.owner = self

        if self.level:
            self.level.owner = self

        <span class="new-text">if self.equipment:
            self.equipment.owner = self

        if self.equippable:
            self.equippable.owner = self

            if not self.item:
                item = Item()
                self.item = item
                self.item.owner = self</span>

    def move(self, dx, dy):
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Notice that if the entity does not have an `Item` component, then we add
one. This is because every piece of equipment is also an item by
definition, because it gets added to the inventory, picked up, and
dropped.

Let's add the new `Equipment` component to the player, in
`initialize_new_game.py`:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
    ...
    level_component = Level()
+   equipment_component = Equipment()
-   player = Entity(0, 0, '@', libtcod.white, 'Player', blocks=True, render_order=RenderOrder.ACTOR,
-                   fighter=fighter_component, inventory=inventory_component, level=level_component)
+   player = Entity(0, 0, '@', libtcod.white, 'Player', blocks=True, render_order=RenderOrder.ACTOR,
+                   fighter=fighter_component, inventory=inventory_component, level=level_component,
+                   equipment=equipment_component)
    entities = [player]
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>    ...
    level_component = Level()
    <span class="new-text">equipment_component = Equipment()</span>
    <span class="crossed-out-text">player = Entity(0, 0, '@', libtcod.white, 'Player', blocks=True, render_order=RenderOrder.ACTOR,</span>
                    <span class="crossed-out-text">fighter=fighter_component, inventory=inventory_component, level=level_component)</span>
    <span class="new-text">player = Entity(0, 0, '@', libtcod.white, 'Player', blocks=True, render_order=RenderOrder.ACTOR,
                    fighter=fighter_component, inventory=inventory_component, level=level_component,
                    equipment=equipment_component)</span>
    entities = [player]
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Be sure to import the component in this file as well.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
import tcod as libtcod

+from components.equipment import Equipment
from components.fighter import Fighter
from components.inventory import Inventory
from components.level import Level
...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>import tcod as libtcod

<span class="new-text">from components.equipment import Equipment</span>
from components.fighter import Fighter
from components.inventory import Inventory
from components.level import Level
...</pre>
{{</ original-tab >}}
{{</ codetab >}}

So how does the player actually go about equipping a piece of equipment?
Well, the equipment will be viewable from the inventory screen like any
usable item, so why not just extend that? We can modify the `use` method
in `Inventory` to equip an item if its equippable, like this:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
        ...
        if item_component.use_function is None:
-           results.append({'message': Message('The {0} cannot be used'.format(item_entity.name), libtcod.yellow)})
+           equippable_component = item_entity.equippable
+
+           if equippable_component:
+               results.append({'equip': item_entity})
+           else:
+               results.append({'message': Message('The {0} cannot be used'.format(item_entity.name), libtcod.yellow)})
        else:
            ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>        ...
        if item_component.use_function is None:
            <span class="crossed-out-text">results.append({'message': Message('The {0} cannot be used'.format(item_entity.name), libtcod.yellow)})</span>
            <span class="new-text">equippable_component = item_entity.equippable

            if equippable_component:
                results.append({'equip': item_entity})
            else:
                results.append({'message': Message('The {0} cannot be used'.format(item_entity.name), libtcod.yellow)})</span>
        else:
            ...
</pre>
{{</ original-tab >}}
{{</ codetab >}}

Now the method checks if the item is equippable, and if so, we return
the equip result. If not, we display the warning message about it not
being usable, as usual.

Let's up the `toggle_equip` method into action, in `engine.py`:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
            ...
            item_dropped = player_turn_result.get('item_dropped')
+           equip = player_turn_result.get('equip')
            targeting = player_turn_result.get('targeting')
            ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>            ...
            item_dropped = player_turn_result.get('item_dropped')
            <span class="new-text">equip = player_turn_result.get('equip')</span>
            targeting = player_turn_result.get('targeting')
            ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
            ...
            if item_dropped:
                entities.append(item_dropped)

                game_state = GameStates.ENEMY_TURN

+           if equip:
+               equip_results = player.equipment.toggle_equip(equip)
+
+               for equip_result in equip_results:
+                   equipped = equip_result.get('equipped')
+                   dequipped = equip_result.get('dequipped')
+
+                   if equipped:
+                       message_log.add_message(Message('You equipped the {0}'.format(equipped.name)))
+
+                   if dequipped:
+                       message_log.add_message(Message('You dequipped the {0}'.format(dequipped.name)))
+
+               game_state = GameStates.ENEMY_TURN

            if targeting:
            ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>            ...
            if item_dropped:
                entities.append(item_dropped)

                game_state = GameStates.ENEMY_TURN

            <span class="new-text">if equip:
                equip_results = player.equipment.toggle_equip(equip)

                for equip_result in equip_results:
                    equipped = equip_result.get('equipped')
                    dequipped = equip_result.get('dequipped')

                    if equipped:
                        message_log.add_message(Message('You equipped the {0}'.format(equipped.name)))

                    if dequipped:
                        message_log.add_message(Message('You dequipped the {0}'.format(dequipped.name)))

                game_state = GameStates.ENEMY_TURN</span>

            if targeting:
            ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

There's a little bug with our current implementation. The player can
drop an item from the inventory, yet still have it "equipped"\! That's
obviously not right, so let's fix that in the `Inventory` method
`drop_item`:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
   ...
    def drop_item(self, item):
        results = []

+       if self.owner.equipment.main_hand == item or self.owner.equipment.off_hand == item:
+           self.owner.equipment.toggle_equip(item)

        item.x = self.owner.x
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>   ...
    def drop_item(self, item):
        results = []

        <span class="new-text">if self.owner.equipment.main_hand == item or self.owner.equipment.off_hand == item:
            self.owner.equipment.toggle_equip(item)</span>

        item.x = self.owner.x
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

So what does equipping something actually *do*? It *should* give bonuses
to the player's fighting ability, but it's not actually doing that right
now. Why? Because our `Fighter` component doesn't take equipment bonuses
into account\! Let's fix that now.

We need do adjust the way we get the values from `Fighter`. It'd be
better if the `max_hp`, `power`, and `defense` were properties, so we
could calculate them as their base plus the bonus at any given time.
Let's change the initialization function to set the bases of each of
these values, and we'll add properties for each to take the place of our
old variables.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
class Fighter:
    def __init__(self, hp, defense, power, xp=0):
-       self.max_hp = hp
+       self.base_max_hp = hp
        self.hp = hp
-       self.defense = defense
+       self.base_defense = defense
-       self.power = power
+       self.base_power = power
        self.xp = xp

+   @property
+   def max_hp(self):
+       if self.owner and self.owner.equipment:
+           bonus = self.owner.equipment.max_hp_bonus
+       else:
+           bonus = 0
+
+       return self.base_max_hp + bonus
+
+   @property
+   def power(self):
+       if self.owner and self.owner.equipment:
+           bonus = self.owner.equipment.power_bonus
+       else:
+           bonus = 0
+
+       return self.base_power + bonus
+
+   @property
+   def defense(self):
+       if self.owner and self.owner.equipment:
+           bonus = self.owner.equipment.defense_bonus
+       else:
+           bonus = 0
+
+       return self.base_defense + bonus

    def take_damage(self, amount):
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class Fighter:
    def __init__(self, hp, defense, power, xp=0):
        <span class="crossed-out-text">self.max_hp = hp</span>
        <span class="new-text">self.base_max_hp = hp</span>
        self.hp = hp
        <span class="crossed-out-text">self.defense = defense</span>
        <span class="new-text">self.base_defense = defense</span>
        <span class="crossed-out-text">self.power = power</span>
        <span class="new-text">self.base_power = power</span>
        self.xp = xp

    <span class="new-text">@property
    def max_hp(self):
        if self.owner and self.owner.equipment:
            bonus = self.owner.equipment.max_hp_bonus
        else:
            bonus = 0

        return self.base_max_hp + bonus

    @property
    def power(self):
        if self.owner and self.owner.equipment:
            bonus = self.owner.equipment.power_bonus
        else:
            bonus = 0

        return self.base_power + bonus

    @property
    def defense(self):
        if self.owner and self.owner.equipment:
            bonus = self.owner.equipment.defense_bonus
        else:
            bonus = 0

        return self.base_defense + bonus</span>

    def take_damage(self, amount):
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

So now when we query for the player's `power`, for example, we'll be
taking into account what equipment is equipped.

For the most part, this just works. The only thing that doesn't is our
previous level up code, because we were increasing the `max_hp`,
`power`, and `defense` values directly, whereas now we need to increase
their bases. It's a pretty easy fix though, just open `engine.py` and
make the following adjustment.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
        ...
        if level_up:
            if level_up == 'hp':
-               player.fighter.max_hp += 20
+               player.fighter.base_max_hp += 20
                player.fighter.hp += 20
            elif level_up == 'str':
-               player.fighter.power += 1
+               player.fighter.base_power += 1
            elif level_up == 'def':
-               player.fighter.defense += 1
+               player.fighter.base_defense += 1
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>        ...
        if level_up:
            if level_up == 'hp':
                <span class="crossed-out-text">player.fighter.max_hp += 20</span>
                <span class="new-text">player.fighter.base_max_hp += 20</span>
                player.fighter.hp += 20
            elif level_up == 'str':
                <span class="crossed-out-text">player.fighter.power += 1</span>
                <span class="new-text">player.fighter.base_power += 1</span>
            elif level_up == 'def':
                <span class="crossed-out-text">player.fighter.defense += 1</span>
                <span class="new-text">player.fighter.base_defense += 1</span>
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

With all that in place, let's actually put some equipment on the map\!
Open up `game_map.py` and modify the `place_entities` function to place
some equipment in the dungeon. Remember to import the needed components
at the top.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
...
from components.ai import BasicMonster
+from components.equipment import EquipmentSlots
+from components.equippable import Equippable
from components.fighter import Fighter
...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>...
from components.ai import BasicMonster
<span class="new-text">from components.equipment import EquipmentSlots
from components.equippable import Equippable</span>
from components.fighter import Fighter
...</pre>
{{</ original-tab >}}
{{</ codetab >}}

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
       item_chances = {
            'healing_potion': 35,
+           'sword': from_dungeon_level([[5, 4]], self.dungeon_level),
+           'shield': from_dungeon_level([[15, 8]], self.dungeon_level),
            'lightning_scroll': from_dungeon_level([[25, 4]], self.dungeon_level),
            'fireball_scroll': from_dungeon_level([[25, 6]], self.dungeon_level),
            'confusion_scroll': from_dungeon_level([[10, 2]], self.dungeon_level)
        }
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>       item_chances = {
            'healing_potion': 35,
            <span class="new-text">'sword': from_dungeon_level([[5, 4]], self.dungeon_level),
            'shield': from_dungeon_level([[15, 8]], self.dungeon_level),</span>
            'lightning_scroll': from_dungeon_level([[25, 4]], self.dungeon_level),
            'fireball_scroll': from_dungeon_level([[25, 6]], self.dungeon_level),
            'confusion_scroll': from_dungeon_level([[10, 2]], self.dungeon_level)
        }</pre>
{{</ original-tab >}}
{{</ codetab >}}

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
               ...
                if item_choice == 'healing_potion':
                    item_component = Item(use_function=heal, amount=40)
                    item = Entity(x, y, '!', libtcod.violet, 'Healing Potion', render_order=RenderOrder.ITEM,
                                  item=item_component)
+               elif item_choice == 'sword':
+                   equippable_component = Equippable(EquipmentSlots.MAIN_HAND, power_bonus=3)
+                   item = Entity(x, y, '/', libtcod.sky, 'Sword', equippable=equippable_component)
+               elif item_choice == 'shield':
+                   equippable_component = Equippable(EquipmentSlots.OFF_HAND, defense_bonus=1)
+                   item = Entity(x, y, '[', libtcod.darker_orange, 'Shield', equippable=equippable_component)
                elif item_choice == 'fireball_scroll':
                    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>               ...
                if item_choice == 'healing_potion':
                    item_component = Item(use_function=heal, amount=40)
                    item = Entity(x, y, '!', libtcod.violet, 'Healing Potion', render_order=RenderOrder.ITEM,
                                  item=item_component)
                <span class="new-text">elif item_choice == 'sword':
                    equippable_component = Equippable(EquipmentSlots.MAIN_HAND, power_bonus=3)
                    item = Entity(x, y, '/', libtcod.sky, 'Sword', equippable=equippable_component)
                elif item_choice == 'shield':
                    equippable_component = Equippable(EquipmentSlots.OFF_HAND, defense_bonus=1)
                    item = Entity(x, y, '[', libtcod.darker_orange, 'Shield', equippable=equippable_component)</span>
                elif item_choice == 'fireball_scroll':
                    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

One thing we can do to make the game a bit more interesting is give the
player a default weapon to start with. Nothing too powerful of course;
this is a roguelike after all. Let's modify the `get_game_variables`
function in `initialize_new_game.py` to give the player a dagger at the
start.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
import tcod as libtcod

from components.equipment import Equipment
+from components.equippable import Equippable
from components.fighter import Fighter
from components.inventory import Inventory
from components.level import Level

from entity import Entity

+from equipment_slots import EquipmentSlots

from game_messages import MessageLog
...

def get_game_variables(constants):
-   fighter_component = Fighter(hp=100, defense=1, power=4)
+   fighter_component = Fighter(hp=100, defense=1, power=2)
    inventory_component = Inventory(26)
    level_component = Level()
    equipment_component = Equipment()
    player = Entity(0, 0, '@', libtcod.white, 'Player', blocks=True, render_order=RenderOrder.ACTOR,
                    fighter=fighter_component, inventory=inventory_component, level=level_component,
                    equipment=equipment_component)
    entities = [player]

+   equippable_component = Equippable(EquipmentSlots.MAIN_HAND, power_bonus=2)
+   dagger = Entity(0, 0, '-', libtcod.sky, 'Dagger', equippable=equippable_component)
+   player.inventory.add_item(dagger)
+   player.equipment.toggle_equip(dagger)

    game_map = GameMap(constants['map_width'], constants['map_height'])
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>import tcod as libtcod

from components.equipment import Equipment
<span class="new-text">from components.equippable import Equippable</span>
from components.fighter import Fighter
from components.inventory import Inventory
from components.level import Level

from entity import Entity

<span class="new-text">from equipment_slots import EquipmentSlots</span>

from game_messages import MessageLog
...

def get_game_variables(constants):
    <span class="crossed-out-text">fighter_component = Fighter(hp=100, defense=1, power=4)</span>
    <span class="new-text">fighter_component = Fighter(hp=100, defense=1, power=2)</span>
    inventory_component = Inventory(26)
    level_component = Level()
    equipment_component = Equipment()
    player = Entity(0, 0, '@', libtcod.white, 'Player', blocks=True, render_order=RenderOrder.ACTOR,
                    fighter=fighter_component, inventory=inventory_component, level=level_component,
                    equipment=equipment_component)
    entities = [player]

    <span class="new-text">equippable_component = Equippable(EquipmentSlots.MAIN_HAND, power_bonus=2)
    dagger = Entity(0, 0, '-', libtcod.sky, 'Dagger', equippable=equippable_component)
    player.inventory.add_item(dagger)
    player.equipment.toggle_equip(dagger)</span>

    game_map = GameMap(constants['map_width'], constants['map_height'])
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Note that we also modified the player's starting power. We don't want
the player to start off too strong\!

One last bit of polish to add: let's show in the inventory screen which
items are equipped. We can do this by modifying the `inventory_menu`
function in `menus.py` to check if each item is equipped or not. We'll
have to make a change in the function's arguments though; we need to
pass the `player` instead of just the inventory. Modify the function
like
    so:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
-def inventory_menu(con, header, inventory, inventory_width, screen_width, screen_height):
+def inventory_menu(con, header, player, inventory_width, screen_width, screen_height):
-   if len(inventory.items) == 0:
+   if len(player.inventory.items) == 0:
        options = ['Inventory is empty.']
    else:
-       options = [item.name for item in inventory.items]
+       options = []
+
+       for item in player.inventory.items:
+           if player.equipment.main_hand == item:
+               options.append('{0} (on main hand)'.format(item.name))
+           elif player.equipment.off_hand == item:
+               options.append('{0} (on off hand)'.format(item.name))
+           else:
+               options.append(item.name)

    menu(con, header, options, inventory_width, screen_width, screen_height)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre><span class="crossed-out-text">def inventory_menu(con, header, inventory, inventory_width, screen_width, screen_height):</span>
<span class="new-text">def inventory_menu(con, header, player, inventory_width, screen_width, screen_height):</span>
    <span class="crossed-out-text">if len(inventory.items) == 0:</span>
    <span class="new-text">if len(player.inventory.items) == 0:</span>
        options = ['Inventory is empty.']
    else:
        <span class="crossed-out-text">options = [item.name for item in inventory.items]</span>
        <span class="new-text">options = []

        for item in player.inventory.items:
            if player.equipment.main_hand == item:
                options.append('{0} (on main hand)'.format(item.name))
            elif player.equipment.off_hand == item:
                options.append('{0} (on off hand)'.format(item.name))
            else:
                options.append(item.name)</span>

    menu(con, header, options, inventory_width, screen_width, screen_height)</pre>
{{</ original-tab >}}
{{</ codetab >}}

Because we changed the arguments of this function, we'll need to adjust
the call we make to it in `render_all`.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
        ...
            inventory_title = 'Press the key next to an item to drop it, or Esc to cancel.\n'

-       inventory_menu(con, inventory_title, player.inventory, 50, screen_width, screen_height)
+       inventory_menu(con, inventory_title, player, 50, screen_width, screen_height)

    elif game_state == GameStates.LEVEL_UP:
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>
        ...
            inventory_title = 'Press the key next to an item to drop it, or Esc to cancel.\n'

        <span class="crossed-out-text">inventory_menu(con, inventory_title, player.inventory, 50, screen_width, screen_height)</span>
        <span class="new-text">inventory_menu(con, inventory_title, player, 50, screen_width, screen_height)</span>

    elif game_state == GameStates.LEVEL_UP:
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

With that, we have a functional equipment system\! This concludes the
main tutorial. If you're wanting more, feel free to check out the extras
section, which I'll try to update now and then with some new content.
Now go forth, and create the roguelike of your dreams\!

If you want to see the code in its entirety [click
here](https://github.com/TStand90/roguelike_tutorial_revised/tree/part13).

<script src="/js/codetabs.js"></script>
