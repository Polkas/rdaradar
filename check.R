exit_val <- 0

args <- commandArgs(trailingOnly = TRUE)

quarantine <- new.env(parent = emptyenv())

load(args[1], envir = quarantine, verbose = FALSE)

c(
  ".Last",
  ".Last.sys",
  "quit",
  "print",
  "q"
) -> dangerous_functions

funs <- lsf.str(quarantine, all.names = TRUE)

if (length(funs) > 0) {
  inter_funs <- intersect(funs, dangerous_functions)
  if (isTRUE(length(inter_funs) > 0)) {
    cat("dangerous functions\n")
    cat(inter_funs, sep = ";")
    exit_val <- 1
  }
}

quit(save = "no", status = exit_val, runLast = FALSE)
