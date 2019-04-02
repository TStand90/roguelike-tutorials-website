---
title: "Part 10 - Saving and loading"
date: 2019-03-30T09:34:04-07:00
draft: false
---
Saving and loading is essential to almost every roguelike, but it can be
a pain to manage if you don't start early. By the end of this chapter,
our game will be able to save and load one file to the disk, which you
could easily expand to multiple saves if you wanted to. But before we
get into that, let's focus on our main game loop.

The `engine.py` file is about 250 lines long right now. In the grand
scheme of things, that really isn't that bad (I've worked on files that
are 10,000 lines long), but let's face it: a lot of what's in there
doesn't need to be. Furthermore, the `main` function could be broken up
into initialization and the main game loop, which will make saving and
loading that much easier.

The first step is to move the initialization of the variables outside
the main game loop as much as we can. We'll create a few functions that
will do things like create the player, create the map, and load
variables like `map_width` and `fov_algorithm`. Let's create a new
folder called `loader_functions`, and put a new file in it called
`initialize_new_game.py`.

Our first function in this new file will return the variables that are
currently at the top of the `main` function. It looks like this:

    import tcod as libtcod


    def get_constants():
        window_title = 'Roguelike Tutorial Revised'

        screen_width = 80
        screen_height = 50

        bar_width = 20
        panel_height = 7
        panel_y = screen_height - panel_height

        message_x = bar_width + 2
        message_width = screen_width - bar_width - 2
        message_height = panel_height - 1

        map_width = 80
        map_height = 43

        room_max_size = 10
        room_min_size = 6
        max_rooms = 30

        fov_algorithm = 0
        fov_light_walls = True
        fov_radius = 10

        max_monsters_per_room = 3
        max_items_per_room = 2

        colors = {
            'dark_wall': libtcod.Color(0, 0, 100),
            'dark_ground': libtcod.Color(50, 50, 150),
            'light_wall': libtcod.Color(130, 110, 50),
            'light_ground': libtcod.Color(200, 180, 50)
        }

        constants = {
            'window_title': window_title,
            'screen_width': screen_width,
            'screen_height': screen_height,
            'bar_width': bar_width,
            'panel_height': panel_height,
            'panel_y': panel_y,
            'message_x': message_x,
            'message_width': message_width,
            'message_height': message_height,
            'map_width': map_width,
            'map_height': map_height,
            'room_max_size': room_max_size,
            'room_min_size': room_min_size,
            'max_rooms': max_rooms,
            'fov_algorithm': fov_algorithm,
            'fov_light_walls': fov_light_walls,
            'fov_radius': fov_radius,
            'max_monsters_per_room': max_monsters_per_room,
            'max_items_per_room': max_items_per_room,
            'colors': colors
        }

        return constants

*\*Note: `window_title` is new. Before, we were just passing the title
of the window as a string, but we might as well define it as part of
this dictionary.*

Why the name "constants"? Python doesn't have a way to declare a
variable that never changes (Java has "final", C\# has "readonly",
etc.), so I wanted a name that conveys the fact that these variable's
*shouldn't* change. The program *could, theoretically* alter them during
the course of the game, but for now, we won't do that. You can use
another name if you prefer, like "game\_variables" or something to that
effect.

Let's put this function to work in our `engine.py` file. Import the
function first:

    ...
    from input_handlers import handle_keys, handle_mouse
    + from loader_functions.initialize_new_game import get_constants
    from map_objects.game_map import GameMap
    ...

