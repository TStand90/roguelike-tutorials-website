---
title: "Part 4 - Field of View"
date: 2020-06-29
draft: false
---

We have a dungeon now, and we can move about it freely. But are we
really *exploring* the dungeon if we can just see it all from the
beginning?

Most roguelikes (not all\!) only let you see within a certain range of
your character, and ours will be no different. We need to implement a way
to calculate the "Field of View" for our adventurer, and fortunately,
tcod makes that easy\!

When walking around the dungeon, there will essentially be three "states" a tile can be in, relating to our field of view.

1. Visible
2. Not visible
3. Not visible, but previously seen

What this means is that we should draw the "visible" tiles as well as the "not visible, but previously seen" ones to the screen, but differentiate them somehow. The "not visible" tiles can simply be drawn as an empty tile, with the color black, gray, or whatever you want to use.

In order to differentiate between these tiles, we'll need two new Numpy arrays: One to keep track of the tiles that are currently visible, and another to keep track of all the tiles that our character has seen before. Add the two arrays to `GameMap` like this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class GameMap:
    def __init__(self, width: int, height: int):
        self.width, self.height = width, height
        self.tiles = np.full((width, height), fill_value=tile_types.wall, order="F")

+       self.visible = np.full((width, height), fill_value=False, order="F")  # Tiles the player can currently see
+       self.explored = np.full((width, height), fill_value=False, order="F")  # Tiles the player has seen before
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class GameMap:
    def __init__(self, width: int, height: int):
        self.width, self.height = width, height
        self.tiles = np.full((width, height), fill_value=tile_types.wall, order="F")

        <span class="new-text">self.visible = np.full((width, height), fill_value=False, order="F")  # Tiles the player can currently see
        self.explored = np.full((width, height), fill_value=False, order="F")  # Tiles the player has seen before</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

We create two arrays, `visible` and `explored`, and fill them with the value `False`. In a moment, we'll create a function that will update these arrays based on what's in the field of view.

Let's turn our attention back to the tile types. Remember when we specified the "walkable", "transparent", and "dark" attributes? We called it "dark" because it's what the tile will look like when its not in the field of view, but what about when it *is*?

For that, we'll want a new `graphic_dt` in the `tile_dt` type, called `light`. We can add that by modifying `tile_types.py` like this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
tile_dt = np.dtype(
    [
        ("walkable", np.bool),  # True if this tile can be walked over.
        ("transparent", np.bool),  # True if this tile doesn't block FOV.
        ("dark", graphic_dt),  # Graphics for when this tile is not in FOV.
+       ("light", graphic_dt),  # Graphics for when the tile is in FOV.
    ]
)


def new_tile(
    *,  # Enforce the use of keywords, so that parameter order doesn't matter.
    walkable: int,
    transparent: int,
    dark: Tuple[int, Tuple[int, int, int], Tuple[int, int, int]],
+   light: Tuple[int, Tuple[int, int, int], Tuple[int, int, int]],
) -> np.ndarray:
    """Helper function for defining individual tile types """
-   return np.array((walkable, transparent, dark), dtype=tile_dt)
+   return np.array((walkable, transparent, dark, light), dtype=tile_dt)


+# SHROUD represents unexplored, unseen tiles
+SHROUD = np.array((ord(" "), (255, 255, 255), (0, 0, 0)), dtype=graphic_dt)

floor = new_tile(
-   walkable=True, transparent=True, dark=(ord(" "), (255, 255, 255), (50, 50, 150)),
+   walkable=True,
+   transparent=True,
+   dark=(ord(" "), (255, 255, 255), (50, 50, 150)),
+   light=(ord(" "), (255, 255, 255), (200, 180, 50)),
)
wall = new_tile(
-   walkable=False, transparent=False, dark=(ord(" "), (255, 255, 255), (0, 0, 100)),
+   walkable=False,
+   transparent=False,
+   dark=(ord(" "), (255, 255, 255), (0, 0, 100)),
+   light=(ord(" "), (255, 255, 255), (130, 110, 50)),
)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>tile_dt = np.dtype(
    [
        ("walkable", np.bool),  # True if this tile can be walked over.
        ("transparent", np.bool),  # True if this tile doesn't block FOV.
        ("dark", graphic_dt),  # Graphics for when this tile is not in FOV.
        <span class="new-text">("light", graphic_dt),  # Graphics for when the tile is in FOV.</span>
    ]
)


