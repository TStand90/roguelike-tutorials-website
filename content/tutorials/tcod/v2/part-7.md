---
title: "Part 7 - Creating the Interface"
date: 2020-06-15T10:20:25-07:00
draft: true
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
bar_filled = (0x0, 0xB0, 0x0)
bar_empty = (0x90, 0x10, 0x10)
```

Some of these colors, like `welcome_text` and `bar_filled` are things we haven't added yet, but don't worry, we'll utilize them by the end of the chapter.

Last chapter, we implemented a basic HP tracker for the player, with the promise that we'd revisit in this chapter to make it look better. And now, the time has come!

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

    console.draw_rect(x=0, y=45, width=20, height=1, ch=1, bg=color.bar_empty)

    if bar_width > 0:
        console.draw_rect(
            x=0, y=45, width=bar_width, height=1, ch=1, bg=color.bar_filled
        )

    console.print(
        x=1, y=45, string=f"HP: {current_value}/{maximum_value}", fg=color.bar_text
    )
```


{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
...
from entity import Actor
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
+           total_width=20
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
from entity import Actor
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
            total_width=20
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