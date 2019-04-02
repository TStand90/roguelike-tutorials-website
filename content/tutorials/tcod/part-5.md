---
title: "Part 5 - Placing Enemies and kicking them (harmlessly)"
date: 2019-03-30T09:33:48-07:00
draft: false
---

What good is a dungeon with no monsters to bash? This chapter will focus
on placing the enemies throughout the dungeon, and setting them up to be
attacked (the actual attacking part we'll save for next time). To start,
we'll need a function to place the enemies in the dungeon; let's call it
`place_entities` and put it in the `GameMap` class.

        def create_v_tunnel(self, y1, y2, x):
            ...

    +     def place_entities(self, room, entities, max_monsters_per_room):
    +         # Get a random number of monsters
    +         number_of_monsters = randint(0, max_monsters_per_room)
    + 
    +         for i in range(number_of_monsters):
    +             # Choose a random location in the room
    +             x = randint(room.x1 + 1, room.x2 - 1)
    +             y = randint(room.y1 + 1, room.y2 - 1)
    + 
    +             if not any([entity for entity in entities if entity.x == x and entity.y == y]):
    +                 if randint(0, 100) < 80:
    +                     monster = Entity(x, y, 'o', libtcod.desaturated_green)
    +                 else:
    +                     monster = Entity(x, y, 'T', libtcod.darker_green)
    + 
    +                 entities.append(monster)

        def is_blocked(self, x, y):
            ...

In this function, we're choosing a random amount of enemies to place,
between 0 and the maximum we specify. Then, we take a random x and y,
and, if no other monster is currently at that location, we place a
monster there. There's an 80% chance of it being an Orc, and a 20%
chance of it being a Troll.

We'll need to import both `libtcod` and the `Entity` class.

    import tcod as libtcod
    from random import randint

    + from entity import Entity
    from map_objects.rectangle import Rect
    from map_objects.tile import Tile

Now let's modify our `make_map` function to include the `place_entities`
function.

                            ...
                            self.create_h_tunnel(prev_x, new_x, new_y)

    +                 self.place_entities(new_room, entities, max_monsters_per_room)

                    rooms.append(new_room)
                    ...

Because we now need the `entities` and `max_monsters_per_room`
variables, we should modify our `make_map` function definition to
include them.

        def make_map(self, max_rooms, room_min_size, room_max_size, map_width, map_height, player):
    +     def make_map(self, max_rooms, room_min_size, room_max_size, map_width, map_height, player, entities,
    +                  max_monsters_per_room):

We're all set up here; now we have to modify `engine.py` to match this
new `make_map` function. Also, we'll need to create the
`max_room_per_monsters` variable before calling the function. Finally,
we'll change our `entities` list to include only the player at first,
and we'll completely remove our dummy NPC from before.

        ...
        fov_radius = 10

    +     max_monsters_per_room = 3

        colors = {
            'dark_wall': libtcod.Color(0, 0, 100),
            'dark_ground': libtcod.Color(50, 50, 150),
            'light_wall': libtcod.Color(130, 110, 50),
            'light_ground': libtcod.Color(200, 180, 50)
        }

    -     player = Entity(int(screen_width / 2), int(screen_height / 2), '@', libtcod.white)
    -     npc = Entity(int(screen_width / 2 - 5), int(screen_height / 2), '@', libtcod.yellow)
    -     entities = [npc, player]
    +     player = Entity(0, 0, '@', libtcod.white)
    +     entities = [player]

        libtcod.console_set_custom_font('arial10x10.png', libtcod.FONT_TYPE_GREYSCALE | libtcod.FONT_LAYOUT_TCOD)

        libtcod.console_init_root(screen_width, screen_height, 'libtcod tutorial revised', False)

        con = libtcod.console_new(screen_width, screen_height)

        game_map = GameMap(map_width, map_height)
    -     game_map.make_map(max_rooms, room_min_size, room_max_size, map_width, map_height, player)
    +     game_map.make_map(max_rooms, room_min_size, room_max_size, map_width, map_height, player, entities, max_monsters_per_room)

        fov_recompute = True
        ...

Run the project now, and you should see some orcs and trolls beginning
to populate our dungeon!

One obvious issue with our newly created monsters (you know, besides the
fact that they just sit there lifelessly) is that the player can just
walk right through them. Unless you're planning on making a game about a
ghost walking through monsters and possessing them (doesn't sound like a
bad idea actually!), this isn't what we want; if the player "moves into"
an enemy, we should attack!

One might think that we can just check if we're moving into an Entity,
and attack it if we are, but we actually do want some Entities to not
block movement. Why? Because we'll be using that same Entity class to
represent items, and we'll want to be able to move over those and pick
them up. So it seems we need a class attribute that tells us if the
Entity "blocks" our movement or not.

Let's modify the `Entity` class to include the "blocks" variable. While
we're modifying this class, we should also pass in a "name" for the
Entity, which will be useful a little later.

    class Entity:
    -     def __init__(self, x, y, char, color):
    +     def __init__(self, x, y, char, color, name, blocks=False):
            self.x = x
            self.y = y
            self.char = char
            self.color = color
    +         self.name = name
    +         self.blocks = blocks

        def move(self, dx, dy):
        ...

Notice that "blocks" is optional; if we don't pass it on initialization,
it will be False by default.

Go back to `game_map.py` and modify the `place_entities` method, where
we declare our monsters.

                if randint(0, 100) < 80:
    -                 monster = Entity(x, y, 'o', libtcod.desaturated_green)
    +                 monster = Entity(x, y, 'o', libtcod.desaturated_green, 'Orc', blocks=True)
                else:
    -                 monster = Entity(x, y, 'T', libtcod.darker_green)
    +                 monster = Entity(x, y, 'T', libtcod.darker_green, 'Troll', blocks=True)

We also need to update the initialization of the player in `engine.py`:

        player = Entity(0, 0, '@', libtcod.white)
    +     player = Entity(0, 0, '@', libtcod.white, 'Player', blocks=True)

With our new attribute in place, we need to make a check if a blocking
entity is in the way when we try to move into a tile. One thing that
will definitely help is a function to get a "blocking" entity in a tile,
given the list of entities and the x and y coordinates. We'll put this
function in `entity.py`, but not in the `Entity` class itself. The
reasoning is that it's a function that relates to the entities, but it
doesn't relate to a specific Entity, so it doesn't need to belong to the
class.

Add the function to `entity.py` like this:

    class Entity:
        ...


    + def get_blocking_entities_at_location(entities, destination_x, destination_y):
    +     for entity in entities:
    +         if entity.blocks and entity.x == destination_x and entity.y == destination_y:
    +             return entity
    + 
    +     return None

The function loops through the entities, and if one of them is
"blocking" and is at the x and y location we specified, we return it. If
none of them match, then we return "None" instead. Note that the
function is assuming that only one "blocking" entity will be at each
location; this should be fine, as we'll make sure two entities can't
move into the same tile.

With that in place, let's return to our movement function. Modify the
code that moves the player in `engine.py` like this:

            if move:
                dx, dy = move
    +             destination_x = player.x + dx
    +             destination_y = player.y + dy

    -             if not game_map.is_blocked(player.x + dx, player.y + dy):
    +             if not game_map.is_blocked(destination_x, destination_y):
    +                 target = get_blocking_entities_at_location(entities, destination_x, destination_y)
    + 
    +                 if target:
    +                     print('You kick the ' + target.name + ' in the shins, much to its annoyance!')
    +                 else:
                        player.move(dx, dy)

                        fov_recompute = True

Also be sure to import the function `get_blocking_entities_at_location`
at the top of `engine.py`.

    from entity import Entity, get_blocking_entities_at_location

Now the player gets blocked when trying to move through another entity.
We're putting that humorous (hey, I think it's funny!) print statement
as a placeholder, for the moment. We'll implement real combat in the
next chapter.

