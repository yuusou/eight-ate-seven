# eight-ate-seven
CentOS 7 to 8 upgrade scripts

## What this script does:

1. It creates a "Minimal" install of CentOS 8 in the new_root diretory;
1. It copies over only the essential files to this install;
1. It pivots / to this new directory
1. It obliterates everything you have in /;
1. It copies everything in this temporary directory to /;
1. It pivots back to /;
1. It obliterates the temporary directory.

## Install:

```bash
git clone https://github.com/yuusou/eight-ate-seven.git
cp 887{,_p1,_p2}.sh /usr/local/bin/
chmod +x /usr/local/bin/887{,_p1,_p2}.sh
```

## Usage:

```bash
/usr/local/bin/887.sh /8 # or some other, temporary directory you wish to use.
```

## Notes:

* SELinux **needs** to be disabled first.
* This hasn't been tested in the wild.
* To see further use cases (such as running a pre-script script or a post-command, run `/usr/local/bin/887.sh` without arguments.
