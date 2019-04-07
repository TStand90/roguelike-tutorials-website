---
title: "Part 3 - Generating a dungeon"
date: 2019-03-30T08:39:22-07:00
draft: false
---

Welcome back to the Roguelike Tutorial Revised\! In this tutorial, we'll
be taking a **very** important step towards having a real, functioning
game: Creating a procedurally generated dungeon\!

Remember that little wall we created for demonstration purposes in the
last tutorial? We don't need it anymore, so let's take it out.

```diff
        tiles[30][22].blocked = True
-       tiles[30][22].block_sight = True
-       tiles[31][22].blocked = True
-       tiles[31][22].block_sight = True
-       tiles[32][22].blocked = True
-       tiles[32][22].block_sight = True
```

We also need to make a slight change to the list comprehension that
created our
Tiles.

```diff
        tiles = [[Tile(False) for y in range(self.height)] for x in range(self.width)]
+       tiles = [[Tile(True) for y in range(self.height)] for x in range(self.width)]
```

Why are we changing the `False` to `True`? Before, we were setting every
Tile to be walk-able by default, so that we could move around easily.
Hence, we passed `False` to the `Tile` class, so that the `blocked`
attribute would be False.

However, our dungeon generation algorithm works the opposite way: We
start with a completely walled off room, and start "digging" out
sections as we go along. Therefore, we initialize all our tiles to be
blocked by default. For the record: every dungeon generation algorithm
I've seen does this in some way.

One more thing we'll want to do before getting to our dungeon algorithm
is defining a helper class for our "rooms". This will be a basic class
that holds some information about dimensions, which we'll call `Rect`
(short for rectangle). Create a new file in the `map_objects` folder,
and name it `rectangle.py`. Enter the following code into it:

```py3
class Rect:
    def __init__(self, x, y, w, h):
        self.x1 = x
        self.y1 = y
        self.x2 = x + w
        self.y2 = y + h
```

The `__init__` function takes the x and y coordinates of the top left
corner, and computes the bottom right corner based on the w and h
parameters (width and height). We'll be adding more to this class
shortly, but to get us started, that's all we need.

Now, if we're going to be "carving out" a bunch of rooms to create our
dungeon, we'll want a function to create a room. This function should
take an argument, which we'll call `room`, and that argument should be
of the `Rect` class we just created. From x1 to x2, and y1 to y2, we'll
want to set each tile in the `Rect` to be not blocked, so the player can
move around in it. We can put this function in the `GameMap` class,
since it will be manipulating the map's list of tiles.

What we end up with is this function:

```diff
    def initialize_tiles(self):
        ...

+   def create_room(self, room):
+       # go through the tiles in the rectangle and make them passable
+       for x in range(room.x1 + 1, room.x2):
+           for y in range(room.y1 + 1, room.y2):
+               self.tiles[x][y].blocked = False
+               self.tiles[x][y].block_sight = False

    def is_blocked(self, x, y):
        ...
```

*\* Note: `initialize_tiles` and `is_blocked` shortened for the sake of
brevity.*

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

*\* Note: In case you're wondering, we don't subtract 1 from x2 and y2
because Python's range function does not include the 'end' value in its
range. For example, range(0, 10) would give us \[0, 1, 2, 3, 4, 5, 6, 7,
8, 9\].*

Let's make some rooms\! We'll need a function in `GameMap` to generate
our map, so let's add one:

```diff
    def initialize_tiles(self):
        ...

+   def make_map(self):
+       # Create two rooms for demonstration purposes
+       room1 = Rect(20, 15, 10, 15)
+       room2 = Rect(35, 15, 10, 15)
+
+       self.create_room(room1)
+       self.create_room(room2)

    def create_room(self, room):
        ...
```

We need to import the `Rect` class into the `game_map` file in order for
this to work. At the top of the file, modify your import section:

    from map_objects.rectangle import Rect
    from map_objects.tile import Tile

Finally, modify `engine.py` to actually call the new `make_map`
function.

```diff
    game_map = GameMap(map_width, map_height)
+   game_map.make_map()
```

Now is a good time to run your code and make sure everything works as
expected. The changes we've made puts two sample rooms on the map, with
our player in one of them (our poor NPC is stuck in a wall though).

I'm sure you've noticed already, but the rooms are not connected. What's
the use of creating a dungeon if we're stuck in one room? Not to worry,
let's write some code to generate tunnels from one room to another. Add
the following methods to `GameMap`:

```diff
    def create_room(self, room):
        ...

+   def create_h_tunnel(self, x1, x2, y):
+       for x in range(min(x1, x2), max(x1, x2) + 1):
+           self.tiles[x][y].blocked = False
+           self.tiles[x][y].block_sight = False
+
+   def create_v_tunnel(self, y1, y2, x):
+       for y in range(min(y1, y2), max(y1, y2) + 1):
+           self.tiles[x][y].blocked = False
+           self.tiles[x][y].block_sight = False

    def is_blocked(self, x, y):
        ...
        
```

Let's put this code to use by drawing a tunnel between our two rooms.

```diff
        ...
        self.create_room(room2)

+       self.create_h_tunnel(25, 40, 23)
```

