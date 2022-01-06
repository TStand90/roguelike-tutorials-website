---
title: "Part 7 - Creating the Interface"
date: 2020-07-07
draft: false
---

Our game is looking more and more playable by the chapter, but before we move forward with the gameplay, we ought to take a moment to focus on how the project *looks*. Despite what some roguelike traditionalists may tell you, a good UI goes a long way.

One of the first things we can do is define a file that will hold our RGB colors. We've just been hard-coding them up until now, but it would be nice if they were all in one place and then imported when needed, so that we could easily update them if need be.

Create a new file, called `color.py`, and fill it with the following:

```py3
white = (0xFF, 0xFF, 0xFF)
black = (0x0, 0x0, 0x0)

player_atk = (0xE0, 0xE0, 0xE0)
enemy_atk = (0xFF, 0xC0, 0xC0)

player_die = (0xFF, 0x30, 0x30)
enemy_die = (0xFF, 0xA0, 0x30)

welcome_text = (0x20, 0xA0, 0xFF)

bar_text = white
bar_filled = (0x0, 0x60, 0x0)
bar_empty = (0x40, 0x10, 0x10)
```

Some of these colors, like `welcome_text` and `bar_filled` are things we haven't added yet, but don't worry, we'll utilize them by the end of the chapter.

Last chapter, we implemented a basic HP tracker for the player, with the promise that we'd revisit in this chapter to make it look better. And now, the time has come!

We'll create a bar that will gradually decrease as the player loses HP. This will help the player visualize how much HP is remaining. To do this, we'll create a generic `render_bar` function, which can accept different values and change the bar's length based on the `current_value` and `maximum_value` we give to it.

To house this new function (as well as some other functions that are coming soon), let's create a new file, called `render_functions.py`. Put the following into it:

```py3
from __future__ import annotations

from typing import TYPE_CHECKING

import color

if TYPE_CHECKING:
    from tcod import Console


def render_bar(
    console: Console, current_value: int, maximum_value: int, total_width: int
) -> None:
    bar_width = int(float(current_value) / maximum_value * total_width)

    console.draw_rect(x=0, y=45, width=total_width, height=1, ch=1, bg=color.bar_empty)

    if bar_width > 0:
        console.draw_rect(
            x=0, y=45, width=bar_width, height=1, ch=1, bg=color.bar_filled
        )

    console.print(
        x=1, y=45, string=f"HP: {current_value}/{maximum_value}", fg=color.bar_text
    )
```

We're utilizing the `draw_rect` functions provided by TCOD to draw rectangular bars. We're actually drawing two bars, one on top of the other. The first one will be the background color, which in the case of our health bar, will be a red color. The second goes on top, and is green. The one on top will gradually decrease as the player drops hit points, as its width is determined by the `bar_width` variable, which is itself determined by the `current_value` over the `maximum_value`.

We also print the "HP" value over the bar, so the player knows the exact number.

In order to utilize this new function, make the following changes to `engine.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
...
from input_handlers import MainGameEventHandler
+from render_functions import render_bar

if TYPE_CHECKING:
    ...

    ...
    def render(self, console: Console, context: Context) -> None:
        self.game_map.render(console)

+       render_bar(
+           console=console,
+           current_value=self.player.fighter.hp,
+           maximum_value=self.player.fighter.max_hp,
+           total_width=20,
+       )
-       console.print(
-           x=1,
-           y=47,
-           string=f"HP: {self.player.fighter.hp}/{self.player.fighter.max_hp}",
-       )

        context.present(console)

        console.clear()
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>...
from input_handlers import MainGameEventHandler
<span class="new-text">from render_functions import render_bar</span>

if TYPE_CHECKING:
    ...

    ...
    def render(self, console: Console, context: Context) -> None:
        self.game_map.render(console)

        <span class="new-text">render_bar(
            console=console,
            current_value=self.player.fighter.hp,
            maximum_value=self.player.fighter.max_hp,
            total_width=20,
        )</span>
        <span class="crossed-out-text">console.print(</span>
            <span class="crossed-out-text">x=1,</span>
            <span class="crossed-out-text">y=47,</span>
            <span class="crossed-out-text">string=f"HP: {self.player.fighter.hp}/{self.player.fighter.max_hp}",</span>
        <span class="crossed-out-text">)</span>

        context.present(console)

        console.clear()</pre>
{{</ original-tab >}}
{{</ codetab >}}

Run the project now, and you should have a functioning health bar!

![Part 7 - Health bar](/images/part-7-health-bar.png)

What next? One obvious problem with our project at the moment is that the messages get printed to the terminal rather than showing up in the actual game. We can fix that by adding a message log, which can display messages along with different colors for a bit of flash.

Create a new file, called `message_log.py`, and put the following contents inside:

```py3
from typing import List, Reversible, Tuple
import textwrap

