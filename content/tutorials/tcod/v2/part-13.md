---
title: "Part 13 - Gearing up"
date: 2020-07-28
draft: true
---

diff --git a/actions.py b/actions.py
index 439c055..b7a8fde 100644
--- a/actions.py
+++ b/actions.py
@@ -75,14 +75,28 @@ class ItemAction(Action):
 
     def perform(self) -> None:
         """Invoke the items ability, this action will be given to provide context."""
-        self.item.consumable.activate(self)
+        if self.item.consumable:
+            self.item.consumable.activate(self)
 
 
 class DropItem(ItemAction):
     def perform(self) -> None:
+        if self.entity.equipment.item_is_equipped(self.item):
+            self.entity.equipment.toggle_equip(self.item)
+
         self.entity.inventory.drop(self.item)
 
 
+class EquipAction(Action):
+    def __init__(self, entity: Actor, item: Item):
+        super().__init__(entity)
+
+        self.item = item
+
+    def perform(self) -> None:
+        self.entity.equipment.toggle_equip(self.item)
+
+
 class WaitAction(Action):
     def perform(self) -> None:
         pass
diff --git a/components/equipment.py b/components/equipment.py
new file mode 100644
index 0000000..4b72afa
--- /dev/null
+++ b/components/equipment.py
@@ -0,0 +1,87 @@
+from __future__ import annotations
+
+from typing import Optional, TYPE_CHECKING
+
+from components.base_component import BaseComponent
+from equipment_types import EquipmentType
+
+if TYPE_CHECKING:
+    from entity import Actor, Item
+
+
+class Equipment(BaseComponent):
+    parent: Actor
+
+    def __init__(self, weapon: Optional[Item] = None, armor: Optional[Item] = None):
+        self.weapon = weapon
+        self.armor = armor
+
+    @property
+    def defense_bonus(self) -> int:
+        bonus = 0
+
+        if self.weapon is not None and self.weapon.equippable is not None:
+            bonus += self.weapon.equippable.defense_bonus
+
+        if self.armor is not None and self.armor.equippable is not None:
+            bonus += self.armor.equippable.defense_bonus
+
+        return bonus
+
+    @property
+    def power_bonus(self) -> int:
+        bonus = 0
+
+        if self.weapon is not None and self.weapon.equippable is not None:
+            bonus += self.weapon.equippable.power_bonus
+
+        if self.armor is not None and self.armor.equippable is not None:
+            bonus += self.armor.equippable.power_bonus
+
+        return bonus
+
+    def item_is_equipped(self, item: Item) -> bool:
+        return self.weapon == item or self.armor == item
+
+    def unequip_message(self, item_name: str) -> None:
+        self.parent.gamemap.engine.message_log.add_message(
+            f"You remove the {item_name}."
+        )
+
+    def equip_message(self, item_name: str) -> None:
+        self.parent.gamemap.engine.message_log.add_message(
+            f"You equip the {item_name}."
+        )
+
+    def equip_to_slot(self, slot: str, item: Item, add_message: bool) -> None:
+        current_item = self.__getattribute__(slot)
+
+        if current_item is not None:
+            self.unequip_from_slot(slot, add_message)
+
+        self.__setattr__(slot, item)
+
+        if add_message:
+            self.equip_message(item.name)
+
+    def unequip_from_slot(self, slot: str, add_message: bool) -> None:
+        current_item = self.__getattribute__(slot)
+
+        if add_message:
+            self.unequip_message(current_item.name)
+
+        self.__setattr__(slot, None)
+
+    def toggle_equip(self, equippable_item: Item, add_message: bool = True) -> None:
+        if (
+            equippable_item.equippable
+            and equippable_item.equippable.equipment_type == EquipmentType.WEAPON
+        ):
+            slot = "weapon"
+        else:
+            slot = "armor"
+
+        if self.__getattribute__(slot) == equippable_item:
+            self.unequip_from_slot(slot, add_message)
+        else:
+            self.equip_to_slot(slot, equippable_item, add_message)
diff --git a/components/equippable.py b/components/equippable.py
new file mode 100644
index 0000000..d624731
--- /dev/null
+++ b/components/equippable.py
@@ -0,0 +1,44 @@
+from __future__ import annotations
+
+from typing import TYPE_CHECKING
+
+from components.base_component import BaseComponent
+from equipment_types import EquipmentType
+
+if TYPE_CHECKING:
+    from entity import Item
+
+
+class Equippable(BaseComponent):
+    parent: Item
+
+    def __init__(
+        self,
+        equipment_type: EquipmentType,
+        power_bonus: int = 0,
+        defense_bonus: int = 0,
+    ):
+        self.equipment_type = equipment_type
+
+        self.power_bonus = power_bonus
+        self.defense_bonus = defense_bonus
+
+
+class Dagger(Equippable):
+    def __init__(self) -> None:
+        super().__init__(equipment_type=EquipmentType.WEAPON, power_bonus=2)
+
+
+class Sword(Equippable):
+    def __init__(self) -> None:
+        super().__init__(equipment_type=EquipmentType.WEAPON, power_bonus=4)
+
+
+class LeatherArmor(Equippable):
+    def __init__(self) -> None:
+        super().__init__(equipment_type=EquipmentType.ARMOR, defense_bonus=1)
+
+
+class ChainMail(Equippable):
+    def __init__(self) -> None:
+        super().__init__(equipment_type=EquipmentType.ARMOR, defense_bonus=3)
diff --git a/components/fighter.py b/components/fighter.py
index 6705d0a..3632405 100644
--- a/components/fighter.py
+++ b/components/fighter.py
@@ -13,11 +13,11 @@ if TYPE_CHECKING:
 class Fighter(BaseComponent):
     parent: Actor
 
