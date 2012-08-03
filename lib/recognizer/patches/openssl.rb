if RUBY_PLATFORM == "java"
  require "openssl"

  module OpenSSL
    module SSL
      remove_const(:VERIFY_PEER)
      const_set(:VERIFY_PEER, VERIFY_NONE)
    end
  end
end
