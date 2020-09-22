---
title: "Part 13 - Gearing up"
date: 2020-07-28
draft: true
---

For the final part of this tutorial, we'll implement something that _most_ roguelikes have: equipment. Our implementation will be extremely simple: equipping a weapon increases attack power, and equipping armor increases defense. Many roguelikes have more equipment types than just these two, and the effects of equipment can go much further than this, but this should be enough to get you started.

First, we'll want to define the types of equipment that can be found in the dungeon. As with the `RenderOrder` class, we can use `Enum` to define the types. For now, we'll leave it at weapons and armor, but feel free to add more types as you see fit.

Create a new file, `equipment_types.py`, and put the following contents in it:

```py3
from enum import auto, Enum


class EquipmentType(Enum):
    WEAPON = auto()
    ARMOR = auto()
```

Now it's time to create the component that we'll attach to the equipment. We'll call the component `Equippable`, which will have a few different attributes:

* `equipment_type`: The type of equipment, using the `EquipmentType` enum.
* `power_bonus`: How much the wielder's attack power will be increased. Currently used for just weapons.
* `defense_bonus`: How much the wearer's defense will be increased. Currently just for armor.

Create the file `equippable.py` in the `components` directory, and fill it with the following:

```py3
from __future__ import annotations

from typing import TYPE_CHECKING

from components.base_component import BaseComponent
from equipment_types import EquipmentType

if TYPE_CHECKING:
    from entity import Item


class Equippable(BaseComponent):
    parent: Item

    def __init__(
        self,
        equipment_type: EquipmentType,
        power_bonus: int = 0,
        defense_bonus: int = 0,
    ):
        self.equipment_type = equipment_type

        self.power_bonus = power_bonus
        self.defense_bonus = defense_bonus


class Dagger(Equippable):
    def __init__(self) -> None:
        super().__init__(equipment_type=EquipmentType.WEAPON, power_bonus=2)


class Sword(Equippable):
    def __init__(self) -> None:
        super().__init__(equipment_type=EquipmentType.WEAPON, power_bonus=4)


class LeatherArmor(Equippable):
    def __init__(self) -> None:
        super().__init__(equipment_type=EquipmentType.ARMOR, defense_bonus=1)


class ChainMail(Equippable):
    def __init__(self) -> None:
        super().__init__(equipment_type=EquipmentType.ARMOR, defense_bonus=3)
```

Aside from creating the `Equippable` class, as described earlier, we've also created a few types of equppable components, for each equippable entity that we'll end up creating, similar to what we did with the `Consumable` classes. You don't have to do it this way, you could just define these when creating the entities, but you might want to add additional functionality to weapons and armor at some point, and defining the `Equippable` classes this way might make that easier. You might also want to move these classes to their own file, but that's outside the scope of this tutorial.

