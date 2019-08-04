(mod: (import <nixpkgs> {}).callPackage mod {})
({ pkgs, lib }:
with pkgs.callPackage ./lib.nix {};
with { T = pkgs.callPackage ./types.nix {}; };
let

result = {
    atl = atl;
    curse = curse;
};

minecraft = rec {
    LAUNCHER_META_MINECRAFT = "https://launchermeta.mojang.com";
    index = parse (T.VersionManifest) (fetchImpure "${LAUNCHER_META_MINECRAFT}/mc/game/version_manifest.json");
    versions = lib.groupBy' (acc: it: it) null (it: it.id) index.versions;
    __functor = self: version: {
        manifest = parse (T.MinecraftVersion) (fetchImpure versions.${version}.url);
    };
};

atl = rec {
    __functor = self: fetchPack;

    DOWNLOAD_SERVER = "https://download.nodecdn.net/containers/atl";
    indexManifest = parse (types.listOf T.Pack) (fetchImpure "${DOWNLOAD_SERVER}/launcher/json/packsnew.json");
    safe = replaceAll "[^A-Za-z0-9]" "";
    ref = packName: version: "${safe packName}_${safe version}";
    index = let
        f = pack: it: { name = ref pack.name it.version; value = (fetchPack pack.name it.version).out; };
        l = (builtins.concatMap (pack: let
            versions = builtins.map (f pack) pack.versions;
            result = versions;
        in result) indexManifest);
    in builtins.listToAttrs l;
    fetchPack = packName: version:
    if (lib.strings.hasInfix "\\u" packName) then builtins.trace "Skipping (unsupported unicode name): ${packName}" { manifest."$error" = packName; out = null; }
    else rec {
        manifest = builtins.trace "Fetching (${DOWNLOAD_SERVER}/packs/${safe packName}/versions/${version}/Configs.json): ${packName}"
            (parse (T.Version) (fetchImpure "${DOWNLOAD_SERVER}/packs/${safe packName}/versions/${version}/Configs.json"));
        out = if (manifest == null) then null else _build {
            name = "${safe packName}_${safe version}";
            manifest = manifest;
            config = fetchImpure "${DOWNLOAD_SERVER}/packs/${safe packName}/versions/${version}/Configs.zip";
        };
    };
    _build = { name, manifest, config }: let
        mc = minecraft manifest.minecraft;
        mcLibraries = builtins.filter (it: it.downloads.artifact != null) mc.manifest.libraries;
        libraries = builtins.filter (it: it.server != null) (if manifest.libraries != null then manifest.libraries else []);
        mods = builtins.filter (it: it.server != false) (if (manifest.mods != null) then manifest.mods else []);
        vanillaServerJar = "minecraft_server.${manifest.minecraft}.jar";
        serverJar = builtins.foldl' (acc: it: {
            forge = it.file;
        }.${it.type} or acc) vanillaServerJar mods;
    in if (mc.manifest.downloads.server == null) then builtins.trace "Skipping (no minecraft_server for ${manifest.minecraft}): ${name}" null
    else pkgs.runCommand name {
        preferLocalBuild = true;
        allowSubstitutes = false;
        buildInputs = with pkgs; [ unzip zip ];
        passAsFile = [ "LaunchServer_bat" "LaunchServer_sh" ];
        LaunchServer_bat =
        ''
            @ECHO OFF

            :: When setting the memory below make sure to include the amount of ram letter. M = MB, G = GB. Don't use 1GB for example, it's 1G ::

            :: This is 64-bit memory ::
            set memsixtyfour=2G

            :: This is 32-bit memory - maximum 1.2G ish::
            set memthirtytwo=1G

            :: Don't edit past this point ::

            if $SYSTEM_os_arch==x86 (
              echo OS is 32
              set mem=%memthirtytwo%
            ) else (
              echo OS is 64
              set mem=%memsixtyfour%
            )
            java -Xmx%mem% -XX:MaxPermSize=256M -jar ${serverJar} nogui
            PAUSE
        '';
        LaunchServer_sh =
        ''
            #!/bin/bash
            java -Xmx2G -XX:MaxPermSize=256M -jar ${serverJar} nogui
        '';
    }
    ''
        mkdir $out && cd $out

        ${if config == null then "" else ''unzip "${config}"''}

        mkdir -p mods
        ${forEach mods (it: let
            jar = fetchPure { url = "${DOWNLOAD_SERVER}/${it.url}"; md5 = it.md5; };
        in {
            mods = ''cp "${jar}" "mods/${it.file}"'';
            forge = ''cp "${jar}" "${it.file}"'';
            extract = ''unzip "${jar}"'';
            dependency = "";
            ic2lib = "";
            resourcepack = "";
            mcpc = "";
            denlib = "";
            flan = "";
            decomp = "";
            shaderpack = "";
            jar = "";
            coremods = "";
        }.${it.type})}

        mkdir -p libraries
        ${forEach libraries (it: let
            jar = fetchPure { url = "${DOWNLOAD_SERVER}/${it.url}"; md5 = it.md5; };
        in ''
            mkdir -p "libraries/${dirOf it.server}"
            cp "${jar}" "libraries/${it.server}"
        '')}

        ${forEach mcLibraries (_it: let
            it = _it.downloads.artifact;
            jar = fetchPure { url = it.url; sha1 = it.sha1; };
        in ''
            echo mkdir -p "libraries/${dirOf it.path}"
            mkdir -p "libraries/${dirOf it.path}"
            echo cp "${jar}" "libraries/${it.path}"
            cp -f "${jar}" "libraries/${it.path}"
        '')}

        ${let
            it = mc.manifest.downloads.server;
            jar = fetchPure { url = it.url; sha1 = it.sha1; };
        in ''
            cp "${jar}" ${vanillaServerJar}
        ''}

        cp $LaunchServer_batPath LaunchServer.bat
        cp $LaunchServer_shPath LaunchServer.sh
        chmod +x LaunchServer.sh
    '';
};

curse = rec {
    __functor = self: projectID: _fetchPack projectID;

    CURSE_API_URL = "https://addons-ecs.forgesvc.net/api/v2";
    _fetchAddonFile = projectID: fileID: let
        manifest = parse (types.unspecified) (fetchImpure "${CURSE_API_URL}/addon/${toString projectID}/file/${toString fileID}");
        in {
            manifest = manifest;
            out = fetchImpure manifest.downloadUrl;
        };
    _fetchPack = projectID: let
        packManifest = parse (types.unspecified) (fetchImpure "${CURSE_API_URL}/addon/${toString projectID}");
        fileID = toString packManifest.defaultFileId;
        file = _fetchAddonFile projectID fileID;
        zip = builtins.trace "Fetching (${file.manifest.downloadUrl}): ${packManifest.name}" file.out;
        config = pkgs.runCommand packManifest.slug {
            preferLocalBuild = true;
            allowSubstitutes = false;
            buildInputs = with pkgs; [ unzip ];
        } ''
            mkdir -p $out
            cd $out
            unzip ${zip}
        '';
        manifest = parse (types.unspecified) "${config}/manifest.json";
        in {
            manifest = manifest;
            out = pkgs.runCommand packManifest.slug {
                preferLocalBuild = true;
                allowSubstitutes = false;
            } ''
                mkdir $out && cd $out

                cp -r "${config}/overrides/." .

                mkdir -p mods
                ${forEach manifest.files (it: let
                    jar = _fetchAddonFile it.projectID it.fileID;
                in ''
                    cp "${jar.out}" "mods/${jar.manifest.fileName}"
                '')}
            '';
        };
};

in result)
