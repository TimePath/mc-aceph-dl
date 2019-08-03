{ pkgs }:
with pkgs.callPackage ./lib.nix {};
rec {
    # https://github.com/ATLauncher/ATLauncher/blob/master/src/main/java/com/atlauncher/data/Pack.java
    Pack = submodule "Pack" {
        id = types.ints.positive;
        position = types.ints.positive;
        name = types.str;
        type = types.enum [ "public" "private" "semipublic" ];
        code = optional types.str;
        versions = types.listOf PackVersion;
        devVersions = types.listOf PackVersion;
        createServer = types.bool;
        leaderboards = types.bool;
        logging = types.bool;
        featured = types.bool;
        hasDiscordImage = types.bool;
        description = types.str;
        discordInviteURL = optional types.str;
        supportURL = optional types.str;
        websiteURL = optional types.str;
    };
    PackVersion = submodule "PackVersion" {
        version = types.str;
        hash = optional types.str;
        minecraft = types.str;
        canUpdate = optional types.bool;
        isRecommended = optional types.bool;
        hasLoader = optional types.bool;
        hasChoosableLoader = optional types.bool;
    };
    # https://github.com/ATLauncher/ATLauncher/blob/master/src/main/java/com/atlauncher/data/json/Version.java
    Version = submodule "Version" {
        deletes = optional types.unspecified;
        enableCurseIntegration = optional types.bool;
        enableEditingMods = optional types.bool;
        extraArguments = optional types.unspecified;
        libraries = optional (types.listOf Library);
        mainClass = optional types.unspecified;
        memory = optional types.ints.positive;
        messages = optional types.unspecified;
        minecraft = types.str;
        mods = optional (types.listOf Mod);
        permgen = optional types.ints.positive;
        version = types.str;
        loader = optional types.unspecified;
        colours = optional types.unspecified;
        warnings = optional types.unspecified;
        noConfigs = optional types.bool;
        caseAllFiles = optional types.unspecified;
        java = optional types.unspecified;
        actions = optional types.unspecified;
    };
    Library = submodule "Library" {
        download = types.enum [ "server" ];
        file = types.str;
        filesize = optional types.ints.unsigned;
        force = optional types.bool;
        md5 = types.str;
        server = optional types.str;
        url = types.str;
        path = optional types.unspecified;
    };
    Mod = submodule "Mod" {
        authors = optional (types.listOf types.str);
        client = optional types.bool;
        description = types.str;
        donation = optional types.str;
        download = types.enum [ "server" "browser" "direct" ];
        file = types.str;
        filesize = optional types.ints.unsigned;
        force = optional types.bool;
        hidden = optional types.bool;
        library = optional types.bool;
        md5 = optional types.str;
        name = types.str;
        optional = optional types.bool;
        recommended = optional types.bool;
        selected = optional types.bool;
        server = optional types.bool;
        serverSeparate = optional types.bool;
        serverOptional = optional types.unspecified;
        type = types.enum [
            "jar"
            "dependency"
            "depandency"
            "forge"
            "mcpc"
            "mods"
            "plugins"
            "ic2lib"
            "denlib"
            "flan"
            "coremods"
            "extract"
            "decomp"
            "millenaire"
            "texturepack"
            "resourcepack"
            "texturepackextract"
            "resourcepackextract"
            "shaderpack"
        ];
        url = types.str;
        version = types.str;
        website = types.str;
        curse_id = optional types.ints.positive;
        curse_file_id = optional types.ints.positive;
        extractFolder = optional types.str;
        extractTo = optional types.str;
        group = optional types.str;
        depends = optional (types.listOf (types.str));
        colour = optional types.unspecified;
        warning = optional types.unspecified;
        linked = optional types.unspecified;
        filePrefix = optional types.unspecified;
        decompFile = optional types.unspecified;
        decompType = optional types.unspecified;
    };
    # https://github.com/ATLauncher/ATLauncher/blob/master/src/main/java/com/atlauncher/data/minecraft/VersionManifest.java
    VersionManifest = submodule "VersionManifest" {
        latest = submodule "VersionManifest.latest" {
            release = types.str;
            snapshot = types.str;
        };
        versions = types.listOf (VersionManifestVersion);
    };
    VersionManifestVersion = submodule "VersionManifestVersion" {
        id = types.str;
        releaseTime = types.str;
        time = types.str;
        type = types.str;
        url = types.str;
    };
    MinecraftVersion = submodule "MinecraftVersion" {
        assetIndex = submodule "assetIndex" {
            id = types.str;
            sha1 = types.str;
            size = types.ints.positive;
            totalSize = types.ints.positive;
            url = types.str;
        };
        assets = types.str;
        downloads = submodule "downloads" (let
            T = submodule "downloads.download" {
                sha1 = types.str;
                size = types.ints.positive;
                url = types.str;
            };
        in {
            client = T;
            server = optional T;
            windows_server = optional T;
        });
        id = types.str;
        libraries = types.listOf (submodule "MinecraftVersion.libraries" {
            downloads = submodule "MinecraftVersion.libraries.downloads" {
                artifact = optional (submodule "MinecraftVersion.libraries.downloads.artifact" {
                    path = types.str;
                    sha1 = types.str;
                    size = types.ints.positive;
                    url = types.str;
                });
                classifiers = optional types.unspecified;
            };
            name = types.str;
            extract = optional (submodule "MinecraftVersion.libraries.extract" {
                exclude = types.listOf (types.str);
            });
            natives = optional (submodule "MinecraftVersion.libraries.natives" {
                linux = optional types.str;
                osx = optional types.str;
                windows = optional types.str;
            });
            rules = optional (types.listOf (submodule "MinecraftVersion.libraries.rules" {
                action = types.str;
                os = optional types.unspecified;
            }));
        });
        logging = optional types.unspecified;
        mainClass = types.str;
        arguments = optional types.unspecified;
        minecraftArguments = optional types.str;
        minimumLauncherVersion = types.ints.positive;
        releaseTime = types.str;
        time = types.str;
        type = types.enum [ "release" "old_beta" "old_alpha" ];
    };
}