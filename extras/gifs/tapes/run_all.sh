tapes_dir="$PWD/extras/gifs/tapes"
tapes=$(ls "$tapes_dir")

for tape in $tapes; do
    if [[ "$tape" != "run_all.sh" ]]; then
        vhs "$tapes_dir/$tape"
    fi
done
