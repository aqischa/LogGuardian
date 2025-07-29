# 🛡️ LOGGUARDIAN.SH

A powerful and customizable Bash script for analyzing logs, detecting critical patterns, and generating clean summaries.

Use it to monitor logs from apps, servers, or any tool that writes events to a file — especially during deployment, debugging, or audits.

---

## 📦 USAGE GUIDE

### 🔧 Basic Syntax:

```bash
  ./logguardian.sh [options]
```

### 🤖 Available Options:

| Option                  | Description                                                  |
|-------------------------|--------------------------------------------------------------|
| `-f <log_file_path>`    | **REQUIRED**: Path to your log file                          |
| `-e <error_keyword>`    | Keyword for CRITICAL errors (default: `ERROR`)               |
| `-w <warning_keyword>`  | Keyword for WARN messages (default: `WARN\|WARNING`)         |
| `-c <info_keyword>`     | Keyword for INFO messages (default: `INFO\|SUCCESS`)         |
| `-t <threshold_count>`  | Max allowed errors before alert (default: `5`)               |
| `-v`                    | Verbose: See parsed values and thresholds                    |
| `-h`, `--help`          | Show usage help                                              |

---

### 📌 Example 1: Basic Scan with Defaults

```bash
./logguardian.sh -f /var/log/syslog
```

### 🔧 Example 2: Custom Keywords and Thresholds

```bash
./logguardian.sh -f app.log -e CRITICAL -w WARN -c SUCCESS -t 10
```

### 📣 Example 3: Verbose Mode

```bash
./logguardian.sh -f logs.txt -v
```

---

## 🧪 HOW TO TEST

Create a test file (`test.log`) with this sample content:

```bash
  [2025-07-06 12:00:01] INFO: Starting up...
  [2025-07-06 12:01:15] ERROR: Unable to authenticate user
  [2025-07-06 12:02:22] WARN: Disk usage at 85%
  [2025-07-06 12:03:33] SUCCESS: Backup complete
```

Then run:

```bash
  ./logguardian.sh -f test.log
```

Test Alert Threshold:

```bash
  ./logguardian.sh -f test.log -e ERROR -t 1
```

You should see:

```bash
  🛑 Total critical errors found: 1
      ⚠️ CRITICAL ALERT!! Error threshold exceeded.
```

---

## 🧠 DEVELOPER NOTES – GRANULAR EXPLANATION

### 🔹 ARGUMENT PARSING

The script processes CLI flags using:

```bash
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -f) log_file="$2"; shift; shift; ;;
      -e) error_keyword="$2"; parse_errors=true; shift; shift; ;;
      ...
    esac
  done
```

Defaults are only applied *after* parsing, so users can override them.

---

### 🔹 FILE VALIDATION

After parsing, the file is checked using:

```bash
  if [[ ! -f "$log_file" || ! -r "$log_file" ]]; then
    echo "Error: Cannot read file"
    exit 1
  fi
```

---

### 🔹 CORE LOGIC: `process_log_file`

This function scans each line:
```bash
  while IFS= read -r line; do
    if [[ "$line" =~ $error_keyword ]]; then
      ((critical_errors_count++))
      critical_errors+=("$line")
    fi
    ...
  done < "$log_file"
```

---

### 🔹 REPORT SUMMARY: `display_summary_report`

After scanning, results are printed:

```bash
  echo "Total lines processed: $(wc -l < "$log_file")"

  if (( critical_errors_count > threshold_count )); then
    echo "⚠️ CRITICAL ALERT!! Error threshold exceeded."
    display_error_line
  fi
```

---

### 🔹 FORMATTED OUTPUT: `display_error_line`

Prints matching error lines:

```bash
  for err in "${critical_errors[@]}"; do
    echo -e "\e[31m$err\e[0m"
  done
```

---

### 🔹 STYLING & COLORS

```bash
  Red:     \e[31m
  Yellow:  \e[33m
  Green:   \e[32m
  Cyan:    \e[36m
  Bold:    \e[1m
  Reset:   \e[0m
```

---

### 🔹 QUICK HELP MESSAGE

When running `-h` or `--help`, a here-doc prints the options:

```bash
  cat << EOF
    Usage: ./logguardian.sh [options]
    -f   Log file (required)
    -e   Error keyword (default: ERROR)
    ...
  EOF
```

---

## 💡 DESIGN NOTES & ENHANCEMENTS

- Modular Parsing: Only process what user requests (error, warn, info)
- Supports default + user keywords flexibly
- Threshold alert system: Simple yet effective monitoring
- Easy to extend: Add export file output, multiple `-f` inputs, etc.

### Potential Improvements:
  ✔ Add --output to export summaries
  ✔ Case-insensitive matching support
  ✔ Unit test support with sample logs

---

## ✅ REQUIREMENTS

- Bash version 4 or newer
- ANSI-compatible terminal (for colors)
- A readable log file

---

## ✍️ AUTHOR

**Amir Anaqishah**
aanaqi@coreium.io