import tcod

import color


class Message:
    def __init__(self, text: str, fg: Tuple[int, int, int]):
        self.plain_text = text
        self.fg = fg
        self.count = 1

    @property
    def full_text(self) -> str:
        """The full text of this message, including the count if necessary."""
        if self.count > 1:
            return f"{self.plain_text} (x{self.count})"
        return self.plain_text


class MessageLog:
    def __init__(self) -> None:
        self.messages: List[Message] = []

    def add_message(
        self, text: str, fg: Tuple[int, int, int] = color.white, *, stack: bool = True,
    ) -> None:
        """Add a message to this log.
        `text` is the message text, `fg` is the text color.
        If `stack` is True then the message can stack with a previous message
        of the same text.
        """
        if stack and self.messages and text == self.messages[-1].plain_text:
            self.messages[-1].count += 1
        else:
            self.messages.append(Message(text, fg))

    def render(
        self, console: tcod.Console, x: int, y: int, width: int, height: int,
    ) -> None:
        """Render this log over the given area.
        `x`, `y`, `width`, `height` is the rectangular region to render onto
        the `console`.
        """
        self.render_messages(console, x, y, width, height, self.messages)

    @staticmethod
    def render_messages(
        console: tcod.Console,
        x: int,
        y: int,
        width: int,
        height: int,
        messages: Reversible[Message],
    ) -> None:
        """Render the messages provided.
        The `messages` are rendered starting at the last message and working
        backwards.
        """
        y_offset = height - 1

        for message in reversed(messages):
            for line in reversed(textwrap.wrap(message.full_text, width)):
                console.print(x=x, y=y + y_offset, string=line, fg=message.fg)
                y_offset -= 1
                if y_offset < 0:
                    return  # No more space to print messages.
```

Let's go through the additions piece by piece.

```py3
class Message:
    def __init__(self, text: str, fg: Tuple[int, int, int]):
        self.plain_text = text
        self.fg = fg
        self.count = 1

    @property
    def full_text(self) -> str:
        """The full text of this message, including the count if necessary."""
        if self.count > 1:
            return f"{self.plain_text} (x{self.count})"
        return self.plain_text
```

The `Message` will be used to save and display messages in our log. It includes three pieces of information:

* `plain_text`: The actual message text.
* `fg`: The "foreground" color of the message.
* `count`: This is used to display something like "The Orc attacks (x3)." Rather than crowding our message log with the same message over and over, we can "stack" the messages by increasing a message's count. This only happens when the same message appears several times in a row.

The `full_text` property returns the text with its count, if the count is greater than 1. Otherwise, it just returns the message as-is.

Now, the actual message log:

```py3
class MessageLog:
    def __init__(self) -> None:
        self.messages: List[Message] = []
```

It keeps a list of the `Message`s received. Nothing too complex here.

```py3
    def add_message(
        self, text: str, fg: Tuple[int, int, int] = color.white, *, stack: bool = True,
    ) -> None:
        """Add a message to this log.
        `text` is the message text, `fg` is the text color.
        If `stack` is True then the message can stack with a previous message
        of the same text.
        """
        if stack and self.messages and text == self.messages[-1].plain_text:
            self.messages[-1].count += 1
        else:
            self.messages.append(Message(text, fg))
```

`add_message` is what adds the message to the log. `text` is required, but `fg` will just default to white if nothing is given. `stack` tells us whether to stack messages or not (which allows us to disable this behavior, if desired).

If we are allowing stacking, and the added message matches the previous message, we just increment the previous message's count by 1. If it's not a match, we add it to the list.

```py3
    def render(
        self, console: tcod.Console, x: int, y: int, width: int, height: int,
    ) -> None:
        """Render this log over the given area.
        `x`, `y`, `width`, `height` is the rectangular region to render onto
        the `console`.
        """
        self.render_messages(console, x, y, width, height, self.messages)

    @staticmethod
    def render_messages(
        console: tcod.Console,
        x: int,
        y: int,
        width: int,
        height: int,
        messages: Reversible[Message],
    ) -> None:
        """Render the messages provided.
        The `messages` are rendered starting at the last message and working
        backwards.
        """
        y_offset = height - 1

        for message in reversed(messages):
            for line in reversed(textwrap.wrap(message.full_text, width)):
                console.print(x=x, y=y + y_offset, string=line, fg=message.fg)
                y_offset -= 1
                if y_offset < 0:
                    return  # No more space to print messages.
