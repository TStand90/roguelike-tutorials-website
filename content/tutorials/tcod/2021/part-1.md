---
title: "Part 1 - Drawing the '@' symbol and moving it around"
draft: false
---

Welcome to part 1 of this tutorial! This series will help you create your very first roguelike game, written in Python\!

The 2021 tutorial is largely based off [the 2020 tutorial](/tutorials/tcod/v2), and is primarily a smaller update rather than a larger rewrite that the previous versions were.

This part assumes that you have either checked [Part 0](../part-0) or are already familiar with Python and Python-tcod.
If not, be sure to check that page, and make sure that you've got Python and TCOD installed, as well as having an IDE or editor ready.

Assuming that you've done all that, let's get started.


We will start by setting up the following directory structure.
The font from [Part 0](../part-0) will go into a `data` directory, then a `game` package will be created with some Python modules, then finally `main.py` will be created as an entry point.

```
/data/dejavu16x16_gs_tc.png
/game/__init__.py
/game/actions.py
/game/input_handlers.py
/main.py
```

`/game/__init__.py` will be a blank file as it's only needed to [define a Python package](https://docs.python.org/3/tutorial/modules.html#packages).

```python
# game/__init__.py
```

`/game/actions.py` is based loosely on [Bob Nystrom's "Is There More to Game Architecture than ECS?"](https://www.youtube.com/watch?v=JxI3Eu5DPwE).

```python
# game/actions.py
from __future__ import annotations


class Action:
    pass


class Move(Action):
    def __init__(self, dx: int, dy: int):
        super().__init__()

        self.dx = dx
        self.dy = dy
```

This has the base class `Action` and the real action `Move` for relative movement, the `Move` class holds the direction of movement.
Since this is in a module in a package the fully qualified name for `Move` is `game.actions.Move`, so it won't be necessary to add the word `Action` to any sub-classes of `Action`.

`from __future__ import annotations` tells Python to do [Postponed Evaluation of Annotations](https://www.python.org/dev/peps/pep-0563/), this helps reduce issues from modules referencing each other which can happen often whenever type-hinting is being used.
This will be added to the beginning of most new modules.

`/game/input_handlers.py`

```python
# game/input_handlers.py
from __future__ import annotations

from typing import Optional

import tcod

import game.actions

MOVE_KEYS = {
    # Arrow keys.
    tcod.event.K_UP: (0, -1),
    tcod.event.K_DOWN: (0, 1),
    tcod.event.K_LEFT: (-1, 0),
    tcod.event.K_RIGHT: (1, 0),
    tcod.event.K_HOME: (-1, -1),
    tcod.event.K_END: (-1, 1),
    tcod.event.K_PAGEUP: (1, -1),
    tcod.event.K_PAGEDOWN: (1, 1),
    # Numpad keys.
    tcod.event.K_KP_1: (-1, 1),
    tcod.event.K_KP_2: (0, 1),
    tcod.event.K_KP_3: (1, 1),
    tcod.event.K_KP_4: (-1, 0),
    tcod.event.K_KP_6: (1, 0),
    tcod.event.K_KP_7: (-1, -1),
    tcod.event.K_KP_8: (0, -1),
    tcod.event.K_KP_9: (1, -1),
    # Vi keys.
    tcod.event.K_h: (-1, 0),
    tcod.event.K_j: (0, 1),
    tcod.event.K_k: (0, -1),
    tcod.event.K_l: (1, 0),
    tcod.event.K_y: (-1, -1),
    tcod.event.K_u: (1, -1),
    tcod.event.K_b: (-1, 1),
    tcod.event.K_n: (1, 1),
}


class EventHandler(tcod.event.EventDispatch[game.actions.Action]):
    def ev_quit(self, event: tcod.event.Quit) -> Optional[game.actions.Action]:
        raise SystemExit(0)

    def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[game.actions.Action]:
        key = event.sym

        if key in MOVE_KEYS:
            dx, dy = MOVE_KEYS[key]
            return game.actions.Move(dx=dx, dy=dy)
        elif key == tcod.event.K_ESCAPE:
            raise SystemExit(0)

        return None
```

[Optional](https://docs.python.org/3/library/typing.html#typing.Optional) is imported from the typing module.
`tcod` and `game.actions` is also used in this module so they are imported as well.

`MOVE_KEYS` can be simplified if you don't need diagonal movement:

```python
MOVE_KEYS = {
    tcod.event.K_UP: (0, -1),
    tcod.event.K_DOWN: (0, 1),
    tcod.event.K_LEFT: (-1, 0),
    tcod.event.K_RIGHT: (1, 0),
}
```

The `EventHandler` class inherits from [tcod.event.EventDispatch](https://python-tcod.readthedocs.io/en/latest/tcod/event.html#tcod.event.EventDispatch), the generic type is filled with `game.actions.Action` which means the event methods can return that type and that the caller of the [dispatch](https://python-tcod.readthedocs.io/en/latest/tcod/event.html#tcod.event.EventDispatch.dispatch) method can receive that type.

Trying to close the window will trigger a call to `ev_quit`.
This will raise [SystemExit](https://docs.python.org/3/library/exceptions.html#SystemExit) which will propagate and terminate the script.

When a key is pressed then `ev_keydown` is triggered.
This will check if that key is one of the keys in `MOVE_KEYS`, if it is then `game.actions.Move` is returned with the values of `MOVE_KEYS[event.sym]`.
Any unexpected key will return `None` instead.


`/main.py` is the entry point of the program.  You can use `python main.py` to start the program after the following is implemented.

```python
#!/usr/bin/env python3
# main.py
import tcod

import game.actions
import game.input_handlers


def main() -> None:
    screen_width = 80
    screen_height = 50

    player_x: int = screen_width // 2
    player_y: int = screen_height // 2

    tileset = tcod.tileset.load_tilesheet("data/dejavu16x16_gs_tc.png", 32, 8, tcod.tileset.CHARMAP_TCOD)

    event_handler = game.input_handlers.EventHandler()

    with tcod.context.new(
        columns=screen_width,
        rows=screen_height,
        tileset=tileset,
        title="Yet Another Roguelike Tutorial",
        vsync=True,
    ) as context:
        root_console = tcod.Console(screen_width, screen_height, order="F")
        while True:
            root_console.print(x=player_x, y=player_y, string="@")

            context.present(root_console)

            root_console.clear()

            for event in tcod.event.wait():
                action = event_handler.dispatch(event)

                if isinstance(action, game.actions.Move):
                    new_x = player_x + action.dx
                    new_y = player_y + action.dy
                    if 0 <= new_x < screen_width and 0 <= new_y < screen_height:
                        player_x, player_y = new_x, new_y


if __name__ == "__main__":
    main()
```

`#!/usr/bin/env python3` is a [shebang](https://en.wikipedia.org/wiki/Shebang_(Unix)) and must be the first line to be useful.
It's normally used to make scripts executable on Linux, but is sometimes used by Python launchers on other platforms as well.

`tcod` is imported along with the two other modules we've added.

The `main` function will be the entry point of the program.
There's nothing special about the name other than the terminology, the special nature of this function comes from the `__name__ == "__main__"` condition at the bottom of the script which is only True when the script is directly run, compared to importing main from an interactive prompt.

`main` starts by setting the screen size, then sets the player position to the center of the screen.
The floor division operator is used so that the numbers don't promote to a float type.

The tileset is loaded with [tcod.tileset.load_tilesheet](https://python-tcod.readthedocs.io/en/latest/tcod/tileset.html#tcod.tileset.load_tilesheet)
The Python-tcod docs have a [character reference](https://python-tcod.readthedocs.io/en/latest/tcod/charmap-reference.html) to keep track of which layouts have what glyphs.

The `event_handler` is now initialized.

[tcod.context.new](https://python-tcod.readthedocs.io/en/latest/tcod/context.html#tcod.context.new) is used to setup the window and returns a [Context](https://python-tcod.readthedocs.io/en/latest/tcod/context.html#tcod.context.Context) instance.
Contexts must be closed once you're done with them, but the `with` statement will do this automatically when exiting the with-block.

Then a [tcod.Console](https://python-tcod.readthedocs.io/en/latest/tcod/console.html#tcod.console.Console) is created with the same size that was given to `tcod.context.new`,
`order="F"` sets the console arrays to be indexed in `x, y` order.
These arrays are not being used yet.

Now with `while True:` the game-loop begins, with the only way of existing this loop normally being the `SystemExit` exceptions implemented earlier.
The player position is printed to `root_console`, then `root_console` is displayed using `context.present(root_console)`, after that the `root_console` is cleared for the next frame.

The for-loop waits for there to be events then iterates over all events until none are left.
This is an efficient way to handle events when the game doesn't have real-time animations or mechanics.
If you have real-time effects then you should replace [tcod.event.wait](https://python-tcod.readthedocs.io/en/latest/tcod/event.html#tcod.event.wait) with [tcod.event.get](https://python-tcod.readthedocs.io/en/latest/tcod/event.html#tcod.event.get).

Events are sent to the `EventHandler` class and the action to be performed is returned.
This could be `None` or any `Action`.
`isinstance(action, game.actions.Move)` tests if `action` is an instance of `Move`.
This affects type checking which can now assume that `action` is that type within the if-branch.
It can then unpack its values and checks if the destination is in the bounds of the screen before setting the player position.

You can see the current progress of this code in its entirety [here](https://github.com/TStand90/tcod_tutorial_v2/tree/2021/part-1).

Part-2 isn't available yet, [but you can setup distribution in the meantime](../extras/distribution).
