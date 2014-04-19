#
# This is the GNU Make include file for 'solution'
#
# Copyright (C) 2014 Derald D. Woods
#
# This file is part of the solution project, and is made available
# under the terms of the GNU General Public License version 2
#

ELDS := $(shell readlink -e $(CURDIR))

CMD := $(shell echo $(ELDS) > $(ELDS)/.solution)

export ELDS
