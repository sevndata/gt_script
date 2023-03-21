#!/bin/bash
set -e

CUSTOM_FILNAME=$(basename "$0")
echo "file name with "$CUSTOM_FILNAME

optimize_limits_conf() {
    local limits_conf_file="/etc/security/limits.conf"
    local limits_conf=(
        "root soft nproc 51200"
        "root hard nproc 51200"
        "root soft nofile 2097152"
        "root hard nofile 2097152"
    )

    if [ ! -f "$limits_conf_file" ]; then
        echo "File not found: $limits_conf_file"
        exit 1
    fi

    if [ ! -f "$limits_conf_file.bak" ]; then
        cp "$limits_conf_file" "$limits_conf_file.bak"
    fi

    for conf_item in "${limits_conf[@]}"; do
        local item_name=$(echo "$conf_item" | awk '{print $2}')
        local item_value=$(echo "$conf_item" | awk '{print $4}')
        local item_type=$(echo "$conf_item" | awk '{print $3}')
        local item_user=$(echo "$conf_item" | awk '{print $1}')

        if grep -q -E "^${item_user} ${item_type} ${item_name}" "$limits_conf_file"; then
            sed -i -E "s|^${item_user} ${item_type} ${item_name}.*|${conf_item}|" "$limits_conf_file"
        else
            echo "$conf_item" | tee -a "$limits_conf_file" >/dev/null
        fi
    done
}

optimize_sysctl_conf() {
    local sysctl_conf_file="/etc/sysctl.conf"
    local sysctl_conf=(
        "fs.file-max = 2097152"
        "net.core.somaxconn = 65535"
        "net.ipv4.tcp_max_syn_backlog = 65535"
        "net.ipv4.ip_local_port_range = 1024 65535"
        "net.ipv4.tcp_sack = 1"
        "net.ipv4.tcp_timestamps = 1"
        "net.ipv4.tcp_keepalive_time = 120"
        "net.ipv4.tcp_keepalive_probes = 9"
        "net.ipv4.tcp_keepalive_intvl = 10"
        "net.ipv4.tcp_fin_timeout = 30"
    )

    if [ ! -f "$sysctl_conf_file" ]; then
        echo "File not found: $sysctl_conf_file"
        exit 1
    fi

    if [ ! -f "$sysctl_conf_file.bak" ]; then
        cp "$sysctl_conf_file" "$sysctl_conf_file.bak"
    fi

    for conf_item in "${sysctl_conf[@]}"; do
        local param_name=$(echo "$conf_item" | awk '{print $1}')
        local param_value=$(echo "$conf_item" | awk '{print $3}')

        if grep -q "^$param_name" "$sysctl_conf_file"; then
            sed -i "s|^$param_name.*|$conf_item|" "$sysctl_conf_file"
        else
            echo "$conf_item" | tee -a "$sysctl_conf_file" >/dev/null
        fi
    done

    sysctl -p >/dev/null
}

optimize_limits_conf && wait && optimize_sysctl_conf && wait && rm -rf $CUSTOM_FILNAME && wait && echo "Optimization complete"
