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

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

prog_name="LIPaS"
script_version="0.3.4"

MAIN_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

verbose=0

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-f] -p param_value arg1 [arg2...]

Script description here.

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
  #~ msg "Died through cleanup ..."
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m' GRAY='\033[38;5;8m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW='' GRAY=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

msn() {
  echo >&2 -e "${1-}"
}


vrb() {
  if [ ${verbose} -eq 1 ] 
  then 
     filler=$( seq -s ' ' 1 100 | tr -dc ' ' )
     string=" ${1}"
     msg_lok=$string${filler:${#string}}
     msg "${GRAY} + ${msg_lok:0:35} + ${NOFORMAT}"
  #~ else
     #pass
  fi	
}

gui() {
   filler=$( seq -s ' ' 1 100 | tr -dc ' ' )
   string=" ${1}"
   msg_lok=$string${filler:${#string}}
   msg "${ORANGE} + ${msg_lok:0:35} + ${NOFORMAT}"
}

iui() {
   filler=$( seq -s ' ' 1 100 | tr -dc ' ' )
   string=" ${1}"
   msg_lok=$string${filler:${#string}}
   msn "${ORANGE} + ${msg_lok:0:35} + ${NOFORMAT}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "${RED} $msg ${NOFORMAT}"
  exit "$code"
}

function trim () {
  echo ${1} | awk '{$1=$1;print}'
}

function get_valuekey () {
  # Send back the value from a key/value set
  local my_value

  if [[ ${1} =~ (.*)=(.*) ]]
  then 
    my_value=$( trim ${BASH_REMATCH[2]} )
    echo ${my_value}
    return 0
  else 
    return 1
  fi
}

function get_keyvalue () {
  # Send back the key from a key/value set
  local my_value

  if [[ ${1} =~ (.*)=(.*) ]]
  then 
    my_value=$( trim ${BASH_REMATCH[1]} )
    echo ${my_value}
    return 0
  else 
    return 1
  fi
}

display_version() {

  msg "${prog_name} version ${script_version}"
  exit
  
}

parse_params() {
	
  args=("$@")
  
  #~ [[ ${#args[@]} -lt 2 ]] && die "Missing script arguments: at the minimum I need one input and one output directory"

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) verbose=1 ;;
    --no-color) NO_COLOR=1 ;;
    --version) display_version ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  return 0
}

function split_string_to_array () {

   arrayid=(`echo "$1" | tr "$2" " "`)
   
		
} # end function

# from: https://www.baeldung.com/linux/command-line-progress-bar
bar_size=40
bar_char_done="#"
bar_char_todo="-"
bar_percentage_scale=2

function show_progress {
    current="$1"
    total="$2"

    # calculate the progress in percentage 
    percent=$(bc <<< "scale=$bar_percentage_scale; 100 * $current / $total" )
    # The number of done and todo characters
    done=$(bc <<< "scale=0; $bar_size * $percent / 100" )
    todo=$(bc <<< "scale=0; $bar_size - $done" )

    # build the done and todo sub-bars
    done_sub_bar=$(printf "%${done}s" | tr " " "${bar_char_done}")
    todo_sub_bar=$(printf "%${todo}s" | tr " " "${bar_char_todo}")

    # output the bar
    echo -ne "\rProgress : [${done_sub_bar}${todo_sub_bar}] ${percent}%"

    if [ $total -eq $current ]; then
        echo -e "\nDONE"
    fi
}


setup_colors
parse_params "$@"

msg "  ===================================== "
msg " +                                     +"
msg " +              LIPaS                  +"
msg " +            version ${script_version}            +"
msg " +                                     +"
msg "  ===================================== "

msg ""

source ./LIPaS.params

msg "  = Main install dir is set to:       = "
msg "       ${LIPaS_ROOT} "

msg ""

# Creating the ROOT sub_directories

LIPaS_BIN="${LIPaS_ROOT}/bin"
LIPaS_INC="${LIPaS_ROOT}/inc"
LIPaS_LIB="${LIPaS_ROOT}/lib"

mkdir -p ${LIPaS_BIN}
mkdir -p ${LIPaS_INC}
mkdir -p ${LIPaS_LIB}

vrb "=======   LOCATING CONFIGS   ======="

if [ -d ${MAIN_dir}/${configsDIR}/${ComputerName} ]
then

    vrb "Detected a configuration DIR"

    CONF_DIR="${MAIN_dir}/${configsDIR}/${ComputerName}"
    LIST_CONF_FILES=()
    for fich in $(ls ${CONF_DIR}/${confFile}*)
    do
       nb_lines_conf=$(wc -l ${fich} | cut --delimiter=" " -f1)
       if [ "${nb_lines_conf}" -ge "${confNbLinesFile}" ]
       then
          LIST_CONF_FILES+=("${fich}")
       fi    
    done
    
    nb_valid_conf=${#LIST_CONF_FILES[@]}
    vrb "Found ${nb_valid_conf} valid file(s) in conf DIR"

else

    vrb "Configuration DIR not detected"
    vrb "No possibility to go further"
    vrb "  in current version of ${prog_name}" 

    die "  Execution of ${prog_name} failed   "
    #~ for fich in `ls ${nom_fich_config}*`
    #~ do
	#~ nom_gen=${fich##${nom_fich_config}}
	#~ nom_gen_mach=`echo ${nommachine} | sed "s%[0-9]*%%g"`
	#~ resul_enlev=${nom_gen##${nom_gen_mach}}
	#~ otreoption=`echo ${nommachine} | sed "s%[0-9]*%%g" | sed "s%${nom_gen}%TOTO%g" | grep TOTO`
	#~ if [ "${nom_gen##${nom_gen_mach}}" = "" ]
	#~ then
	    #~ echo "Retreiving  environement variables for ${nom_gen} "
	    #~ fichconfig="${fich}"
	#~ elif [ ! "${otreoption}" = "" ]
	#~ then
	    #~ echo "Retreiving  environement variables for ${nom_gen} "
	    #~ fichconfig="${fich}"
        #~ elif [ ! "${nommachine##${nom_gen}}" = ${nommachine} ]
        #~ then
	    #~ echo "Retreiving  environement variables for ${nom_gen} "
	    #~ fichconfig="${fich}"
        #~ fi
    #~ done

fi

vrb "=======  DEFINING COMPILERS  ======="


env_to_build=()
conf_to_build=()

for file in "${LIST_CONF_FILES[@]}"
do
   env_type=$(basename ${file} | cut -d. -f 2) # second part of config file name is type of env, e.g. conf.gnu
   
   if [[ ${env_to_build[@]} =~ ${env_type} ]]
   then
      vrb "Env. ${env_type} has a double conf file"
      vrb "   ... using first one found ..."
   else
      vrb "Conf file for env. ${env_type} found"
      env_to_build+=("${env_type}")
      conf_to_build+=("${file}")
   fi
done

vrb "I found ${#conf_to_build[@]} environnement(s)"

declare -i CHOSEN_CONF=0

if [ ${#conf_to_build[@]} -gt 1 ]
then

  gui " "
  #    ==================================
  gui "Your system is configured with:"
  gui "... multiple environnements"
  gui "Which env. should I work with?"

  for (( indx_conf=0; indx_conf<=${#conf_to_build[@]}-1; indx_conf++ ))
  do
     gui "[${indx_conf}] ${env_to_build[${indx_conf}]}"
  done
  (( max_index = ${indx_conf} - 1 ))
  gui " "
  iui "Your choice? [0-${max_index}]"
  read xyzzy 
  if [[ ! ${xyzzy} =~ ^[0-${max_index}]+$ ]] ; then
    die "Choice not understood"
  else
    CHOSEN_CONF=${xyzzy}
  fi
fi

# Retreive the compiler /version ...

msg "  ===  Analysing Environnements  ====== "

   conf=${conf_to_build[${CHOSEN_CONF}]}
      
   FC_line=$(grep "FC" ${conf})
   declare -x ${FC_line}
   
   FC_version=$(${FC} --version | grep -o "[0-9]*\.[0-9]\.[0-9]" | tail -1)
   
   vrb "${env_to_build[${CHOSEN_CONF}]} env FC = ${FC_version}"

   source ${MAIN_dir}/${MODULES_D}/test-FC_compiler.sh      
   test_FC_compiler
   
   source ${MAIN_dir}/${MODULES_D}/check_NC-env.sh
   check_NC-env
   
   source ${MAIN_dir}/${MODULES_D}/test-NC_Fortran.sh   
   test-NC_Fortran
      
   cd ${MAIN_dir}
   
   if [ -d ${env_DIR}/${env_to_build[${CHOSEN_CONF}]} ]
   then
     # Delete, we are renewing the configuration
     rm -fR ${env_DIR}/${env_to_build[${CHOSEN_CONF}]}
   fi
  
   mkdir -p ${env_DIR}/${env_to_build[${CHOSEN_CONF}]}
      
   cd ${env_DIR}/${env_to_build[${CHOSEN_CONF}]}
    
   vrb "Generating .pkg" 
   echo "FC = ${FC}" >> gen.pkg
   vrb "Generating .libs"
   echo "INCNETCDF = ${INCNETCDF}" >> gen.libs
   echo "LIBNETCDF = ${LIBNETCDF}" >> gen.libs
   
   # Adding the checking of the env.dict
   
   if [ -f ${MAIN_dir}/${DICT_DIR}/${env_to_build[${CHOSEN_CONF}]}.dict ]
   then
       vrb "Found dictionnary file for ${env_to_build[${CHOSEN_CONF}]}"
       DICT_FOR_ENV="${MAIN_dir}/${DICT_DIR}/${env_to_build[${CHOSEN_CONF}]}.dict"
   else
       die "Could not find dictionnary file for ${env_to_build[${CHOSEN_CONF}]}"
   fi
            
   msg " +  Generating ${env_to_build[${CHOSEN_CONF}]} environnement ...   + ${GREEN} [Done] ${NOFORMAT}" 
#~ done

cd ${MAIN_dir}

# From there, the code for setting up the base configuration

# Here a first version of installing any library in the base config
# Steps are:
# 	=> retreive
# 		-> method / git = git clone in tmp
#   => build
#       -> depends on language/method : autotools = configure ; make ; check success 
#   => install
#       -> in general a form of make install


source ${MAIN_dir}/${MODULES_D}/read-toml.sh


declare -a LIST_PKGS_TO_INSTALL=("makedepf90" "dinsol")

for PKGS_TO_INSTALL in ${LIST_PKGS_TO_INSTALL[@]}
do

# PKGS_TO_INSTALL ... should be in a loop at some point!

unset TOML_TABLE_PKG

#~ PKGS_TO_INSTALL="makedepf90"


# The function read-toml uses directly the global variable TOML_TABLE_PKG
declare -A TOML_TABLE_PKG

read-toml pkgs-db/${PKGS_TO_INSTALL}.toml

unset AARRAY_TEXIST
declare -A AARRAY_TEXIST

TODO="pkginfo"

# The function Texists uses directly the global variable AARRAY_TEXIST

# Technique proposed by Florian Feldhaus 
# from https://stackoverflow.com/questions/4069188/how-to-pass-an-associative-array-as-argument-to-a-function-in-bash

if Texists "${TODO}" in "$(declare -p TOML_TABLE_PKG)"
then
  PKG_NAME=${AARRAY_TEXIST["name"]//\"}
  vrb "Trying to install ${PKG_NAME}"
else
  die "Could not find infos over library [unkonwn]"
fi

if [ -f "pkgs-db/${PKG_NAME}.ok" ]
then

  vrb "${PKG_NAME} is already installed"

else
  declare -a pkg_work=(retrieve build installtst)

  for TODO in ${pkg_work[@]}
  do
    unset AARRAY_TEXIST
    declare -A AARRAY_TEXIST

    if Texists "${TODO}" in "$(declare -p TOML_TABLE_PKG)"
    then
      source ${MAIN_dir}/${MODULES_D}/"${TODO}"_pkg.sh
      "${TODO}"_pkg "$(declare -p AARRAY_TEXIST)" ${PKG_NAME}
      success_pkg=$?
    else
      vrb "Could not find a method to ${TODO} lib ${PKG_NAME}"
    fi

    if [ ! ${success_pkg} -eq 0 ]
    then
      die "${TODO} ${PKG_NAME} failed"
    else
      vrb "${TODO}     lib ${PKG_NAME} [OK]" 
    fi
  done
fi

msg " +  Installing ${PKG_NAME} ...          + ${GREEN} [Done] ${NOFORMAT}" 


done # Loop on the list of pkg to install



#~ # PKGS_TO_INSTALL ... should be in a loop at some point!

#~ unset TOML_TABLE_PKG

#~ PKGS_TO_INSTALL="dinsol"

#~ declare -A TOML_TABLE_PKG

#~ read-toml pkgs-db/${PKGS_TO_INSTALL}.toml

# To check the hash table content
#~ for i in "${!TOML_TABLE_PKG[@]}"
#~ do
 #~ echo "${i} ${TOML_TABLE_PKG[$i]}"
#~ done

#~ unset AARRAY_TEXIST/
#~ declare -A AARRAY_TEXIST

#~ TODO="pkginfo"

#~ if Texists "${TODO}" in "$(declare -p TOML_TABLE_PKG)"
#~ then
  #~ PKG_NAME=${AARRAY_TEXIST["name"]//\"}
  #~ vrb "Trying to install ${PKG_NAME}"
#~ else
  #~ die "Could not find infos over library [unkonwn]"
#~ fi

#~ if [ -f "pkgs-db/${PKG_NAME}.ok" ]
#~ then

  #~ vrb "${PKG_NAME} is already installed"

#~ else
  #~ declare -a pkg_work=(retrieve build installtst)

  #~ for TODO in ${pkg_work[@]}
  #~ do
    #~ declare -A AARRAY_TEXIST
    
    #~ if Texists "${TODO}" in TOML_TABLE_PKG
    #~ then

      #~ source ${MAIN_dir}/${MODULES_D}/"${TODO}"_pkg.sh
      #~ "${TODO}"_pkg AARRAY_TEXIST ${PKG_NAME}
      #~ success_pkg=$?
    #~ else
      #~ vrb "Could not find a method to ${TODO} lib ${PKG_NAME}"
    #~ fi

    #~ if [ ! ${success_pkg} -eq 0 ]
    #~ then
      #~ die "${TODO} ${PKG_NAME} failed"
    #~ else
      #~ vrb "${TODO}     lib ${PKG_NAME} [OK]" 
    #~ fi
    
    #~ unset AARRAY_TEXIST    
  #~ done
#~ fi

#~ msg " +  Installing ${PKG_NAME} ...          + ${GREEN} [Done] ${NOFORMAT}" 


#~ rm -fR ${tempDIR}

# The End of All Things (op. cit.)