To create the actual equppable entities, we'll want to adjust our `Item` class. We can use the same class that we used for our consumables, and just handle them slightly differently. Another approach would be to create another subclass of `Entity`, but for the sake of keeping the number of `Entity` subclasses in this tutorial short, we'll adjust `Item`. Make the following adjustments to `entity.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
...
if TYPE_CHECKING:
    from components.ai import BaseAI
    from components.consumable import Consumable
+   from components.equippable import Equippable
    from components.fighter import Fighter
    from components.inventory import Inventory
    from components.level import Level
    from game_map import GameMap
...

class Item(Entity):
    def __init__(
        self,
        *,
        x: int = 0,
        y: int = 0,
        char: str = "?",
        color: Tuple[int, int, int] = (255, 255, 255),
        name: str = "<Unnamed>",
-       consumable: Consumable,
+       consumable: Optional[Consumable] = None,
+       equippable: Optional[Equippable] = None,
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
-       self.consumable.parent = self

+       if self.consumable:
+           self.consumable.parent = self

+       self.equippable = equippable

+       if self.equippable:
+           self.equippable.parent = self
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>...
if TYPE_CHECKING:
    from components.ai import BaseAI
    from components.consumable import Consumable
    <span class="new-text">from components.equippable import Equippable</span>
    from components.fighter import Fighter
    from components.inventory import Inventory
    from components.level import Level
    from game_map import GameMap
...

class Item(Entity):
    def __init__(
        self,
        *,
        x: int = 0,
        y: int = 0,
        char: str = "?",
        color: Tuple[int, int, int] = (255, 255, 255),
        name: str = "<Unnamed>",
        <span class="crossed-out-text">consumable: Consumable,</span>
        <span class="new-text">consumable: Optional[Consumable] = None,
        equippable: Optional[Equippable] = None,</span>
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
        <span class="crossed-out-text">self.consumable.parent = self</span>

        <span class="new-text">if self.consumable:
            self.consumable.parent = self

        self.equippable = equippable

        if self.equippable:
            self.equippable.parent = self</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

We've added `Equippable` as an optional component for the `Item` class, and also made `Consumable` optional, so that not all `Item` instances will be consumable.

In order to actually create the equippable entities, we'll want to add a few examples to `entity_factories.py`. The entities we will add will correspond to the `Equippable` subclasses we already made. Edit `entity_factories.py` like this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from components.ai import HostileEnemy
-from components import consumable
+from components import consumable, equippable
from components.fighter import Fighter
from components.inventory import Inventory
from components.level import Level

...
lightning_scroll = Item(
    char="~",
    color=(255, 255, 0),
    name="Lightning Scroll",
    consumable=consumable.LightningDamageConsumable(damage=20, maximum_range=5),
)

+dagger = Item(
+   char="/", color=(0, 191, 255), name="Dagger", equippable=equippable.Dagger()
+)
+
+sword = Item(char="/", color=(0, 191, 255), name="Sword", equippable=equippable.Sword())

+leather_armor = Item(
+   char="[",
+   color=(139, 69, 19),
+   name="Leather Armor",
+   equippable=equippable.LeatherArmor(),
+)

+chain_mail = Item(
+   char="[", color=(139, 69, 19), name="Chain Mail", equippable=equippable.ChainMail()
+)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from components.ai import HostileEnemy
<span class="crossed-out-text">from components import consumable</span>
<span class="new-text">from components import consumable, equippable</span>
from components.fighter import Fighter
from components.inventory import Inventory
from components.level import Level

...
lightning_scroll = Item(
    char="~",
    color=(255, 255, 0),
    name="Lightning Scroll",
    consumable=consumable.LightningDamageConsumable(damage=20, maximum_range=5),
)

<span class="new-text">dagger = Item(
    char="/", color=(0, 191, 255), name="Dagger", equippable=equippable.Dagger()
)

sword = Item(char="/", color=(0, 191, 255), name="Sword", equippable=equippable.Sword())

leather_armor = Item(
    char="[",
    color=(139, 69, 19),
    name="Leather Armor",
    equippable=equippable.LeatherArmor(),
)

chain_mail = Item(
    char="[", color=(139, 69, 19), name="Chain Mail", equippable=equippable.ChainMail()
)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

The creation of these entities is very similar to the consumables, except we give them the `Equippable` component instead of `Consumable`. This is all we need to do to create the entities themselves, but we're far from finished. We still need to make these entities appear on the map, make them equippable (there's nothing for them to attach _to_ on the player right now), and make equipping them actually do something.

To handle the equipment that the player has equipped at the moment, we can create yet another component to handle the player's (or the monster's, for that matter) equipment. Create a new file called `equipment.py` in the `components` folder, and add these contents:

```py3
from __future__ import annotations

from typing import Optional, TYPE_CHECKING

from components.base_component import BaseComponent
from equipment_types import EquipmentType

if TYPE_CHECKING:
    from entity import Actor, Item