Then, call it in the first line of `main`. Let's also remove those same
variables :

    def main():
    +     constants = get_constants()

    -     screen_width = 80
    -     screen_height = 50

    -     bar_width = 20
    -     panel_height = 7
    -     panel_y = screen_height - panel_height

    -     message_x = bar_width + 2
    -     message_width = screen_width - bar_width - 2
    -     message_height = panel_height - 1

    -     map_width = 80
    -     map_height = 43

    -     room_max_size = 10
    -     room_min_size = 6
    -     max_rooms = 30

    -     fov_algorithm = 0
    -     fov_light_walls = True
    -     fov_radius = 10

    -     max_monsters_per_room = 3
    -     max_items_per_room = 2

    -     colors = {
    -         'dark_wall': (0, 0, 100),
    -         'dark_ground': (50, 50, 150),
    -         'light_wall': (130, 110, 50),
    -         'light_ground': (200, 180, 50)
    -     }

Okay, so if you're using an IDE (like PyCharm), then it's probably going
crazy right now. Obviously we can't just remove that many variables and
expect everything to be just fine. We have to modify all the times we
used those "constant" variables directly, and replace then with a lookup
to the `constants` dictionary.

        ...
        libtcod.console_set_custom_font('arial10x10.png', libtcod.FONT_TYPE_GREYSCALE | libtcod.FONT_LAYOUT_TCOD)

    -     libtcod.console_init_root(screen_width, screen_height, 'libtcod tutorial revised', False)
    +     libtcod.console_init_root(constants['screen_width'], constants['screen_height'], constants['window_title'], False)

    -     con = libtcod.console_new(screen_width, screen_height)
    -     panel = libtcod.console_new(screen_width, panel_height)
    +     con = libtcod.console_new(constants['screen_width'], constants['screen_height'])
    +     panel = libtcod.console_new(constants['screen_width'], constants['panel_height'])

    -     game_map = GameMap(map_width, map_height)
    -     game_map.make_map(max_rooms, room_min_size, room_max_size, map_width, map_height, player, entities,
    -                       max_monsters_per_room, max_items_per_room)
    +     game_map = GameMap(constants['map_width'], constants['map_height'])
    +     game_map.make_map(constants['max_rooms'], constants['room_min_size'], constants['room_max_size'],
    +                       constants['map_width'], constants['map_height'], player, entities,
    +                       constants['max_monsters_per_room'], constants['max_items_per_room'])

        fov_recompute = True

        fov_map = initialize_fov(game_map)

    -     message_log = MessageLog(message_x, message_width, message_height)
    +     message_log = MessageLog(constants['message_x'], constants['message_width'], constants['message_height'])

        key = libtcod.Key()

            ...
            if fov_recompute:
    -             recompute_fov(fov_map, player.x, player.y, fov_radius, fov_light_walls, fov_algorithm)
    +             recompute_fov(fov_map, player.x, player.y, constants['fov_radius'], constants['fov_light_walls'],
    +                           constants['fov_algorithm'])

    -         render_all(con, panel, entities, player, game_map, fov_map, fov_recompute, message_log, screen_width,
    -                    screen_height, bar_width, panel_height, panel_y, mouse, colors, game_state)
    +         render_all(con, panel, entities, player, game_map, fov_map, fov_recompute, message_log,
    +                    constants['screen_width'], constants['screen_height'], constants['bar_width'],
    +                    constants['panel_height'], constants['panel_y'], mouse, constants['colors'], game_state)

*\*Note: Why are we using the square bracket notation instead of the
`get()` method? In most other spots, we've used the 'get' notation, but
here I would argue it makes more sense to use the square brackets.
Square brackets will outright crash our game if the variable isn't
found, which in this case, is probably what we'd want. The game can't
possibly proceed without these variables, so there's no reason to try to
continue the program without them.*

That's a lot of changes, but we've successfully removed the constant
variables out of the main loop! Note that if you wanted to, you could
shorten a *lot* of those function definitions by just passing the
`constants` dictionary instead of passing only what the functions need.
It doesn't make a huge difference and is really a matter of preference.
I'll leave it as is in this tutorial, since changing the functions right
now would be a ton of work.

