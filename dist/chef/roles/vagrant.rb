name "vagrant"
description "role for recognizer testing vbox"
run_list(
  "recipe[recognizer::default]"
)