```

This `render` calls `render_messages`, which is a static method that actually renders the messages to the screen. It renders them in reverse order, to make it appear that the messages are scrolling in an upwards direction. We use the `textwrap.wrap` function to wrap the text to fit within the given area, and then print each line to the console. We can only print so many messages to the console, however, so if `y_offset` reaches -1, we stop.

To utilize the message log, we'll first need to add it to the `Engine` class. Modify `engine.py` like this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
...
from input_handlers import MainGameEventHandler
+from message_log import MessageLog
from render_functions import render_bar

if TYPE_CHECKING:
    from entity import Actor
    from game_map import GameMap
    from input_handlers import EventHandler

class Engine:
    game_map: GameMap

    def __init__(self, player: Actor):
        self.event_handler: EventHandler = MainGameEventHandler(self)
+       self.message_log = MessageLog()
        self.player = player
    ...

    def render(self, console: Console, context: Context) -> None:
        self.game_map.render(console)

+       self.message_log.render(console=console, x=21, y=45, width=40, height=5)

        render_bar(
            ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>...
from input_handlers import MainGameEventHandler
<span class="new-text">from message_log import MessageLog</span>
from render_functions import render_bar

if TYPE_CHECKING:
    from entity import Actor
    from game_map import GameMap
    from input_handlers import EventHandler

class Engine:
    game_map: GameMap

    def __init__(self, player: Actor):
        self.event_handler: EventHandler = MainGameEventHandler(self)
        <span class="new-text">self.message_log = MessageLog()</span>
        self.player = player
    ...

    def render(self, console: Console, context: Context) -> None:
        self.game_map.render(console)

        <span class="new-text">self.message_log.render(console=console, x=21, y=45, width=40, height=5)</span>

        render_bar(
            ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

We're adding an instance of `MessageLog` in the initializer, and rendering the log in the Engine's `render` method. Nothing too complicated here.

We need to make a small change to `main.py` in order to actually make room for our message log. We can also add a friendly welcome message here.

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
#!/usr/bin/env python3
import copy

import tcod

+import color
from engine import Engine
import entity_factories
...

    ...
    map_width = 80
-   map_height = 45
+   map_height = 43

    room_max_size = 10
    ...

    ...
    engine.update_fov()

+   engine.message_log.add_message(
+       "Hello and welcome, adventurer, to yet another dungeon!", color.welcome_text
+   )

    with tcod.context.new_terminal(
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>#!/usr/bin/env python3
import copy

import tcod

<span class="new-text">import color</span>
from engine import Engine
import entity_factories
...

    ...
    map_width = 80
    <span class="crossed-out-text">map_height = 45</span>
    <span class="new-text">map_height = 43</span>

    room_max_size = 10
    ...

    ...
    engine.update_fov()

    <span class="new-text">engine.message_log.add_message(
        "Hello and welcome, adventurer, to yet another dungeon!", color.welcome_text
    )</span>

    with tcod.context.new_terminal(
        ...</pre>


{{</ original-tab >}}
{{</ codetab >}}

Feel free to experiment with different window and map sizes, if you like.

Run the project, and you should see the welcome message.

![Part 7 - Welcome Message](/images/part-7-welcome-message.png)

Now that we've confirmed our message log accepts and displays messages, we'll need to replace all of our previous `print` statements to push messages to the log instead.

Let's start with our attack action, in `actions.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
...
from typing import Optional, Tuple, TYPE_CHECKING

+import color

if TYPE_CHECKING:
    ...

        ...
        damage = self.entity.fighter.power - target.fighter.defense

        attack_desc = f"{self.entity.name.capitalize()} attacks {target.name}"
+       if self.entity is self.engine.player:
+           attack_color = color.player_atk
+       else:
+           attack_color = color.enemy_atk

        if damage > 0:
-           print(f"{attack_desc} for {damage} hit points.")
+           self.engine.message_log.add_message(
+               f"{attack_desc} for {damage} hit points.", attack_color
+           )
            target.fighter.hp -= damage
        else:
-           print(f"{attack_desc} but does no damage.")
+           self.engine.message_log.add_message(
+               f"{attack_desc} but does no damage.", attack_color
+           )
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>...
from typing import Optional, Tuple, TYPE_CHECKING

<span class="new-text">import color</span>

if TYPE_CHECKING:
    ...

        ...
        damage = self.entity.fighter.power - target.fighter.defense

        attack_desc = f"{self.entity.name.capitalize()} attacks {target.name}"
        <span class="new-text">if self.entity is self.engine.player:
            attack_color = color.player_atk
        else:
            attack_color = color.enemy_atk</span>

        if damage > 0:
            <span class="crossed-out-text">print(f"{attack_desc} for {damage} hit points.")</span>
            <span class="new-text">self.engine.message_log.add_message(
                f"{attack_desc} for {damage} hit points.", attack_color
            )</span>
            target.fighter.hp -= damage
        else:
            <span class="crossed-out-text">print(f"{attack_desc} but does no damage.")</span>
            <span class="new-text">self.engine.message_log.add_message(
                f"{attack_desc} but does no damage.", attack_color
            )</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

We determine the color based on who is doing the attacking. Other than that, there's really nothing new here, we're just pushing those messages to the log rather than printing them.

Now we just need to update our death messages. Open up `fighter.py` and modify it like this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from __future__ import annotations

from typing import TYPE_CHECKING

+import color
from components.base_component import BaseComponent
...

    ...
    def die(self) -> None:
        if self.engine.player is self.entity:
            death_message = "You died!"
+           death_message_color = color.player_die
            self.engine.event_handler = GameOverEventHandler(self.engine)
        else:
            death_message = f"{self.entity.name} is dead!"
+           death_message_color = color.enemy_die

        self.entity.char = "%"
        self.entity.color = (191, 0, 0)
        self.entity.blocks_movement = False
        self.entity.ai = None
        self.entity.name = f"remains of {self.entity.name}"
        self.entity.render_order = RenderOrder.CORPSE

-       print(death_message)
+       self.engine.message_log.add_message(death_message, death_message_color)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from __future__ import annotations

from typing import TYPE_CHECKING

<span class="new-text">import color</span>
from components.base_component import BaseComponent
...

    ...
    def die(self) -> None:
        if self.engine.player is self.entity:
            death_message = "You died!"
            <span class="new-text">death_message_color = color.player_die</span>
            self.engine.event_handler = GameOverEventHandler(self.engine)
        else:
            death_message = f"{self.entity.name} is dead!"
            <span class="new-text">death_message_color = color.enemy_die</span>

        self.entity.char = "%"
        self.entity.color = (191, 0, 0)
        self.entity.blocks_movement = False
        self.entity.ai = None
        self.entity.name = f"remains of {self.entity.name}"
        self.entity.render_order = RenderOrder.CORPSE

        <span class="crossed-out-text">print(death_message)</span>
        <span class="new-text">self.engine.message_log.add_message(death_message, death_message_color)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Run the project now. You should see messages for both attacks and deaths!

![Part 7 - Death Messages](/images/part-7-death-messages.png)

What next? One thing that would be nice is to see the names of the different entities. This will become useful later on if you decide to add more enemy types. It's easy enough to remember "Orc" and "Troll", but most roguelikes have a wide variety of enemies, so it's helpful to know what each letter on the screen means.

We can accomplish this by displaying the names of the entities that are currently under the player's mouse. We'll need to make a few changes to our project to capture the mouse's current position, however.

Edit `main.py` like this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
        root_console = tcod.Console(screen_width, screen_height, order="F")
        while True:
+           root_console.clear()
+           engine.event_handler.on_render(console=root_console)
+           context.present(root_console)
-           engine.render(console=root_console, context=context)

+           engine.event_handler.handle_events(context)
-           engine.event_handler.handle_events()
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>        root_console = tcod.Console(screen_width, screen_height, order="F")
        while True:
            <span class="new-text">root_console.clear()
            engine.event_handler.on_render(console=root_console)
            context.present(root_console)</span>
            <span class="crossed-out-text">engine.render(console=root_console, context=context)</span>

            <span class="new-text">engine.event_handler.handle_events(context)</span>
            <span class="crossed-out-text">engine.event_handler.handle_events()</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

We're adding the console's `clear` back to main, as well as the context's `present`. Also, we're calling a method that we haven't defined yet: `on_render`, but don't worry, we'll define it in a moment. Basically, this method tells the engine to render.