What's next? Another thing we could do is move the initialization of the
player, entities list, and game's map to a separate function. Put the
following function in `initialize_new_game.py`:

    def get_constants():
        ...

    + def get_game_variables(constants):
    +     fighter_component = Fighter(hp=30, defense=2, power=5)
    +     inventory_component = Inventory(26)
    +     player = Entity(0, 0, '@', libtcod.white, 'Player', blocks=True, render_order=RenderOrder.ACTOR,
    +                     fighter=fighter_component, inventory=inventory_component)
    +     entities = [player]
    + 
    +     game_map = GameMap(constants['map_width'], constants['map_height'])
    +     game_map.make_map(constants['max_rooms'], constants['room_min_size'], constants['room_max_size'],
    +                       constants['map_width'], constants['map_height'], player, entities,
    +                       constants['max_monsters_per_room'], constants['max_items_per_room'])
    + 
    +     message_log = MessageLog(constants['message_x'], constants['message_width'], constants['message_height'])
    + 
    +     game_state = GameStates.PLAYERS_TURN
    + 
    +     return player, entities, game_map, message_log, game_state

We'll need to include a few imports in `initialize_new_game.py` for
this:

    import tcod as libtcod

    + from components.fighter import Fighter
    + from components.inventory import Inventory
    + 
    + from entity import Entity
    + 
    + from game_messages import MessageLog
    + 
    + from game_states import GameStates
    + 
    + from map_objects.game_map import GameMap
    + 
    + from render_functions import RenderOrder


    def get_constants():
        ...

Nothing has changed about the way we're initializing these variables.
All we're doing is putting it in one function, which we'll call once in
our main game loop. Let's do that now. Start by importing the
`get_game_variables` function:

    ...
    from input_handlers import handle_keys, handle_mouse
    from loader_functions.initialize_new_game import get_constants, get_game_variables
    from map_objects.game_map import GameMap
    ...

Then modify the `main` function like this:

        ...
    -     fighter_component = Fighter(hp=30, defense=2, power=5)
    -     inventory_component = Inventory(26)
    -     player = Entity(0, 0, '@', libtcod.white, 'Player', blocks=True, render_order=RenderOrder.ACTOR,
    -                     fighter=fighter_component, inventory=inventory_component)
    -     entities = [player]

        libtcod.console_set_custom_font('arial10x10.png', libtcod.FONT_TYPE_GREYSCALE | libtcod.FONT_LAYOUT_TCOD)

        libtcod.console_init_root(constants['screen_width'], constants['screen_height'], constants['window_title'], False)

        con = libtcod.console_new(constants['screen_width'], constants['screen_height'])
        panel = libtcod.console_new(constants['screen_width'], constants['panel_height'])

    -     game_map = GameMap(constants['map_width'], constants['map_height'])
    -     game_map.make_map(constants['max_rooms'], constants['room_min_size'], constants['room_max_size'],
    -                       constants['map_width'], constants['map_height'], player, entities,
    -                       constants['max_monsters_per_room'], constants['max_items_per_room'])

    +     player, entities, game_map, message_log, game_state = get_game_variables(constants)

        fov_recompute = True

        fov_map = initialize_fov(game_map)

    -     message_log = MessageLog(constants['message_x'], constants['message_width'], constants['message_height'])

        key = libtcod.Key()
        mouse = libtcod.Mouse()

    -     game_state = GameStates.PLAYERS_TURN
        previous_game_state = game_state

        targeting_item = None
        ...

One interesting effect of removing these lines is that we don't need all
the imports we did before. Modify your import section at the top of
`engine.py` to look like this:

    import tcod as libtcod

    - from components.fighter import Fighter
    - from components.inventory import Inventory
    from death_functions import kill_monster, kill_player
    from entity import Entity, get_blocking_entities_at_location
    from fov_functions import initialize_fov, recompute_fov
    from game_messages import Message, MessageLog
    from game_states import GameStates
    from input_handlers import handle_keys, handle_mouse
    from loader_functions.initialize_new_game import get_constants, get_game_variables
    - from map_objects.game_map import GameMap
    from render_functions import clear_all, render_all, RenderOrder