class Equipment(BaseComponent):
    parent: Actor

    def __init__(self, weapon: Optional[Item] = None, armor: Optional[Item] = None):
        self.weapon = weapon
        self.armor = armor

    @property
    def defense_bonus(self) -> int:
        bonus = 0

        if self.weapon is not None and self.weapon.equippable is not None:
            bonus += self.weapon.equippable.defense_bonus

        if self.armor is not None and self.armor.equippable is not None:
            bonus += self.armor.equippable.defense_bonus

        return bonus

    @property
    def power_bonus(self) -> int:
        bonus = 0

        if self.weapon is not None and self.weapon.equippable is not None:
            bonus += self.weapon.equippable.power_bonus

        if self.armor is not None and self.armor.equippable is not None:
            bonus += self.armor.equippable.power_bonus

        return bonus

    def item_is_equipped(self, item: Item) -> bool:
        return self.weapon == item or self.armor == item

    def unequip_message(self, item_name: str) -> None:
        self.parent.gamemap.engine.message_log.add_message(
            f"You remove the {item_name}."
        )

    def equip_message(self, item_name: str) -> None:
        self.parent.gamemap.engine.message_log.add_message(
            f"You equip the {item_name}."
        )

    def equip_to_slot(self, slot: str, item: Item, add_message: bool) -> None:
        current_item = self.__getattribute__(slot)

        if current_item is not None:
            self.unequip_from_slot(slot, add_message)

        self.__setattr__(slot, item)

        if add_message:
            self.equip_message(item.name)

    def unequip_from_slot(self, slot: str, add_message: bool) -> None:
        current_item = self.__getattribute__(slot)

        if add_message:
            self.unequip_message(current_item.name)

        self.__setattr__(slot, None)

    def toggle_equip(self, equippable_item: Item, add_message: bool = True) -> None:
        if (
            equippable_item.equippable
            and equippable_item.equippable.equipment_type == EquipmentType.WEAPON
        ):
            slot = "weapon"
        else:
            slot = "armor"

        if self.__getattribute__(slot) == equippable_item:
            self.unequip_from_slot(slot, add_message)
        else:
            self.equip_to_slot(slot, equippable_item, add_message)