-    def __init__(self, hp: int, defense: int, power: int):
+    def __init__(self, hp: int, base_defense: int, base_power: int):
         self.max_hp = hp
         self._hp = hp
-        self.defense = defense
-        self.power = power
+        self.base_defense = base_defense
+        self.base_power = base_power
 
     @property
     def hp(self) -> int:
@@ -29,6 +29,28 @@ class Fighter(BaseComponent):
         if self._hp == 0 and self.parent.ai:
             self.die()
 
+    @property
+    def defense(self) -> int:
+        return self.base_defense + self.defense_bonus
+
+    @property
+    def power(self) -> int:
+        return self.base_power + self.power_bonus
+
+    @property
+    def defense_bonus(self) -> int:
+        if self.parent.equipment:
+            return self.parent.equipment.defense_bonus
+        else:
+            return 0
+
+    @property
+    def power_bonus(self) -> int:
+        if self.parent.equipment:
+            return self.parent.equipment.power_bonus
+        else:
+            return 0
+
     def die(self) -> None:
         if self.engine.player is self.parent:
             death_message = "You died!"
diff --git a/components/level.py b/components/level.py
index 0513191..8863f00 100644
--- a/components/level.py
+++ b/components/level.py
@@ -60,14 +60,14 @@ class Level(BaseComponent):
         self.increase_level()
 
     def increase_power(self, amount: int = 1) -> None:
-        self.parent.fighter.power += amount
+        self.parent.fighter.base_power += amount
 
         self.engine.message_log.add_message("You feel stronger!")
 
         self.increase_level()
 
     def increase_defense(self, amount: int = 1) -> None:
-        self.parent.fighter.defense += amount
+        self.parent.fighter.base_defense += amount
 
         self.engine.message_log.add_message("Your movements are getting swifter!")
 
diff --git a/entity.py b/entity.py
index a7b716b..734a70e 100644
--- a/entity.py
+++ b/entity.py
@@ -9,6 +9,8 @@ from render_order import RenderOrder
 if TYPE_CHECKING:
     from components.ai import BaseAI
     from components.consumable import Consumable
+    from components.equipment import Equipment
+    from components.equippable import Equippable
     from components.fighter import Fighter
     from components.inventory import Inventory
     from components.level import Level
@@ -93,6 +95,7 @@ class Actor(Entity):
         color: Tuple[int, int, int] = (255, 255, 255),
         name: str = "<Unnamed>",
         ai_cls: Type[BaseAI],
+        equipment: Equipment,
         fighter: Fighter,
         inventory: Inventory,
         level: Level,
@@ -109,6 +112,9 @@ class Actor(Entity):
 
         self.ai: Optional[BaseAI] = ai_cls(self)
 
+        self.equipment: Equipment = equipment
+        self.equipment.parent = self
+
         self.fighter = fighter
         self.fighter.parent = self
 
@@ -133,7 +139,8 @@ class Item(Entity):
         char: str = "?",
         color: Tuple[int, int, int] = (255, 255, 255),
         name: str = "<Unnamed>",
-        consumable: Consumable,
+        consumable: Optional[Consumable] = None,
+        equippable: Optional[Equippable] = None,
     ):
         super().__init__(
             x=x,
@@ -146,4 +153,11 @@ class Item(Entity):
         )
 
         self.consumable = consumable
-        self.consumable.parent = self
+
+        if self.consumable:
+            self.consumable.parent = self
+
+        self.equippable = equippable
+
+        if self.equippable:
+            self.equippable.parent = self
diff --git a/entity_factories.py b/entity_factories.py
index f472714..b9a3576 100644
--- a/entity_factories.py
+++ b/entity_factories.py
@@ -1,5 +1,6 @@
 from components.ai import HostileEnemy
-from components import consumable
+from components import consumable, equippable
+from components.equipment import Equipment
 from components.fighter import Fighter
 from components.inventory import Inventory
 from components.level import Level
@@ -11,7 +12,8 @@ player = Actor(
     color=(255, 255, 255),
     name="Player",
     ai_cls=HostileEnemy,
-    fighter=Fighter(hp=30, defense=2, power=5),
+    equipment=Equipment(),
+    fighter=Fighter(hp=30, base_defense=1, base_power=2),
     inventory=Inventory(capacity=26),
     level=Level(level_up_base=200),
 )
