---
title: "Part 12 - Increasing Difficulty"
date: 2019-03-30T09:34:08-07:00
draft: false
---
Right now, our game doesn't feel like much of a roguelike. It's far too
easy! On top of that, the game doesn't get harder as you progress. We'll
remedy that in this chapter, by making enemies stronger, and staggering
enemies and equipment drops through deeper levels of the dungeon.

Before we do that though, let's address something in our design that
will likely cause headache in the future: our random choice selection
for monsters and items. Right now, we're picking a random number between
0 and 100, and checking if that number is less than the "chances" for a
certain item. This works alright for just a few options, but chances
are, you'll want a lot more enemies than just two, and more items than
just four.

A better way to accomplish this is to assign each item a "weight", which
determines how likely the enemy/item is to be created. We could then
pass the choices and their weights to a function, which would pick one
at random and return the selection.

Create a new file called `random_utils.py` and put the following in it:

    from random import randint


    def random_choice_index(chances):
        random_chance = randint(1, sum(chances))

        running_sum = 0
        choice = 0
        for w in chances:
            running_sum += w

            if random_chance <= running_sum:
                return choice
            choice += 1


    def random_choice_from_dict(choice_dict):
        choices = list(choice_dict.keys())
        chances = list(choice_dict.values())

        return choices[random_choice_index(chances)]

Let's put this new functions to use. Open `game_map.py` and modify it
like this:

    ...
    from map_objects.tile import Tile

    + from random_utils import random_choice_from_dict

    from render_functions import RenderOrder
    ...

        def place_entities(self, room, entities, max_monsters_per_room, max_items_per_room):
            number_of_monsters = randint(0, max_monsters_per_room)
            number_of_items = randint(0, max_items_per_room)

    +         monster_chances = {'orc': 80, 'troll': 20}
    +         item_chances = {'healing_potion': 70, 'lightning_scroll': 10, 'fireball_scroll': 10, 'confusion_scroll': 10}

            for i in range(number_of_monsters):
                x = randint(room.x1 + 1, room.x2 - 1)
                y = randint(room.y1 + 1, room.y2 - 1)

                if not any([entity for entity in entities if entity.x == x and entity.y == y]):
    +                 monster_choice = random_choice_from_dict(monster_chances)

    -                 if randint(0, 100) < 80:
    +                 if monster_choice == 'orc':
                        fighter_component = Fighter(hp=10, defense=0, power=3, xp=35)
                        ai_component = BasicMonster()

                        monster = Entity(x, y, 'o', libtcod.desaturated_green, 'Orc', blocks=True,
                                         render_order=RenderOrder.ACTOR, fighter=fighter_component, ai=ai_component)
                    else:
                        fighter_component = Fighter(hp=16, defense=1, power=4, xp=100)
                        ai_component = BasicMonster()

                        monster = Entity(x, y, 'T', libtcod.darker_green, 'Troll', blocks=True, fighter=fighter_component,
                                         render_order=RenderOrder.ACTOR, ai=ai_component)

                    entities.append(monster)

            for i in range(number_of_items):
                x = randint(room.x1 + 1, room.x2 - 1)
                y = randint(room.y1 + 1, room.y2 - 1)

                if not any([entity for entity in entities if entity.x == x and entity.y == y]):
    -                 item_chance = randint(0, 100)
    +                 item_choice = random_choice_from_dict(item_chances)

    -                 if item_chance < 70:
    +                 if item_choice == 'healing_potion':
                        item_component = Item(use_function=heal, amount=4)
                        item = Entity(x, y, '!', libtcod.violet, 'Healing Potion', render_order=RenderOrder.ITEM,
                                      item=item_component)
    -                 elif item_chance < 80:
    +                 elif item_choice == 'fireball_scroll':
                        item_component = Item(use_function=cast_fireball, targeting=True, targeting_message=Message(
                            'Left-click a target tile for the fireball, or right-click to cancel.', libtcod.light_cyan),
                                              damage=12, radius=3)
                        item = Entity(x, y, '#', libtcod.red, 'Fireball Scroll', render_order=RenderOrder.ITEM,
                                      item=item_component)
    -                 elif item_chance < 90:
    +                 elif item_choice == 'confusion_scroll':
                        item_component = Item(use_function=cast_confuse, targeting=True, targeting_message=Message(
                            'Left-click an enemy to confuse it, or right-click to cancel.', libtcod.light_cyan))
                        item = Entity(x, y, '#', libtcod.light_pink, 'Confusion Scroll', render_order=RenderOrder.ITEM,
                                      item=item_component)
                    else:
                        item_component = Item(use_function=cast_lightning, damage=20, maximum_range=5)
                        item = Entity(x, y, '#', libtcod.yellow, 'Lightning Scroll', render_order=RenderOrder.ITEM,
                                      item=item_component)

                    entities.append(item)

