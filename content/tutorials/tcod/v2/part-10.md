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

Another thing we'll need is a new type of exception. This will be used when we want to quit the game, but not save it. Normally, we'll save the game when the user quits, but if the game is over (because the player is dead), we don't want to create a save file.

We can put this exception in `exceptions.py`:

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

`input_handlers.py`

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
from __future__ import annotations
 
+import os

-from typing import Callable, Optional, Tuple, TYPE_CHECKING
+from typing import Callable, Optional, Tuple, TYPE_CHECKING, Union
 
import tcod
...

... 
CONFIRM_KEYS = {
    tcod.event.K_RETURN,
    tcod.event.K_KP_ENTER,
}


+ActionOrHandler = Union[Action, "BaseEventHandler"]
+"""An event handler return value which can trigger an action or switch active handlers.

+If a handler is returned then it will become the active handler for future events.
+If an action is returned it will be attempted and if it's valid then
+MainGameEventHandler will become the active handler.
+"""


+class BaseEventHandler(tcod.event.EventDispatch[ActionOrHandler]):
+   def handle_events(self, event: tcod.event.Event) -> BaseEventHandler:
+       """Handle an event and return the next active event handler."""
+       state = self.dispatch(event)
+       if isinstance(state, BaseEventHandler):
+           return state
+       assert not isinstance(state, Action), f"{self!r} can not handle actions."
+       return self

+   def on_render(self, console: tcod.Console) -> None:
+       raise NotImplementedError()

+   def ev_quit(self, event: tcod.event.Quit) -> Optional[Action]:
+       raise SystemExit()


+class PopupMessage(BaseEventHandler):
+   """Display a popup text window."""

+   def __init__(self, parent_handler: BaseEventHandler, text: str):
+       self.parent = parent_handler
+       self.text = text

+   def on_render(self, console: tcod.Console) -> None:
+       """Render the parent and dim the result, then print the message on top."""
+       self.parent.on_render(console)
+       console.tiles_rgb["fg"] //= 8
+       console.tiles_rgb["bg"] //= 8

+       console.print(
+           console.width // 2,
+           console.height // 2,
+           self.text,
+           fg=color.white,
+           bg=color.black,
+           alignment=tcod.CENTER,
+       )

+   def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[BaseEventHandler]:
+       """Any key returns to the parent handler."""
+       return self.parent
 
-class EventHandler(tcod.event.EventDispatch[Action]):
+class EventHandler(BaseEventHandler):
    def __init__(self, engine: Engine):
        self.engine = engine
 
-   def handle_events(self, event: tcod.event.Event) -> None:
-       self.handle_action(self.dispatch(event))
+   def handle_events(self, event: tcod.event.Event) -> BaseEventHandler:
+       """Handle events for input handlers with an engine."""
+       action_or_state = self.dispatch(event)
+       if isinstance(action_or_state, BaseEventHandler):
+           return action_or_state
+       if self.handle_action(action_or_state):
+           # A valid action was performed.
+           if not self.engine.player.is_alive:
+               # The player was killed sometime during or after the action.
+               return GameOverEventHandler(self.engine)
+           return MainGameEventHandler(self.engine)  # Return to the main handler.
+       return self

    def handle_action(self, action: Optional[Action]) -> bool:
        ...
 
-   def ev_quit(self, event: tcod.event.Quit) -> Optional[Action]:
-       raise SystemExit()

    def on_render(self, console: tcod.Console) -> None:
        self.engine.render(console)
 

class AskUserEventHandler(EventHandler):
    """Handles user input for actions which require special input."""
 
-   def handle_action(self, action: Optional[Action]) -> bool:
-       """Return to the main event handler when a valid action was performed."""
-       if super().handle_action(action):
-           self.engine.event_handler = MainGameEventHandler(self.engine)
-           return True
-       return False

