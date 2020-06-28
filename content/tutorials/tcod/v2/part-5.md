---
title: "Part 5"
date: 2020-06-29
draft: true
---

What good is a dungeon with no monsters to bash? This chapter will focus
on placing the enemies throughout the dungeon, and setting them up to be
attacked (the actual attacking part we'll save for next time).

When we're building our dungeon, we'll need to place the enemies in the rooms. In order to do that, we will need to make a change to the way `entities` are stored in our game. Currently, they're saved in the `Engine` class. However, for the sake of placing enemies in the dungeon, and when we get to the part where we move between dungeon floors, it will be better to store them in the `GameMap` class. That way, the map has access to the entities directly, and we can preserve which entities are on which floors fairly easily.

Start by modifying `Engine`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class Engine:
-   def __init__(self, entities: Set[Entity], event_handler: EventHandler, game_map: GameMap, player: Entity):
+   def __init__(self, event_handler: EventHandler, game_map: GameMap, player: Entity):
-       self.entities = entities
        self.event_handler = event_handler
        self.game_map = game_map
        self.player = player
        self.update_fov()
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class Engine:
    <span class="crossed-out-text">def __init__(self, entities: Set[Entity], event_handler: EventHandler, game_map: GameMap, player: Entity):</span>
    <span class="new-text">def __init__(self, event_handler: EventHandler, game_map: GameMap, player: Entity):</span>
        <span class="crossed-out-text">self.entities = entities</span>
        self.event_handler = event_handler
        self.game_map = game_map
        self.player = player
        self.update_fov()</pre>
{{</ original-tab >}}
{{</ codetab >}}

Because we've modified the definition of `GameMap.__init__`, we need to modify `main.py` where we create our `game_map` variable. We might as well remove that `npc` as well, since we won't be needing it anymore.

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
    ...
    player = Entity(int(screen_width / 2), int(screen_height / 2), "@", (255, 255, 255))
-   npc = Entity(int(screen_width / 2 - 5), int(screen_height / 2), "@", (255, 255, 0))
-   entities = {npc, player}

    game_map = generate_dungeon(
        max_rooms=max_rooms,
        room_min_size=room_min_size,
        room_max_size=room_max_size,
        map_width=map_width,
        map_height=map_height,
        player=player
    )

-   engine = Engine(entities=entities, event_handler=event_handler, game_map=game_map, player=player)
+   engine = Engine(event_handler=event_handler, game_map=game_map, player=player)

    with tcod.context.new_terminal(
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>    ...
    player = Entity(int(screen_width / 2), int(screen_height / 2), "@", (255, 255, 255))
    <span class="crossed-out-text">npc = Entity(int(screen_width / 2 - 5), int(screen_height / 2), "@", (255, 255, 0))</span>
    <span class="crossed-out-text">entities = {npc, player}</span>

    game_map = generate_dungeon(
        max_rooms=max_rooms,
        room_min_size=room_min_size,
        room_max_size=room_max_size,
        map_width=map_width,
        map_height=map_height,
        player=player
    )

    <span class="crossed-out-text">engine = Engine(entities=entities, event_handler=event_handler, game_map=game_map, player=player)</span>
    <span class="new-text">engine = Engine(event_handler=event_handler, game_map=game_map, player=player)</span>

    with tcod.context.new_terminal(
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

We can remove the part in `Engine.render` that loops through the entities and renders the ones that are visible. That part will also be handled by the `GameMap` from now on.

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class Engine:
    ...

    def render(self, console: Console, context: Context) -> None:
        self.game_map.render(console)

-       for entity in self.entities:
-           # Only print entities that are in the FOV
-           if self.game_map.visible[entity.x, entity.y]:
-               console.print(entity.x, entity.y, entity.char, fg=entity.color)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class Engine:
    ...

    def render(self, console: Console, context: Context) -> None:
        self.game_map.render(console)

        <span class="crossed-out-text">for entity in self.entities:</span>
            <span class="crossed-out-text"># Only print entities that are in the FOV</span>
            <span class="crossed-out-text">if self.game_map.visible[entity.x, entity.y]:</span>
                <span class="crossed-out-text">console.print(entity.x, entity.y, entity.char, fg=entity.color)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

We can move this block into `GameMap.render`, though take note that the line that checks for visibility has a slight change: it goes from:

`if self.game_map.visible[entity.x, entity.y]:`

To:

`if self.visible[entity.x, entity.y]:`.

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class GameMap:
    ...

    def render(self, console: Console) -> None:
        """
        Renders the map.

        If a tile is in the "visible" array, then draw it with the "light" colors.
        If it isn't, but it's in the "explored" array, then draw it with the "dark" colors.
        Otherwise, the default is "SHROUD".
        """
        console.tiles_rgb[0:self.width, 0:self.height] = np.select(
            condlist=[self.visible, self.explored],
            choicelist=[self.tiles["light"], self.tiles["dark"]],
            default=tile_types.SHROUD
        )

+       for entity in self.entities:
+           # Only print entities that are in the FOV
+           if self.visible[entity.x, entity.y]:
+               console.print(entity.x, entity.y, entity.char, fg=entity.color)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class GameMap:
    ...

    def render(self, console: Console) -> None:
        """
        Renders the map.

        If a tile is in the "visible" array, then draw it with the "light" colors.
        If it isn't, but it's in the "explored" array, then draw it with the "dark" colors.
        Otherwise, the default is "SHROUD".
        """
        console.tiles_rgb[0:self.width, 0:self.height] = np.select(
            condlist=[self.visible, self.explored],
            choicelist=[self.tiles["light"], self.tiles["dark"]],
            default=tile_types.SHROUD
        )

        <span class="new-text">for entity in self.entities:
            # Only print entities that are in the FOV
            if self.visible[entity.x, entity.y]:
                console.print(entity.x, entity.y, entity.char, fg=entity.color)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Finally, we need to alter the part in `generate_dungeon` that creates the instance of `GameMap`, so that the `player` is passed into the `entities` argument.

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
def generate_dungeon(
    max_rooms: int,
    room_min_size: int,
    room_max_size: int,
    map_width: int,
    map_height: int,
    player: Entity,
) -> GameMap:
    """Generate a new dungeon map."""
-   dungeon = GameMap(map_width, map_height)
+   dungeon = GameMap(map_width, map_height, entities=[player])

    rooms: List[RectangularRoom] = []
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>def generate_dungeon(
    max_rooms: int,
    room_min_size: int,
    room_max_size: int,
    map_width: int,
    map_height: int,
    player: Entity,
) -> GameMap:
    """Generate a new dungeon map."""
    <span class="crossed-out-text">dungeon = GameMap(map_width, map_height)</span>
    <span class="new-text">dungeon = GameMap(map_width, map_height, entities=[player])</span>

    rooms: List[RectangularRoom] = []
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

If you run the project now, things should look the same as before, minus the NPC that we had earlier for testing.
