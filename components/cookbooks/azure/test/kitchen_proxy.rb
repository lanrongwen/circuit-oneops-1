require "kitchen/verifier/busser"

module Kitchen
  module Verifier
    class Busser < Kitchen::Verifier::Base
      def busser_env
        root = config[:root_path]
        gem_home = gem_path = remote_path_join(root, "gems")
        gem_cache = remote_path_join(gem_home, "cache")

        [
            shell_env_var("BUSSER_ROOT", root),
            shell_env_var("GEM_HOME", gem_home),
            shell_env_var("GEM_PATH", gem_path),
            shell_env_var("GEM_CACHE", gem_cache),
            shell_env_var("WORKORDER", ENV['WORKORDER'])
        ].join("\n")
            .tap { |str| str.insert(0, reload_ps1_path) if windows_os? }
      end
    end
  end
end