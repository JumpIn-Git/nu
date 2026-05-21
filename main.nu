def main [] {
    let today = date now | format date "%d/%m/%Y"
    mut data = open prayer_times.toml | get $today

    if $data.fajr == Bright {
        $data.fajr = $data.sunrise | into datetime | $in - 1.5hr
    }
    if $data.isha == Bright {
        $data.isha = $data.maghrib | into datetime | $in + 1.5hr
    }

    for prayer in ($data | transpose key value) {
        if $prayer.key == hijri {continue}
        let time = $prayer.value | into datetime

        if (date now) > $time {
            continue
        }

        let remaining = $time - (date now)
        if $remaining > 15min {
            $remaining - 15min | sleep $in
            notify-send $"Pray ($prayer.key)!" "15 minutes remaining"
        } else {
            notify-send $"Pray ($prayer.key) now!" $"($remaining) left!"
            sleep $remaining
        }
        break
    }
}