We're also passing the `context` to `handle_events` now, because we need to call an extra method on it to capture the mouse input.

Now let's modify `input_handlers.py` to contain the methods we're calling in `main.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class EventHandler(tcod.event.EventDispatch[Action]):
    def __init__(self, engine: Engine):
        self.engine = engine

-   def handle_events(self) -> None:
-       raise NotImplementedError()

+   def handle_events(self, context: tcod.context.Context) -> None:
+       for event in tcod.event.wait():
+           context.convert_event(event)
+           self.dispatch(event)

    def ev_quit(self, event: tcod.event.Quit) -> Optional[Action]:
        raise SystemExit()

+   def on_render(self, console: tcod.Console) -> None:
+       self.engine.render(console)


class MainGameEventHandler(EventHandler):
-   def handle_events(self) -> None:
+   def handle_events(self, context: tcod.context.Context) -> None:
        for event in tcod.event.wait():
+           context.convert_event(event)

            action = self.dispatch(event)
            ...


class GameOverEventHandler(EventHandler):
-   def handle_events(self) -> None:
+   def handle_events(self, context: tcod.context.Context) -> None:
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class EventHandler(tcod.event.EventDispatch[Action]):
    def __init__(self, engine: Engine):
        self.engine = engine

    <span class="crossed-out-text">def handle_events(self) -> None:</span>
        <span class="crossed-out-text">raise NotImplementedError()</span>

    <span class="new-text">def handle_events(self, context: tcod.context.Context) -> None:
        for event in tcod.event.wait():
            context.convert_event(event)
            self.dispatch(event)</span>

    def ev_quit(self, event: tcod.event.Quit) -> Optional[Action]:
        raise SystemExit()

    <span class="new-text">def on_render(self, console: tcod.Console) -> None:
        self.engine.render(console)</span>


class MainGameEventHandler(EventHandler):
    <span class="crossed-out-text">def handle_events(self) -> None:</span>
    <span class="new-text">def handle_events(self, context: tcod.context.Context) -> None:</span>
        for event in tcod.event.wait():
            <span class="new-text">context.convert_event(event)</span>

            action = self.dispatch(event)
            ...


class GameOverEventHandler(EventHandler):
    <span class="crossed-out-text">def handle_events(self) -> None:</span>
    <span class="new-text">def handle_events(self, context: tcod.context.Context) -> None:</span>
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

We're modifying the `handle_events` method in `EventHandler` to actually have an implementation. It iterates through the events, and uses `context.convert_event` to give the event knowledge on the mouse position. It then dispatches that event, to be handled like normal.

`on_render` just tells the `Engine` class to call its render method, using the given console.

`MainGameEventHandler` and `GameOverEventHandler` have small changes to their `handle_events` methods to match the signature of `EventHandler`, and `MainGameEventHandler` also uses `context.convert_event`.

We're no longer passing the `context` to the `Engine` class's `render` method, so let's change the method now:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
...
from typing import TYPE_CHECKING

-from tcod.context import Context
from tcod.console import Console
...

class Engine:
    ...

-   def render(self, console: Console, context: Context) -> None:
+   def render(self, console: Console) -> None:
        self.game_map.render(console)

        self.message_log.render(console=console, x=21, y=45, width=40, height=5)

        render_bar(
            console=console,
            current_value=self.player.fighter.hp,
            maximum_value=self.player.fighter.max_hp,
            total_width=20,
        )

-       context.present(console)

-       console.clear()
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>...
from typing import TYPE_CHECKING

<span class="crossed-out-text">from tcod.context import Context</span>
from tcod.console import Console
...

class Engine:
    ...

    <span class="crossed-out-text">def render(self, console: Console, context: Context) -> None:</span>
    <span class="new-text">def render(self, console: Console) -> None:</span>
        self.game_map.render(console)

        self.message_log.render(console=console, x=21, y=45, width=40, height=5)

        render_bar(
            console=console,
            current_value=self.player.fighter.hp,
            maximum_value=self.player.fighter.max_hp,
            total_width=20,
        )

        <span class="crossed-out-text">context.present(console)</span>

        <span class="crossed-out-text">console.clear()</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

We've also removed the `console.clear` call, as that's being handled by `main.py`.

So we're passing the context around to different classes and converting the events to capture the mouse location. But where does that information actually get stored? Let's add a data point on to the `Engine` class to hold that information. Add the following to `engine.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class Engine:
    game_map: GameMap

    def __init__(self, player: Actor):
        self.event_handler: EventHandler = MainGameEventHandler(self)
        self.message_log = MessageLog()
