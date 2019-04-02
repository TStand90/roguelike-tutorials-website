---
title: "Part 8 - Items and Inventory"
date: 2019-03-30T09:33:55-07:00
draft: false
---

So far, our game has movement, dungeon exploring, combat, and AI (okay,
we're stretching the meaning of "intelligence" in *artificial
intelligence* to its limits, but bear with me here). Now it's time for
another staple of the roguelike genre: items! Why would our rogue
venture into the dungeons of doom if not for some sweet loot, after all?

We'll start by placing one type of item, the healing potion in this
case, and then we'll work on our implementation of the inventory. In the
next chapter, we'll add different types of items, but for now, just the
healing potion will suffice.

Make the following changes to `place_entities` to start placing some
health potion entities. They won't do anything yet, but they'll at least
appear on the map.

        def place_entities(self, room, entities, max_monsters_per_room, max_items_per_room):
            number_of_monsters = randint(0, max_monsters_per_room)
    +         number_of_items = randint(0, max_items_per_room)

            for i in range(number_of_monsters):
                ...

    +         for i in range(number_of_items):
    +             x = randint(room.x1 + 1, room.x2 - 1)
    +             y = randint(room.y1 + 1, room.y2 - 1)
    + 
    +             if not any([entity for entity in entities if entity.x == x and entity.y == y]):
    +                 item = Entity(x, y, '!', libtcod.violet, 'Healing Potion', render_order=RenderOrder.ITEM)
    + 
    +                 entities.append(item)

Update the call to `place_entities` in `make_map`:

                    self.place_entities(new_room, entities, max_monsters_per_room, max_items_per_room)

Update the definition of `make_map` to include the new
`max_items_per_room` variable.

        def make_map(self, max_rooms, room_min_size, room_max_size, map_width, map_height, player, entities,
                     max_monsters_per_room, max_items_per_room):

And finally, the call in `engine.py`. We'll also define the variable
here.

        ...
        max_monsters_per_room = 3
    +     max_items_per_room = 2
        ...
        game_map = GameMap(map_width, map_height)
        game_map.make_map(max_rooms, room_min_size, room_max_size, map_width, map_height, player, entities,
                          max_monsters_per_room, max_items_per_room)

        fov_recompute = True
        ...

You should now see a few health potions here and there in the dungeon.
But we can't pick anything up yet. An obvious place to start would be by
giving the player an inventory. Let's create a new component, called
Inventory, which will hold a list of items, along with the maximum
amount of items the inventory can have. Create a new file in the
`components` folder, named `inventory.py`, and put the following in it:

    class Inventory:
        def __init__(self, capacity):
            self.capacity = capacity
            self.items = []

The `items` list will be what holds the actual item entities. Capacity
determines how many items we can pick up in total.

But what types of entities can we pick up in the first place? We may or
may not want the player picking up *every* type of entity that can be
walked on (corpses for example), so how do we distinguish between the
two?

Let's create a new component, called `Item`, which we'll add to entities
when we want them to be able to be picked up. Create a file called
`item.py` in `components`, and add the following class to it:

    class Item:
        def __init__(self):
            pass

Wait, what? An empty class? Don't worry, we'll add some more interesting
stuff here once we move on to using our items. But for now, if an Entity
has this component, we can pick it up, and if not, we can't. Therefore,
all we need is an empty class at the moment.

Now let's modify the `Entity` class to accept the `Item` and `Inventory`
components.

    class Entity:
        def __init__(self, x, y, char, color, name, blocks=False, render_order=RenderOrder.CORPSE, fighter=None, ai=None,
                     item=None, inventory=None):
            self.x = x
            self.y = y
            self.char = char
            self.color = color
            self.name = name
            self.blocks = blocks
            self.render_order = render_order
            self.fighter = fighter
            self.ai = ai
    +         self.item = item
    +         self.inventory = inventory

            if self.fighter:
                self.fighter.owner = self

            if self.ai:
                self.ai.owner = self

    +         if self.item:
    +             self.item.owner = self
    + 
    +         if self.inventory:
    +             self.inventory.owner = self