It's time to think about how we're going to save and load our game. In
order for this to happen, we'll need to save some (not necessarily all)
of our data to some sort of persistent external location. In many
applications, this would be a SQL or NoSQL database, but that's probably
overkill for our little project. Instead, we'll just save to a data
file.

So what exactly do we need to save? The key things are the entities list
(including the player), the game's map, the message log, and the game's
state. These are the same variables we got from the game's
initialization function too, so we'll be able to start a new game or
load an old one by just swapping our the respective functions. More on
that later.

Unfortunately, plain JSON isn't quite enough to save and load our data.
Our objects are too complex to just save to straight JSON. There are a
few solutions to this. The first would be to write serializers for our
classes and objects ourselves, which isn't a bad idea. But in the
interest of keeping things simple for this tutorial, we'll just use a
library; specifically: `shelve`. This library allows you to save and
load complex Python objects, without needing to write custom
serializers.

Install `shelve` in your Python installation (pip is the best way).
Then, create a new file in `loader_functions`, called `data_loaders.py`.
We'll start by writing our save function.

    import shelve


    def save_game(player, entities, game_map, message_log, game_state):
        with shelve.open('savegame.dat', 'n') as data_file:
            data_file['player_index'] = entities.index(player)
            data_file['entities'] = entities
            data_file['game_map'] = game_map
            data_file['message_log'] = message_log
            data_file['game_state'] = game_state

Using `shelve`, we're encoding the data into a dictionary which we'll
save to the file later. Note that we're not actually saving the
`player`, because the player is already part of the `entities` list. We
just need the index in the list, so that we can load the player from
that list later.

And that's all we need to save the game! Without the `shelve` module, it
would have taken far more effort to be able to save our game. Luckily,
it also makes loading our game easy too; let's implement that now. In
the same file (`data_loaders.py`), create a new function called
`load_game`. You'll need to import `GameMap` in order for this to work.

    import os

    import shelve


    def save_game(player, entities, game_map, message_log, game_state):
        ...

    + def load_game():
    +     if not os.path.isfile('savegame.dat'):
    +         raise FileNotFoundError
    + 
    +     with shelve.open('savegame.dat', 'r') as data_file:
    +         player_index = data_file['player_index']
    +         entities = data_file['entities']
    +         game_map = data_file['game_map']
    +         message_log = data_file['message_log']
    +         game_state = data_file['game_state']
    + 
    +     player = entities[player_index]
    + 
    +     return player, entities, game_map, message_log, game_state

This is just the reverse of the save function. We pull the data out of
the data file, and return all the variables needed to the engine.

The functions for saving and loading are done, but now we need a way to
use them. Before we do that, it's probably a good time to think about
how our game starts up in the first place. Right now, the game just
starts, throwing the player straight into a new game. But that's not how
games typically work. Almost every game in existence has some sort of
starting screen, which lets the player start a new game, load an
existing one, exit, or maybe edit some options. Let's implement
something similar for ours; we should let the player start a new game,
load an existing one, or quit.

We'll need a new menu function to display our main menu. Open up
`menus.py` and add the following function to it:

    def inventory_menu(con, header, inventory, inventory_width, screen_width, screen_height):
        ...


    + def main_menu(con, background_image, screen_width, screen_height):
    +     libtcod.image_blit_2x(background_image, 0, 0, 0)
    + 
    +     libtcod.console_set_default_foreground(0, libtcod.light_yellow)
    +     libtcod.console_print_ex(0, int(screen_width / 2), int(screen_height / 2) - 4, libtcod.BKGND_NONE, libtcod.CENTER,
    +                              'TOMBS OF THE ANCIENT KINGS')
    +     libtcod.console_print_ex(0, int(screen_width / 2), int(screen_height - 2), libtcod.BKGND_NONE, libtcod.CENTER,
    +                              'By (Your name here)')
    + 
    +     menu(con, '', ['Play a new game', 'Continue last game', 'Quit'], 24, screen_width, screen_height)