+       self.mouse_location = (0, 0)
        self.player = player
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class Engine:
    game_map: GameMap

    def __init__(self, player: Actor):
        self.event_handler: EventHandler = MainGameEventHandler(self)
        self.message_log = MessageLog()
        <span class="new-text">self.mouse_location = (0, 0)</span>
        self.player = player</pre>
{{</ original-tab >}}
{{</ codetab >}}

Okay, so we've got a place to store the mouse location, but where do we actually get that information?

There's an easy way: by overriding a method in `EventHandler`, which is called `ev_mousemotion`. By doing that, we can write the mouse location to the engine for access later. Here's how that looks:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class EventHandler(tcod.event.EventDispatch[Action]):
    def __init__(self, engine: Engine):
        self.engine = engine

    def handle_events(self, context: tcod.context.Context) -> None:
        for event in tcod.event.wait():
            context.convert_event(event)
            self.dispatch(event)

+   def ev_mousemotion(self, event: tcod.event.MouseMotion) -> None:
+       if self.engine.game_map.in_bounds(event.tile.x, event.tile.y):
+           self.engine.mouse_location = event.tile.x, event.tile.y

    def ev_quit(self, event: tcod.event.Quit) -> Optional[Action]:
        raise SystemExit()
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class EventHandler(tcod.event.EventDispatch[Action]):
    def __init__(self, engine: Engine):
        self.engine = engine

    def handle_events(self, context: tcod.context.Context) -> None:
        for event in tcod.event.wait():
            context.convert_event(event)
            self.dispatch(event)

    <span class="new-text">def ev_mousemotion(self, event: tcod.event.MouseMotion) -> None:
        if self.engine.game_map.in_bounds(event.tile.x, event.tile.y):
            self.engine.mouse_location = event.tile.x, event.tile.y</span>

    def ev_quit(self, event: tcod.event.Quit) -> Optional[Action]:
        raise SystemExit()</pre>
{{</ original-tab >}}
{{</ codetab >}}

Great! Now we're saving the mouse's location, so it's time to actually make use of it. Our original goal was to display the entity names that are in the mouse's current position. The hard part is already done, now all we need to do is check which entities are in the given location, get their names, and print them out to the screen.

Since this has to do with rendering, let's put these new functions in `render_functions.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from __future__ import annotations

from typing import TYPE_CHECKING

import color

if TYPE_CHECKING:
    from tcod import Console
+   from engine import Engine
+   from game_map import GameMap


+def get_names_at_location(x: int, y: int, game_map: GameMap) -> str:
+   if not game_map.in_bounds(x, y) or not game_map.visible[x, y]:
+       return ""

+   names = ", ".join(
+       entity.name for entity in game_map.entities if entity.x == x and entity.y == y
+   )

+   return names.capitalize()


def render_bar(
    console: Console, current_value: int, maximum_value: int, total_width: int
) -> None:
    bar_width = int(float(current_value) / maximum_value * total_width)

    console.draw_rect(x=0, y=45, width=20, height=1, ch=1, bg=color.bar_empty)

    if bar_width > 0:
        console.draw_rect(
            x=0, y=45, width=bar_width, height=1, ch=1, bg=color.bar_filled
        )

    console.print(
        x=1, y=45, string=f"HP: {current_value}/{maximum_value}", fg=color.bar_text
    )


+def render_names_at_mouse_location(
+   console: Console, x: int, y: int, engine: Engine
+) -> None:
+   mouse_x, mouse_y = engine.mouse_location

+   names_at_mouse_location = get_names_at_location(
+       x=mouse_x, y=mouse_y, game_map=engine.game_map
+   )

+   console.print(x=x, y=y, string=names_at_mouse_location)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from __future__ import annotations

from typing import TYPE_CHECKING

import color

if TYPE_CHECKING:
    from tcod import Console
    <span class="new-text">from engine import Engine
    from game_map import GameMap


def get_names_at_location(x: int, y: int, game_map: GameMap) -> str:
    if not game_map.in_bounds(x, y) or not game_map.visible[x, y]:
        return ""

    names = ", ".join(
        entity.name for entity in game_map.entities if entity.x == x and entity.y == y
    )

    return names.capitalize()</span>


