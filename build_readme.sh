#! /bin/bash

#
# Copyright (C) 2011 Georgia Institute of Technology, University of Utah, 
# Weill Cornell Medical College
#
# This program is free software: you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation, either version 3 of the License, or (at your option) any later 
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT 
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more 
# details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program.  If not, see <http://www.gnu.org/licenses/>.
#

#
# This script will build a README file using a module's source code, assuming 
# the module abstracted from DefaultGUI. In the module directory, run: 
#
# ./build_readme.sh
#


#
# Set and generate variables.
#

# Set names for the source files and screenshot. Assume source code is files
# have the same name as the parent directory. Manually override this behaviour
# as needed. 
CPPFILE="${PWD##*/}.cpp"
HEADER="${PWD##*/}.h"
SCREENSHOT="${PWD##*/}.png"

# Name of the output. Change to README.md to automatically overwrite the
# current readme.
OUTPUT=NEW_README.md

REQUIREMENTS=None
LIMITATIONS=None

# Get the name of the plugin from the DefaultGuiModel() call.
PLUGIN_NAME=$(cat "${CPPFILE}" | \
              sed -n "s/.*DefaultGUIModel(\"\(.*\)\",.*/\1/p" | \
              sed -e 's/ \([A-Z][a-z]\)/ \1/g')

# Get the plugin description from the text stuck in the setWhatsThis call().
DESCRIPTION=$(awk '/^[ \t]*setWhatsThis.*/,/\);/' "${CPPFILE}" | \
              tr -d '\n' | sed -n "s/^\s*setWhatsThis(.*\"\(.*\)\");/\1\n/p")

# Use grep to get the code for the vars[] array that specify all the RTXI
# variables.
VARS_ARRAY=$(grep -Pzo "(?s)(\s*)\N*vars\[\].*?{.*?\1};" "${CPPFILE}" | \
             tr -d '\0')

# Parse VARS_ARRAY to generate a list containing all the vars[] variables,
# including the variable name, tooltip description, and type.
CATAPULT=$(echo ${VARS_ARRAY} | tr -d '\n' | \
awk ' BEGIN { p=0 } 
{
  for(i=1; i<=length($0); i++)
  {
    test=substr($0, i, 1)
    if(test=="{") {
      p=1
      continue
    }
    if(test=="}") {
      printf("\n")
      p=0;
    }
    if(p==1 && test!="\t") {
      printf("%s", test)
    }
  }
} ')


# Function that takes a variable list and a type (PARAMETER, STATE, INPUT,
# OUTPUT) and then prints out a README-formatted list containing all the
# variables in the list with the specified type.
#
# Usage: PRINT_VARIABLES <LIST> <TYPE>
#    eg: PRINT_VARIABLES ${CATAPULT} "PARAMETER"
function PRINT_VARIABLES() {
  LIST=$1
  TYPE=$2
  COUNTER=1
  while read -r LINE; do
    if [[ "$LINE" =~ "$TYPE" ]]; then
      NAME=$(echo ${LINE} | cut -d "," -f1 | sed "s/^[ \t]*//" | sed -e "s/\"//g")
      DESCRIPTION=$(echo ${LINE} | cut -d "," -f2 | sed "s/^[ \t]*//" | sed -e "s/\"//g")
      if [[ "$TYPE" == INPUT ]] || [[ "$TYPE" == OUTPUT ]]; then
        echo "$COUNTER. ${TYPE,,}($((COUNTER-1))) - $NAME : $DESCRIPTION"
      else
        echo "$COUNTER. $NAME - $DESCRIPTION"
      fi
      COUNTER=$((COUNTER+1))
    fi
  done <<< "${LIST}"
}


#
# Generate the README.
#
# The format is intended to be consistent with the pages found on
# http://rtxi.org/modules. 
#

echo "### ${PLUGIN_NAME}"                          > "${OUTPUT}"
echo ""                                           >> "${OUTPUT}"
echo "**Requirements:** ${REQUIREMENTS}"          >> "${OUTPUT}"
echo "**Limitations:** ${LIMITATIONS}"            >> "${OUTPUT}"
echo ""                                           >> "${OUTPUT}"
echo "![${PLUGIN_NAME} GUI](${SCREENSHOT})"       >> "${OUTPUT}"
echo ""                                           >> "${OUTPUT}"
echo "<!--start-->"                               >> "${OUTPUT}"
echo "${DESCRIPTION}"                             >> "${OUTPUT}"
echo "<!--end-->"                                 >> "${OUTPUT}"
echo ""                                           >> "${OUTPUT}"
echo "#### Input"                                 >> "${OUTPUT}"
echo "$(PRINT_VARIABLES "${CATAPULT}" INPUT)"     >> "${OUTPUT}"
echo ""                                           >> "${OUTPUT}"
echo "#### Output"                                >> "${OUTPUT}"
echo "$(PRINT_VARIABLES "${CATAPULT}" OUTPUT)"    >> "${OUTPUT}"
echo ""                                           >> "${OUTPUT}"
echo "#### Parameters"                            >> "${OUTPUT}"
echo "$(PRINT_VARIABLES "${CATAPULT}" PARAMETER)" >> "${OUTPUT}"
echo ""                                           >> "${OUTPUT}"
echo "#### States"                                >> "${OUTPUT}"
echo "$(PRINT_VARIABLES "${CATAPULT}" STATE)"     >> "${OUTPUT}"
