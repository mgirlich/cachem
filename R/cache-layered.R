#' Compose any number of cache objects into a new, layered cache object
#'
#' @param ... Cache objects to compose into a new, layered cache object.
#' @inheritParams cache_disk
#'
#' @return A layered caching object, with class `cache_layered`.
#' @examples
#'
#' # Make a layered cache from a small memory cache and large disk cache
#' m <- cache_mem(max_size = 100 * 1024^2)
#' d <- cache_disk(max_size = 2 * 1024^3)
#' cl <- cache_layered(m, d)
#' @export
cache_layered <- function(..., logfile = NULL) {
  caches <- list(...)
  logfile_ <- logfile

  # ============================================================================
  # Logging
  # ============================================================================
  # This needs to be defined first, because it's used in initialization.
  log_ <- function(text) {
    if (is.null(logfile_)) return()

    text <- paste0(format(Sys.time(), "[%Y-%m-%d %H:%M:%OS3] cache_layered "), text)
    cat(text, sep = "\n", file = logfile_, append = TRUE)
  }

  get <- function(key) {
    log_(paste0("Get: ", key))
    value <- NULL
    # Search down the caches for the object
    for (i in seq_along(caches)) {
      value <- caches[[i]]$get(key)

      if (!is.key_missing(value)) {
        log_(paste0("Get from ", class(caches[[i]])[1], "... hit"))
        # Set the value in any caches where we searched and missed.
        for (j in seq_len(i-1)) {
          caches[[j]]$set(key, value)
        }
        break
      } else {
        log_(paste0("Get from ", class(caches[[i]])[1], "... miss"))
      }
    }

    value
  }

  set <- function(key, value) {
    for (cache in caches) {
      cache$set(key, value)
    }
  }

  exists <- function(key) {
    for (cache in caches) {
      if (cache$exists(key)) {
        return(TRUE)
      }
    }
    FALSE
  }

  keys <- function() {
    unique(unlist(lapply(caches, function (cache) {
      cache$keys()
    })))
  }

  remove <- function(key) {
    for (cache in caches) {
      cache$remove(key)
    }
  }

  reset <- function() {
    for (cache in caches) {
      cache$reset()
    }
  }

  get_caches <- function() {
    caches
  }

  structure(
    list(
      get = get,
      set = set,
      exists = exists,
      keys = keys,
      remove = remove,
      reset = reset,
      get_caches = get_caches
    ),
    class = c("cache_layered", "cachem")
  )
}

