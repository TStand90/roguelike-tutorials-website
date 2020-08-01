---
title: "Part 11 - Delving into the Dungeon"
date: 2019-03-30T09:34:06-07:00
draft: false
---
Our game isn't much of a "dungeon crawler" if there's only one floor to
our dungeon. In this chapter, we'll allow the player to go down a level,
and we'll put a very basic leveling up system in place, to make the dive
all the more rewarding.

Let's start by modifying the `GameMap` to hold the current dungeon
depth. This will help out when we're writing our stairs. Open `game_map`
and make the following modification:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
class GameMap:
-   def __init__(self, width, height):
+   def __init__(self, width, height, dungeon_level=1):
        self.width = width
        self.height = height
        self.tiles = self.initialize_tiles()

+       self.dungeon_level = dungeon_level
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class GameMap:
    def __init__(self, width, height<span class="new-text">, dungeon_level=1</span>):
        self.width = width
        self.height = height
        self.tiles = self.initialize_tiles()

        <span class="new-text">self.dungeon_level = dungeon_level</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

The stairs themselves will be another `Entity`, as you might expect.
We'll create a new component that sets it apart from the rest, called
`Stairs`. Create a file called `stairs.py` and put the following class
in it:

{{< highlight py3 >}}
class Stairs:
    def __init__(self, floor):
        self.floor = floor
{{</ highlight >}}

The `floor` variable tells us which floor we'll be landing on if we take
the stairs. Our game will only allow for downward movement, but you
could use this to represent going up a floor as well.

Like with all our other components, we need to pass it into `Entity`.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
class Entity:
    def __init__(self, x, y, char, color, name, blocks=False, render_order=RenderOrder.CORPSE, fighter=None, ai=None,
-                item=None, inventory=None):
+                item=None, inventory=None, stairs=None):
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
+       self.stairs = stairs

        if self.fighter:
            self.fighter.owner = self

        if self.ai:
            self.ai.owner = self

        if self.item:
            self.item.owner = self

        if self.inventory:
            self.inventory.owner = self

+       if self.stairs:
+           self.stairs.owner = self
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class Entity:
    def __init__(self, x, y, char, color, name, blocks=False, render_order=RenderOrder.CORPSE, fighter=None, ai=None,
                 item=None, inventory=None<span class="new-text">, stairs=None</span>):
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
        <span class="new-text">self.stairs = stairs</span>

        if self.fighter:
            self.fighter.owner = self

        if self.ai:
            self.ai.owner = self

        if self.item:
            self.item.owner = self

        if self.inventory:
            self.inventory.owner = self

        <span class="new-text">if self.stairs:
            self.stairs.owner = self</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

For placing our stairs, we'll turn to our `make_map` function. To keep
things simple, we'll always place the stairs in the middle of the last
room we create. Modify the function like
this:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
    def make_map(self, max_rooms, room_min_size, room_max_size, map_width, map_height, player, entities,
                 max_monsters_per_room, max_items_per_room):
        rooms = []
        num_rooms = 0

+       center_of_last_room_x = None
+       center_of_last_room_y = None

        for r in range(max_rooms):
            # random width and height
            w = randint(room_min_size, room_max_size)
            h = randint(room_min_size, room_max_size)
            # random position without going out of the boundaries of the map
            x = randint(0, map_width - w - 1)
            y = randint(0, map_height - h - 1)

            # "Rect" class makes rectangles easier to work with
            new_room = Rect(x, y, w, h)

            # run through the other rooms and see if they intersect with this one
            for other_room in rooms:
                if new_room.intersect(other_room):
                    break
            else:
                # this means there are no intersections, so this room is valid

                # "paint" it to the map's tiles
                self.create_room(new_room)

                # center coordinates of new room, will be useful later
                (new_x, new_y) = new_room.center()

+               center_of_last_room_x = new_x
+               center_of_last_room_y = new_y

                if num_rooms == 0:
                    # this is the first room, where the player starts at
                    player.x = new_x
                    player.y = new_y
                else:
                    # all rooms after the first:
                    # connect it to the previous room with a tunnel

                    # center coordinates of previous room
                    (prev_x, prev_y) = rooms[num_rooms - 1].center()

                    # flip a coin (random number that is either 0 or 1)
                    if randint(0, 1) == 1:
                        # first move horizontally, then vertically
                        self.create_h_tunnel(prev_x, new_x, prev_y)
                        self.create_v_tunnel(prev_y, new_y, new_x)
                    else:
                        # first move vertically, then horizontally
                        self.create_v_tunnel(prev_y, new_y, prev_x)
                        self.create_h_tunnel(prev_x, new_x, new_y)

                self.place_entities(new_room, entities, max_monsters_per_room, max_items_per_room)

                # finally, append the new room to the list
                rooms.append(new_room)
                num_rooms += 1

