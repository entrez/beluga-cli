# beluga-cli

## overview:

### usage:
`beluga-cli <command> [-is] [arguments]`

### description:
beluga-cli is a bash utility which uses [curl](https://curl.haxx.se/) - with the exception of the `ftp` command, which uses [ftp](https://www.gnu.org/software/inetutils/)\* - to efficiently manipulate files on an ftp origin server (like the one provided by beluga) and interact with the belugacdn api. it can be used to quickly accomplish, and/or as a step in the automation of, many tasks involving the manipulation of files stored on an ftp origin and accessible to the public via [belugacdn](http://www.belugacdn.com/).

\*if you are running mac os 10.13 or newer and do not have a command line ftp client installed but wish to use this command, you can install ftp by running the following [homebrew](https://brew.sh/) command: `brew install tnftp`.

### setup:
in order to get everything working correctly before you start using beluga-cli, run the command `beluga-cli setup` to define the location and credentials used for your origin, the credentials used for belugacdn, and so on.  

**caution:** your origin server username and password will be stored & transmitted as plain text, so ensure they are not used elsewhere.

if you would like to be able to run the utility by typing `beluga-cli` no matter your current location, you can add the directory which contains the file to your `$PATH` variable.

## possible flags:

**-i** : beluga-cli will invalidate the uri of any file modified by the requested operation. see [here](#origin-vs-cdn).

**-s** : the program will run silently.

each flag can only be used on certain commands. if a flag is used on a command where it is not standard, beluga-cli will generally print an error message but then ignore the flag and continue.

## possible commands:

### file manipulation:

**cp** : upload or download a file, resulting in duplicate copies at the origin and destination.  
usage: `beluga-cli cp [-is] <localpath> <cdn://uri> or <cdn://uri> <localpath> or <cdn://uri> <cdn://uri>`

**mv** : move a file to, from, or within the server, deleting the original and keeping the new copy.  
usage: `beluga-cli mv [-is] <localpath> <cdn://uri> or <cdn://uri> <localpath> or <cdn://uri> <cdn://uri>`

**rm** : delete a remote file.  
usage: `beluga-cli rm [-is] <cdn://uri>`

### navigation & file discovery:

**ftp** : log on to the origin server in an interactive ftp session.  
usage: `beluga-cli ftp`

**ls** : briefly list the contents of a directory.  
usage: `beluga-cli ls <cdn://uri>`

**ll** : list the contents of a directory plus permissions, creation date, etc.  
usage: `beluga-cli ll <cdn://uri>`

### cdn utilities:

**iv** : invalidate a file in the cdn's cache, so that another copy must be retrieved from the origin server.  
usage: `beluga-cli iv [-s] <cdn://uri>`

## brief examples:

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

4. use grep and xargs to download every image file (.png or .jp[e]g) in the dir from the previous example to a local directory named 'cdnimg', with 'cp_' prepended to each local filename:

   ```
   $ beluga-cli ls cdn://images 2> /dev/null | grep -E "\.(jpe?g|png)" | xargs -I % beluga-cli cp cdn://images/% ~/cdnimg/cp_%
   downloading: cdn://images/babypic.jpg -> ~/cdnimg/cp_babypic.jpg
   done
   downloading: cdn://images/logo.png -> ~/cdnimg/cp_logo.png
   done
   downloading: cdn://images/product.jpeg -> ~/cdnimg/cp_product.jpeg
   done
   downloading: cdn://images/product_rev3.jpeg -> ~/cdnimg/cp_product_rev3.jpeg
   done
   ```

## tips & tricks:

### help:
you can include the word `help` after any command for a quick refresher about the use of that particular command, or by itself (`beluga-cli help`) to get a general help page like this one.

### setup:
the "origin server location" in `beluga-cli setup` should include the entire path used as the origin on belugacdn. if you entered an additional path in your property's settings page on beluga, include it here. if you use beluga's origin solution, this may also include a directory with your property name (e.g. X.X.X.X/cdn.your.site/).

### remote uri formatting:
note that in all commands, remote uris should be be formatted as cdn://path. for instance, in order to download the file http://cdn.your.site/dir1/file.txt, you could run the command `beluga-cli cp cdn://dir1/file.txt ~/file.txt`. as a general rule, cdn://path/to/obj corresponds to http://cdn.your.site/path/to/obj.

### origin vs cdn:
when making changes to files on the origin server, note that the differences may not propagate to the cdn (and therefore become public) until you invalidate the existing uri of the modified file. this includes any operation on a uri that has already been used before: uploading a file to a new uri doesn't require invalidation, but deleting an existing one does.
