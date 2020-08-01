---
title: "Part 10 - Saving and loading"
date: 2020-07-21
draft: true
---

Saving and loading is essential to almost every roguelike, but it can be a pain to manage if you don't start early. By the end of this chapter, our game will be able to save and load one file to the disk, which you could easily expand to multiple saves if you wanted to.

Let's start by defining the colors we'll need this chapter, by opening `color.py` and entering the following:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
...
bar_empty = (0x40, 0x10, 0x10)

+menu_title = (255, 255, 63)
+menu_text = white
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>...
bar_empty = (0x40, 0x10, 0x10)

<span class="new-text">menu_title = (255, 255, 63)
menu_text = white</span></pre>
{{</ original-tab >}}
{{</ codetab >}}


{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
import components.ai
import components.inventory
from components.base_component import BaseComponent
from exceptions import Impossible
-from input_handlers import AreaRangedAttackHandler, SingleRangedAttackHandler
+from input_handlers import (
+   ActionOrHandler,
+   AreaRangedAttackHandler,
+   SingleRangedAttackHandler,
+)
 
if TYPE_CHECKING:
    ...

...
class Consumable(BaseComponent):
    parent: Item
 
-   def get_action(self, consumer: Actor) -> Optional[actions.Action]:
+   def get_action(self, consumer: Actor) -> Optional[ActionOrHandler]:
        """Try to return the action for this item."""
        return actions.ItemAction(consumer, self.parent)
 
@@ -40,15 +44,14 @@ class ConfusionConsumable(Consumable):
    def __init__(self, number_of_turns: int):
        self.number_of_turns = number_of_turns
 
-   def get_action(self, consumer: Actor) -> Optional[actions.Action]:
+   def get_action(self, consumer: Actor) -> SingleRangedAttackHandler:
        self.engine.message_log.add_message(
            "Select a target location.", color.needs_target
        )
-       self.engine.event_handler = SingleRangedAttackHandler(
+       return SingleRangedAttackHandler(
            self.engine,
            callback=lambda xy: actions.ItemAction(consumer, self.parent, xy),
        )
-       return None
 
    def activate(self, action: actions.ItemAction) -> None:
        consumer = action.entity
@@ -76,16 +79,15 @@ class FireballDamageConsumable(Consumable):
        self.damage = damage
        self.radius = radius
 
-   def get_action(self, consumer: Actor) -> Optional[actions.Action]:
+   def get_action(self, consumer: Actor) -> AreaRangedAttackHandler:
        self.engine.message_log.add_message(
            "Select a target location.", color.needs_target
        )
-       self.engine.event_handler = AreaRangedAttackHandler(
+       return AreaRangedAttackHandler(
            self.engine,
            radius=self.radius,
            callback=lambda xy: actions.ItemAction(consumer, self.parent, xy),
        )
-       return None
 
    def activate(self, action: actions.ItemAction) -> None:
        target_xy = action.target_xy
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre></pre>
{{</ original-tab >}}
{{</ codetab >}}


TODO: Fill this in

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from __future__ import annotations
 
+import lzma
+import pickle
from typing import TYPE_CHECKING
 
from tcod.console import Console
from tcod.map import compute_fov
 
import exceptions
-from input_handlers import MainGameEventHandler
from message_log import MessageLog
from render_functions import (
    render_bar,
    render_names_at_mouse_location,
)

if TYPE_CHECKING:
    from entity import Actor
    from game_map import GameMap
-   from input_handlers import EventHandler
 
 
class Engine:
    game_map: GameMap
 
    def __init__(self, player: Actor):
-       self.event_handler: EventHandler = MainGameEventHandler(self)
        self.message_log = MessageLog()
        self.mouse_location = (0, 0)
        self.player = player
        ...

    def render(self, console: Console) -> None:
        ...

+   def save_as(self, filename: str) -> None:
+       """Save this Engine instance as a compressed file."""
+       save_data = lzma.compress(pickle.dumps(self))
+       with open(filename, "wb") as f:
+           f.write(save_data)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from __future__ import annotations
 
<span class="new-text">import lzma
import pickle</span>
from typing import TYPE_CHECKING
 
from tcod.console import Console
from tcod.map import compute_fov
 
import exceptions
<span class="crossed-out-text">from input_handlers import MainGameEventHandler</span>
from message_log import MessageLog
from render_functions import (
    render_bar,
    render_names_at_mouse_location,
)

if TYPE_CHECKING:
    from entity import Actor
    from game_map import GameMap
    <span class="crossed-out-text">from input_handlers import EventHandler</span>
 
 
class Engine:
    game_map: GameMap
 
    def __init__(self, player: Actor):
        <span class="crossed-out-text">self.event_handler: EventHandler = MainGameEventHandler(self)</span>
        self.message_log = MessageLog()
        self.mouse_location = (0, 0)
        self.player = player
        ...

    def render(self, console: Console) -> None:
        ...

    <span class="new-text">def save_as(self, filename: str) -> None:
        """Save this Engine instance as a compressed file."""
        save_data = lzma.compress(pickle.dumps(self))
        with open(filename, "wb") as f:
            f.write(save_data)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class Impossible(Exception):
    """Exception raised when an action is impossible to be performed.

    The reason is given as the exception message.
    """


+class QuitWithoutSaving(SystemExit):
+   """Can be raised to exit the game without automatically saving."""
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class Impossible(Exception):
    """Exception raised when an action is impossible to be performed.

    The reason is given as the exception message.
    """


<span class="new-text">class QuitWithoutSaving(SystemExit):
    """Can be raised to exit the game without automatically saving."""</span></pre>
{{</ original-tab >}}
{{</ codetab >}}


```py3
"""Handle the loading and initialization of game sessions."""
from __future__ import annotations

import copy
import lzma
import pickle
import traceback
from typing import Optional

import tcod

import color
from engine import Engine
import entity_factories
import input_handlers
from procgen import generate_dungeon


# Load the background image and remove the alpha channel.
background_image = tcod.image.load("menu_background.png")[:, :, :3]


def new_game() -> Engine:
    """Return a brand new game session as an Engine instance."""
    map_width = 80
    map_height = 43

    room_max_size = 10
    room_min_size = 6
    max_rooms = 30

    max_monsters_per_room = 2
    max_items_per_room = 2

    player = copy.deepcopy(entity_factories.player)

    engine = Engine(player=player)

    engine.game_map = generate_dungeon(
        max_rooms=max_rooms,
        room_min_size=room_min_size,
        room_max_size=room_max_size,
        map_width=map_width,
        map_height=map_height,
        max_monsters_per_room=max_monsters_per_room,
        max_items_per_room=max_items_per_room,
        engine=engine,
    )
    engine.update_fov()

    engine.message_log.add_message(
        "Hello and welcome, adventurer, to yet another dungeon!", color.welcome_text
    )
    return engine


def load_game(filename: str) -> Engine:
    """Load an Engine instance from a file."""
    with open(filename, "rb") as f:
        engine = pickle.loads(lzma.decompress(f.read()))
    assert isinstance(engine, Engine)
    return engine


class MainMenu(input_handlers.BaseEventHandler):
    """Handle the main menu rendering and input."""

    def on_render(self, console: tcod.Console) -> None:
        """Render the main menu on a background image."""
        console.draw_semigraphics(background_image, 0, 0)

        console.print(
            console.width // 2,
            console.height // 2 - 4,
            "TOMBS OF THE ANCIENT KINGS",
            fg=color.menu_title,
            alignment=tcod.CENTER,
        )
        console.print(
            console.width // 2,
            console.height - 2,
            "By (Your name here)",
            fg=color.menu_title,
            alignment=tcod.CENTER,
        )

        menu_width = 24
        for i, text in enumerate(
            ["[N] Play a new game", "[C] Continue last game", "[Q] Quit"]
        ):
            console.print(
                console.width // 2,
                console.height // 2 - 2 + i,
                text.ljust(menu_width),
                fg=color.menu_text,
                bg=color.black,
                alignment=tcod.CENTER,
                bg_blend=tcod.BKGND_ALPHA(64),
            )

    def ev_keydown(
        self, event: tcod.event.KeyDown
    ) -> Optional[input_handlers.BaseEventHandler]:
        if event.sym in (tcod.event.K_q, tcod.event.K_ESCAPE):
            raise SystemExit()
        elif event.sym == tcod.event.K_c:
            try:
                return input_handlers.MainGameEventHandler(load_game("savegame.sav"))
            except FileNotFoundError:
                return input_handlers.PopupMessage(self, "No saved game to load.")
            except Exception as exc:
                traceback.print_exc()  # Print to stderr.
                return input_handlers.PopupMessage(self, f"Failed to load save:\n{exc}")
        elif event.sym == tcod.event.K_n:
            return input_handlers.MainGameEventHandler(new_game())

        return None
```


{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
#!/usr/bin/env python3
-import copy
import traceback
 
import tcod
 
import color
-from engine import Engine
-import entity_factories
-from procgen import generate_dungeon
+import exceptions
+import setup_game
+import input_handlers


+def save_game(handler: input_handlers.BaseEventHandler, filename: str) -> None:
+   """If the current event handler has an active Engine then save it."""
+   if isinstance(handler, input_handlers.EventHandler):
+       handler.engine.save_as(filename)
+       print("Game saved.")
 
 
def main() -> None:
    screen_width = 80
    screen_height = 50
 
-   map_width = 80
-   map_height = 43

-   room_max_size = 10
-   room_min_size = 6
-   max_rooms = 30

-   max_monsters_per_room = 2
-   max_items_per_room = 2

    tileset = tcod.tileset.load_tilesheet(
        "dejavu10x10_gs_tc.png", 32, 8, tcod.tileset.CHARMAP_TCOD
    )

-   player = copy.deepcopy(entity_factories.player)

-   engine = Engine(player=player)

-   engine.game_map = generate_dungeon(
-       max_rooms=max_rooms,
-       room_min_size=room_min_size,
-       room_max_size=room_max_size,
-       map_width=map_width,
-       map_height=map_height,
-       max_monsters_per_room=max_monsters_per_room,
-       max_items_per_room=max_items_per_room,
-       engine=engine,
-   )
-   engine.update_fov()

-   engine.message_log.add_message(
-       "Hello and welcome, adventurer, to yet another dungeon!", color.welcome_text
-   )
+   handler: input_handlers.BaseEventHandler = setup_game.MainMenu()

    with tcod.context.new_terminal(
        screen_width,
        screen_height,
        tileset=tileset,
        title="Yet Another Roguelike Tutorial",
        vsync=True,
    ) as context:
        root_console = tcod.Console(screen_width, screen_height, order="F")
-       while True:
-           root_console.clear()
-           engine.event_handler.on_render(console=root_console)
-           context.present(root_console)

-           try:
-               for event in tcod.event.wait():
-                   context.convert_event(event)
-                   engine.event_handler.handle_events(event)
-           except Exception:  # Handle exceptions in game.
-               traceback.print_exc()  # Print error to stderr.
-               # Then print the error to the message log.
-               engine.message_log.add_message(traceback.format_exc(), color.error)
+       try:
+           while True:
+               root_console.clear()
+               handler.on_render(console=root_console)
+               context.present(root_console)

+               try:
+                   for event in tcod.event.wait():
+                       context.convert_event(event)
+                       handler = handler.handle_events(event)
+               except Exception:  # Handle exceptions in game.
+                   traceback.print_exc()  # Print error to stderr.
+                   # Then print the error to the message log.
+                   if isinstance(handler, input_handlers.EventHandler):
+                       handler.engine.message_log.add_message(
+                           traceback.format_exc(), color.error
+                       )
+       except exceptions.QuitWithoutSaving:
+           raise
+       except SystemExit:  # Save and quit.
+           save_game(handler, "savegame.sav")
+           raise
+       except BaseException:  # Save on any other unexpected exception.
+           save_game(handler, "savegame.sav")
+           raise


if __name__ == "__main__":
    main()
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>#!/usr/bin/env python3
<span class="crossed-out-text">import copy</span>
import traceback
 
import tcod
 
import color
<span class="crossed-out-text">from engine import Engine</span>
<span class="crossed-out-text">import entity_factories</span>
<span class="crossed-out-text">from procgen import generate_dungeon</span>
<span class="new-text">import exceptions
import setup_game
import input_handlers</span>


<span class="new-text">def save_game(handler: input_handlers.BaseEventHandler, filename: str) -> None:
    """If the current event handler has an active Engine then save it."""
    if isinstance(handler, input_handlers.EventHandler):
        handler.engine.save_as(filename)
        print("Game saved.")</span>
 
 
def main() -> None:
    screen_width = 80
    screen_height = 50
 
    <span class="crossed-out-text">map_width = 80</span>
    <span class="crossed-out-text">map_height = 43</span>

    <span class="crossed-out-text">room_max_size = 10</span>
    <span class="crossed-out-text">room_min_size = 6</span>
    <span class="crossed-out-text">max_rooms = 30</span>

    <span class="crossed-out-text">max_monsters_per_room = 2</span>
    <span class="crossed-out-text">max_items_per_room = 2</span>

    tileset = tcod.tileset.load_tilesheet(
        "dejavu10x10_gs_tc.png", 32, 8, tcod.tileset.CHARMAP_TCOD
    )

    <span class="crossed-out-text">player = copy.deepcopy(entity_factories.player)</span>

    <span class="crossed-out-text">engine = Engine(player=player)</span>

    <span class="crossed-out-text">engine.game_map = generate_dungeon(</span>
        <span class="crossed-out-text">max_rooms=max_rooms,</span>
        <span class="crossed-out-text">room_min_size=room_min_size,</span>
        <span class="crossed-out-text">room_max_size=room_max_size,</span>
        <span class="crossed-out-text">map_width=map_width,</span>
        <span class="crossed-out-text">map_height=map_height,</span>
        <span class="crossed-out-text">max_monsters_per_room=max_monsters_per_room,</span>
        <span class="crossed-out-text">max_items_per_room=max_items_per_room,</span>
        <span class="crossed-out-text">engine=engine,</span>
    <span class="crossed-out-text">)</span>
    <span class="crossed-out-text">engine.update_fov()</span>

    <span class="crossed-out-text">engine.message_log.add_message(</span>
        <span class="crossed-out-text">"Hello and welcome, adventurer, to yet another dungeon!", color.welcome_text</span>
    <span class="crossed-out-text">)</span>
    <span class="new-text">handler: input_handlers.BaseEventHandler = setup_game.MainMenu()</span>

    with tcod.context.new_terminal(
        screen_width,
        screen_height,
        tileset=tileset,
        title="Yet Another Roguelike Tutorial",
        vsync=True,
    ) as context:
        root_console = tcod.Console(screen_width, screen_height, order="F")
        <span class="crossed-out-text">while True:</span>
            <span class="crossed-out-text">root_console.clear()</span>
            <span class="crossed-out-text">engine.event_handler.on_render(console=root_console)</span>
            <span class="crossed-out-text">context.present(root_console)</span>

            <span class="crossed-out-text">try:</span>
                <span class="crossed-out-text">for event in tcod.event.wait():</span>
                    <span class="crossed-out-text">context.convert_event(event)</span>
                    <span class="crossed-out-text">engine.event_handler.handle_events(event)</span>
            <span class="crossed-out-text">except Exception:  # Handle exceptions in game.</span>
                <span class="crossed-out-text">traceback.print_exc()  # Print error to stderr.</span>
                <span class="crossed-out-text"># Then print the error to the message log.</span>
                <span class="crossed-out-text">engine.message_log.add_message(traceback.format_exc(), color.error)</span>
        <span class="new-text">try:
            while True:
                root_console.clear()
                handler.on_render(console=root_console)
                context.present(root_console)

                try:
                    for event in tcod.event.wait():
                        context.convert_event(event)
                        handler = handler.handle_events(event)
                except Exception:  # Handle exceptions in game.
                    traceback.print_exc()  # Print error to stderr.
                    # Then print the error to the message log.
                    if isinstance(handler, input_handlers.EventHandler):
                        handler.engine.message_log.add_message(
                            traceback.format_exc(), color.error
                        )
        except exceptions.QuitWithoutSaving:
            raise
        except SystemExit:  # Save and quit.
            save_game(handler, "savegame.sav")
            raise
        except BaseException:  # Save on any other unexpected exception.
            save_game(handler, "savegame.sav")
            raise</span>
 
 
if __name__ == "__main__":
    main()</pre>
{{</ original-tab >}}
{{</ codetab >}}



{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from typing import TYPE_CHECKING
 
import color
from components.base_component import BaseComponent
-from input_handlers import GameOverEventHandler
from render_order import RenderOrder
 
...

        ...
        if self.engine.player is self.parent:
            death_message = "You died!"
            death_message_color = color.player_die
-           self.engine.event_handler = GameOverEventHandler(self.engine)
        else:
            death_message = f"{self.parent.name} is dead!"
            death_message_color = color.enemy_die
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from typing import TYPE_CHECKING
 
import color
from components.base_component import BaseComponent
<span class="crossed-out-text">from input_handlers import GameOverEventHandler</span>
from render_order import RenderOrder
 
...

        ...
        if self.engine.player is self.parent:
            death_message = "You died!"
            death_message_color = color.player_die
            <span class="crossed-out-text">self.engine.event_handler = GameOverEventHandler(self.engine)</span>
        else:
            death_message = f"{self.parent.name} is dead!"
            death_message_color = color.enemy_die
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}


TODO: Finish the tutorial.