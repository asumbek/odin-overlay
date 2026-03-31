use std/log

#-| TODO: Make part of the program that downloads the archive to be async (use jobs)

const compiler_manifest_file = path self ./manifests/odin.toml
const ols_manifest_file = path self ./manifests/ols.toml

## Nushell's datetime type is so weird
let minimum_release_date = "2026-01-01" | into datetime

let compiler_manifest_versions = open $compiler_manifest_file | columns | where $it != "latest"
let ols_manifest_versions = open $ols_manifest_file | columns | where $it != "latest"

do {
    if (which gh | is-empty) {
        error make "gh cli is required for generating the manifest files"
    }

    if (which nix |is-empty) or (which nix-prefetch-url | is-empty) {
        error make "nix must be installed for generating the manifest files"
    }
}

export-env {
    $env.NU_LOG_FORMAT = "%ANSI_START%] %MSG%%ANSI_STOP%"
    $env.NIX_CONFIG = r##'
        # not sure if we need flakes
        extra-experimental-features = nix-command flakes
    '##
}

def async-each [
    mapper,
]: list<any> -> list<any> {
    let inputs = $in
    let max_messages = $inputs | length
    let current_id = job id

    $inputs
      | each {|v|
          job spawn {
              do $mapper $v | job send $current_id
          }
        }

    mut messages_now = 0
    mut unsorted_results = []
    loop {
        if $messages_now == $max_messages {
            return $unsorted_results
        }
        let result = job recv
        $messages_now += 1
        $unsorted_results ++= [$result]
    }

    []
}

def getNarHashOfArchiveURL [archive_url: string]: nothing -> record {
    log info $"Getting hash for ($archive_url)"

    let store_path = nix-prefetch-url --print-path --unpack $archive_url | split row "\n" | last
    let nar_hash = nix hash path --sri --type sha256 $store_path
    {
        url: $archive_url,
        hash: $nar_hash,
    }
}

def pullExpectedReleases [repo: string, versions: list<string> = []]: nothing -> list<record> {
    def toDate [name: string]: nothing -> datetime {
        $name
          | str replace "dev-" ""
          | $in + "-01"
          | into datetime
    }

    log info $"Pulling releases from ($repo)"

    gh api $"/repos/($repo)/releases"
      | from json
      | where prerelease == false
      | where (toDate $it.name) >= $minimum_release_date
      | where name not-in $versions
}

def generateCompilerManifest [releases: list<record>]: nothing -> record {
    if $releases == [] {
        return {}
    }

    let transform = {|release|
        let version_manifest = {
            ($release.name): (
                $release.assets
                | where name =~ "(linux|macos).+(amd64|arm64)"
                | async-each {|asset| getNarHashOfArchiveURL $asset.browser_download_url }
            )
        }
        $version_manifest
    }

    let latest_version = $releases | last | get name
    let manifest = $releases
                     | async-each $transform
                     | reduce {|it, acc| $it | merge $acc }

    $manifest | upsert latest ($manifest | get $latest_version)
}

def generateOlsManifest [releases: list<record>]: nothing -> record {
    if $releases == [] {
        return {}
    }

    let transform = {|release|
        let version_manifest = {
            ($release.name): (
                $release.assets
                | where name =~ "(x86_64|arm64).+(linux|darwin)"
                | async-each {|asset| getNarHashOfArchiveURL $asset.browser_download_url }
            )
        }
        $version_manifest
    }

    let latest_version = $releases | last | get name
    let manifest = $releases
                     | async-each $transform
                     | reduce {|it, acc| $it | merge $acc }

    $manifest | upsert latest ($manifest | get $latest_version)
}

const odin_repo = "odin-lang/Odin"
const ols_repo = "DanielGavin/ols"

def main [] {
    log info "Generating manifest for Odin compiler"

    let compiler_manifest = pullExpectedReleases $odin_repo $compiler_manifest_versions
                              | generateCompilerManifest $in

    if ($compiler_manifest | is-not-empty) {
        let $compiler_manifest_content = $compiler_manifest
                                           | to toml
                                           | [$in (open --raw $compiler_manifest_file)]
                                           | str join "\n"
        $compiler_manifest_content | save --force $compiler_manifest_file
    }

    log info "Generating manifest for OLS/Odinfmt"

    let ols_manifest = pullExpectedReleases $ols_repo $ols_manifest_versions
                         | generateOlsManifest $in

    if ($ols_manifest | is-not-empty) {
        let $ols_manifest_content = $ols_manifest
                                      | to toml
                                      | [$in (open --raw $ols_manifest_file)]
                                      | str join "\n"
        $ols_manifest_content | save --force $ols_manifest_file
    }

    log info "Done!"
}
