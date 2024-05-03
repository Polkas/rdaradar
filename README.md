

# rdaradar (RDA Radar)

Sanity check R data files before use.

## Why?

“Researchers” from HiddenLayer took advantage of the hype cycle before
RSAC 2024 to [broadcast a non-vulnerability in
R](https://hiddenlayer.com/research/r-bitrary-code-execution/).

They (IMO) inappropriately received a CVE assignment (CVE-2024-27322)
for, what is, expected behavior in the deserialization of R objects via
standard mechanisms. I am not shocked as I am also of the opinion
that the current state of “CVE” in general is “busted”.

There is no mention of this CVE in the release of R 4.4.0 which *did*
modify the behavior of deserializing certain objects within R data
files. I am going to make an assumption the change was made because of
this CVE.

However, the “weakness” is by no means closed.

[Konrad Rudolph](https://mastodon.social/@klmr#.) and [Iakov
Davydov](https://mstdn.science/@idavydov) did some ace cyber sleuthing
and [figured out other ways R data file deserialization can be
abused](https://mastodon.social/@klmr/112360501388055184). Please take a
moment and drop a note on Mastodon to them saying “thank you”. This is
excellent work. We need more folks like them in this ecosystem.

> Please note that *this is all expected behavior*. R has many
> “defaults” that can get one into trouble. Seven years ago I [made this
> example repo/package](https://github.com/hrbrmstr/rpwnd/) to
> demonstrate some of the more overt “gotchas” that can lead to
> potential unwanted behavior. Back in 2019, the fine folks at rOpenSci
> [also let us poke at making R a bit
> safer](https://ropensci.org/blog/2019/04/09/commcall-may2019/#resources).

I’m including one of their sample “calc” exploit payloads since hiding
it really doesn’t do much to determined attackers.

When you `load()` an R data file directly into your R session into the
global environment, the object will, well, *load there*. So, if it has
an object named `print` that’s going to be in your global environment
and get called when `print()` gets called. Lather/rinse/repeat for any
other object name. It should be pretty obvious how this could be abused.

A tad more insidious is what happens when you quit R. By default, on
`quit()`, unless you specify otherwise, that function invocation will
also call `.Last()` if it exists in the environment. This functionality
exists in the event things need to be cleaned up. One “nice” aspect of
`.`-prefixed R objects is that they’re hidden by default from the
environment. So, you may not even notice if an R data file you’ve loaded
has that defined. (You likely do not check what’s loaded anyway.)

It’s also possible to create custom R objects that have their own
“finalizers” (ref `reg.finalizer`), which will also get called by
default when the objects are being destroyed on quit.

There are also likely other ways to trigger unwanted behavior.

If you want to see how this works, start R from RStudio, the command
line, or R GUI. Then, load `exploit.rda`. Then, quit R/RStudio/R GUI
(this will be less dramatic on linux, but the demo should still be
effective).

The main takeaway from this is DO NOT LOAD ANY R DATA FILES YOU DID NOT
CREATE OR TRUST THE PROVENANCE OF.

If you *must* take in untrusted R data files, keep reading.

## What (Does This Do)?

You can either run the `check.R` script directly or via the Docker
container version of it. It will load the specified R data file into a
“quarantined” environment, then list out the objects in the environment,
compare them to known, potentially dangerous ones, and also print out
the contents of any functions defined.

It will exit with a status code of `1` if anything dangerous is found.

It’s a work-in-progress (I’m really short on time this week), and filing
issues with suggestions for improvement (then, PRs) would be most
welcome.

## Usage: Bare Script (POTENTIALLY DANGEROUS)

``` bash
$ Rscript check.R /path/to/RDATAFILE
```

Example output for the `exploit.rda` file:

    -----------------------------------------------
    Loading R data file in quarantined environment…
    -----------------------------------------------

    Loading objects:
      .Last
      quit

    -----------------------------------------
    Enumerating objects in loaded R data file
    -----------------------------------------

    .Last : function (...)  
     - attr(*, "srcref")= 'srcref' int [1:8] 1 13 6 1 13 1 1 6
      ..- attr(*, "srcfile")=Classes 'srcfilecopy', 'srcfile' <environment: 0x12cb25f48> 
    quit : function (...)  
     - attr(*, "srcref")= 'srcref' int [1:8] 1 13 6 1 13 1 1 6
      ..- attr(*, "srcfile")=Classes 'srcfilecopy', 'srcfile' <environment: 0x12cb25f48> 

    ------------------------------------
    Functions found: enumerating sources
    ------------------------------------

    Checking `.Last`…

    !! `.Last` may execute arbitrary code on your system under certain conditions !!

    `.Last` source:
    {
        cmd = if (.Platform$OS.type == "windows") 
            "calc.exe"
        else if (grepl("^darwin", version$os)) 
            "open -a Calculator.app"
        else "echo pwned\\!"
        system(cmd)
    }


    Checking `quit`…

    !! `quit` may execute arbitrary code on your system under certain conditions !!

    `quit` source:
    {
        cmd = if (.Platform$OS.type == "windows") 
            "calc.exe"
        else if (grepl("^darwin", version$os)) 
            "open -a Calculator.app"
        else "echo pwned\\!"
        system(cmd)
    }

While this should theoretically be “safe”, it is much safer to run this
in a Docker container.

## Usage: Docker

Build:

``` bash
$ docker build -t rdaradar:0.1.0 -t rdaradar:latest .  
```

Run:

``` bash
$ docker run --rm -v "$(pwd)/exploit.rda:/unsafe.rda" rdaradar 
```

Example output for the `exploit.rda` file:

    -----------------------------------------------
    Loading R data file in quarantined environment…
    -----------------------------------------------

    Loading objects:
      .Last
      quit

    -----------------------------------------
    Enumerating objects in loaded R data file
    -----------------------------------------

    .Last : function (...)  
     - attr(*, "srcref")= 'srcref' int [1:8] 1 13 6 1 13 1 1 6
      ..- attr(*, "srcfile")=Classes 'srcfilecopy', 'srcfile' <environment: 0xaaaac3a30568> 
    quit : function (...)  
     - attr(*, "srcref")= 'srcref' int [1:8] 1 13 6 1 13 1 1 6
      ..- attr(*, "srcfile")=Classes 'srcfilecopy', 'srcfile' <environment: 0xaaaac3a30568> 

    ------------------------------------
    Functions found: enumerating sources
    ------------------------------------

    Checking `.Last`…

    !! `.Last` may execute arbitrary code on your system under certain conditions !!

    `.Last` source:
    {
        cmd = if (.Platform$OS.type == "windows") 
            "calc.exe"
        else if (grepl("^darwin", version$os)) 
            "open -a Calculator.app"
        else "echo pwned\\!"
        system(cmd)
    }


    Checking `quit`…

    !! `quit` may execute arbitrary code on your system under certain conditions !!

    `quit` source:
    {
        cmd = if (.Platform$OS.type == "windows") 
            "calc.exe"
        else if (grepl("^darwin", version$os)) 
            "open -a Calculator.app"
        else "echo pwned\\!"
        system(cmd)
    }

## TODO

- [ ] Better write-up
- [ ] More checks
