file.create("/Users/maciejnasinski/Documents/rdaradar/cran_top_results.txt")
con <- file("/Users/maciejnasinski/Documents/rdaradar/cran_top_results.txt", "a")
write(sprintf("Package, File, Status, GitHub"), con)

top_cran_pacs <- vapply(jsonlite::read_json('http://cranlogs.r-pkg.org/top/last-week/100')$downloads, function(x) x$package, character(1)) # rownames(available.packages())

for (pac in top_cran_pacs) {
  print(pac)

  has_data <- try({
    readLines(sprintf("https://github.com/cran/%s/tree/master/data", pac))
  }, silent = TRUE)

  if (inherits(download, "try-error"))  {
    write(sprintf("%s, %s, %s, %s", pac, NA, 0, NA), con, append = TRUE)
    next
  }

  base_url <- "https://cran.r-project.org/src/contrib"
  version <- pacs::pac_last(pac)
  d_url <- sprintf("%s/%s_%s.tar.gz", base_url, pac, version)
  temp_tar <- tempfile(fileext = ".tar.gz")
  download <- try({
    suppressWarnings(utils::download.file(d_url, destfile = temp_tar, quiet = TRUE))
  }, silent = TRUE)

  if (inherits(download, "try-error")) {
    result <- structure(list(), package = pac, version = version)
  } else {
    temp_dir <- tempdir()
    utils::untar(temp_tar, exdir = temp_dir)
    ll <- list.files(file.path(temp_dir, pac), pattern = ".rda$", recursive = TRUE, full.names = TRUE)
    if (length(ll)) {
      for (f in ll) {
        status <- system(sprintf('podman run --rm -v "%s:/unsafe.rda" rdaradar', f))
        base_name <- basename(f)
        github_source <- sprintf("https://raw.githubusercontent.com/cran/%s/%s/data/%s", pac, version, base_name)
        write(sprintf("%s, %s, %s, %s", pac, base_name, status, github_source), con, append = TRUE)
      }
    } else {
      write(sprintf("%s, %s, %s, %s", pac, NA, 0, NA), con, append = TRUE)
    }

  }
  unlink(temp_tar)
}

# Check results
dat <- read.csv("cran_top_results.txt")
dat[dat$Status == 1, ]
