#!/usr/bin/env bash
######################################################################
# build.sh
# Build multiple LaTeX targets from a single source.
# Run ./build.sh --help for more information.
######################################################################
# BSD 3-Clause License
#
# Copyright (c) 2022, Robo Technical Group, LLC
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
######################################################################

# Locating binaries; adjust for your system if necessary.
readonly biber=$(which biber)
readonly latexmk=$(which latexmk)
readonly lualatex=$(which lualatex)
readonly make4ht=$(which make4ht)
readonly makeglossaries=$(which makeglossaries)
readonly makeindex=$(which makeindex)
readonly pandocbin=$(which pandoc)
readonly pdflatex=$(which pdflatex)
readonly tex4ebook=$(which tex4ebook)
readonly tidy=$(which tidy)
readonly tree=$(which tree)
readonly xelatex=$(which xelatex)

# Additional global variables
DEBUG=0
clean=0
cwd=$( pwd )
epub=0
figs=0
html=0
interactive=0
luatex=0
mainfile=main
markdown=0
outdir=./latex.out
pandoc=0
pdf=0
postclean=0
quick=0
xetex=0
web=0

# Functions

build_epub() {
    local $outdir="$1"
    build_outputdir "$outdir" 1

    if [ $pandoc -eq 1 ]
    then
        build_epub_pandoc $outdir
    else
        build_epub_tex4ebook $outdir
    fi
}

build_epub_pandoc() {
    local outdir="$1"
    local retval=0
    test_exes "pandocbin"
    retval=$?
    if [ $retval -gt 0 ]
    then
        return $retval
    fi

    local config="pandoc-epub.yaml"
    echo "Building e-book." | tee -a $logfile
    if [ -e "$config" ]
    then
        if [ $DEBUG -eq 0 ]
        then
            $pandocbin --from=latex --output="${outdir}/${mainfile}.epub" --defaults=$config ${mainfile}.tex >> $logfile 2>&1
        else
            $pandocbin --from=latex --output="${outdir}/${mainfile}.epub" --defaults=$config ${mainfile}.tex | tee -a $logfile
        fi
    else
        if [ $DEBUG -eq 0 ]
        then
            $pandocbin --from=latex --to=epub3 --output="${outdir}/${mainfile}.epub" --mathml ${mainfile}.tex >> $logfile 2>&1
        else
            $pandocbin --from=latex --to=epub3 --output="${outdir}/${mainfile}.epub" --mathml ${mainfile}.tex | tee -a $logfile
        fi
    fi
}

build_epub_tex4ebook() {
    local outdir="$1"
    local retval=0
    test_exes "tex4ebook"
    retval=$?
    if [ $retval -gt 0 ]
    then
        return $retval
    fi

    local config="tex4ebookrc"

    echo "Building e-book." | tee -a $logfile
    if [ -e "$config" ]
    then
        if [ $DEBUG -eq 0 ]
        then
            $tex4ebook --format epub3 --build-file $config $mainfile >> $logfile 2>&1
        else
            $tex4ebook --format epub3 --build-file $config $mainfile | tee -a $logfile
        fi
    else
        if [ $DEBUG -eq 0 ]
        then
            $tex4ebook --format epub3 $mainfile >> $logfile 2>&1
        else
            $tex4ebook --format epub3 $mainfile | tee -a $logfile
        fi
    fi

    epubfile="${mainfile}.epub"
    if [ -e "$epubfile" ]
    then
        if [ $DEBUG -eq 0 ]
        then
            echo "Moving ePub file to output directory."
        fi
        mv "$epubfile" "$outdir"/
    fi
}

build_markdown() {
    local outdir="$1"
    local retval=0
    test_exes "pandocbin"
    retval=$?
    if [ $retval -gt 0 ]
    then
        return $retval
    fi

    build_outputdir "$outdir" 1
    local config="pandoc-md.yaml"
    echo "Building Markdown files." | tee -a $logfile
    if [ -e "$config" ]
    then
        if [ $DEBUG -eq 0 ]
        then
            $pandocbin --from=latex --output="${outdir}/${mainfile}.md" --defaults=$config ${mainfile}.tex >> $logfile 2>&1
        else
            $pandocbin --from=latex --output="${outdir}/${mainfile}.md" --defaults=$config ${mainfile}.tex | tee -a $logfile
        fi
    else
        if [ $DEBUG -eq 0 ]
        then
            $pandocbin --from=latex --to=markdown --output="${outdir}/${mainfile}.epub" ${mainfile}.tex >> $logfile 2>&1
        else
            $pandocbin --from=latex --to=markdown --output="${outdir}/${mainfile}.epub" ${mainfile}.tex | tee -a $logfile
        fi
    fi
}

