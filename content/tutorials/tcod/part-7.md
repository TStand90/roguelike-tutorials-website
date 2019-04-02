---
title: "Part 7 - Creating the Interface"
date: 2019-03-30T09:33:53-07:00
draft: false
---

Our game is looking more and more playable by the chapter, but before we
move forward with the gameplay, we ought to take a moment to focus on
how the project *looks*. Despite what roguelike traditionalists may tell
you, a good UI goes a long way.

Let's start by fixing up our HP section. With not all that much code, we
can add a neat little health bar, that will tell the player how much
health is remaining before death. We'll start by adding some needed
variables in `engine.py`:

        ...
        screen_height = 50

    +     bar_width = 20
    +     panel_height = 7
    +     panel_y = screen_height - panel_height

        map_width = 80
    -     map_height = 45
    +     map_height = 43
        ...
        con = libtcod.console_new(screen_width, screen_height)
    +     panel = libtcod.console_new(screen_width, panel_height)

We're creating a new console, called `panel`, which will hold our HP bar
and message log. We also modified the map height while we were at it, to
give the HP bar and (soon to come) message log more room.

Now we'll want a function that draws the health bar, or any other bar we
desire. You might want to add a Mana or Stamina bar later on, so it's
best that we make this function as reusable as possible. Put the
following in `render_functions.py`, right under the `RenderOrder` enum,
but above `render_all`.

    def render_bar(panel, x, y, total_width, name, value, maximum, bar_color, back_color):
        bar_width = int(float(value) / maximum * total_width)

        libtcod.console_set_default_background(panel, back_color)
        libtcod.console_rect(panel, x, y, total_width, 1, False, libtcod.BKGND_SCREEN)

        libtcod.console_set_default_background(panel, bar_color)
        if bar_width > 0:
            libtcod.console_rect(panel, x, y, bar_width, 1, False, libtcod.BKGND_SCREEN)

        libtcod.console_set_default_foreground(panel, libtcod.white)
        libtcod.console_print_ex(panel, int(x + total_width / 2), y, libtcod.BKGND_NONE, libtcod.CENTER,
                                 '{0}: {1}/{2}'.format(name, value, maximum))

Now let's use this function in `render_all`. Remove the HP indicator we
had put in before, and put the code for the stats panel at the end of
the function.

    def render_all(con, entities, player, game_map, fov_map, fov_recompute, screen_width, screen_height, colors):
    + def render_all(con, panel, entities, player, game_map, fov_map, fov_recompute, screen_width, screen_height, bar_width,
    +                panel_height, panel_y, colors):
                ...
    -     libtcod.console_set_default_foreground(con, libtcod.white)
    -     libtcod.console_print_ex(con, 1, screen_height - 2, libtcod.BKGND_NONE, libtcod.LEFT,
    -                              'HP: {0:02}/{1:02}'.format(player.fighter.hp, player.fighter.max_hp))

        libtcod.console_blit(con, 0, 0, screen_width, screen_height, 0, 0, 0)

    +     libtcod.console_set_default_background(panel, libtcod.black)
    +     libtcod.console_clear(panel)
    + 
    +     render_bar(panel, 1, 1, bar_width, 'HP', player.fighter.hp, player.fighter.max_hp,
    +                libtcod.light_red, libtcod.darker_red)
    + 
    +     libtcod.console_blit(panel, 0, 0, screen_width, panel_height, 0, 0, panel_y)

Be sure to update the call to `render_all` in `engine.py`:

            render_all(con, entities, player, game_map, fov_map, fov_recompute, screen_width, screen_height, colors)
    +         render_all(con, panel, entities, player, game_map, fov_map, fov_recompute, screen_width, screen_height,
    +                    bar_width, panel_height, panel_y, colors)

Now we've got a nice looking HP bar at the bottom of the screen. It'll
decrease when the player takes damage, and increase when we heal (that's
coming next chapter).

Let's keep things going, and create our message log. Add the following
variables to `engine.py` to start:

        ...
        panel_y = screen_height - panel_height

    +     message_x = bar_width + 2
    +     message_width = screen_width - bar_width - 2
    +     message_height = panel_height - 1

        map_width = 80
        ...

