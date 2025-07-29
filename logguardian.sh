#!/bin/bash

# This is a script for logguardian.sh

FILE="" # Log file to be analyzed

critical_errors_count=0 # Counter for critical errors
warning_count=0 # Counter for warning messages
info_messages_count=0 # Counter for info messages

error_keyword="ERROR" # Default error keyword
warning_keyword="WARN|WARNING" # Default warning keyword, handle both WARN and WARNING
info_keyword="INFO|SUCCESS" # Default info keyword, handle both INFO and SUCCESS
threshold_count=5 # Leave this empty to use the default threshold count

critical_errors=() # Array to hold critical error messages

run_immediately=false # Flag to indicate if the script should run immediately
parse_error=false # Flag to indicate if the error keyword is parsed
parse_warning=false # Flag to indicate if the warning keyword is parsed
parse_info=false # Flag to indicate if the info keyword is parsed
# parse_threshold=false # Flag to indicate if the threshold count is parsed

RED='\e[31m' # Define red color for error messages
GREEN='\e[32m' # Define green color for success messages
YELLOW='\e[33m' # Define yellow color for warning messages
BLUE='\e[34m' # Define blue color for informational messages
NC='\e[0m' # No color, reset to default
BOLD='\e[1m' # Define bold text

show_help() {
    cat << EOF # Using 'here document' to display help message. Using EOF to end the message.
###############===================================###############
Usage: logguardian.sh [options]

Description:
    Automates the analysis of application log files, identifies critical events, and
    simulate notifications or reports based on these findings.

Options:
    -f <log_file_path>   : Specifies the path to the log file to be analyzed.
    -e <error_keyword>   : A specific keyword to search for as a "critical error."
                           Defaults to "ERROR" if not provided.
    -w <warning_keyword> : A specific keyword to search for as a "warning".
                           Defaults to "WARN" or "WARNING" (handle both) if not provided.
    -c <info_keyword>    : A specific keyword to search for as "info" or "completion" messages.
                           Defaults to "INFO" or "SUCCESS" if not provided.
    -t <threshold_count> : A positive integer threshold. If the count of "critical errors"
                           (based on -e keyword) exceeds this number, trigger a "critical alert."
                           Defaults to 5 if not provided.
    -h or --help         : Display a comprehensive help message explaining all options.
    -v                   : Verbose mode. Process the log file and display a summary report.

Example:
logguardian.sh -f /var/log/myapp.log -e "CRITICAL"
logguardian.sh -f /var/log/myapp.log -w "WARN" -c "INFO" -t 10
###############===================================###############

EOF
}

get_file_path() {
    if [[ -f $FILE ]];then # Check if the file exists and is a regular file.
        if [[ -r $FILE ]]; then # Check if the file is readable.
            local log_file_path=$(readlink -e "$FILE") # Using readlink to find the absolute path of the log file.
            echo -e "${GREEN}✅ Log file found and is readable.${NC}" # Print success message in green color.
            echo "Log file: $FILE"
            echo "Log file path: $log_file_path"
            echo
        else
            echo -e "${RED}❌ Error: Log file is not readable.${NC}"
            echo
            exit 1 # Exit with error code if the file is not readable.
        fi
    else # If the file does not exist.
        echo -e "${RED}❌ Error: Log file does not exist.${NC}"
        echo
    fi
}

process_log_file() {
    # Read the log files line by line and process them based on the keywords provided.
    while IFS= read -r line; do # IFS: to read file line by line. -r: to prevent backslash escapes from being interpreted. line: variable to hold each line of the log file.
        if [[ $line =~ $error_keyword ]]; then # Check if the line contains the error keyword.
            critical_errors+=("$line") # Add the line to the critical errors array.
            ((critical_errors_count++)) # Increment the critical errors count.
        elif [[ $line =~ $warning_keyword ]]; then # Check if the line contains the warning keyword.
            ((warning_count++)) # Increment the warning count.
        elif [[ $line =~ $info_keyword ]]; then # Check if the line contains the info keyword.
            ((info_messages_count++)) # Increment the info messages count.
        fi

    done < "$FILE" # Read from the specified log file.
}

display_error_line() {
    echo "  Critical errors found in the log file:"
    for error in "${critical_errors[@]}"; do # Loop through the critical errors array. @ is used to expand the array into individual elements.
        echo "   - $error" # Print each critical error.
    done
}

display_summary_report() {
    echo -e "${YELLOW}##########========== Summary Report ===========##########${NC}"
    echo
    echo "      🚾 Total line processed: $(wc -l < "$FILE")" # wc -l counts the number of lines in the file.
    if [[ $parse_error == true ]]; then # Check if the error keyword is parsed.
        echo "      🔤 Error Keyword: $error_keyword"
        echo "      🛑 Total critical errors found: $critical_errors_count" # Display the count of critical errors.
        if [[ $critical_errors_count -ge $threshold_count ]]; then # Check if the critical errors count exceeds the threshold.
            echo
            echo -e "${RED}          ⚠️ CRITICAL ALERT!! Error threshold exceeded.${NC}"
            display_error_line
        elif [[ $critical_errors_count -eq 0 ]]; then # Check if there are no critical errors.
            echo -e "${GREEN}          🤖 No critical errors found.${NC}"
        else
            echo "          🔢 Threshold count: $threshold_count"
            echo "          ✅ Error count within acceptable limits."
        fi
    else
        echo -e "      🛑 Total critical errors found: ${BLUE}Not Analyzed${NC}" # If error keyword is not parsed, display not analyzed.
    fi
    if [[ $parse_warning == true ]]; then # Check if the warning keyword is parsed.
        echo "      🔤 Warning Keyword: $warning_keyword"
        echo "      🚨 Total warnings found: $warning_count" # Display the count of warnings.
    else
        echo -e "      🚨 Total warnings found: ${BLUE}Not Analyzed${NC}" # If warning keyword is not parsed, display not analyzed.
    fi
    if [[ $parse_info == true ]]; then # Check if the info keyword is parsed.
        echo "      🔤 Info Keyword: $info_keyword"
        echo "      ℹ️ Total info messages found: $info_messages_count" # Display the count of info messages.
    else
        echo -e "      ℹ️ Total info messages found: ${BLUE}Not Analyzed${NC}" # If info keyword is not parsed, display not analyzed.
    fi
    echo
    echo -e "${YELLOW}##########========== End of Report ===========##########${NC}"
    echo
}

