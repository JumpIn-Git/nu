def main [] {
    let script_dir = $env.CURRENT_FILE | path dirname
    let path = $script_dir | path join prayer_times.toml
    if not ($path | path exists) {
        notify-send "Error" $"($path) not found."
        return
    }

    loop {
        let now = date now
        let db = open $path
        let idx = $now | format date "%d/%m/%Y"
        let data = $db | get -o $idx

        if ($data | is-empty) {
            notify-send "Error" $"Outdated or corrupt TOML. Missing date index: ($idx)"
            exit 1
        }

        let today_parsed = [fajr sunrise dhuhr asr maghrib isha] | each {|k|
            mut time_str = $data | get $k -o
            if ($time_str | is-empty) {
                notify-send "Error" $"($idx) is missing ($k)"
                exit 1
            }

            if $time_str == "-----" { $time_str = "00:00" }

            mut prayer_time = null
            if $time_str == "Bright" {
                if $k == "fajr" {
                    let sunrise_dt = $data.sunrise | into datetime
                    $prayer_time = $sunrise_dt - 1.5hr
                } else if $k == "isha" {
                    let maghrib_dt = $data.maghrib | into datetime
                    $prayer_time = $maghrib_dt + 1.5hr
                } else {
                    notify-send "Error" $"Unexpected 'Bright' for ($k)"
                    exit 1
                }
            } else {
                $prayer_time = $time_str | into datetime
            }

            { name: $k, time: $prayer_time }
        }

        let next = $today_parsed | where {|p| $p.time > $now } | sort-by time | first

        if ($next | is-empty) {
            let isha_time = $today_parsed | where name == "isha" | first | get time
            let duration_since_isha = $now - $isha_time | format duration min
            let tomorrow_string = ($now + 1day) | format date "%Y-%m-%dT00:01:00"
            let sleep_duration = ($tomorrow_string | into datetime) - $now

            notify-send "Prayer Tracker" $"Isha was ($duration_since_isha) ago. Sleeping until tomorrow."
            sleep $sleep_duration
            continue
        }

        let diff = $next.time - $now

        if $diff > 15min {
            sleep ($diff - 15min)
            notify-send "Prayer Reminder" $"15 minutes remaining for ($next.name)!"
            sleep 15sec
        } else {
            notify-send "Prayer Urgent" $"($diff | format duration min) remaining for ($next.name)! Pray now."
            sleep ($diff + 5sec)
        }
    }
}
