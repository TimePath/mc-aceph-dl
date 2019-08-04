# mc-aceph-dl

A minecraft modpack downloader for use on headless servers

# example

```bash
nix build '(import ./.).atl "Journey to the Core" "1.9.2"'
nix build '(import ./.).curse 290913'
```

# advanced example

```bash
out=$PWD/server-jttc
pack=$(nix path-info '(import ./.).atl "Journey to the Core" "1.9.2"')

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