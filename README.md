# VisionEval

VisionEval is a model system and supporting software framework for building
collaborative disaggregate strategic planning models. These models can support
scenario planning and a variety of "what-if" analyses.

**NOTE ON WEBSITE**: The VisionEval website can be found at
<https://VisionEval.github.io>

There are basic instructions on the website for installing VisionEval from
recent releases. We are moving to a new installation process which greatly
simplifies the installation. Details of that installation framework are
presented below.

The new installation and current version of VisionEval is presently found in the
[VisionEval-4 repository on Github](https://github.com/VisionEval/VisionEval-4).
See the repository details below, especially if you planning to do development
work on VisionEval.

The `development` branch of this repository (VisionEval-4) will be the basis for
development of new features and fixes to VisionEval. To use it, fork this
repository, work on a branch departing from `development` and lodge a pull
request when you think your work is ready for review. Be sure to pull the
`development` branch into your new branch before placing the pull request -
we'll reject the request if it's not making changes to the HEAD of
`development`.

The older VisionEval repositories should be considered obsolete (and will
gradually be marked as such).

If you have questions, please contact info at visioneval.org. If you think you
found a bug, please create an issue explaining in as much detail as possible
what you were trying to do (including files or code to reproduce the issue),
what happened when you were trying to do it, and why you think what happened is
an error (that is, tell us what you think SHOULD have happened).

## Documentation

Documentation for the VisionEval models is online at
[https://visioneval.github.io/docs](https://visionveal.github.io/docs)

That documentation is gradually being updated to reflect the VisionEval-4
installer. It remains current for running VisionEval models, but instructions
for building and rebuilding packages are still under construction. The
information on installing and building below should enable you to build updated
packages (including updating PUMS or PowertrainsAndFuels fleet penetration
tables).

## Release Installation

You can retrieve the current binary release of VisionEval by running the
installation script as described here (and on the website).

Start your selected version of R (using the built-in RGui or RStudio, either
will work), then copy the following line into your R console:

```R
source(ve.url<-"https://visioneval.github.io/assets/install/VE4-install.R")
```

Currently, VisionEval will run on any R version in the 4.4.x or 4.5.x series.

### Optional HDF5 datastore support

VisionEval uses the `RD` datastore backend by default and does not require
Bioconductor. To use the optional `H5` backend, first install its package in R:

```R
install.packages("BiocManager")
BiocManager::install("rhdf5")
```

Then set `"DatastoreType": "H5"` in the model's `run_parameters.json`. If
`rhdf5` is missing, VisionEval reports this requirement when H5 functionality
is requested. Source builds that should include this optional dependency can
set `VE_INSTALL_HDF5=1` in the build environment; ordinary builds use CRAN
dependencies and only add Bioconductor when a required package needs it.

**GORY DETAIL** The most up-to-date installer scripts can be found within the
Github source tree in `sources/framework/VEStart/inst/download`, or within the
`download` folder of the installed VEStart package, which you can locate with
the R command `system.file("download",package="VEStart")`

**ADDITIONAL GORY DETAIL** The mysterious `ve.url<-` incantation enables some
tcltk dialogs (in file `VE4-UI-tcltk.R`) stored in a separate script file that
give you flexibility in using releases other than the most current, or in
downloading a snapshot of the full VisionEval code without using Git so you can
build the entire system locally. If you leave it out, you'll get a forced
installation of the latest binary release. Note that you will still want to do a
Git clone from VisionEval-4 development branch if you are planning to contribute
your developments back to the main project.

When the installation is complete, VisionEval will automatically start with your
selected runtime directory as the R working directory. Apart from the
installation, using VisionEval 4 will still work just the same as it always did
for any VisionEval 3 model. The tiny number of new features are all backward
compatible. More documentation updates will happen as significant new features
find their way into the code.

## Detailed Installation Instructions

The `ve.url<-` method (recommended) for calling the installation script gives
you a variety of choices for installation.

**1. Set VE_HOME** The first question in the full installation is where you want
to put VE_HOME (location for the VisionEval code library). Use the "Change
VE_HOME" button to open a directory finder dialog. You will have the option to
create a new folder if you like. All the stuff you will download for the
installation as well as your future installed VisionEval code will end up in
subdirectories of VE_HOME.

**GORY DETAIL** You can have VisionEval for multiple R versions in the same
VE_HOME, but you can only have one VisionEval version per R version. To update
VisionEval for a new R version, just start your new R and run the install
script, leaving it in your existing VE_HOME. If you are updating VisionEval
itself to a later release (with or without updating R), we recommend creating a
new VE_HOME just to avoid screwy version problems if you accidentally run your
model with an earlier R version.

**GORY DETAIL** If you have an existing VE installation (even one from before
VisionEval 4), it is probably safe to point the installer's VE_HOME location to
your existing VisionEval directory. However, if you have a `models` folder there
with precious information in it, you would do well to *back that information up
right now* before you do anything else.

**2. What kind of installation?** The script will then ask what kind of
installation you want to do. There are three choices:

1.  Pre-built release (Recommended). This option is the easiest way to get the
    most recent tested and packaged version. If for some reason the latest
    release doesn't work for you, you can select earlier releases in the
    subsequent dialog. The script will identify the R version that is running
    and show you the installers compatible with that R version (see below).

2.  Build from release code. This method will let you download the full code
    snapshot of the release you select and launch the VE-Bootstrap.R script that
    loads the build environment. You can then build the entire VisionEval core
    system from scratch. You will need to have
    [RTools](https://cran.r-project.org/bin/windows/Rtools/) installed. Use this
    option if you would like to build any VisionEval packages later (e.g. with
    new versions of PUMS or Powertrain and Fuel information). You do not need to
    install or know anything about Git to use this option. It gets a snapshot of
    the code and you can copy, modify it, and rebuild it to your heart's
    content. **Do NOT use this option if you expect to contribute your changes
    back to the VisionEval project.**

3.  Build from Local Clone. This method expects you to already have made a
    "clone" of the VisionEval-4 repository and it will ask you for the directory
    where you made that clone. It will then launch VE-Bootstrap.R to load the
    build environment. To make that clone, you'll need Git, you may want to fork
    the Visioneval-4 repository, and you'll need to clone either the original
    VisionEval-4 or your fork. Make a fork if you expect to send us pull
    requests.

**PRO TIP** If you only want to build one or two VisionEval packages, and you
don't want to deal with Git or building the whole system, you should install
once using the pre-build release, then do a second installation with the release
code. Copy the packages to a new location, make your changes, then before you
build anything, create a `ve-build-config.yml` file (see the instructions below)
that sets the PackageSources to the directory containing your modified packages.
Then do `ve.build()` and you're all set.

**2. Pick the Installer** Once you have picked your installation type, you'll
get a follow-up dialog that lets you pick the repository, the release, and the
specific installer (there are several types of installer, discussed below).

By default, the installer will look at the VisionEval-4 repository. You can add
your own GitHub repository using the "Add Repositories" button - but it won't
show up until you have created tagged releases in the repository with assets
built using the `ve.make.installer()` function. The release name doesn't matter,
but the asset files must have specific names for them to be recognized by the
installer.

For the release, the installer will automatically select the newest valid
release (i.e. one that has recognizable installers attached as assets).

In the third section of the dialog, you pick the specific installer type. All of
these installers will conduct a binary installation, yielding a fully-functional
VisionEval with the packages stored in the `VE_HOME/ve-lib` library. None of
these installers will let you rebuild the packages. For that, you'll need to
pick one of the source code installers (either a release snapshot or a local git
clone).

Each of the installers uses a different R mechanism for getting the VisionEval
code on your computer. The fastest installer (smallest and easiest) is the one
called **"VE-Installer-Windows"** and it will automatically be selected if there
is one available for your version of R. That installer will need to go online to
download the 150 or so R dependency packages that VisionEval requries.

Alternatively, you can download the larger **"VE-Installer-Library"** which
works like the former VisionEval-3 installer: it downloads an immense zip file
with all the VisionEval packages plus all its dependencies and just unzips that
into the `VE_HOME/ve-lib` directory for your R version. A binary release may not
be available if you're running an R version that was released within the last
couple of weeks. In that case, you can build from the release source code, or
make a local clone and build from that. Instructions for how to build from
source code are below.

Finally, you can try **"VE-Installer-Source"**, though it's really there for
future compatibility. You can't use this installer unless you have
[RTools](https://cran.r-project.org/bin/windows/Rtools/) installed on Windows.

This source package installer is intended for Macintosh or Linux. But to use it
on one of those operating systems, you'll need to do tedious iterations of
building all the VisionEval packages and all the many dependency packages. Each
build iteration will crash, asking you to install yet another operating system
package. If you keep at it relentlessly (build - crash - install missing OS
package) you will eventually end up with a working VisionEval. We are working on
automating the SystemRequirements, which will eventually make installing on
Macintosh or Linux as easy as a Windows installation (though it will require
system administrator rights, which the Windows installation does not). [The pak
package](https://pak.r-lib.org) which will provide the necessary services).

**GORY DETAIL** The "source" installer does **NOT** give you editable source -
use the "Build from Release Code" or "Build from Local Clone" installation
methods if you want to do that. This "source" installer installs R source
packages (as opposed to R binary packages), which are very different from
anything resembling what we usually think of as "source code". It will
ultimately be the preferred installer for non-Windows operating systems (once we
fully integrate the auxililary operating system packages that may be required).

**3. Proceed with Installation** Once you have picked the installer version, the
installation script will download the installer (if needed) and show a
confirmation dialog. Then it will do the installation.

If you installed one of the release packages, you should get a dialog asking you
to select the directory for your models (we call it VE_RUNTIME) and that
directory will be initialized for you with a "models" folder (if there isn't
already one there) plus updated startup files so you can start R or RStudio
directly from that runtime folder.

If you just click through the dialog, it will set VE_RUNTIME to the same folder
as VE_HOME and put your `models` folder there. We usually recommend keeping them
separate for ease of model backup, but there is a case to be made for keeping it
all together since you can then archive the model plus its results plus the code
that ran it, all in one place.

If you downloaded the release source code or selected to use a local clone, you
won't get a directly runnable VisionEval. Instead, the installer will start the
"Bootstrap" loader (see below) and you'll need to run `ve.build()` yourself to
complete the process. See the `ve.build()` instructions below.

**IMPORTANT BUILD INFORMATION** If you're doing any kind of building on Windows
from the source installer (or from clones or snapshots of VisionEval-4), you
will need first to install [RTools for your version of
R](https://cran.r-project.org/bin/windows/Rtools/).

**BUILDING ON MACINTOSH OR LINUX** On Linux or Macintosh, you'll need to ensure
you have a development version of R installed, along with the operating system
"devtools" package (including C++ and Fortan compilers and related tools). Also,
if you’re not building on Windows (i.e. you are on Macintosh or Linux), the
build will be interrupted multiple times to report missing operating system
packages necessary for building the VisionEval R dependencies, and you’ll need
to keep restarting it after you’ve installed the missing packages. We are
developing a complete list of such packages for the Mac and popular Linux
systems, and also looking at ways to automate their installation.

Be aware that building and running VisionEval requires a lot of RAM (a minimum
of 8 Gigabytes is recommended).

If you're using a Linux cloud server, you'll need something quite a bit more
capacious (and expensive) than what is usually delivered at the "low end".
Having multiple CPUs will not speed up the build process, but when you run
models, you can use additional processes to run multiple model scenarios in
parallel. But remember: 8 Gigabytes of RAM will still be needed for each
scenario you're running simultaneously.

## Issues

Please submit issues, bugs, or feature requests about VisionEval on the
[VisionEval-Dev issues page](https://github.com/VisionEval/VisionEval-4/issues).

Please submit issues with the VisionEval.org website or the documentation on the
[VisionEval.org issues
page](https://github.com/VisionEval/VisionEval.org/issues).

## For Developers: Building VisionEval

There are two avenues to building VisionEval packages from source code:

1.  From local snapshots or clones of the VisionEval-4 repository: you can build
    or rebuild individual packages or the entire system. This approach uses the
    Bootstrap builder. If you use the installer to install release code or
    attach a local clone, it will connect you to the Bootstrap builder and
    you'll need to follow the instructions here.

2.  From within a binary release installation: you can use the "Runtime
    Builder". Load the VEBuild package using `library(VEBuild)` to activate the
    build machinery. You will need to create a configuration file that
    identifies the folders that contain the packages you want to build.

    **GORY DETAIL** You don't generally want to rebuild the `VEBuild` package
    itselfusing the Runtime Builder - it should work, but if you're developing
    files for the framework you'll be happier with the Bootstrap builder.

### Bootstrap Builder

The Bootstrap Builder consists of four functions that are presented in a text
menu. Enter them as commands with suitable arguments. Each will run fine with no
arguments, but may not do exactly what you want (see details below). You'll
typically go through them in order. The remainder of this section talks about
the possible arguments (if any).

Menu: ve.setup() [optional dialog to set VE_BUILD and VE_RUNTIME] ve.build() [to
build the whole system by default, or just individual packages] ve.run() [once
built, will run VisionEval in VE_RUNTIME] ve.make.installer() [will add various
installer types to VE_BUILD/install]

ve.setup() gives you a dialog to set VE_BUILD and VE_RUNTIME in your .Renviron
file (for when you next start R from VE_HOME). That step is optional. By
default, the builder will use `VE_HOME/built` for VE_BUILD and `VE_HOME/runtime`
for VE_RUNTIME

`ve.build()` does the heavy lifting. It will look in standard places and build
everything it finds (unless you override the defaults by adding
`ve-build-config.yml` to your VE_HOME directory - see the instructions under the
Runtime Builder below).

`ve.build()` will not automatically rebuild anything. That is, if the built
package is newer than the source code it would be built from, you just get a
message that the package is already installed and nothing will happen. The
upside of that is that if you're working incrementally on a single package, you
can just re-run `ve.build()` over and over and only the changed package will get
rebuilt.

If you're working on one package, you can provide a vector of package names as
the first argument for `ve.build()`, For example, doing this:

```
ve.build( c("visioneval","VEStart","VEBuild","VEModel") )
```

would rebuild all the framework packages and not touch any of the modules, even
if they're out of date. In general, you only need to name the package if you're
"resetting" it. Otherwise, if you didn't change anything about the package, it
won't get rebuilt.

#### Resetting built packages

"Resetting" is needed to do a "deep rebuild" of a built package. Ordinarily,
ve.build() will not rebuild the package NAMESPACE, data files and R
documentation even if the package code changed, to speed up working on the
package code.

If you make data changes (e.g. to extdata) and are rebuilding the package (i.e.
an earlier version was already built by you), or if you have added @imports or
made changes to the R documentation within the package, you should add the
`reset=TRUE` option like this:

```
ve.build( c("VEPowertrainsAndFuels"), reset=TRUE)
```

In order for that instruction to work, you will first have to have built (or
have installed binaries) of all the other VE packages that VEPowertrainsAndFuels
might depend on.

You can use `reset=TRUE` all by itself to get a clean build of everything, which
is recommended prior to doing the final step, `ve.make.installer()`:

```
ve.build(reset=TRUE)
```

You don't want to do a full reset often, however, since it will take 45 minutes
to an hour (or more) to rebuild everything.

Finally, you can see what packages are available to build by using the
`listtargets=TRUE` argument to `ve.build()`. It will give you heavy details,
including each package's DESCRIPTION file. This argument is also "forward
compatible". But the current plan is to create a VEPackage type and return a
list of those, which you will be able to inspect for version information and
other tidbits, and which will print neatly as just a list of package names by
default.

```
ve.build(listtargets=TRUE)
```

`ve.run()` will start your newly built VisionEval working in the VE_RUNTIME
folder that you set earlier.

`ve.make.installer()` can be used to make the special zip files that need to be
attached to GitHub releases in order to be recognized by the VisionEval 4
installer. You probably won't want to do that unless you're planning to set up
your own repository for VE code. The use case for that would be if you made some
cool custom packages that you want to share. People would then run the
installer, choose your repository, select the release and the installer and run
the installation - whatever you give them will overwrite any existing VE package
with the same name (a bad idea) or slip your uniquely named packates into
`ve-lib` alongside the rest of their VisionEval. Obviously, there are "circle of
trust" issues, and users will want to perform due diligence before they grab
stuff from "strangers".

`ve.make.installer()` by default just builds a binary release (the standard
option) for the version of R that is running the function. To make an installer
for a different R version, you'll need to run the Bootstrap builder with that
version of R (you can't "cross-compile"). To make the other installer types you
can use one of these options:

```
ve.make.installer("win.binary")  # the default
ve.make.installer("win.library") # the VE 3 style full dependency package, pre-installed
ve.make.installer("source")      # source rather than binary packages
ve.make.installer("all")         # make all three
```

The resulting installers will have the R version encoded in their names where
relevant (the "source" type does not care about the R version), and will be
saved in the VE_BUILD/install folder.

If you want to poke around in the builder code, look at `VE-Bootstrap.R` in the
Git repository root, and also at code in the `VEBuild` package at
`sources\framework\VEBuild\inst\build-scripts`.

### The Runtime Builder (VEBuild package)

When you load VEBuild using `library(VEBuild)`, it presents you with exactly the
same menu as the Bootstrap builder, even if you just did a binary installation.
The difference is that you won't automatically have the VisionEval source code
to build, so you'll need to set up instructions about what to build.

Usually, you won't use ve.setup() with the Runtime Builder. Just go straight to
`ve.build()` and then use `ve.run()` (or restart R from your VE_RUNTIME
directory) to try it out.

**NOTE** If you intend do more than one build and run cycle, you should restart
VisionEval before doing the next build since the current builder does not reload
every VisionEval package (just the framework).

In order for `ve.build()` to do something useful, you'll need to put your
packages in a place that the builder can find. While there are places in its own
directory structure that it will look automatically, you will generally want
your own packages in a separate folder. To tell the builder about that folder,
just create a small configuration file and put it in your VE_HOME folder
(adjacent to `ve-lib`). The file should be called `ve-build-config.yml` and look
like this:

```
ve-build-config.yml:

PackageSources:               # absolute path or relative to VE_SOURCE
  - N:/My-VE-Packages         # change this to the parent of your VE package folders
  - N:/My-Special-Package     # and this might be just a single package folder with a DESCRIPTION file
```

With that file in place, `ve.build()` will recursively visit your folder and its
subfolders, looking for packages (folders with a DESCRIPTION file), it will
build them, and install them into your VisionEval library.

You'll need to define at least one folder with a VisionEval-compatible R package
(one with modules and models, just like any of the VE packages). In fact, you'll
usually create those package folders by copying an existing VE package source
code and then modifying it.

If you do make such a copy, give the folder a different name than the original
package and make sure you change the package name consistently in the package's
DESCRIPTION file.

Then do `ve.run()` to restart VisionEval and try your package out (you'll need a
model that uses it, of course).

If you want to try out the process, you can make a clone of the
VisionEval/VisionEval-Extras repository, add it to `ve-build-config.yml` and
then enter this magic instruction (because VEFHWAAV does incorrect things
managing its estimated data files):

```
Sys.setenv(VE_KEEP_R=1)
```

Once you've done that, running `ve.build()` will build and install the VEFHWAAV
and VEPopulationSim packages.

## For Developers: Submitting changes or bug requests

If you intend to submit changes back to the VisionEval project, please clone the
[VisionEval-4 repository, development
branch](https://github.com/VisionEval/VisionEval-4/tree/development). Pull
requests against this branch are welcome. Make sure you have first rebased your
pull request on the current HEAD of `development` by doing a `git pull
VisionEval-4/development` instruction and resolving any merge conflicts.

You do *NOT* need to fork the repository unless you are planning to submit
changes (pull requests) back to the VisionEval project.