build_pdf() {
    local outdir="$1"
    build_outputdir "$outdir"
    if [ ! -z "$latexmk" -a -x "$latexmk" ]
    then
        build_pdf_latexmk "$outdir"
    else
        build_pdf_pdflatex "$outdir"
    fi
}

build_pdf_latexmk() {
    local outdir="$1"
    local pdf="-pdf"
    if [ $xetex -eq 1 ]
    then
        pdf="-pdfxe"
    fi
    if [ $luatex -eq 1 ]
    then
        pdf="-pdflua"
    fi
    if [ $interactive -eq 0 ]
    then
        if [ $DEBUG -eq 0 ]
        then
            $latexmk $pdf -interaction=batchmode -file-line-error -output-directory="$outdir" $mainfile | tee -a $logfile
        else
            $latexmk $pdf -interaction=nonstopmode -file-line-error -output-directory="$outdir" $mainfile | tee -a $logfile
        fi
    else
        $latexmk $pdf -file-line-error -output-directory="$outdir" $mainfile | tee -a $logfile
    fi
}

build_pdf_pdflatex() {
    local outdir="$1"
    local retval=0
    local pdfbin=$pdflatex
    if [ $xetex -eq 1 ]
    then
        pdfbin=$xelatex
    fi
    if [ $luatex -eq 1 ]
    then
        pdfbin=$lualatex
    fi
    test_exes "tree pdfbin makeindex makeglossaries biber"
    retval=$?
    if [ $retval -gt 0 ]
    then
        return $retval
    fi

    echo "Starting PDF first pass." | tee $logfile
    if [ $interactive -eq 0 ]
    then
        if [ $DEBUG -eq 0 ]
        then
            $pdfbin -interaction=batchmode -file-line-error -output-directory="$outdir" $mainfile | tee -a $logfile
        else
            $pdfbin -interaction=nonstopmode -file-line-error -output-directory="$outdir" $mainfile | tee -a $logfile
        fi
    else
        $pdfbin -file-line-error -output-directory="$outdir" $mainfile | tee -a $logfile
    fi

    if [ $quick -eq 0 ]
    then
        echo "Building index." | tee -a $logfile
        if [ $DEBUG -eq 0 ]
        then
            $makeindex -o ${outdir}/${mainfile}.ind -t ${outdir}/${mainfile}.ind.log ${outdir}/$mainfile >> $logfile 2>&1
        else
            $makeindex -o ${outdir}/${mainfile}.ind -t ${outdir}/${mainfile}.ind.log ${outdir}/$mainfile | tee -a $logfile
        fi

        echo "Building bibliography." | tee -a $logfile
        if [ $DEBUG -eq 0 ]
        then
            $biber --input-directory $outdir --output-directory $outdir $mainfile >> $logfile
        else
            $biber --input-directory $outdir --output-directory $outdir $mainfile | tee -a $logfile
        fi

        echo "Building glossary." | tee -a $logfile
        if [ $DEBUG -eq 0 ]
        then
            $makeglossaries -d $outdir $mainfile >> $logfile
        else
            $makeglossaries -d $outdir $mainfile | tee -a $logfile
        fi

        echo "Starting PDF second pass." | tee -a $logfile
        if [ $interactive -eq 0 ]
        then
            if [ $DEBUG -eq 0 ]
            then
                $pdfbin -interaction=nonstopmode -file-line-error -output-directory="$outdir" $mainfile >> $logfile
            else
                $pdfbin -interaction=nonstopmode -file-line-error -output-directory="$outdir" $mainfile | tee -a $logfile
            fi
        else
            $pdfbin -file-line-error -output-directory="$outdir" $mainfile | tee -a $logfile
        fi

        echo "Starting PDF third pass." | tee -a $logfile
        if [ $interactive -eq 0 ]
        then
            if [ $DEBUG -eq 0 ]
            then
                $pdfbin -interaction=nonstopmode -file-line-error -output-directory="$outdir" $mainfile >> $logfile
            else
                $pdfbin -interaction=nonstopmode -file-line-error -output-directory="$outdir" $mainfile | tee -a $logfile
            fi
        else
            $pdfbin -file-line-error -output-directory="$outdir" $mainfile | tee -a $logfile
        fi
    fi
}

