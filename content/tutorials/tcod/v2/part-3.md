---
title: "Part 3"
date: 2020-06-15T10:20:18-07:00
draft: true
---

Remember how we created a wall in the last part? We won't need that anymore. Additionally, our dungeon generator will start by filling the entire map with "wall" tiles and "carving" out rooms, so we can modify our `GameMap` class to fill in walls instead of floors.

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class GameMap:
    def __init__(self, width: int, height: int):
        self.width, self.height = width, height
-       self.tiles = np.full((width, height), fill_value=tile_types.floor, order="F")
+       self.tiles = np.full((width, height), fill_value=tile_types.wall, order="F")

-       self.tiles[30:33, 22] = tile_types.wall
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class GameMap:
    def __init__(self, width: int, height: int):
        self.width, self.height = width, height
        <span class="crossed-out-text">self.tiles = np.full((width, height), fill_value=tile_types.floor, order="F")</span>
        <span class="new-text">self.tiles = np.full((width, height), fill_value=tile_types.wall, order="F")</span>

        <span class="crossed-out-text">self.tiles[30:33, 22] = tile_types.wall</span>
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

One more thing we’ll want to do before getting to our dungeon algorithm is defining a helper class for our “rooms”. This will be a basic class that holds some information about dimensions, which we’ll call `Rect` (short for rectangle). Add the following to `game_map.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
...
import tile_types


+class Rect:
+   def __init__(self, x: int, y: int, width: int, height: int):
+       self.x1 = x
+       self.y1 = y
+       self.x2 = x + width
+       self.y2 = y + height


class GameMap:
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>...
import tile_types


<span class="new-text">class Rect:
    def __init__(self, x: int, y: int, width: int, height: int):
        self.x1 = x
        self.y1 = y
        self.x2 = x + width
        self.y2 = y + height</span>


class GameMap:
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

The `__init__` function takes the x and y coordinates of the top left corner, and computes the bottom right corner based on the w and h parameters (width and height). We'll be adding more to this class shortly, but to get us started, that's all we need.

Now, if we're going to be "carving out" a bunch of rooms to create our dungeon, we'll want a function to create a room. This function should take an argument, which we'll call `room`, and that argument should be of the `Rect` class we just created. From x1 to x2, and y1 to y2, we'll want to set each tile in the `Rect` to be not blocked, so the player can move around in it. We can put this function in the `GameMap` class, since it will be manipulating the map's list of tiles.

What we end up with is this function:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
    def __init__(self, width: int, height: int):
        ...

+   def create_room(self, room: Rect) -> None:
+       self.tiles[room.x1+1:room.x2, room.y1+1:room.y2] = tile_types.floor
    
    def render(self, console: Console) -> None:
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>    def __init__(self, width: int, height: int):
        ...

    <span class="new-text">def create_room(self, room: Rect) -> None:
        self.tiles[room.x1+1:room.x2, room.y1+1:room.y2] = tile_types.floor</span>
    
    def render(self, console: Console) -> None:
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

What's with the + 1 on room.x1 and room.y1? Think about what we're
saying when we tell our program that we want a room at coordinates (1,
1) that goes to (6, 6). You might assume that would carve out a room
like this one (remember that lists are 0-indexed, so (0, 0) is a wall in
this case):

``` 
  0 1 2 3 4 5 6 7
0 # # # # # # # #
1 # . . . . . . #
2 # . . . . . . #
3 # . . . . . . #
4 # . . . . . . #
5 # . . . . . . #
6 # . . . . . . #
7 # # # # # # # #
```

That's all fine and good, but what happens if we put a room right next
to it? Let's say this room starts at (7, 1) and goes to (9, 6)

``` 
  0 1 2 3 4 5 6 7 8 9 10