def new_tile(
    *,  # Enforce the use of keywords, so that parameter order doesn't matter.
    walkable: int,
    transparent: int,
    dark: Tuple[int, Tuple[int, int, int], Tuple[int, int, int]],
    <span class="new-text">light: Tuple[int, Tuple[int, int, int], Tuple[int, int, int]],</span>
) -> np.ndarray:
    """Helper function for defining individual tile types """
    <span class="crossed-out-text">return np.array((walkable, transparent, dark), dtype=tile_dt)</span>
    <span class="new-text">return np.array((walkable, transparent, dark, light), dtype=tile_dt)</span>


<span class="new-text"># SHROUD represents unexplored, unseen tiles
SHROUD = np.array((ord(" "), (255, 255, 255), (0, 0, 0)), dtype=graphic_dt)</span>

floor = new_tile(
    <span class="crossed-out-text">walkable=True, transparent=True, dark=(ord(" "), (255, 255, 255), (50, 50, 150)),</span>
    <span class="new-text">walkable=True,
    transparent=True,
    dark=(ord(" "), (255, 255, 255), (50, 50, 150)),
    light=(ord(" "), (255, 255, 255), (200, 180, 50)),</span>
)
wall = new_tile(
    <span class="crossed-out-text">walkable=False, transparent=False, dark=(ord(" "), (255, 255, 255), (0, 0, 100)),</span>
    <span class="new-text">walkable=False,
    transparent=False,
    dark=(ord(" "), (255, 255, 255), (0, 0, 100)),
    light=(ord(" "), (255, 255, 255), (130, 110, 50)),</span>
)</pre>
{{</ original-tab >}}
{{</ codetab >}}

Let's go through the new additions.

```py3
tile_dt = np.dtype(
    [
        ("walkable", np.bool),  # True if this tile can be walked over.
        ("transparent", np.bool),  # True if this tile doesn't block FOV.
        ("dark", graphic_dt),  # Graphics for when this tile is not in FOV.
        ("light", graphic_dt),  # Graphics for when the tile is in FOV.
    ]
)
```

We're adding a new `graphic_dt` to the `tile_dt` that we use to define our tiles. `light` will hold the information about what our tile looks like when it's in the field of view.

```py3
def new_tile(
    *,  # Enforce the use of keywords, so that parameter order doesn't matter.
    walkable: int,
    transparent: int,
    dark: Tuple[int, Tuple[int, int, int], Tuple[int, int, int]],
    light: Tuple[int, Tuple[int, int, int], Tuple[int, int, int]],
) -> np.ndarray:
    """Helper function for defining individual tile types """
    return np.array((walkable, transparent, dark, light), dtype=tile_dt)
```

We've modified the `new_tile` function to account for the new `light` attribute. `light` works the same as `dark`.

```py3
# SHROUD represents unexplored, unseen tiles
SHROUD = np.array((ord(" "), (255, 255, 255), (0, 0, 0)), dtype=graphic_dt)
```

`SHROUD` is what we'll use for when a tile is neither in view nor has been "explored". It's set to just draw a black tile.

```py3
floor = new_tile(
    walkable=True,
    transparent=True,
    dark=(ord(" "), (255, 255, 255), (50, 50, 150)),
    light=(ord(" "), (255, 255, 255), (200, 180, 50)),
)
wall = new_tile(
    walkable=False,
    transparent=False,
    dark=(ord(" "), (255, 255, 255), (0, 0, 100)),
    light=(ord(" "), (255, 255, 255), (130, 110, 50)),
)
```

