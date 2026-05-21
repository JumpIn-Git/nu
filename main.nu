def main [] {
    let now = date now
    let all_data = open prayer_times.toml
    
    let prayers = [0, 1] | each {|offset|
        let d_obj = $now + ($offset * 1day)
        let d = $d_obj | format date "%d/%m/%Y"
        let data = $all_data | get -i $d
        if ($data | is-empty) { return [] }
        
        let keys = [fajr sunrise dhuhr asr maghrib isha]
        $keys | each {|k|
            let val = $data | get -i $k
            if ($val | is-empty) or $val == "-----" { return null }
            
            let time = if $val == "Bright" {
                if $k == "fajr" {
                    ($"($d) ($data.sunrise)" | into datetime -f "%d/%m/%Y %H:%M") - 1.5hr
                } else if $k == "isha" {
                    ($"($d) ($data.maghrib)" | into datetime -f "%d/%m/%Y %H:%M") + 1.5hr
                } else {
                    null
                }
            } else {
                $"($d) ($val)" | into datetime -f "%d/%m/%Y %H:%M"
            }
            
            if $time != null {
                {key: $k, time: $time}
            } else {
                null
            }
        }
    } | flatten | compact | filter {|p| $p.time > $now } | sort-by time

    if ($prayers | is-empty) {
        return
    }

    let next = $prayers | first
    let remaining = $next.time - $now

    if $remaining > 15min {
        sleep ($remaining - 15min)
        notify-send $"Pray ($next.key)!" "15 minutes remaining"
    } else {
        notify-send $"Pray ($next.key) now!" $"($remaining) left!"
        sleep $remaining
    }
}