Our "main" function right now operates off the assumption that we're
going straight into the game. A better method of handling this would be
to have the "main" function open the main menu, and, if the player
chooses to either start a new game or continue an old one, the main game
starts. We can move the logic of the main game to a separate function,
which we'll call `play_game`. This function will live in our `engine.py`
file (it doesn't have to, but it doesn't make much sense to put it
elsewhere right now).

*\*Note: I won't bother with code highlighting here, there's just too
much to cover.*

    def play_game(player, entities, game_map, message_log, game_state, con, panel, constants):
        fov_recompute = True

        fov_map = initialize_fov(game_map)

        key = libtcod.Key()
        mouse = libtcod.Mouse()

        game_state = GameStates.PLAYERS_TURN
        previous_game_state = game_state

        targeting_item = None

        while not libtcod.console_is_window_closed():
            libtcod.sys_check_for_event(libtcod.EVENT_KEY_PRESS | libtcod.EVENT_MOUSE, key, mouse)

            if fov_recompute:
                recompute_fov(fov_map, player.x, player.y, constants['fov_radius'], constants['fov_light_walls'],
                              constants['fov_algorithm'])

            render_all(con, panel, entities, player, game_map, fov_map, fov_recompute, message_log,
                       constants['screen_width'], constants['screen_height'], constants['bar_width'],
                       constants['panel_height'], constants['panel_y'], mouse, constants['colors'], game_state)

            fov_recompute = False

            libtcod.console_flush()

            clear_all(con, entities)

            action = handle_keys(key, game_state)
            mouse_action = handle_mouse(mouse)

            move = action.get('move')
            pickup = action.get('pickup')
            show_inventory = action.get('show_inventory')
            drop_inventory = action.get('drop_inventory')
            inventory_index = action.get('inventory_index')
            exit = action.get('exit')
            fullscreen = action.get('fullscreen')

            left_click = mouse_action.get('left_click')
            right_click = mouse_action.get('right_click')

            player_turn_results = []

            if move and game_state == GameStates.PLAYERS_TURN:
                dx, dy = move
                destination_x = player.x + dx
                destination_y = player.y + dy

                if not game_map.is_blocked(destination_x, destination_y):
                    target = get_blocking_entities_at_location(entities, destination_x, destination_y)

                    if target:
                        attack_results = player.fighter.attack(target)
                        player_turn_results.extend(attack_results)
                    else:
                        player.move(dx, dy)

                        fov_recompute = True

                    game_state = GameStates.ENEMY_TURN

            elif pickup and game_state == GameStates.PLAYERS_TURN:
                for entity in entities:
                    if entity.item and entity.x == player.x and entity.y == player.y:
                        pickup_results = player.inventory.add_item(entity)
                        player_turn_results.extend(pickup_results)

                        break
                else:
                    message_log.add_message(Message('There is nothing here to pick up.', libtcod.yellow))

            if show_inventory:
                previous_game_state = game_state
                game_state = GameStates.SHOW_INVENTORY

            if drop_inventory:
                previous_game_state = game_state
                game_state = GameStates.DROP_INVENTORY

            if inventory_index is not None and previous_game_state != GameStates.PLAYER_DEAD and inventory_index < len(
                    player.inventory.items):
                item = player.inventory.items[inventory_index]

                if game_state == GameStates.SHOW_INVENTORY:
                    player_turn_results.extend(player.inventory.use(item, entities=entities, fov_map=fov_map))
                elif game_state == GameStates.DROP_INVENTORY:
                    player_turn_results.extend(player.inventory.drop_item(item))

            if game_state == GameStates.TARGETING:
                if left_click:
                    target_x, target_y = left_click

                    item_use_results = player.inventory.use(targeting_item, entities=entities, fov_map=fov_map,
                                                            target_x=target_x, target_y=target_y)
                    player_turn_results.extend(item_use_results)
                elif right_click:
                    player_turn_results.append({'targeting_cancelled': True})

            if exit:
                if game_state in (GameStates.SHOW_INVENTORY, GameStates.DROP_INVENTORY):
                    game_state = previous_game_state
                elif game_state == GameStates.TARGETING:
                    player_turn_results.append({'targeting_cancelled': True})
                else:
                    save_game(player, entities, game_map, message_log, game_state)

                    return True

            if fullscreen:
                libtcod.console_set_fullscreen(not libtcod.console_is_fullscreen())

            for player_turn_result in player_turn_results:
                message = player_turn_result.get('message')
                dead_entity = player_turn_result.get('dead')
                item_added = player_turn_result.get('item_added')
                item_consumed = player_turn_result.get('consumed')
                item_dropped = player_turn_result.get('item_dropped')
                targeting = player_turn_result.get('targeting')
                targeting_cancelled = player_turn_result.get('targeting_cancelled')

                if message:
                    message_log.add_message(message)

                if dead_entity:
                    if dead_entity == player:
                        message, game_state = kill_player(dead_entity)
                    else:
                        message = kill_monster(dead_entity)

                    message_log.add_message(message)

                if item_added:
                    entities.remove(item_added)

                    game_state = GameStates.ENEMY_TURN

                if item_consumed:
                    game_state = GameStates.ENEMY_TURN

                if item_dropped:
                    entities.append(item_dropped)

                    game_state = GameStates.ENEMY_TURN

                if targeting:
                    previous_game_state = GameStates.PLAYERS_TURN
                    game_state = GameStates.TARGETING

                    targeting_item = targeting

                    message_log.add_message(targeting_item.item.targeting_message)

                if targeting_cancelled:
                    game_state = previous_game_state

                    message_log.add_message(Message('Targeting cancelled'))

            if game_state == GameStates.ENEMY_TURN:
                for entity in entities:
                    if entity.ai:
                        enemy_turn_results = entity.ai.take_turn(player, fov_map, game_map, entities)

                        for enemy_turn_result in enemy_turn_results:
                            message = enemy_turn_result.get('message')
                            dead_entity = enemy_turn_result.get('dead')

                            if message:
                                message_log.add_message(message)

                            if dead_entity:
                                if dead_entity == player:
                                    message, game_state = kill_player(dead_entity)
                                else:
                                    message = kill_monster(dead_entity)

                                message_log.add_message(message)

                                if game_state == GameStates.PLAYER_DEAD:
                                    break

                        if game_state == GameStates.PLAYER_DEAD:
                            break
                else:
                    game_state = GameStates.PLAYERS_TURN