Finally, we add `light` to both the `floor` and `wall` tiles. We also modify the functions to fit a bit better on the screen, adding new lines after each argument. This is just for the sake of readability.

`light` in both cases is set to a brighter color, so that when we draw the field of view to the screen, the player can easily differentiate between what's in view and what's not. As usual, feel free to play with the color schemes to match whatever you might have in mind.

With all that in place, we need to modify the way `GameMap` draws itself to the screen.

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class GameMap:
    ...

    def render(self, console: Console) -> None:
-       console.tiles_rgb[0:self.width, 0:self.height] = self.tiles["dark"]
+       """
+       Renders the map.
+
+       If a tile is in the "visible" array, then draw it with the "light" colors.
+       If it isn't, but it's in the "explored" array, then draw it with the "dark" colors.
+       Otherwise, the default is "SHROUD".
+       """
+       console.tiles_rgb[0:self.width, 0:self.height] = np.select(
+           condlist=[self.visible, self.explored],
+           choicelist=[self.tiles["light"], self.tiles["dark"]],
+           default=tile_types.SHROUD
+       )
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class GameMap:
    ...

    def render(self, console: Console) -> None:
        <span class="crossed-out-text">console.tiles_rgb[0:self.width, 0:self.height] = self.tiles["dark"]</span>
        <span class="new-text">"""
        Renders the map.

        If a tile is in the "visible" array, then draw it with the "light" colors.
        If it isn't, but it's in the "explored" array, then draw it with the "dark" colors.
        Otherwise, the default is "SHROUD".
        """
        console.tiles_rgb[0:self.width, 0:self.height] = np.select(
            condlist=[self.visible, self.explored],
            choicelist=[self.tiles["light"], self.tiles["dark"]],
            default=tile_types.SHROUD
        )</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

The first part of the statement, `console.tiles_rgb[0:self.width, 0:self.height]`, hasn't changed. But instead of just setting it to `self.tiles["dark"]`, we're using `np.select`.

`np.select` allows us to conditionally draw the tiles we want, based on what's specified in `condlist`. Since we're passing `[self.visible, self.explored]`, it will check if the tile being drawn is either visible, then explored. If it's visible, it uses the first value in `choicelist`, in this case, `self.tiles["light"]`. If it's not visible, but explored, then we draw `self.tiles["dark"]`. If neither is true, we use the `default` argument, which is just the `SHROUD` we defined earlier.

If you run the project now, none of the tiles will be drawn to the screen. This is because we need a way to actually modify the `visible` and `explored` tiles. Let's modify `Engine` to do just that:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
...
from tcod.context import Context
from tcod.console import Console
+from tcod.map import compute_fov

from entity import Entity
...

class Engine:
    def __init__(self, entities: Set[Entity], event_handler: EventHandler, game_map: GameMap, player: Entity):
        self.entities = entities
        self.event_handler = event_handler
        self.game_map = game_map
        self.player = player
+       self.update_fov()

    def handle_events(self, events: Iterable[Any]) -> None:
        for event in events:
            action = self.event_handler.dispatch(event)

            if action is None:
                continue

            action.perform(self, self.player)

+           self.update_fov()  # Update the FOV before the players next action.

+   def update_fov(self) -> None:
+       """Recompute the visible area based on the players point of view."""
+       self.game_map.visible[:] = compute_fov(
+           self.game_map.tiles["transparent"],
+           (self.player.x, self.player.y),
+           radius=8,
+       )
+       # If a tile is "visible" it should be added to "explored".
+       self.game_map.explored |= self.game_map.visible

    def render(self, console: Console, context: Context) -> None:
        self.game_map.render(console)

        for entity in self.entities:
-           console.print(entity.x, entity.y, entity.char, fg=entity.color)
+           # Only print entities that are in the FOV
+           if self.game_map.visible[entity.x, entity.y]:
+               console.print(entity.x, entity.y, entity.char, fg=entity.color)

        context.present(console)

        console.clear()
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>...
from tcod.context import Context
from tcod.console import Console
<span class="new-text">from tcod.map import compute_fov</span>

from entity import Entity
...

class Engine:
    def __init__(self, entities: Set[Entity], event_handler: EventHandler, game_map: GameMap, player: Entity):
        self.entities = entities
        self.event_handler = event_handler
        self.game_map = game_map
        self.player = player
        <span class="new-text">self.update_fov()</span>

    def handle_events(self, events: Iterable[Any]) -> None:
        for event in events:
            action = self.event_handler.dispatch(event)

            if action is None:
                continue

            action.perform(self, self.player)

            <span class="new-text">self.update_fov()  # Update the FOV before the players next action.</span>

    <span class="new-text">def update_fov(self) -> None:
        """Recompute the visible area based on the players point of view."""
        self.game_map.visible[:] = compute_fov(
            self.game_map.tiles["transparent"],
            (self.player.x, self.player.y),
            radius=8,
        )
        # If a tile is "visible" it should be added to "explored".
        self.game_map.explored |= self.game_map.visible</span>

    def render(self, console: Console, context: Context) -> None:
        self.game_map.render(console)

        for entity in self.entities:
            <span class="crossed-out-text">console.print(entity.x, entity.y, entity.char, fg=entity.color)</span>
            <span class="new-text"># Only print entities that are in the FOV
            if self.game_map.visible[entity.x, entity.y]:
                console.print(entity.x, entity.y, entity.char, fg=entity.color)</span>

        context.present(console)

        console.clear()</pre>
{{</ original-tab >}}
{{</ codetab >}}

The most important part of our additions is the `update_fov` function.

```py3
    def update_fov(self) -> None:
        """Recompute the visible area based on the players point of view."""
        self.game_map.visible[:] = compute_fov(
            self.game_map.tiles["transparent"],
            (self.player.x, self.player.y),
            radius=8,
        )
        # If a tile is "visible" it should be added to "explored".
        self.game_map.explored |= self.game_map.visible
```

We're setting the `game_map`'s `visible` tiles to equal the result of the `compute_fov`. We're giving `compute_fov` three arguments, which it uses to compute our field of view.

* `transparency`: This is the first argument, which we're passing `self.game_map.tiles["transparent"]`. `transparency` takes a 2D numpy array, and considers any non-zero values to be transparent. This is the array it uses to calculate the field of view.
* `pov`: The origin point for the field of view, which is a 2D index. We use the player's x and y position here.
* `radius`: How far the FOV extends.

There's more that this function can do, including not lighting up walls, and using different algorithms to calculate the FOV. If you're interested, you can find the documentation [here](https://python-tcod.readthedocs.io/en/latest/tcod/map.html#tcod.map.compute_fov).

The line `self.game_map.explored |= self.game_map.visible` sets the `explored` array to include everything in the `visible` array, plus whatever it already had. This means that any tile the player can see, the player has also "explored."

That's all we need to do to update our field of view. Notice that we call the function when we initialize the `Engine` class, so that the field of view is created before the player can move, and after handling an action, so that whenever the player does move, the field of view will be updated.

Lastly, we modify the part that draws the entities, so that only entities in the field of view are drawn.

Run the project now, and you'll see something like this:

![Part 4 - FOV](/images/part-4-fov.png "Field of View")

It's hard to believe, but that's all we need to do for a functioning field of view!

This chapter was a shorter one, but we've accomplished quite a lot. Our dungeon feels a lot more mysterious, and in coming chapters, it will get a lot more dangerous.

If you want to see the code so far in its entirety, [click
here](https://github.com/TStand90/tcod_tutorial_v2/tree/2020/part-4).

[Click here to move on to the next part of this
tutorial.](../part-5)
