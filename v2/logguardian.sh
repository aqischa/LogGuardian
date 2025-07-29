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
warning_messages=() # Array to hold warning messages
info_messages=() # Array to hold info messages

run_immediately=false # Flag to indicate if the script should run immediately
parse_error=false # Flag to indicate if the error keyword is parsed
parse_warning=false # Flag to indicate if the warning keyword is parsed
parse_info=false # Flag to indicate if the info keyword is parsed

show_help() {
    cat << EOF # Using 'here document' to display help message. Using EOF to end the message.
###############===================================###############
Usage: logguardian2.sh [options]

Description:
    Automates the analysis of application log files, identifies critical events, and
    simulate notifications or reports based on these findings.

Options:
    -f <log_file_path>   : Specifies the path to the log file to be analyzed.
    -e <error_keyword>   : A regex string for matching "error" messages.
                           Example: "ERROR|FATAL|CRITICAL"
                           Note: If using multiple keywords (e.g., "CRITICAL|ERROR|FATAL"), wrap them in quotes.
    -w <warning_keyword> : A regex string for matching "warning" messages.
                           Example: "WARN|WARNING|NOTICE"
                           Note: If using multiple keywords (e.g., "WARN|WARNING"), wrap them in quotes.
    -c <info_keyword>    : A regex string for matching "info" or "completion" messages.
                           Example: "INFO|SUCCESS|DEBUG"
                           Note: If using multiple keywords (e.g., "INFO|SUCCESS"), wrap them in quotes.
    -t <threshold_count> : A positive integer threshold. If the count of "critical errors"
                           (based on -e keyword) exceeds this number, trigger a "critical alert."
                           Defaults to 5 if not provided.
    -h or --help         : Display a comprehensive help message explaining all options.
    -v                   : Verbose mode. Process the log file and display a summary report.

Example:
logguardian2.sh -f /var/log/myapp.log -e "CRITICAL"
logguardian2.sh -f /var/log/myapp.log -w "WARN" -c "INFO" -t 10
###############===================================###############

EOF
}

get_file_path() {
    if [[ -f $FILE ]];then # Check if the file exists and is a regular file.
        if [[ -r $FILE ]]; then # Check if the file is readable.
            local log_file_path=$(readlink -e "$FILE") # Using readlink to find the absolute path of the log file.
            echo "Log file found and is readable." # Print success message in green color.
            echo "Log file: $FILE"
            echo "Log file path: $log_file_path"
            echo
        else
            echo "ERROR: Log file is not readable."
            echo
            exit 1 # Exit with error code if the file is not readable.
        fi
    else # If the file does not exist.
        echo "ERROR: Log file does not exist."
        echo
        exit 1 # Exit with error code if the file does not exist.
    fi
}

process_log_file() {
    # Read the log files line by line and process them based on the keywords provided.
    # IFS: to read file line by line. -r: to prevent backslash escapes from being interpreted.
    # line: variable to hold each line of the log file.
    while IFS= read -r line; do 
        if [[ $line =~ $error_keyword ]]; then # Check if the line contains the error keyword.
            critical_errors+=("$line") # Add the line to the critical errors array.
            ((critical_errors_count++)) # Increment the critical errors count.
        elif [[ $line =~ $warning_keyword ]]; then # Check if the line contains the warning keyword.
            warning_messages+=("$line") # Add the line to the warning messages array.
            ((warning_count++)) # Increment the warning count.
        elif [[ $line =~ $info_keyword ]]; then # Check if the line contains the info keyword.
            info_messages+=("$line") # Add the line to the info messages array.
            ((info_messages_count++)) # Increment the info messages count.
        fi

    done < "$FILE" # Read from the specified log file.
}