build_outputdir() {
    local outdir="$1"
    local norecurse=${2:-0}

    [ ! -d "$outdir" ] && mkdir -p "$outdir"
    if [ ! -d "$outdir" ]
    then
        echo "Unable to create output directory ${outdir}; aborting."
        return 1
    fi

    if [ $norecurse -eq 0 ]
    then
        for d in $(ls -d */) ;
        do
            if [ "$d" != "latex.out/" ]
            then
                tree -dfi --noreport "$d" | xargs -I{} mkdir -p "${outdir}/{}"
            fi
        done
    fi
}

build_web() {
    local $outdir="$1"
    build_outputdir "$outdir" 1

    if [ $pandoc -eq 1 ]
    then
        build_web_pandoc $outdir
    else
        build_web_make4ht $outdir
    fi
}

build_web_make4ht() {
    local outdir="$1"
    local retval=0
    test_exes "make4ht"
    retval=$?
    if [ $retval -gt 0 ]
    then
        return $retval
    fi

    local config="make4htrc"
    local htmlfilter="html5+common_domfilters+tidy"
    if [ -z $tidy -o ! -x $tidy ]
    then
        htmlfilter="html5+common_domfilters"
    fi

    echo "Building web site." | tee -a $logfile
    if [ -e "$config" ]
    then
        if [ $DEBUG -eq 0 ]
        then
            $make4ht --output-dir "$outdir" --utf8 --build-file $config --format html5 $mainfile >> $logfile 2>&1
        else
            $make4ht --output-dir "$outdir" --utf8 --build-file $config --format html5 $mainfile | tee -a $logfile
        fi
    else
        if [ $DEBUG -eq 0 ]
        then
            $make4ht --output-dir "$outdir" --utf8 --format $htmlfilter $mainfile "mathjax,2" >> $logfile 2>&1
        else
            $make4ht --output-dir "$outdir" --utf8 --format $htmlfilter $mainfile "mathjax,2" | tee -a $logfile
        fi
    fi
}

build_web_pandoc() {
    local outdir="$1"
    local retval=0
    test_exes "pandocbin"
    retval=$?
    if [ $retval -gt 0 ]
    then
        return $retval
    fi

    local config="pandoc-web.yaml"
    echo "Building web site." | tee -a $logfile
    if [ -e "$config" ]
    then
        if [ $DEBUG -eq 0 ]
        then
            $pandocbin --from=latex --to=html5 --output="${outdir}/${mainfile}.html" --defaults=$config ${mainfile}.tex >> $logfile 2>&1
        else
            $pandocbin --from=latex --to=html5 --output="${outdir}/${mainfile}.html" --defaults=$config ${mainfile}.tex | tee -a $logfile
        fi
    else
        if [ $DEBUG -eq 0 ]
        then
            $pandocbin --from=latex --to=html5 --output="${outdir}/${mainfile}.html" --standalone --mathjax ${mainfile}.tex >> $logfile 2>&1
        else
            $pandocbin --from=latex --to=html5 --output="${outdir}/${mainfile}.html" --standalone --mathjax ${mainfile}.tex | tee -a $logfile
        fi
    fi
}

print_help() {
    echo "Usage:"
    echo "  $ build.sh [options] main-file[.tex]"
    echo "Options:"
    echo "  -a, --all"
    echo "    Same as --figures --pdf --epub --html."
    echo "  --clean"
    echo "    Deletes the output directory before building."
    echo "  -e, --epub"
    echo "    Builds the ePub files."
    echo "  -f, --figures"
    echo "    Builds any figure files located in the working directory."
    echo "  -h, --html"
    echo "    Build web site files. Synonymous with -w and --web."
    echo "  -i, --interactive"
    echo "    Run programs in interactive mode."
    echo "  -l, --luatex"
    echo "    Use LuaTeX engine instead of LaTeX engine."
    echo "  -m, --markdown"
    echo "    Build Markdown files."
    echo "  -p, --pdf"
    echo "    Builds the PDF file."
    echo "  --post-clean"
    echo "    Runs the cleanup routines after building."
    echo "  -q, --quick"
    echo "    Runs just one pass of pdflatex, et al."
    echo "  -v, --debug, --verbose"
    echo "    Output additional information during build."
    echo "  -w, --web"
    echo "    Build web site files. Synonymous with -h and --html."
    echo "  -x, -xetex"
    echo "    Use XeTeX engine instead of LaTeX engine."
    echo "  -?, --help"
    echo "    Displays this information."
}

