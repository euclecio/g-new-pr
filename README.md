Git New Pull Request
--------------------

This script will create a new pull request

How to use
----------

If you want to use this script you have to set the environment variables bellow on `~/.bashrc` (or another file as your choice):
```sh
export GITHUB_TOKEN=tokenValue
#OR
export GITHUB_USER=username
export GITHUB_PASSWORD=userpass
```

Usage:

```sh
cd /path/your-project
g-new-pr {args}

```

```sh
    --help, -h    Script helper
```

Install
-------

To install into your machine run the commands bellow:

```sh
curl -sL https://raw.githubusercontent.com/euclecio/g-new-pr/master/g-new-pr.sh -o /usr/local/bin/g-new-pr
chmod a+x /usr/local/bin/g-new-pr
```
If it didn't work, try run it with `sudo`
