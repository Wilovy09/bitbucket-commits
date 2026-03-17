def main [range?: string] {

    let work_repo = "/Users/computadora/Dev/adquiere/api"
    let activity_repo = "/Users/computadora/Dev/adquiere/github-log"

    let map_file = $"($activity_repo)/sync-map.json"

    let authors = [
        "Emiliano Maldonado Garza"
        "wilovy"
    ]

    # cargar mapa existente
    let synced = (
        if ($map_file | path exists) {
            open $map_file
        } else {
            []
        }
    )

    # determinar rango
    let today = (date now | format date "%Y-%m-%d")

    let since = (
        if $range == null {
            $today
        } else if $range == "hoy" {
            $today
        } else if $range == "all-time" {
            "1970-01-01"
        } else if ($range | str contains "..") {
            ($range | split row ".." | get 0)
        } else {
            $range
        }
    )

    let until = (
        if $range == null {
            $today
        } else if $range == "hoy" {
            $today
        } else if $range == "all-time" {
            $today
        } else if ($range | str contains "..") {
            ($range | split row ".." | get 1)
        } else {
            $range
        }
    )

    print $"Sync commits desde ($since) hasta ($until)"

    # leer commits del repo de trabajo
    let commits = (
        do {
            cd $work_repo
            git log --since $since --until $until --pretty=format:'%H|%an|%ad|%s' --date=iso
        }
        | lines
        | parse "{hash}|{author}|{date}|{message}"
        | where {|row| $authors | any {|a| $a == $row.author }}
        | where {|row| not ($synced | any {|s| $s == $row.hash })}
        | reverse
    )

    if ($commits | length) == 0 {
        print "No hay commits nuevos"
        return
    }

    cd $activity_repo

    mut new_synced = $synced

    for $c in $commits {

        let date = $c.date
        let msg = $"($c.message)"

        $new_synced = ($new_synced | append $c.hash)
        $new_synced | save -f $map_file

        print $"creating commit ($date)"

        with-env {GIT_AUTHOR_DATE: $date, GIT_COMMITTER_DATE: $date} {
            git add $map_file
            git commit -m $msg
        }
    }

    git push

    print $"Synced commits: ($commits | length)"
}
