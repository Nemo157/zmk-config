default:
    @just --list --unsorted

config := absolute_path('config')
build := absolute_path('build')
out := absolute_path('firmware')

# parse build.yaml and filter targets by expression
_parse_targets $expr:
    #!/usr/bin/env bash
    attrs="[.board, .shield]"
    filter="(($attrs | map(. // [.]) | combinations), ((.include // {})[] | $attrs)) | join(\",\")"
    echo "$(yq -r "$filter" build.yaml | grep -v "^," | grep -i "${expr/#all/.*}")"

# build firmware for single board & shield combination
_build_single $board $shield *west_args:
    #!/usr/bin/env bash
    set -euo pipefail
    artifact="${shield:+${shield// /+}-}${board}"
    build_dir="{{ build / '$artifact' }}"

    echo "Building firmware for $artifact..."
    west build -s zmk/app -d "$build_dir" -b $board {{ west_args }} -- \
        -DZMK_CONFIG="{{ config }}" ${shield:+-DSHIELD="$shield"}

    if [[ -f "$build_dir/zephyr/zmk.uf2" ]]; then
        mkdir -p "{{ out }}" && cp "$build_dir/zephyr/zmk.uf2" "{{ out }}/$artifact.uf2"
    else
        mkdir -p "{{ out }}" && cp "$build_dir/zephyr/zmk.bin" "{{ out }}/$artifact.bin"
    fi

# build firmware for matching targets
build expr *west_args:
    #!/usr/bin/env bash
    set -euo pipefail
    targets=$(just _parse_targets {{ expr }})

    [[ -z $targets ]] && echo "No matching targets found. Aborting..." >&2 && exit 1
    echo "$targets" | while IFS=, read -r board shield; do
        just _build_single "$board" "$shield" {{ west_args }}
    done

clean:
    rm -rf {{ build }} {{ out }}

clean-all: clean
    rm -rf .west zmk

init:
    west init -l config
    west update
    west zephyr-export

list:
    @just _parse_targets all | sed 's/,$//' | sort | column

update:
    west update