This is the same as our game code from before, just put into a function.
We'll pass all the needed variables in our `main` function. If the
player presses escape during the game, we'll return to the main loop,
which displays the main menu. The one thing that is different here is
that we're calling `save_game` before exiting the loop.

Now let's change our main loop. It'll display the main menu, and
depending on the player's choice, it will either start a new game, load
an existing one, or exit the program.

    def main():
        constants = get_constants()

        libtcod.console_set_custom_font('arial10x10.png', libtcod.FONT_TYPE_GREYSCALE | libtcod.FONT_LAYOUT_TCOD)

        libtcod.console_init_root(constants['screen_width'], constants['screen_height'], constants['window_title'], False)

        con = libtcod.console_new(constants['screen_width'], constants['screen_height'])
        panel = libtcod.console_new(constants['screen_width'], constants['panel_height'])

        player = None
        entities = []
        game_map = None
        message_log = None
        game_state = None

        show_main_menu = True
        show_load_error_message = False

        main_menu_background_image = libtcod.image_load('menu_background.png')

        key = libtcod.Key()
        mouse = libtcod.Mouse()

        while not libtcod.console_is_window_closed():
            libtcod.sys_check_for_event(libtcod.EVENT_KEY_PRESS | libtcod.EVENT_MOUSE, key, mouse)

            if show_main_menu:
                main_menu(con, main_menu_background_image, constants['screen_width'],
                          constants['screen_height'])

                if show_load_error_message:
                    message_box(con, 'No save game to load', 50, constants['screen_width'], constants['screen_height'])

                libtcod.console_flush()

                action = handle_main_menu(key)

                new_game = action.get('new_game')
                load_saved_game = action.get('load_game')
                exit_game = action.get('exit')

                if show_load_error_message and (new_game or load_saved_game or exit_game):
                    show_load_error_message = False
                elif new_game:
                    player, entities, game_map, message_log, game_state = get_game_variables(constants)
                    game_state = GameStates.PLAYERS_TURN

                    show_main_menu = False
                elif load_saved_game:
                    try:
                        player, entities, game_map, message_log, game_state = load_game()
                        show_main_menu = False
                    except FileNotFoundError:
                        show_load_error_message = True
                elif exit_game:
                    break

            else:
                libtcod.console_clear(con)
                play_game(player, entities, game_map, message_log, game_state, con, panel, constants)

                show_main_menu = True

