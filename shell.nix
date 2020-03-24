{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  ruby = ruby_2_7;
  rubygems = (rubygems.override { ruby = ruby; });

in mkShell rec {
  name = "sanctum";
  buildInputs = [
    bzip2
    docker-compose
    git
    libxml2
    libxslt
    openssl
    pkgconfig
    ruby
    zlib
  ];

  shellHook = ''
    #export PKG_CONFIG_PATH=${pkgs.libxml2}/lib/pkgconfig:${pkgs.libxslt}/lib/pkgconfig:${pkgs.zlib}/lib/pkgconfig

    mkdir -p .gems
    export GEM_HOME=$PWD/.gems
    export GEM_PATH=$GEM_HOME
    export PATH=$GEM_HOME/bin:$PATH
  '';
}
