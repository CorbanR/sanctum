{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  ruby = ruby_2_7;
  rubygems = (rubygems.override { ruby = ruby; });

# Below inputs should be enough to build nokogiri from source
in mkShell rec {
  name = "sanctum";
  buildInputs = [
    autoconf
    bash-completion
    bison
    bzip2
    cmake
    docker-compose
    gcc
    gdbm
    git
    libffi
    libiconv
    libxml2
    libxslt
    libyaml
    ncurses
    openssl
    pkgconfig
    readline
    ruby
    zlib
  ];

  shellHook = ''
    mkdir -p .gems
    export GEM_HOME=$PWD/.gems
    export GEM_PATH=$GEM_HOME
    export PATH=$GEM_HOME/bin:$PATH

    for p in ''${buildInputs}; do
      if [ -d "$p/share/bash-completion" ]; then
        XDG_DATA_DIRS="$XDG_DATA_DIRS:$p/share"
      fi
    done

    source ${bash-completion}/etc/profile.d/bash_completion.sh
  '';
}
