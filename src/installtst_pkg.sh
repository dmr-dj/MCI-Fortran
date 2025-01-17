#!/usr/bin/env bash

# Copyright [2024] [Didier M. Roche]
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


source ${MAIN_dir}/${MODULES_D}/gen_libmke.sh

function installtst_pkg () {
	
   # Expectation is to pass the toml associative array
   #  we access it here as in https://stackoverflow.com/questions/4069188/how-to-pass-an-associative-array-as-argument-to-a-function-in-bash
   #~ local -n tomlAA=${1}

   # Updated to avoid compatibility issues
   
   	# Technique proposed by Florian Feldhaus 
	# from https://stackoverflow.com/questions/4069188/how-to-pass-an-associative-array-as-argument-to-a-function-in-bash
    eval "declare -A tomlAA="${1#*=}

   #~ declare -p tomlAA



   local name_pkg=${2}
    
   status_return=0 
    
   # To check the hash table content
   # for i in "${!tomlAA[@]}"
   # do
   #   echo "${i} ${tomlAA[$i]}"
   # done    
    
   for key in ${!tomlAA[@]}
   do
     if [ ${key} == "exec" ]
     then # this should have installed a binary
        if [ -f ${LIPaS_BIN}/${tomlAA[${key}]//\"} ]
        then
           echo ${LIPaS_BIN}/${tomlAA[${key}]//\"} > "${PKG_DATABASE}/${PKG_NAME}.ok"
        else
           status_return=1
        fi
     fi
     if [ ${key} == "lib" ]
     then # this should have installed a library or several
        well_installed=""
	for library_inst in ${tomlAA[$key]//\"}
        do
          if [ -f ${LIPaS_LIB}/${library_inst}.a ]
          then        
             well_installed="${well_installed} ${library_inst}"
          else
             # Library has not been installed in the right place
             # Try to figure it out
             # 
             vrb "search for ${library_inst}.a"
	     locatie_lib=$(find ${MAIN_dir}/${tempDIR} -name "${library_inst}.a")
             if [ -f ${locatie_lib} ]
             then
                cp -vf ${locatie_lib} ${LIPaS_LIB}/.
                well_installed="${well_installed} ${library_inst}.a"
             else
                die "${library_inst} not found"
             fi
             status_return=1
          fi
        done
        gen_liblines ${PKG_NAME} "${LIPaS_LIB}" "${well_installed}" "${ENV_DIR}/${env_to_build[${CHOSEN_CONF}]}/gen.libs"
	for lib_installed in ${well_installed}
        do
           echo ${LIPaS_LIB}/${lib_installed} >> "${PKG_DATABASE}/${PKG_NAME}.ok"
        done
     fi
     return ${status_return}
   done
   unset tomlAA
}

# The End of All Things (op. cit.)
