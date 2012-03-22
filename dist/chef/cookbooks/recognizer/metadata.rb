maintainer       "Sean Porter"
maintainer_email "portertech@gmail.com"
license          "All rights reserved"
description      "Installs/Configures Recognizer"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.0.3"

# available @ http://community.opscode.com/cookbooks/git
depends "git"

# available @ http://community.opscode.com/cookbooks/java
depends "java"

%w[
  ubuntu
  debian
].each do |os|
  supports os
end
