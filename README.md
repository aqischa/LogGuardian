# 🛡️ LOGGUARDIAN.SH

A powerful and customizable Bash script for analyzing logs, detecting critical patterns, and generating clean summaries.

Use it to monitor logs from apps, servers, or any tool that writes events to a file — especially during deployment, debugging, or audits.

Now enhanced with support for multiple keywords, unified thresholds, and streamlined parsing.

---

## 📦 USAGE GUIDE

### 🔧 Basic Syntax:

```bash
  ./logguardian2.sh [options]
```

### 🤖 Available Options:

```bash
  -f <log_file_path>     # REQUIRED: Path to your log file
  -e "<error_keyword>"   # Regex for CRITICAL errors (e.g. "ERROR|FATAL|CRITICAL")
  -w "<warning_keyword>" # Regex for WARNING messages (e.g. "WARN|NOTICE")
  -c "<info_keyword>"    # Regex for INFO messages (e.g. "INFO|SUCCESS")
  -t <threshold_count>   # Max allowed messages per category before alert (default: 5)
  -v                     # Verbose: Run immediately and show full summary
  -h or --help           # Show usage help

⚠️ NOTE:
If using multiple keywords (like "CRITICAL|ERROR|FATAL"), wrap them in **quotes**.
```

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
  [2025-07-06 12:04:11] FATAL: Kernel panic detected
```

### Then run:

```bash
  ./logguardian2.sh -f test.log -e "ERROR|FATAL" -t 1
```

### Expected Output:

```bash
  🛑 Total critical errors found: 2
      ⚠️ ERROR ALERT!! Threshold exceeded.
      - ERROR: Unable to authenticate user
      - FATAL: Kernel panic detected
```

---

## 🧠 DEVELOPER NOTES – GRANULAR EXPLANATION

### 🔹 ARGUMENT PARSING

Handled by reusable function `handle_keyword_option`:

```bash
  handle_keyword_option "$2" "error"
  shift $([[ -n "$2" && "$2" != -* ]] && echo 2 || echo 1)
```

Parses both keyword and whether to process immediately.

---

### 🔹 FILE VALIDATION

Log file must exist and be readable. Checked early:

```bash
  if [[ ! -f "$FILE" || ! -r "$FILE" ]]; then
    echo "Error: Cannot read file"
    exit 1
  fi
```

---

### 🔹 LOG PROCESSING: `process_log_file`

Scans line by line:

```bash
  if [[ $line =~ $error_keyword ]]; then
    critical_errors+=("$line")
    ((critical_errors_count++))
```

Includes arrays for:
  - `critical_errors`
  - `warning_messages`
  - `info_messages`

---

### 🔹 THRESHOLD CHECK: `display_threshold_alert`

This function is reused for error, warning, and info:

```bash
  display_threshold_alert "$count" "$threshold" "$level" arrayname
```

Uses nameref to receive the appropriate array and prints matched lines if threshold is exceeded.

---

### 🔹 GENERIC OUTPUT: `display_message_lines`

Replaces `display_error_line`, now used across all levels.

```bash
  display_message_lines "warning" warning_messages
```

---

### 🔹 VERBOSE MODE: `-v`

Enables:
- `parse_error=true`
- `parse_warning=true`
- `parse_info=true`
- `run_immediately=true`

This triggers full analysis without needing extra flags.

---

## ✨ WHAT'S NEW IN LOGGUARDIAN2

✅ Multiple Keyword Support:
  Use `|` to specify several patterns (e.g., `"ERROR|FATAL|CRITICAL"`)

✅ Unified Threshold Handling:
  Threshold count now applies to errors, warnings, and info (not just errors)

✅ Matching Line Output:
  When threshold is exceeded, matching lines are printed for that level

✅ Cleaner Logic:
  - Reusable functions (`handle_keyword_option`, `display_threshold_alert`)
  - Less code duplication

✅ Better Help Output:
  Clarified how to quote regex keywords in CLI examples

---

## ✅ REQUIREMENTS

- Bash version 4+
- ANSI-compatible terminal (for color output)
- A readable log file

---

## ✍️ AUTHOR

**Amir Anaqishah**
aanaqi@coreium.io