#!/bin/bash

#=============================================================
# "No Space Left on Device" Errors
# Immediate Solution:

# Quick space recovery
# sudo truncate -s 0 /var/lib/docker/containers/*/*-json.log

# Clean Docker system
# docker system prune -a -f
#=============================================================

ALERT_THRESHOLD="1G"
EMAIL="admin@example.com"

check_log_sizes() {
    find /var/lib/docker/containers -name "*-json.log" -size +$ALERT_THRESHOLD -exec bash -c '
        container_id=$(basename $(dirname "$1"))
        container_name=$(docker inspect --format="{{.Name}}" "$container_id" 2>/dev/null | sed "s/^///")
        size=$(du -h "$1" | cut -f1)
        
        echo "ALERT: Container $container_name has log file size: $size"
        
        # Optional: Send email alert
        # echo "Container $container_name log size exceeded threshold: $size" | mail -s "Docker Log Alert" $EMAIL
    ' bash {} \;
}


check_log_sizes_container() {
    find /home/nov_ema/docker/rsdu-webapps -name "*.log" -size +$ALERT_THRESHOLD -exec bash -c '
       # truncate -s 0 "$1"
      
       echo "ALERT: log file $1 size>1G"

    ' bash {} \;
}

check_log_sizes_container
