---
title: "Extra - A more \"Traditional\" Look"
date: 2020-09-18T16:39:01-07:00
draft: false
---

_Prerequisites: Completion of [part 4](../../part-4/)_

The tutorial itself goes in a much different visual direction than most roguelikes. If you like this look, great! If you want to make your game look a bit more like other roguelikes you might be more familiar with, this section is for you.

Most roguelikes define the floor tiles as a period (`.`) and the wall tiles as a pound sign (`#`). This is simple enough to implement, by adjusting our tile types like this:

{{< codetab >}}
{{< diff-tab >}}
{{< highlight diff >}}
floor = new_tile(
    walkable=True,
    transparent=True,
-   dark=(ord(" "), (255, 255, 255), (50, 50, 150)),
-   light=(ord(" "), (255, 255, 255), (200, 180, 50)),
+   dark=(ord("."), (100, 100, 100), (0, 0, 0)),
+   light=(ord("."), (200, 200, 200), (0, 0, 0)),
)
wall = new_tile(
    walkable=False,
    transparent=False,
-   dark=(ord(" "), (255, 255, 255), (0, 0, 100)),
-   light=(ord(" "), (255, 255, 255), (130, 110, 50)),
+   dark=(ord("#"), (100, 100, 100), (0, 0, 0)),
+   light=(ord("#"), (200, 200, 200), (0, 0, 0)),
)
down_stairs = new_tile(
    walkable=True,
    transparent=True,
-   dark=(ord(">"), (0, 0, 100), (50, 50, 150)),
-   light=(ord(">"), (255, 255, 255), (200, 180, 50)),
+   dark=(ord(">"), (100, 100, 100), (0, 0, 0)),
+   light=(ord(">"), (200, 200, 200), (0, 0, 0)),
)
{{</ highlight >}}
{{</ diff-tab >}}
{{< original-tab >}}
<pre>floor = new_tile(
    walkable=True,
    transparent=True,
    <span class="crossed-out-text">dark=(ord(" "), (255, 255, 255), (50, 50, 150)),</span>
    <span class="crossed-out-text">light=(ord(" "), (255, 255, 255), (200, 180, 50)),</span>
    <span class="new-text">dark=(ord("."), (100, 100, 100), (0, 0, 0)),</span>
    <span class="new-text">light=(ord("."), (200, 200, 200), (0, 0, 0)),</span>
)
wall = new_tile(
    walkable=False,
    transparent=False,
    <span class="crossed-out-text">dark=(ord(" "), (255, 255, 255), (0, 0, 100)),</span>
    <span class="crossed-out-text">light=(ord(" "), (255, 255, 255), (130, 110, 50)),</span>
    <span class="new-text">dark=(ord("#"), (100, 100, 100), (0, 0, 0)),</span>
    <span class="new-text">light=(ord("#"), (200, 200, 200), (0, 0, 0)),</span>
)
down_stairs = new_tile(
    walkable=True,
    transparent=True,
    <span class="crossed-out-text">dark=(ord(">"), (0, 0, 100), (50, 50, 150)),</span>
    <span class="crossed-out-text">light=(ord(">"), (255, 255, 255), (200, 180, 50)),</span>
    <span class="new-text">dark=(ord(">"), (100, 100, 100), (0, 0, 0)),</span>
    <span class="new-text">light=(ord(">"), (200, 200, 200), (0, 0, 0)),</span>
)</pre>
{{</ original-tab >}}
{{</ codetab >}}

_Note: If you haven't completed [part 11](../../part-11/) yet, just ignore the `down_stairs` tile type._

The tile types are now represented by `.` and `#`, and the colors are a lighter gray if the tile is in the field of view, and a darker gray if it's outside of it.

After these changes, the game will look like this:

![Traditional Look](/images/traditional-look.png)

_Note: Screenshot taken from a version of the game after part 13_

You should experiment with different looks for your game, based on what you think is visually appealing. Adjust colors, change symbols, and modify the UI to your heart's content!
