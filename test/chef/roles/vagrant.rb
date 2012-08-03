name "vagrant"
description "Role for testing Recognizer"
run_list("recipe[rabbitmq]", "recipe[recognizer]")

override_attributes :recognizer => {
  :librato => {
    :email => ENV["LIBRATO_EMAIL"],
    :api_key => ENV["LIBRATO_API_KEY"]
  },
  :amqp => {
    :host => "localhost"
  }
}
