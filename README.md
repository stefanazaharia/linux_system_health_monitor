# Linux System Health Monitor

A lightweight, interactive Bash utility designed to monitor critical Linux system resources in real time. It features custom threshold checks, color-coded terminal alerts, and automated persistent logging for proactive system diagnostics.

## Features

- **CPU Monitoring:** Calculates actual processor usage dynamically via `top` and alert thresholds.
- **Memory Tracking:** Computes memory utilization percentages using raw byte output from `free`.
- **Disk Usage Inspection:** Inspects mounted `/dev/` filesystems to flag low disk space.
- **Top Resource Consumers:** Identifies the top 10 CPU-heavy active processes via `ps aux`.
- **Network Throughput:** Automatically detects the default network interface and samples traffic in KB/s using `ifstat`.
- **Automated Logging & Alerts:** Flags threshold breaches in colored terminal output and logs timestamped events to `/var/log/system_health_check.log`.

---

## Prerequisites

The script requires standard Linux utilities plus `bc` (for precise floating-point math) and `ifstat` (for network telemetry).

On Debian/Ubuntu systems:
```bash
sudo apt update
sudo apt install bc ifstat -y