+       stairs_component = Stairs(self.dungeon_level + 1)
+       down_stairs = Entity(center_of_last_room_x, center_of_last_room_y, '>', libtcod.white, 'Stairs',
+                            render_order=RenderOrder.STAIRS, stairs=stairs_component)
+       entities.append(down_stairs)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>    def make_map(self, max_rooms, room_min_size, room_max_size, map_width, map_height, player, entities,
                 max_monsters_per_room, max_items_per_room):
        rooms = []
        num_rooms = 0

        <span class="new-text">center_of_last_room_x = None
        center_of_last_room_y = None</span>

        for r in range(max_rooms):
            # random width and height
            w = randint(room_min_size, room_max_size)
            h = randint(room_min_size, room_max_size)
            # random position without going out of the boundaries of the map
            x = randint(0, map_width - w - 1)
            y = randint(0, map_height - h - 1)

            # "Rect" class makes rectangles easier to work with
            new_room = Rect(x, y, w, h)

            # run through the other rooms and see if they intersect with this one
            for other_room in rooms:
                if new_room.intersect(other_room):
                    break
            else:
                # this means there are no intersections, so this room is valid

                # "paint" it to the map's tiles
                self.create_room(new_room)

                # center coordinates of new room, will be useful later
                (new_x, new_y) = new_room.center()

                <span class="new-text">center_of_last_room_x = new_x
                center_of_last_room_y = new_y</span>

                if num_rooms == 0:
                    # this is the first room, where the player starts at
                    player.x = new_x
                    player.y = new_y
                else:
                    # all rooms after the first:
                    # connect it to the previous room with a tunnel

                    # center coordinates of previous room
                    (prev_x, prev_y) = rooms[num_rooms - 1].center()

                    # flip a coin (random number that is either 0 or 1)
                    if randint(0, 1) == 1:
                        # first move horizontally, then vertically
                        self.create_h_tunnel(prev_x, new_x, prev_y)
                        self.create_v_tunnel(prev_y, new_y, new_x)
                    else:
                        # first move vertically, then horizontally
                        self.create_v_tunnel(prev_y, new_y, prev_x)
                        self.create_h_tunnel(prev_x, new_x, new_y)

                self.place_entities(new_room, entities, max_monsters_per_room, max_items_per_room)

                # finally, append the new room to the list
                rooms.append(new_room)
                num_rooms += 1

        <span class="new-text">stairs_component = Stairs(self.dungeon_level + 1)
        down_stairs = Entity(center_of_last_room_x, center_of_last_room_y, '>', libtcod.white, 'Stairs',
                             render_order=RenderOrder.STAIRS, stairs=stairs_component)
        entities.append(down_stairs)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Be sure to import `Stairs` at the top.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
...
from components.ai import BasicMonster
from components.fighter import Fighter
from components.item import Item
+from components.stairs import Stairs
...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>...
from components.ai import BasicMonster
from components.fighter import Fighter
from components.item import Item
<span class="new-text">from components.stairs import Stairs</span>
...</pre>
{{</ original-tab >}}
{{</ codetab >}}

We're creating two new variables to keep track of the last room's center
x and y, and using them to place our stairs. The stairs themselves are
just a tuple that holds the x and y coordinates.

Notice that we used a new value in the `RenderOrder` enum in the code
above. We'll need to add that to `RenderOrder`. The stairs should appear
below everything else, so it will be the first value in our enum; the
others will have to be pushed down.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
class RenderOrder(Enum):
+   STAIRS = 1
-   CORPSE = 1
+   CORPSE = 2
-   ITEM = 2
+   ITEM = 3
-   ACTOR = 3
+   ACTOR = 4
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class RenderOrder(Enum):
    <span class="new-text">STAIRS = 1</span>
    <span class="crossed-out-text">CORPSE = 1</span>
    <span class="new-text">CORPSE = 2</span>
    <span class="crossed-out-text">ITEM = 2</span>
    <span class="new-text">ITEM = 3</span>
    <span class="crossed-out-text">ACTOR = 3</span>
    <span class="new-text">ACTOR = 4</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Note that if you're working on Python 3.6, you can make this a lot
easier with the `auto()` function.

{{< highlight py3 >}}
class RenderOrder(Enum):
    STAIRS = auto()
    CORPSE = auto()
    ITEM = auto()
    ACTOR = auto()
{{</ highlight >}}

One problem with our current implementation is that we can only see the
stairs when they're in the player's field of view. This might sound
right at first, but consider if the player has seen the stairs, and then
moves away from them. The stairs won't show on the map\! It'd be better
if once found, the stairs are always drawn.

To make this happen, we can modify the `draw_entity` function inside
`render_functions`.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
-def draw_entity(con, entity, fov_map):
+def draw_entity(con, entity, fov_map, game_map):
-   if libtcod.map_is_in_fov(fov_map, entity.x, entity.y):
+   if libtcod.map_is_in_fov(fov_map, entity.x, entity.y) or (entity.stairs and game_map.tiles[entity.x][entity.y].explored):
        libtcod.console_set_default_foreground(con, entity.color)
        libtcod.console_put_char(con, entity.x, entity.y, entity.char, libtcod.BKGND_NONE)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre><span class="crossed-out-text">def draw_entity(con, entity, fov_map):</span>
<span class="new-text">def draw_entity(con, entity, fov_map, game_map):</span>
    <span class="crossed-out-text">if libtcod.map_is_in_fov(fov_map, entity.x, entity.y):</span>
    <span class="new-text">if libtcod.map_is_in_fov(fov_map, entity.x, entity.y) or (entity.stairs and game_map.tiles[entity.x][entity.y].explored):</span>
        libtcod.console_set_default_foreground(con, entity.color)
        libtcod.console_put_char(con, entity.x, entity.y, entity.char, libtcod.BKGND_NONE)</pre>
{{</ original-tab >}}
{{</ codetab >}}

We're now checking if the entity has the 'stairs' component, and if the
map has been explored. If so, we draw the entity, regardless if it's in
the field of view or not. This works even if there's another entity on
top of the stairs.

Note that we're now passing the `game_map` object to `draw_entity`.
We'll need to update our call to `draw_entity` in `render_all`.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
    for entity in entities_in_render_order:
-       draw_entity(con, entity, fov_map)
+       draw_entity(con, entity, fov_map, game_map)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>    for entity in entities_in_render_order:
        draw_entity(con, entity, fov_map<span class="new-text">, game_map</span>)</pre>
{{</ original-tab >}}
{{</ codetab >}}

Run the project now, and you should be able to see the stairs (if you
can find them before meeting your end\!). Now let's make them do
something.

First, let's add a handler for going down the stairs in
`input_handlers.py`. Add the following to the `handle_player_turn_keys`
function:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
    ...
    elif key_char == 'd':
        return {'drop_inventory': True}

