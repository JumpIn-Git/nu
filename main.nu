def main [] {
    let now = date now
    let db = open prayer_times.toml

    let next = [0 1] | each {|i|
        let d_obj = $now + ($i * 1day)
        let d = $d_obj | format date "%d/%m/%Y"
        let data = $db | get -o $d
        if ($data | is-empty) { return }

        [fajr sunrise dhuhr asr maghrib isha] | each {|k|
            mut v = $data | get $k
            if $v == "-----" { $v = "00:00" } # Wierd visual bug

            # Combine date + time so it's unambiguous
            let t_str = if $v == "Bright" { if $k == "fajr" { $data.sunrise } else { $data.maghrib } } else { $v }
            mut t = $"($d) ($t_str)" | into datetime -f "%d/%m/%Y %H:%M"

            # Adjust for "Bright" offset
            if $v == "Bright" { if $k == "fajr" { $t -= 1.5hr } else { $t += 1.5hr } }

            {name: $k, time: $t}
        }
    } | flatten | filter { $in.time > $now } | sort-by time | first

    if ($next | is-empty) {
        notify-send "No prayer times found" "prayer_times.toml is corrupt or outdated."
        return
    }

    let remaining = $next.time - $now
    if $remaining > 15min {
        print $remaining - 15 min
        sleep ($remaining - 15min)
        notify-send $"Pray ($next.name)!" "15 minutes remaining"
    } else {
        let m = $remaining // 1min
        let s = ($remaining mod 1min) // 1sec
        let mmss = $"($m):($s | fill -w 2 -c '0' -a right)"
        notify-send $"Pray ($next.name) now!" $"($mmss) left!"
        sleep $remaining
    }
}
