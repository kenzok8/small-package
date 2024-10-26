#!/bin/sh

conffile="/etc/config/autoshell"
output_file="/etc/autoshell.sh"

url=""
headers=""
data=""

while read -r line; do
    if [[ "$line" =~ "curl" ]]; then
        url=$(echo "$line" | grep -oE 'curl "([^"]+)"' | cut -d'"' -f2)
    elif [[ "$line" =~ "-H" ]]; then
        header=$(echo "$line" | grep -oE '^ *-H "[^"]+"' | cut -d'"' -f2)
        headers="$headers\n$header"
    elif [[ "$line" =~ "--data-raw" ]]; then
        data=$(echo "$line" | grep -oE '\-\-data-raw "[^"]+"' | cut -d'"' -f2)
        data=$(echo "$data" | tr -d '^')
    fi
done < "$conffile"

headers=$(echo -e "$headers")
headers=$(echo "$headers" | sed 's/\^\%\^/^/g')

cat <<EOF > "$output_file"
#!/bin/sh

url="$url"

headers="$headers"

data="$data"

log_file="/tmp/log/autoshell.log"
log_time=\$(date '+%Y-%m-%d %H:%M:%S')
echo "[\$log_time] 开始运行" >> "\$log_file"

while true; do
    while true; do
        log_time=\$(date '+%Y-%m-%d %H:%M:%S')
        if ping -c 1 8.8.8.8 >/dev/null; then
            echo "[\$log_time] 网络守护日志输出-目前网络正常" >> "\$log_file"
            log_line_count=\$(wc -l < "\$log_file")
            if [ "\$log_line_count" -gt 100 ]; then
                echo "[\$log_time] 日志达到上限，已覆盖" > "\$log_file"
        fi
            sleep 30
        else
            echo "[\$log_time] 网络异常，进行二次网络监测，避免误测" >> "\$log_file"
            sleep 3
            break
        fi
    done

    while true; do
        log_time=\$(date '+%Y-%m-%d %H:%M:%S')
        if ping -c 1 8.8.8.8 >/dev/null; then
            break
        else
            echo "[\$log_time] 确认网络异常，将发起认证请求！" >> "\$log_file"
            response=\$(curl -s -X POST -H "\$(echo "\$headers" | tr '\n' '\r\n')" -d "\$data" "\$url")
            sleep 5

            if [ \${#response} -lt 1 ]; then
                echo "[\$log_time] 服务器未返回信息，等待网络检测结果" >> "\$log_file"
            else
                result=\$(echo "\$response" | grep -o '"result":"[^"]*"' | sed 's/"result":"\([^"]*\)"/\1/')
                message=\$(echo "\$response" | grep -o '"message":"[^"]*"' | sed 's/"message":"\([^"]*\)"/\1/')
                echo "[\$log_time] 服务器返回：\$response" >> "\$log_file"
            fi
        fi
    done
done
EOF

chmod +x "$output_file"
exit 0