test_exes() {
    local retval=0
    for x in $1 ;
    do
        if [ -z "${!x}" -o ! -x "${!x}" ]
        then
            if [ "$x" == "pdfbin" ]
            then
                if [ $xetex -eq 0 ]
                then
                    echo "Cannot find executable pdflatex."
                else
                    echo "Cannot find executable xelatex."
                fi
            else
                echo "Cannot find executable ${x}."
            fi
            retval=1
        fi
    done
    return $retval
}

# Inspired by https://stackoverflow.com/questions/35718955/bash-script-to-get-its-full-path-use-source-to-invoke-it
# Returns given file with its full path
# Uses realpath if it exists
get_full_path() {
    local realpath=$(which realpath)
    if [ ! -z "$realpath" -a -x "$realpath" ]
    then
        echo $($realpath "$1")
    else
        local relname=$1
        if [[ ! "$relname" =~ "/" ]]
        then
            relname="./$relname"
        fi

        local relpath=$(dirname $relname)
        local name="${relname##*/}"

        # convert to absolute path by cd-ing and using pwd.
        cd "$relpath" >/dev/null
        local path=$( pwd )
        cd - >/dev/null

        # construct full path from absolute path and filename
        echo "$path/$name"
    fi
}

# From https://stackoverflow.com/questions/965053/extract-filename-and-extension-in-bash
#
# splitPath()
#
# SYNOPSIS
#   splitPath path varDirname [varBasename [varBasenameRoot [varSuffix]]] 
# DESCRIPTION
#   Splits the specified input path into its components and returns them by assigning
#   them to variables with the specified *names*.
#   Specify '' or throw-away variable _ to skip earlier variables, if necessary.
#   The filename suffix, if any, always starts with '.' - only the *last*
#   '.'-prefixed token is reported as the suffix.
#   As with `dirname`, varDirname will report '.' (current dir) for input paths
#   that are mere filenames, and '/' for the root dir.
#   As with `dirname` and `basename`, a trailing '/' in the input path is ignored.
#   A '.' as the very first char. of a filename is NOT considered the beginning
#   of a filename suffix.
# EXAMPLE
#   splitPath '/home/jdoe/readme.txt' parentpath fname fnameroot suffix
#   echo "$parentpath" # -> '/home/jdoe'
#   echo "$fname" # -> 'readme.txt'
#   echo "$fnameroot" # -> 'readme'
#   echo "$suffix" # -> '.txt'
#   ---
#   splitPath '/home/jdoe/readme.txt' _ _ fnameroot
#   echo "$fnameroot" # -> 'readme'  
splitPath() {
  local _sp_dirname= _sp_basename= _sp_basename_root= _sp_suffix=
    # simple argument validation
  (( $# >= 2 )) || { echo "$FUNCNAME: ERROR: Specify an input path and at least 1 output variable name." >&2; exit 2; }
    # extract dirname (parent path) and basename (filename)
  _sp_dirname=$(dirname "$1")
  _sp_basename=$(basename "$1")
    # determine suffix, if any
  _sp_suffix=$([[ $_sp_basename = *.* ]] && printf %s ".${_sp_basename##*.}" || printf '')
    # determine basename root (filemane w/o suffix)
  if [[ "$_sp_basename" == "$_sp_suffix" ]]; then # does filename start with '.'?
      _sp_basename_root=$_sp_basename
      _sp_suffix=''
  else # strip suffix from filename
    _sp_basename_root=${_sp_basename%$_sp_suffix}
  fi
  # assign to output vars.
  [[ -n $2 ]] && printf -v "$2" "$_sp_dirname"
  [[ -n $3 ]] && printf -v "$3" "$_sp_basename"
  [[ -n $4 ]] && printf -v "$4" "$_sp_basename_root"
  [[ -n $5 ]] && printf -v "$5" "$_sp_suffix"
  return 0
}

######################################################################
# 00_getargs.bm
# Bash module for parsing command-line arguments
# Argument is stored in global variable GETARGS_RETVAL
# Sample usage:
#
# # Load first argument
# GA_init
# GA_getarg
#
# # Parse arguments until none returned
# until [ -z "$GETARGS_RETVAL" ]
# do
#     case "$GETARGS_RETVAL" in
#     -f|--file)
#         # -f and --file requires a parameter; retrieve it
#         GA_getarg_noflag
#         FILE="$GETARGS_RETVAL"
#         if [ -z "$FILE" ]
#         then
#             echo "Must specify input file with $GETARGS_RETVAL"
#         fi
#         ;;
#
#     -v|--debug|--verbose)
#         DEBUG=1
#         ;;
#
#     *)
#         echo "Invalid or unknown argument: $GETARGS_RETVAL"
#         ;;
#     esac # $GETARGS_RETVAL
#
#     # Move on to the next argument
#     GA_getarg
# done # $GETARGS_RETVAL
######################################################################

# Global Constants

# Global Variables
GETARGS_INDEX=1
GETARGS_NUMARGS=$#
GETARGS_CURRENT=""
GETARGS_RETVAL=""
declare -a GETARGS_ARGS


######################################################################
# Main
# Initializes module
# Copies command-line arguments into global variable
# Calls:
#    -- None --
######################################################################
# Changelog
# Date         Author    Comments
######################################################################
# 02 Feb 2012  akulcsar  Initial version
######################################################################
for (( GETARGS_COUNTER=0 ; GETARGS_COUNTER <= $# ; GETARGS_COUNTER++ ))
do
    GETARGS_ARGS[$GETARGS_COUNTER]="${!GETARGS_COUNTER}"
done # GETARGS_COUNTER

######################################################################
# GA_getarg
# Stores the next argument in GETARGS_RETVAL
# If no other argument exists, GETARGS_RETVAL will be empty
# Calls:
#    -- None --
######################################################################
# Changelog
# Date         Author    Comments
######################################################################
# 02 Feb 2012  akulcsar  Initial version
######################################################################
GA_getarg()
{
    local RETVAL=""
    
    # Determine if getarg was previously parsing a multi-flag
    # argument (e.g. -ldh)
    if [ -z "$GETARGS_CURRENT" ]
    then
        # Not working on a multi-flag argument
        # Parse next argument if it exists
        if [ $GETARGS_INDEX -gt $GETARGS_NUMARGS ]
        then
            # No arguments remain; return empty string
            # (Yes, aware that declaration is redundant)
            RETVAL=""
        else
            # Parse next argument
            local CURRENT_ARG="${GETARGS_ARGS[$GETARGS_INDEX]}"
            if [ "${CURRENT_ARG:0:1}" == "-" ]
            then
                if [ "${CURRENT_ARG:0:2}" == "--" ]
                then
                    # This is a long-style flag
                    # Return the whole thing and move on to next argument
                    RETVAL="$CURRENT_ARG"
                    (( GETARGS_INDEX++ ))
                else
                    # This is a short flag
                    # Return the first letter
                    RETVAL="-"${CURRENT_ARG:1:1}
                    
                    # Store the rest for later if multiple flags included
                    if [ ${#CURRENT_ARG} -gt 2 ]
                    then
                        GETARGS_CURRENT="-"${CURRENT_ARG:2}
                    else
                        # Single-letter flag; move on to next argument
                        (( GETARGS_INDEX++ ))
                    fi  # ${#CURRENT_ARG}
                fi  # ${CURRENT_ARG:0:2}
            else
                # Not a flag
                # Return the argument as-is and move on to next argument
                RETVAL="$CURRENT_ARG"
                (( GETARGS_INDEX++ ))
            fi  # ${CURRENT_ARG:0:1}
         fi  # $GETARGS_INDEX
    else
        # Still working on a multi-flag argument
        # Get next letter in flag
        RETVAL="-"${GETARGS_CURRENT:1:1}
        if [ ${#GETARGS_CURRENT} -gt 2 ]
        then
            # More flags remain in argument
            # Strip current flag and replace remainder in GETARGS_CURRENT
            GETARGS_CURRENT="-"${GETARGS_CURRENT:2}
        else
            # No more flags remain in argument
            # Move on to the next argument
            GETARGS_CURRENT=""
            (( GETARGS_INDEX++ ))
        fi  # ${#GETARGS_CURRENT}
    fi  # $GETARGS_CURRENT
    
    # echo $RETVAL
    GETARGS_RETVAL="$RETVAL"
    
    return 0    
}   # GA_getarg( )

######################################################################
# GA_getarg_noflag
# Stores the next argument in GETARGS_RETVAL
# If no other argument exists, or if the next argument is a flag,
#  GETARGS_RETVAL will be empty
# Call if the previous argument was a flag and you are
#  expecting a parameter for it
# Calls:
#    -- None --
######################################################################
# Changelog
# Date         Author    Comments
######################################################################
# 02 Feb 2012  akulcsar  Initial version
######################################################################
GA_getarg_noflag()
{
    local RETVAL=""

    if [ -z "$GETARGS_CURRENT" ]
    then
        # Not working on a multi-flag argument
        # Parse next argument if it exists
        if [ $GETARGS_INDEX -gt $GETARGS_NUMARGS ]
        then
            # No arguments remain; return empty string
            # (Yes, aware that declaration is redundant)
            RETVAL=""
        else
            # Parse next argument
            local CURRENT_ARG="${GETARGS_ARGS[$GETARGS_INDEX]}"
            if [ ${CURRENT_ARG:0:1} == "-" ]
            then
                # Next argument is a flag
                # Return empty string
                RETVAL=""
            else
                # Next argument is not a flag
                # Return it and move on to the next
                RETVAL="$CURRENT_ARG"
                (( GETARGS_INDEX++ ))
            fi  # ${CURRENT_ARG:0:1}
        fi  # $GETARGS_INDEX
    else
        # getarg is working on a multi-flag argument
        # Return empty string
        # (Yes, aware that declaration is redundant)
        RETVAL=""
    fi  # $GETARGS_CURRENT
    
    GETARGS_RETVAL="$RETVAL"
    return 0
}   # GA_getarg_noflag()

# Main
# Parse command-line arguments
GA_getarg
until [ -z "$GETARGS_RETVAL" ]
do
    case "$GETARGS_RETVAL" in
    -?|--help)
        print_help
        exit 0
        ;;

    -a|--all)
        figs=1
        pdf=1
        epub=1
        web=1
        markdown=1
        ;;

    -c|--content-dir)
        # -c and --content-dir requires a parameter; retrieve it
        GA_getarg_noflag
        content_dir="$GETARGS_RETVAL"
        if [ -z "$content_dir" ]
        then
            echo "Must specify content directory with ${GETARGS_RETVAL}."
        fi
        ;;

    --clean)
        clean=1
        ;;

    -e|--epub)
        epub=1
        ;;

    -f|--figures)
        figs=1
        ;;

    -h|--html)
        html=1
        web=1
        ;;

    -i|--interactive)
        interactive=1
        ;;

    -l|--luatex)
        luatex=1
        ;;

    -m|--markdown)
        markdown=1
        ;;

    -p|--pdf)
        pdf=1
        ;;

    --post-clean)
        postclean=1
        ;;

    -q|--quick)
        quick=1
        ;;

    -v|--debug|--verbose)
        DEBUG=1
        ;;

    -x|--xetex)
        xetex=1
        ;;

    -w|--web)
        web=1
        ;;

    *)
        # Positional argument must be main file
        mainfile="$GETARGS_RETVAL"
        ;;
    esac

    # Move on to the next argument
    GA_getarg
