#!/bin/sh
# AP端分块接收与断点续传/回滚示例

UPLOAD_LOG="/tmp/firmware_upload.log"
BACKUP="/firmware/backup.bin"
TARGET="/firmware/upgrade.bin"

# 接收分块（参数: $1=offset $2=base64_chunk $3=action[rollback|commit]）
offset="$1"
chunk_b64="$2"
action="$3"

if [ "$action" = "rollback" ]; then
    [ -f "$BACKUP" ] && cp "$BACKUP" "$TARGET"
    echo "{\"timestamp\":$(date +%s),\"type\":\"event\",\"msg\":\"rollback\",\"code\":0}" >> $UPLOAD_LOG
    echo '{"code":0,"msg":"rollback ok"}'
    exit 0
fi

if [ "$action" = "commit" ]; then
    # 校验并应用升级
    md5sum "$TARGET" > "$TARGET.md5"
    # 触发实际升级流程（如mtd写入/重启）
    echo "{\"timestamp\":$(date +%s),\"type\":\"event\",\"msg\":\"commit upgrade\",\"code\":0}" >> $UPLOAD_LOG
    echo '{"code":0,"msg":"commit ok"}'
    exit 0
fi

[ -z "$offset" ] && echo '{"code":1,"msg":"missing offset"}' && exit 1
[ -z "$chunk_b64" ] && echo '{"code":2,"msg":"missing chunk"}' && exit 1

chunk_bin=$(echo "$chunk_b64" | base64 -d)
dd if=/dev/zero of=$TARGET bs=1 count=0 seek=$offset 2>/dev/null
echo -n "$chunk_bin" | dd of=$TARGET bs=1 seek=$offset conv=notrunc 2>/dev/null

echo "$offset" > $UPLOAD_LOG
echo '{"code":0,"msg":"chunk written"}'