Now that we've demonstrated to ourselves that our room and tunnel
functions work as intended, it's time to move on to an actual dungeon
generation algorithm. Our will be fairly simple; we'll place rooms one
at a time, making sure they don't overlap, and connect them with
tunnels.

We'll need two additional functions in the `Rect` class to ensure that
two rectangles (rooms) don't overlap. Enter the following methods into
the `Rect` class:

```diff
class Rect:
    def __init__(self, x, y, w, h):
        self.x1 = x
        self.y1 = y
        self.x2 = x + w
        self.y2 = y + h

+   def center(self):
+       center_x = int((self.x1 + self.x2) / 2)
+       center_y = int((self.y1 + self.y2) / 2)
+       return (center_x, center_y)
+
+   def intersect(self, other):
+       # returns true if this rectangle intersects with another one
+       return (self.x1 <= other.x2 and self.x2 >= other.x1 and
+               self.y1 <= other.y2 and self.y2 >= other.y1)
```

Don't worry too much about the specifics here. Just know that the
'center' method gives us the center point of a rectangle, and that
'intersect' tells us if two rectangles overlap.

We're going to need a few variables to set the maximum and minimum size
of the rooms, along with the maximum number of rooms one floor can have.
Add the following to `engine.py`

```diff
    ...
    map_height = 45

+   room_max_size = 10
+   room_min_size = 6
+   max_rooms = 30

    colors = {
    ...
```

At long last, it's time to modify `make_map` to generate our dungeon\!
You can completely remove our old implementation and replace it with the
following:

```diff
    def make_map(self):
+   def make_map(self, max_rooms, room_min_size, room_max_size, map_width, map_height, player):
-       room1 = Rect(20, 15, 10, 15)
-       room2 = Rect(35, 15, 10, 15)

-       self.create_room(room1)
-       self.create_room(room2)

-       self.create_h_tunnel(25, 40, 23)

+       rooms = []
+       num_rooms = 0
+
+       for r in range(max_rooms):
+           # random width and height
+           w = randint(room_min_size, room_max_size)
+           h = randint(room_min_size, room_max_size)
+           # random position without going out of the boundaries of the map
+           x = randint(0, map_width - w - 1)
+           y = randint(0, map_height - h - 1)
```

The variables we're creating here will be what we use to create our
rooms momentarily. `randint` gives us a random integer between the
values we specify. In this case, we want our width and height to be
between our given minimums and maximums, and our x and y should be
within the boundaries of the map.

We also need to import `randint` from `random` at the top of the file.
Your import section for `game_map.py` should now look something like
this:

```py3
from random import randint

from map_objects.rectangle import Rect
from map_objects.tile import Tile
```

Last thing before we proceed: We need to update the call to `make_map`
in `engine.py`, because now we're asking for a bunch of variables that
we weren't before. Modify it to look like this:

```diff
    ...
    game_map = GameMap(map_width, map_height)
-   game_map.make_map()
+   game_map.make_map(max_rooms, room_min_size, room_max_size, map_width, map_height, player)
```

Now we'll put our `Rect` class to use, by passing it the variables we
just created. Then, we can check if it intersects with any other rooms.
If it does, we don't want to add it to our rooms, and we simply toss it
out.

```diff
            ...
            y = randint(0, map_height - h - 1)

+           # "Rect" class makes rectangles easier to work with
+           new_room = Rect(x, y, w, h)
+
+           # run through the other rooms and see if they intersect with this one
+           for other_room in rooms:
+               if new_room.intersect(other_room):
+                   break
```

If the room does *not* intersect any others, then we'll need to create
it. Rather than introducing a boolean (True/False value) to keep track
of whether or not we intersected, we can simply use a for-else
statement\! This is a unique, lesser known Python technique, which
basically says "if the for loop did not 'break', then do this". We'll
put our room placement code in this 'else' statement right after the
for-loop.

```diff
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
+               (new_x, new_y) = new_room.center()
+
+               if num_rooms == 0:
+                   # this is the first room, where the player starts at
+                   player.x = new_x
+                   player.y = new_y
```

We're creating our room, and saving the coordinates of its "center". If
it's the first room we've created, then we place the player right in the
middle of it. We'll also put these center coordinates to use in just a
moment to create our tunnels.

```diff
                ...
                if num_rooms == 0:
                    # this is the first room, where the player starts at
                    player.x = new_x
                    player.y = new_y
+               else:
+                   # all rooms after the first:
+                   # connect it to the previous room with a tunnel
+
+                   # center coordinates of previous room
+                   (prev_x, prev_y) = rooms[num_rooms - 1].center()
+
+                   # flip a coin (random number that is either 0 or 1)
+                   if randint(0, 1) == 1:
+                       # first move horizontally, then vertically
+                       self.create_h_tunnel(prev_x, new_x, prev_y)
+                       self.create_v_tunnel(prev_y, new_y, new_x)
+                   else:
+                       # first move vertically, then horizontally
+                       self.create_v_tunnel(prev_y, new_y, prev_x)
+                       self.create_h_tunnel(prev_x, new_x, new_y)
+
+               # finally, append the new room to the list
+               rooms.append(new_room)
+               num_rooms += 1
```

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
here](https://github.com/TStand90/roguelike_tutorial_revised/tree/part3).

[Click here to move on to the next part of this
tutorial.](/tutorials/tcod/part-4)