def render_bar(
    console: Console, current_value: int, maximum_value: int, total_width: int
) -> None:
    bar_width = int(float(current_value) / maximum_value * total_width)

    console.draw_rect(x=0, y=45, width=20, height=1, ch=1, bg=color.bar_empty)

    if bar_width > 0:
        console.draw_rect(
            x=0, y=45, width=bar_width, height=1, ch=1, bg=color.bar_filled
        )

    console.print(
        x=1, y=45, string=f"HP: {current_value}/{maximum_value}", fg=color.bar_text
    )


<span class="new-text">def render_names_at_mouse_location(
    console: Console, x: int, y: int, engine: Engine
) -> None:
    mouse_x, mouse_y = engine.mouse_location

    names_at_mouse_location = get_names_at_location(
        x=mouse_x, y=mouse_y, game_map=engine.game_map
    )

    console.print(x=x, y=y, string=names_at_mouse_location)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

We've added two new functions, `render_names_at_mouse_location` and `get_names_at_location`. Let's discuss what each one does.

`render_names_at_mouse_location` takes the console, x and y coordinates (the location to draw the names), and the engine. From the engine, it grabs the mouse's current x and y positions, and passes them to `get_names_at_location`, which we can assume for the moment will return the list of entity names we want. Once we have these entity names as a string, we can print that string to the given x and y location on the screen, with `console.print`.

`get_names_at_location` also takes "x" and "y" variables, though these represent a spot on the map. We first check that the x and y coordinates are within the map, and are currently visible to the player. If they are, then we create a string of the entity names at that spot, separated by a comma. We then return that string, adding `capitalize` to make sure the first letter in the string is capitalized.

