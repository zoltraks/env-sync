#!/bin/sh

#################################################################################################################
###                                                                                                           ###
###   oooooooooooo ooooo      ooo oooooo     oooo       .oooooo..o oooooo   oooo ooooo      ooo   .oooooo.    ###
###   `888'     `8 `888b.     `8'  `888.     .8'       d8P'    `Y8  `888.   .8'  `888b.     `8'  d8P'  `Y8b   ###
###    888          8 `88b.    8    `888.   .8'        Y88bo.        `888. .8'    8 `88b.    8  888           ###
###    888oooo8     8   `88b.  8     `888. .8'          `"Y8888o.     `888.8'     8   `88b.  8  888           ###
###    888    "     8     `88b.8      `888.8'               `"Y88b     `888'      8     `88b.8  888           ###
###    888       o  8       `888       `888'           oo     .d8P      888       8       `888  `88b    ooo   ###
###   o888ooooood8 o8o        `8        `8'            8""88888P'      o888o     o8o        `8   `Y8bood8P'   ###
###                                                                                                           ###
#################################################################################################################

verbose=false
mode="first"
remove=false
append=false
missing=false
obsolete=false
sort=false
time=false

# Print help
print_help() {
    script_name=$(basename "$0")
    echo "Usage: $script_name [options] source.env target.env [output.env]"
    echo ""
    echo "Options:"
    echo ""
    echo "  --help      Show this help message and exit."
    echo "  --verbose   Print verbose messages."
    echo "  --time      Print time in messages."
    echo "  --last      Change mode to read the last occurrence of variables."
    echo "  --remove    Remove variables."
    echo "  --append    Add missing variables."
    echo "  --missing   Show only non-existing variables."
    echo "  --obsolete  Show variables that should not exist anymore."
    echo "  --sort      Sort variables by name."
    echo ""
    echo "Using remove or append option will result in modified target file printed or optionally written to output file."
}

# Print log messages with verbosity level and optional timestamp
log() {
    local level=$1
    shift
    local message="$@"

    if [ "$level" = "error" ]
    then
        message="Error: $message"
    fi

    if [ "$time" = true ]
    then
        timestamp=$(date +"%Y-%m-%d %H:%M:%S.%3N")
        message="$timestamp $message"
    fi

    case "$level" in
        message)
            echo "$message"
            ;;
        error)
            echo "$message" >&2
            ;;
        verbose)
            if [ "$verbose" = true ]
            then
                echo "$message"
            fi
            ;;
        *)
            echo "Unknown verbosity level: $level" >&2
            ;;
    esac
}

# Parse command-line arguments
options_end=false
args=()  # Array to store non-option arguments (files)
for arg in "$@"; do
    if [ "$options_end" = true ] || ! echo "$arg" | grep -q '^--'; then
        args+=("$arg")
    else
        case "$arg" in
            --verbose) verbose=true ;;
            --help)
                print_help
                exit 0
                ;;
            --time) time=true ;;
            --last) mode="last" ;;
            --remove) remove=true ;;
            --append) append=true ;;
            --missing) missing=true ;;
            --obsolete) obsolete=true ;;
            --list) list=true ;;
            --sort) sort=true ;;
            --) options_end=true ;;
            *)
                echo "Unknown option: $arg"
                print_help
                exit 1
                ;;
        esac
    fi
done

# Ensure two files are provided
if [ "${#args[@]}" -ne 2 ]; then
    log error "You must provide two file locations: source.env and target.env."
    exit 1
fi

source_file="${args[0]}"
target_file="${args[1]}"

# Check if source file exists
if [ ! -f "$source_file" ]; then
    log error "Source file '$source_file' does not exist."
    exit 1
fi

# Check if target file exists
if [ ! -f "$target_file" ]; then
    log error "Target file '$target_file' does not exist."
    exit 1
fi

