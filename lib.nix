{ pkgs, lib }: let
inherit (lib) types mkOption;
in rec {
    replaceAll = needle: replacement: haystack: let
        found = builtins.match ".*(${needle}).*" haystack;
        next = replaceAll needle replacement (builtins.replaceStrings found [""] haystack);
        in (if (found != null) then next else haystack);

    types = lib.types;

    submodule = name: options: { _name = name; } // (types.submodule {
        options = lib.mapAttrs (k: v: if (lib.isOption v) then v else (mkOption { type = v; })) options;
    });

    optional = T: mkOption {
        type = types.nullOr T;
        default = null;
    };

    parse = T: file: let
        text = builtins.readFile file;
        result = if (text == "") then null else builtins.fromJSON (builtins.readFile json);
        attrs = builtins.fromJSON (builtins.replaceStrings ["\\u"] ["\\\\u"] text);
        attrsKey = T._name or "attrs";
        conf = (lib.evalModules {
            modules = [{ options = { ${attrsKey} = mkOption { type = T; }; }; config = { ${attrsKey} = attrs; }; }];
        }).config.${attrsKey};
        json = pkgs.runCommand "jsonTypeCheck" {
            preferLocalBuild = true;
            allowSubstitutes = false;
            passAsFile = [ "json" ];
            json = builtins.toJSON conf;
        } "cat $jsonPath | ${pkgs.jq}/bin/jq 'del(.. | ._module?)' > $out";
        in result;

    forEach = list: f: lib.concatMapStringsSep "\n" f list;

    jsonFile = data: pkgs.runCommand "jsonFile" {
        preferLocalBuild = true;
        allowSubstitutes = false;
        passAsFile = [ "json" ];
        json = builtins.toJSON data;
    } "cat $jsonPath | ${pkgs.jq}/bin/jq > $out";

    fetchImpure = url: builtins.fetchurl url;

    fetchPure = { url, md5 ? null, sha1 ? null }: let
        result = if (availableHashes == [])
            then builtins.trace "Skipping (no available hashes): ${url}" ""
            else drv;
        hashes = {
            ${if md5 != null then "md5" else null} = md5;
            ${if sha1 != null then "sha1" else null} = sha1;
        };
        availableHashes = lib.attrNames hashes;
        outputHashAlgo = lib.head availableHashes;
        outputHash = hashes.${outputHashAlgo};
        drv = derivation rec {
            builder = "builtin:fetchurl";

            # New-style output content requirements.
            inherit outputHashAlgo outputHash;
            outputHashMode = "flat";

            name = (replaceAll "[^A-Za-z0-9]" "") (baseNameOf url);

            inherit url;
            executable = false;
            unpack = false;

            system = "builtin";

            # No need to double the amount of network traffic
            preferLocalBuild = true;
            allowSubstitutes = false;

            impureEnvVars = [
                # We borrow these environment variables from the caller to allow
                # easy proxy configuration.  This is impure, but a fixed-output
                # derivation like fetchurl is allowed to do so since its result is
                # by definition pure.
                "http_proxy" "https_proxy" "ftp_proxy" "all_proxy" "no_proxy"
            ];

            # To make "nix-prefetch-url" work.
            urls = [ url ];
        };
        in result;
}