-   def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[Action]:
+   def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[ActionOrHandler]:
        """By default any key exits this input handler."""
        if event.sym in {  # Ignore modifier keys.
            tcod.event.K_LSHIFT,
            tcod.event.K_RSHIFT,
            tcod.event.K_LCTRL,
            tcod.event.K_RCTRL,
            tcod.event.K_LALT,
            tcod.event.K_RALT,
        }:
            return None
        return self.on_exit()
 
-   def ev_mousebuttondown(self, event: tcod.event.MouseButtonDown) -> Optional[Action]:
+   def ev_mousebuttondown(
+       self, event: tcod.event.MouseButtonDown
+   ) -> Optional[ActionOrHandler]:
        """By default any mouse click exits this input handler."""
        return self.on_exit()
 
-   def on_exit(self) -> Optional[Action]:
+   def on_exit(self) -> Optional[ActionOrHandler]:
        """Called when the user is trying to exit or cancel an action.
 
        By default this returns to the main event handler.
        """
-       self.engine.event_handler = MainGameEventHandler(self.engine)
-       return None
+       return MainGameEventHandler(self.engine)
 
 
class InventoryEventHandler(AskUserEventHandler):
    ...
 
-   def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[Action]:
+   def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[ActionOrHandler]:
        player = self.engine.player
        key = event.sym
        index = key - tcod.event.K_a

        if 0 <= index <= 26:
            try:
                selected_item = player.inventory.items[index]
            except IndexError:
                self.engine.message_log.add_message("Invalid entry.", color.invalid)
                return None
            return self.on_item_selected(selected_item)
        return super().ev_keydown(event)
 
-   def on_item_selected(self, item: Item) -> Optional[Action]:
+   def on_item_selected(self, item: Item) -> Optional[ActionOrHandler]:
        """Called when the user selects a valid item."""
        raise NotImplementedError()


class InventoryActivateHandler(InventoryEventHandler):
    """Handle using an inventory item."""
 
    TITLE = "Select an item to use"
 
-   def on_item_selected(self, item: Item) -> Optional[Action]:
+   def on_item_selected(self, item: Item) -> Optional[ActionOrHandler]:
        """Return the action for the selected item."""
        return item.consumable.get_action(self.engine.player)
 

class InventoryDropHandler(InventoryEventHandler):
    """Handle dropping an inventory item."""
 
    TITLE = "Select an item to drop"
 
-   def on_item_selected(self, item: Item) -> Optional[Action]:
+   def on_item_selected(self, item: Item) -> Optional[ActionOrHandler]:
        """Drop this item."""
        return actions.DropItem(self.engine.player, item)
 

class SelectIndexHandler(AskUserEventHandler):
    ...
 
-   def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[Action]:
+   def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[ActionOrHandler]:
        ...
 
-   def ev_mousebuttondown(self, event: tcod.event.MouseButtonDown) -> Optional[Action]:
+   def ev_mousebuttondown(
+       self, event: tcod.event.MouseButtonDown
+   ) -> Optional[ActionOrHandler]:
        ...
 
-   def on_index_selected(self, x: int, y: int) -> Optional[Action]:
+   def on_index_selected(self, x: int, y: int) -> Optional[ActionOrHandler]:
        """Called when an index is selected."""
        raise NotImplementedError()
 

class LookHandler(SelectIndexHandler):
    """Lets the player look around using the keyboard."""
 
-   def on_index_selected(self, x: int, y: int) -> None:
+   def on_index_selected(self, x: int, y: int) -> MainGameEventHandler:
        """Return to main handler."""
-       self.engine.event_handler = MainGameEventHandler(self.engine)
+       return MainGameEventHandler(self.engine)

...

class MainGameEventHandler(EventHandler):
-   def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[Action]:
+   def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[ActionOrHandler]:
        action: Optional[Action] = None

        key = event.sym

        player = self.engine.player

        if key in MOVE_KEYS:
            dx, dy = MOVE_KEYS[key]
            action = BumpAction(player, dx, dy)
        elif key in WAIT_KEYS:
            action = WaitAction(player)

        elif key == tcod.event.K_ESCAPE:
            raise SystemExit()
        elif key == tcod.event.K_v:
-           self.engine.event_handler = HistoryViewer(self.engine)
+           return HistoryViewer(self.engine)
 
        elif key == tcod.event.K_g:
            action = PickupAction(player)
 
        elif key == tcod.event.K_i:
-           self.engine.event_handler = InventoryActivateHandler(self.engine)
+           return InventoryActivateHandler(self.engine)
        elif key == tcod.event.K_d:
-           self.engine.event_handler = InventoryDropHandler(self.engine)
+           return InventoryDropHandler(self.engine)
        elif key == tcod.event.K_SLASH:
-           self.engine.event_handler = LookHandler(self.engine)
+           return LookHandler(self.engine)
 
        # No valid key was pressed
        return action
 
 
class GameOverEventHandler(EventHandler):
+   def on_quit(self) -> None:
+       """Handle exiting out of a finished game."""
+       if os.path.exists("savegame.sav"):
+           os.remove("savegame.sav")  # Deletes the active save file.
+       raise exceptions.QuitWithoutSaving()  # Avoid saving a finished game.

+   def ev_quit(self, event: tcod.event.Quit) -> None:
+       self.on_quit()

    def ev_keydown(self, event: tcod.event.KeyDown) -> None:
        if event.sym == tcod.event.K_ESCAPE:
-           raise SystemExit()
+           self.on_quit()

... 
class HistoryViewer(EventHandler):
    ...
 
-   def ev_keydown(self, event: tcod.event.KeyDown) -> None:
+   def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[MainGameEventHandler]:
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
-           self.engine.event_handler = MainGameEventHandler(self.engine)
+           return MainGameEventHandler(self.engine)
+       return None
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>from __future__ import annotations
 
<span class="new-text">import os</span>

<span class="crossed-out-text">from typing import Callable, Optional, Tuple, TYPE_CHECKING</span>
<span class="new-text">from typing import Callable, Optional, Tuple, TYPE_CHECKING, Union</span>
 
import tcod
...

... 
CONFIRM_KEYS = {
    tcod.event.K_RETURN,
    tcod.event.K_KP_ENTER,
}


<span class="new-text">ActionOrHandler = Union[Action, "BaseEventHandler"]
"""An event handler return value which can trigger an action or switch active handlers.

If a handler is returned then it will become the active handler for future events.
If an action is returned it will be attempted and if it's valid then
MainGameEventHandler will become the active handler.
"""</span>


<span class="new-text">class BaseEventHandler(tcod.event.EventDispatch[ActionOrHandler]):
    def handle_events(self, event: tcod.event.Event) -> BaseEventHandler:
        """Handle an event and return the next active event handler."""
        state = self.dispatch(event)
        if isinstance(state, BaseEventHandler):
            return state
        assert not isinstance(state, Action), f"{self!r} can not handle actions."
        return self

    def on_render(self, console: tcod.Console) -> None:
        raise NotImplementedError()

    def ev_quit(self, event: tcod.event.Quit) -> Optional[Action]:
        raise SystemExit()</span>


<span class="new-text">class PopupMessage(BaseEventHandler):
    """Display a popup text window."""

    def __init__(self, parent_handler: BaseEventHandler, text: str):
        self.parent = parent_handler
        self.text = text

    def on_render(self, console: tcod.Console) -> None:
        """Render the parent and dim the result, then print the message on top."""
        self.parent.on_render(console)
        console.tiles_rgb["fg"] //= 8
        console.tiles_rgb["bg"] //= 8

        console.print(
            console.width // 2,
            console.height // 2,
            self.text,
            fg=color.white,
            bg=color.black,
            alignment=tcod.CENTER,
        )

    def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[BaseEventHandler]:
        """Any key returns to the parent handler."""
        return self.parent</span>
 
