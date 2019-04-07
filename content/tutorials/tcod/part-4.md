---
title: "Part 4 - Field of View"
date: 2019-03-30T09:33:44-07:00
draft: false
---

We have a dungeon now, and we can move about it freely. But are we
really *exploring* the dungeon if we can just see it all from the
beginning?

Most roguelikes (not all\!) only let you see within a certain range of
your character, and our will be no different. We need to implement a way
to calculate the "Field of View" for our adventurer, and fortunately,
libtcod makes that easy\!

We'll need to define a few variables before we get started. Add these in
the same section as our screen and map variables:

```diff
    ...
    max_rooms = 30

+   fov_algorithm = 0
+   fov_light_walls = True
+   fov_radius = 10

    colors = {
    ...
```

'0' is just the default algorithm that libtcod uses; it has more, and I
encourage you to experiment with them later. `fov_light_walls` just
tells us whether or not to 'light up' the walls we see; you can change
it if you don't like the way it looks. `fov_radius` is somewhat obvious,
it tells us how far we can actually see.

We also need to update the `colors` dictionary, because now we need two
more colors for the 'light' versions of both walls and floors. Walls and
floors in our fov will be 'lit', distinguishing them from the ones
outside what we can see.

```py3
    colors = {
        'dark_wall': libtcod.Color(0, 0, 100),
        'dark_ground': libtcod.Color(50, 50, 150),
        'light_wall': libtcod.Color(130, 110, 50),
        'light_ground': libtcod.Color(200, 180, 50)
    }
```

*\* Don't forget to add the comma after the 'dark\_ground' entry; Python
will throw an error without it\!*

If you don't like these colors, feel free to change them to your liking.

The thing about field of view is that it doesn't need to be computed
every turn. In fact, it would be quite a waste to do so\! We really only
need change it when the player moves. Attacking, using an item, or just
standing still for a turn doesn't alter FOV. We can handle this by
having a boolean variable, which we'll call `fov_recompute`, which tells
us if we need to recompute. We can define it somewhere above our game
loop (I put mine right after the map initialization).

```diff
    ...
    game_map.make_map(max_rooms, room_min_size, room_max_size, map_width, map_height, player)

+   fov_recompute = True

    key = libtcod.Key()
    ...
```

It's `True` by default, because we have to compute it right when the
game starts.

Now let's initialize our field of view, which we'll store in a variable
called `fov_map`. `fov_map` will need to not only be initialized, but
recomputed when the player moves. Let's keep these functions out of
`engine.py`, and instead, put them in a new file, called
`fov_functions.py`. In that file, put the following:

```py3
import tcod as libtcod


def initialize_fov(game_map):
    fov_map = libtcod.map_new(game_map.width, game_map.height)

    for y in range(game_map.height):
        for x in range(game_map.width):
            libtcod.map_set_properties(fov_map, x, y, not game_map.tiles[x][y].block_sight,
                                       not game_map.tiles[x][y].blocked)

    return fov_map
```

Call this function in `engine.py` and store the result in `fov_map`.

```diff
    ...
    fov_recompute = True

+   fov_map = initialize_fov(game_map)

    key = libtcod.Key()
    ...
```

Don't forget the import for the function.

```diff
...
from entity import Entity
+from fov_functions import initialize_fov
from input_handlers import handle_keys
...
```

While we're at it, let's modify the section where we move the player to
set `fov_recompute` to True.

```diff
                ...
                player.move(dx, dy)

+               fov_recompute = True
```

But where does the recompute actually *happen*? For that, let's add a
new function to `fov_functions.py` to do the recomputing. The recompute
function will modify the `fov_map` variable based on where the player
is, what the radius for lighting is, whether or not to light the walls,
and what algorithm we're using.

That's a lot of variables, but consider this: in your game, you'll
probably pick one FOV algorithm and stick with it. Also, whether or not
you light the walls probably won't change during the course of the game.
So why not create our function with default arguments? That way, we can
pass the `light_walls` and `algorithm` variables if we want to, but if
not, a default is chosen. That looks like this:

```diff
def initialize_fov(game_map):
    ...

+def recompute_fov(fov_map, x, y, radius, light_walls=True, algorithm=0):
+   libtcod.map_compute_fov(fov_map, x, y, radius, light_walls, algorithm)
```

So when we call the function, we have to give fov\_map, x, y, and
radius, but we don't necessarily have to pass in light\_walls or
algorithm. In my `engine.py` file, I'll pass them in anyway, but you
don't have to if you don't want to (you can also change the defaults I
gave above to whatever you prefer).

Whatever you decide, put your fov recomputation in `engine.py` like so:

```py3
        ...
        libtcod.sys_check_for_event(libtcod.EVENT_KEY_PRESS, key, mouse)

        if fov_recompute:
            recompute_fov(fov_map, player.x, player.y, fov_radius, fov_light_walls, fov_algorithm)

        render_all(con, entities, game_map, screen_width, screen_height, colors)
        ...
```

... And, of course, we have to import that function:

```py3
...
from entity import Entity
from fov_functions import initialize_fov, recompute_fov
from input_handlers import handle_keys
...
```

Now, after the player successfully moves, the field of view will be set
to recalculate, but it won't if we do something else.

With our field of view calculated, we need to actually *display* it (if
you run the code now, you won't notice any visible change). Open up
`render_functions.py` and modify the `render_all` function like
    this:

```diff
def render_all(con, entities, game_map, screen_width, screen_height, colors):
+def render_all(con, entities, game_map, fov_map, fov_recompute, screen_width, screen_height, colors):
+   if fov_recompute:
        for y in range(game_map.height):
            for x in range(game_map.width):
+               visible = libtcod.map_is_in_fov(fov_map, x, y)
                wall = game_map.tiles[x][y].block_sight

+               if visible:
+                   if wall:
+                       libtcod.console_set_char_background(con, x, y, colors.get('light_wall'), libtcod.BKGND_SET)
+                   else:
+                       libtcod.console_set_char_background(con, x, y, colors.get('light_ground'), libtcod.BKGND_SET)
+               else:
                    if wall:
                        libtcod.console_set_char_background(con, x, y, colors.get('dark_wall'), libtcod.BKGND_SET)
                    else:
                        libtcod.console_set_char_background(con, x, y, colors.get('dark_ground'), libtcod.BKGND_SET)

    # Draw all entities in the list
    for entity in entities:
        draw_entity(con, entity)

    libtcod.console_blit(con, 0, 0, screen_width, screen_height, 0, 0, 0)
```

*\* Note: Blue denotes lines that are exactly the same as before, expect
for their indentation. The if statements for `fov_recompute` and
`visible` force certain lines to be indented farther than they were
before. Remember, this is Python, indentation matters\!*

Now our `render_all` function will display tiles differently, depending
on if they're in our field of view or not. If a tile falls in the
`fov_map`, we draw it with the 'light' colors, and if not, we draw the
'dark' version.

The definition of `render_all` has changed, so be sure to update it in
`engine.py`. While we're at it, let's set `fov_recompute` to `False`
after we call `render_all`.

```diff
        ...
-       render_all(con, entities, game_map, screen_width, screen_height, colors)
+       render_all(con, entities, game_map, fov_map, fov_recompute, screen_width, screen_height, colors)
+
+       fov_recompute = False
```

Run the project now. The player's field of view is now visible\! But,
despite being able to "see" the FOV, it still doesn't really *do*
anything. We can still see the entire map, along with our NPC. Luckily,
the changes we have to make to fix this are fairly minimal.

Let's start with our NPC. We should just be able to modify our
`draw_entity` function to account for the field of view, which would
solve our problem.

```diff
def draw_entity(con, entity):
+def draw_entity(con, entity, fov_map):
+   if libtcod.map_is_in_fov(fov_map, entity.x, entity.y):
        libtcod.console_set_default_foreground(con, entity.color)
        libtcod.console_put_char(con, entity.x, entity.y, entity.char, libtcod.BKGND_NONE)
```

*\* Again, the blue means the line is the same as before, except the
indentation has changed.*

Also be sure to update the part where we call the function:

```diff
    for entity in entities:
-       draw_entity(con, entity)
+       draw_entity(con, entity, fov_map)
```

Run the project again, and you won't see the NPC unless it's in your
field of view.

Now for the map. In traditional roguelikes, your character can only see
whats inside its field of view, but it will "remember" areas that were
explored previously. We can accomplish this effect by adding a variable
called `explored` to our `Tile` class. Modify the `__init__` function in
`Tile` to include this new variable:

```diff
        ...
        self.block_sight = block_sight

+       self.explored = False
```

This new variable needs to be taken into account in our `render_all`
function. Let's do that now. We'll only draw the tiles outside of our
field of view if we've explored them previously. Also, any tiles that
*are* in our field of view, we'll mark as 'explored'.

```diff
                ...
                visible = libtcod.map_is_in_fov(fov_map, x, y)
                wall = game_map.tiles[x][y].block_sight

                if visible:
                    if wall:
                        libtcod.console_set_char_background(con, x, y, colors.get('light_wall'), libtcod.BKGND_SET)
                    else:
                        libtcod.console_set_char_background(con, x, y, colors.get('light_ground'), libtcod.BKGND_SET)

+                   game_map.tiles[x][y].explored = True
-               else:
+               elif game_map.tiles[x][y].explored:
                    if wall:
                        libtcod.console_set_char_background(con, x, y, colors.get('dark_wall'), libtcod.BKGND_SET)
                    else:
                        libtcod.console_set_char_background(con, x, y, colors.get('dark_ground'), libtcod.BKGND_SET)
                    ...
```

We now have a real, explorable dungeon\! True, there may not be much
*in* there right now, but this was a major step to a working game. In
the next few parts, we'll fill the dungeon with some evil(?) monsters to
punch.

If you want to see the code so far in its entirety, [click
here](https://github.com/TStand90/roguelike_tutorial_revised/tree/part4).

[Click here to move on to the next part of this
tutorial.](/tutorials/tcod/part-5)