With our `Entity` class modified, we'll need to modify the player and
the healing potions to have `Inventory` and `Item` respectively. This
tutorial won't give monsters an inventory, but you could attach the
`Inventory` component to them for a similar effect.

In `engine.py`:

        ...
        fighter_component = Fighter(hp=30, defense=2, power=5)
    +     inventory_component = Inventory(26)
    -     player = Entity(0, 0, '@', libtcod.white, 'Player', blocks=True, render_order=RenderOrder.ACTOR, fighter=fighter_component)
    +     player = Entity(0, 0, '@', libtcod.white, 'Player', blocks=True, render_order=RenderOrder.ACTOR,
    +                     fighter=fighter_component, inventory=inventory_component)
        entities = [player]
        ...

Of course, be sure to import `Inventory` as well:

    from components.fighter import Fighter
    + from components.inventory import Inventory
    from death_functions import kill_monster, kill_player
    ...

Then, modify where we put the healing potions in the `place_entities`
function.

                    item_component = Item()
    -                 item = Entity(x, y, '!', libtcod.violet, 'Healing Potion', render_order=RenderOrder.ITEM)
    +                 item = Entity(x, y, '!', libtcod.violet, 'Healing Potion', render_order=RenderOrder.ITEM,
    +                               item=item_component)

... And don't forget the import:

    ...
    from components.ai import BasicMonster
    from components.fighter import Fighter
    + from components.item import Item

    from entity import Entity
    ...

How does our player go about picking things up then? Roguelikes
traditionally allow you to pick up an item if you're standing on top of
it, and ours will be no different. Many of them use the 'g' key
(probably for 'grab' or 'get') for the pickup command, so we'll use that
as well. Modify `handle_keys` in `input_handlers.py` to process the 'g'
key:

        ...
        elif key_char == 'n':
            return {'move': (1, 1)}

    +     if key_char == 'g':
    +         return {'pickup': True}

        if key.vk == libtcod.KEY_ENTER and key.lalt:
            ...

Now we'll need to check for the 'pickup' action in our engine.

            ...
            move = action.get('move')
    +         pickup = action.get('pickup')
            exit = action.get('exit')
            ...

Now we'll need to actually *do* something when this 'pickup' variable is
true. First, let's create a method for the `Inventory` class to add an
item to the inventory. We'll use the same "results" pattern as before.
If adding the item to the inventory was successful, then we'll return a
result saying we picked up the item. If not, we'll send a result that
indicates a failure. The engine will then have to determine what to do
with the item entity.

    import tcod as libtcod

    from game_messages import Message


    class Inventory:
        def __init__(self, capacity):
            self.capacity = capacity
            self.items = []

    +     def add_item(self, item):
    +         results = []
    + 
    +         if len(self.items) >= self.capacity:
    +             results.append({
    +                 'item_added': None,
    +                 'message': Message('You cannot carry any more, your inventory is full', libtcod.yellow)
    +             })
    +         else:
    +             results.append({
    +                 'item_added': item,
    +                 'message': Message('You pick up the {0}!'.format(item.name), libtcod.blue)
    +             })
    + 
    +             self.items.append(item)
    + 
    +         return results

Let's add some code in `engine.py` to process the results of adding an
item to the inventory.

            if move and game_state == GameStates.PLAYERS_TURN:
                ...

    +         elif pickup and game_state == GameStates.PLAYERS_TURN:
    +             for entity in entities:
    +                 if entity.item and entity.x == player.x and entity.y == player.y:
    +                     pickup_results = player.inventory.add_item(entity)
    +                     player_turn_results.extend(pickup_results)
    + 
    +                     break
    +             else:
    +                 message_log.add_message(Message('There is nothing here to pick up.', libtcod.yellow))

            if exit:
                ...

We'll need to import `Message` for this to work:

    from game_messages import Message, MessageLog