<span class="crossed-out-text">class EventHandler(tcod.event.EventDispatch[Action]):</span>
<span class="new-text">class EventHandler(BaseEventHandler):</span>
    def __init__(self, engine: Engine):
        self.engine = engine
 
    <span class="crossed-out-text">def handle_events(self, event: tcod.event.Event) -> None:</span>
        <span class="crossed-out-text">self.handle_action(self.dispatch(event))</span>
    <span class="new-text">def handle_events(self, event: tcod.event.Event) -> BaseEventHandler:
        """Handle events for input handlers with an engine."""
        action_or_state = self.dispatch(event)
        if isinstance(action_or_state, BaseEventHandler):
            return action_or_state
        if self.handle_action(action_or_state):
            # A valid action was performed.
            if not self.engine.player.is_alive:
                # The player was killed sometime during or after the action.
                return GameOverEventHandler(self.engine)
            return MainGameEventHandler(self.engine)  # Return to the main handler.
        return self</span>

    def handle_action(self, action: Optional[Action]) -> bool:
        ...
 
    <span class="crossed-out-text">def ev_quit(self, event: tcod.event.Quit) -> Optional[Action]:</span>
        <span class="crossed-out-text">raise SystemExit()</span>

    def on_render(self, console: tcod.Console) -> None:
        self.engine.render(console)
 

class AskUserEventHandler(EventHandler):
    """Handles user input for actions which require special input."""
 
    <span class="crossed-out-text">def handle_action(self, action: Optional[Action]) -> bool:</span>
        <span class="crossed-out-text">"""Return to the main event handler when a valid action was performed."""</span>
        <span class="crossed-out-text">if super().handle_action(action):</span>
            <span class="crossed-out-text">self.engine.event_handler = MainGameEventHandler(self.engine)</span>
            <span class="crossed-out-text">return True</span>
        <span class="crossed-out-text">return False</span>

    <span class="crossed-out-text">def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[Action]:</span>
    <span class="new-text">def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[ActionOrHandler]:</span>
        """By default any key exits this input handler."""
        if event.sym in {  # Ignore modifier keys.
            tcod.event.K_LSHIFT,
            tcod.event.K_RSHIFT,
            tcod.event.K_LCTRL,
            tcod.event.K_RCTRL,
            tcod.event.K_LALT,
            tcod.event.K_RALT,
        }:
            return None
        return self.on_exit()
 
    <span class="crossed-out-text">def ev_mousebuttondown(self, event: tcod.event.MouseButtonDown) -> Optional[Action]:</span>
    <span class="new-text">def ev_mousebuttondown(
        self, event: tcod.event.MouseButtonDown
    ) -> Optional[ActionOrHandler]:</span>
        """By default any mouse click exits this input handler."""
        return self.on_exit()
 
    <span class="crossed-out-text">def on_exit(self) -> Optional[Action]:</span>
    <span class="new-text">def on_exit(self) -> Optional[ActionOrHandler]:</span>
        """Called when the user is trying to exit or cancel an action.
 
        By default this returns to the main event handler.
        """
        <span class="crossed-out-text">self.engine.event_handler = MainGameEventHandler(self.engine)</span>
        <span class="crossed-out-text">return None</span>
        <span class="new-text">return MainGameEventHandler(self.engine)</span>


class InventoryEventHandler(AskUserEventHandler):
    ...
 
    <span class="crossed-out-text">def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[Action]:</span>
    <span class="new-text">def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[ActionOrHandler]:</span>
        player = self.engine.player
        key = event.sym
        index = key - tcod.event.K_a

        if 0 <= index <= 26:
            try:
                selected_item = player.inventory.items[index]
            except IndexError:
                self.engine.message_log.add_message("Invalid entry.", color.invalid)
                return None
            return self.on_item_selected(selected_item)
        return super().ev_keydown(event)
 
    <span class="crossed-out-text">def on_item_selected(self, item: Item) -> Optional[Action]:</span>
    <span class="new-text">def on_item_selected(self, item: Item) -> Optional[ActionOrHandler]:</span>
        """Called when the user selects a valid item."""
        raise NotImplementedError()


class InventoryActivateHandler(InventoryEventHandler):
    """Handle using an inventory item."""
 
    TITLE = "Select an item to use"
 
    <span class="crossed-out-text">def on_item_selected(self, item: Item) -> Optional[Action]:</span>
    <span class="new-text">def on_item_selected(self, item: Item) -> Optional[ActionOrHandler]:</span>
        """Return the action for the selected item."""
        return item.consumable.get_action(self.engine.player)
 

