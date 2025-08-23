draft := if env("GITHUB_REF", "") == "refs/heads/main" { "false" } else { "true" }
revision := if draft == "true" {
  `git symbolic-ref --short HEAD 2> /dev/null || echo unknown` + "-" + `git rev-list --count HEAD` + "[" + `git rev-parse --short HEAD` + "]"
} else {
  `git rev-list --count main`
}

build: write-config
  typst compile {{justfile_directory()}}/gbctr.typ

watch: write-config
  typst watch --open xdg-open {{justfile_directory()}}/gbctr.typ

write-config:
  echo '{"draft": {{draft}}, "revision": "{{revision}}"}' > {{justfile_directory()}}/config.json
