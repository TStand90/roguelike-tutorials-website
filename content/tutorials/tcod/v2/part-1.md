---
title: "Part 1 - Drawing the '@' symbol and moving it around"
date: 2020-06-14T11:35:26-07:00
draft: true
---


Welcome to part 1 of this tutorial! This series will help you create your very first roguelike game, written in Python\!

This tutorial is largely based off the [one found on Roguebasin](http://www.roguebasin.com/index.php?title=Complete_Roguelike_Tutorial,_using_python%2Blibtcod). Many of the design decisions were mainly to keep this tutorial in lockstep
with that one (at least in terms of chapter composition and general direction). This tutorial would not have been possible without the guidance of those who wrote that tutorial, along with all the wonderful contributors to tcod and python-tcod over the years.

This part assumes that you have either checked [Part 0](/tutorials/tcod/part-0) and are already set up and ready to go. If not, be sure to check that page, and make sure that you've got Python and TCOD installed, and a file called `main.py` created in the directory that you want to work in.

Assuming that you've done all that, let's get started. Modify (or create, if you haven't already) the file `main.py` to look like this:

{{< highlight py3 >}}
import tcod


def main():
    print("Hello World!")


if __name__ == "__main__":
    main()
{{</ highlight >}}

You can run the program by like any other Python program, but for those who are brand new, you do that by typing `python main.py` in the terminal. If you have both Python 2 and 3 installed on your machine, you might have to use `python3 main.py` to run (it depends on your default python, and whether you're using a virtualenv or not).

Okay, not the most exciting program in the world, I admit, but we've already got our first major difference from the other tutorial. Namely, this funky looking thing here:

{{< highlight py3 >}}
if __name__ == "__main__":
    main()
{{< /highlight >}}

So what does that do? Basically, we're saying that we're only going to run the "main" function when we explicitly run the script, using `python main.py`. It's not super important that you understand this now, but if you want a more detailed explanation, [this answer on Stack Overflow](https://stackoverflow.com/a/419185) gives a pretty good overview.

Confirm that the above program runs (if not, there's probably an issue with your tcod setup). Once that's done, we can move on to bigger and better things. The first major step to creating any roguelike is getting an '@' character on the screen and moving, so let's get started with that.

Modify `main.py` to look like this:

{{< highlight py3 >}}
import tcod


def main():
    screen_width: int = 80
    screen_height: int = 50

    tcod.console_set_custom_font("arial10x10.png", tcod.FONT_TYPE_GREYSCALE | tcod.FONT_LAYOUT_TCOD)

    with tcod.console_init_root(
        w=screen_width,
        h=screen_height,
        title="Yet Another Roguelike Tutorial",
        order="F",
        vsync=True
    ) as root_console:
        while True:
            root_console.print(x=1, y=1, string="@")
            
            tcod.console_flush()

            for event in tcod.event.wait():
                if event.type == "QUIT":
                    raise SystemExit()


if __name__ == "__main__":
    main()
{{</ highlight >}}

Run `main.py` again, and you should see an '@' symbol on the screen. Once you've fully soaked in the glory on the screen in front of you, you can click the "X" in the top-left corner of the program to close it.

There's a lot going on here, so let's break it down line by line.

{{< highlight py3 >}}
    screen_width: int = 80
    screen_height: int = 50
{{</ highlight >}}

This is simple enough. We're defining some variables for the screen size. The only thing that might seem odd is the type hinting syntax, which is the ": int" part of the declarations. Those parts are optional, and you could write the statement as `screen_width = 80` without issue. Whether to include type hints is largely a matter of preference.

Eventually, we'll load these values from a JSON file rather than hard coding them in the source, but we won't worry about that until we have some more variables like this.

{{< highlight py3 >}}
    tcod.console_set_custom_font("arial10x10.png", tcod.FONT_TYPE_GREYSCALE | tcod.FONT_LAYOUT_TCOD)
{{</ highlight >}}

Here, we're telling tcod which font to use. The `"arial10x10.png"` bit is the actual file we're reading from (this should exist in your project folder). The other two parts are telling tcod which type of file we're reading.

{{< highlight py3 >}}
    with tcod.console_init_root(
        w=screen_width,
        h=screen_height,
        title="Yet Another Roguelike Tutorial",
        order="F",
        vsync=True
    ) as root_console:
{{</ highlight >}}

This part is what actually creates the screen. We're giving it the `screen_width` and `screen_height` values from before (80 and 50, respectively), along with a title (change this if you've already got your game's name figured out).

The other variables, `order` and `vsync`, require a bit more explanation.

* `order`: When set to "F", this will change the ordering of the axes in NumPy. TCOD uses NumPy under the hood, which, by default, accesses 2D arrays in [y, x] order, which is fairly unintuitive. By setting `order="F"`, we can change this to be [x, y] instead. This will make more sense once we start drawing the map.
* `vsync` turns vsync on or off. I recommend looking up what "vsync" is if you don't already know. It won't really matter whether it's on or off for our purposes, but TCOD gives a warning if a default value is not supplied.

{{< highlight py3 >}}
        while True:
{{</ highlight >}}

This is what's called our 'game loop'. Basically, this is a loop that won't ever end, until we close the screen. Every game has some sort of game loop or another.

{{< highlight py3 >}}
            root_console.print(x=1, y=1, string="@")
{{</ highlight >}}

This line is what tells the program to actually put the "@" symbol on the screen in its proper place. We're telling the `root_console` we created to `print` the "@" symbol at the given x and y coordinates. Try changing the x and y values and see what happens, if you feel so inclined.

{{< highlight py3 >}}
            tcod.console_flush()
{{</ highlight >}}

Without this line, nothing would actually print out on the screen. This is because `console_flush` is what actually updates the screen with what we've told it to display so far.

{{< highlight py3 >}}
            for event in tcod.event.wait():
                if event.type == "QUIT":
                    raise SystemExit()
{{</ highlight >}}

This part gives us a way to gracefully exit (i.e. not crashing) the program by hitting the `X` button in the console's window. The line `for event in tcod.event.wait()` will wait for some sort of input from the user (mouse clicks, keyboard strokes, etc.) and loop through each event that happened. `SystemExit()` tells Python to quit the current running program.

Alright, our "@" symbol is successfully displayed on the screen, but we can't rest just yet. We still need to get it moving around\!

We need to keep track of the player's position at all times. Since this is a 2d game, we can express this in two data points: the `x` and `y` coordinates. Let's create two variables, `player_x` and `player_y`, to keep track of this.

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
    ...
    screen_height: int = 50
+   
+   player_x: int = int(screen_width / 2)
+   player_y: int = int(screen_height / 2)
+   
    tcod.console_set_custom_font("arial10x10.png", tcod.FONT_TYPE_GREYSCALE | tcod.FONT_LAYOUT_TCOD)
    ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>    ...
    screen_height: int = 50
    <span class="new-text">
    player_x: int = int(screen_width / 2)
    player_y: int = int(screen_height / 2)
    </span>
    tcod.console_set_custom_font("arial10x10.png", tcod.FONT_TYPE_GREYSCALE | tcod.FONT_LAYOUT_TCOD)
    ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

*Note: Ellipses denote omitted parts of the code. I'll include lines around the code to be inserted so that you'll know exactly where to put new pieces of code, but I won't be showing the entire file every time. The green lines denote code that you should be adding.*

We're placing the player right in the middle of the screen. What's with the `int()` function though? Well, Python 3 doesn't automatically
truncate division like Python 2 does, so we have to cast the division result (a float) to an integer. If we don't, tcod will give an error.

*Note: It's been pointed out that you could divide with `//` instead of `/` and achieve the same effect. This is true, except in cases where, for whatever reason, one of the numbers given is a decimal. For example, `screen_width // 2.0` will give an error. That shouldn't happen in this case, but wrapping the function in `int()` gives us certainty that this won't ever happen.*

We also have to modify the command to put the '@' symbol to use these new coordinates.

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
        ...
        while True:
-           root_console.print(x=1, y=1, string="@")
+           root_console.print(x=player_x, y=player_y, string="@")
        
            tcod.console_flush()
            ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>        ...
        while True:
            <span class="crossed-out-text">root_console.print(x=1, y=1, string="@")</span>
            <span class="new-text">root_console.print(x=player_x, y=player_y, string="@")</span>
        
            tcod.console_flush()
            ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

*Note: The red lines denote code that has been removed.*

Run the code now and you should see the '@' in the center of the screen. Let's take care of moving it around now.

So, how do we actually capture the user's input? TCOD makes this pretty easy, and in fact, we're already doing it. This line takes care of it for us:

{{< highlight py3 >}}
            for event in tcod.event.wait():
{{</ highlight >}}

It gets the "events", which we can then process. Events range from mouse movements to keyboard strokes. Let's start by getting some basic keyboard commands and processing them, and based on what we get, we'll move our little "@" symbol around.

We *could* identify which key is being pressed right here in `main.py`, but this is a good opportunity to break our project up a little bit. Sooner or later, we're going to have quite a few potential keyboard commands, so putting them all in `main.py` would make the file longer than it needs to be. Maybe we should import what we need into `main.py` rather than writing it all there.

To handle the keyboard inputs and the actions associated with them, let's actually create *two* new files. One will hold the different types of "actions" our rogue can perform, and the other will bridge the gap between the keys we press and those actions.

Create two new Python files in your project's directory, one called `input_handlers.py`, and the other called `actions.py`. Let's fill out `actions.py` first:

{{< highlight py3 >}}
from enum import auto, Enum


class ActionType(Enum):
    ESCAPE = auto()
    MOVEMENT = auto()


class Action:
    def __init__(self, action_type: ActionType, **kwargs):
        self.action_type: ActionType = action_type
        self.kwargs = kwargs
{{</ highlight >}}

There's a few things to go over here. The first being Enums.

Enums are basically a set of predefined constant values. That is, they are set ahead of time, and they won't change while the program is running. You could just have a bunch of strings that you keep track of instead, but that can be a bit error prone.

To create Enums in Python, you have to create a class that inheirits from the Enum class, like our `ActionType` class. From there, you set the different values, which in our case, are `ESCAPE` and `MOVEMENT`. We'll add more action types through this tutorial, but this will get us through the first few parts.

`auto()` was added in Python 3.6, and allows you to automatically set the value of the enums. Before Python 3.6, you would have to do something like this:

{{< highlight py3 >}}
from enum import Enum


class ActionType(Enum):
    ESCAPE = 1
    MOVEMENT = 2
{{</ highlight >}}

`auto()` does the same thing for us, incrementing the value for each enum inside the class. It's a nice little convenience. You can still set the values manually if you really want to, but `auto()` will do just fine for us here.

So `ActionType` is an Enum, but it's not the only thing we added to this file. We also added a class called `Action`, which uses `ActionType` and also accepts `**kwargs`. What this means is that it needs an `ActionType` to determine what type of action it is, but it also accepts arbitrary named arguments, in case we need to know more than just the type. In fact, we use this in our `MOVEMENT` action type.

That's all we need to do in `actions.py` right now. Let's fill out `input_handlers.py`, which will use the `Action` and `ActionType` classes we just created:

{{< highlight py3 >}}
import tcod.event

from actions import Action, ActionType


def handle_keys(key) -> [Action, None]:
    action: [Action, None] = None

    if key == tcod.event.K_UP:
        action = Action(ActionType.MOVEMENT, dx=0, dy=-1)
    elif key == tcod.event.K_DOWN:
        action = Action(ActionType.MOVEMENT, dx=0, dy=1)
    elif key == tcod.event.K_LEFT:
        action = Action(ActionType.MOVEMENT, dx=-1, dy=0)
    elif key == tcod.event.K_RIGHT:
        action = Action(ActionType.MOVEMENT, dx=1, dy=0)

    elif key == tcod.event.K_ESCAPE:
        action = Action(ActionType.ESCAPE)

    # No valid key was pressed
    return action
{{</ highlight >}}

We define a function, `handle_keys`, which accepts one arguments: `key`. It probably goes without saying, but `key` represents the key on the keyboard the user pressed. The function will return either an `Action`, or `None`.

From there, we go down a list of possible keys pressed. For example:

{{< highlight py3 >}}
    if key == tcod.event.K_UP:
        action = Action(ActionType.MOVEMENT, dx=0, dy=-1)
{{</ highlight >}}

In this case, the user pressed the up-arrow key, so we're creating an action of type `MOVEMENT`. In the case of `MOVEMENT`, we also need to provide additional information: the direction the user is trying to move in. Hence, the `dx` and `dy` keyword arguments (which represent the change in x and y coordinates, respectively) in the `Action`. Hopefully now the inclusion of `**kwargs` earlier makes some sense.

{{< highlight py3 >}}
    elif key == tcod.event.K_ESCAPE:
        action = Action(ActionType.ESCAPE)
{{</ highlight >}}

If the user pressed the "Escape" key, we return Action type `ESCAPE`. We'll use this to exit the game for now, though in the future, `ESCAPE` will be used to do things like exit menus.

Let's put our new actions and input handlers to use in `main.py`. Edit `main.py` like this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
import tcod

+from actions import Action, ActionType
+from input_handlers import handle_keys


def main():
    ...

            ...
            for event in tcod.event.wait():
                if event.type == "QUIT":
                    raise SystemExit()
                
+               if event.type == "KEYDOWN":
+                   action: [Action, None] = handle_keys(event.sym)

+                   if action is None:
+                       continue

+                   action_type: ActionType = action.action_type

+                   if action_type == ActionType.MOVEMENT:
+                       dx: int = action.kwargs.get("dx", 0)
+                       dy: int = action.kwargs.get("dy", 0)

+                       player_x += dx
+                       player_y += dy
+                   elif action_type == ActionType.ESCAPE:
+                       raise SystemExit()


if __name__ == "__main__":
    main()
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>import tcod

<span class="new-text">from actions import Action, ActionType
from input_handlers import handle_keys</span>


def main():
    ...

            ...
            for event in tcod.event.wait():
                if event.type == "QUIT":
                    raise SystemExit()
                <span class="new-text">
                if event.type == "KEYDOWN":
                    action: [Action, None] = handle_keys(event.sym)

                    if action is None:
                        continue

                    action_type: ActionType = action.action_type

                    if action_type == ActionType.MOVEMENT:
                        dx: int = action.kwargs.get("dx", 0)
                        dy: int = action.kwargs.get("dy", 0)

                        player_x += dx
                        player_y += dy
                    elif action_type == ActionType.ESCAPE:
                        raise SystemExit()</span>


if __name__ == "__main__":
    main()</pre>
{{</ original-tab >}}
{{</ codetab >}}

Let's break down the new additions a bit.

{{< highlight py3 >}}
                if event.type == "KEYDOWN":
                    action: [Action, None] = handle_keys(event.sym)
{{</ highlight >}}

We check if the "event" we received is of type "KEYDOWN", which means we check if the user pressed a key on the keyboard. If so, we call our `handle_keys` function, and pass `event.sym` as an argument. `event.sym` is the "symbol" (key). The return value from `handle_keys` is set to our `action` variable, which can be either `None` or class `Action`.

{{< highlight py3 >}}
                    if action is None:
                        continue
{{</ highlight >}}

This is pretty straightforward: If `action` is `None` (that is, no key was pressed, or the key pressed isn't recognized), then we skip over the rest the loop. There's no need to go any further, since the lines below are going to handle the valid key presses.

{{< highlight py3 >}}
                    action_type: ActionType = action.action_type
{{</ highlight >}}

We're grabbing the `ActionType` from the action for convenience. We'll check what type we received to determine what to do. We could just keep typing `action.action_type` instead, but I think this syntax is a bit cleaner and easier to read in the long run.

{{< highlight py3 >}}
                    if action_type == ActionType.MOVEMENT:
                        dx: int = action.kwargs.get("dx", 0)
                        dy: int = action.kwargs.get("dy", 0)

                        player_x += dx
                        player_y += dy
{{</ highlight >}}

Now we arrive at the interesting part. If the `action_type` is type `MOVEMENT`, we need to move our "@" symbol. We grab the `dx` and `dy` values from the keyword arguments we gave to the `Action` earlier, which will the "@" symbol in which direction we want it to move. `dx` and `dy`, as of now, will only ever be -1, 0, or 1. Regardless of what the value is, we add `dx` and `dy` to `player_x` and `player_y`, respectively. Because the console is using `player_x` and `player_y` to draw where our "@" symbol is, modifying these two variables will cause the symbol to move.

{{< highlight py3 >}}
                    elif action_type == ActionType.ESCAPE:
                        raise SystemExit()
{{</ highlight>}}

`raise SystemExit()` should look familiar: it's how we're quitting out of the program. So basically, if the user hits the `Esc` key, our program should exit. You don't have to include this, I just think it's convenient to allow users to quit the program using the keyboard.

With all that done, let's run the program and see what happens!

Indeed, our "@" symbol does move, but... it's perhaps not what was expected.

![Snake the Roguelike?](/images/snake_the_roguelike.png "Snake the Roguelike?")

Unless you're making a roguelike version of "Snake" (and who knows, maybe you are), we need to fix the "@" symbol being left behind wherever we move. So why is this happening in the first place?

Turns out, we need to "clear" the console after we've drawn it, or we'll get these leftovers when we draw symbols in their new places. Luckily, this is as easy as adding one line:


{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
    ...
        while True:
            root_console.print(x=player_x, y=player_y, string="@")

            tcod.console_flush()

+           root_console.clear()

            for event in tcod.event.wait():
                ...
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>    ...
        while True:
            root_console.print(x=player_x, y=player_y, string="@")

            tcod.console_flush()

            <span class="new-text">root_console.clear()</span>

            for event in tcod.event.wait():
                ...</pre>
{{</ original-tab >}}
{{</ codetab >}}

That's it! Run the project now, and the "@" symbol will move around, without leaving traces of itself behind.

That wraps up part one of this tutorial\! If you're using git or some
other form of version control (and I recommend you do), commit your
changes now.

If you want to see the code so far in its entirety, [click
here](https://github.com/TStand90/tcod_tutorail_v2/tree/part-1).

[Click here to move on to the next part of this
tutorial.](/tutorials/tcod/v2/part-2)
