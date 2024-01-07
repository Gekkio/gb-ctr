draft := if env("GITHUB_REF", "") == "refs/heads/main" { "false" } else { "true" }
revision := if draft == "true" {
  `git symbolic-ref --short HEAD` + "-" + `git rev-list --count HEAD` + "[" + `git rev-parse --short HEAD` + "]"
} else {
  `git rev-list --count main`
}
config := "{\"draft\": true, \"revision\": \"main-127[0dc4a5]\"}"

build: write-config
  typst compile {{justfile_directory()}}/gbctr.typ

watch: write-config
  typst watch {{justfile_directory()}}/gbctr.typ

write-config:
  echo '{"draft": {{draft}}, "revision": "{{revision}}"}' > {{justfile_directory()}}/config.json