To implement the message log, we'll need two classes: one for the log,
and one for the messages inside it. Start by creating a new file, called
`game_messages.py`. Put the following code inside it:

    import tcod as libtcod

    import textwrap


    class Message:
        def __init__(self, text, color=libtcod.white):
            self.text = text
            self.color = color


    class MessageLog:
        def __init__(self, x, width, height):
            self.messages = []
            self.x = x
            self.width = width
            self.height = height

        def add_message(self, message):
            # Split the message if necessary, among multiple lines
            new_msg_lines = textwrap.wrap(message.text, self.width)

            for line in new_msg_lines:
                # If the buffer is full, remove the first line to make room for the new one
                if len(self.messages) == self.height:
                    del self.messages[0]

                # Add the new line as a Message object, with the text and the color
                self.messages.append(Message(line, message.color))

That's a lot to take in at once, so let's go through it.

`Message` is pretty simple. We store the message text and the color to
draw it with. You can opt to not pass a color, in which case, white is
used by default.

The `MessageLog` is the more interesting class. It holds a list of
messages (the `Message` class), holds its x coordinate (for
convenience), and its width and height. Width and height are useful so
that we'll know when we need to cut off the top messages (the message
log will "scroll" as new messages come up).

In the `add_message` method, we're splitting up the message text into
multiple lines if needed, using the `textwrap.wrap` function. We then
check if the message log is at its capacity, and if so, we delete the
top lines. Finally, we append the new message.

Let's start putting this new message log into place. Add a new message
log to `engine.py`:

        fov_map = initialize_fov(game_map)

    +     message_log = MessageLog(message_x, message_width, message_height)

        key = libtcod.Key()

Remember to import the `MessageLog` at the top as well:

    from fov_functions import initialize_fov, recompute_fov
    + from game_messages import MessageLog
    from game_states import GameStates

With our message log in place, let's go through the project and remove
all the `print` statements, replacing them with the message log.

Let's start with the death functions. In `death_functions.py`:

    import tcod as libtcod

    + from game_messages import Message

    from game_states import GameStates

    from render_functions import RenderOrder


    def kill_player(player):
        player.char = '%'
        player.color = libtcod.dark_red

    -     return 'You died!', GameStates.PLAYER_DEAD
    +     return Message('You died!', libtcod.red), GameStates.PLAYER_DEAD


    def kill_monster(monster):
    -     death_message = '{0} is dead!'.format(monster.name.capitalize())
    +     death_message = Message('{0} is dead!'.format(monster.name.capitalize()), libtcod.orange)
        ...