class InventoryDropHandler(InventoryEventHandler):
    """Handle dropping an inventory item."""
 
    TITLE = "Select an item to drop"
 
    <span class="crossed-out-text">def on_item_selected(self, item: Item) -> Optional[Action]:</span>
    <span class="new-text">def on_item_selected(self, item: Item) -> Optional[ActionOrHandler]:</span>
        """Drop this item."""
        return actions.DropItem(self.engine.player, item)
 

class SelectIndexHandler(AskUserEventHandler):
    ...
 
    <span class="crossed-out-text">def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[Action]:</span>
    <span class="new-text">def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[ActionOrHandler]:</span>
        ...
 
    <span class="crossed-out-text">def ev_mousebuttondown(self, event: tcod.event.MouseButtonDown) -> Optional[Action]:</span>
    <span class="new-text">def ev_mousebuttondown(
        self, event: tcod.event.MouseButtonDown
    ) -> Optional[ActionOrHandler]:</span>
        ...
 
    <span class="crossed-out-text">def on_index_selected(self, x: int, y: int) -> Optional[Action]:</span>
    <span class="new-text">def on_index_selected(self, x: int, y: int) -> Optional[ActionOrHandler]:</span>
        """Called when an index is selected."""
        raise NotImplementedError()
 

class LookHandler(SelectIndexHandler):
    """Lets the player look around using the keyboard."""
 
    <span class="crossed-out-text">def on_index_selected(self, x: int, y: int) -> None:</span>
    <span class="new-text">def on_index_selected(self, x: int, y: int) -> MainGameEventHandler:</span>
        """Return to main handler."""
        <span class="crossed-out-text">self.engine.event_handler = MainGameEventHandler(self.engine)</span>
        <span class="new-text">return MainGameEventHandler(self.engine)</span>

...

class MainGameEventHandler(EventHandler):
    <span class="crossed-out-text">def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[Action]:</span>
    <span class="new-text">def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[ActionOrHandler]:</span>
        action: Optional[Action] = None

        key = event.sym

        player = self.engine.player

        if key in MOVE_KEYS:
            dx, dy = MOVE_KEYS[key]
            action = BumpAction(player, dx, dy)
        elif key in WAIT_KEYS:
            action = WaitAction(player)

        elif key == tcod.event.K_ESCAPE:
            raise SystemExit()
        elif key == tcod.event.K_v:
            <span class="crossed-out-text">self.engine.event_handler = HistoryViewer(self.engine)</span>
            <span class="new-text">return HistoryViewer(self.engine)</span>
 
        elif key == tcod.event.K_g:
            action = PickupAction(player)
 
        elif key == tcod.event.K_i:
            <span class="crossed-out-text">self.engine.event_handler = InventoryActivateHandler(self.engine)</span>
            <span class="new-text">return InventoryActivateHandler(self.engine)</span>
        elif key == tcod.event.K_d:
            <span class="crossed-out-text">self.engine.event_handler = InventoryDropHandler(self.engine)</span>
            <span class="new-text">return InventoryDropHandler(self.engine)</span>
        elif key == tcod.event.K_SLASH:
            <span class="crossed-out-text">self.engine.event_handler = LookHandler(self.engine)</span>
            <span class="new-text">return LookHandler(self.engine)</span>
 
        # No valid key was pressed
        return action
 
 
class GameOverEventHandler(EventHandler):
    <span class="new-text">def on_quit(self) -> None:
        """Handle exiting out of a finished game."""
        if os.path.exists("savegame.sav"):
            os.remove("savegame.sav")  # Deletes the active save file.
        raise exceptions.QuitWithoutSaving()  # Avoid saving a finished game.

    def ev_quit(self, event: tcod.event.Quit) -> None:
        self.on_quit()</span>

    def ev_keydown(self, event: tcod.event.KeyDown) -> None:
        if event.sym == tcod.event.K_ESCAPE:
            <span class="crossed-out-text">raise SystemExit()</span>
            <span class="new-text">self.on_quit()</span>