@@ -21,7 +23,8 @@ orc = Actor(
     color=(63, 127, 63),
     name="Orc",
     ai_cls=HostileEnemy,
-    fighter=Fighter(hp=10, defense=0, power=3),
+    equipment=Equipment(),
+    fighter=Fighter(hp=10, base_defense=0, base_power=3),
     inventory=Inventory(capacity=0),
     level=Level(xp_given=35),
 )
@@ -30,7 +33,8 @@ troll = Actor(
     color=(0, 127, 0),
     name="Troll",
     ai_cls=HostileEnemy,
-    fighter=Fighter(hp=16, defense=1, power=4),
+    equipment=Equipment(),
+    fighter=Fighter(hp=16, base_defense=1, base_power=4),
     inventory=Inventory(capacity=0),
     level=Level(xp_given=100),
 )
@@ -59,3 +63,20 @@ lightning_scroll = Item(
     name="Lightning Scroll",
     consumable=consumable.LightningDamageConsumable(damage=20, maximum_range=5),
 )
+
+dagger = Item(
+    char="/", color=(0, 191, 255), name="Dagger", equippable=equippable.Dagger()
+)
+
+sword = Item(char="/", color=(0, 191, 255), name="Sword", equippable=equippable.Sword())
+
+leather_armor = Item(
+    char="[",
+    color=(139, 69, 19),
+    name="Leather Armor",
+    equippable=equippable.LeatherArmor(),
+)
+
+chain_mail = Item(
+    char="[", color=(139, 69, 19), name="Chain Mail", equippable=equippable.ChainMail()
+)
diff --git a/equipment_types.py b/equipment_types.py
new file mode 100644
index 0000000..9a0b5b3
--- /dev/null
+++ b/equipment_types.py
@@ -0,0 +1,6 @@
+from enum import auto, Enum
+
+
+class EquipmentType(Enum):
+    WEAPON = auto()
+    ARMOR = auto()
diff --git a/input_handlers.py b/input_handlers.py
index b83009c..b619293 100644
--- a/input_handlers.py
+++ b/input_handlers.py
@@ -349,7 +349,15 @@ class InventoryEventHandler(AskUserEventHandler):
         if number_of_items_in_inventory > 0:
             for i, item in enumerate(self.engine.player.inventory.items):
                 item_key = chr(ord("a") + i)
-                console.print(x + 1, y + i + 1, f"({item_key}) {item.name}")
+
+                is_equipped = self.engine.player.equipment.item_is_equipped(item)
+
+                item_string = f"({item_key}) {item.name}"
+
+                if is_equipped:
+                    item_string = f"{item_string} (E)"
+
+                console.print(x + 1, y + i + 1, item_string)
         else:
             console.print(x + 1, y + 1, "(Empty)")
 
@@ -378,8 +386,13 @@ class InventoryActivateHandler(InventoryEventHandler):
     TITLE = "Select an item to use"
 
     def on_item_selected(self, item: Item) -> Optional[ActionOrHandler]:
-        """Return the action for the selected item."""
-        return item.consumable.get_action(self.engine.player)
+        if item.consumable:
+            """Return the action for the selected item."""
+            return item.consumable.get_action(self.engine.player)
+        elif item.equippable:
+            return actions.EquipAction(self.engine.player, item)
+        else:
+            return None
 
 
 class InventoryDropHandler(InventoryEventHandler):
diff --git a/procgen.py b/procgen.py
index 3148f00..567003f 100644
--- a/procgen.py
+++ b/procgen.py
@@ -29,8 +29,8 @@ max_monsters_by_floor = [
 item_chances: Dict[int, List[Tuple[Entity, int]]] = {
     0: [(entity_factories.health_potion, 35)],
     2: [(entity_factories.confusion_scroll, 10)],
-    4: [(entity_factories.lightning_scroll, 25)],
-    6: [(entity_factories.fireball_scroll, 25)],
+    4: [(entity_factories.lightning_scroll, 25), (entity_factories.sword, 5)],
+    6: [(entity_factories.fireball_scroll, 25), (entity_factories.chain_mail, 15)],
 }
 
 enemy_chances: Dict[int, List[Tuple[Entity, int]]] = {
diff --git a/setup_game.py b/setup_game.py
index 1728914..88d1b3e 100644
--- a/setup_game.py
+++ b/setup_game.py
@@ -48,6 +48,19 @@ def new_game() -> Engine:
     engine.message_log.add_message(
         "Hello and welcome, adventurer, to yet another dungeon!", color.welcome_text
     )
+
+    dagger = copy.deepcopy(entity_factories.dagger)
+    leather_armor = copy.deepcopy(entity_factories.leather_armor)
+
+    dagger.parent = player.inventory
+    leather_armor.parent = player.inventory
+
+    player.inventory.items.append(dagger)
+    player.equipment.toggle_equip(dagger, add_message=False)
+
+    player.inventory.items.append(leather_armor)
+    player.equipment.toggle_equip(leather_armor, add_message=False)
+
     return engine

