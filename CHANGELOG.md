# Changelog

## 1.2.1 (2019-05-24)

* Enhancements
  * Allow custom file_system backend options

## 1.2.0 (2018-11-07)

* Enhancements
  * Support Phoenix 1.4 transport changes

## 1.1.7 (2018-10-10)

* Enhancements
  * Relax version requirements to support Phoenix 1.4

## 1.1.6 (2018-09-28)

* Enhancements
  * Allow file system watcher backend to be configured
  * Add `:fs_poll` backend as fallback for generic OS support

## 1.1.5

* Bug fix
  * Use proper default interval of 100ms

## 1.1.4

* Enhancements
  * Support `:interval` configuration for cases where the live reloading was triggering too fast

* Bug fix
  * Support IE11
  * Fix CSS reloading in iframe

## 1.1.3 (2017-09-25)

* Bug fix
  * Do not return unsupported `:ignore` from live channel

## 1.1.2 (2017-09-25)

* Enhancements
  * Improve error messages

## 1.1.1 (2017-08-27)

* Enhancements
  * Bump `:file_system` requirement

* Bug fixes
  * Do not raise when response has no body

## 1.1.0 (2017-08-10)

* Enhancements
  * Use `:file_system` for file change notifications for improved reliability

## 1.0.8 (2017-02-01)

* Enhancements
  * Revert to `:fs` 0.9.1 to side-step rebar build problems

## 1.0.7 (2017-01-18)

* Enhancements
  * Update to latest `:fs` 2.12

## 1.0.6 (2016-11-29)

* Bug fixes
  * Remove warnings on Elixir v1.4
  * Do not try to access the endpoint if it is no longer loaded

## 1.0.5 (2016-05-04)

* Bug fixes
  * Do not include hard earmark requirement

## 1.0.4 (2016-04-29)

* Enhancements
  * Support Phoenix v1.2

## 1.0.3 (2016-01-11)

* Enhancements
  * Log whenever a live reload event is sent

## 1.0.2 (2016-01-07)

* Bug fixes
  * Fix issue where iframe path did not respect script_name

## 1.0.1 (2015-09-18)

* Bug fixes
  * Fix issue causing stylesheet link taps to duplicate on reload