... 
class HistoryViewer(EventHandler):
    ...
 
    <span class="crossed-out-text">def ev_keydown(self, event: tcod.event.KeyDown) -> None:</span>
    <span class="new-text">def ev_keydown(self, event: tcod.event.KeyDown) -> Optional[MainGameEventHandler]:</span>
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
            <span class="crossed-out-text">self.engine.event_handler = MainGameEventHandler(self.engine)</span>
            <span class="new-text">return MainGameEventHandler(self.engine)
        return None</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

`consumable.py`

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
...
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
    
    ...

class ConfusionConsumable(Consumable):
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
 
    ...

class FireballDamageConsumable(Consumable):
    def __init__(self, damage: int, radius: int):
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
        ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>...
import components.ai
import components.inventory
from components.base_component import BaseComponent
from exceptions import Impossible
<span class="crossed-out-text">from input_handlers import AreaRangedAttackHandler, SingleRangedAttackHandler</span>
<span class="new-text">from input_handlers import (
    ActionOrHandler,
    AreaRangedAttackHandler,
    SingleRangedAttackHandler,
)</span>
 
if TYPE_CHECKING:
    ...

...
class Consumable(BaseComponent):
    parent: Item
 
    <span class="crossed-out-text">def get_action(self, consumer: Actor) -> Optional[actions.Action]:</span>
    <span class="new-text">def get_action(self, consumer: Actor) -> Optional[ActionOrHandler]:</span>
        """Try to return the action for this item."""
        return actions.ItemAction(consumer, self.parent)
    
    ...

class ConfusionConsumable(Consumable):
    def __init__(self, number_of_turns: int):
        self.number_of_turns = number_of_turns
 
    <span class="crossed-out-text">def get_action(self, consumer: Actor) -> Optional[actions.Action]:</span>
    <span class="new-text">def get_action(self, consumer: Actor) -> SingleRangedAttackHandler:</span>
        self.engine.message_log.add_message(
            "Select a target location.", color.needs_target
        )
        <span class="crossed-out-text">self.engine.event_handler = SingleRangedAttackHandler(</span>
        <span class="new-text">return SingleRangedAttackHandler(</span>
            self.engine,
            callback=lambda xy: actions.ItemAction(consumer, self.parent, xy),
        )
        <span class="crossed-out-text">return None</span>
 
    ...

class FireballDamageConsumable(Consumable):
    def __init__(self, damage: int, radius: int):
        self.damage = damage
        self.radius = radius

    <span class="crossed-out-text">def get_action(self, consumer: Actor) -> Optional[actions.Action]:</span>
    <span class="new-text">def get_action(self, consumer: Actor) -> AreaRangedAttackHandler:</span>
        self.engine.message_log.add_message(
            "Select a target location.", color.needs_target
        )
        <span class="crossed-out-text">self.engine.event_handler = AreaRangedAttackHandler(</span>
        <span class="new-text">return AreaRangedAttackHandler(</span>
            self.engine,
            radius=self.radius,
            callback=lambda xy: actions.ItemAction(consumer, self.parent, xy),
        )
        <span class="crossed-out-text">return None</span>
 
    def activate(self, action: actions.ItemAction) -> None:
        ...</pre>
{{</ original-tab >}}
{{</ codetab >}}


TODO: Fill this in

`engine.py`

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

`main.py`

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

`fighter.py`

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

Last thing before we wrap up: We're creating the `.sav` files to represent our saved games, but we don't want to include these in out Git repository, since that should be reserved for just the code. The fix for this is to add this to our `.gitignore` file:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
+# Saved games
+*.sav
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre><span class="new-text"># Saved games
*.sav</span></pre>
{{</ original-tab >}}
{{</ codetab >}}

_The rest of the .gitignore is omitted, as your .gitignore file may look different from mine. It doesn't matter where you add this in._


TODO: Finish the tutorial.