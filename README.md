
<!--#echo json="package.json" key="name" underline="=" -->
crypto-at-rest-util-pmb
=======================
<!--/#echo -->

<!--#echo json="package.json" key="description" -->
Utilities for storing data encrypted.
<!--/#echo -->



`luks-with-keyfile`
-------------------

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
create it in a secure temporary directory¹ on a secure temporary file system²,
and symlink to it if needed.

<small>

¹ Be aware of the usual attacks on temporary files
(read permissions, race conditions on create, still-open file handles, …)
and avoid them.
The `mktemp` command and `mkdir`'s `--mode=0700` option can help you.
<br>² Depending on your swap settings and threat model,
a regular `tmpfs` in your RAM may be secure enough.
On Ubuntu, `systemd` should have created
a personal `tmpfs` just for you in `/run/user/$UID`.

</small>



`openssl-enc-file-with-keyfile`
-------------------------------

```text
openssl-enc-file-with-keyfile secret.key foo.txt     bar.zip       # encrypt
openssl-enc-file-with-keyfile secret.key foo.txt.enc bar.zip.enc   # decrypt
```

Whether to encrypt or decrypt is chosen based on whether the filename
ends in `.enc`.






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