Basically, we loop through each entity on the map, checking if it's an
item and if it is occupying the same space as the player. If so, we add
it to the inventory and tack on the results to `player_turn_results`,
and if not, we create a message informing the player that nothing can be
picked up. The 'break' statement makes it so that we can only pick up
one item at a time (though perhaps in your game, you'll allow the player
to pick up several things at once).

Now let's process the results of the pickup, in our loop that processes
the player's turn results:

            ...
            for player_turn_result in player_turn_results:
                message = player_turn_result.get('message')
                dead_entity = player_turn_result.get('dead')
    +             item_added = player_turn_result.get('item_added')

                if message:
                    message_log.add_message(message)

                if dead_entity:
                    if dead_entity == player:
                        message, game_state = kill_player(dead_entity)
                    else:
                        message = kill_monster(dead_entity)

                    message_log.add_message(message)

    +             if item_added:
    +                 entities.remove(item_added)
    + 
    +                 game_state = GameStates.ENEMY_TURN

            if game_state == GameStates.ENEMY_TURN:
                ...

This just handles removing the entity from the entities list (since it's
now located in the player's inventory, not the map) and sets the game
state to the enemy's turn. Simple enough.

Run the project, and you should be able to pick the healing potions up
off the ground. Of course, this doesn't do our rogue any good at the
moment; we can't use any of them yet, so we're really just wasting a
turn.

Before we get into how to use items, we need to have a way to look at
and select which item to use. We'll create an inventory interface, which
the player can open and select an item from. Let's start by creating a
new file, called `menus.py`, where we'll store our menu functions for
the inventory and any other menus we'll need for this tutorial. Put the
following code in that file:

    import tcod as libtcod


    def menu(con, header, options, width, screen_width, screen_height):
        if len(options) > 26: raise ValueError('Cannot have a menu with more than 26 options.')

        # calculate total height for the header (after auto-wrap) and one line per option
        header_height = libtcod.console_get_height_rect(con, 0, 0, width, screen_height, header)
        height = len(options) + header_height

        # create an off-screen console that represents the menu's window
        window = libtcod.console_new(width, height)

        # print the header, with auto-wrap
        libtcod.console_set_default_foreground(window, libtcod.white)
        libtcod.console_print_rect_ex(window, 0, 0, width, height, libtcod.BKGND_NONE, libtcod.LEFT, header)

        # print all the options
        y = header_height
        letter_index = ord('a')
        for option_text in options:
            text = '(' + chr(letter_index) + ') ' + option_text
            libtcod.console_print_ex(window, 0, y, libtcod.BKGND_NONE, libtcod.LEFT, text)
            y += 1
            letter_index += 1

        # blit the contents of "window" to the root console
        x = int(screen_width / 2 - width / 2)
        y = int(screen_height / 2 - height / 2)
        libtcod.console_blit(window, 0, 0, width, height, 0, x, y, 1.0, 0.7)

    def menu(con, header, options, width, screen_width, screen_height):
        ...

    + def inventory_menu(con, header, inventory, inventory_width, screen_width, screen_height):
    +     # show a menu with each item of the inventory as an option
    +     if len(inventory.items) == 0:
    +         options = ['Inventory is empty.']
    +     else:
    +         options = [item.name for item in inventory.items]
    + 
    +     menu(con, header, options, inventory_width, screen_width, screen_height)

How might we display this menu? One way is to switch our game state, and
when the game state is set to "inventory menu", we'll display the menu
and accept input for it. So let's add the option to `GameStates`:

    from enum import Enum


    class GameStates(Enum):
        PLAYERS_TURN = 1
        ENEMY_TURN = 2
        PLAYER_DEAD = 3
    +     SHOW_INVENTORY = 4

When do we switch to this new state? Let's add a new key command to
switch to "inventory" mode. As you may have guessed, we'll press the 'i'
key to do this.

        ...
        if key_char == 'g':
            return {'pickup': True}

    +     elif key_char == 'i':
    +         return {'show_inventory': True}

        if key.vk == libtcod.KEY_ENTER and key.lalt:
            ...

Not only do we want to switch the game state to `SHOW_INVENTORY`, we'll
also want to switch back to the previous game state if we exit the menu
without doing anything. This makes it so that just opening the inventory
doesn't waste a turn, and so that we can view our inventory after death
(this makes it sting that much more). So we'll need a variable to keep
track of the last game state.

        ...
        game_state = GameStates.PLAYERS_TURN
    +     previous_game_state = game_state

        while not libtcod.console_is_window_closed():
            ...

            ...
            pickup = action.get('pickup')
    +         show_inventory = action.get('show_inventory')
            exit = action.get('exit')
            ...

            elif pickup and game_state == GameStates.PLAYERS_TURN:
                ...

    +         if show_inventory:
    +             previous_game_state = game_state
    +             game_state = GameStates.SHOW_INVENTORY

            if exit:
    +             if game_state == GameStates.SHOW_INVENTORY:
    +                 game_state = previous_game_state
    +             else:
                    return True

We're modifying our previous "exit" section to just revert back to the
previous game state if we open the inventory. That way, the "escape" key
just closes the menu, rather than closing the game.

Now we're switching the game's state, but we still need to display the
menu. Needless to say, we'll need to modify `render_all`. Because we'll
only display the inventory when the game state is `SHOW_INVENTORY`, the
`render_all` function will need to be aware of the state. Modify the
call in `engine.py`:

    render_all(con, panel, entities, player, game_map, fov_map, fov_recompute, message_log, screen_width,
                       screen_height, bar_width, panel_height, panel_y, mouse, colors, game_state)

And now for the definition:

    def render_all(con, panel, entities, player, game_map, fov_map, fov_recompute, message_log, screen_width, screen_height,
                   bar_width, panel_height, panel_y, mouse, colors, game_state):
        ...
        ...
        libtcod.console_blit(panel, 0, 0, screen_width, panel_height, 0, 0, panel_y)

    +     if game_state == GameStates.SHOW_INVENTORY:
    +         inventory_menu(con, 'Press the key next to an item to use it, or Esc to cancel.\n',
    +                        player.inventory, 50, screen_width, screen_height)

We'll need to import `GameStates` and `inventory_menu` for this to work.

    import tcod as libtcod

    from enum import Enum

    + from game_states import GameStates
    + 
    + from menus import inventory_menu


    class RenderOrder(Enum):
        ...

Run the project now. You should be able to open the inventory menu and
see all the items you've picked up so far. We can't quite use them yet,
but we're almost there!

In order to actually select an inventory item, we'll need to modify
`handle_keys`. Why? Because we're selecting items using the letter keys,
which is fine and good, but some of those keys we're using for movement
and other things. It'd be nice if our function reacted differently
depending on what our game's state was.

Here's what we'll do: We'll split `handle_keys` up into several
different functions, which will return different results depending on
the game's state. Rename the `handle_keys` function to
`handle_player_turn_keys`:

    def handle_keys(key):
    + def handle_player_turn_keys(key):

Then, create a new `handle_keys` function, which calls
`handle_player_turn_keys`

    import tcod as libtcod

    + from game_states import GameStates
    + 
    + 
    + def handle_keys(key, game_state):
    +     if game_state == GameStates.PLAYERS_TURN:
    +         return handle_player_turn_keys(key)
    + 
    +     return {}


    def handle_player_turn_keys(key):
        ...

Don't forget to modify the call to `handle_keys` in `engine.py`:

    action = handle_keys(key, game_state)

Before we move on to the inventory part, let's cover our bases and put
in a key handler for when the player is dead.

    ...
    def handle_keys(key, game_state):
        if game_state == GameStates.PLAYERS_TURN:
            return handle_player_turn_keys(key)
    +     elif game_state == GameStates.PLAYER_DEAD:
    +         return handle_player_dead_keys(key)

        return {}


    def handle_player_turn_keys(key):
        ...


    + def handle_player_dead_keys(key):
    +     key_char = chr(key.c)
    + 
    +     if key_char == 'i':
    +         return {'show_inventory': True}
    + 
    +     if key.vk == libtcod.KEY_ENTER and key.lalt:
    +         # Alt+Enter: toggle full screen
    +         return {'fullscreen': True}
    +     elif key.vk == libtcod.KEY_ESCAPE:
    +         # Exit the menu
    +         return {'exit': True}
    + 
    +     return {}

Now, let's create a new function, called `handle_inventory_keys`, which
will handle our input when the inventory menu is open.

    ...
    def handle_keys(key, game_state):
        if game_state == GameStates.PLAYERS_TURN:
            return handle_player_turn_keys(key)
        elif game_state == GameStates.PLAYER_DEAD:
            return handle_player_dead_keys(key)
    +     elif game_state == GameStates.SHOW_INVENTORY:
    +         return handle_inventory_keys(key)

        return {}
    ...

    + def handle_inventory_keys(key):
    +     index = key.c - ord('a')
    + 
    +     if index >= 0:
    +         return {'inventory_index': index}
    + 
    +     if key.vk == libtcod.KEY_ENTER and key.lalt:
    +         # Alt+Enter: toggle full screen
    +         return {'fullscreen': True}
    +     elif key.vk == libtcod.KEY_ESCAPE:
    +         # Exit the menu
    +         return {'exit': True}
    + 
    +     return {}

What's with the `ord` function? Long story short, we're converting the
key pressed to an index. 'a' will be 0, 'b' will be 1, and so on. This
will allow us to select an item out of the inventory in `engine.py`. All
we need the input handler to do is give us the index of what we picked;
it doesn't need to know anything about the item or what it should do.

Let's get this index in `engine.py` and do something with it!

            ...
            show_inventory = action.get('show_inventory')
    +         inventory_index = action.get('inventory_index')
            exit = action.get('exit')
            ...

            ...
            if show_inventory:
                ...

    +         if inventory_index is not None and previous_game_state != GameStates.PLAYER_DEAD and inventory_index < len(
    +                 player.inventory.items):
    +             item = player.inventory.items[inventory_index]
    +             print(item)

            if exit:
                ...

*\*Note: The print statement is just a placeholder for now. We're close
to actually using the item, I promise!*

We're taking the index that we selected, and "using" (printing for now)
the item selected. Run the project and verify that this works. Now that
we have a way of opening the menu and selecting an item, we can, at long
last, move on to using the item.

So, how do we use the item? The `Item` component seems like an obvious
place to do something. But, each item should do something different,
right? So the `Item` class won't actually contain the functions for
healing the player, or doing damage to an enemy. Instead, it will just
hold the healing and damaging functions, along with whatever arguments
we need to make that function work. We'll then take the results of that
function (like usual) and process them.

Modify `Item` like this:

    class Item:
        def __init__(self, use_function=None, **kwargs):
    -         pass
    +         self.use_function = use_function
    +         self.function_kwargs = kwargs

What about the actual function though? We'll define that separately,
which will allow us (in the next chapter) to freely assign functions to
the `use_function`, thus changing the behavior of each item depending on
our needs.

Create a file, called `item_functions.py`, and put the following
function in it:

    import tcod as libtcod

    from game_messages import Message


    def heal(*args, **kwargs):
        entity = args[0]
        amount = kwargs.get('amount')

        results = []

        if entity.fighter.hp == entity.fighter.max_hp:
            results.append({'consumed': False, 'message': Message('You are already at full health', libtcod.yellow)})
        else:
            entity.fighter.heal(amount)
            results.append({'consumed': True, 'message': Message('Your wounds start to feel better!', libtcod.green)})

        return results

We're taking the `entity` that's using the item as the first argument
(all of our functions will do this, even if they don't need it). We're
also extracting the "amount" from "kwargs", which will be provided by
the `function_kwargs` from the `Item` component.

We'll need to add the `heal` method to the `Fighter` component for this
to work right (note: both functions are called "heal", but they are not
the same).

        ...
        def take_damage(self, amount):
            ...

    +     def heal(self, amount):
    +         self.hp += amount
    + 
    +         if self.hp > self.max_hp:
    +             self.hp = self.max_hp

        def attack(self, target):
            ...

This may make more sense once we pass the `heal` function to the healing
potions. Let's do that now; in the `place_entities` function in
`game_map`:

                ...
                if not any([entity for entity in entities if entity.x == x and entity.y == y]):
    -                 item_component = Item()
    +                 item_component = Item(use_function=heal, amount=4)
                    item = Entity(x, y, '!', libtcod.violet, 'Healing Potion', render_order=RenderOrder.ITEM,
                                  item=item_component)

You'll need to import `heal` for this.

    ...
    from entity import Entity

    + from item_functions import heal

    from map_objects.rectangle import Rect
    ...

Now our item has an actual function to fire off when it gets used. But
*where* does this get called? Why not have our inventory call the
function? Add the following functions to `Inventory`:

        ...
    +     def use(self, item_entity, **kwargs):
    +         results = []
    + 
    +         item_component = item_entity.item
    + 
    +         if item_component.use_function is None:
    +             results.append({'message': Message('The {0} cannot be used'.format(item_entity.name), libtcod.yellow)})
    +         else:
    +             kwargs = {**item_component.function_kwargs, **kwargs}
    +             item_use_results = item_component.use_function(self.owner, **kwargs)
    + 
    +             for item_use_result in item_use_results:
    +                 if item_use_result.get('consumed'):
    +                     self.remove_item(item_entity)
    + 
    +             results.extend(item_use_results)
    + 
    +         return results
    + 
    +     def remove_item(self, item):
    +         self.items.remove(item)

            ...
            if inventory_index is not None and previous_game_state != GameStates.PLAYER_DEAD and inventory_index < len(
                    player.inventory.items):
                item = player.inventory.items[inventory_index]
    -             print(item)
    +             player_turn_results.extend(player.inventory.use(item))

Finally, let's handle the results of the item use function in
`engine.py`:

            ...
            for player_turn_result in player_turn_results:
                message = player_turn_result.get('message')
                dead_entity = player_turn_result.get('dead')
                item_added = player_turn_result.get('item_added')
    +             item_consumed = player_turn_result.get('consumed')
                ...
                if item_added:
                    entities.remove(item_added)

                    game_state = GameStates.ENEMY_TURN

    +             if item_consumed:
    +                 game_state = GameStates.ENEMY_TURN
                ...

Run the project now. You can now consume the health potions, and this
will take a turn. Potions will not be used if you're at full health
already.

Final thing before we end the chapter: dropping items. This may seem
pointless now, but later on, when we have multiple levels in the
dungeon, the player may have to make some decisions about which items to
keep and which to drop.

First, add a new game state:

    class GameStates(Enum):
        PLAYERS_TURN = 1
        ENEMY_TURN = 2
        PLAYER_DEAD = 3
        SHOW_INVENTORY = 4
    +     DROP_INVENTORY = 5

Then, modify `handle_player_turn_keys` to respond to the 'd' key:

        ...
        elif key_char == 'i':
            return {'show_inventory': True}

    +     elif key_char == 'd':
    +         return {'drop_inventory': True}

        if key.vk == libtcod.KEY_ENTER and key.lalt:
            ...

Update the action handler section to accept this:

            ...
            show_inventory = action.get('show_inventory')
    +         drop_inventory = action.get('drop_inventory')
            inventory_index = action.get('inventory_index')
            ...

We'll need to switch the game state when the player presses this key:

            ...
            if show_inventory:
                previous_game_state = game_state
                game_state = GameStates.SHOW_INVENTORY

    +         if drop_inventory:
    +             previous_game_state = game_state
    +             game_state = GameStates.DROP_INVENTORY

            if inventory_index is not None and previous_game_state != GameStates.PLAYER_DEAD and inventory_index < len(
                    player.inventory.items):
                ...

You might think we need to add another function to handle the keys for
dropping inventory, but we actually don't; we can just use our code for
`SHOW_INVENTORY` for this same purpose. Just modify the "if" statement
in `handle_keys`:

    def handle_keys(key, game_state):
        if game_state == GameStates.PLAYERS_TURN:
            return handle_player_turn_keys(key)
        elif game_state == GameStates.PLAYER_DEAD:
            return handle_player_dead_keys(key)
    -     elif game_state == GameStates.SHOW_INVENTORY:
    +     elif game_state in (GameStates.SHOW_INVENTORY, GameStates.DROP_INVENTORY):
            return handle_inventory_keys(key)

        return {}

Also, modify the `exit` section:

            ...
            if exit:
    -             if game_state in GameStates.SHOW_INVENTORY:
    +             if game_state in (GameStates.SHOW_INVENTORY, GameStates.DROP_INVENTORY):
                    game_state = previous_game_state
                else:
                    return True
            ...

Now for displaying the drop menu. It's really not different from the
inventory menu, so we can use the same function, and send a different
title to it.

        ...
    -     if game_state == GameStates.SHOW_INVENTORY:
    -         inventory_menu(con, 'Press the key next to an item to use it, or Esc to cancel.\n',
    -                        player.inventory, 50, screen_width, screen_height)

    +     if game_state in (GameStates.SHOW_INVENTORY, GameStates.DROP_INVENTORY):
    +         if game_state == GameStates.SHOW_INVENTORY:
    +             inventory_title = 'Press the key next to an item to use it, or Esc to cancel.\n'
    +         else:
    +             inventory_title = 'Press the key next to an item to drop it, or Esc to cancel.\n'
    + 
    +         inventory_menu(con, inventory_title, player.inventory, 50, screen_width, screen_height)

What happens when the player pressed a key in this menu? Let's modify
the part in `engine.py` that handled the `inventory_index` to take the
game's state into account. If it's `SHOW_INVENTORY`, then use the item,
and if it's `DROP_INVENTORY`, then call a function to drop the item.

    if inventory_index is not None and previous_game_state != GameStates.PLAYER_DEAD and inventory_index < len(
                    player.inventory.items):
                item = player.inventory.items[inventory_index]

    +             if game_state == GameStates.SHOW_INVENTORY:
                    player_turn_results.extend(player.inventory.use(item))
    +             elif game_state == GameStates.DROP_INVENTORY:
    +                 player_turn_results.extend(player.inventory.drop_item(item))

We haven't defined the `drop_item` method of inventory yet, so let's do
that now. It will remove the item from the inventory, set the item's
coordinates to match the player (since the item gets dropped at the
player's feet), and return the results.

        ...
        def remove_item(self, item):
            self.items.remove(item)

    +     def drop_item(self, item):
    +         results = []
    + 
    +         item.x = self.owner.x
    +         item.y = self.owner.y
    + 
    +         self.remove_item(item)
    +         results.append({'item_dropped': item, 'message': Message('You dropped the {0}'.format(item.name),
    +                                                                  libtcod.yellow)})
    + 
    +         return results

Finally, handle the results in `engine.py`:

            ...
            for player_turn_result in player_turn_results:
                message = player_turn_result.get('message')
                dead_entity = player_turn_result.get('dead')
                item_added = player_turn_result.get('item_added')
                item_consumed = player_turn_result.get('consumed')
    +             item_dropped = player_turn_result.get('item_dropped')
                ...
                if item_consumed:
                    game_state = GameStates.ENEMY_TURN

    +             if item_dropped:
    +                 entities.append(item_dropped)
    + 
    +                 game_state = GameStates.ENEMY_TURN

That was quite the chapter! It took a lot of setup to get using the
items, but now we've got a framework that we can add on to. In the next
chapter, we'll do just that, by adding some scrolls to cast spells at
our enemies.

If you want to see the code so far in its entirety, [click
here](https://github.com/TStand90/roguelike_tutorial_revised/tree/part8).

[Click here to move on to the next part of this
tutorial.](/tutorials/tcod/part-9)