```

TODO: Explain `equipment.py`


One thing we need to do is change the way `power` and `defense` are calculated in the `Fighter` component. Currently, the values are set directly in the class, but we'll want to calculate them based on their base values (what gets leveled up), and the bonus values (based on the equipment).

We can redefine `power` and `defense` as properties, and rename what we set in the class to `base_power` and `base_defense`. `power` and `defense` will then get their values from their respective bases and equipment bonuses.

This will require edits to several places, but we'll start first with the most obvious: the `Fighter` class itself.

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class Fighter(BaseComponent):
    parent: Actor
 
-   def __init__(self, hp: int, defense: int, power: int):
+   def __init__(self, hp: int, base_defense: int, base_power: int):
        self.max_hp = hp
        self._hp = hp
-       self.defense = defense
-       self.power = power
+       self.base_defense = base_defense
+       self.base_power = base_power

    @property
    def hp(self) -> int:
        return self._hp

    @hp.setter
    def hp(self, value: int) -> None:
        self._hp = max(0, min(value, self.max_hp))
        if self._hp == 0 and self.parent.ai:
            self.die()
 
+   @property
+   def defense(self) -> int:
+       return self.base_defense + self.defense_bonus

+   @property
+   def power(self) -> int:
+       return self.base_power + self.power_bonus

+   @property
+   def defense_bonus(self) -> int:
+       if self.parent.equipment:
+           return self.parent.equipment.defense_bonus
+       else:
+           return 0

+   @property
+   def power_bonus(self) -> int:
+       if self.parent.equipment:
+           return self.parent.equipment.power_bonus
+       else:
+           return 0

    def die(self) -> None:
        if self.engine.player is self.parent:
            death_message = "You died!"
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class Fighter(BaseComponent):
    parent: Actor
 
    <span class="crossed-out-text">def __init__(self, hp: int, defense: int, power: int):</span>
    <span class="new-text">def __init__(self, hp: int, base_defense: int, base_power: int):</span>
        self.max_hp = hp
        self._hp = hp
        <span class="crossed-out-text">self.defense = defense</span>
        <span class="crossed-out-text">self.power = power</span>
        <span class="new-text">self.base_defense = base_defense
        self.base_power = base_power</span>

    @property
    def hp(self) -> int:
        return self._hp

    @hp.setter
    def hp(self, value: int) -> None:
        self._hp = max(0, min(value, self.max_hp))
        if self._hp == 0 and self.parent.ai:
            self.die()
 
    <span class="new-text">@property
    def defense(self) -> int:
        return self.base_defense + self.defense_bonus

    @property
    def power(self) -> int:
        return self.base_power + self.power_bonus

    @property
    def defense_bonus(self) -> int:
        if self.parent.equipment:
            return self.parent.equipment.defense_bonus
        else:
            return 0

    @property
    def power_bonus(self) -> int:
        if self.parent.equipment:
            return self.parent.equipment.power_bonus
        else:
            return 0</span>

    def die(self) -> None:
        if self.engine.player is self.parent:
            death_message = "You died!"</pre>
{{</ original-tab >}}
{{</ codetab >}}

Now, the `power` and `defense` values will be adjusted when the player equips different types of equipment.

We'll need to edit `level.py` to reflect the new attribute names as well:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class Level(BaseComponent):
    ...

    def increase_power(self, amount: int = 1) -> None:
-       self.parent.fighter.power += amount
+       self.parent.fighter.base_power += amount
 
        self.engine.message_log.add_message("You feel stronger!")

        self.increase_level()

    def increase_defense(self, amount: int = 1) -> None:
-       self.parent.fighter.defense += amount
+       self.parent.fighter.base_defense += amount

        self.engine.message_log.add_message("Your movements are getting swifter!")
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class Level(BaseComponent):
    ...

    def increase_power(self, amount: int = 1) -> None:
        <span class="crossed-out-text">self.parent.fighter.power += amount</span>
        <span class="new-text">self.parent.fighter.base_power += amount</span>
 
        self.engine.message_log.add_message("You feel stronger!")

        self.increase_level()

    def increase_defense(self, amount: int = 1) -> None:
        <span class="crossed-out-text">self.parent.fighter.defense += amount</span>
        <span class="new-text">self.parent.fighter.base_defense += amount</span>

        self.engine.message_log.add_message("Your movements are getting swifter!")</pre>
{{</ original-tab >}}
{{</ codetab >}}

`procgen.py`

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
item_chances: Dict[int, List[Tuple[Entity, int]]] = {
    0: [(entity_factories.health_potion, 35)],
    2: [(entity_factories.confusion_scroll, 10)],
-   4: [(entity_factories.lightning_scroll, 25)],
-   6: [(entity_factories.fireball_scroll, 25)],
+   4: [(entity_factories.lightning_scroll, 25), (entity_factories.sword, 5)],
+   6: [(entity_factories.fireball_scroll, 25), (entity_factories.chain_mail, 15)],
}
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>item_chances: Dict[int, List[Tuple[Entity, int]]] = {
    0: [(entity_factories.health_potion, 35)],
    2: [(entity_factories.confusion_scroll, 10)],
    <span class="crossed-out-text">4: [(entity_factories.lightning_scroll, 25)],</span>
    <span class="crossed-out-text">6: [(entity_factories.fireball_scroll, 25)],</span>
    <span class="new-text">4: [(entity_factories.lightning_scroll, 25), (entity_factories.sword, 5)],</span>
    <span class="new-text">6: [(entity_factories.fireball_scroll, 25), (entity_factories.chain_mail, 15)],</span>
}</pre>
{{</ original-tab >}}
{{</ codetab >}}

`actions.py`

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
...
class ItemAction(Action):
    ...

    def perform(self) -> None:
        """Invoke the items ability, this action will be given to provide context."""
-       self.item.consumable.activate(self)
+       if self.item.consumable:
+           self.item.consumable.activate(self)
 
 
class DropItem(ItemAction):
    def perform(self) -> None:
+       if self.entity.equipment.item_is_equipped(self.item):
+           self.entity.equipment.toggle_equip(self.item)

        self.entity.inventory.drop(self.item)
 
 
+class EquipAction(Action):
+   def __init__(self, entity: Actor, item: Item):
+       super().__init__(entity)

+       self.item = item

+   def perform(self) -> None:
+       self.entity.equipment.toggle_equip(self.item)


class WaitAction(Action):
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>...
class ItemAction(Action):
    ...

    def perform(self) -> None:
        """Invoke the items ability, this action will be given to provide context."""
        <span class="crossed-out-text">self.item.consumable.activate(self)</span>
        <span class="new-text">if self.item.consumable:
            self.item.consumable.activate(self)</span>
 
 
class DropItem(ItemAction):
    def perform(self) -> None:
        <span class="new-text">if self.entity.equipment.item_is_equipped(self.item):
            self.entity.equipment.toggle_equip(self.item)</span>

        self.entity.inventory.drop(self.item)
 
 
<span class="new-text">class EquipAction(Action):
    def __init__(self, entity: Actor, item: Item):
        super().__init__(entity)

        self.item = item

    def perform(self) -> None:
        self.entity.equipment.toggle_equip(self.item)</span>


class WaitAction(Action):
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

`entity.py`

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
...
if TYPE_CHECKING:
    from components.ai import BaseAI
    from components.consumable import Consumable
+   from components.equipment import Equipment
+   from components.equippable import Equippable
    from components.fighter import Fighter
    from components.inventory import Inventory
    from components.level import Level
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
+       equipment: Equipment,
        fighter: Fighter,
        inventory: Inventory,
        level: Level,
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
 
+       self.equipment: Equipment = equipment
+       self.equipment.parent = self

        self.fighter = fighter
        self.fighter.parent = self
        
        ...
 
class Item(Entity):
    def __init__(
        self,
        *,
        x: int = 0,
        y: int = 0,
        char: str = "?",
        color: Tuple[int, int, int] = (255, 255, 255),
        name: str = "<Unnamed>",
-       consumable: Consumable,
+       consumable: Optional[Consumable] = None,
+       equippable: Optional[Equippable] = None,
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
-       self.consumable.parent = self

+       if self.consumable:
+           self.consumable.parent = self

+       self.equippable = equippable

+       if self.equippable:
+           self.equippable.parent = self
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>...
if TYPE_CHECKING:
    from components.ai import BaseAI
    from components.consumable import Consumable
    <span class="new-text">from components.equipment import Equipment
    from components.equippable import Equippable</span>
    from components.fighter import Fighter
    from components.inventory import Inventory
    from components.level import Level
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
        <span class="new-text">equipment: Equipment,</span>
        fighter: Fighter,
        inventory: Inventory,
        level: Level,
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
 
        <span class="new-text">self.equipment: Equipment = equipment
        self.equipment.parent = self</span>

        self.fighter = fighter
        self.fighter.parent = self
        
        ...
 
class Item(Entity):
    def __init__(
        self,
        *,
        x: int = 0,
        y: int = 0,
        char: str = "?",
        color: Tuple[int, int, int] = (255, 255, 255),
        name: str = "<Unnamed>",
        <span class="crossed-out-text">consumable: Consumable,</span>
        <span class="new-text">consumable: Optional[Consumable] = None,
        equippable: Optional[Equippable] = None,</span>
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
        <span class="crossed-out-text">self.consumable.parent = self</span>

        <span class="new-text">if self.consumable:
            self.consumable.parent = self

        self.equippable = equippable

        if self.equippable:
            self.equippable.parent = self</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

`entity_factories.py`

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from components.ai import HostileEnemy
-from components import consumable
+from components import consumable, equippable
+from components.equipment import Equipment
from components.fighter import Fighter
from components.inventory import Inventory
from components.level import Level


player = Actor(
    char="@",
    color=(255, 255, 255),
    name="Player",
    ai_cls=HostileEnemy,
-   fighter=Fighter(hp=30, defense=2, power=5),
+   equipment=Equipment(),
+   fighter=Fighter(hp=30, base_defense=1, base_power=2),
    inventory=Inventory(capacity=26),
    level=Level(level_up_base=200),
)
orc = Actor(
    char="o",
    color=(63, 127, 63),
    name="Orc",
    ai_cls=HostileEnemy,
-   fighter=Fighter(hp=10, defense=0, power=3),
+   equipment=Equipment(),
+   fighter=Fighter(hp=10, base_defense=0, base_power=3),
    inventory=Inventory(capacity=0),
    level=Level(xp_given=35),
)
troll = Actor(
    char="T",
    color=(0, 127, 0),
    name="Troll",
    ai_cls=HostileEnemy,
-   fighter=Fighter(hp=16, defense=1, power=4),
+   equipment=Equipment(),
+   fighter=Fighter(hp=16, base_defense=1, base_power=4),
    inventory=Inventory(capacity=0),
    level=Level(xp_given=100),
)

...
lightning_scroll = Item(
    char="~",
    color=(255, 255, 0),
    name="Lightning Scroll",
    consumable=consumable.LightningDamageConsumable(damage=20, maximum_range=5),
)

+dagger = Item(
+   char="/", color=(0, 191, 255), name="Dagger", equippable=equippable.Dagger()
+)
+
+sword = Item(char="/", color=(0, 191, 255), name="Sword", equippable=equippable.Sword())

+leather_armor = Item(
+   char="[",
+   color=(139, 69, 19),
+   name="Leather Armor",
+   equippable=equippable.LeatherArmor(),
+)

+chain_mail = Item(
+   char="[", color=(139, 69, 19), name="Chain Mail", equippable=equippable.ChainMail()
+)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from components.ai import HostileEnemy
<span class="crossed-out-text">from components import consumable</span>
<span class="new-text">from components import consumable, equippable
from components.equipment import Equipment</span>
from components.fighter import Fighter
from components.inventory import Inventory
from components.level import Level


player = Actor(
    char="@",
    color=(255, 255, 255),
    name="Player",
    ai_cls=HostileEnemy,
    <span class="crossed-out-text">fighter=Fighter(hp=30, defense=2, power=5),</span>
    <span class="new-text">equipment=Equipment(),
    fighter=Fighter(hp=30, base_defense=1, base_power=2),</span>
    inventory=Inventory(capacity=26),
    level=Level(level_up_base=200),
)
orc = Actor(
    char="o",
    color=(63, 127, 63),
    name="Orc",
    ai_cls=HostileEnemy,
    <span class="crossed-out-text">fighter=Fighter(hp=10, defense=0, power=3),</span>
    <span class="new-text">equipment=Equipment(),
    fighter=Fighter(hp=10, base_defense=0, base_power=3),</span>
    inventory=Inventory(capacity=0),
    level=Level(xp_given=35),
)
troll = Actor(
    char="T",
    color=(0, 127, 0),
    name="Troll",
    ai_cls=HostileEnemy,
    <span class="crossed-out-text">fighter=Fighter(hp=16, defense=1, power=4),</span>
    <span class="new-text">equipment=Equipment(),
    fighter=Fighter(hp=16, base_defense=1, base_power=4),</span>
    inventory=Inventory(capacity=0),
    level=Level(xp_given=100),
)

...
lightning_scroll = Item(
    char="~",
    color=(255, 255, 0),
    name="Lightning Scroll",
    consumable=consumable.LightningDamageConsumable(damage=20, maximum_range=5),
)

<span class="new-text">dagger = Item(
    char="/", color=(0, 191, 255), name="Dagger", equippable=equippable.Dagger()
)

sword = Item(char="/", color=(0, 191, 255), name="Sword", equippable=equippable.Sword())

leather_armor = Item(
    char="[",
    color=(139, 69, 19),
    name="Leather Armor",
    equippable=equippable.LeatherArmor(),
)

chain_mail = Item(
    char="[", color=(139, 69, 19), name="Chain Mail", equippable=equippable.ChainMail()
)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

`input_handlers.py`

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class InventoryEventHandler(AskUserEventHandler):
    def on_render(self, console: tcod.Console) -> None:
        ...

        if number_of_items_in_inventory > 0:
            for i, item in enumerate(self.engine.player.inventory.items):
                item_key = chr(ord("a") + i)
-               console.print(x + 1, y + i + 1, f"({item_key}) {item.name}")

+               is_equipped = self.engine.player.equipment.item_is_equipped(item)

+               item_string = f"({item_key}) {item.name}"

+               if is_equipped:
+                   item_string = f"{item_string} (E)"

+               console.print(x + 1, y + i + 1, item_string)
        else:
            console.print(x + 1, y + 1, "(Empty)")
 
class InventoryActivateHandler(InventoryEventHandler):
    """Handle using an inventory item."""

    TITLE = "Select an item to use"

    def on_item_selected(self, item: Item) -> Optional[ActionOrHandler]:
-       """Return the action for the selected item."""
-       return item.consumable.get_action(self.engine.player)
+       if item.consumable:
+           """Return the action for the selected item."""
+           return item.consumable.get_action(self.engine.player)
+       elif item.equippable:
+           return actions.EquipAction(self.engine.player, item)
+       else:
+           return None


class InventoryDropHandler(InventoryEventHandler):
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class InventoryEventHandler(AskUserEventHandler):
    def on_render(self, console: tcod.Console) -> None:
        ...

        if number_of_items_in_inventory > 0:
            for i, item in enumerate(self.engine.player.inventory.items):
                item_key = chr(ord("a") + i)
                <span class="crossed-out-text">console.print(x + 1, y + i + 1, f"({item_key}) {item.name}")</span>

                <span class="new-text">is_equipped = self.engine.player.equipment.item_is_equipped(item)

                item_string = f"({item_key}) {item.name}"

                if is_equipped:
                    item_string = f"{item_string} (E)"

                console.print(x + 1, y + i + 1, item_string)</span>
        else:
            console.print(x + 1, y + 1, "(Empty)")
 
class InventoryActivateHandler(InventoryEventHandler):
    """Handle using an inventory item."""

    TITLE = "Select an item to use"

    def on_item_selected(self, item: Item) -> Optional[ActionOrHandler]:
        <span class="crossed-out-text">"""Return the action for the selected item."""</span>
        <span class="crossed-out-text">return item.consumable.get_action(self.engine.player)</span>
        <span class="new-text">if item.consumable:
            """Return the action for the selected item."""
            return item.consumable.get_action(self.engine.player)
        elif item.equippable:
            return actions.EquipAction(self.engine.player, item)
        else:
            return None</span>


class InventoryDropHandler(InventoryEventHandler):
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

One last thing we can do is give the player a bit of equipment to start. We'll spawn a dagger and leather armor, and immediately add them to the player's inventory.

`setup_game.py`

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
def new_game() -> Engine:
    ...

    engine.message_log.add_message(
        "Hello and welcome, adventurer, to yet another dungeon!", color.welcome_text
    )

+   dagger = copy.deepcopy(entity_factories.dagger)
+   leather_armor = copy.deepcopy(entity_factories.leather_armor)

+   dagger.parent = player.inventory
+   leather_armor.parent = player.inventory

+   player.inventory.items.append(dagger)
+   player.equipment.toggle_equip(dagger, add_message=False)

+   player.inventory.items.append(leather_armor)
+   player.equipment.toggle_equip(leather_armor, add_message=False)

    return engine
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>def new_game() -> Engine:
    ...

    engine.message_log.add_message(
        "Hello and welcome, adventurer, to yet another dungeon!", color.welcome_text
    )

    <span class="new-text">dagger = copy.deepcopy(entity_factories.dagger)
    leather_armor = copy.deepcopy(entity_factories.leather_armor)

    dagger.parent = player.inventory
    leather_armor.parent = player.inventory

    player.inventory.items.append(dagger)
    player.equipment.toggle_equip(dagger, add_message=False)

    player.inventory.items.append(leather_armor)
    player.equipment.toggle_equip(leather_armor, add_message=False)</span>

    return engine</pre>
{{</ original-tab >}}
{{</ codetab >}}
