
<!--#echo json="package.json" key="name" underline="=" -->
crypto-at-rest-util-pmb
=======================
<!--/#echo -->

<!--#echo json="package.json" key="description" -->
Utilities for storing data encrypted.
<!--/#echo -->



Usage
-----

### `luks-with-keyfile`

```text
$ luks-with-keyfile /path/to/my/secrets/mydisk.key init
$ luks-with-keyfile /path/to/my/secrets/mydisk.key open
$ luks-with-keyfile /path/to/my/secrets/mydisk.key close
$ luks-with-keyfile /path/to/my/secrets/mydisk.key close --force-detach
```

Initialize/ open/ close an LVM LUKS crypto device,
guessing the device path from the key filename (path part ignored):
* `mydisk.luks` or `mydisk.disk` in the current working directory:
  May be symlinks or container files.
* `/dev/disk/by-partlabel/mydisk`: Probably a local disk partition.


#### Determine LUKS's maximum keyfile size

```text
$ cryptsetup --help | grep -Fie maximum
        Maximum keyfile size: 8192kB, Maximum interactive passphrase length 512 (characters)
```

Different GNU/Linux installations may have different values,
so make sure your keyfile will work on all devices you want to use.


#### Use a combination of keyfile(s) and/or password(s)

To construct a more complex key file,
create it on a secure temporary file system,
and symlink to it if needed.
Depending on your swap settings and threat model,
a regular `tmpfs` in your RAM may be secure enough.





Known issues
------------

* Needs more/better tests and docs.





<!--#toc stop="scan" -->

&nbsp;


License
-------
<!--#echo json="package.json" key="license" -->
ISC
<!--/#echo -->
