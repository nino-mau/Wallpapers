#!/usr/bin/env fish

function usage
    echo 'Usage: ./generate.fish [--override]'
    echo
    echo 'Generate Catppuccin Mocha and Latte variants of images in source/.'
    echo 'Latte outputs use the -colorful suffix. Existing files are skipped'
    echo 'unless --override is provided.'
end

argparse 'o/override' 'h/help' -- $argv
or exit 2

if set -q _flag_help
    usage
    exit 0
end

if test (count $argv) -ne 0
    usage >&2
    exit 2
end

if not command -q lutgen
    echo 'generate.fish: lutgen is not installed' >&2
    exit 127
end

set -l root_dir (path resolve (status dirname))
set -l source_dir "$root_dir/source"
set -l output_dir "$root_dir/catppuccin"

if not test -d "$source_dir"
    echo "generate.fish: source directory not found: $source_dir" >&2
    exit 1
end

mkdir -p "$output_dir"
or exit 1

set -l generated 0
set -l skipped 0

for image in "$source_dir"/*
    test -f "$image"
    or continue

    set -l extension (string lower -- (path extension "$image"))
    switch "$extension"
        case .avif .bmp .dds .exr .ff .gif .hdr .ico .jpg .jpeg .png .pnm .qoi .tga .tiff .webp
        case '*'
            continue
    end

    set -l name (path basename (path change-extension '' "$image"))

    for variant in 'catppuccin-mocha|' 'catppuccin-latte|-colorful'
        set -l parts (string split '|' "$variant")
        set -l theme $parts[1]
        set -l suffix $parts[2]
        set -l output "$output_dir/$name$suffix$extension"

        if test -e "$output"; and not set -q _flag_override
            echo "Skipping existing: $output"
            set skipped (math $skipped + 1)
            continue
        end

        echo "Generating $theme: $output"
        lutgen apply -p "$theme" -l 12 -r 12 --lum 0.7 -P -o "$output" "$image"
        or begin
            echo "generate.fish: failed to generate $output" >&2
            exit 1
        end

        set generated (math $generated + 1)
    end
end

echo "Done: $generated generated, $skipped skipped."
