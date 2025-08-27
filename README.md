# Doto
A primitive CLI tool telling you what to do.

Given a list of activites that regularly need to be done and their frequencies, Doto assigns a schedule and prints out, what tasks are assigned for today.

The name comes from either "**Do** **to**day" or the anagram of "Todo", up to you.

## Usage
You are meant to edit the source code. Think of it as a [suckless](https://suckless.org) program. The business logic is done at compile-time and thus, the program only prints at runtime, making it very efficient.

The program expects an array of tuples, for example:

```zig
const CONFIG = [_]Entry{
    .{ "Read a book",   1, 2 },
    .{ "Clean",         1, 7 },
    .{ "Learn Italian", 3, 7 },
    .{ "Code"           2, 4 }
};
```

The first tuple item is the name of activity itself. The latter numbers
are the frequency described as a fraction. In this example, you would want to

- read every other day
- clean weekly
- learn Italian thrice a week
- code twice every four days

To see the tasks for today, just call

```sh
doto
```

To see the entire schedule, use

```sh
doto list
```