We assign each enemy or item to a weight, and then get the selection
from our new function. Note that while our weights still sum up to 100,
they don't have to.

This is a lot more extensible than our previous solution, but we still
haven't achieved what we set out to. What we really want is variable
weights depending on the dungeon floor. That is, the deeper you go, the
more likely you run into Trolls instead of Orcs, and the more likely you
are to find useful items rather than just healing potions.

Let's create a new function that will accept a range of values that tell
us when a certain thing appears in the dungeon, and with what weight.
The function returns the weight appropriate for the dungeon level. It
should go in `random_utils.py` and it looks like this:

    from random import randint


    + def from_dungeon_level(table, dungeon_level):
    +     for (value, level) in reversed(table):
    +         if dungeon_level >= level:
    +             return value
    + 
    +     return 0


    def random_choice_index(chances):
        ...

This might not make sense right away, but let's put it into practice and
see what happens. We can remove the `max_monsters_per_room` and
`max_items_per_room` variables, since they'll be determined by the
dungeon level instead of being passed to the function.

    ...
    from map_objects.tile import Tile

    from random_utils import from_dungeon_level, random_choice_from_dict

    from render_functions import RenderOrder

        def place_entities(self, room, entities, max_monsters_per_room, max_items_per_room):
    +     def place_entities(self, room, entities):
    +         max_monsters_per_room = from_dungeon_level([[2, 1], [3, 4], [5, 6]], self.dungeon_level)
    +         max_items_per_room = from_dungeon_level([[1, 1], [2, 4]], self.dungeon_level)

            number_of_monsters = randint(0, max_monsters_per_room)
            number_of_items = randint(0, max_items_per_room)

    -         monster_chances = {'orc': 80, 'troll': 20}
    -         item_chances = {'healing_potion': 70, 'lightning_scroll': 10, 'fireball_scroll': 10, 'confusion_scroll': 10}

    +         monster_chances = {
    +             'orc': 80,
    +             'troll': from_dungeon_level([[15, 3], [30, 5], [60, 7]], self.dungeon_level)
    +         }

    +         item_chances = {
    +             'healing_potion': 35,
    +             'lightning_scroll': from_dungeon_level([[25, 4]], self.dungeon_level),
    +             'fireball_scroll': from_dungeon_level([[25, 6]], self.dungeon_level),
    +             'confusion_scroll': from_dungeon_level([[10, 2]], self.dungeon_level)
    +         }

We'll also need to update our call to `place_entities` in `make_map`

                            ...
                            self.create_h_tunnel(prev_x, new_x, new_y)

    -                 self.place_entities(new_room, entities, max_monsters_per_room, max_items_per_room)
    +                 self.place_entities(new_room, entities)

                    rooms.append(new_room)
                    ...

Because we've removed `max_monsters_per_room` and `max_items_per_room`
from the function call, we can also remove them from the definition of
`make_map`.

    -     def make_map(self, max_rooms, room_min_size, room_max_size, map_width, map_height, player, entities,
    -                  max_monsters_per_room, max_items_per_room):
    +     def make_map(self, max_rooms, room_min_size, room_max_size, map_width, map_height, player, entities):

We should also remove these variables from the calls to `make_map` in
`initialize_new_game.py`...

        game_map.make_map(constants['max_rooms'], constants['room_min_size'], constants['room_max_size'],
    -                       constants['map_width'], constants['map_height'], player, entities,
    -                       constants['max_monsters_per_room'], constants['max_items_per_room'])
    +     game_map.make_map(constants['max_rooms'], constants['room_min_size'], constants['room_max_size'],
    +                       constants['map_width'], constants['map_height'], player, entities)