We're loading a background image with `image_load` to display in our
main menu. The sample image used for this tutorial can be [found
here](http://roguecentral.org/doryen/files/menu_background1.png).
Download it and put in in your project's directory.

Other than that, a lot of this should look familiar. We're displaying
the main menu with three options, and accepting keyboard input to
determine which option to go with. If the user starts a new game, we use
our `get_game_variables` function from earlier, and if an old game is
being loaded, we use the `load_game` function. Either way, we get the
same variables. Assuming one of those options was chosen, we pass the
variables off to the `play_game` function, and the game proceeds as it
has been until now.

We haven't implemented the `message_box` or `handle_main_menu` functions
yet, so let's do so now. We'll start with `message_box` and we'll put it
in `menus.py`, at the bottom of the file:

    def message_box(con, header, width, screen_width, screen_height):
        menu(con, header, [], width, screen_width, screen_height)

Pretty straightforward. The message box is just an empty menu,
basically.

Now on to `handle_main_menu`, which goes in `input_handlers.py`:

    def handle_inventory_keys(key):
        ...

    + def handle_main_menu(key):
    +     key_char = chr(key.c)
    + 
    +     if key_char == 'a':
    +         return {'new_game': True}
    +     elif key_char == 'b':
    +         return {'load_game': True}
    +     elif key_char == 'c' or  key.vk == libtcod.KEY_ESCAPE:
    +         return {'exit': True}
    + 
    +     return {}


    def handle_mouse(mouse):
        ...

Nothing too complicated here: Our main menu will have 3 options, so just
return the result of which option was selected. Note that the 'Quit'
option can be done through the 'c' key or 'Escape'.

Remember to import these new functions into `engine.py`:

    import tcod as libtcod

    from death_functions import kill_monster, kill_player
    from entity import get_blocking_entities_at_location
    from fov_functions import initialize_fov, recompute_fov
    from game_messages import Message
    from game_states import GameStates
    from input_handlers import handle_keys, handle_mouse, handle_main_menu
    from loader_functions.initialize_new_game import get_constants, get_game_variables
    + from loader_functions.data_loaders import load_game, save_game
    + from menus import main_menu, message_box
    from render_functions import clear_all, render_all
    ...

That's all for this chapter. The gameplay itself hasn't changed, but
saving and loading is no small feat. Be proud!

If you want to see the code so far in its entirety, [click
here](https://github.com/TStand90/roguelike_tutorial_revised/tree/part10).

[Click here to move on to the next part of this
tutorial.](/tutorials/tcod/part-11)
