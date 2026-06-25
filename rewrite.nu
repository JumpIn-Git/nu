def main [] {
    let db = open prayer_times.toml
    let now = date now

    mut data = $db | get ($now | format date "%d/%m/%Y")% -o
    if ($data | is-empty) {
        notify-send "" "" # curropt or outdated toml
        exit 1
    }

    if $data.isha ==  "-----" {
        $data.isha = "00:00" # Wierd visual bug
    } else if $data.isha == Bright {

    }
}