Now all we need to do is modify `engine.py` to import these functions and utilize them in the `render` method. Make the following modifications:
{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
...
from message_log import MessageLog
-from render_functions import render_bar
+from render_functions import render_bar, render_names_at_mouse_location

if TYPE_CHECKING:
    ...

    ...
    def render(self, console: Console) -> None:
        self.game_map.render(console)

        self.message_log.render(console=console, x=21, y=45, width=40, height=5)

        render_bar(
            console=console,
            current_value=self.player.fighter.hp,
            maximum_value=self.player.fighter.max_hp,
            total_width=20,
        )

+       render_names_at_mouse_location(console=console, x=21, y=44, engine=self)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>...
from message_log import MessageLog
<span class="crossed-out-text">from render_functions import render_bar</span>
<span class="new-text">from render_functions import render_bar, render_names_at_mouse_location</span>

if TYPE_CHECKING:
    ...

    ...
    def render(self, console: Console) -> None:
        self.game_map.render(console)

        self.message_log.render(console=console, x=21, y=45, width=40, height=5)

        render_bar(
            console=console,
            current_value=self.player.fighter.hp,
            maximum_value=self.player.fighter.max_hp,
            total_width=20,
        )

        <span class="new-text">render_names_at_mouse_location(console=console, x=21, y=44, engine=self)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Now if you hover your mouse over an entity, you'll see its name. If you stack a few corpses up, you'll notice that it prints a list of the names.

We're almost finished with this chapter. Before we wrap up, let's revisit our message log for a moment. One issue with it is that we can't see messages that are too far back. However, HexDecimal was kind enough to provide a method for viewing the whole log, with the ability to scroll.

Add the following to `input_handlers.py`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
class GameOverEventHandler(EventHandler):
    ...


+CURSOR_Y_KEYS = {
+   tcod.event.K_UP: -1,
+   tcod.event.K_DOWN: 1,
+   tcod.event.K_PAGEUP: -10,
+   tcod.event.K_PAGEDOWN: 10,
+}


+class HistoryViewer(EventHandler):
+   """Print the history on a larger window which can be navigated."""

+   def __init__(self, engine: Engine):
+       super().__init__(engine)
+       self.log_length = len(engine.message_log.messages)
+       self.cursor = self.log_length - 1

+   def on_render(self, console: tcod.Console) -> None:
+       super().on_render(console)  # Draw the main state as the background.

+       log_console = tcod.Console(console.width - 6, console.height - 6)

+       # Draw a frame with a custom banner title.
+       log_console.draw_frame(0, 0, log_console.width, log_console.height)
+       log_console.print_box(
+           0, 0, log_console.width, 1, "┤Message history├", alignment=tcod.CENTER
+       )

+       # Render the message log using the cursor parameter.
+       self.engine.message_log.render_messages(
+           log_console,
+           1,
+           1,
+           log_console.width - 2,
+           log_console.height - 2,
+           self.engine.message_log.messages[: self.cursor + 1],
+       )
+       log_console.blit(console, 3, 3)

+   def ev_keydown(self, event: tcod.event.KeyDown) -> None:
+       # Fancy conditional movement to make it feel right.
+       if event.sym in CURSOR_Y_KEYS:
+           adjust = CURSOR_Y_KEYS[event.sym]
+           if adjust < 0 and self.cursor == 0:
+               # Only move from the top to the bottom when you're on the edge.
+               self.cursor = self.log_length - 1
+           elif adjust > 0 and self.cursor == self.log_length - 1:
+               # Same with bottom to top movement.
+               self.cursor = 0
+           else:
+               # Otherwise move while staying clamped to the bounds of the history log.
+               self.cursor = max(0, min(self.cursor + adjust, self.log_length - 1))
+       elif event.sym == tcod.event.K_HOME:
+           self.cursor = 0  # Move directly to the top message.
+       elif event.sym == tcod.event.K_END:
+           self.cursor = self.log_length - 1  # Move directly to the last message.
+       else:  # Any other key moves back to the main game state.
+           self.engine.event_handler = MainGameEventHandler(self.engine)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>class GameOverEventHandler(EventHandler):
    ...


<span class="new-text">CURSOR_Y_KEYS = {
    tcod.event.K_UP: -1,
    tcod.event.K_DOWN: 1,
    tcod.event.K_PAGEUP: -10,
    tcod.event.K_PAGEDOWN: 10,
}


class HistoryViewer(EventHandler):
    """Print the history on a larger window which can be navigated."""

    def __init__(self, engine: Engine):
        super().__init__(engine)
        self.log_length = len(engine.message_log.messages)
        self.cursor = self.log_length - 1

    def on_render(self, console: tcod.Console) -> None:
        super().on_render(console)  # Draw the main state as the background.

        log_console = tcod.Console(console.width - 6, console.height - 6)

        # Draw a frame with a custom banner title.
        log_console.draw_frame(0, 0, log_console.width, log_console.height)
        log_console.print_box(
            0, 0, log_console.width, 1, "┤Message history├", alignment=tcod.CENTER
        )

        # Render the message log using the cursor parameter.
        self.engine.message_log.render_messages(
            log_console,
            1,
            1,
            log_console.width - 2,
            log_console.height - 2,
            self.engine.message_log.messages[: self.cursor + 1],
        )
        log_console.blit(console, 3, 3)

    def ev_keydown(self, event: tcod.event.KeyDown) -> None:
        # Fancy conditional movement to make it feel right.
        if event.sym in CURSOR_Y_KEYS:
            adjust = CURSOR_Y_KEYS[event.sym]
            if adjust < 0 and self.cursor == 0:
                # Only move from the top to the bottom when you're on the edge.
                self.cursor = self.log_length - 1
            elif adjust > 0 and self.cursor == self.log_length - 1:
                # Same with bottom to top movement.
                self.cursor = 0
            else:
                # Otherwise move while staying clamped to the bounds of the history log.
                self.cursor = max(0, min(self.cursor + adjust, self.log_length - 1))
        elif event.sym == tcod.event.K_HOME:
            self.cursor = 0  # Move directly to the top message.
        elif event.sym == tcod.event.K_END:
            self.cursor = self.log_length - 1  # Move directly to the last message.
        else:  # Any other key moves back to the main game state.
            self.engine.event_handler = MainGameEventHandler(self.engine)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

To show this new view, all we need to do is this, in `MainGameEventHandler`:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
        ...
        elif key == tcod.event.K_ESCAPE:
            action = EscapeAction(player)
+       elif key == tcod.event.K_v:
+           self.engine.event_handler = HistoryViewer(self.engine)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>        ...
        elif key == tcod.event.K_ESCAPE:
            action = EscapeAction(player)
        <span class="new-text">elif key == tcod.event.K_v:
            self.engine.event_handler = HistoryViewer(self.engine)</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

Now all the player has to do is press the "v" key to see a log of all past messages. By using the up and down keys, you can scroll through the log.

If you want to see the code so far in its entirety, [click here](https://github.com/TStand90/tcod_tutorial_v2/tree/2020/part-7).

[Click here to move on to the next part of this tutorial.](/tutorials/tcod/v2/part-8)