+   elif key.vk == libtcod.KEY_ENTER:
+       return {'take_stairs': True}

    if key.vk == libtcod.KEY_ENTER and key.lalt:
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>    ...
    elif key_char == 'd':
        return {'drop_inventory': True}

    <span class="new-text">elif key.vk == libtcod.KEY_ENTER:
        return {'take_stairs': True}</span>

    if key.vk == libtcod.KEY_ENTER and key.lalt:
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

*\*Note: I've used the Enter key here rather than the traditional '\>'
key. This is because the current Roguebasin tutorial's code for the '\>'
key does not work.*

With all this in place, we'll need to implement the code to actually
move the player down a floor. To go down a floor, we'll need to generate
a new map, create a new list of entities, and increment the integer that
represents the dungeon floor. It's not nearly as complex as it sounds\!
Things get a little more difficult if you want to allow the player to
move back up the stairs, but in order to keep this tutorial as simple as
possible, we'll say that once you descend down to the next floor, you
cannot go back up.

Now let's write the function that will take us down a floor. Add the
following to the bottom of the `game_map.py`:

{{< highlight py3 >}}
    def next_floor(self, player, message_log, constants):
        self.dungeon_level += 1
        entities = [player]

        self.tiles = self.initialize_tiles()
        self.make_map(constants['max_rooms'], constants['room_min_size'], constants['room_max_size'],
                      constants['map_width'], constants['map_height'], player, entities,
                      constants['max_monsters_per_room'], constants['max_items_per_room'])

        player.fighter.heal(player.fighter.max_hp // 2)

        message_log.add_message(Message('You take a moment to rest, and recover your strength.', libtcod.light_violet))

        return entities
{{</ highlight >}}

The function starts by incrementing the dungeon level by one. The
`entities` list is created from scratch, with only the player in it
initially. We then call `make_map` to generate the new floor, like we
did at the game's start. We'll also give the player half of the max HP
back, as a reward for making it to the new floor, and add a message to
this effect. We then return the `entities` list to be used in
`engine.py`.

At last, let's modify `engine.py` to use this new function.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
        ...
        inventory_index = action.get('inventory_index')
+       take_stairs = action.get('take_stairs')
        exit = action.get('exit')
        ...
        if inventory_index is not None and previous_game_state != GameStates.PLAYER_DEAD and inventory_index < len(
            ...

+       if take_stairs and game_state == GameStates.PLAYERS_TURN:
+           for entity in entities:
+               if entity.stairs and entity.x == player.x and entity.y == player.y:
+                   entities = game_map.next_floor(player, message_log, constants)
+                   fov_map = initialize_fov(game_map)
+                   fov_recompute = True
+                   libtcod.console_clear(con)
+
+                   break
+           else:
+               message_log.add_message(Message('There are no stairs here.', libtcod.yellow))

        if game_state == GameStates.TARGETING:
            ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>
        ...
        inventory_index = action.get('inventory_index')
        <span class="new-text">take_stairs = action.get('take_stairs')</span>
        exit = action.get('exit')
        ...
        if inventory_index is not None and previous_game_state != GameStates.PLAYER_DEAD and inventory_index < len(
            ...

        <span class="new-text">if take_stairs and game_state == GameStates.PLAYERS_TURN:
            for entity in entities:
                if entity.stairs and entity.x == player.x and entity.y == player.y:
                    entities = game_map.next_floor(player, message_log, constants)
                    fov_map = initialize_fov(game_map)
                    fov_recompute = True
                    libtcod.console_clear(con)

                    break
            else:
                message_log.add_message(Message('There are no stairs here.', libtcod.yellow))</span>

        if game_state == GameStates.TARGETING:
            ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

If the player is standing on the stairs, we call the `next_floor`
function and set the `entities` list to the new values. We also clear
the screen, so that the map shows as unexplored once again, and set the
FOV to recompute. If there aren't any stairs, we let the player know.

We can easily display the dungeon's current depth right below the HP
bar, by rendering the `render_all` function like so:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
    ...
    render_bar(panel, 1, 1, bar_width, 'HP', player.fighter.hp, player.fighter.max_hp,
               libtcod.light_red, libtcod.darker_red)
+   libtcod.console_print_ex(panel, 1, 3, libtcod.BKGND_NONE, libtcod.LEFT,
+                            'Dungeon level: {0}'.format(game_map.dungeon_level))

    libtcod.console_set_default_foreground(panel, libtcod.light_gray)
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>
    ...
    render_bar(panel, 1, 1, bar_width, 'HP', player.fighter.hp, player.fighter.max_hp,
               libtcod.light_red, libtcod.darker_red)
    <span class="new-text">libtcod.console_print_ex(panel, 1, 3, libtcod.BKGND_NONE, libtcod.LEFT,
                             'Dungeon level: {0}'.format(game_map.dungeon_level))</span>

    libtcod.console_set_default_foreground(panel, libtcod.light_gray)
    ...
</pre>
{{</ original-tab >}}
{{</ codetab >}}

And that's it\! We are now officially dungeon diving\! However, the way
our game works right now, going deeper into the dungeon isn't
particularly interesting. In order to make it feel more like a
roguelike, we'll need to do two things: give our character some sort of
progression (either through leveling up or better equipment) and make
the monsters more threatening at lower levels. We'll focus on the former
for the remainder of this chapter, while the latter will be for the next
one.

Most roguelikes (and RPGs in general) reward the player with experience
points upon killing an opponent. Once a certain amount of experience has
been collected, the player levels up and gets stronger. In order to
achieve that, we'll need to do several things. Let's start by modifying
the `Fighter` component to hold a new variable: `xp`. This will
represent the experience points the player receives upon killing an
enemy (but not the experience points of the Entity itself, more on that
later).

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
class Fighter:
-   def __init__(self, hp, defense, power):
+   def __init__(self, hp, defense, power, xp=0):
        self.max_hp = hp
        self.hp = hp
        self.defense = defense
        self.power = power
+       self.xp = xp
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class Fighter:
    def __init__(self, hp, defense, power<span class="new-text">, xp=0</span>):
        self.max_hp = hp
        self.hp = hp
        self.defense = defense
        self.power = power
        <span class="new-text">self.xp = xp</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

We don't need to modify the player's fighter component at all, but we'll
need to alter the components for our enemies. Open up `game_map.py` and
modify the `place_entities` function to include experience points in
each fighter component.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
                ...
                if randint(0, 100) < 80:
-                   fighter_component = Fighter(hp=10, defense=0, power=3)
+                   fighter_component = Fighter(hp=10, defense=0, power=3, xp=35)
                    ai_component = BasicMonster()

                    monster = Entity(x, y, 'o', libtcod.desaturated_green, 'Orc', blocks=True,
                                     render_order=RenderOrder.ACTOR, fighter=fighter_component, ai=ai_component)
                else:
-                   fighter_component = Fighter(hp=16, defense=1, power=4)
+                   fighter_component = Fighter(hp=16, defense=1, power=4, xp=100)
                    ai_component = BasicMonster()

                    monster = Entity(x, y, 'T', libtcod.darker_green, 'Troll', blocks=True, fighter=fighter_component,
                                     render_order=RenderOrder.ACTOR, ai=ai_component)
                ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>                ...
                if randint(0, 100) < 80:
                    fighter_component = Fighter(hp=10, defense=0, power=3<span class="new-text">, xp=35</span>)
                    ai_component = BasicMonster()

                    monster = Entity(x, y, 'o', libtcod.desaturated_green, 'Orc', blocks=True,
                                     render_order=RenderOrder.ACTOR, fighter=fighter_component, ai=ai_component)
                else:
                    fighter_component = Fighter(hp=16, defense=1, power=4<span class="new-text">, xp=100</span>)
                    ai_component = BasicMonster()

                    monster = Entity(x, y, 'T', libtcod.darker_green, 'Troll', blocks=True, fighter=fighter_component,
                                     render_order=RenderOrder.ACTOR, ai=ai_component)
                ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

The player's xp will be a bit different, because we'll be keeping track
of a running total. We'll also need to know how much more experience the
player needs until the next level up. Let's create a new component to
keep track of all this, which we'll call `Level`. Create a new file in
`components` called `level.py` and put the following code in it.

{{< highlight py3 >}}
class Level:
    def __init__(self, current_level=1, current_xp=0, level_up_base=200, level_up_factor=150):
        self.current_level = current_level
        self.current_xp = current_xp
        self.level_up_base = level_up_base
        self.level_up_factor = level_up_factor

    @property
    def experience_to_next_level(self):
        return self.level_up_base + self.current_level * self.level_up_factor

    def add_xp(self, xp):
        self.current_xp += xp

        if self.current_xp > self.experience_to_next_level:
            self.current_xp -= self.experience_to_next_level
            self.current_level += 1

            return True
        else:
            return False
{{</ highlight>}}

I've set all the variables in this class to have the defaults I want,
which you should feel free to change. Also, it probably makes more sense
to put these defaults in our `constants` dictionary, but in the interest
of moving things along faster, I've put them here.

The `current_level` is our player's level, which should start at 1,
unless we're loading a saved game. `current_xp` is a running total of
the player's experience points, which resets when the player levels up.
`level_up_base` and `level_up_factor` are using in our level up formula.

When the player gains experience points, we check if the current xp is
greater than the level up base, plus the current level times the level
up factor. This makes it such that leveling up takes a longer time at
higher levels. If it is, then we reset the `current_xp`, and return
`True` (which our engine will know means that the player leveled up).

The actual level up threshold is handled by the
`experience_to_next_level` property. What's a property? It's basically a
read only variable that we can easily access inside the class and on the
objects we create. `experience_to_next_level` will always have the
latest value when we access it, so we can just say
`player.level.experience_to_next_level` and get the correct value.

Let's add this new component to the `Entity`:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
class Entity:
    def __init__(self, x, y, char, color, name, blocks=False, render_order=RenderOrder.CORPSE, fighter=None, ai=None,
-                item=None, inventory=None, stairs=None):
+                item=None, inventory=None, stairs=None, level=None):
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
+       self.level = level

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

+       if self.level:
+           self.level.owner = self
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class Entity:
    def __init__(self, x, y, char, color, name, blocks=False, render_order=RenderOrder.CORPSE, fighter=None, ai=None,
                 item=None, inventory=None, stairs=None<span class="new-text">, level=None</span>):
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
        <span class="new-text">self.level = level</span>

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

        <span class="new-text">if self.level:
            self.level.owner = self</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Now we'll need to add it to the `player` object. Open
`initialize_new_game.py` and make the following modifications:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
    fighter_component = Fighter(hp=30, defense=2, power=5)
    inventory_component = Inventory(26)
+   level_component = Level()
    player = Entity(0, 0, '@', libtcod.white, 'Player', blocks=True, render_order=RenderOrder.ACTOR,
-                   fighter=fighter_component, inventory=inventory_component)
+                   fighter=fighter_component, inventory=inventory_component, level=level_component)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>
    fighter_component = Fighter(hp=30, defense=2, power=5)
    inventory_component = Inventory(26)
    <span class="new-text">level_component = Level()</span>
    player = Entity(0, 0, '@', libtcod.white, 'Player', blocks=True, render_order=RenderOrder.ACTOR,
                    fighter=fighter_component, inventory=inventory_component<span class="new-text">, level=level_component</span>)
</pre>
{{</ original-tab >}}
{{</ codetab >}}

Remember to import `Level` at the top:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
from components.fighter import Fighter
from components.inventory import Inventory
+from components.level import Level
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>
from components.fighter import Fighter
from components.inventory import Inventory
<span class="new-text">from components.level import Level</span>
</pre>
{{</ original-tab >}}
{{</ codetab >}}

As is tradition in RPGs, we'll gain this experience when we defeat the
monsters. We can return the xp amount along with our death result, in
the `Fighter` component's `take_damage` function.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
    def take_damage(self, amount):
        results = []

        self.hp -= amount

        if self.hp <= 0:
-           results.append({'dead': self.owner})
+           results.append({'dead': self.owner, 'xp': self.xp})

        return results
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>    def take_damage(self, amount):
        results = []

        self.hp -= amount

        if self.hp <= 0:
            results.append({'dead': self.owner<span class="new-text">, 'xp': self.xp</span>})

        return results</pre>
{{</ original-tab >}}
{{</ codetab >}}

And now let's process the result in `engine.py`:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
            ...
            targeting_cancelled = player_turn_result.get('targeting_cancelled')
+           xp = player_turn_result.get('xp')

            if message:
                ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>            ...
            targeting_cancelled = player_turn_result.get('targeting_cancelled')
            <span class="new-text">xp = player_turn_result.get('xp')</span>

            if message:
                ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
            ...
            if targeting_cancelled:
                ...

+           if xp:
+               leveled_up = player.level.add_xp(xp)
+               message_log.add_message(Message('You gain {0} experience points.'.format(xp)))
+
+               if leveled_up:
+                   message_log.add_message(Message(
+                       'Your battle skills grow stronger! You reached level {0}'.format(
+                           player.level.current_level) + '!', libtcod.yellow))
+                   previous_game_state = game_state
+                   game_state = GameStates.LEVEL_UP

        if game_state == GameStates.ENEMY_TURN:
            ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>            ...
            if targeting_cancelled:
                ...

            <span class="new-text">if xp:
                leveled_up = player.level.add_xp(xp)
                message_log.add_message(Message('You gain {0} experience points.'.format(xp)))

                if leveled_up:
                    message_log.add_message(Message(
                        'Your battle skills grow stronger! You reached level {0}'.format(
                            player.level.current_level) + '!', libtcod.yellow))
                    previous_game_state = game_state
                    game_state = GameStates.LEVEL_UP</span>

        if game_state == GameStates.ENEMY_TURN:
            ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Obviously, we'll need to add the `LEVEL_UP` game state to our
`GameStates` enum.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
class GameStates(Enum):
    PLAYERS_TURN = 1
    ENEMY_TURN = 2
    PLAYER_DEAD = 3
    SHOW_INVENTORY = 4
    DROP_INVENTORY = 5
    TARGETING = 6
+   LEVEL_UP = 7
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class GameStates(Enum):
    PLAYERS_TURN = 1
    ENEMY_TURN = 2
    PLAYER_DEAD = 3
    SHOW_INVENTORY = 4
    DROP_INVENTORY = 5
    TARGETING = 6
    <span class="new-text">LEVEL_UP = 7</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

So what happens when the player levels up? Our system will be pretty
simple: the player will have a choice between increasing HP, attack, or
defense. A menu will pop up, prompting the user to select one of these
power ups, and won't close until a selection is made.

Let's create a new menu function, called `level_up_menu`, which will
display our options:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
def main_menu(con, background_image, screen_width, screen_height):
    ...

+def level_up_menu(con, header, player, menu_width, screen_width, screen_height):
+   options = ['Constitution (+20 HP, from {0})'.format(player.fighter.max_hp),
+              'Strength (+1 attack, from {0})'.format(player.fighter.power),
+              'Agility (+1 defense, from {0})'.format(player.fighter.defense)]
+
+   menu(con, header, options, menu_width, screen_width, screen_height)


def message_box(con, header, width, screen_width, screen_height):
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>def main_menu(con, background_image, screen_width, screen_height):
    ...

<span class="new-text">def level_up_menu(con, header, player, menu_width, screen_width, screen_height):
    options = ['Constitution (+20 HP, from {0})'.format(player.fighter.max_hp),
               'Strength (+1 attack, from {0})'.format(player.fighter.power),
               'Agility (+1 defense, from {0})'.format(player.fighter.defense)]

    menu(con, header, options, menu_width, screen_width, screen_height)</span>


def message_box(con, header, width, screen_width, screen_height):
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Modify the `render_all` function to display this menu, after importing
the `level_up_menu` function.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
import tcod as libtcod

from enum import Enum

from game_states import GameStates

-from menus import inventory_menu
+from menus import inventory_menu, level_up_menu
...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>import tcod as libtcod

from enum import Enum

from game_states import GameStates

from menus import inventory_menu<span class="new-text">, level_up_menu</span>
...</pre>
{{</ original-tab >}}
{{</ codetab >}}

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
    if game_state in (GameStates.SHOW_INVENTORY, GameStates.DROP_INVENTORY):
        ...

+   elif game_state == GameStates.LEVEL_UP:
+       level_up_menu(con, 'Level up! Choose a stat to raise:', player, 40, screen_width, screen_height)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>
    if game_state in (GameStates.SHOW_INVENTORY, GameStates.DROP_INVENTORY):
        ...

    <span class="new-text">elif game_state == GameStates.LEVEL_UP:
        level_up_menu(con, 'Level up! Choose a stat to raise:', player, 40, screen_width, screen_height)</span>
</pre>
{{</ original-tab >}}
{{</ codetab >}}

Of course, we'll need to handle the input for this menu. Open up
`input_handlers.py` and add the following function:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
def handle_main_menu(key):
    ...

+def handle_level_up_menu(key):
+   if key:
+       key_char = chr(key.c)
+
+       if key_char == 'a':
+           return {'level_up': 'hp'}
+       elif key_char == 'b':
+           return {'level_up': 'str'}
+       elif key_char == 'c':
+           return {'level_up': 'def'}
+
+   return {}


def handle_mouse(mouse):
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>def handle_main_menu(key):
    ...

<span class="new-text">def handle_level_up_menu(key):
    if key:
        key_char = chr(key.c)

        if key_char == 'a':
            return {'level_up': 'hp'}
        elif key_char == 'b':
            return {'level_up': 'str'}
        elif key_char == 'c':
            return {'level_up': 'def'}

    return {}</span>


def handle_mouse(mouse):
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Modify the `handle_keys` function to use this new handler:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
def handle_keys(key, game_state):
    if game_state == GameStates.PLAYERS_TURN:
        return handle_player_turn_keys(key)
    elif game_state == GameStates.PLAYER_DEAD:
        return handle_player_dead_keys(key)
    elif game_state == GameStates.TARGETING:
        return handle_targeting_keys(key)
    elif game_state in (GameStates.SHOW_INVENTORY, GameStates.DROP_INVENTORY):
        return handle_inventory_keys(key)
+   elif game_state == GameStates.LEVEL_UP:
+       return handle_level_up_menu(key)

    return {}
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>def handle_keys(key, game_state):
    if game_state == GameStates.PLAYERS_TURN:
        return handle_player_turn_keys(key)
    elif game_state == GameStates.PLAYER_DEAD:
        return handle_player_dead_keys(key)
    elif game_state == GameStates.TARGETING:
        return handle_targeting_keys(key)
    elif game_state in (GameStates.SHOW_INVENTORY, GameStates.DROP_INVENTORY):
        return handle_inventory_keys(key)
    <span class="new-text">elif game_state == GameStates.LEVEL_UP:
        return handle_level_up_menu(key)</span>

    return {}</pre>
{{</ original-tab >}}
{{</ codetab >}}

With our key handler in place, let's handle the results in `engine.py`:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
        ...
        take_stairs = action.get('take_stairs')
+       level_up = action.get('level_up')
        exit = action.get('exit')
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>        ...
        take_stairs = action.get('take_stairs')
        <span class="new-text">level_up = action.get('level_up')</span>
        exit = action.get('exit')
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
        if take_stairs and game_state == GameStates.PLAYERS_TURN:
            ...

+       if level_up:
+           if level_up == 'hp':
+               player.fighter.max_hp += 20
+               player.fighter.hp += 20
+           elif level_up == 'str':
+               player.fighter.power += 1
+           elif level_up == 'def':
+               player.fighter.defense += 1
+
+           game_state = previous_game_state

        if game_state == GameStates.TARGETING:
            ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>        if take_stairs and game_state == GameStates.PLAYERS_TURN:
            ...

        <span class="new-text">if level_up:
            if level_up == 'hp':
                player.fighter.max_hp += 20
                player.fighter.hp += 20
            elif level_up == 'str':
                player.fighter.power += 1
            elif level_up == 'def':
                player.fighter.defense += 1

            game_state = previous_game_state</span>

        if game_state == GameStates.TARGETING:
            ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

In order to help the players keep track of their progress, let's create
a "character" screen, which displays the player's current stats. This
will require another game state, so let's add that now.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
class GameStates(Enum):
    PLAYERS_TURN = 1
    ENEMY_TURN = 2
    PLAYER_DEAD = 3
    SHOW_INVENTORY = 4
    DROP_INVENTORY = 5
    TARGETING = 6
    LEVEL_UP = 7
+   CHARACTER_SCREEN = 8
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class GameStates(Enum):
    PLAYERS_TURN = 1
    ENEMY_TURN = 2
    PLAYER_DEAD = 3
    SHOW_INVENTORY = 4
    DROP_INVENTORY = 5
    TARGETING = 6
    LEVEL_UP = 7
    <span class="new-text">CHARACTER_SCREEN = 8</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

We should display this screen when the 'c' key is pressed. Let's add the
key to `handle_player_turn_keys`:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
    ...
    elif key.vk == libtcod.KEY_ENTER:
        return {'take_stairs': True}

+   elif key_char == 'c':
+       return {'show_character_screen': True}

    if key.vk == libtcod.KEY_ENTER and key.lalt:
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>    ...
    elif key.vk == libtcod.KEY_ENTER:
        return {'take_stairs': True}

    <span class="new-text">elif key_char == 'c':
        return {'show_character_screen': True}</span>

    if key.vk == libtcod.KEY_ENTER and key.lalt:
        ...
</pre>
{{</ original-tab >}}
{{</ codetab >}}

Now let's handle that in `engine.py`:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
        ...
        level_up = action.get('level_up')
+       show_character_screen = action.get('show_character_screen')
        exit = action.get('exit')
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>        ...
        level_up = action.get('level_up')
        <span class="new-text">show_character_screen = action.get('show_character_screen')</span>
        exit = action.get('exit')
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
        ...
        if level_up:
            ...

+       if show_character_screen:
+           previous_game_state = game_state
+           game_state = GameStates.CHARACTER_SCREEN

        if game_state == GameStates.TARGETING:
            ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>        ...
        if level_up:
            ...

        <span class="new-text">if show_character_screen:
            previous_game_state = game_state
            game_state = GameStates.CHARACTER_SCREEN</span>

        if game_state == GameStates.TARGETING:
            ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Now let's write the input handler for the character screen. All it does
is handles the 'Escape' key, since the character screen isn't
interactive in any way.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
def handle_level_up_menu(key):
    ...

+def handle_character_screen(key):
+   if key.vk == libtcod.KEY_ESCAPE:
+       return {'exit': True}
+
+   return {}


def handle_mouse(mouse):
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>def handle_level_up_menu(key):
    ...

<span class="new-text">def handle_character_screen(key):
    if key.vk == libtcod.KEY_ESCAPE:
        return {'exit': True}

    return {}</span>


def handle_mouse(mouse):
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Modify `handle_keys` to call this function when showing the character
screen:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
def handle_keys(key, game_state):
    if game_state == GameStates.PLAYERS_TURN:
        return handle_player_turn_keys(key)
    elif game_state == GameStates.PLAYER_DEAD:
        return handle_player_dead_keys(key)
    elif game_state == GameStates.TARGETING:
        return handle_targeting_keys(key)
    elif game_state in (GameStates.SHOW_INVENTORY, GameStates.DROP_INVENTORY):
        return handle_inventory_keys(key)
    elif game_state == GameStates.LEVEL_UP:
        return handle_level_up_menu(key)
+   elif game_state == GameStates.CHARACTER_SCREEN:
+       return handle_character_screen(key)

    return {}
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>def handle_keys(key, game_state):
    if game_state == GameStates.PLAYERS_TURN:
        return handle_player_turn_keys(key)
    elif game_state == GameStates.PLAYER_DEAD:
        return handle_player_dead_keys(key)
    elif game_state == GameStates.TARGETING:
        return handle_targeting_keys(key)
    elif game_state in (GameStates.SHOW_INVENTORY, GameStates.DROP_INVENTORY):
        return handle_inventory_keys(key)
    elif game_state == GameStates.LEVEL_UP:
        return handle_level_up_menu(key)
    <span class="new-text">elif game_state == GameStates.CHARACTER_SCREEN:
        return handle_character_screen(key)</span>

    return {}</pre>
{{</ original-tab >}}
{{</ codetab >}}

If the player does press the escape key, we'll just want to revert the
game state. For this, we can extend our current code for 'exit'.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
        if exit:
-           if game_state in (GameStates.SHOW_INVENTORY, GameStates.DROP_INVENTORY):
+           if game_state in (GameStates.SHOW_INVENTORY, GameStates.DROP_INVENTORY, GameStates.CHARACTER_SCREEN):
                game_state = previous_game_state
            elif game_state == GameStates.TARGETING:
                player_turn_results.append({'targeting_cancelled': True})
            else:
                save_game(player, entities, game_map, message_log, game_state)

                return True
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>        if exit:
            if game_state in (GameStates.SHOW_INVENTORY, GameStates.DROP_INVENTORY<span class="new-text">, GameStates.CHARACTER_SCREEN</span>):
                game_state = previous_game_state
            elif game_state == GameStates.TARGETING:
                player_turn_results.append({'targeting_cancelled': True})
            else:
                save_game(player, entities, game_map, message_log, game_state)

                return True
</pre>
{{</ original-tab >}}
{{</ codetab >}}

That takes care of the input handling. Now, to actually display the
screen, we'll need a new menu function. Unlike the other menu functions,
we're not displaying a list of options. Instead, we know up front what
we want to display. Therefore, we can directly print the information to
the screen in a more straightforward fashion. Open `menus.py` and add
the following
    function.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
def level_up_menu(con, header, player, menu_width, screen_width, screen_height):
    ...

+def character_screen(player, character_screen_width, character_screen_height, screen_width, screen_height):
+   window = libtcod.console_new(character_screen_width, character_screen_height)
+
+   libtcod.console_set_default_foreground(window, libtcod.white)
+
+   libtcod.console_print_rect_ex(window, 0, 1, character_screen_width, character_screen_height, libtcod.BKGND_NONE,
+                                 libtcod.LEFT, 'Character Information')
+   libtcod.console_print_rect_ex(window, 0, 2, character_screen_width, character_screen_height, libtcod.BKGND_NONE,
+                                 libtcod.LEFT, 'Level: {0}'.format(player.level.current_level))
+   libtcod.console_print_rect_ex(window, 0, 3, character_screen_width, character_screen_height, libtcod.BKGND_NONE,
+                                 libtcod.LEFT, 'Experience: {0}'.format(player.level.current_xp))
+   libtcod.console_print_rect_ex(window, 0, 4, character_screen_width, character_screen_height, libtcod.BKGND_NONE,
+                                 libtcod.LEFT, 'Experience to Level: {0}'.format(player.level.experience_to_next_level))
+   libtcod.console_print_rect_ex(window, 0, 6, character_screen_width, character_screen_height, libtcod.BKGND_NONE,
+                                 libtcod.LEFT, 'Maximum HP: {0}'.format(player.fighter.max_hp))
+   libtcod.console_print_rect_ex(window, 0, 7, character_screen_width, character_screen_height, libtcod.BKGND_NONE,
+                                 libtcod.LEFT, 'Attack: {0}'.format(player.fighter.power))
+   libtcod.console_print_rect_ex(window, 0, 8, character_screen_width, character_screen_height, libtcod.BKGND_NONE,
+                                 libtcod.LEFT, 'Defense: {0}'.format(player.fighter.defense))
+
+   x = screen_width // 2 - character_screen_width // 2
+   y = screen_height // 2 - character_screen_height // 2
+   libtcod.console_blit(window, 0, 0, character_screen_width, character_screen_height, 0, x, y, 1.0, 0.7)


def message_box(con, header, width, screen_width, screen_height):
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>def level_up_menu(con, header, player, menu_width, screen_width, screen_height):
    ...

<span class="new-text">def character_screen(player, character_screen_width, character_screen_height, screen_width, screen_height):
    window = libtcod.console_new(character_screen_width, character_screen_height)

    libtcod.console_set_default_foreground(window, libtcod.white)

    libtcod.console_print_rect_ex(window, 0, 1, character_screen_width, character_screen_height, libtcod.BKGND_NONE,
                                  libtcod.LEFT, 'Character Information')
    libtcod.console_print_rect_ex(window, 0, 2, character_screen_width, character_screen_height, libtcod.BKGND_NONE,
                                  libtcod.LEFT, 'Level: {0}'.format(player.level.current_level))
    libtcod.console_print_rect_ex(window, 0, 3, character_screen_width, character_screen_height, libtcod.BKGND_NONE,
                                  libtcod.LEFT, 'Experience: {0}'.format(player.level.current_xp))
    libtcod.console_print_rect_ex(window, 0, 4, character_screen_width, character_screen_height, libtcod.BKGND_NONE,
                                  libtcod.LEFT, 'Experience to Level: {0}'.format(player.level.experience_to_next_level))
    libtcod.console_print_rect_ex(window, 0, 6, character_screen_width, character_screen_height, libtcod.BKGND_NONE,
                                  libtcod.LEFT, 'Maximum HP: {0}'.format(player.fighter.max_hp))
    libtcod.console_print_rect_ex(window, 0, 7, character_screen_width, character_screen_height, libtcod.BKGND_NONE,
                                  libtcod.LEFT, 'Attack: {0}'.format(player.fighter.power))
    libtcod.console_print_rect_ex(window, 0, 8, character_screen_width, character_screen_height, libtcod.BKGND_NONE,
                                  libtcod.LEFT, 'Defense: {0}'.format(player.fighter.defense))

    x = screen_width // 2 - character_screen_width // 2
    y = screen_height // 2 - character_screen_height // 2
    libtcod.console_blit(window, 0, 0, character_screen_width, character_screen_height, 0, x, y, 1.0, 0.7)</span>


def message_box(con, header, width, screen_width, screen_height):
    ...
</pre>
{{</ original-tab >}}
{{</ codetab >}}

In order to display this new menu, we'll modify `render_all` once again.
Start by importing the menu.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
import tcod as libtcod

from enum import Enum

from game_states import GameStates

-from menus import inventory_menu, level_up_menu
+from menus import character_screen, inventory_menu, level_up_menu
...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>import tcod as libtcod

from enum import Enum

from game_states import GameStates

from menus import <span class="new-text">character_screen,</span> inventory_menu, level_up_menu
...
</pre>
{{</ original-tab >}}
{{</ codetab >}}

Now, add the menu to the bottom of `render_all`.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
    elif game_state == GameStates.LEVEL_UP:
        level_up_menu(con, 'Level up! Choose a stat to raise:', player, 40, screen_width, screen_height)

+   elif game_state == GameStates.CHARACTER_SCREEN:
+       character_screen(player, 30, 10, screen_width, screen_height)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>    elif game_state == GameStates.LEVEL_UP:
        level_up_menu(con, 'Level up! Choose a stat to raise:', player, 40, screen_width, screen_height)

    <span class="new-text">elif game_state == GameStates.CHARACTER_SCREEN:
        character_screen(player, 30, 10, screen_width, screen_height)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Final thing before we wrap up this chapter: Awhile ago, we included
diagonal movement for the player character, but we forgot (okay, **I
forgot**) to include a wait command. It's simple to add, but it's
something we'll definitely want before the next chapter, where the game
will start getting more difficult. Open up `input_handlers.py` and add
the following to `handle_player_turn_keys`:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
def handle_player_turn_keys(key):
    key_char = chr(key.c)

    if key.vk == libtcod.KEY_UP or key_char == 'k':
        return {'move': (0, -1)}
    elif key.vk == libtcod.KEY_DOWN or key_char == 'j':
        return {'move': (0, 1)}
    elif key.vk == libtcod.KEY_LEFT or key_char == 'h':
        return {'move': (-1, 0)}
    elif key.vk == libtcod.KEY_RIGHT or key_char == 'l':
        return {'move': (1, 0)}
    elif key_char == 'y':
        return {'move': (-1, -1)}
    elif key_char == 'u':
        return {'move': (1, -1)}
    elif key_char == 'b':
        return {'move': (-1, 1)}
    elif key_char == 'n':
        return {'move': (1, 1)}
+   elif key_char == 'z':
+       return {'wait': True}
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>def handle_player_turn_keys(key):
    key_char = chr(key.c)

    if key.vk == libtcod.KEY_UP or key_char == 'k':
        return {'move': (0, -1)}
    elif key.vk == libtcod.KEY_DOWN or key_char == 'j':
        return {'move': (0, 1)}
    elif key.vk == libtcod.KEY_LEFT or key_char == 'h':
        return {'move': (-1, 0)}
    elif key.vk == libtcod.KEY_RIGHT or key_char == 'l':
        return {'move': (1, 0)}
    elif key_char == 'y':
        return {'move': (-1, -1)}
    elif key_char == 'u':
        return {'move': (1, -1)}
    elif key_char == 'b':
        return {'move': (-1, 1)}
    elif key_char == 'n':
        return {'move': (1, 1)}
    <span class="new-text">elif key_char == 'z':
        return {'wait': True}</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Then, in `engine.py`:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
        move = action.get('move')
+       wait = action.get('wait')
        pickup = action.get('pickup')
        ...

        if move and game_state == GameStates.PLAYERS_TURN:
            ...

+       elif wait:
+           game_state = GameStates.ENEMY_TURN

        elif pickup and game_state == GameStates.PLAYERS_TURN:
            ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>        move = action.get('move')
        <span class="new-text">wait = action.get('wait')</span>
        pickup = action.get('pickup')
        ...

        if move and game_state == GameStates.PLAYERS_TURN:
            ...

        <span class="new-text">elif wait:
            game_state = GameStates.ENEMY_TURN</span>

        elif pickup and game_state == GameStates.PLAYERS_TURN:
            ...
</pre>
{{</ original-tab >}}
{{</ codetab >}}

So all we're doing is "skipping" the player's turn. Easy\! You could do
a number of things here, like giving the player back 1 HP for waiting,
but I won't do that because I'm cruel and unforgiving.

That's all for this chapter. We've given the player a lot of advantages
(in fact, just one more point in defense makes Orcs a non-threat), but
that's all about to change. Next chapter, we're going to buff up the
monsters, while making the player *weaker*. This is a roguelike after
all, it's not supposed to be easy\!

If you want to see the code so far in its entirety, [click
here](https://github.com/TStand90/roguelike_tutorial_revised/tree/part11).

[Click here to move on to the next part of this
tutorial.](/tutorials/tcod/part-12)

<script src="/js/codetabs.js"></script>
