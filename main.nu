def main [] {
    print "This script will overwrite existing update files (KoboRoot.tgz,upgrade/,manifest.md5sum)"
    [yes no] | input list "Do you want to continue?" | if $in == no { exit }

    let mounts = lsblk --json -o LABEL,MOUNTPOINT | from json | get blockdevices | where label == KOBOeReader
    if ($mounts | is-empty) {
        print "No eReader found"
        exit 1
    }
    let koboMount = $mounts | first | get mountpoint
    let koboRoot = $koboMount | path join .kobo

    print "Preparing NickelMenu"
    let nm = http get api.github.com/repos/pgaskin/NickelMenu/releases/latest
    | get assets
    | first
    | if $in.name != KoboRoot.tgz {
        print "Unexpected NickelMenu release, update script"
        exit 1
    } else { http get $in.browser_download_url }

    print "Checking for a firmware update"
    let versionData = $koboMount | path join .kobo version | open | split row ","
    let fwApi = $"http://api.kobobooks.com/1.0/UpgradeCheck/Device/($versionData.5)/kobo/($versionData.2)/N0"
    | http get $in --headers [Accept application/xml]
    let UpgradeType = $fwApi | get content | where tag == UpgradeType | first | get content | get context | first
    if UpgradeType != None and ([yes no] | input list $"UpgradeType is ($UpgradeType), do you want to update your eReader?") == yes {
        let fwZip = $fwApi | get content | where tag == UpgradeURL | first | get content.content | first | http get $in
        $fwZip | bsdtar -x -C $koboRoot manifest.md5sum upgrade/ # We will merge KoboRoot.tgz with nm

        let merged = mktemp -d
        $fwZip | bsdtar -x -O KoboRoot.tgz | bsdtar -x -C $merged
        $nm | bsdtar -x -C $merged

        tar --format=gnu -czf ($koboRoot | path join KoboRoot.tgz) -C $merged .
    } else {
        $nm | save ($koboRoot | path join KoboRoot.tgz)
    }

    print "Preparing Plato"
    let plato = http get api.github.com/repos/baskerville/plato/releases/latest
    | get assets
    | first
    | if $in.name !~ '^plato-(?:\d+\.)*\d+\.zip$' {
        print "Unexpected Plato release, update script"
        exit 1
    } else { http get $in.browser_download_url }
    let platoPath = $koboMount | path join .adds plato
    rm -rf $platoPath
    mkdir $platoPath
    $plato | bsdtar -x -C $platoPath
}
