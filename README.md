# beluga-cli

v0.7.4

## overview

### usage
`beluga-cli <command> [<options>]... [--profile=<profilename>] [--no-color] [<arguments>]`

### description
beluga-cli is a bash utility which uses [curl](https://curl.haxx.se/) - with the exception of the `ftp` command, which uses [ftp](https://www.gnu.org/software/inetutils/)\* - to efficiently manipulate files on an ftp origin server (like the one provided by beluga) and interact with the [belugacdn](http://www.belugacdn.com/) api.  it can be used to quickly and easily accomplish, and/or as a step in the automation of, many tasks involving the management of objects which fit one or both of these criteria.

\*if you are running mac os 10.13 or newer and do not have a command line ftp client installed but wish to use this command, you can install ftp by running the following [homebrew](https://brew.sh/) command: `brew install tnftp`.

### setup
if you would like to be able to run the utility by typing `beluga-cli` no matter your current location, and are unfamiliar with modifying your system `$PATH` variable or would prefer a more automated solution, you can run the included `installer.sh` script, which can also verify the status of all `beluga-cli` dependencies and warn if any are missing from your computer, in addition to several other potentially useful features (including the verification of proper file permissions, the automatic download of a new copy of `beluga-cli` if an existing local file can't be found, and the installation of a manpage accessible via `man beluga-cli`).

### configuration
in order to get everything working correctly before you start using beluga-cli, run the command `beluga-cli config` to define the location and credentials used for your origin, the credentials used for belugacdn, and so on. you will be given the choice between using an existing token for authentication with the belugacdn api or generating a new one.

note that the "origin server location" should include the entire path used as the origin on belugacdn. if you entered an additional path in your property's settings page on beluga, include it here. if you use beluga's origin solution, this may also include a directory with your property name (e.g. X.X.X.X/cdn.your.site/).

**caution:** your origin server username and password will be stored & transmitted as plain text, so ensure they are not used elsewhere.

on the other hand, although you will be prompted for your belugacdn username and password if you choose to create a new token during the setup & configuration process, these are only used once (for basic authentication, i.e. transmitted in base64) to generate the token, and are not stored anywhere.

## possible commands

### file manipulation

**cp** : copy a file to, from, or within the origin, resulting in duplicate copies at the source and destination.  
usage: `beluga-cli cp [-ips] [--no-overwrite] [--profile=<profilename>] [--no-color] <localpath> <cdn://uri> or <cdn://uri> <localpath> or <cdn://uri> <cdn://uri>`

**mv** : move a file to, from, or within the server, deleting the original and keeping the new copy.  
usage: `beluga-cli mv [-ips] [--no-overwrite] [--profile=<profilename>] [--no-color] <localpath> <cdn://uri> or <cdn://uri> <localpath> or <cdn://uri> <cdn://uri>`

**rm** : delete a remote file or directory.  
usage: `beluga-cli rm [-irs] [--profile=<profilename>] [--no-color] <cdn://uri>`

**mkdir** : create a new directory on the origin server.  
usage: `beluga-cli mkdir [-ps] [--profile=<profilename>] [--no-color] <cdn://uri>`

### navigation & file discovery

**ftp** : log on to the origin server in an interactive ftp session.  
usage: `beluga-cli ftp [--profile=<profilename>]`

**ls** : briefly list the contents of a directory.  
usage: `beluga-cli ls [-s] [--profile=<profilename>] [--no-color] <cdn://uri>`

**ll** : list the contents of a directory plus permissions, creation date, etc.  
usage: `beluga-cli ll [-s] [--profile=<profilename>] [--no-color] <cdn://uri>`

### cdn utilities

**iv** : invalidate a file in the cdn's cache, so that another copy must be retrieved from the origin server.  
usage: `beluga-cli iv [-s] [--profile=<profilename>] [--no-color] <cdn://uri>`

### internal tools

**update** : check whether the version of beluga-cli running is the latest available; if a newer version exists, update the local file.  
usage: `beluga-cli update [--no-color]`

**help** : get help about a command, or display the general help page (similar to this readme) if no command is specified.  
usage: `beluga-cli [<command>] help [--no-color]`

**config** : set up server/CDN credentials and other information; see the ['configuration' section](#configuration) for more details.  
usage: `beluga-cli config`

## possible options:

**-i** : will invalidate the uri of any file modified by the requested operation. see [origin vs cdn](#origin-vs-cdn) for why this may be useful.

**-p** : create all intermediate directories in the specified path (the destination path, when used with mv or cp commands) as needed.

**-r** : delete all contents of the specified directory recursively.

**-s** : the program will suppress output to stderr while maintaining normal output to stdout (e.g. the directory listing generated by ls).

**--profile=<_profilename_\>** : create and switch between any number of named profiles. see the [profiles](#profiles) section below.

**--no-overwrite** : the operation will fail if the destination (whether local or on the origin) refers to an already-existing file.

**--no-color** : output will not include the usual text decoration (color/bolding/etc).

each option can only be used on certain commands (see [above](#possible-commands)). if an option is used on a command where it is not standard, beluga-cli will generally print an error message but then ignore the option and continue.

## brief examples

the following examples should help to demonstrate what normal input and output look like, as well as suggest some common applications which might be useful.

1. invalidate a remote uri so that it is deleted from the belugacdn cache and must be retrieved again from the origin:

   ```
   $ beluga-cli iv cdn://public/main.html
   invalidating: http://cdn.example.com/public/main.html
   request pending
   ```

2. replace an online file with an updated local copy and request invalidation so the update becomes visible on the cdn:

   ```
   $ beluga-cli cp -i work/progressreport.pdf cdn://reports/2018.pdf
   uploading: work/progressreport.pdf -> cdn://reports/2018.pdf
   done
   invalidating: http://cdn.example.com/reports/2018.pdf
   request pending
   ```

3. look through the contents of a directory and download a particular file:

   ```
   $ beluga-cli ls cdn://images/
   listing contents of cdn://images
   success:
   edited
   babypic.jpg
   logo.png
   product.jpeg
   product_rev3.jpeg
   $ beluga-cli cp cdn://images/logo.png ~/Downloads
   downloading: cdn://images/logo.png -> ~/Downloads/logo.png
   done
   ```

4. use grep and xargs to download every image file (.png or .jp[e]g) in the dir from the previous example to a local directory named 'cdnimg' - which is created in the process if it didn't previously exist - with 'cp_' prepended to each local filename:

   ```
   $ beluga-cli ls cdn://images 2> /dev/null | grep -E "\.(jpe?g|png)" | xargs -I % beluga-cli cp -p cdn://images/% ~/cdnimg/cp_%
   downloading: cdn://images/babypic.jpg -> ~/cdnimg/cp_babypic.jpg
   done
   downloading: cdn://images/logo.png -> ~/cdnimg/cp_logo.png
   done
   downloading: cdn://images/product.jpeg -> ~/cdnimg/cp_product.jpeg
   done
   downloading: cdn://images/product_rev3.jpeg -> ~/cdnimg/cp_product_rev3.jpeg
   done
   ```

## notes

### profiles
including `--profile=<profilename>` after the primary command allows you to switch between any number of named profiles. to set up a new profile, run `beluga-cli config --profile=<profilename>` (with the name you want to use filled in). once you have set up the credentials for a particular profile, it can be used for any other command.

### remote uri formatting
note that in all commands, remote uris should be be formatted as cdn://path. for instance, in order to download the file http://cdn.your.site/dir1/file.txt, you could run the command `beluga-cli cp cdn://dir1/file.txt ~/file.txt`. as a general rule, cdn://path/to/obj corresponds to http://cdn.your.site/path/to/obj.

### origin vs cdn
when making changes to files on the origin server, note that the differences may not propagate to the cdn (and therefore become public) until you invalidate the existing uri of the modified file. this includes any operation on a uri that has already been used before: uploading a file to a new uri doesn't require invalidation, but deleting an existing one does.
