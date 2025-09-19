# Learning Assembler

This repository contains programs and notes I have taken while learning
assembly. There are 2 versions of every program for both the FASM and NASM
assemblers.

I'd really appreciate constructive criticism and feedback on anything seen in
the repository so I can improve.

My notes can be found in [./NOTES.md](./NOTES.md).

## Notes:

- All programs that do not have a number suffix e.g. `word_count` are the
  original versions of the programs and will not be changed.
- The number suffixed programs are my improved versions such as `word_count_2`
  and will be incrementally improved as time goes on.
- At most one program will have 2 versions, the original and the improved.
- Inside the comment header of the improved programs, there will be a list of
  changes compared to the original version.

## Usage:

There is a nix flake with all the necessary tooling in
[./flake.nix](./flake.nix).

You can use it with `nix develop` or add a `.envrc` file with `use flake`
inside.

Otherwise you will need to install `just`, `fasm` and `nasm`. If you want to use
"hot reloading" via the `watch` recipe, you will also need `inotify-tools`.

Check the [./Justfile](./Justfile) for recipes you can use. You may have to
adjust them depending on your OS and CPU architecture. I am on x64 Linux so it
is tailored to that.

You can see all recipes by running `just` alone.

Generally the recipes follow this pattern:

```Justfile
just <RECIPE> <ASSEMBLER> <PROGRAM> <ARGS>
```

For example, to run the `word_count` NASM project:

```Justfile
just run nasm word_count ./README.md
```

All programs contain a comment header with additional information and verbose
notes commented throughout.

## License

```
The MIT License (MIT)

Copyright (c) 2025-present PlumJam <git@plumj.am>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