# MAIN LOOP

if [[ $# -eq 0 ]]; then # Check if no arguments are provided. -eq 0 checks if the number of arguments is zero.
    echo -e "${YELLOW}⚠️ No arguments provided. Use -h or --help for usage information.${NC}"
    echo
    show_help
    exit 1 # Exit with error code if no arguments are provided
fi

# parse arguments
while [[ $# -gt 0 ]]; do # -gt 0 checks if the number of arguments is greater than zero.
    case $1 in
        -h|--help)
            show_help
            exit 0 # Exit with success code after displaying help message
            ;;
        -f)
            FILE="$2" # Assign the second argument to FILE variable
            if [[ $# -ge 2 ]]; then # -ge 2 checks if there are at least two arguments.
                get_file_path # Call the function to get the file path
                shift 2
            else
                echo -e "${RED}❌ No log file provided. Use -h or --help for usage information.${NC}"
                echo
                show_help
                exit 1 # Exit with error code if no log file is provided
            fi
            ;;
        -e)
            parse_error=true # Set the flag to true to indicate that the error keyword is parsed
            if [[ -n "$2" && "$2" != -* ]]; then # -n checks if the second argument is not empty and != -* checks if it does not start with a hyphen.
                if [[ "$2" =~ ^-?[0-9]+$ ]]; then # Check if the second argument is a number
                    echo -e "${RED}⚠️ Error keyword must be a string.${NC}"
                    exit 1 # Exit with error code if error keyword is not a string
                else
                    error_keyword="$2"
                    shift 2 # Shift because there are more arguments
                fi
            else
                run_immediately=true # Set the flag to true to run immediately
                shift # Shift to the next argument
            fi
            ;;
        -w)
            parse_warning=true # Set the flag to true to indicate that the warning keyword is parsed
            if [[ -n "$2" && "$2" != -* ]]; then
                if [[ "$2" =~  ^-?[0-9]+$ ]]; then
                    echo -e "${RED}⚠️ Warning keyword must be a string.${NC}"
                    exit 1 # Exit with error code if warning keyword is not a string
                else
                    warning_keyword="$2"
                    shift 2 # Shift because there are more arguments
                fi
            else
                run_immediately=true # Set the flag to true to run immediately
                shift # Shift to the next argument
            fi
            ;;
        -c)
            parse_info=true # Set the flag to true to indicate that the info keyword is parsed
            if [[ -n "$2" && "$2" != -* ]]; then
                if [[ "$2" =~  ^-?[0-9]+$ ]]; then
                    echo -e "${RED}⚠️ Info keyword must be a string.${NC}"
                    exit 1 # Exit with error code if info keyword is not a string
                else
                    info_keyword="$2"
                    shift 2 # Shift because there are more arguments
                fi
            else
                run_immediately=true # Set the flag to true to run immediately
                shift # Shift to the next argument
            fi
            ;;
        -t)
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then # Check if the second argument is not empty and is a positive integer.
                threshold_count="$2"
                if [[ $threshold_count -le 0 ]]; then # Check if the threshold count is a positive integer. -le 0 checks if the threshold count is less than or equal to zero.
                    echo -e "${RED}⚠️Threshold count must be a positive integer.${NC}"
                    exit 1 # Exit with error code if threshold count is not a positive integer
                else
                    shift 2 # Shift because there are more arguments
                fi
            else
                echo -e "${RED}❌ Invalid threshold count provided. Use -h or --help for usage information.${NC}"
                echo
                exit 1 # Exit with error code if invalid threshold count is provided
            fi
            ;;
        -v)
            parse_error=true # Set the flag to true to indicate that the error keyword is parsed
            parse_warning=true # Set the flag to true to indicate that the warning keyword is parsed
            parse_info=true # Set the flag to true to indicate that the info keyword is parsed
            run_immediately=true # Set the flag to true to run immediately
            shift # Shift to the next argument
            ;;
        *)
            echo -e "${RED}⚠️ Unknown option: $1. Use -h or --help for usage information.${NC}"
            echo
            show_help
            exit 1 # Exit with error code for unknown option
            ;;
    esac
done

# Check if the script should run immediately
if [[ "$run_immediately" == true ]]; then
    process_log_file # Call the function to process the log file
    display_summary_report # Call the function to display summary report
    exit 0 # Exit with success code after processing the log file and displaying the summary report
fi

process_log_file # Call the function to process the log file after parsing all arguments
display_summary_report # Call the function to display summary report after processing the log file