... and in `next_floor` (in `game_map.py`):

            self.make_map(constants['max_rooms'], constants['room_min_size'], constants['room_max_size'],
    -                       constants['map_width'], constants['map_height'], player, entities,
    -                       constants['max_monsters_per_room'], constants['max_items_per_room'])
    +         self.make_map(constants['max_rooms'], constants['room_min_size'], constants['room_max_size'],
    +                       constants['map_width'], constants['map_height'], player, entities)

Now our dungeon gets more dangerous as we go deeper! Mission
accomplished! The game itself is still pretty easy though, so let's
change that by modifying the default values for each entity's `Fighter`
component, including the player. We'll also modify the values for the
healing potion, fireball scroll, and lightning scroll.

    def get_game_variables(constants):
    -     fighter_component = Fighter(hp=30, defense=2, power=5)
    +     fighter_component = Fighter(hp=100, defense=1, power=4)
        inventory_component = Inventory(26)
        ...

                    ...
                    if monster_choice == 'orc':
    -                     fighter_component = Fighter(hp=10, defense=0, power=3, xp=35)
    +                     fighter_component = Fighter(hp=20, defense=0, power=4, xp=35)
                        ai_component = BasicMonster()

                        monster = Entity(x, y, 'o', libtcod.desaturated_green, 'Orc', blocks=True,
                                         render_order=RenderOrder.ACTOR, fighter=fighter_component, ai=ai_component)
                    else:
    -                     fighter_component = Fighter(hp=16, defense=1, power=4, xp=100)
    +                     fighter_component = Fighter(hp=30, defense=2, power=8, xp=100)
                        ai_component = BasicMonster()

                        monster = Entity(x, y, 'T', libtcod.darker_green, 'Troll', blocks=True, fighter=fighter_component,
                                         render_order=RenderOrder.ACTOR, ai=ai_component)
                    ...

                ...
                if not any([entity for entity in entities if entity.x == x and entity.y == y]):
                    item_choice = random_choice_from_dict(item_chances)

                    if item_choice == 'healing_potion':
    -                     item_component = Item(use_function=heal, amount=4)
                        item_component = Item(use_function=heal, amount=40)
                        item = Entity(x, y, '!', libtcod.violet, 'Healing Potion', render_order=RenderOrder.ITEM,
                                      item=item_component)
                    elif item_choice == 'fireball_scroll':
    -                     item_component = Item(use_function=cast_fireball, targeting=True, targeting_message=Message(
    -                         'Left-click a target tile for the fireball, or right-click to cancel.', libtcod.light_cyan),
    -                                           damage=12, radius=3)
                        item_component = Item(use_function=cast_fireball, targeting=True, targeting_message=Message(
                            'Left-click a target tile for the fireball, or right-click to cancel.', libtcod.light_cyan),
                                              damage=25, radius=3)
                        item = Entity(x, y, '#', libtcod.red, 'Fireball Scroll', render_order=RenderOrder.ITEM,
                                      item=item_component)
                    elif item_choice == 'confusion_scroll':
                        item_component = Item(use_function=cast_confuse, targeting=True, targeting_message=Message(
                            'Left-click an enemy to confuse it, or right-click to cancel.', libtcod.light_cyan))
                        item = Entity(x, y, '#', libtcod.light_pink, 'Confusion Scroll', render_order=RenderOrder.ITEM,
                                      item=item_component)
                    else:
    -                     item_component = Item(use_function=cast_lightning, damage=20, maximum_range=5)
    +                     item_component = Item(use_function=cast_lightning, damage=40, maximum_range=5)
                        item = Entity(x, y, '#', libtcod.yellow, 'Lightning Scroll', render_order=RenderOrder.ITEM,
                                      item=item_component)
                    ...

That's all for today's tutorial. The next part will be the last one.
We're almost there!

If you want to see the code so far in its entirety, [click
here](https://github.com/TStand90/roguelike_tutorial_revised/tree/part12).

[Click here to move on to the next part of this
tutorial.](/tutorials/tcod/part-13)