0 # # # # # # # # # # #
1 # . . . . . . . . . #
2 # . . . . . . . . . #
3 # . . . . . . . . . #
4 # . . . . . . . . . #
5 # . . . . . . . . . #
6 # . . . . . . . . . #
7 # # # # # # # # # # #
```

There's no wall separating the two\! That means that if two rooms are
one right next to the other, then there won't be a wall between them\!
So long story short, our function needs to take the walls into account
when digging out a room. So if we have a rectangle with coordinates x1 =
1, x2 = 6, y1 = 1, and y2 = 6, then the room should actually look like
this:

``` 
  0 1 2 3 4 5 6 7
0 # # # # # # # #
1 # # # # # # # #
2 # # . . . . # #
3 # # . . . . # #
4 # # . . . . # #
5 # # . . . . # #
6 # # # # # # # #
7 # # # # # # # #
```

This ensures that we'll always have at least a one tile wide wall
between our rooms, unless we choose to create overlapping rooms. In
order to accomplish this, we add + 1 to x1 and y1.

Let's make some rooms\! We'll need a function in `GameMap` to generate
our map, so let's add one:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
    def create_room(self, room: Rect) -> None:
        ...

+   def make_map(self) -> None:
+       room_1 = Rect(x=20, y=15, width=10, height=15)
+       room_2 = Rect(x=35, y=15, width=10, height=15)

+       self.create_room(room_1)
+       self.create_room(room_2)

    def render(self, console: Console) -> None:
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>    def create_room(self, room: Rect) -> None:
        ...

    <span class="new-text">def make_map(self) -> None:
        room_1 = Rect(x=20, y=15, width=10, height=15)
        room_2 = Rect(x=35, y=15, width=10, height=15)

        self.create_room(room_1)
        self.create_room(room_2)</span>

    def render(self, console: Console) -> None:
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Finally, modify `main.py` to actually call the new `make_map`
function.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
    game_map = GameMap(map_width, map_height)
+   game_map.make_map()
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
    <pre>    game_map = GameMap(map_width, map_height)
    <span class="new-text">game_map.make_map()</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Now is a good time to run your code and make sure everything works as
expected. The changes we've made puts two sample rooms on the map, with
our player in one of them (our poor NPC is stuck in a wall though).

I'm sure you've noticed already, but the rooms are not connected. What's
the use of creating a dungeon if we're stuck in one room? Not to worry,
let's write some code to generate tunnels from one room to another. Add
the following methods to `GameMap`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
    def __init__(self, width: int, height: int):
        ...

+   def create_horizontal_tunnel(self, x1: int, x2: int, y: int) -> None:
+       min_x = min(x1, x2)
+       max_x = max(x1, x2) + 1
        
+       self.tiles[min_x:max_x, y] = tile_types.floor

    def create_room(self, room: Rect) -> None:
        self.tiles[room.x1+1:room.x2, room.y1+1:room.y2] = tile_types.floor

+   def create_vertical_tunnel(self, y1: int, y2: int, x: int) -> None:
+       min_y = min(y1, y2)
+       max_y = max(y1, y2) + 1

+       self.tiles[x, min_y:max_y] = tile_types.floor
    
    def make_map(self) -> None:
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>    def __init__(self, width: int, height: int):
        ...

    <span class="new-text">def create_horizontal_tunnel(self, x1: int, x2: int, y: int) -> None:
        min_x = min(x1, x2)
        max_x = max(x1, x2) + 1
        
        self.tiles[min_x:max_x, y] = tile_types.floor</span>

    def create_room(self, room: Rect) -> None:
        self.tiles[room.x1+1:room.x2, room.y1+1:room.y2] = tile_types.floor

    <span class="new-text">def create_vertical_tunnel(self, y1: int, y2: int, x: int) -> None:
        min_y = min(y1, y2)
        max_y = max(y1, y2) + 1

        self.tiles[x, min_y:max_y] = tile_types.floor</span>
    
    def make_map(self) -> None:
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

Let's put this code to use by drawing a tunnel between our two rooms.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
        ...
        self.create_room(room_2)

+       self.create_horizontal_tunnel(25, 40, 23)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>        ...
        self.create_room(room_2)

        <span class="new-text">self.create_horizontal_tunnel(25, 40, 23)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Run the project, and you'll see a horizontal tunnel that connects the two rooms. It's starting to come together!

Now that we've demonstrated to ourselves that our room and tunnel functions work as intended, it's time to move on to an actual dungeon generation algorithm. Our will be fairly simple; we'll place rooms one at a time, making sure they don't overlap, and connect them with tunnels.

We'll need two additional things in the `Rect` class to ensure that two rooms don't overlap. First, we'll need to know where the "center" of each room is. Secondly,

Enter the following methods into the `Rect` class:


{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
+from __future__ import annotations

+from typing import Tuple

import numpy as np  # type: ignore
from tcod.console import Console

import tile_types


class Rect:
    def __init__(self, x: int, y: int, width: int, height: int):
        self.x1 = x
        self.y1 = y
        self.x2 = x + width
        self.y2 = y + height

+   @property
+   def center(self) -> Tuple[int, int]:
+       center_x = int((self.x1 + self.x2) / 2)
+       center_y = int((self.y1 + self.y2) / 2)

+       return center_x, center_y

+   def intersects(self, other: Rect) -> bool:
+       return self.x1 <= other.x2 and self.x2 >= other.x1 and self.y1 <= other.y2 and self.y2 >= other.y1


class GameMap:
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre><span class="new-text">from __future__ import annotations

from typing import Tuple</span>

import numpy as np  # type: ignore
from tcod.console import Console

import tile_types


class Rect:
    def __init__(self, x: int, y: int, width: int, height: int):
        self.x1 = x
        self.y1 = y
        self.x2 = x + width
        self.y2 = y + height

    <span class="new-text">@property
    def center(self) -> Tuple[int, int]:
        center_x = int((self.x1 + self.x2) / 2)
        center_y = int((self.y1 + self.y2) / 2)

        return center_x, center_y

    def intersects(self, other: Rect) -> bool:
        return self.x1 <= other.x2 and self.x2 >= other.x1 and self.y1 <= other.y2 and self.y2 >= other.y1</span>


class GameMap:
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

`center` is a "property", which essentially acts like a read-only variable for our `Rect` class. It describes the "x" and "y" coordinates of the center of a room. It will be useful later on.

`interects` checks if the room and another room (`other` in the arguments) intersect or not. It returns `True` if the do, `False` if they don't. We'll use this to determine if two rooms are overlapping or not.

We're going to need a few variables to set the maximum and minimum size
of the rooms, along with the maximum number of rooms one floor can have.
Add the following to `main.py`:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
    ...
    map_height = 45

+   room_max_size = 10
+   room_min_size = 6
+   max_rooms = 30

    tileset = tcod.tileset.load_tilesheet(
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>    ...
    map_height = 45

    <span class="new-text">room_max_size = 10
    room_min_size = 6
    max_rooms = 30</span>

    tileset = tcod.tileset.load_tilesheet(
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

At long last, it's time to modify `make_map` to generate our dungeon\!
You can completely remove our old implementation and replace it with the
following:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
from __future__ import annotations

+from random import randint
-from typing import Tuple
+from typing import Tuple, TYPE_CHECKING

import numpy as np  # type: ignore
from tcod.console import Console

import tile_types

+if TYPE_CHECKING:
+   from entity import Entity


class Rect:
    ...

-   def make_map(self):
+   def make_map(self, max_rooms: int, room_min_size: int, room_max_size: int, map_width: int, map_height: int,
+                player: Entity) -> None:
-       room_1 = Rect(x=20, y=15, width=10, height=15)
-       room_2 = Rect(x=35, y=15, width=10, height=15)

-       self.create_room(room_1)
-       self.create_room(room_2)

-       self.create_horizontal_tunnel(25, 40, 23)

+       rooms = []
+       number_of_rooms = 0
+
+       for r in range(max_rooms):
+           # random width and height
+           w = randint(room_min_size, room_max_size)
+           h = randint(room_min_size, room_max_size)
+           # random position without going out of the boundaries of the map
+           x = randint(0, map_width - w - 1)
+           y = randint(0, map_height - h - 1)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from __future__ import annotations

<span class="new-text">from random import randint</span>
<span class="crossed-out-text">from typing import Tuple</span>
<span class="new-text">from typing import Tuple, TYPE_CHECKING</span>

import numpy as np  # type: ignore
from tcod.console import Console

import tile_types

<span class="new-text">if TYPE_CHECKING:
    from entity import Entity</span>


class Rect:
    ...

    <span class="crossed-out-text">def make_map(self):</span>
    <span class="new-text">def make_map(self, max_rooms: int, room_min_size: int, room_max_size: int, map_width: int, map_height: int,
                 player: Entity) -> None:</span>
        <span class="crossed-out-text">room_1 = Rect(x=20, y=15, width=10, height=15)</span>
        <span class="crossed-out-text">room_2 = Rect(x=35, y=15, width=10, height=15)</span>

        <span class="crossed-out-text">self.create_room(room_1)</span>
        <span class="crossed-out-text">self.create_room(room_2)</span>

        <span class="crossed-out-text">self.create_horizontal_tunnel(25, 40, 23)</span>
        
        <span class="new-text">rooms = []
        number_of_rooms = 0
 
        for r in range(max_rooms):
            # random width and height
            w = randint(room_min_size, room_max_size)
            h = randint(room_min_size, room_max_size)
            # random position without going out of the boundaries of the map
            x = randint(0, map_width - w - 1)
            y = randint(0, map_height - h - 1)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

The variables we're creating here will be what we use to create our
rooms momentarily. `randint` gives us a random integer between the
values we specify. In this case, we want our width and height to be
between our given minimums and maximums, and our x and y should be
within the boundaries of the map.

Last thing before we proceed: We need to update the call to `make_map`
in `main.py`, because now we're asking for a bunch of variables that
we weren't before. Modify it to look like this:

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
    ...
    game_map = GameMap(map_width, map_height)
-   game_map.make_map()
+   game_map.make_map(
+       max_rooms=max_rooms,
+       room_min_size=room_min_size,
+       room_max_size=room_max_size,
+       map_width=map_width,
+       map_height=map_height,
+       player=player
+   )
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>    ...
    game_map = GameMap(map_width, map_height)
    <span class="crossed-out-text">game_map.make_map()</span>
    <span class="new-text">game_map.make_map(
        max_rooms=max_rooms,
        room_min_size=room_min_size,
        room_max_size=room_max_size,
        map_width=map_width,
        map_height=map_height,
        player=player
    )</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Now we'll put our `Rect` class to use, by passing it the variables we
just created. Then, we can check if it intersects with any other rooms.
If it does, we don't want to add it to our rooms, and we simply toss it
out.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
            ...
            y = randint(0, map_height - h - 1)

+           # "Rect" class makes rectangles easier to work with
+           new_room = Rect(x, y, w, h)
+
+           # run through the other rooms and see if they intersect with this one
+           for other_room in rooms:
+               if new_room.intersects(other_room):
+                   break
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>            ...
            y = randint(0, map_height - h - 1)

            <span class="new-text"># "Rect" class makes rectangles easier to work with
            new_room = Rect(x, y, w, h)

            # run through the other rooms and see if they intersect with this one
            for other_room in rooms:
                if new_room.intersects(other_room):
                    break</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

If the room does *not* intersect any others, then we'll need to create
it. Rather than introducing a boolean (True/False value) to keep track
of whether or not we intersected, we can simply use a for-else
statement\! This is a unique, lesser known Python technique, which
basically says "if the for loop did not 'break', then do this". We'll
put our room placement code in this 'else' statement right after the
for-loop.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
            ...
            for other_room in rooms:
                if new_room.intersect(other_room):
                    break
+           else:
+               # this means there are no intersections, so this room is valid
+
+               # "paint" it to the map's tiles
+               self.create_room(new_room)
+
+               # center coordinates of new room, will be useful later
+               (new_x, new_y) = new_room.center
+
+               if number_of_rooms == 0:
+                   # this is the first room, where the player starts at
+                   player.x = new_x
+                   player.y = new_y
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>            ...
            for other_room in rooms:
                if new_room.intersect(other_room):
                    break
            <span class="new-text">else:
                # this means there are no intersections, so this room is valid

                # "paint" it to the map's tiles
                self.create_room(new_room)

                # center coordinates of new room, will be useful later
                (new_x, new_y) = new_room.center

                if number_of_rooms == 0:
                    # this is the first room, where the player starts at
                    player.x = new_x
                    player.y = new_y</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

We're creating our room, and saving the coordinates of its "center". If
it's the first room we've created, then we place the player right in the
middle of it. We'll also put these center coordinates to use in just a
moment to create our tunnels.

{{< codetab >}} {{< diff-tab >}} {{< highlight diff >}}
                ...
                if number_of_rooms == 0:
                    # this is the first room, where the player starts at
                    player.x = new_x
                    player.y = new_y
+               else:
+                   # all rooms after the first:
+                   # connect it to the previous room with a tunnel
+
+                   # center coordinates of previous room
+                   (prev_x, prev_y) = rooms[number_of_rooms - 1].center
+
+                   # flip a coin (random number that is either 0 or 1)
+                   if randint(0, 1) == 1:
+                       # first move horizontally, then vertically
+                       self.create_horizontal_tunnel(prev_x, new_x, prev_y)
+                       self.create_vertical_tunnel(prev_y, new_y, new_x)
+                   else:
+                       # first move vertically, then horizontally
+                       self.create_vertical_tunnel(prev_y, new_y, prev_x)
+                       self.create_horizontal_tunnel(prev_x, new_x, new_y)
+
+               # finally, append the new room to the list
+               rooms.append(new_room)
+               number_of_rooms += 1
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>                ...
                if number_of_rooms == 0:
                    # this is the first room, where the player starts at
                    player.x = new_x
                    player.y = new_y
                <span class="new-text">else:
                    # all rooms after the first:
                    # connect it to the previous room with a tunnel

                    # center coordinates of previous room
                    (prev_x, prev_y) = rooms[number_of_rooms - 1].center

                    # flip a coin (random number that is either 0 or 1)
                    if randint(0, 1) == 1:
                        # first move horizontally, then vertically
                        self.create_horizontal_tunnel(prev_x, new_x, prev_y)
                        self.create_vertical_tunnel(prev_y, new_y, new_x)
                    else:
                        # first move vertically, then horizontally
                        self.create_vertical_tunnel(prev_y, new_y, prev_x)
                        self.create_horizontal_tunnel(prev_x, new_x, new_y)

                # finally, append the new room to the list
                rooms.append(new_room)
                number_of_rooms += 1</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

This 'else' statement covers all cases where we've already placed at
least one room. In order for our dungeon to be navigable, we need to
ensure connectivity by creating tunnels. We get the center of the
previous room, and then, based on a random choice (between one or zero,
or a coin toss if you prefer to think of it that way), we carve our
tunnels, either vertically then horizontally or vice versa. After all
that, we append the room to our 'rooms' list, and increment the number
of rooms.

And that's it\! There's our functioning, albeit basic, dungeon
generation algorithm. Run the project now and you should be placed in a
procedurally generated dungeon\! Note that our NPC isn't being placed
intelligently here, so it may or may not be stuck in a wall.

If you want to see the code so far in its entirety, [click
here](https://github.com/TStand90/tcod_tutorial_v2/tree/part-3).

The next part of this tutorial will be available on June 30th. Check back soon!
