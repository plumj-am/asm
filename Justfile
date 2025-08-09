OUTDIR := "./target"

alias b := build
alias br := build-release
alias c := clean
alias ca := clean-all
alias d := disasm
alias i := info
alias l := list
alias n := new
alias r := run
alias w := watch

# default recipe
default: 
    @just --list

# build a specific program
build project name: 
    @printf '> BUILDING: {{name}} in {{project}}/\n\n'
    @mkdir -p {{project}}/{{OUTDIR}}
    @if [ "{{project}}" = "nasm" ]; then \
        cd {{project}} && \
        nasm -Ov -f elf64 -g -F dwarf {{name}}.asm -o {{OUTDIR}}/{{name}}.o && \
        stat -c "nasm size: %s bytes" {{OUTDIR}}/{{name}}.o && \
        ld {{OUTDIR}}/{{name}}.o -o {{OUTDIR}}/{{name}} && \
        stat -c "final size: %s bytes" {{OUTDIR}}/{{name}}; \
    elif [ "{{project}}" = "fasm" ]; then \
        cd {{project}} && fasm {{name}}.asm {{OUTDIR}}/{{name}}; \
    else \
        echo "Error: project must be 'nasm' or 'fasm'"; \
        exit 1; \
    fi

# build a specific program without debug info (release, nasm only)
build-release project name:
    @if [ "{{project}}" != "nasm" ]; then \
        echo "Release build only available for nasm projects"; \
        exit 1; \
    fi
    @printf '> BUILDING RELEASE: {{name}} in {{project}}/\n\n'
    @mkdir -p {{project}}/{{OUTDIR}}
    @cd {{project}} && \
        nasm -Ox -f elf64 {{name}}.asm -o {{OUTDIR}}/{{name}}.o && \
        stat -c "nasm size: %s bytes" {{OUTDIR}}/{{name}}.o && \
        ld -s --gc-sections {{OUTDIR}}/{{name}}.o -o {{OUTDIR}}/{{name}} && \
        strip --strip-all {{OUTDIR}}/{{name}} && \
        stat -c "final size: %s bytes" {{OUTDIR}}/{{name}}

# run a specific program
run project name: (build project name)
    @printf '\n> RUNNING: {{name}} from {{project}}/\n\n'
    @{{project}}/{{OUTDIR}}/{{name}}


# clean build artifacts for a project
clean project:
    @printf '> CLEANING BUILD ARTIFACTS in {{project}}/\n'
    @rm -rf {{project}}/{{OUTDIR}}
    @if [ "{{project}}" = "nasm" ]; then \
        cd {{project}} && rm -f *.bin *.o; \
    else \
        cd {{project}} && rm -f *.bin; \
    fi

# clean both projects
clean-all:
    @printf '> CLEANING ALL BUILD ARTIFACTS\n'
    @rm -rf nasm/{{OUTDIR}} fasm/{{OUTDIR}}
    @cd nasm && rm -f *.bin *.o
    @cd fasm && rm -f *.bin

# disassemble a specific binary
disasm project name: (build project name)
    @printf '> DISASSEMBLING: {{name}} from {{project}}/\n'
    @objdump -D -S {{project}}/{{OUTDIR}}/{{name}}

# show debug info for a binary (nasm only)
debug-info project name: (build project name)
    @if [ "{{project}}" != "nasm" ]; then \
        echo "Debug info only available for nasm projects"; \
        exit 1; \
    fi
    @printf '> DEBUG INFO FOR: {{name}} from {{project}}/\n'
    @objdump -g {{project}}/{{OUTDIR}}/{{name}}
    @readelf --debug-dump=info {{project}}/{{OUTDIR}}/{{name}}

# check file information for specific binary
info project name: (build project name)
    @printf '> FETCHING FILE INFO FOR: {{name}} from {{project}}/\n'
    @file {{project}}/{{OUTDIR}}/{{name}}
    @readelf -h {{project}}/{{OUTDIR}}/{{name}}

# watch for changes and rebuild specific binary
watch project name:
    @printf '> WATCHING FOR CHANGES IN: {{project}}/{{name}}\n\n'
    @while inotifywait -q -e modify {{project}}/{{name}}.asm; do just run {{project}} {{name}}; done

# list all programs in both projects
list:
    @printf '> NASM PROGRAMS:\n'
    @cd nasm && ls -1 *.asm | sed 's/\.asm$// ; s/^/  /'
    @printf '\n> FASM PROGRAMS:\n'
    @cd fasm && ls -1 *.asm | sed 's/\.asm$// ; s/^/  /'

# create new program from template
new project name:
    @cd {{project}} && cp template.asm {{name}}.asm
    @echo "{{project}}/{{name}}" >> .gitignore
    @printf '> CREATED: {{project}}/{{name}}.asm from template\n'
    @printf '> ADDED: {{project}}/{{name}} to .gitignore\n'
