spider
======
Explore a web application and test linked ressources.
```
   _____ _____ _____ _____  ______ _____
  / ____|  __ \_   _|  __ \|  ____|  __ \
 | (___ | |__) || | | |  | | |__  | |__) |
  \___ \|  ___/ | | | |  | |  __| |  _  /
  ____) | |    _| |_| |__| | |____| | \ \
 |_____/|_|   |_____|_____/|______|_|  \_\
                  :
                  :
       ,,         :         ,,
       ::         :         ::
,,     ::         :         ::     ,,
::     ::         :         ::     ::
 '::.   '::.      :      .::'   .::'
    '::.  '::.  _/~\_  .::'  .::'
      '::.  :::/     \:::  .::'
        ':::::(       ):::::'
               \ ___ /
         .:::::/`   `\:::::.
       .::'   .:\o o/:.   '::.
     .::'   .::  :":  ::.   '::.
   .::'    ::'   ' '   '::    '::.
  ::      ::             ::      ::
  ^^      ::             ::      ^^
          ::             ::
          ^^             ^^
```

## Why ?
Test a webapp, hunt for 404.

## Design
The script is split around 3 modules:
* spider: User interface, can launch other modules & configure output.
* web: Return linked ressources on a given URL (also img, css, js).
* prober: Test a URL and return HTTP code, and timer.

## Beta / Proof
This script is still in beta.


## Participate !
If you find it useful, and would like to add your tips and tricks in it,
feel free to fork this project and fill a __Pull Request__.

## Licence
The project is GPLv3.