Then, back in `engine.py`, replace the corresponding `print` statements
like this:

                 ...
                (In the player's results loop)
                ...
                if dead_entity:
                    if dead_entity == player:
                        message, game_state = kill_player(dead_entity)
                    else:
                        message = kill_monster(dead_entity)

    -                 print(message)
    +                 message_log.add_message(message)
                ...
                (In the enemy results loop)
                ...
                            if dead_entity:
                                if dead_entity == player:
                                    message, game_state = kill_player(dead_entity)
                                else:
                                    message = kill_monster(dead_entity)

    -                             print(message)
    +                             message_log.add_message(message)
                                ...

Now for our action messages. In `fighter.py`:

            ...
            if damage > 0:
    -             results.append({'message': '{0} attacks {1} for {2} hit points.'.format(self.owner.name.capitalize(),
    -                                                                                     target.name, str(damage))})
    +             results.append({'message': Message('{0} attacks {1} for {2} hit points.'.format(
    +                 self.owner.name.capitalize(), target.name, str(damage)), libtcod.white)})
                results.extend(target.fighter.take_damage(damage))
            else:
    -             results.append({'message': '{0} attacks {1} but does no damage.'.format(self.owner.name.capitalize(),
    -                                                                                     target.name)})
    +             results.append({'message': Message('{0} attacks {1} but does no damage.'.format(
    +                 self.owner.name.capitalize(), target.name), libtcod.white)})

            return results

You'll need to import both libtcod and Message for this to work:

    import tcod as libtcod

    from game_messages import Message


    class Fighter:
        ...

And in `engine.py`:

                ...
                (In the player's results loop)
                ...
                if message:
    -                 print(message)
    +                 message_log.add_message(message)
                ...
                (In the enemy results loop)
                ...
                            if message:
    -                             print(message)
    +                             message_log.add_message(message)

Great, now we're adding all the messages to the log. However, nothing
shows up yet. Let's modify `render_all` to display the message log we've
created.

    def render_all(con, panel, entities, player, game_map, fov_map, fov_recompute, screen_width, screen_height, bar_width,
    -                panel_height, panel_y, colors):
    + def render_all(con, panel, entities, player, game_map, fov_map, fov_recompute, message_log, screen_width, screen_height,
    +                bar_width, panel_height, panel_y, colors):
        ...
        libtcod.console_clear(panel)

    +     # Print the game messages, one line at a time
    +     y = 1
    +     for message in message_log.messages:
    +         libtcod.console_set_default_foreground(panel, message.color)
    +         libtcod.console_print_ex(panel, message_log.x, y, libtcod.BKGND_NONE, libtcod.LEFT, message.text)
    +         y += 1
        ...

Then modify the call to `render_all` in `engine.py` to include the
message log:

            render_all(con, panel, entities, player, game_map, fov_map, fov_recompute, screen_width, screen_height,
    -                    bar_width, panel_height, panel_y, colors)
    +         render_all(con, panel, entities, player, game_map, fov_map, fov_recompute, message_log, screen_width,
    +                    screen_height, bar_width, panel_height, panel_y, colors)

Run the project now. All our previous printed statements should now
appear in a scrolling message log. From here on out, we won't be doing
any more `print` statements, we'll just add everything to our message
log.

What's next? How about a little mouse-driven action? Our game is only
orcs and trolls right now, but perhaps someday it will have dozens
(hundreds?) of different monster and item types. It would be nice if we
could see what they are by moving our mouse over them.

Lucky for us, we're already capturing Mouse input, in the `mouse`
variable right above the game loop. All we need to do is adjust our call
to `libtcod.sys_check_for_event` to respond to the mouse, and write the
code that displays the name when we move the mouse over something.

            libtcod.sys_check_for_event(libtcod.EVENT_KEY_PRESS, key, mouse)
    +         libtcod.sys_check_for_event(libtcod.EVENT_KEY_PRESS | libtcod.EVENT_MOUSE, key, mouse)

Put the following function in `render_functions.py`, above `render_bar`:

    def get_names_under_mouse(mouse, entities, fov_map):
        (x, y) = (mouse.cx, mouse.cy)

        names = [entity.name for entity in entities
                 if entity.x == x and entity.y == y and libtcod.map_is_in_fov(fov_map, entity.x, entity.y)]
        names = ', '.join(names)

        return names.capitalize()


    def render_bar(panel, x, y, total_width, name, value, maximum, bar_color, back_color):
        ...

Now we'll once again modify our `render_all` function (that sure has had
a lot of changes this chapter, hasn't it?) to account for the mouse and
take advantage of our new function.

    def render_all(con, panel, entities, player, game_map, fov_map, fov_recompute, message_log, screen_width, screen_height,
    -                bar_width, panel_height, panel_y, colors):
    + def render_all(con, panel, entities, player, game_map, fov_map, fov_recompute, message_log, screen_width, screen_height,
    +                bar_width, panel_height, panel_y, mouse, colors):
        ...
        render_bar(panel, 1, 1, bar_width, 'HP', player.fighter.hp, player.fighter.max_hp,
                   libtcod.light_red, libtcod.darker_red)

    +     libtcod.console_set_default_foreground(panel, libtcod.light_gray)
    +     libtcod.console_print_ex(panel, 1, 0, libtcod.BKGND_NONE, libtcod.LEFT,
    +                              get_names_under_mouse(mouse, entities, fov_map))

        libtcod.console_blit(panel, 0, 0, screen_width, panel_height, 0, 0, panel_y)

And, of course, we'll need to modify the call to `render_all` in
`engine.py` to match our new definition.

            render_all(con, panel, entities, player, game_map, fov_map, fov_recompute, message_log, screen_width,
    -                    screen_height, bar_width, panel_height, panel_y, colors)
    +         render_all(con, panel, entities, player, game_map, fov_map, fov_recompute, message_log, screen_width,
    +                    screen_height, bar_width, panel_height, panel_y, mouse, colors)

Our game is now looking much, much better. If you ever intend for your
game to be played by more people than just yourself (it's okay if you
don't!) then changes like these will be of paramount importance to your
project.

If you want to see the code so far in its entirety, [click
here](https://github.com/TStand90/roguelike_tutorial_revised/tree/part7).

[Click here to move on to the next part of this
tutorial.](/tutorials/tcod/part-8)