Our player should only be able to move during their turn, and the same
applies for the monsters. We'll need a variable to keep track of whose
turn it actually is. We could store a string in this variable, say,
'players\_turn' and 'enemy\_turn', but that seems error prone. If you
happen to mistype one of those strings, you'll end up with some bugs.
Not to mention our number of game states will inevitably grow, and we'll
need a better way to keep track of them all.

Let's keep the game states in an Enum. An "Enum" is a set of named
values that won't change, so it's perfect for things like game states.
Create a new file called `game_states.py` and put the following class in
it:

    from enum import Enum


    class GameStates(Enum):
        PLAYERS_TURN = 1
        ENEMY_TURN = 2

This will make our game state switching much easier to manage,
especially in the future when we have more than two.

*\* Note: The numbers for the states don't necessarily mean anything. In
fact, if you're using Python 3.6 or higher, you can use the 'auto'
feature to just increment the number for you. Check it out if you're
able to.*

Let's put this new `GameStates` enum into action. Start by importing it
at the top.

    ...
    from fov_functions import initialize_fov, recompute_fov
    + from game_states import GameStates
    from input_handlers import handle_keys
    ...

Then, create a variable called `game_state`, which we'll set initially
to the player's turn.

        ...
        mouse = libtcod.Mouse()

    +     game_state = GameStates.PLAYERS_TURN

        while not libtcod.console_is_window_closed():
        ...

Depending on whether or not its the players turn, we want to control the
player's movement. The player can only move on the players turn, so
let's modify our `if move:` section to handle this. After the player
successfully moves, we'll set the state to `ENEMY_TURN`.

            if move:
    +         if move and game_state == GameStates.PLAYERS_TURN:
                dx, dy = move
                destination_x = player.x + dx
                destination_y = player.y + dy

                if not game_map.is_blocked(destination_x, destination_y):
                    target = get_blocking_entities_at_location(entities, destination_x, destination_y)

                    if target:
                        print('You kick the ' + target.name + ' in the shins, much to its annoyance!')
                    else:
                        player.move(dx, dy)

                        fov_recompute = True

    +                 game_state = GameStates.ENEMY_TURN

If you run the project now, the player will be able to move once... and
then get stuck forever. That's because we need to implement the enemy's
moves, and set the `game_state` back to the player's turn afterwards.
Note that you *can* exit the game and make it full screen, because we're
not stopping the player from doing those things when it isn't the
player's turn.

            ...
            if fullscreen:
                libtcod.console_set_fullscreen(not libtcod.console_is_fullscreen())

    +         if game_state == GameStates.ENEMY_TURN:
    +             for entity in entities:
    +                 if entity != player:
    +                     print('The ' + entity.name + ' ponders the meaning of its existence.')
    + 
    +             game_state = GameStates.PLAYERS_TURN

This is simple enough. Assuming it's the enemy turn, we're looping
through each of the entities (excluding the player) and allowing them to
take a turn. Right now, we don't have any AI in place for our enemies,
so they'll just sit there contemplating their lives for now. In the next
chapter, we'll give them some more interesting behavior, but for now,
this works as a placeholder.

If you want to see the code so far in its entirety, [click
here](https://github.com/TStand90/roguelike_tutorial_revised/tree/part5).

[Click here to move on to the next part of this
tutorial.](/tutorials/tcod/part-6)

