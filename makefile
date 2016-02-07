# This makefile is used to configuration my workingspace environment.
# Author:Tom
# Create Date:2015/12/02
# Late update:2015/12/27

# The program used as the shell is taken from variable `
# If this variable is not set in your makefile, the program '/bin/sh' is used as the shell.
# Because sh is a specification, not an implementation (/bin/sh is a symlink on most UNIX system),
# we need to specify it.

SHELL :=/bin/bash

.PHONY: install
install:
	. ./install.sh
	
.PHONY: clean
clean:
	. ./un_install.sh



