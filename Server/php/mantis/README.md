# MantisBT Integration, 2017-edition

## PHP system administration/configuration

`php.ini` settings that are relevant:

    post_max_size = 42M;

> (42 MiB should be enough?)

    upload_max_filesize = 42M;

> (42 MiB per file uploaded should be enough?)

    max_input_time = 300;

> (5 minutes to perform the upload should be enough?)

## July 2017

### Introduction ~~~

Hello, World!

I have updated the MantisBT integration of feedbackreporter
to support the lates available version of MantisBT
(2.5.1)

// Victor

### New Features ~~~

- `config.php` is version controlled, so, it now uses a
small "hook" to look for `config.private.php` before it
sets its own default values.

  - If a constant named `SUBMIT_TEST` is set, then errors
    in creating a bug will be output as `<pre>` text.

  - `BUG_SUMMARY` constant dropped in favour of providing
    a more verbose summary line.

# MantisBT Integration, 2011-edition

## Introduction

Hi,

this is a simple script that enable you to integrate FeedbackReporter and Mantis.

You'll need to change a couple of values in config.php

If you need to contact me, you can do it via my website:

 http://tellini.info/

Other useful links...

FeedbackReporter Framework:

 http://github.com/tcurdt/feedbackreporter

Mantis:

 http://www.mantisbt.org/

Have fun,
           Simone