# Print character as many times as the length of a given value
repeat_char() {
    char="$1"
    text="$2"
    len=${#text}
    while [ "$len" -gt 0 ]
    do
        printf "%s" "$char"
        len=$((len - 1))
    done
    printf "\n"
}

log verbose "Source file: $source_file"
log verbose "Target file: $target_file"

# Extract variables from a file
process_file() {
    local file=$1
    declare -A keys
    # Pass associative array of variables by reference
    local -n var_array=$2
    # Pass indexed array of keys by reference
    local -n var_keys=$3

    while IFS= read -r line
    do
        case "$line" in
            [[:space:]]*\#*) continue ;; 
        esac

        if echo "$line" | grep -qE "^[a-zA-Z][^=]*="
        then
            var_name=$(echo "$line" | cut -d '=' -f 1)
            var_lower=$(echo "$var_name" | tr '[:upper:]' '[:lower:]')
            var_value=$(echo "$line" | cut -d '=' -f 2-)

            if [ "$mode" = "first" ]
            then
                if [ -z "${keys[$var_lower]}" ]
                then
                    var_array["$var_name"]="$var_value"
                    var_keys+=("$var_name")
                    keys[$var_lower]="$var_name"
                fi
            fi

            if [ "$mode" = "last" ]
            then
                if [ -z "${keys[$var_lower]}" ]
                then
                    var_array["$var_name"]="$var_value"
                    var_keys+=("$var_name")
                    keys[$var_lower]="$var_name"
                else
                    var_real="${keys[$var_lower]}"
                    for i in "${!var_keys[@]}"
                    do
                        if [ "${var_keys[$i]}" = "$var_real" ]
                        then
                            unset var_keys[$i]
                            var_keys=("${var_keys[@]}")
                        fi
                    done
                    unset "var_array[$var_real]"
                    var_array["$var_name"]="$var_value"
                    var_keys+=("$var_name")
                fi
            fi
        fi
    done < "$file"
}

log verbose "Processing files..."

# Declare associative arrays for variables from both files
declare -a source_keys
declare -A source_variables
declare -a target_keys
declare -A target_variables

# Process source and target files
process_file "$source_file" source_variables source_keys
process_file "$target_file" target_variables target_keys

# Optionally sort variables
if [ "$sort" = true ]
then
    sorted_array=($(printf "%s\n" "${source_keys[@]}" | sort -f))
    source_keys=("${sorted_array[@]}")
    sorted_array=($(printf "%s\n" "${target_keys[@]}" | sort -f))
    target_keys=("${sorted_array[@]}")
fi

if [ "$remove" = "false" ] && [ "$append" = "false" ] && [ "$missing" = "false" ] && [ "$obsolete" = "false" ]; then
    nop=true
else
    nop=false
fi

if [ "$nop" = true ]
then
    echo ""
    repeat_char "-" $source_file
    echo $source_file
    repeat_char "-" $source_file
    echo ""
    for name in "${source_keys[@]}"; do
        echo "$name=${source_variables[$name]}"
    done
    echo ""

    repeat_char "-" $target_file
    echo $target_file
    repeat_char "-" $target_file
    echo ""
    for name in "${target_keys[@]}"; do
        echo "$name=${target_variables[$name]}"
    done
    echo ""
fi

# Show variables that are present in the target file but not in the source file
if [ "$obsolete" = true ]
then
    if [ "$verbose" = true ]
    then
        echo "Obsolete variables present in target but not in source:"
        echo ""
    fi

    obsolete_found=false
    for tgt in "${target_keys[@]}"; do
        tgt_lower=$(echo "$tgt" | tr '[:upper:]' '[:lower:]')
        found=false
        for src in "${source_keys[@]}"; do
            src_lower=$(echo "$src" | tr '[:upper:]' '[:lower:]')
            if [ "$tgt_lower" = "$src_lower" ]; then
                found=true
                break
            fi
        done
        if [ "$found" = false ]; then
            echo "$tgt=${target_variables[$tgt]}"
            obsolete_found=true
        fi
    done

    if [ "$verbose" = true ]
    then
        if [ "$obsolete_found" = false ]
        then
            echo "No obsolete variables found."
        fi
        echo ""
    fi
fi

# Show variables that are present in the source file but missing in the target file
if [ "$missing" = true ]
then
    if [ "$verbose" = true ]
    then
        echo "Missing variables present in source but not in target:"
        echo ""
    fi

    missing_found=false
    for src in "${source_keys[@]}"; do
        src_lower=$(echo "$src" | tr '[:upper:]' '[:lower:]')
        found=false
        for tgt in "${target_keys[@]}"; do
            tgt_lower=$(echo "$tgt" | tr '[:upper:]' '[:lower:]')
            if [ "$src_lower" = "$tgt_lower" ]; then
                found=true
                break
            fi
        done
        if [ "$found" = false ]; then
            echo "$src=${source_variables[$src]}"
            missing_found=true
        fi
    done

    if [ "$verbose" = true ]
    then
        if [ "$obsolete_found" = false ]
        then
            echo "No missing variables found."
        fi
        echo ""
    fi
fi

log verbose "It is done for now..."
