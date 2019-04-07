---
title: "Part 0 - Setting Up"
date: 2019-03-30T09:53:48-07:00
draft: false
---

#### Prior knowledge

This tutorial assumes some basic familiarity with programming in
general, and with Python. If you've never used Python before, this
tutorial could be a little confusing. There are many free resources
online about learning programming and Python (too many to list here),
and I'd recommend learning about objects and functions in Python at the
very least before attempting to read this tutorial.

... Of course, there are those who have ignored this advice and done
well with this tutorial anyway, so feel free to ignore that last
paragraph if you're feeling bold\!

#### Installation

To do this tutorial, you'll need Python version 3.5 or higher. The
latest version of Python is recommended (currently 3.7 as of March
2019). **Note: Python 2 is not compatible.**

[Download Python here](https://www.python.org/downloads/).

You'll also want the latest version of the TCOD library, which is what
this tutorial is based on.

[Installation instructions for TCOD can be found
here.](https://python-tcod.readthedocs.io/en/latest/installation.html)

While you can certainly install TCOD and complete this tutorial without
it, I'd highly recommend using a virtual environment. [Documentation on
how to do that can be found
here.](https://docs.python.org/3/library/venv.html)

#### Editors

Any text editor can work for writing Python. You could even use Notepad
if you really wanted to. Personally, I'm a fan of
[Pycharm](https://www.jetbrains.com/pycharm/) and [Visual Studio
Code](https://code.visualstudio.com/). Whatever you choose, I strongly
recommend something that can help catch Python syntax errors at the very
least. I've been working with Python for over five years, and I still
make these types of mistakes all the time\!

#### Making sure Python works

To verify that your installation of both Python 3 and TCOD are working,
create a new file (in whatever directory you plan on using for the
tutorial) called `engine.py`, and enter the following text into it:

    import tcod as libtcod
    
    
    def main():
        print('Hello World!')
    
    
    if __name__ == '__main__':
        main()

Run the file in your terminal (or alternatively in your editor, if
possible):

`python engine.py`

If you're not using `virtualenv`, the command will probably look like
this:

`python3 engine.py`

You should see "Hello World\!" printed out to the terminal. If you
receive an error, there is probably an issue with either your Python or
TCOD installation.

### Getting help

Be sure to check out the [Roguelike Development
Subreddit](https://www.reddit.com/r/roguelikedev) for help. There's a
link there to the Discord channel as well.

-----

### Ready to go?

Once you're set up and ready to go, you can proceed to [Part
1](/tutorials/tcod/part-1).