#reusable function to handle keyword options
handle_keyword_option() {
    local keyword_value="$1" # Assign the first argument to keyword_value
    local keyword_type="$2" # Assign the second argument to keyword_type

    if [[ -n "$keyword_value" && "$keyword_value" != -* ]]; then
            case "$keyword_type" in
                error)
                    error_keyword="$keyword_value"
                    parse_error=true
                    ;;
                warning)
                    warning_keyword="$keyword_value"
                    parse_warning=true
                    ;;
                info)
                    info_keuword="$keyword_value"
                    parse_info=true
                    ;;
            esac
    else
        run_immediately=true
        case "$keyword_type" in
            error) parse_error=true ;;
            warning) parse_warning=true ;;
            info) parse_info=true ;;
        esac
    fi
}

display_threshold_alert() {
    local count="$1"
    local threshold="$2"
    local level="$3"
    local -n messages="$4"

    if [[ $count -ge $threshold ]]; then
        echo "${level^^} ALERT!! Threshold exceeded (${count}/${threshold})."
        display_message_lines "$level" messages
    elif [[ $count -eq 0 ]]; then
        echo "No ${level} messages found."
    else
        echo "Threshold: $threshold"
        echo "${level^^} count within acceptable limits."
    fi
}

display_message_lines() {
    local level="$1"
    local -n lines="$2"

    echo "${level^^} messages found in the log file:"
    for msg in "${lines[@]}"; do
        echo "   - $msg" # Print each message line.
    done
}

display_summary_report() {
    echo "##########========== Summary Report ===========##########"
    echo
    echo "Total line processed: $(wc -l < "$FILE")" # wc -l counts the number of lines in the file.
    if [[ $parse_error == true ]]; then # Check if the error keyword is parsed.
        echo "Error Keyword: $error_keyword"
        echo "Total critical errors found: $critical_errors_count" # Display the count of critical errors.
        display_threshold_alert "$critical_errors_count" "$threshold_count" "error" critical_errors
        echo
    else
        echo "Total critical errors found: Not analyzed"
        echo
    fi
    if [[ $parse_warning == true ]]; then # Check if the warning keyword is parsed.
        echo "Warning Keyword: $warning_keyword"
        echo "Total warnings found: $warning_count" # Display the count of warnings.
        display_threshold_alert "$warning_count" "$threshold_count" "warning" warning_messages
        echo
    else
        echo "Total warnings found: Not Analyzed" # If warning keyword is not parsed,
        echo
    fi
    if [[ $parse_info == true ]]; then # Check if the info keyword is parsed.
        echo "Info Keyword: $info_keyword"
        echo "Total info messages found: $info_messages_count" # Display the count of info messages.
        display_threshold_alert "$info_messages_count" "$threshold_count" "info" info_messages
        echo
    else
        echo "Total info messages found: Not Analyzed" # If info keyword is not parsed
        echo
    fi
    echo "##########========== End of Report ===========##########"
    echo
}

# MAIN LOOP

if [[ $# -eq 0 ]]; then # Check if no arguments are provided. -eq 0 checks if the number of arguments is zero.
    echo "No arguments provided. Use -h or --help for usage information."
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
                echo "No log file provided. Use -h or --help for usage information."
                echo
                show_help
                exit 1 # Exit with error code if no log file is provided
            fi
            ;;
        -e)
            handle_keyword_option "$2" "error"
            shift $([[ -n "$2" && "$2" != -* ]] && echo 2 || echo 1)
            ;;
        -w)
            handle_keyword_option "$2" "warning"
            shift $([[ -n "$2" && "$2" != -* ]] && echo 2 || echo 1)
            ;;
        -c)
            handle_keyword_option "$2" "info"
            shift $([[ -n "$2" && "$2" != -* ]] && echo 2 || echo 1)
            ;;
        -t)
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then # Check if the second argument is not empty and is a positive integer.
                threshold_count="$2"
                # Check if the threshold count is a positive integer. -le 0 checks if the threshold count is less than or equal to zero.
                if [[ $threshold_count -le 0 ]]; then
                    echo "Threshold count must be a positive integer."
                    exit 1 # Exit with error code if threshold count is not a positive integer
                else
                    shift 2 # Shift because there are more arguments
                fi
            else
                echo "Invalid threshold count provided. Use -h or --help for usage information."
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
            echo "Unknown option: $1. Use -h or --help for usage information."
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