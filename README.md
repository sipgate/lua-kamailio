# lua-kamailio
A library to replace the monolithic Kemi example file, making it testable

##  State of the project

This project is currently in an early alpha stage. It was created as a proof of concept for Kamailioworld 2018 showing how to develop Kamailio routing logic the test driven way.

It aims to replace the example KEMI lua file. The original can be found here: [Kamailio KEMI example config](https://github.com/kamailio/kamailio/blob/master/misc/examples/kemi/kamailio-basic-kemi-lua.lua) 

Currently, only `ksr_request_route()` and all functions called by it have been replaced. The other functions are just a copy from the example file.

## Installation

To install the library, simply type:
```make install```

You may have to fix some permissions first. On Debian, this should work, if you are in group `staff`.

After the installation of the library, please install the file `src/kamailio-basic-kemi-lua.lua` to the desired location. Then change the appropriate modparam for `app_lua` to point to the installed file.

Now restart your Kamailio.