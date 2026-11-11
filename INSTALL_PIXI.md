# Install VisionEval from source with Pixi

The prebuilt release assets used by the README's [Release Installation procedure](README.md#release-installation)
are Windows-focused. Linux and macOS users can install VisionEval from source
with this repository's Pixi environment, which pins R 4.5.3 and the runtime,
development, and native dependencies needed to build and run it. This guide
replaces the README Release Installation procedure for users choosing Pixi: use
the steps below instead of first running `VE4-install.R` or a Windows binary
installer.

The Pixi workspace targets Linux x86-64, macOS x86-64, and macOS Apple silicon.
The lockfile requires Linux with glibc 2.28 or newer and kernel 4.18 or newer,
or macOS 13 or newer.

## Get the source

Use the repository's `release` branch, which contains the Pixi workflow described
here.

Choose one source option below: [clone with Git](#clone-with-git) or
[download a ZIP](#download-a-zip). Complete only that option, then continue to
[Install with Pixi](#install-with-pixi).

### Clone with Git

Follow GitHub's guide to [clone a repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository),
or run:

```sh
git clone --branch release https://github.com/cities-lab/VisionEval-4.git
cd VisionEval-4
```

### Download a ZIP

Follow GitHub's guide to [download source code archives](https://docs.github.com/en/repositories/working-with-files/using-files/downloading-source-code-archives),
select the `release` branch, and extract the archive. Or download the
[release branch ZIP](https://github.com/cities-lab/VisionEval-4/archive/refs/heads/release.zip)
directly. Open a terminal in the extracted `VisionEval-4-release` folder, which
contains `pixi.toml`.

Run the Pixi commands below from the repository root (`VisionEval-4` for the
Git clone, or `VisionEval-4-release` for the ZIP).

## Install with Pixi

Install Pixi using the [official installation instructions](https://pixi.sh/latest/installation/),
then, from the VisionEval-4 repository root, run:

```sh
pixi install --locked
pixi run --locked setup
pixi run --locked r
```

`pixi run --locked setup` generates package namespaces with roxygen and installs
all runtime framework and module packages in dependency order into
`.pixi/ve-library`, then checks the attached `VEModel` runtime, default RD
datastore roundtrip, and GDAL/PROJ GeoPackage operations. Start an interactive
Pixi-managed R with `pixi run --locked r`, then use `library(VEModel)` as usual.
The first setup loads modules to regenerate their package datasets and model
estimates, so it can take a while and use substantial memory.

The Pixi profile uses the project library and excludes host R library paths,
bypassing the legacy VE bootstrap that otherwise redirects R to `ve-lib`.
To rerun only the source-level optional-datastore regression test, use
`pixi run --locked rd-smoke`.

The default environment does not automatically install packages from
`Suggests`, including `rhdf5`, BiocManager, RMariaDB, NHTS2009, and SLD. The
local VE2001NHTS data-estimation package is built as source support for
VEHouseholdTravel; it uses bundled public survey datasets. Three required
packages are pinned as SHA-256-verified CRAN source archives in
`pixi/cran-sources.lock` because matching conda-forge builds are unavailable for
the selected R/platform set: `import` 1.3.4, `jrc` 0.6.0, and `pscl` 1.5.9 on
macOS Apple silicon. The other two platforms use the conda-forge `pscl` package.

After updating dependencies with `pixi update`, review and commit the updated
`pixi.lock`, then rerun `pixi run --locked setup` to rebuild local packages and
repeat the smoke checks. Update source fallback versions and SHA-256 values
separately in `pixi/cran-sources.lock`. `pixi run --locked install` forces a
package rebuild without running verification. Building the `pscl` source
package on macOS Apple silicon requires Xcode Command Line Tools and the macOS
SDK in addition to the compiler toolchain supplied by Pixi.

Source installation and runtime checks passed on Linux. The macOS lock resolved,
but the runtime has not been tested there.

## Use RStudio with Pixi

After completing Pixi setup, follow the [Pixi RStudio integration guide](https://pixi.prefix.dev/latest/integration/editor/r_studio/)
to launch RStudio from the activated Pixi environment.
