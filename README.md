# mc-aceph-dl

A minecraft modpack downloader for use on headless servers

# example

```bash
nix build -f default.nix atl.JourneytotheCore_192
```

# advanced example

```bash
pack=$(nix-build default.nix -A atl.JourneytotheCore_192 --no-out-link)
out=$PWD/server

mkdir -p $out
cd $out
mkdir full state tmp 

sudo mount -t overlay -o lowerdir=$pack,upperdir=$out/state,workdir=$out/tmp none $out/full

cd $out/full

sudo chown -R $(id -u):$(id -g) ./mods/ ./config/ ./world/
chmod -R +w ./mods/ ./config/ ./world/

sh LaunchServer.sh
```

Mojang requires accepting [the Minecraft EULA](https://account.mojang.com/documents/minecraft_eula). To accept:


```bash
EULA=TRUE
if [ "$EULA" != "" ]; then
  if [ ! -e eula.txt ]; then
    echo "#$(date)" > eula.txt
    echo "eula=$EULA" >> eula.txt
  fi
fi
```