done

if [ ! -e $mainfile -a ! -e ${mainfile}.tex ]
then
    echo "Main file '${mainfile}' does not exist; aborting."
    exit 1
fi

mainfile=$(get_full_path $mainfile)
splitPath $mainfile mainfilelocation fn mainfile ext
if [ -z "$ext" ]
then
    ext=.tex
    fn=${fn}.tex
fi
mainfilefullpath=${mainfilelocation}/$fn
logfile="${outdir}/build.log"
cd "$mainfilelocation"

# Last test before starting
if [ ! -e $mainfilefullpath ]
then
    echo " Main file '${mainfilefullpath}' does not exist; aborting."
    exit 1
fi

if [ $clean -eq 1 -a -e $outdir ]
then
    if [ $DEBUG -eq 1 ]
    then
        echo "Removing output directory ${outdir}."
    fi
    rm -rf $outdir
fi

if [ $pdf -eq 1 ]
then
    if [ $DEBUG -eq 1 ]
    then
        echo "Building PDF."
    fi
    build_pdf "${outdir}/pdf"
fi

if [ $web -eq 1 ]
then
    build_web "${outdir}/html"
fi

if [ $epub -eq 1 ]
then
    build_epub "${outdir}/epub"
fi

if [ $md -eq 1 ]
then
    build_markdown "${outdir}/md"
fi

if [ $postclean -eq 1]
then
    echo "Cleanup routines requested after build. Not yet implemented."
fi

cd "$cwd"
