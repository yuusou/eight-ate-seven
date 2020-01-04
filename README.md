# eight-ate-seven
CentOS 7 to 8 upgrade scripts

## What this script does:

1. It creates a "Minimal" install of CentOS 8 in the new_root diretory;
1. It copies over only the essential files to new_root;
1. It pivots / with new_root;
1. It obliterates everything you have in /;
1. It copies everything in new_root to /;
1. It pivots back to /;
1. It obliterates new_root.

## Install:

```bash
git clone https://github.com/yuusou/eight-ate-seven.git
```

## Usage:

```bash
bash 887.sh /8 # or some other, temporary directory you wish to use.
```

## Notes:

* SELinux **needs** to be disabled first.
* This hasn't been tested in the wild.
* To see further use cases (such as running a pre-script script or a post-command, run `bash 887.sh` without arguments.

## TODO:

- [x] Create functions for each step;
- [x] Merge all three scripts into one;
- [x] Remove need for having script in specific location;
- [ ] Fix running commands and running scripts, currently not working;
