{pkgs ? null} @ args:
let
  pinnedNixpkgsSrc = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/f1f038331f538550072acd8845f2138de23cb401.tar.gz";
    # Get this info from the output of: `nix-prefetch-url --unpack $url` where `url` is the above.
    sha256 = "1y5gnbikhyk7bfxqn11fk7y49jad9nlmaq1mr4qzj6fnmrh807js";
  };

  pinnedNixpkgs = import pinnedNixpkgsSrc { config = {}; };

  pkgs = if args ? "pkgs" then args.pkgs else pinnedNixpkgs;
in

with pkgs;

let
  mono = mono6;
  scriptcs = stdenv.mkDerivation rec {
    version = "0.17.1";
    pname = "scriptcs";

    src = fetchNuGet {
      baseName = "scriptcs";
      version = "${version}";
      sha256 = "011caqndm84vywyy68i0yap6qm4axv41i41lyrv184chrnrsrr2w";
      outputFiles = [ "*" ];
    };

    nativeBuildInputs = [
      makeWrapper
    ];

    buildInputs = [
      mono
    ];

    installPhase = ''
      mkdir -p $out
      cp -r "./lib" "$out/lib"

      mkdir $out/bin
      makeWrapper "${mono}/bin/mono" "$out/bin/${pname}" --add-flags "$out/lib/dotnet/scriptcs/tools/scriptcs.exe"
    '';

    dontStrip = true;
  };

  dotnetCoreCombined = with dotnetCorePackages; combinePackages [
    sdk_3_1
    sdk_3_0
    sdk_2_1
  ];

in

mkShell {
  name = "dotnet-env";
  buildInputs = [
    (with dotnetCorePackages; combinePackages [
      sdk_3_1
      sdk_3_0
      sdk_2_1
    ])
    dotnetPackages.Nuget
    mono
    fsharp
    dotnetPackages.NUnit
    gtk-sharp-2_0
    gnome-sharp
    # monodevelop
    msbuild
    scriptcs
  ];

  # Allow us to use dotnet tools such as dotnet ef.
  shellHook = ''
    export "DOTNET_ROOT=${dotnetCoreCombined}"
    export "PATH=$HOME/.dotnet/tools:$PATH"
  '';
}
